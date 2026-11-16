extends SceneTree

const World = preload("res://scripts/sim/world_state.gd")
const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const PurchaseTests = preload("res://tests/purchase_tests.gd")
const TradingTests = preload("res://tests/trading_tests.gd")
const AgentsTests = preload("res://tests/agents_tests.gd")
const CoordinationTests = preload("res://tests/coordination_tests.gd")
const PlanningTests = preload("res://tests/planning_tests.gd")
const MarketTests = preload("res://tests/market_tests.gd")
const MarketDownstreamTests = preload("res://tests/market_downstream_tests.gd")
const CalibrationTests = preload("res://tests/calibration_tests.gd")
const LaborTests = preload("res://tests/labor_tests.gd")
const FinanceTests = preload("res://tests/finance_tests.gd")
const EquilibriumTests = preload("res://tests/equilibrium_tests.gd")
const EmployerTests = preload("res://tests/employer_tests.gd")
const CausalityTests = preload("res://tests/causality_tests.gd")
const ProfitableTests = preload("res://tests/profitable_tests.gd")
const EnterpriseTests = preload("res://tests/enterprise_tests.gd")
const PricingTests = preload("res://tests/pricing_tests.gd")
const ProfileTests = preload("res://tests/profile_tests.gd")
const LearningTests = preload("res://tests/learning_tests.gd")
const SpatialTests = preload("res://tests/spatial_tests.gd")

var _checks: int = 0
var _failures: int = 0


