extends RefCounted

const Runner = preload("res://scripts/sim/market_downstream_runner.gd")
const Market = preload("res://scripts/sim/market_runner.gd")
const Policy = preload("res://scripts/sim/market_policy.gd")
const Goals = preload("res://scripts/sim/npc_policy.gd")
const World = preload("res://scripts/sim/market_world.gd")
const MarketTests = preload("res://tests/market_tests.gd")
const CommercialTests = preload("res://tests/coordination_tests.gd")


static func run(suite: SceneTree) -> void:
	_test_configuration(suite)
	_test_competition(suite)
	_test_agreements(suite)
	_test_farmer_response(suite)
	var old_hashes = {7: ["4a7edae82f7248515905f19c039ca1586a73e0180735151354793d416eaf2d4d",
		"4e5c030bc8b54678ab078cb41951c66cae0a1e5b4f7f4721659325a30ae071ad"],
		42: ["dd8b29bf0bdc13eb9a872d183e0984f5a0011e231a35f1bf234799703114e015",
		"6e2d526d9d4c3965f9bee0818c346e37b0e07d1dd4119c661cba0dc495551bb9"],
		99: ["9bffea37fcd88e0fa2bc7a1287fe6e1d576a6f8cbdfabac6dc652024a58f9f12",
		"905532de7686c26987de5a632713c160a4b73690c1e8d9b82f553700ca977c9c"]}
	for seed_value in [7, 42, 99]:
		for index in 2:
			var days: int = [30, 365][index]
			var first = Runner.new(seed_value)
			var split = Runner.new(seed_value)
			first.run(days)
			split.run(12)
			split.run(days - 12)
			suite._check(first.world.snapshot() == split.world.snapshot(), "downstream state replays across split runs")
			suite._check(JSON.stringify(first.world.events()) == JSON.stringify(split.world.events()), "downstream full ledger replays")
			suite._check(JSON.stringify(first.report()) == JSON.stringify(split.report()), "downstream report replays")
			suite._audit(first.world.events(), first.world.snapshot())
			MarketTests._check_report(suite, first, 115, 38)
			_check_harvests(suite, first, seed_value, days)
			var original = Market.new(seed_value)
			original.run(days)
			var payload: String = JSON.stringify({"report": original.report(), "events": original.world.events()}, "\t", true) + "\n"
			suite._check(payload.sha256_text() == old_hashes[seed_value][index], "historical M6 full JSON hash unchanged")


static func _test_configuration(suite: SceneTree) -> void:
	var runner = Runner.new(42)
	var report: Dictionary = runner.report()
	suite._check(report.scenario == "market_downstream" and report.initial == report.final
		and report.decisions.total == 0, "downstream zero-day run is separate and creates no resources")
	suite._check(runner.participant_ids() == ["farmer", "miller", "miller_2", "baker", "baker_2", "laborer"],
		"existing role/ID scheduling handles one farmer and two millers")
	var count: Dictionary = {"farmer": 0, "miller": 0, "baker": 0, "laborer": 0}
	var money: int = 0
	for person in report.initial.entities.values():
		count[person.role] += 1
		money += person.money
	suite._check(count == {"farmer": 1, "miller": 2, "baker": 2, "laborer": 1} and money == 115,
		"exact downstream population initializes 115 coins")
	for person in Market.default_entities():
		suite._check(report.initial.entities[person.id] == person, "original holdings retained: " + person.id)
	for pair in [["miller_2", "miller"], ["baker_2", "baker"]]:
		var added: Dictionary = report.initial.entities[pair[0]]
		var original: Dictionary = report.initial.entities[pair[1]]
		suite._check(added.money == original.money and added.inventory == original.inventory
			and added.role == original.role, "new peer has counterpart endowment and occupation")
	var offers: Dictionary = runner.world.observe("laborer").offers
	suite._check(offers.wheat.size() == 1 and offers.wheat[0].seller == "farmer"
		and offers.flour.size() == 2 and offers.bread.size() == 2, "public board has exactly one wheat and two flour/bread producers")
	var generic = Market.new(42, Runner.downstream_entities())
	generic.run(3)
	runner.run(3)
	suite._check(generic.world.events() == runner.world.events(), "thin configuration wrapper uses the identical existing runner")
	var generic_report: Dictionary = generic.report()
	generic_report.scenario = "market_downstream"
	suite._check(generic_report == runner.report(), "only report label differs from the configured market runner")


