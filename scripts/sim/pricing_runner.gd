extends "res://scripts/sim/external_trade_runner.gd"
## Four prescribed M15 production schedules differing only in quote/buyer policies.
const PricingWorld = preload("res://scripts/sim/pricing_world.gd")
const ENABLED = {"A": [], "B": ["bakery"], "C": ["mill", "bakery"], "D": ["farm", "mill", "bakery"]}
var stage: String


func _init(seed_value: int = 42, activation: String = "A", initial: Dictionary = Enterprise.initial()) -> void:
	assert(activation in ENABLED)
	super(seed_value, initial)
	world = PricingWorld.new(seed_value, initial)
	_initial = world.snapshot()
	stage = activation


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		for business in Config.BUSINESS_ORDER:
			world.execute_pricing(_initial.businesses[business].owner, business, "rational_pricing" if business in ENABLED[stage] else "fixed")
		for business in Config.BUSINESS_ORDER:
			var firm: Dictionary = _initial.businesses[business]
			var workers: Array = firm.employees.duplicate()
			workers.sort()
			var input: String = Config.INDUSTRIES[firm.industry].input
			for worker in workers:
				if not input.is_empty():
					world.buy_from_market(business, input, 4)
				if world.offer_shift(firm.owner, business, worker):
					world.work_shift(worker, business)
		for actor in participant_ids():
			world.buy_from_market(actor, "bread", 1)
		for _visitor in 6:
			world.buy_from_market("visitors", "bread", 1)
		for actor in participant_ids():
			world.consume(actor)
		world.consume_external("visitors")
		for business in Config.BUSINESS_ORDER:
			world.settle_profit(_initial.businesses[business].owner, business)
		world.close_contract_day()


func _reference_verification(history: Array, final: Dictionary) -> Dictionary:
	return preload("res://scripts/sim/pricing_audit.gd").verify(history, final)


func report() -> Dictionary:
	var r: Dictionary = super()
	r.scenario = "pricing_competition_fixture" if stage == "competition_fixture" else "settlement_pricing"
	if stage == "competition_fixture":
		r.erase("potential")
		r.schedule.workers = "no productive work; two finite initial bakery stocks"
		r.schedule.external_sales = "not exercised in the competition fixture"
	r.prices = "seller-specific versioned quotes"
	r.profitable.mode = "M16 prescribed production, " + stage + " price activation"
	r.schedule["pricing"] = "chain order before any production; prior-day observations only"
	r["pricing"] = preload("res://scripts/sim/pricing_report.gd").build(world.events(), r.final, stage)
	return r
