extends RefCounted

const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const World = preload("res://scripts/sim/coordination_world.gd")
const M4 = preload("res://scripts/sim/coordination_runner.gd")
const Commercial = preload("res://scripts/sim/coordination_policy.gd")
const Policy = preload("res://scripts/sim/planning_policy.gd")
const Runner = preload("res://scripts/sim/planning_runner.gd")
const Goals = preload("res://scripts/sim/npc_policy.gd")
const CommercialTests = preload("res://tests/coordination_tests.gd")


static func run(suite: SceneTree) -> void:
	_test_m4_failure(suite)
	_test_costs_privacy_authority(suite)
	for days in [30, 365]:
		var pairs: Array = []
		for priority in Policy.PRIORITIES:
			var first = Runner.new(42, [], Goals.DEFAULT_GOALS, priority)
			var second = Runner.new(42, [], Goals.DEFAULT_GOALS, priority)
			first.run(days)
			second.run(12)
			second.run(days - 12)
			suite._check(first.world.snapshot() == second.world.snapshot(), "planning state replays: " + priority)
			suite._check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()), "planning event replay: " + priority)
			suite._check(JSON.stringify(first.report()) == JSON.stringify(second.report()), "planning report replay: " + priority)
			suite._audit(first.world.events(), first.world.snapshot())
			CommercialTests._check_report(suite, first)
			_check_plans(suite, first, priority)
			pairs.append(first)
		suite._check(pairs[0].report().initial == pairs[1].report().initial
			and pairs[0].report().prices == pairs[1].report().prices and pairs[0].report().goals == pairs[1].report().goals
			and pairs[0].report().daily_payment == pairs[1].report().daily_payment, "strategies start with identical economics")
		suite._check(pairs[0]._rng.state == pairs[1]._rng.state, "strategies draw identical seeded environmental opportunities")
		var baseline = M4.new(42)
		baseline.run(days)
		var payload = JSON.stringify({"report": baseline.report(), "events": baseline.world.events()}, "\t", true) + "\n"
		var expected: String = "f835a43f45c8867ee0e5a861923260aa9a00e04efd680d594726aa70eca23646" if days == 30 \
			else "5dcdb3e42ca3cbd3d285ee0044b7f89915ab9450ececff0f7ee521d30c9139bf"
		suite._check(payload.sha256_text() == expected, "historical M4 hash is unchanged")
	for priority in Policy.PRIORITIES:
		var empty = Runner.new(42, [], Goals.DEFAULT_GOALS, priority)
		empty.run(0)
		suite._check(empty.report().initial == empty.report().final and empty.report().decisions.total == 0,
			"zero-day planning does not create implicit resources or promises")


static func _fixture(buyer_money: int = 20) -> RefCounted:
	var entities = Simulation.default_entities()
	entities[0].inventory.wheat = 5
	entities[1].money = 0
	entities[1].inventory.bread = 0
	entities[2].money = buyer_money
	var world = World.new(entities)
	world.post_request("baker", "flour", 2)
	world.accept_request("miller", "r1")
	return world


static func _choice(world: RefCounted, phase: String, priority: String) -> Dictionary:
	return Policy.decide(world.observe("miller"), Goals.DEFAULT_GOALS, phase, priority)


static func _test_m4_failure(suite: SceneTree) -> void:
	var reference = _fixture()
	var observation: Dictionary = reference.observe("miller")
	var plan: Dictionary = Policy.working_capital(observation, Goals.DEFAULT_GOALS)
	suite._check(plan.active and plan.input_missing == 2 and plan.input_cost == 2 and plan.cash == 4 and plan.food_cost == 3,
		"precise M4 case requires two wheat coins from four prepaid coins")
	var m4_food: Dictionary = Commercial.decide(observation, Goals.DEFAULT_GOALS, "food")
	suite._check(m4_food.action.type == "purchase" and m4_food.action.quantity == 1, "M4 spends three coins on food in this case")
	reference.execute_decision("miller", "food", m4_food)
	reference.execute_decision("miller", "meal", Commercial.decide(reference.observe("miller"), Goals.DEFAULT_GOALS, "meal"))
	reference.advance_day()
	var m4_inputs: Dictionary = Commercial.decide(reference.observe("miller"), Goals.DEFAULT_GOALS, "inputs")
	reference.execute_decision("miller", "inputs", m4_inputs)
	suite._check(reference.snapshot().entities.miller.inventory.wheat == 1 and reference.snapshot().entities.miller.money == 0,
		"M4 leaves only one wheat and no working capital")
	var starts: Array = []
	for priority in Policy.PRIORITIES:
		var world = _fixture()
		starts.append(world.snapshot())
		var before: Dictionary = world.snapshot()
		var proposal: Dictionary = _choice(world, "food", priority)
		suite._check(world.snapshot() == before, "working-capital calculation is not an escrow or world mutation")
		if priority == "commitment-first":
			suite._check(proposal.action.type == "wait" and proposal.reason == "reserve_obligation_capital"
				and proposal.action.planning.discretionary_budget == 2, "commitment-first retains two-coin input capacity")
		else:
			suite._check(proposal.action.type == "purchase" and proposal.reason == "spend_immediate_needs",
				"immediate-needs-first chooses current food despite delivery risk")
		world.execute_decision("miller", "food", proposal)
		world.execute_decision("miller", "meal", _choice(world, "meal", priority))
		world.advance_day()
		world.execute_decision("miller", "inputs", _choice(world, "inputs", priority))
		world.execute_decision("miller", "work", _choice(world, "work", priority))
		world.execute_decision("miller", "delivery", _choice(world, "delivery", priority))
		if priority == "commitment-first":
			suite._check(world.snapshot().requests.r1.status == "fulfilled" and world.snapshot().entities.baker.inventory.flour == 2,
				"planning prevents the precise food-before-input failure and delivers real flour")
			suite._check(world.events().back().details.reason == "fulfill_obligation" and world.events().back().success,
				"successful fulfillment has a linked structured decision reason")
		else:
			suite._check(world.snapshot().requests.r1.status == "accepted" and world.snapshot().entities.miller.money == 1,
				"immediate need is met while the underfunded agreement remains outstanding")
			suite._check(world.events().back().details.reason == "unable_to_satisfy_obligation", "inability is recorded without a fabricated solution")
		suite._audit(world.events(), world.snapshot())
	suite._check(starts[0] == starts[1], "focused priority comparison has exactly identical starting conditions")