static func _test_competition(suite: SceneTree) -> void:
	var entities: Array = Runner.downstream_entities()
	MarketTests._person(entities, "farmer").inventory.wheat = 2
	var world = World.new(entities)
	var first: Dictionary = MarketTests._choose(world, "miller", "inputs")
	var stale: Dictionary = MarketTests._choose(world, "miller_2", "inputs")
	suite._check(first == stale and first.action.quantity == 2 and first.action.seller == "farmer",
		"both millers use the same occupation policy against scarce wheat")
	suite._check(world.execute_decision("miller", "inputs", first), "first miller purchases real wheat")
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("miller_2", "inputs", stale) and world.snapshot() == before
		and world.events().back().details.execution_reason == "insufficient_stock", "competing miller cannot duplicate or pay for exhausted wheat")
	suite._check(MarketTests._choose(world, "miller_2", "inputs").action.type == "wait", "second miller sees depleted supply on fresh observation")
	world.execute_decision("miller", "work", MarketTests._choose(world, "miller", "work"))
	suite._check(world.observe("baker").offers.flour[0].stock == 2, "mill production immediately advertises actual output")
	suite._audit(world.events(), world.snapshot())
	# Both new-role producers can trade through existing authority, without custom rules.
	world.harvest("farmer", 4)
	suite._check(world.execute_decision("miller_2", "inputs", MarketTests._choose(world, "miller_2", "inputs")), "Edda independently purchases wheat")
	suite._check(world.execute_decision("miller_2", "work", MarketTests._choose(world, "miller_2", "work")), "Edda independently mills flour")
	var baker_choice: Dictionary = MarketTests._choose(world, "baker", "inputs")
	var other_choice: Dictionary = MarketTests._choose(world, "baker_2", "inputs")
	suite._check(baker_choice.action.seller == "miller_2" and baker_choice == other_choice,
		"both bakers select the greater public flour stock by the common rule")
	world.execute_decision("baker", "inputs", baker_choice)
	before = world.snapshot()
	suite._check(not world.execute_decision("baker_2", "inputs", other_choice) and world.snapshot() == before,
		"competing bakers cannot duplicate the second miller's stock")
	suite._check(MarketTests._choose(world, "baker_2", "inputs").action.seller == "miller",
		"fresh baker choice switches to the other remaining flour supplier")
	var private_entities: Array = Runner.downstream_entities()
	var unchanged = World.new(private_entities)
	MarketTests._person(private_entities, "miller_2").money = 999
	MarketTests._person(private_entities, "miller_2").inventory.bread = 12
	var hidden = World.new(private_entities)
	suite._check(unchanged.observe("baker") == hidden.observe("baker")
		and MarketTests._choose(unchanged, "baker", "inputs") == MarketTests._choose(hidden, "baker", "inputs"),
		"private second-miller cash and food do not influence buyer observations or decisions")
	suite._audit(world.events(), world.snapshot())


