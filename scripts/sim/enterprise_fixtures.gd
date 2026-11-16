extends RefCounted
## Explicit transaction fixtures, not autonomous choices or complete village runs.
const Runner = preload("res://scripts/sim/external_trade_runner.gd")
const Config = preload("res://scripts/sim/enterprise_config.gd")
const BUSINESS = "finn_bakery"


static func _must(result: bool) -> void:
	assert(result)


static func checkpoint(simulation, label: String) -> void:
	var state: Dictionary = simulation.world.snapshot()
	simulation._checkpoints[label] = {"event_id": simulation.world.events().size(), "owner_cash": state.entities.finn.money,
		"business_cash": state.entities[BUSINESS].money, "book": state.cash_results[BUSINESS].duplicate(true),
		"assets": {"spare_oven": state.productive_assets.spare_oven.holder, "spare_workshop": state.productive_assets.spare_workshop.holder}}


static func startup() -> RefCounted:
	var simulation = Runner.new(42, Config.initial(100, true), "B")
	var w = simulation.world
	_must(w.found_business("finn", BUSINESS, "baker", 300))
	_must(w.buy_asset("finn", BUSINESS, "spare_oven"))
	_must(w.buy_asset("finn", BUSINESS, "spare_workshop"))
	checkpoint(simulation, "after_startup")
	_must(w.request_resignation("finn", "bakery"))
	_must(w.request_resignation("iona", "bakery"))
	w.advance_day()
	_must(w.start_self_employment("finn", BUSINESS))
	return simulation


static func owner_sale(sell: bool = true) -> RefCounted:
	var simulation = startup()
	var w = simulation.world
	_must(w.purchase(BUSINESS, "mill", "flour", 4, 4))
	_must(w.owner_work_shift("finn", BUSINESS))
	if sell:
		_must(w.purchase("visitors", BUSINESS, "bread", 6, 4))
		_must(w.consume_external("visitors"))
	w.close_contract_day()
	checkpoint(simulation, "after_owner_sale" if sell else "after_unsold_production")
	return simulation


static func delegation() -> RefCounted:
	var simulation = owner_sale()
	simulation._case = "C"
	var w = simulation.world
	_must(w.post_job("finn", BUSINESS, "baker_job", 6, 0, 3, 3))
	_must(w.apply_for_job("iona", "baker_job"))
	_must(w.make_job_offer("finn", "baker_job:iona"))
	_must(w.accept_job_offer("iona", "baker_job:iona"))
	_must(w.request_resignation("finn", BUSINESS))
	w.advance_day()
	_must(w.purchase(BUSINESS, "mill", "flour", 4, 4))
	_must(w.offer_shift("finn", BUSINESS, "iona"))
	_must(w.work_shift("iona", BUSINESS))
	_must(w.purchase("visitors", BUSINESS, "bread", 6, 4))
	_must(w.consume_external("visitors"))
	w.close_contract_day()
	checkpoint(simulation, "after_employee_sale")
	return simulation