func _init() -> void:
	_test_transfers()
	_test_rejections()
	_test_production_and_eating()
	_test_limits()
	_test_state_isolation()
	_test_unmet_report()
	_test_simulation()
	print("M0 regression checks: %d" % _checks)
	PurchaseTests.run(self)
	print("M0/M1 regression checks: %d" % _checks)
	TradingTests.run(self)
	print("M0/M1/M2 regression checks: %d" % _checks)
	AgentsTests.run(self)
	print("M0/M1/M2/M3 regression checks: %d" % _checks)
	CoordinationTests.run(self)
	print("M0–M4 regression checks: %d" % _checks)
	PlanningTests.run(self)
	print("M0–M5 regression checks: %d" % _checks)
	MarketTests.run(self)
	print("M0–M6 regression checks: %d" % _checks)
	MarketDownstreamTests.run(self)
	print("M0–M6B regression checks: %d" % _checks)
	CalibrationTests.run(self)
	print("M0–M8 regression checks: %d" % _checks)
	LaborTests.run(self)
	print("M0–M9 regression checks: %d" % _checks)
	FinanceTests.run(self)
	print("M0–M10 regression checks: %d" % _checks)
	EquilibriumTests.run(self)
	print("M0–M11 regression checks: %d" % _checks)
	EmployerTests.run(self)
	print("M0–M12 regression checks: %d" % _checks)
	CausalityTests.run(self)
	print("M0–M13 regression checks: %d" % _checks)
	ProfitableTests.run(self)
	print("M0–M14 regression checks: %d" % _checks)
	EnterpriseTests.run(self)
	print("M0–M15 regression checks: %d" % _checks)
	PricingTests.run(self)
	print("M0–M16 regression checks: %d" % _checks)
	SpatialTests.run(self)
	LearningTests.run(self)
	ProfileTests.run(self)
	print("Tests: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _fixture() -> RefCounted:
	var entities = Simulation.default_entities()
	entities[0].inventory.wheat = 10
	return World.new(entities)


func _unchanged(world: RefCounted, before: Dictionary, result: bool, message: String) -> void:
	_check(not result and world.snapshot() == before, message + ": rejects without state changes")
	var event: Dictionary = world.events().back()
	_check(not event.success and event.details.has("reason"), message + ": records failure reason")


func _test_transfers() -> void:
	var world = _fixture()
	_check(world.transfer_item("farmer", "miller", "wheat", 4), "item transfer succeeds")
	var state: Dictionary = world.snapshot().entities
	_check(state.farmer.inventory.wheat == 6 and state.miller.inventory.wheat == 4,
		"item transfer debits and credits exactly four")
	_check(world.transfer_money("farmer", "laborer", 30), "entire balance can be transferred")
	state = world.snapshot().entities
	_check(state.farmer.money == 0 and state.laborer.money == 35, "money transfer is exact")
	var total = 0
	for entity in state.values():
		total += entity.money
	_check(total == 75, "money transfer conserves total money")
	_check(world.transfer_item("farmer", "miller", "wheat", 6), "entire stock can be transferred")
	state = world.snapshot().entities
	_check(state.farmer.inventory.wheat == 0 and state.miller.inventory.wheat == 10,
		"transfers conserve total wheat")


func _test_rejections() -> void:
	var world = _fixture()
	var before: Dictionary = world.snapshot()
	for amount in [0, -1, 0.5, "1", null, true, World.MAX_AMOUNT + 1]:
		_unchanged(world, before, world.transfer_item("farmer", "miller", "wheat", amount),
			"invalid item amount %s" % str(amount))
		_unchanged(world, before, world.transfer_money("farmer", "miller", amount),
			"invalid money amount %s" % str(amount))
		_unchanged(world, before, world.produce("miller", "mill", amount), "invalid batches")
		_unchanged(world, before, world.harvest("farmer", amount), "invalid harvest amount")
		_unchanged(world, before, world.consume("farmer", amount), "invalid meal amount")
	_unchanged(world, before, world.transfer_item("farmer", "miller", "wheat", 11), "insufficient items")
	_unchanged(world, before, world.transfer_money("farmer", "miller", 31), "unaffordable payment")
	for pair in [["missing", "miller"], ["farmer", "missing"], ["farmer", "farmer"]]:
		_unchanged(world, before, world.transfer_item(pair[0], pair[1], "wheat", 1), "invalid item participant")
		_unchanged(world, before, world.transfer_money(pair[0], pair[1], 1), "invalid money participant")
	_unchanged(world, before, world.transfer_item("farmer", "miller", "gold", 1), "unknown item")
	_unchanged(world, before, world.produce("miller", "unknown"), "unknown recipe")
	_unchanged(world, before, world.produce("farmer", "mill"), "wrong production role")
	_unchanged(world, before, world.harvest("laborer", 1), "wrong harvest role")
	_unchanged(world, before, world.harvest("missing", 1), "unknown harvester")
	_unchanged(world, before, world.produce("missing", "mill"), "unknown producer")
	_unchanged(world, before, world.consume("missing"), "unknown eater")
	_unchanged(world, before, world.produce("miller", "mill"), "missing recipe inputs")


func _test_production_and_eating() -> void:
	var world = _fixture()
	_check(world.harvest("farmer", 3), "harvest succeeds")
	_check(world.snapshot().entities.farmer.inventory.wheat == 13, "harvest creates exactly three wheat")
	_check(world.events().back().action == "harvest", "source is explicit in history")
	world.transfer_item("farmer", "miller", "wheat", 4)
	_check(world.produce("miller", "mill", 2), "milling succeeds")
	var stock: Dictionary = world.snapshot().entities.miller.inventory
	_check(stock.wheat == 0 and stock.flour == 4, "milling consumes four wheat and creates four flour")
	var event: Dictionary = world.events().back()
	_check(event.details.inputs == {"wheat": 4} and event.details.outputs == {"flour": 4},
		"production event declares exact source and sink")
	world.transfer_item("miller", "baker", "flour", 4)
	_check(world.produce("baker", "bake", 2), "baking succeeds")
	stock = world.snapshot().entities.baker.inventory
	_check(stock.flour == 0 and stock.bread == 7, "baking consumes four flour and creates six bread")
	_check(world.consume("baker", 7), "all actual bread can be eaten")
	_check(world.snapshot().entities.baker.inventory.bread == 0, "eating removes stock")
	var before: Dictionary = world.snapshot()
	_unchanged(world, before, world.consume("baker"), "cannot eat nonexistent food")


func _test_limits() -> void:
	var entities = Simulation.default_entities()
	entities[1].inventory.wheat = World.MAX_AMOUNT
	entities[1].inventory.flour = World.MAX_AMOUNT
	entities[1].money = World.MAX_AMOUNT
	entities[0].inventory.wheat = World.MAX_AMOUNT
	var world = World.new(entities)
	var before: Dictionary = world.snapshot()
	_unchanged(world, before, world.harvest("farmer", 1), "harvest capacity")
	_unchanged(world, before, world.transfer_item("farmer", "miller", "wheat", 1), "item recipient capacity")
	_unchanged(world, before, world.transfer_money("farmer", "miller", 1), "money recipient capacity")
	_unchanged(world, before, world.produce("miller", "mill"), "output capacity checked before consuming inputs")
	_unchanged(world, before, world.produce("miller", "mill", World.MAX_AMOUNT), "large recipe multiplication")


func _test_state_isolation() -> void:
	var initial = Simulation.default_entities()
	var world = World.new(initial)
	var before: Dictionary = world.snapshot()
	initial[0].money = -1
	var copy: Dictionary = world.snapshot()
	copy.entities.farmer.inventory.bread = -1
	var history: Array = world.events()
	history[0].details.state.entities.farmer.money = -1
	_check(world.snapshot() == before, "constructor and snapshot isolate authoritative state")
	_check(world.events()[0].details.state == before, "history is append-only through public API")


func _test_unmet_report() -> void:
	var entities = Simulation.default_entities()
	for entity in entities:
		entity.inventory.bread = 0
	var simulation = Simulation.new(42, entities)
	# A controlled day with no production verifies the report's scarcity path.
	simulation.world.advance_day()
	for actor in Simulation.IDS:
		simulation.world.consume(actor)
	var report: Dictionary = simulation.report()
	_check(report.unmet_meals == {"farmer": 1, "miller": 1, "baker": 1, "laborer": 1},
		"report counts actual unmet meals per NPC")
	_check(report.totals.consumed.bread == 0, "failed meals do not count as consumption")
	_check(report.failures == {"consume:insufficient_stock": 4}, "report groups meaningful failures")


func _test_simulation() -> void:
	var first = Simulation.new(42)
	var second = Simulation.new(42)
	first.run(30)
	# Splitting a run must preserve RNG state and tick order.
	second.run(12)
	second.run(18)
	_check(first.world.snapshot() == second.world.snapshot(), "same seed and state reproduce final state")
	_check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()),
		"same seed and state reproduce identical ordered events")
	_check(JSON.stringify(first.report()) == JSON.stringify(second.report()), "reports are deterministic")
	var other = Simulation.new(43)
	other.run(30)
	_check(first.world.events() != other.world.events(), "seed controls harvest randomness")
	var empty = Simulation.new(42)
	empty.run(0)
	_check(empty.report().initial == empty.report().final, "zero days preserve initial state")
	_audit(first.world.events(), first.world.snapshot())
	var report: Dictionary = first.report()
	var wheat = 0
	var flour = 0
	var bread = 0
	for entity in report.final.entities.values():
		wheat += entity.inventory.wheat
		flour += entity.inventory.flour
		bread += entity.inventory.bread
	_check(wheat == report.totals.harvested.wheat - report.totals.production_inputs.wheat,
		"30-day wheat sources and sinks reconcile")
	_check(flour == report.totals.production_outputs.flour - report.totals.production_inputs.flour,
		"30-day flour sources and sinks reconcile")
	_check(bread == 4 + report.totals.production_outputs.bread - report.totals.consumed.bread,
		"30-day bread sources and sinks reconcile")
	var unmet = 0
	for amount in report.unmet_meals.values():
		unmet += amount
	_check(report.totals.consumed.bread + unmet == 120, "every daily food need is met or recorded unmet")


