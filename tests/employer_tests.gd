extends RefCounted

const Runner = preload("res://scripts/sim/employer_runner.gd")
const Policy = preload("res://scripts/sim/employer_policy.gd")
const Reference = preload("res://scripts/sim/equilibrium_runner.gd")
const LaborTests = preload("res://tests/labor_tests.gd")


static func ledger_ok(history: Array, final: Dictionary) -> bool:
	var state: Dictionary = history[0].details.state.duplicate(true)
	var sources: Dictionary = {}
	var claimed: Dictionary = {}
	var worked: Dictionary = {}
	var sales: Dictionary = {}
	var work_receipts: Dictionary = {}
	var plan_claims: Dictionary = {}
	var valid: bool = true
	for index in history.size():
		var e: Dictionary = history[index]
		var d: Dictionary = e.details
		valid = valid and e.id == index + 1
		if e.action == "day_started":
			state.day += 1
			worked.clear()
		valid = valid and e.day == state.day
		if e.action == "employer_plan" and d.has("execution"):
			var item: String = {"farm": "wheat", "mill": "flour", "bakery": "bread"}[e.target]
			var expected: int = {"wheat": 8, "flour": 8, "bread": 12}[item] if e.day == 1 else sales.get(str(e.day - 1) + ":" + e.target + ":" + item, 0)
			valid = valid and d.proposal.forecast == expected and d.execution.cash_after == state.entities[e.target].money \
				and d.execution.output_stock_after == state.entities[e.target].inventory[item]
			for id in d.execution.work_event_ids:
				valid = valid and not plan_claims.has(id) and history[id - 1].action == "work_shift" and history[id - 1].target == e.target
				plan_claims[id] = true
		if not e.success:
			continue
		match e.action:
			"transfer_money":
				state.entities[e.actor].money -= d.amount
				state.entities[e.target].money += d.amount
				sources[e.id] = true
			"purchase":
				valid = valid and d.unit_price == {"wheat": 2, "flour": 4, "bread": 4}[d.item] and d.total_price == d.quantity * d.unit_price
				state.entities[e.actor].money -= d.total_price
				state.entities[e.target].money += d.total_price
				state.entities[e.actor].inventory[d.item] += d.quantity
				state.entities[e.target].inventory[d.item] -= d.quantity
				var key: String = str(e.day) + ":" + e.target + ":" + d.item
				sales[key] = sales.get(key, 0) + d.quantity
			"harvest":
				valid = valid and e.actor == "farm" and d.amount == 4
				state.entities[e.actor].inventory.wheat += d.amount
				sources[e.id] = true
			"produce":
				valid = valid and d.batches == 2 and d.inputs == ({"wheat": 4} if d.recipe == "mill" else {"flour": 4}) \
					and d.outputs == ({"flour": 4} if d.recipe == "mill" else {"bread": 6})
				for item in d.inputs:
					state.entities[e.actor].inventory[item] -= d.inputs[item]
				for item in d.outputs:
					state.entities[e.actor].inventory[item] += d.outputs[item]
				sources[e.id] = true
			"work_shift":
				work_receipts[e.id] = true
				var pay: Dictionary = history[d.payment_event_id - 1]
				var output: Dictionary = history[d.production_event_id - 1]
				valid = valid and not worked.has(e.actor) and d.wage == 8 and d.labor == 1 \
					and pay.action == "transfer_money" and pay.actor == e.target and pay.target == e.actor and pay.details.amount == 8 \
					and output.actor == e.target and not claimed.has(pay.id) and not claimed.has(output.id)
				worked[e.actor] = true
				claimed[pay.id] = true
				claimed[output.id] = true
			"consume":
				valid = valid and d.amount == 1
				state.entities[e.actor].inventory.bread -= 1
			"initialize", "day_started", "labor_environment", "shift_offered", "labor_decision", "employer_plan":
				pass
			_:
				valid = false
		var money: int = 0
		for entity in state.entities.values():
			money += entity.money
			valid = valid and entity.money >= 0 and entity.money <= 1_000_000_000
			for amount in entity.inventory.values():
				valid = valid and amount >= 0 and amount <= 1_000_000_000
		valid = valid and money == 432
	return valid and sources == claimed and work_receipts == plan_claims and state.entities == final.entities