static func _test_costs_privacy_authority(suite: SceneTree) -> void:
	var world = _fixture()
	var observation: Dictionary = world.observe("miller")
	var original: Dictionary = observation.duplicate(true)
	var goals: Dictionary = Goals.DEFAULT_GOALS.duplicate(true)
	var goal_copy: Dictionary = goals.duplicate(true)
	var private_change = _fixture(100)
	suite._check(observation == private_change.observe("miller"), "private buyer cash does not enter either planner's information")
	for priority in Policy.PRIORITIES:
		suite._check(Policy.decide(observation, goals, "food", priority)
			== Policy.decide(private_change.observe("miller"), goals, "food", priority), "both priorities ignore hidden financial differences")
		suite._check(observation == original and goals == goal_copy, "planner is pure over observations and goals")
	observation.self.inventory.wheat = 1
	suite._check(Policy.working_capital(observation, goals).input_cost == 1, "owned inputs reduce the working-capital requirement")
	observation.self.inventory.wheat = 2
	suite._check(Policy.working_capital(observation, goals).input_cost == 0, "owned recipe inputs free all planned cash capacity")
	observation.self.inventory.flour = 2
	suite._check(Policy.working_capital(observation, goals).status == "delivery_ready", "owned deliverable stock requires no extra inputs")
	observation = world.observe("miller")
	observation.self.money = 1
	suite._check(Policy.working_capital(observation, goals).status == "insufficient_working_capital", "known cost is not clamped to pretend affordability")
	observation.self.money = 4
	observation.market.wheat.stock = 0
	suite._check(Policy.working_capital(observation, goals).status == "input_supply_shortage", "public input shortage remains visible to both modes")
	for priority in Policy.PRIORITIES:
		var proposal: Dictionary = Policy.decide(observation, goals, "inputs", priority)
		suite._check(proposal.action.type == "wait" and proposal.reason == "unable_to_satisfy_obligation", "no strategy invents unavailable ingredients")
	observation = world.observe("miller")
	observation.self.money = 5
	suite._check(Policy.decide(observation, goals, "food", "commitment-first").action.type == "purchase",
		"commitment-first still buys food when input costs and food are both affordable")
	suite._check(world.purchase("miller", "baker", "bread", 1, 3), "world money remains spendable despite a policy reservation")
	suite._check(world.snapshot().entities.miller.money == 1 and world.snapshot().requests.r1.status == "accepted",
		"budgeting creates no new account, escrow, enforcement, or waiver")
	world = _fixture()
	var proposal: Dictionary = _choice(world, "inputs", "commitment-first")
	world.transfer_item("farmer", "laborer", "wheat", 5)
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("miller", "inputs", proposal) and world.snapshot() == before,
		"authority revalidates stale input plans without charging or creating stock")
	world = _fixture()
	proposal = _choice(world, "inputs", "commitment-first")
	proposal.action.quantity = 999
	proposal.action.planning.cash = 999999
	before = world.snapshot()
	suite._check(not world.execute_decision("miller", "inputs", proposal) and world.snapshot() == before,
		"planning annotations cannot override actual stock, money, or quantity validation")
	var entities = Simulation.default_entities()
	entities[2].inventory.bread = 0
	world = World.new(entities)
	world.post_request("laborer", "bread", 1)
	world.accept_request("baker", "r1")
	suite._check(Policy.working_capital(world.observe("baker"), goals).input_missing == 2
		and Policy.working_capital(world.observe("baker"), goals).input_cost == 4, "planning rounds whole recipe batches and uses public flour prices")


static func _check_plans(suite: SceneTree, simulation: RefCounted, priority: String) -> void:
	var report: Dictionary = simulation.report()
	var history: Array = simulation.world.events()
	var valid: bool = report.priority == priority and report.scenario == "planning"
	var activity = {"purchases_successful": 0, "purchases_failed": 0, "production_commands": 0,
		"agreements_accepted": 0, "agreements_fulfilled": 0}
	for event in history:
		if event.action == "decision":
			var plan: Dictionary = event.details.selected_action.planning
			valid = valid and plan.priority == priority and plan.input_cost >= 0
			if plan.active and plan.input_item != "":
				valid = valid and plan.input_cost == plan.input_missing * report.prices[plan.input_item]
				var expected: int = maxi(0, plan.cash - plan.input_cost) if priority == "commitment-first" else plan.cash
				valid = valid and plan.discretionary_budget == expected
		if event.day <= 26:
			continue
		if event.action == "purchase":
			activity["purchases_successful" if event.success else "purchases_failed"] += 1
		elif event.success:
			if event.action == "produce":
				activity.production_commands += 1
			elif event.action == "agreement_accepted":
				activity.agreements_accepted += 1
			elif event.action == "agreement_fulfilled":
				activity.agreements_fulfilled += 1
	suite._check(valid, "every decision logs the same cost model and its selected priority budget")
	for key in activity:
		suite._check(activity[key] == report.activity_after_day_26[key], "post-day-26 report matches actual activity: " + key)
