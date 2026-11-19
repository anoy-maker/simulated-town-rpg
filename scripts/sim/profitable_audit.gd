extends RefCounted
## Independent receipt reconstruction. Reference expectations are not used by authority.

const GROUPS = {
	"farm": [["dain", "gale"], ["dain", "edda"], ["edda", "gale"]],
	"mill": [["hale", "lyle"], ["hale", "jory"], ["jory", "lyle"]],
	"bakery": [["finn", "kira"], ["finn", "iona"], ["iona", "kira"]],
}


static func verify(history: Array, final: Dictionary) -> Dictionary:
	var initial: Dictionary = history[0].details.state
	var entities: Dictionary = initial.entities.duplicate(true)
	var books: Dictionary = initial.cash_results.duplicate(true)
	var total_money: int = 0
	for entity in entities.values():
		total_money += entity.money
	var checks = {"event_order": true, "currency_each_event": true, "bounded_accounts": true,
		"authorized_labor": true, "recipes_and_receipts": true, "contracts": true, "profit_accounting": true,
		"final_state": true}
	var reference = {"all_commands_succeed": true, "daily_production_meals_payments": true,
		"business_daily_cycle": true, "household_three_day_cycle": true, "employee_contract_cycle": true}
	var day: int = 0
	var days_checked: int = 0
	var closed: bool = true
	var due: Dictionary = {}
	var outcomes: Dictionary = {}
	var work_failures: Dictionary = {}
	var worked: Dictionary = {}
	var business_used: Dictionary = {}
	var meal_attempts: Dictionary = {}
	var paid_sources: Dictionary = {}
	var claimed: Dictionary = {}
	var before_payments: Dictionary = {}
	var before_offers: Dictionary = {}
	var phase_states: Dictionary = {0: _household_cash(entities)}
	var cycle_shifts: Dictionary = {}
	var production: Dictionary = {}
	var meals: int = 0
	var payroll: int = 0
	var distributions: int = 0
	for index in history.size():
		var e: Dictionary = history[index]
		var d: Dictionary = e.details
		checks.event_order = checks.event_order and e.id == index + 1
		reference.all_commands_succeed = reference.all_commands_succeed and e.success
		if e.action == "day_started":
			checks.contracts = checks.contracts and closed
			day += 1
			closed = false
			due.clear()
			outcomes.clear()
			work_failures.clear()
			worked.clear()
			business_used.clear()
			meal_attempts.clear()
			production = {"wheat": 0, "flour": 0, "bread": 0}
			meals = 0
			payroll = 0
			distributions = 0
		checks.event_order = checks.event_order and e.day == day
		if e.action == "consume" and d.get("amount") == 1 and entities.has(e.actor) and entities[e.actor].kind == "resident" \
				and d.get("reason", "") in ["", "insufficient_stock"]:
			meal_attempts[e.actor] = true
		if e.action == "shift_offered":
			before_offers[e.id] = {"cash": entities[e.target].money, "inventory": entities[e.target].inventory.duplicate()}
		if e.action == "work_shift" and not e.success:
			work_failures[e.target + ":" + e.actor] = d.reason
		if e.action == "contract_attempt":
			var command: Dictionary = history[d.command_event_id - 1]
			checks.contracts = checks.contracts and command.id == e.id - 1 and command.action == "shift_offered" \
				and command.actor == e.actor and command.target == e.target and command.success == e.success and d.reason == command.details.get("reason", "") \
				and d.constraints.cash == before_offers[command.id].cash and d.constraints.inventory == before_offers[command.id].inventory
		if e.action == "contract_shift":
			checks.contracts = checks.contracts and not outcomes.has(e.actor) and due.has(e.actor) and due[e.actor] == e.target \
				and d.contract_id == "%d:%s:%s" % [day, e.target, e.actor] and d.employer == initial.businesses[e.target].owner \
				and d.completed == e.success and d.expected_compensation == 6 and d.actual_compensation == (6 if e.success else 0)
			outcomes[e.actor] = e.success
			checks.contracts = checks.contracts and d.attempted == (d.attempt_event_id != null)
			if d.attempt_event_id != null:
				var attempt: Dictionary = history[d.attempt_event_id - 1]
				checks.contracts = checks.contracts and attempt.action == "contract_attempt" and attempt.day == day \
					and attempt.actor == d.employer and attempt.target == e.target and attempt.details.worker == e.actor and attempt.details.authorized_attempt
			if e.success:
				var shift: Dictionary = history[d.shift_event_id - 1]
				checks.contracts = checks.contracts and worked.get(e.actor) == shift.id and shift.success and shift.actor == e.actor and shift.target == e.target
			else:
				var why: String = "employer_did_not_schedule"
				if d.attempted:
					var attempt: Dictionary = history[d.attempt_event_id - 1]
					why = work_failures.get(e.target + ":" + e.actor, attempt.details.reason if not attempt.success else "offered_not_completed")
				checks.contracts = checks.contracts and not worked.has(e.actor) and d.shift_event_id == null and d.reason == why
		if e.success:
			match e.action:
				"purchase":
					checks.recipes_and_receipts = checks.recipes_and_receipts and d.quantity > 0 and d.unit_price == {"wheat": 2, "flour": 4, "bread": 4}[d.item] \
						and d.total_price == d.quantity * d.unit_price
					entities[e.actor].money -= d.total_price
					entities[e.target].money += d.total_price
					entities[e.actor].inventory[d.item] += d.quantity
					entities[e.target].inventory[d.item] -= d.quantity
					books[e.target].sales += d.total_price
					if books.has(e.actor):
						books[e.actor].inputs += d.total_price
				"transfer_money":
					before_payments[e.id] = {"cash": entities[e.actor].money, "book": books[e.actor].duplicate()}
					entities[e.actor].money -= d.amount
					entities[e.target].money += d.amount
					if e.target == initial.businesses[e.actor].owner:
						books[e.actor].distributions += d.amount
						distributions += d.amount
					else:
						books[e.actor].payroll += d.amount
						payroll += d.amount
					paid_sources[e.id] = true
				"harvest", "produce":
					var inputs: Dictionary = {} if e.action == "harvest" else d.inputs
					var outputs: Dictionary = {"wheat": d.amount} if e.action == "harvest" else d.outputs
					checks.recipes_and_receipts = checks.recipes_and_receipts and (e.actor == "farm" and d.amount == 4 if e.action == "harvest" else d.batches == 2 \
						and inputs == ({"wheat": 4} if e.actor == "mill" else {"flour": 4}) and outputs == ({"flour": 4} if e.actor == "mill" else {"bread": 6}))
					for item in inputs:
						entities[e.actor].inventory[item] -= inputs[item]
					for item in outputs:
						entities[e.actor].inventory[item] += outputs[item]
						production[item] += outputs[item]
					paid_sources[e.id] = true
				"work_shift":
					var firm: Dictionary = initial.businesses[e.target]
					var job: Dictionary = initial.employment.get(e.actor, {})
					checks.authorized_labor = checks.authorized_labor and e.actor in GROUPS[e.target][(day - 1) % 3] and e.actor != firm.owner \
						and not worked.has(e.actor) and business_used.get(e.target, 0) < firm.assets.daily_slots and job.get("active", false) and job.get("business") == e.target \
						and firm.industry in entities[e.actor].skills and d.wage == 6 and d.labor == 1
					var pay: Dictionary = history[d.payment_event_id - 1]
					var output: Dictionary = history[d.production_event_id - 1]
					checks.recipes_and_receipts = checks.recipes_and_receipts and pay.id == e.id - 2 and output.id == e.id - 1 \
						and pay.success and pay.action == "transfer_money" and pay.actor == e.target and pay.target == e.actor and pay.details.amount == 6 \
						and output.success and output.actor == e.target and output.action in ["harvest", "produce"] \
						and not claimed.has(pay.id) and not claimed.has(output.id)
					claimed[pay.id] = true
					claimed[output.id] = true
					worked[e.actor] = e.id
					business_used[e.target] = business_used.get(e.target, 0) + 1
					cycle_shifts[e.actor] = cycle_shifts.get(e.actor, 0) + 1
				"consume":
					entities[e.actor].inventory.bread -= d.amount
					meals += d.amount
				"profit_distribution":
					var pay: Dictionary = history[d.payment_event_id - 1]
					var before: Dictionary = before_payments[pay.id]
					var book: Dictionary = before.book
					var realized: int = book.sales - book.inputs - book.payroll - book.distributions
					var eligible: int = maxi(0, mini(realized, before.cash - 120))
					checks.profit_accounting = checks.profit_accounting and initial.businesses[e.target].owner == e.actor and meal_attempts.size() == 12 \
						and pay.id == e.id - 1 and pay.success and pay.action == "transfer_money" and pay.actor == e.target and pay.target == e.actor \
						and pay.details.amount == d.amount and d.amount == eligible and eligible > 0 and d.capital_floor == 120 \
						and d.cumulative_before == book and d.realized_before == realized and d.cash_before == before.cash \
						and d.business_cash_after == entities[e.target].money and entities[e.target].money >= 120 and not claimed.has(pay.id)
					claimed[pay.id] = true
				"contract_due":
					checks.contracts = checks.contracts and e.actor in GROUPS[e.target][(day - 1) % 3] and not due.has(e.actor) and d.expected_compensation == 6 \
						and d.contract_id == "%d:%s:%s" % [day, e.target, e.actor] and d.employer == initial.businesses[e.target].owner and d.phase == (day - 1) % 3 + 1
					due[e.actor] = e.target
				"contract_day_closed":
					closed = true
					days_checked += 1
					var completed: int = outcomes.values().count(true)
					checks.contracts = checks.contracts and due.size() == 6 and outcomes.size() == 6 and d.due == 6 and d.completed == completed and d.breaches == 6 - completed
					var goods = {"wheat": 0, "flour": 0, "bread": 0}
					var business_cash: Dictionary = {}
					for id in entities:
						if entities[id].kind == "business":
							business_cash[id] = entities[id].money
						for item in goods:
							goods[item] += entities[id].inventory[item]
					checks.final_state = checks.final_state and d.business_cash == business_cash and d.household_cash == _household_cash(entities) and d.goods == goods and d.cash_results == books
					reference.daily_production_meals_payments = reference.daily_production_meals_payments and completed == 6 and worked.size() == 6 \
						and production == {"wheat": 8, "flour": 8, "bread": 12} and meals == 12 and payroll == 36 and distributions == 12
					for id in entities:
						reference.business_daily_cycle = reference.business_daily_cycle and entities[id].inventory == {"wheat": 0, "flour": 0, "bread": 0}
						if entities[id].kind == "business":
							reference.business_daily_cycle = reference.business_daily_cycle and entities[id].money == 120
					var phase: int = day % 3
					var households: Dictionary = _household_cash(entities)
					for id in households:
						var expected: int = 6
						if initial.employment.has(id) and phase == 1:
							expected = 8 if worked.has(id) else 2
						elif initial.employment.has(id) and phase == 2:
							expected = 10 if id in ["dain", "hale", "finn"] else 4
						reference.household_three_day_cycle = reference.household_three_day_cycle and households[id] == expected
					if not phase_states.has(phase):
						phase_states[phase] = households
					reference.household_three_day_cycle = reference.household_three_day_cycle and households == phase_states[phase]
					if phase == 0:
						for worker in initial.employment:
							reference.employee_contract_cycle = reference.employee_contract_cycle and cycle_shifts.get(worker, 0) == 2
						cycle_shifts.clear()
				"initialize", "day_started", "labor_environment", "shift_offered", "contract_attempt", "contract_shift":
					pass
				_:
					checks.event_order = false
		var money: int = 0
		for entity in entities.values():
			money += entity.money
			checks.bounded_accounts = checks.bounded_accounts and entity.money >= 0 and entity.money <= 1_000_000_000
			for amount in entity.inventory.values():
				checks.bounded_accounts = checks.bounded_accounts and amount >= 0 and amount <= 1_000_000_000
		checks.currency_each_event = checks.currency_each_event and money == total_money
	checks.recipes_and_receipts = checks.recipes_and_receipts and paid_sources == claimed
	checks.final_state = checks.final_state and entities == final.entities and books == final.cash_results and closed == final.contract_day_closed
	checks.contracts = checks.contracts and days_checked == day
	return {"accounting": checks, "reference": reference, "days_checked": days_checked}


static func _household_cash(entities: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id in entities:
		if entities[id].kind == "resident":
			result[id] = entities[id].money
	return result