static func run(suite: SceneTree) -> void:
	var simulation = Runner.new(42)
	suite._check(simulation.world.snapshot() == Reference.new(42).world.snapshot(), "M12 starts with exactly M11's world and no new endowments")
	simulation.world.advance_day()
	var obs: Dictionary = simulation.world.observe("ada", "farm")
	var p: Dictionary = Policy.decide(obs)
	suite._check(p.forecast == 8 and p.workers == ["ada", "dain"] and p.planned_output == 8, "one-time forecast starts two owner-first farming shifts")
	obs.day = 2
	obs.business.history.sold.wheat = 0
	suite._check(Policy.decide(obs).planned_shifts == 0, "zero realized sales never restore a startup target")
	obs.business.history.sold.wheat = 4
	suite._check(Policy.decide(obs).workers == ["ada"], "lower realized demand needs only the owner")
	obs.business.inventory.wheat = 4
	suite._check(Policy.decide(obs).reason == "unsold_inventory_covers_forecast", "owned unsold stock replaces new production")
	obs.business.inventory.wheat = 0
	obs.business.money = 7
	suite._check(Policy.decide(obs).planned_shifts == 0 and "insufficient_operating_funds" in Policy.decide(obs).reductions, "no unfunded shift or management wage is proposed")
	obs.business.money = 8
	obs.business.output_target = 999999
	suite._check(Policy.decide(obs).planned_shifts == 1, "historical output targets cannot become hidden demand floors")
	var mill: Dictionary = simulation.world.observe("bram", "mill")
	suite._check(Policy.decide(mill).planned_shifts == 0 and "insufficient_inputs" in Policy.decide(mill).reductions, "missing public stock cannot be fabricated for a planned mill shift")
	for offer in mill.offers:
		if offer.item == "wheat":
			offer.stock = 8
	mill.business.money = 31
	suite._check(Policy.decide(mill).planned_shifts == 1 and Policy.decide(mill).input_cost == 8, "joint input/payroll cost reduces a 32-coin two-shift plan")
	mill.business.money = 32
	suite._check(Policy.decide(mill).planned_shifts == 2 and Policy.decide(mill).input_cost == 16, "exact input and payroll budget permits two shifts")
	var before: Dictionary = simulation.world.snapshot()
	suite._check(not simulation.world.execute_plan("dain", "farm", p) and simulation.world.snapshot() == before, "employee cannot spend the employer's funds by submitting a plan")
	var invalid: Dictionary = p.duplicate(true)
	invalid.workers = ["ada", "ada"]
	suite._check(not simulation.world.execute_plan("ada", "farm", invalid) and simulation.world.snapshot() == before, "duplicate labor plan rejects before economic mutation")
	invalid = p.duplicate(true)
	invalid.workers = ["bram"]
	suite._check(not simulation.world.execute_plan("ada", "farm", invalid) and simulation.world.snapshot() == before, "unrelated worker cannot be hired through a forged plan")
	# The synthetic public-stock observation was stale; actual stock remains zero.
	suite._check(not simulation.world.execute_plan("bram", "mill", Policy.decide(mill)) and simulation.world.snapshot() == before,
		"stale input offers fail through native authority without free goods, labor or refunds")
	var initial: Dictionary = Reference.Reference.initial()
	LaborTests._entity(initial, "farm").money = 7
	var poor = Runner.new(42, initial)
	poor.world.advance_day()
	before = poor.world.snapshot()
	suite._check(not poor.world.execute_plan("ada", "farm", p) and poor.world.snapshot() == before, "authority recomputes actual payroll instead of trusting a stale plan budget")
	initial = Reference.Reference.initial()
	LaborTests._entity(initial, "dain").skills = ["miller"]
	var changed_skill = Runner.new(42, initial)
	changed_skill.world.advance_day()
	var complete: bool = changed_skill.world.execute_plan("ada", "farm", p)
	var partial: Dictionary = changed_skill.world.events().back().details
	suite._check(not complete and partial.outcome == "partial" and partial.execution.work_event_ids.size() == 1
		and changed_skill.world.snapshot().entities.farm.inventory.wheat == 4
		and changed_skill.world.snapshot().entities.ada.money == 14 and changed_skill.world.snapshot().entities.dain.money == 6
		and ledger_ok(changed_skill.world.events(), changed_skill.world.snapshot()), "partial execution preserves and audits real earlier work without fabricating the missing shift or refunding it")
	initial = Reference.Reference.initial()
	LaborTests._entity(initial, "finn").money = 999
	LaborTests._entity(initial, "bakery").money = 888
	LaborTests._entity(initial, "bakery").inventory.flour = 777
	var private_world = Runner.new(42, initial)
	private_world.world.advance_day()
	var clean = Runner.new(42)
	clean.world.advance_day()
	suite._check(clean.world.observe("ada", "farm") == private_world.world.observe("ada", "farm")
		and clean.world.observe("dain", "farm").business.is_empty(), "observations exclude unrelated private cash/ingredients and employer history from employees")
	var two = Runner.new(42)
	two.run(2)
	var r: Dictionary = two.report()
	suite._check(r.totals.consumed.bread == 18 and r.shifts.paid == 12 and r.employers.first_unmet_meal_day == 2
		and r.final.entities.bakery.inventory.bread == 6, "repeated owner-first staffing causes day-two financial exclusion despite actual bread")
	var history: Array = two.world.events()
	var last_day: Dictionary = two.world.observe("cora", "bakery").business.history
	suite._check(last_day.day == 1 and last_day.sold.bread == 12 and last_day.bought.flour == 8,
		"own history contains completed previous-day sales/purchases, not current/future transactions")
	two.world.advance_day()
	suite._check(two.world.observe("cora", "bakery").business.history.sold.bread == 6,
		"next-day history responds to realized market sales rather than reference quantities")
	for days in [2, 30, 365]:
		var first = Runner.new(42)
		var replay = Runner.new(42)
		first.run(days)
		@warning_ignore("integer_division")
		var split: int = days / 2
		replay.run(split)
		replay.run(days - split)
		suite._check(first.world.events() == replay.world.events() and first.world.snapshot() == replay.world.snapshot() and first.report() == replay.report(),
			"M12 %dd full ledger/state/report split replay" % days)
		suite._check(ledger_ok(first.world.events(), first.world.snapshot()), "M12 %dd every-event currency/resources, funded unique labor and final reconciliation" % days)
		r = first.report()
		var cash_ok: bool = r.money.final == 432
		for id in r.accounts:
			cash_ok = cash_ok and r.final.entities[id].money == r.initial.entities[id].money + r.accounts[id].earned - r.accounts[id].spent
		suite._check(cash_ok and r.final.employment == r.initial.employment and r.totals.consumed.bread + _missed(r.unmet_meals) == days * 12,
			"M12 %dd cash flows, unchanged employment and all met/unmet needs reconcile" % days)
		print("M12 employer choice: days=%d meals=%d missed=%d shifts=%d currency=%d" % [days, r.totals.consumed.bread, _missed(r.unmet_meals), r.shifts.paid, r.money.final])
	var other_seed = Runner.new(99)
	other_seed.run(2)
	suite._check(history == other_seed.world.events(), "M12 policy and fixed opportunities use no randomness")


static func _missed(values: Dictionary) -> int:
	var total: int = 0
	for value in values.values():
		total += value
	return total
