extends "res://scripts/sim/profitable_runner.gd"
## Prescribed M15 references; all new facts and movements go through world commands.
const Enterprise = preload("res://scripts/sim/enterprise_config.gd")
const EnterpriseWorld = preload("res://scripts/sim/enterprise_world.gd")
var _case: String
var _report_accounts: Dictionary = {}
var _checkpoints: Dictionary = {}


func _init(seed_value: int = 42, initial: Dictionary = Enterprise.initial(), experiment: String = "A") -> void:
	super(seed_value)
	world = EnterpriseWorld.new(seed_value, initial)
	_initial = world.snapshot()
	_case = experiment


func run(days: int) -> void:
	assert(_case == "A" and days >= 0)
	for _index in days:
		world.advance_day()
		for business in Config.BUSINESS_ORDER:
			var firm: Dictionary = _initial.businesses[business]
			var workers: Array = firm.employees.duplicate()
			workers.sort()
			var input: String = Config.INDUSTRIES[firm.industry].input
			for worker in workers:
				if not input.is_empty():
					world.purchase(business, "farm" if input == "wheat" else "mill", input, 4, Terms.Reference.PRICES[input])
				if world.offer_shift(firm.owner, business, worker):
					world.work_shift(worker, business)
		for actor in participant_ids():
			world.purchase(actor, "bakery", "bread", 1, 4)
		for _visitor in 6:
			world.purchase("visitors", "bakery", "bread", 1, 4)
		for actor in participant_ids():
			world.consume(actor)
		world.consume_external("visitors")
		for business in Config.BUSINESS_ORDER:
			world.settle_profit(_initial.businesses[business].owner, business)
		world.close_contract_day()


func _report_entities() -> Dictionary:
	return _initial.entities if _report_accounts.is_empty() else _report_accounts


func _report_businesses() -> Dictionary:
	return world.snapshot().businesses


func _report_employment() -> Dictionary:
	return _initial.employment.merged(world.snapshot().employment, true)


func _reference_verification(history: Array, final: Dictionary) -> Dictionary:
	return preload("res://scripts/sim/enterprise_audit.gd").verify(history, final, _case == "A" and _initial.entities.visitors.money == 8760)


func report() -> Dictionary:
	_report_accounts = _initial.entities.duplicate(true)
	for id in world.snapshot().entities:
		if not _report_accounts.has(id):
			_report_accounts[id] = world.snapshot().entities[id].duplicate(true)
			_report_accounts[id].money = 0
			_report_accounts[id].inventory = {"wheat": 0, "flour": 0, "bread": 0}
	var summary: Dictionary = super()
	summary.scenario = "settlement_external_trade_reference" if _case == "A" else "enterprise_fixture_" + _case.to_lower()
	summary.schedule.workers = "all three existing employees daily; managers never work" if _case == "A" else "prescribed fixture transitions and actual owner/employee shifts"
	summary.schedule["external_sales"] = "six one-loaf attempts after resident purchases" if _case == "A" else "specified existing buyer only"
	if _case != "A":
		summary.erase("potential")
	summary.profitable.mode = "M15 prescribed " + _case
	summary.profitable.erase("capital_floor")
	summary.profitable.household_cycle_days = null
	for account in summary.accounts.values():
		for key in ["capital_contributions_paid", "capital_contributions_received", "capital_asset_purchases", "asset_sale_receipts", "owner_shifts"]:
			account[key] = 0
	var visitors_bought: int = 0
	var external_rejections: int = 0
	var owner_shifts: int = 0
	for e in world.events():
		if e.action == "purchase" and summary.final.entities[e.actor].kind == "external":
			visitors_bought += e.details.quantity if e.success else 0
			external_rejections += 0 if e.success else 1
		if not e.success:
			continue
		if e.action == "consume" and summary.final.entities[e.actor].kind == "external":
			# The historical household report counts one meal per command. Visitors
			# consume several purchased loaves at once and have no household need.
			summary.accounts[e.actor].consumed += e.details.amount - 1
		elif e.action == "capital_contribution":
			summary.accounts[e.actor].wages_paid -= e.details.amount
			summary.accounts[e.actor].capital_contributions_paid += e.details.amount
			summary.accounts[e.target].wages_received -= e.details.amount
			summary.accounts[e.target].capital_contributions_received += e.details.amount
		elif e.action == "asset_purchased" and e.details.price > 0:
			summary.accounts[e.target].wages_paid -= e.details.price
			summary.accounts[e.target].capital_asset_purchases += e.details.price
			summary.accounts[e.details.seller].wages_received -= e.details.price
			summary.accounts[e.details.seller].asset_sale_receipts += e.details.price
		elif e.action == "owner_work_shift":
			owner_shifts += 1
			summary.accounts[e.actor].owner_shifts += 1
			summary.accounts[e.target].owner_shifts += 1
	var village: int = 0
	var external: int = 0
	var meals: int = 0
	for id in summary.final.entities:
		if summary.final.entities[id].kind == "external":
			external += summary.final.entities[id].money
		else:
			village += summary.final.entities[id].money
		if summary.final.entities[id].kind == "resident":
			meals += summary.accounts[id].consumed
	summary["open_economy"] = {"experiment": _case, "village_money": village, "external_money": external,
		"combined_money": village + external, "resident_meals": meals, "visitor_bread": visitors_bought,
		"external_purchase_rejections": external_rejections, "unpaid_owner_shifts": owner_shifts,
		"additional_paid_shifts": summary.shifts.paid - summary.profitable.contracts.completed if _case == "A" else 0,
		"retained_earnings": {}, "operational": {}, "fixture_checkpoints": _checkpoints.duplicate(true)}
	for business in summary.final.businesses:
		summary.open_economy.retained_earnings[business] = world.profit_budget(business).realized_remaining
		summary.open_economy.operational[business] = world._asset_error(business).is_empty()
	return summary
