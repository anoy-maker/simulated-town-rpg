extends RefCounted

const Runner = preload("res://scripts/sim/calibration_runner.gd")
const Config = preload("res://scripts/sim/calibration_config.gd")
const World = preload("res://scripts/sim/calibration_world.gd")
const Downstream = preload("res://scripts/sim/market_downstream_runner.gd")
const MarketTests = preload("res://tests/market_tests.gd")
const CommercialTests = preload("res://tests/coordination_tests.gd")


static func run(suite: SceneTree) -> void:
	_test_configuration(suite)
	_test_authority(suite)
	_test_metrics(suite)
	for experiment in Config.EXPERIMENTS:
		for days in [30, 365]:
			var config: Dictionary = Config.preset(experiment)
			var first = Runner.new(42, config)
			var split = Runner.new(42, config)
			first.run(days)
			split.run(12)
			split.run(days - 12)
			suite._check(first.world.snapshot() == split.world.snapshot(), "calibration state replays: " + experiment)
			suite._check(first.world.events() == split.world.events(), "calibration ledger replays: " + experiment)
			suite._check(first.report() == split.report(), "calibration report replays: " + experiment)
			suite._audit(first.world.events(), first.world.snapshot())
			MarketTests._check_report(suite, first, 175 if experiment == "extra_liquidity" else 115, 38)
			_check_environment(suite, first, days)
			var summary: Dictionary = first.report()
			suite._check(summary.prices == config.prices and summary.daily_payment.amount == config.daily_payment
				and summary.goals.output_targets.farmer == config.farmer_target, "report uses actual configured economics")
			suite._check(summary.totals.production_outputs.bread <= summary.potential.bread_upper_bound
				and summary.totals.consumed.bread <= summary.potential.timely_meals_upper_bound, "realized food cannot exceed physical supply bound")
			if experiment == "baseline":
				var old = Downstream.new(42)
				old.run(days)
				suite._check(old.world.events() == first.world.events(), "calibration baseline exactly matches M6B economic ledger")
				for key in ["configuration", "experiment", "potential", "calibration"]:
					summary.erase(key)
				summary.scenario = "market_downstream"
				suite._check(summary == old.report(), "baseline's inherited report matches M6B exactly")


static func _test_configuration(suite: SceneTree) -> void:
	for experiment in Config.EXPERIMENTS:
		var config: Dictionary = Config.preset(experiment)
		suite._check(Config.validate(config).is_empty(), "valid fixed calibration preset: " + experiment)
		var changes: Array = []
		for key in Config.DEFAULT:
			if config[key] != Config.DEFAULT[key]:
				changes.append(key)
		var expected = {"baseline": [], "higher_productivity": ["harvest_bonus"], "higher_target": ["farmer_target"],
			"lower_food_price": ["prices"], "higher_wage": ["daily_payment"], "extra_liquidity": ["initial_money"]}
		suite._check(changes == expected[experiment], "each preset isolates exactly its declared economic variable")
	var config: Dictionary = Config.preset("lower_food_price")
	var runner = Runner.new(42, config)
	config.prices.bread = 99
	config.initial_money.farmer = 999
	suite._check(runner.configuration() == Config.preset("lower_food_price")
		and runner.world.observe("laborer").offers.bread[0].unit_price == 2, "caller changes cannot alter instance economics")
	var exposed: Dictionary = runner.configuration()
	exposed.prices.wheat = 99
	suite._check(runner.configuration().prices.wheat == 1 and Config.preset("baseline") == Config.DEFAULT,
		"configuration getters, presets, and defaults are isolated copies")
	for invalid in [null, true, [], {}, {"unsupported": 1}]:
		suite._check(not Config.validate(invalid).is_empty(), "reject malformed calibration configuration")
	for key in ["harvest_bonus", "farmer_target", "daily_payment"]:
		for invalid in [-1, 1.0, NAN, INF, "1", null, true, 9223372036854775807]:
			config = Config.preset("baseline")
			config[key] = invalid
			suite._check(Config.validate(config) == "invalid_" + key, "reject noninteger, negative or overflowing parameter")
	for key in ["prices", "initial_money"]:
		for invalid in [[], null, {}, {"unexpected": 1}]:
			config = Config.preset("baseline")
			config[key] = invalid
			suite._check(Config.validate(config) == "invalid_" + key, "reject malformed nested parameter")
		for invalid in [-1, 1.0, INF, true, null, 9223372036854775807]:
			config = Config.preset("baseline")
			config[key]["bread" if key == "prices" else "laborer"] = invalid
			suite._check(Config.validate(config) == "invalid_" + key, "nested values require bounded integer accounting")
	for key in ["farmer_target", "daily_payment"]:
		config = Config.preset("baseline")
		config[key] = 0
		suite._check(Config.validate(config) == "invalid_" + key, "zero target/payment is not silently reinterpreted")
	config = Config.preset("baseline")
	config.prices.bread = 0
	suite._check(Config.validate(config) == "invalid_prices", "laboratory forbids zero prices used as policy divisors")
	config = Config.preset("baseline")
	config.initial_money.laborer = 0
	suite._check(Config.validate(config).is_empty(), "zero initial cash is permitted without debt or rescue")
	config["extra"] = 1
	suite._check(Config.validate(config) == "invalid_configuration", "unknown parameters cannot change hidden experiment conditions")
	var zero = Runner.new()
	suite._check(zero.report().initial == zero.report().final and zero.report().potential.food_required == 0,
		"zero-day calibration creates no economic activity")