static func _test_agreements(suite: SceneTree) -> void:
	# Run the identical prepaid production opportunity separately for each miller.
	for supplier in ["miller", "miller_2"]:
		var entities: Array = Runner.downstream_entities()
		MarketTests._person(entities, "farmer").inventory.wheat = 4
		MarketTests._person(entities, supplier).money = 0
		var world = World.new(entities)
		suite._check(world.post_request("baker", "flour", 2), "buyer posts public flour opportunity")
		for actor in ["miller", "miller_2"]:
			suite._check(MarketTests._choose(world, actor, "accept").action.type == "accept_request",
				"both millers independently consider an eligible commercial request")
		suite._check(world.execute_decision(supplier, "accept", MarketTests._choose(world, supplier, "accept")),
			"either miller can voluntarily accept through authority")
		var competitor: String = "miller_2" if supplier == "miller" else "miller"
		CommercialTests._reject(suite, world, "accept_request", [competitor, "r1"], "invalid_status")
		suite._check(world.observe(competitor).requests.is_empty(), "other miller cannot inspect an accepted private agreement")
		for phase in ["inputs", "work", "delivery"]:
			suite._check(world.execute_decision(supplier, phase, MarketTests._choose(world, supplier, phase)),
				"common commitment policy executes prepaid flour chain: " + supplier + ":" + phase)
		suite._check(world.snapshot().requests.r1.status == "fulfilled"
			and world.snapshot().entities.baker.inventory.flour == 2, "each miller can deliver real flour exactly once")
		CommercialTests._reject(suite, world, "fulfill_request", [supplier, "r1"], "invalid_status")
		suite._audit(world.events(), world.snapshot())


static func _test_farmer_response(suite: SceneTree) -> void:
	var entities: Array = Runner.downstream_entities()
	MarketTests._person(entities, "farmer").inventory.wheat = 4
	var world = World.new(entities)
	var choice: Dictionary = MarketTests._choose(world, "farmer", "work")
	suite._check(choice.action.type == "wait" and choice.reason == "output_target_met", "farmer waits at four wheat despite two potential buyers")
	world.purchase("miller", "farmer", "wheat", 1, 1)
	choice = MarketTests._choose(world, "farmer", "work")
	suite._check(choice.action.type == "harvest", "actual sales below target trigger the unchanged farmer rule")
	world.execute_decision("farmer", "work", choice, 6)
	suite._check(world.snapshot().entities.farmer.inventory.wheat == 9, "target is a trigger, not a hard cap on actual harvest")
	suite._check(MarketTests._choose(world, "farmer", "work").action.type == "wait", "overshoot postpones the next harvest without forecasting demand")
	var observation: Dictionary = world.observe("farmer")
	var busier: Dictionary = observation.duplicate(true)
	busier.offers.flour.append({"seller": "public_fixture", "unit_price": 2, "stock": 100})
	suite._check(Policy.decide(observation, Goals.DEFAULT_GOALS, "work") == Policy.decide(busier, Goals.DEFAULT_GOALS, "work"),
		"more downstream public offers alone cannot increase the farmer target or work frequency")
	suite._audit(world.events(), world.snapshot())
	# Existing commercial commitments can raise the effective target; ordinary demand cannot.
	world = World.new(entities)
	world.post_request("miller_2", "wheat", 6)
	world.execute_decision("farmer", "accept", MarketTests._choose(world, "farmer", "accept"))
	choice = MarketTests._choose(world, "farmer", "work")
	suite._check(world.snapshot().requests.r1.status == "accepted" and choice.action.type == "harvest"
		and choice.reason == "produce_for_obligation", "accepted six-wheat obligation can raise effective harvest target above four")
	suite._audit(world.events(), world.snapshot())


static func _check_harvests(suite: SceneTree, runner: RefCounted, seed_value: int, days: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var opportunities: Array = [0]
	for _index in days:
		opportunities.append(rng.randi_range(2, 6))
	var stock: int = 0
	var valid: bool = true
	for event in runner.world.events():
		if not event.success:
			continue
		var d: Dictionary = event.details
		if event.action == "harvest":
			valid = valid and event.actor == "farmer" and d.amount == opportunities[event.day]
			stock += d.amount
		elif event.action == "purchase" and event.target == "farmer":
			stock -= d.quantity
		elif event.action == "transfer_item" and event.actor == "farmer":
			stock -= d.amount
		elif event.action == "decision" and event.actor == "farmer" and d.phase == "work":
			var planning: Dictionary = d.selected_action.planning
			if not planning.active:
				if d.selected_action.type == "harvest":
					valid = valid and stock - opportunities[event.day] < 4
				else:
					valid = valid and stock >= 4
	suite._check(runner._rng.state == rng.state and valid, "one original daily harvest opportunity; target waits only at sufficient owned stock")