func _audit(history: Array, final_state: Dictionary) -> void:
	# Independently reconstruct each state from the ledger, without calling commands.
	var state: Dictionary = history[0].details.state.duplicate(true)
	var initial_money: int = 0
	var used_receipts: Dictionary = {}
	for entity in state.entities.values():
		initial_money += entity.money
	var valid = true
	for index in history.size():
		var event: Dictionary = history[index]
		valid = valid and event.id == index + 1
		if event.action == "day_started":
			state.day += 1
		valid = valid and event.day == state.day
		if event.success:
			var details: Dictionary = event.details
			match event.action:
				"request_posted", "agreement_accepted", "agreement_fulfilled", "request_closed":
					var request: Dictionary = details.request
					var previous: Dictionary = state.requests.get(request.id, {})
					if event.action == "request_posted":
						valid = valid and previous.is_empty() and request.status == "open" and request.supplier == ""
						valid = valid and request.buyer == event.actor and request.quantity > 0
						valid = valid and request.payment == request.quantity * request.unit_price and request.created_day == event.day
					else:
						for field in ["id", "buyer", "item", "quantity", "unit_price", "payment", "created_day"]:
							valid = valid and previous.get(field) == request[field]
						if event.action == "request_closed":
							valid = valid and previous.status in ["open", "accepted"] and request.status == "closed"
							valid = valid and event.actor == request.buyer and not request.close_reason.is_empty()
						else:
							var accepting: bool = event.action == "agreement_accepted"
							var receipt_id: int = details.payment_event_id if accepting else details.item_event_id
							var receipt: Dictionary = history[receipt_id - 1]
							valid = valid and not used_receipts.has(receipt_id) and receipt.success and receipt.id < event.id
							used_receipts[receipt_id] = true
							if accepting:
								valid = valid and previous.status == "open" and request.status == "accepted"
								valid = valid and receipt.action == "transfer_money" and receipt.actor == request.buyer
								valid = valid and receipt.target == request.supplier and receipt.details.amount == request.payment
							else:
								valid = valid and previous.status == "accepted" and request.status == "fulfilled"
								valid = valid and receipt.action == "transfer_item" and receipt.actor == request.supplier
								valid = valid and receipt.target == request.buyer and receipt.details.item == request.item
								valid = valid and receipt.details.amount == request.quantity
							valid = valid and event.actor == request.supplier
					state.requests[request.id] = request.duplicate(true)
				"agreement_outstanding":
					valid = valid and state.requests[details.request.id] == details.request and details.request.status == "accepted"
				"purchase":
					state.entities[event.target].inventory[details.item] -= details.quantity
					state.entities[event.actor].inventory[details.item] += details.quantity
					state.entities[event.actor].money -= details.total_price
					state.entities[event.target].money += details.total_price
				"transfer_item":
					state.entities[event.actor].inventory[details.item] -= details.amount
					state.entities[event.target].inventory[details.item] += details.amount
				"transfer_money":
					state.entities[event.actor].money -= details.amount
					state.entities[event.target].money += details.amount
				"harvest":
					state.entities[event.actor].inventory[details.item] += details.amount
				"produce":
					for item in details.inputs:
						state.entities[event.actor].inventory[item] -= details.inputs[item]
					for item in details.outputs:
						state.entities[event.actor].inventory[item] += details.outputs[item]
				"consume":
					state.entities[event.actor].inventory[details.item] -= details.amount
				"initialize", "day_started", "decision":
					pass
				_:
					valid = false
		var money = 0
		for entity in state.entities.values():
			money += entity.money
			valid = valid and entity.money >= 0
			for amount in entity.inventory.values():
				valid = valid and amount >= 0
		valid = valid and money == initial_money
	_check(valid, "every event has ordered identity, valid day, nonnegative stock and conserved money")
	_check(state == final_state, "structured events reconstruct the complete final state")
