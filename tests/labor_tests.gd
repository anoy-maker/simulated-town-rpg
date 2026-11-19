extends RefCounted

const World = preload("res://scripts/sim/labor_world.gd")
const Runner = preload("res://scripts/sim/labor_runner.gd")
const Config = preload("res://scripts/sim/labor_config.gd")
const Policy = preload("res://scripts/sim/labor_policy.gd")


static func _entity(initial: Dictionary, id: String) -> Dictionary:
	for entity in initial.entities:
		if entity.id == id:
			return entity
	return {}


static func _unchanged(suite: SceneTree, world: RefCounted, command: Callable, reason: String) -> void:
	var before: Dictionary = world.snapshot()
	var result: bool = command.call()
	suite._check(not result and world.snapshot() == before and world.events().back().details.reason == reason,
		"M9 rejects " + reason + " without changing funds, goods, offers or labor")


static func run(suite: SceneTree) -> void:
	var config: Dictionary = Config.initial()
	var world = World.new(42, config)
	suite._check(world.snapshot().entities.size() == 15 and world.snapshot().employment.size() == 9,
		"M9 has twelve people, three separately owned accounts and nine explicit employment records")
	config.businesses.farm.owner = "dain"
	var copy: Dictionary = world.snapshot()
	copy.businesses.farm.employees.clear()
	copy.entities.farm.money = 0
	suite._check(world.snapshot().businesses.farm.owner == "ada" and world.snapshot().businesses.farm.employees.size() == 3
		and world.snapshot().entities.farm.money == 120, "business construction and snapshots isolate ownership and funds")
	_unchanged(suite, world, func(): return world.work_shift("dain", "farm"), "no_work_day")
	world.advance_day()
	_unchanged(suite, world, func(): return world.offer_shift("dain", "farm", "dain"), "not_owner")
	_unchanged(suite, world, func(): return world.offer_shift("ada", "missing", "dain"), "unknown_business")
	_unchanged(suite, world, func(): return world.offer_shift("ada", "farm", "missing"), "unknown_worker")
	_unchanged(suite, world, func(): return world.offer_shift("ada", "farm", "finn"), "not_employed")
	_unchanged(suite, world, func(): return world.work_shift("dain", "farm"), "no_shift_offer")
	suite._check(world.offer_shift("ada", "farm", "dain"), "an owner can offer a funded shift to their skilled laborer")
	_unchanged(suite, world, func(): return world.offer_shift("ada", "farm", "dain"), "duplicate_offer")
	var before: Dictionary = world.snapshot()
	suite._check(world.work_shift("dain", "farm"), "a laborer can use farmer skill independently of occupation")
	var after: Dictionary = world.snapshot()
	suite._check(after.entities.farm.money == before.entities.farm.money - 3 and after.entities.dain.money == before.entities.dain.money + 3
		and after.entities.farm.inventory.wheat == before.entities.farm.inventory.wheat + before.harvest_opportunities.dain
		and after.labor_used.dain == 1 and after.business_labor.farm == 1, "a paid full shift creates only the permitted harvest in business stock")
	var receipt: Dictionary = world.events().back().details
	suite._check(world.events()[receipt.payment_event_id - 1].action == "transfer_money"
		and world.events()[receipt.production_event_id - 1].action == "harvest", "work annotation links native payroll and production receipts")
	_unchanged(suite, world, func(): return world.work_shift("dain", "farm"), "daily_labor_limit")
	_unchanged(suite, world, func(): return world.harvest("farm", 6), "paid_labor_required")
	_unchanged(suite, world, func(): return world.produce("mill", "mill", 2), "paid_labor_required")
	_unchanged(suite, world, func(): return world.transfer_money("farm", "ada", 3), "payroll_only")
	_unchanged(suite, world, func(): return world.transfer_item("bakery", "cora", "bread", 1), "market_only")
	_unchanged(suite, world, func(): return world.consume("bakery"), "not_resident")
	suite._check(world.consume("dain"), "worker eats only personal real bread")
	_unchanged(suite, world, func(): return world.consume("dain"), "no_meal_due")
	world.advance_day()
	suite._check(world.snapshot().labor_used.is_empty() and world.snapshot().offers.is_empty()
		and world.offer_shift("ada", "farm", "dain"), "new day resets capacity and expires old offers")
	_test_boundaries(suite)
	_test_decisions(suite)
	var first = Runner.new(42)
	var split = Runner.new(42)
	first.run(30)
	split.run(12)
	split.run(18)
	suite._check(first.world.snapshot() == split.world.snapshot() and first.world.events() == split.world.events()
		and first.report() == split.report(), "M9 full state, labor, RNG and report preserve split deterministic replay")
	var report: Dictionary = first.report()
	suite._check(report.money.initial == 432 and report.money.final == 432 and report.shifts.paid <= 360
		and report.totals.consumed.bread + _sum(report.unmet_meals) == 360, "M9 conserved funds, bounded labor and all household meal needs reconcile")
	suite._check(report.failures == {"consume:insufficient_stock": _sum(report.unmet_meals)},
		"M9 failed decisions do not duplicate their authoritative economic failures")
	var zero = Runner.new(42)
	suite._check(zero.report().initial == zero.report().final and zero.report().potential.bread_including_initial_bound == 18,
		"zero-day report contains real initial bread without fictional processing")
	var isolated: Dictionary = first.report()
	isolated.accounts.ada.wages_received = -1
	suite._check(first.report().accounts.ada.wages_received >= 0, "labor report cannot mutate state or later projections")


static func _sum(values: Dictionary) -> int:
	var total: int = 0
	for amount in values.values():
		total += amount
	return total


