extends RefCounted
## Independent receipt reconstruction and day-by-day reference invariants, in memory.

const Runner = preload("res://scripts/sim/equilibrium_runner.gd")
const Labor = preload("res://scripts/sim/labor_config.gd")


static func _households(entities: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id in entities:
		if entities[id].kind == "resident":
			result[id] = entities[id].duplicate(true)
	return result


static func audit(history: Array, final_entities: Dictionary) -> Dictionary:
	var entities: Dictionary = history[0].details.state.entities.duplicate(true)
	var firms: Dictionary = history[0].details.state.businesses
	var checks = {"ordered_days": true, "commands_succeed": true, "currency_each_event": true,
		"bounded_accounts": true, "paid_labor": true, "daily_goods_and_meals": true,
		"business_daily_cycle": true, "household_two_day_cycle": true}
	var parity_states: Dictionary = {0: _households(entities)}
	var day: int = 0
	var day_count: int = 0
	var production: Dictionary = {}
	var bought: Dictionary = {}
	var meals: Array = []
	var worked: Array = []
	var sources: Dictionary = {}
	var claimed: Dictionary = {}
	for index in history.size():
		var e: Dictionary = history[index]
		var d: Dictionary = e.details
		checks.ordered_days = checks.ordered_days and e.id == index + 1
		checks.commands_succeed = checks.commands_succeed and e.success
		if e.action == "day_started":
			day += 1
			production = {"wheat": 0, "flour": 0, "bread": 0}
			bought = {"wheat": 0, "flour": 0, "bread": 0}
			meals = []
			worked = []
		checks.ordered_days = checks.ordered_days and e.day == day
		if not e.success:
			continue
		match e.action:
			"transfer_money":
				entities[e.actor].money -= d.amount
				entities[e.target].money += d.amount
				sources[e.id] = true
			"harvest":
				entities[e.actor].inventory.wheat += d.amount
				production.wheat += d.amount
				checks.paid_labor = checks.paid_labor and e.actor == "farm" and d.amount == 4
				sources[e.id] = true
			"produce":
				var expected_inputs: Dictionary = {"wheat": 4} if d.recipe == "mill" else {"flour": 4}
				var expected_outputs: Dictionary = {"flour": 4} if d.recipe == "mill" else {"bread": 6}
				checks.paid_labor = checks.paid_labor and d.batches == 2 and d.inputs == expected_inputs and d.outputs == expected_outputs
				for item in d.inputs:
					entities[e.actor].inventory[item] -= d.inputs[item]
				for item in d.outputs:
					entities[e.actor].inventory[item] += d.outputs[item]
					production[item] += d.outputs[item]
				sources[e.id] = true
			"work_shift":
				var firm: Dictionary = firms[e.target]
				var employees: Array = firm.employees.duplicate()
				employees.sort()
				var roster: Array = [firm.owner] + employees
				var expected: Array = roster.slice(0, 2) if day % 2 == 1 else roster.slice(2, 4)
				checks.paid_labor = checks.paid_labor and e.actor in expected and e.actor not in worked and d.labor == 1 and d.wage == 8
				worked.append(e.actor)
				var pay: Dictionary = history[d.payment_event_id - 1]
				var output: Dictionary = history[d.production_event_id - 1]
				checks.paid_labor = checks.paid_labor and d.payment_event_id == e.id - 2 and d.production_event_id == e.id - 1 \
					and pay.action == "transfer_money" and pay.actor == e.target and pay.target == e.actor and pay.details.amount == 8 \
					and output.actor == e.target and output.action in ["harvest", "produce"] \
					and not claimed.has(pay.id) and not claimed.has(output.id)
				claimed[pay.id] = true
				claimed[output.id] = true
			"purchase":
				checks.daily_goods_and_meals = checks.daily_goods_and_meals and d.unit_price == {"wheat": 2, "flour": 4, "bread": 4}[d.item] \
					and d.total_price == d.quantity * d.unit_price
				entities[e.actor].money -= d.total_price
				entities[e.target].money += d.total_price
				entities[e.actor].inventory[d.item] += d.quantity
				entities[e.target].inventory[d.item] -= d.quantity
				bought[d.item] += d.quantity
			"consume":
				checks.daily_goods_and_meals = checks.daily_goods_and_meals and d.amount == 1 and e.actor not in meals
				entities[e.actor].inventory.bread -= d.amount
				meals.append(e.actor)
			"labor_environment":
				checks.paid_labor = checks.paid_labor and d.opportunities.size() == 4
				for amount in d.opportunities.values():
					checks.paid_labor = checks.paid_labor and amount == 4
			"initialize", "day_started", "shift_offered":
				pass
			_:
				checks.commands_succeed = false
		var money: int = 0
		for entity in entities.values():
			money += entity.money
			checks.bounded_accounts = checks.bounded_accounts and entity.money >= 0 and entity.money <= 1_000_000_000
			for amount in entity.inventory.values():
				checks.bounded_accounts = checks.bounded_accounts and amount >= 0 and amount <= 1_000_000_000
		checks.currency_each_event = checks.currency_each_event and money == 432
		if e.action == "consume" and meals.size() == 12:
			day_count += 1
			checks.daily_goods_and_meals = checks.daily_goods_and_meals and production == {"wheat": 8, "flour": 8, "bread": 12} \
				and bought == {"wheat": 8, "flour": 8, "bread": 12} and worked.size() == 6
			for id in entities:
				checks.daily_goods_and_meals = checks.daily_goods_and_meals and entities[id].inventory == {"wheat": 0, "flour": 0, "bread": 0}
				if entities[id].kind == "business":
					checks.business_daily_cycle = checks.business_daily_cycle and entities[id].money == 120
				else:
					var expected_money: int = (10 if id in worked else 2) if day % 2 == 1 else 6
					checks.household_two_day_cycle = checks.household_two_day_cycle and entities[id].money == expected_money
			var households: Dictionary = _households(entities)
			if not parity_states.has(day % 2):
				parity_states[day % 2] = households
			checks.household_two_day_cycle = checks.household_two_day_cycle and households == parity_states[day % 2]
	checks["all_days_checked"] = day_count == day
	checks["unique_labor_receipts"] = claimed == sources
	checks["economic_ledger_matches_authority"] = entities == final_entities
	return checks


static func run(suite: SceneTree) -> void:
	var zero = Runner.new(42)
	var initial: Dictionary = zero.world.snapshot()
	var original: Dictionary = Labor.initial()
	var configured: bool = initial.entities.size() == 15 and initial.employment.size() == 9
	for id in initial.entities:
		var entity: Dictionary = initial.entities[id]
		configured = configured and entity.inventory == {"wheat": 0, "flour": 0, "bread": 0} \
			and entity.money == (120 if entity.kind == "business" else 6)
	for id in initial.businesses:
		configured = configured and initial.businesses[id].owner == original.businesses[id].owner \
			and initial.businesses[id].employees == original.businesses[id].employees and initial.businesses[id].owner_compensation == 8
	for id in initial.employment:
		configured = configured and initial.employment[id].business == original.employment[id].business and initial.employment[id].wage == 8
	suite._check(configured, "reference has exact zero-stock endowments, compensation, original owners and employment")
	suite._check(not zero.world.has_method("owner_withdrawal"), "reference has no ownership-withdrawal mechanism")
	zero.world.advance_day()
	var before: Dictionary = zero.world.snapshot()
	suite._check(not zero.world.purchase("mill", "farm", "wheat", 8, 2) and not zero.world.harvest("farm", 8)
		and not zero.world.purchase("ada", "bakery", "bread", 1, 3) and zero.world.snapshot() == before,
		"reference retains actual-stock, paid-labor and fixed-price guards without partial mutation")
	var prices: Dictionary = {}
	for offer in zero.world.observe("ada", "farm").offers:
		prices[offer.item] = offer.unit_price
	suite._check(prices == {"wheat": 2, "flour": 4, "bread": 4}, "public offers and purchase authority use the same reference prices")
	for days in [1, 2, 30, 365]:
		var first = Runner.new(42)
		var replay = Runner.new(42)
		first.run(days)
		@warning_ignore("integer_division")
		var split: int = days / 2
		replay.run(split)
		replay.run(days - split)
		var verified: Dictionary = audit(first.world.events(), first.world.snapshot().entities)
		for name in verified:
			suite._check(verified[name], "reference %dd: %s" % [days, name])
		suite._check(first.world.events() == replay.world.events() and first.world.snapshot() == replay.world.snapshot()
			and first.report() == replay.report(), "reference %dd exact ledger/state/report split replay" % days)
		var report: Dictionary = first.report()
		var totals_ok: bool = report.totals == {"harvested": {"wheat": 8 * days}, "production_inputs": {"wheat": 8 * days, "flour": 8 * days},
			"production_outputs": {"flour": 8 * days, "bread": 12 * days}, "consumed": {"bread": 12 * days}}
		for id in report.accounts:
			var account: Dictionary = report.accounts[id]
			totals_ok = totals_ok and report.final.entities[id].money == report.initial.entities[id].money + account.earned - account.spent
			if report.final.entities[id].kind == "resident":
				totals_ok = totals_ok and account.consumed == days and report.unmet_meals[id] == 0 and account.purchases == 4 * days
				@warning_ignore("integer_division")
				var shifts: int = (days + (1 if id in ["ada", "dain", "bram", "hale", "cora", "finn"] else 0)) / 2
				totals_ok = totals_ok and account.shifts == shifts and account.wages_received == shifts * 8
		suite._check(totals_ok and report.shifts.paid == 6 * days and report.shifts.wages == 48 * days
			and report.money == {"initial": 432, "final": 432, "circulation": 144 * days}
			and report.failures.is_empty() and report.decisions.is_empty(), "reference %dd reports exact production, wages, meals, cash and no autonomous decisions" % days)
		var missed: int = 0
		for amount in report.unmet_meals.values():
			missed += amount
		print("M11 reference: days=%d meals=%d shifts=%d missed=%d currency=%d invariants=%s" % [days, report.totals.consumed.bread, report.shifts.paid, missed, report.money.final, str(verified.values().all(func(value): return value))])
	var seed_a = Runner.new(7)
	var seed_b = Runner.new(99)
	seed_a.run(2)
	seed_b.run(2)
	suite._check(seed_a.world.events() == seed_b.world.events(), "reference fixed opportunities are seed-independent")
	var history: Array = seed_a.world.events()
	for e in history:
		if e.action == "transfer_money":
			e.details.amount = 7
			break
	suite._check(not audit(history, seed_a.world.snapshot().entities).household_two_day_cycle,
		"independent checker rejects conserved cash transfers that violate reference cycles")
