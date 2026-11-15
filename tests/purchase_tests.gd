extends RefCounted

const World = preload("res://scripts/sim/world_state.gd")
const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const INT64_MAX = 9223372036854775807
const INT64_MIN = -9223372036854775807 - 1


static func run(suite: SceneTree) -> void:
	_test_success(suite)
	_test_rejections(suite)
	_test_boundaries(suite)
	_test_replay(suite)


static func _test_success(suite: SceneTree) -> void:
	var world = suite._fixture()
	var before: Dictionary = world.snapshot()
	var event_count: int = world.events().size()
	suite._check(world.purchase("miller", "farmer", "wheat", 4, 3), "purchase succeeds")
	var state: Dictionary = world.snapshot().entities
	suite._check(state.farmer.inventory.wheat == 6 and state.miller.inventory.wheat == 4,
		"purchase transfers exact goods")
	suite._check(state.miller.money == 8 and state.farmer.money == 42,
		"purchase transfers exact payment in the opposite direction")
	_check_conservation(suite, before, world.snapshot())
	var event: Dictionary = world.events().back()
	suite._check(world.events().size() == event_count + 1 and event.action == "purchase" and event.success,
		"successful purchase records one atomic event")
	suite._check(event.actor == "miller" and event.target == "farmer" and event.day == 0,
		"purchase uses existing actor/target/day schema")
	suite._check(event.details == {"buyer": "miller", "seller": "farmer", "item": "wheat",
		"quantity": 4, "unit_price": 3, "total_price": 12}, "purchase event records exact exchange")
	# Exact affordability and complete stock depletion are legal.
	suite._check(world.purchase("miller", "farmer", "wheat", 4, 2), "buyer can spend entire balance")
	suite._check(world.snapshot().entities.miller.money == 0, "exact affordability reaches zero")
	suite._check(world.purchase("miller", "farmer", "wheat", 2, 0), "zero-price purchase needs no money")
	suite._check(world.snapshot().entities.farmer.inventory.wheat == 0, "seller can sell entire stock")
	suite._check(world.events().back().details.total_price == 0, "free purchase records zero payment")
	_check_conservation(suite, before, world.snapshot())
	suite._audit(world.events(), world.snapshot())


static func _rejected(suite: SceneTree, args: Array, reason: String, entities: Array = []) -> void:
	var world = suite._fixture() if entities.is_empty() else World.new(entities)
	var before: Dictionary = world.snapshot()
	var event_count: int = world.events().size()
	var result: bool = world.callv("purchase", args)
	suite._unchanged(world, before, result, "purchase " + reason)
	var event: Dictionary = world.events().back()
	suite._check(world.events().size() == event_count + 1 and event.action == "purchase"
		and event.details.reason == reason, "rejected purchase records one event with exact reason")
	suite._check(event.actor == args[0] and event.target == args[1]
		and event.details.buyer == args[0] and event.details.seller == args[1]
		and event.details.item == args[2] and event.details.has("quantity")
		and event.details.has("unit_price") and event.details.has("total_price"),
		"rejected purchase preserves participants and amount fields")
	suite._check(var_to_str(event.details.quantity) == var_to_str(args[3])
		and var_to_str(event.details.unit_price) == var_to_str(args[4]),
		"rejected purchase records original quantity and unit price")
	var expected_total: Variant = null
	if reason in ["insufficient_money", "insufficient_stock", "buyer_inventory_limit", "seller_money_limit"]:
		expected_total = args[3] * args[4]
	suite._check(event.details.total_price == expected_total, "rejected purchase records safe total or null")
	_check_conservation(suite, before, world.snapshot())


