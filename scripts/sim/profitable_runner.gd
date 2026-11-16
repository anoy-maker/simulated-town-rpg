extends "res://scripts/sim/labor_runner.gd"
## Prescribed M14 schedule. No forecasts, target offsets, hiring or owner production.

const Terms = preload("res://scripts/sim/profitable_config.gd")
const ProfitableWorld = preload("res://scripts/sim/profitable_world.gd")


func _init(seed_value: int = 42, initial: Dictionary = Terms.initial()) -> void:
	super(seed_value)
	world = ProfitableWorld.new(seed_value, initial)
	_initial = world.snapshot()


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		for business in Config.BUSINESS_ORDER:
			var firm: Dictionary = _initial.businesses[business]
			var input: String = Config.INDUSTRIES[firm.industry].input
			for worker in Terms.workers(firm, world.snapshot().day):
				if not input.is_empty():
					var missing: int = maxi(0, 4 - world.snapshot().entities[business].inventory[input])
					if missing > 0:
						world.purchase(business, "farm" if input == "wheat" else "mill", input, missing, Terms.Reference.PRICES[input])
				if world.offer_shift(firm.owner, business, worker):
					world.work_shift(worker, business)
		for actor in participant_ids():
			world.purchase(actor, "bakery", "bread", 1, Terms.Reference.PRICES.bread)
		for actor in participant_ids():
			world.consume(actor)
		for business in Config.BUSINESS_ORDER:
			world.settle_profit(_initial.businesses[business].owner, business)
		world.close_contract_day()


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "settlement_profitable_reference"
	summary.prices = Terms.Reference.PRICES.duplicate()
	summary.schedule.workers = "prescribed two of three employees; managers never work"
	summary.potential = {"labor_shifts": summary.days * 9, "wheat": summary.days * 12,
		"milling_flour_capacity": summary.days * 12, "baking_bread_capacity": summary.days * 18,
		"bread_including_initial_bound": summary.days * 18, "meal_needs": summary.days * 12}
	var contracts = {"due": 0, "attempted": 0, "completed": 0, "breaches": 0, "expected_compensation": 0, "paid_compensation": 0,
		"by_employee": {}, "breach_reasons": {}}
	var income = {"transactions": 0, "amount": 0, "rejected": 0}
	for account in summary.accounts.values():
		account["profit_distributions_received"] = 0
		account["profit_distributions_paid"] = 0
	for worker in _initial.employment:
		contracts.by_employee[worker] = {"due": 0, "attempted": 0, "completed": 0, "breaches": 0, "expected_compensation": 0, "paid_compensation": 0}
	var days: Array = []
	var history: Array = world.events()
	for e in history:
		var d: Dictionary = e.details
		if e.action == "contract_shift":
			var row: Dictionary = contracts.by_employee[e.actor]
			for destination in [contracts, row]:
				destination.due += 1
				destination.attempted += 1 if d.attempted else 0
				destination.completed += 1 if e.success else 0
				destination.breaches += 0 if e.success else 1
				destination.expected_compensation += d.expected_compensation
				destination.paid_compensation += d.actual_compensation
			if not e.success:
				contracts.breach_reasons[d.reason] = contracts.breach_reasons.get(d.reason, 0) + 1
		if e.action == "profit_distribution":
			if not e.success:
				income.rejected += 1
				continue
			income.transactions += 1
			income.amount += d.amount
			# Native transfer already counted income/spending/circulation; classify it once.
			summary.accounts[e.actor].wages_received -= d.amount
			summary.accounts[e.actor].profit_distributions_received += d.amount
			summary.accounts[e.target].wages_paid -= d.amount
			summary.accounts[e.target].profit_distributions_paid += d.amount
		if e.action == "contract_day_closed" and days.size() < 3:
			days.append({"day": e.day, "business_cash": d.business_cash, "household_cash": d.household_cash,
				"goods": d.goods, "completed": d.completed, "breaches": d.breaches})
	for business in _initial.businesses:
		summary.business_activity[business].can_fund_one_shift = summary.final.entities[business].money >= Terms.WAGE
	for key in summary.failures.keys():
		if key.begins_with("contract_shift:") or key.begins_with("contract_attempt:"):
			summary.failures.erase(key)
	summary.notable_events = []
	for e in history:
		if not e.success and e.action not in ["contract_shift", "contract_attempt", "labor_decision"] and summary.notable_events.size() < 8:
			summary.notable_events.append(e)
	var verified: Dictionary = preload("res://scripts/sim/profitable_audit.gd").verify(history, summary.final)
	summary["profitable"] = {"mode": "prescribed reference; no autonomous scheduling", "wage": Terms.WAGE,
		"capital_floor": Terms.CAPITAL, "household_cycle_days": 3, "contracts": contracts,
		"distributions": income, "cash_results": summary.final.cash_results, "first_three_days": days,
		"verification": verified, "ledger_sha256": JSON.stringify(history, "", true).sha256_text()}
	return summary
