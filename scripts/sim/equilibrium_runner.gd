extends "res://scripts/sim/labor_runner.gd"
## Prescribed feasibility reference, not an autonomous economic policy.

const Reference = preload("res://scripts/sim/equilibrium_config.gd")
const ReferenceWorld = preload("res://scripts/sim/equilibrium_world.gd")


func _init(seed_value: int = 42) -> void:
	var initial: Dictionary = Reference.initial()
	super(seed_value, initial)
	world = ReferenceWorld.new(seed_value, initial)
	_initial = world.snapshot()


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		var day: int = world.snapshot().day
		for business in Config.BUSINESS_ORDER:
			var firm: Dictionary = _initial.businesses[business]
			var input: String = Config.INDUSTRIES[firm.industry].input
			if not input.is_empty():
				var seller: String = "farm" if input == "wheat" else "mill"
				world.purchase(business, seller, input, 8, Reference.PRICES[input])
			for worker in Reference.workers(firm, day):
				world.offer_shift(firm.owner, business, worker)
				world.work_shift(worker, business)
		for actor in participant_ids():
			world.purchase(actor, "bakery", "bread", 1, Reference.PRICES.bread)
		for actor in participant_ids():
			world.consume(actor)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "settlement_equilibrium_reference"
	summary.prices = Reference.PRICES.duplicate()
	# M9's potential calculation includes its initial commodity buffers; ours are zero.
	summary.potential.bread_including_initial_bound = summary.days * 24
	summary["reference"] = {"mode": "prescribed decisions; feasibility only, not autonomous stability",
		"wage": Reference.WAGE, "harvest_per_shift": Reference.HARVEST,
		"daily_production": {"wheat": 8, "flour": 8, "bread": 12}, "daily_shifts": 6,
		"groups": {}, "household_cycle_days": 2, "business_cycle_days": 1}
	for business in Config.BUSINESS_ORDER:
		summary.reference.groups[business] = {"odd_days": Reference.workers(_initial.businesses[business], 1),
			"even_days": Reference.workers(_initial.businesses[business], 2)}
	summary.reference["ledger_sha256"] = JSON.stringify(world.events(), "", true).sha256_text()
	return summary