static func _test_rejections(suite: SceneTree) -> void:
	_rejected(suite, ["miller", "farmer", "wheat", 4, 6], "insufficient_money")
	_rejected(suite, ["miller", "farmer", "wheat", 11, 1], "insufficient_stock")
	for pair in [["missing", "farmer"], ["", "farmer"]]:
		_rejected(suite, [pair[0], pair[1], "wheat", 1, 1], "unknown_actor")
	_rejected(suite, ["miller", "missing", "wheat", 1, 1], "unknown_target")
	_rejected(suite, ["farmer", "farmer", "wheat", 1, 0], "same_entity")
	_rejected(suite, ["miller", "farmer", "gold", 1, 1], "unknown_item")
	for quantity in [0, -1, 1.0, NAN, INF, -INF, "1", null, true, World.MAX_AMOUNT + 1, INT64_MAX, INT64_MIN]:
		_rejected(suite, ["miller", "farmer", "wheat", quantity, 1], "invalid_amount")
	for price in [-1, 1.0, NAN, INF, -INF, "1", null, false, World.MAX_AMOUNT + 1, INT64_MAX, INT64_MIN]:
		_rejected(suite, ["miller", "farmer", "wheat", 1, price], "invalid_unit_price")
	# Includes multiplication that would overflow int64 if validated too late.
	_rejected(suite, ["miller", "farmer", "wheat", INT64_MAX, INT64_MAX], "invalid_amount")
	_rejected(suite, ["miller", "farmer", "wheat", 2, World.MAX_AMOUNT], "total_price_limit")
	_rejected(suite, ["miller", "farmer", "wheat", World.MAX_AMOUNT, World.MAX_AMOUNT], "total_price_limit")
	_rejected(suite, ["miller", "farmer", "wheat", 3, 333333334], "total_price_limit")
	var entities = Simulation.default_entities()
	entities[0].inventory.wheat = 10
	entities[1].inventory.wheat = World.MAX_AMOUNT
	_rejected(suite, ["miller", "farmer", "wheat", 1, 1], "buyer_inventory_limit", entities)
	entities[1].inventory.wheat = World.MAX_AMOUNT - 1
	_rejected(suite, ["miller", "farmer", "wheat", 2, 1], "buyer_inventory_limit", entities)
	entities[1].inventory.wheat = 0
	entities[0].money = World.MAX_AMOUNT
	_rejected(suite, ["miller", "farmer", "wheat", 1, 1], "seller_money_limit", entities)


static func _test_boundaries(suite: SceneTree) -> void:
	var entities = Simulation.default_entities()
	entities[0].inventory.wheat = World.MAX_AMOUNT
	entities[0].money = 0
	entities[1].money = World.MAX_AMOUNT
	var world = World.new(entities)
	var before: Dictionary = world.snapshot()
	suite._check(world.purchase("miller", "farmer", "wheat", World.MAX_AMOUNT, 1),
		"maximum quantity and total reach inventory and money limits exactly")
	_check_conservation(suite, before, world.snapshot())
	suite._audit(world.events(), world.snapshot())
	suite._check(world.purchase("farmer", "miller", "wheat", 1, World.MAX_AMOUNT),
		"maximum unit price is valid with sufficient funds and capacity")
	suite._check(world.purchase("farmer", "miller", "wheat", World.MAX_AMOUNT - 1, 0),
		"maximum inventory and seller balance permit a zero-price purchase")
	_check_conservation(suite, before, world.snapshot())
	# Just below the total-price limit tests exact integer division near its boundary.
	entities[0].inventory.wheat = 3
	world = World.new(entities)
	suite._check(world.purchase("miller", "farmer", "wheat", 3, 333333333),
		"total one below the limit is accepted without rounding")
	suite._check(world.events().back().details.total_price == 999999999, "large total is exact")


static func _check_conservation(suite: SceneTree, before: Dictionary, after: Dictionary) -> void:
	var money_delta: int = 0
	var item_deltas = {"wheat": 0, "flour": 0, "bread": 0}
	for actor in before.entities:
		money_delta += after.entities[actor].money - before.entities[actor].money
		for item in World.ITEMS:
			item_deltas[item] += after.entities[actor].inventory[item] - before.entities[actor].inventory[item]
	suite._check(money_delta == 0 and item_deltas == {"wheat": 0, "flour": 0, "bread": 0},
		"purchase conserves every commodity and money across all NPCs")


static func _test_replay(suite: SceneTree) -> void:
	var first = Simulation.new(42)
	var second = Simulation.new(42)
	for simulation in [first, second]:
		simulation.run(4)
		simulation.world.purchase("laborer", "baker", "bread", 2, 2)
		simulation.world.purchase("farmer", "miller", "wheat", 1, 1)
		simulation.run(3)
		simulation.world.purchase("farmer", "baker", "bread", 1, 0)
		simulation.world.purchase("laborer", "baker", "bread", 3, World.MAX_AMOUNT)
	var purchases: Array = first.world.events().filter(func(event): return event.action == "purchase")
	suite._check(purchases.size() == 4 and purchases[0].success and not purchases[1].success
		and purchases[2].success and not purchases[3].success, "replay exercises accepted and rejected purchases")
	suite._check(first.world.snapshot() == second.world.snapshot(), "ordered purchases preserve deterministic final state")
	suite._check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()),
		"ordered purchases preserve identical event logs")
	suite._check(JSON.stringify(first.report()) == JSON.stringify(second.report()),
		"reports remain deterministic with purchase events")
	suite._audit(first.world.events(), first.world.snapshot())