static func _test_boundaries(suite: SceneTree) -> void:
	for failure in ["missing_skill", "unfunded_payroll", "worker_money_limit", "insufficient_inputs", "output_limit", "workplace_capacity", "not_employed"]:
		var initial: Dictionary = Config.initial()
		var worker: String = "hale"
		match failure:
			"missing_skill": _entity(initial, worker).skills = ["farmer"]
			"unfunded_payroll": _entity(initial, "mill").money = 2
			"worker_money_limit": _entity(initial, worker).money = World.MAX_AMOUNT - 2
			"insufficient_inputs": _entity(initial, "mill").inventory.wheat = 3
			"output_limit": _entity(initial, "mill").inventory.flour = World.MAX_AMOUNT - 3
			"workplace_capacity": initial.businesses.mill.assets.daily_slots = 1
			"not_employed": initial.employment.hale.active = false
		var world = World.new(42, initial)
		world.advance_day()
		if failure == "workplace_capacity":
			world.offer_shift("bram", "mill", "bram")
			world.work_shift("bram", "mill")
		_unchanged(suite, world, func(): return world.offer_shift("bram", "mill", worker), failure)
		_unchanged(suite, world, func(): return world.work_shift(worker, "mill"), failure)
	# An offer reserves neither money nor inputs: stale acceptance must revalidate both.
	var initial: Dictionary = Config.initial()
	_entity(initial, "mill").money = 3
	var world = World.new(42, initial)
	world.advance_day()
	world.offer_shift("bram", "mill", "hale")
	suite._check(world.purchase("mill", "farm", "wheat", 1, 1), "ordinary authoritative purchases may spend unreserved offered payroll")
	_unchanged(suite, world, func(): return world.work_shift("hale", "mill"), "unfunded_payroll")
	initial = Config.initial()
	# A resident can own two firms yet still cannot supply two full shifts.
	initial.businesses.mill.owner = "ada"
	_entity(initial, "ada").skills.append("miller")
	world = World.new(42, initial)
	world.advance_day()
	world.offer_shift("ada", "farm", "ada")
	world.offer_shift("ada", "mill", "ada")
	world.work_shift("ada", "farm")
	_unchanged(suite, world, func(): return world.work_shift("ada", "mill"), "daily_labor_limit")
	initial = Config.initial()
	_entity(initial, "mill").inventory.wheat = 4
	world = World.new(42, initial)
	world.advance_day()
	world.offer_shift("bram", "mill", "bram")
	world.offer_shift("bram", "mill", "hale")
	suite._check(world.work_shift("bram", "mill"), "first worker consumes actual shared recipe inputs")
	_unchanged(suite, world, func(): return world.work_shift("hale", "mill"), "insufficient_inputs")


static func _test_decisions(suite: SceneTree) -> void:
	var initial: Dictionary = Config.initial()
	var world = World.new(42, initial)
	world.advance_day()
	var owner: Dictionary = world.observe("ada", "farm")
	suite._check(Policy.decide(owner, "schedule", "dain").action.type == "offer_shift", "owner proposes productive funded labor")
	owner.business.inventory.wheat = 16
	suite._check(Policy.decide(owner, "schedule", "dain").reason == "output_target_met", "owner skips labor when output target is met")
	owner = world.observe("ada", "farm")
	owner.business.money = 2
	suite._check(Policy.decide(owner, "schedule", "dain").reason == "unfunded_payroll", "owner explicitly declines unpaid hired labor")
	var private_initial: Dictionary = Config.initial()
	_entity(private_initial, "finn").money = 500
	_entity(private_initial, "bakery").money = 999
	_entity(private_initial, "bakery").inventory.flour = 99
	var private_world = World.new(42, private_initial)
	private_world.advance_day()
	suite._check(world.observe("ada", "farm") == private_world.observe("ada", "farm")
		and world.observe("dain", "farm").business.is_empty(), "owners see own business, workers see own offers, other finances and inputs stay private")
	var food: Dictionary = world.observe("dain")
	suite._check(Policy.decide(food, "food").reason == "food_owned", "worker avoids redundant food purchases")
	food.self.inventory.bread = 0
	suite._check(Policy.decide(food, "food").action.type == "purchase", "worker buys food when personally needed and affordable")
	food.self.money = 0
	suite._check(Policy.decide(food, "food").reason == "unaffordable_food", "unfunded household does not spend employer funds")
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("dain", "inputs", {"action": {"type": "purchase", "seller": "farm", "item": "wheat", "quantity": 1, "unit_price": 1}}, "mill")
		and world.snapshot() == before, "employee cannot direct another business's purchasing")
	suite._check(not world.execute_decision("dain", "work", {"action": {"type": "produce", "recipe": "bake", "batches": 999}}, "bakery")
		and world.snapshot() == before, "decision cannot bypass paid-labor production authority")
	_unchanged(suite, world, func(): return world.purchase("dain", "bakery", "bread", 1, 0), "invalid_market_offer")
	_unchanged(suite, world, func(): return world.purchase("dain", "bakery", "bread", true, 3), "invalid_amount")
	_unchanged(suite, world, func(): return world.purchase("dain", "bakery", "bread", World.MAX_AMOUNT, 3), "total_price_limit")
	# Actor/account binding ignores spoofed identity fields in proposals.
	_entity(initial, "dain").inventory.bread = 0
	world = World.new(42, initial)
	world.advance_day()
	world.execute_decision("dain", "food", {"action": {"type": "purchase", "buyer": "farm", "seller": "bakery", "quantity": 1, "unit_price": 3}})
	suite._check(world.snapshot().entities.dain.money == 3 and world.snapshot().entities.farm.money == 120,
		"food purchase uses actor's personal account regardless of proposed buyer")