static func _test_authority(suite: SceneTree) -> void:
	for price in [2, 4]:
		var config: Dictionary = Config.preset("baseline")
		config.prices.bread = price
		var world = World.new(Downstream.downstream_entities(), config)
		world.consume("laborer")
		world.advance_day()
		var choice: Dictionary = MarketTests._choose(world, "laborer", "food")
		suite._check(choice.action.unit_price == price and world.execute_decision("laborer", "food", choice),
			"lower/higher configured prices reach real purchase authority")
		suite._check(world.snapshot().entities.laborer.money == 5 - price
			and world.snapshot().entities.baker.money == 20 + price, "configured exchange debits/credits exact integer price")
		choice.action.unit_price = 3
		var before: Dictionary = world.snapshot()
		suite._check(not world.execute_decision("laborer", "food", choice) and world.snapshot() == before,
			"historical price cannot bypass new fixed public price")
		suite._check(world.post_request("farmer", "bread", 2), "configured fixed-price agreement is posted")
		suite._check(world.snapshot().requests.r1.payment == 2 * price, "agreement terms use the same price as public spot offers")
		world.accept_request("baker", "r1")
		CommercialTests._reject(suite, world, "fulfill_request", ["baker", "r1"], "insufficient_stock")
		suite._audit(world.events(), world.snapshot())
	var config: Dictionary = Config.preset("baseline")
	config.prices = {"wheat": 2, "flour": 3, "bread": 4}
	var world = World.new(Downstream.downstream_entities(), config)
	var offers: Dictionary = world.observe("baker").offers
	suite._check(offers.wheat[0].unit_price == 2 and offers.flour[1].unit_price == 3
		and offers.bread[0].unit_price == 4, "all three commodity prices are parameterized")
	world.consume("laborer")
	world.advance_day()
	var stale: Dictionary = MarketTests._choose(world, "laborer", "food")
	world.transfer_money("laborer", "farmer", 5)
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("laborer", "food", stale) and world.snapshot() == before,
		"configured price still revalidates stale affordability atomically")
	config.prices.bread = Config.Rules.MAX_AMOUNT
	world = World.new(Downstream.downstream_entities(), config)
	CommercialTests._reject(suite, world, "post_request", ["farmer", "bread", 2], "payment_limit")
	var proposal = {"action": {"type": "purchase", "seller": "baker", "item": "bread",
		"quantity": 2, "unit_price": Config.Rules.MAX_AMOUNT}, "reason": "overflow_fixture"}
	before = world.snapshot()
	suite._check(not world.execute_decision("laborer", "food", proposal) and world.snapshot() == before,
		"large valid unit price cannot overflow a purchase total")
	config = Config.preset("higher_productivity")
	world = World.new(Downstream.downstream_entities(), config)
	proposal = {"action": {"type": "harvest", "amount": 999}, "reason": "trusted_environment_only"}
	suite._check(world.execute_decision("farmer", "work", proposal, 8)
		and world.snapshot().entities.farmer.inventory.wheat == 8, "authorized shifted opportunity passes through inherited harvest accounting")
	before = world.snapshot()
	suite._check(not world.execute_decision("farmer", "work", proposal, 9) and world.snapshot() == before,
		"policy cannot supply an out-of-range environmental yield")
	suite._audit(world.events(), world.snapshot())
	var private_entities: Array = Downstream.downstream_entities()
	var visible = World.new(private_entities, config)
	MarketTests._person(private_entities, "miller_2").money = 999
	var hidden = World.new(private_entities, config)
	suite._check(visible.observe("baker") == hidden.observe("baker"), "parameter plumbing does not expose seller balances")


static func _test_metrics(suite: SceneTree) -> void:
	var config: Dictionary = Config.preset("baseline")
	config.initial_money.laborer = 2
	var runner = Runner.new(42, config)
	runner.run(1)
	var stats: Dictionary = runner.report().calibration.per_npc.laborer
	suite._check(stats.cash_affordable_food_days == 1 and stats.owned_food_days == 1,
		"food snapshot counts initial owned bread and wage-funded affordability before food choice")
	for seed_value in [7, 42, 99]:
		var baseline: Dictionary = Runner.Diagnostics.potential(seed_value, 365, 0)
		var higher: Dictionary = Runner.Diagnostics.potential(seed_value, 365, 2)
		var expected: int = {7: 1456, 42: 1470, 99: 1482}[seed_value]
		suite._check(baseline.opportunity_wheat == expected and baseline.bread_upper_bound == 3 * (expected / 2),
			"physical bounds match independently recorded historical opportunity totals")
		suite._check(higher.opportunity_wheat == expected + 730 and higher.bread_upper_bound == baseline.bread_upper_bound + 1095
			and baseline.underlying_draws_hash == higher.underlying_draws_hash, "productivity changes yield, never the underlying environmental draw")
	var capped: Dictionary = Runner.Diagnostics.potential(42, 30, 100)
	suite._check(capped.bread_upper_bound == 360 and capped.timely_meals_upper_bound == 180,
		"physical bound respects both processors' batch capacities and meal timing")


static func _check_environment(suite: SceneTree, runner: RefCounted, days: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var yields: Array = [0]
	for _day in days:
		yields.append(rng.randi_range(2, 6) + runner.configuration().harvest_bonus)
	var valid: bool = true
	for event in runner.world.events():
		if event.action == "harvest" and event.success:
			valid = valid and event.details.amount == yields[event.day]
	suite._check(valid and rng.state == runner._rng.state, "one equivalent seeded opportunity per day, including waits")
