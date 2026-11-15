extends RefCounted

const Runner = preload("res://scripts/sim/market_runner.gd")
const World = preload("res://scripts/sim/market_world.gd")
const Policy = preload("res://scripts/sim/market_policy.gd")
const Goals = preload("res://scripts/sim/npc_policy.gd")
const Planning = preload("res://scripts/sim/planning_runner.gd")
const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const CommercialTests = preload("res://tests/coordination_tests.gd")


static func run(suite: SceneTree) -> void:
	_test_offers_and_privacy(suite)
	_test_competition_and_authority(suite)
	_test_agreements(suite)
	_test_baselines(suite)
	var empty = Runner.new(42)
	suite._check(empty.world.snapshot() == empty.report().initial and empty.report().decisions.total == 0,
		"market zero-day report creates no goods, money, or agreements")
	suite._check(empty.participant_ids() == ["farmer", "farmer_2", "miller", "baker", "baker_2", "laborer"],
		"market schedule uses occupation then stable ID")
	var originals: Array = Simulation.default_entities()
	for person in originals:
		var stored: Dictionary = empty.world.snapshot().entities[person.id].duplicate(true)
		stored["id"] = person.id
		suite._check(stored == person, "original endowment preserved: " + person.id)
	for seed_value in [7, 42, 99]:
		for days in [30, 365]:
			var first = Runner.new(seed_value)
			var second = Runner.new(seed_value)
			first.run(days)
			second.run(12)
			second.run(days - 12)
			suite._check(first.world.snapshot() == second.world.snapshot(), "market state replays across split run")
			suite._check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()), "market ledger replays")
			suite._check(JSON.stringify(first.report()) == JSON.stringify(second.report()), "market report replays")
			suite._audit(first.world.events(), first.world.snapshot())
			_check_report(suite, first)
			var rng = RandomNumberGenerator.new()
			rng.seed = seed_value
			for _index in days * 2:
				rng.randi_range(2, 6)
			suite._check(first._rng.state == rng.state, "every farmer gets one seeded opportunity daily, including waits")


static func _person(entities: Array, actor: String) -> Dictionary:
	for person in entities:
		if person.id == actor:
			return person
	return {}


static func _choose(world: RefCounted, actor: String, phase: String) -> Dictionary:
	return Policy.decide(world.observe(actor), Goals.DEFAULT_GOALS, phase)


static func _test_offers_and_privacy(suite: SceneTree) -> void:
	var entities: Array = Runner.market_entities()
	_person(entities, "farmer").inventory.wheat = 2
	_person(entities, "farmer_2").inventory.wheat = 5
	_person(entities, "baker").inventory.bread = 2
	_person(entities, "baker_2").inventory.bread = 4
	_person(entities, "laborer").inventory.bread = 0
	var world = World.new(entities)
	var observation: Dictionary = world.observe("miller")
	suite._check(observation.offers.wheat.size() == 2 and observation.offers.bread.size() == 2
		and observation.offers.flour.size() == 1, "all and only occupational public sellers are discoverable")
	var proposal: Dictionary = _choose(world, "miller", "inputs")
	suite._check(proposal.action.type == "purchase" and proposal.action.seller == "farmer_2"
		and proposal.action.quantity == 4, "miller selects greater advertised wheat stock")
	suite._check(_choose(world, "laborer", "food").action.seller == "baker_2", "food buyer independently selects second baker")
	var own: Dictionary = Policy.selected_observation(world.observe("baker_2"))
	suite._check(own.market.bread.seller == "baker_2", "same own-output rule applies to second baker")
	for actor in ["farmer", "farmer_2"]:
		var choice: Dictionary = _choose(world, actor, "work")
		suite._check(choice.action.type == ("harvest" if actor == "farmer" else "wait"), "farmer choice follows own stock target")
	for actor in ["baker", "baker_2"]:
		var changed: Dictionary = world.observe(actor)
		changed.self.inventory.bread = 0
		changed.offers.flour[0].stock = 4
		var choice: Dictionary = Policy.decide(changed, Goals.DEFAULT_GOALS, "inputs")
		suite._check(choice.action.type == "purchase" and choice.action.seller == "miller"
			and choice.action.quantity == 4, "both bakers use common input behavior")
	var ranked: Array = [{"seller": "z", "unit_price": 1, "stock": 2}, {"seller": "a", "unit_price": 2, "stock": 100}]
	suite._check(Policy.select_offer(ranked).seller == "z", "lower price wins before stock")
	ranked[1].unit_price = 1
	suite._check(Policy.select_offer(ranked).seller == "a", "higher stock wins equal-price choice")
	ranked[0].stock = 100
	suite._check(Policy.select_offer(ranked).seller == "a", "stable ID breaks equal price and stock")
	ranked.reverse()
	suite._check(Policy.select_offer(ranked).seller == "a", "discovery order cannot alter tie resolution")
	ranked[0].stock = 0
	suite._check(Policy.select_offer(ranked).seller == "z", "empty cheap/equal-price offers do not block real stock")
	ranked[1].stock = 0
	suite._check(Policy.select_offer(ranked).stock == 0 and Policy.select_offer([]).is_empty(), "zero-stock and absent offers stay unavailable")
	var private_entities: Array = entities.duplicate(true)
	_person(private_entities, "farmer_2").money = 999
	_person(private_entities, "baker_2").inventory.wheat = 37
	var private_world = World.new(private_entities)
	suite._check(observation == private_world.observe("miller"), "seller cash and unadvertised stock cannot enter observations")
	suite._check(proposal == _choose(private_world, "miller", "inputs"), "hidden seller facts cannot influence selection or planning")
	var original: Dictionary = observation.duplicate(true)
	var goals: Dictionary = Goals.DEFAULT_GOALS.duplicate(true)
	var before: Dictionary = world.snapshot()
	Policy.decide(observation, goals, "inputs")
	suite._check(observation == original and goals == Goals.DEFAULT_GOALS and world.snapshot() == before,
		"selection and planning are pure and do not reserve advertised inventory")
	observation.offers.wheat[0].stock = 999
	observation.self.money = 999
	suite._check(world.observe("miller") == original, "public observations are isolated deep copies")
	entities.reverse()
	var reordered = Runner.new(42, entities)
	suite._check(reordered.participant_ids() == Runner.new().participant_ids(), "initial array order does not determine turn priority")


static func _test_competition_and_authority(suite: SceneTree) -> void:
	var entities: Array = Runner.market_entities()
	_person(entities, "miller").inventory.flour = 2
	var world = World.new(entities)
	var first: Dictionary = _choose(world, "baker", "inputs")
	var stale: Dictionary = _choose(world, "baker_2", "inputs")
	suite._check(first.action.quantity == 2 and stale.action.quantity == 2, "competing bakers observe the same two real flour")
	suite._check(world.execute_decision("baker", "inputs", first), "first competitor buys through world purchase authority")
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("baker_2", "inputs", stale) and world.snapshot() == before,
		"stale competing purchase fails atomically without duplicating or charging")
	suite._check(world.events().back().details.execution_reason == "insufficient_stock", "stock competition records authoritative failure")
	suite._check(_choose(world, "baker_2", "inputs").action.type == "wait", "fresh choice observes exhausted stock")
	suite._check(world.events()[1].action == "purchase" and world.events()[1].target == "miller", "execution records the real selected supplier")
	suite._audit(world.events(), world.snapshot())
	var fixture = Runner.new(42, entities)
	fixture.world.execute_decision("baker", "inputs", first)
	fixture.world.execute_decision("baker_2", "inputs", stale)
	var report: Dictionary = fixture.report()
	suite._check(report.purchases.successful == 1 and report.purchases.rejected == 1
		and report.participants.miller.sales_successful == 1 and report.participants.miller.sales_failed == 1
		and report.participants.baker_2.purchases_failed == 1, "report counts successful and failed stock competition by buyer and seller")
	suite._check(report.participants.baker_2.selected_suppliers == {"miller": 1}
		and report.cash_flow.miller.sales == 4 and report.cash_flow.baker_2.spent == 0,
		"failed selection is observable but contributes no cash or goods flow")
	suite._check(report.failures == {"purchase:insufficient_stock": 1}, "failed decision and purchase count once in economic failures")
	entities = Runner.market_entities()
	_person(entities, "farmer_2").inventory.wheat = 5
	world = World.new(entities)
	var legitimate: Dictionary = _choose(world, "miller", "inputs")
	for change in [{"seller": "laborer"}, {"seller": "missing"}, {"unit_price": 0}, {"quantity": -1}, {"quantity": 9223372036854775807}]:
		var forged: Dictionary = legitimate.duplicate(true)
		for key in change:
			forged.action[key] = change[key]
		before = world.snapshot()
		suite._check(not world.execute_decision("miller", "inputs", forged) and world.snapshot() == before,
			"authority rejects forged offer or invalid arithmetic without mutation")
	legitimate.action["buyer"] = "laborer"
	suite._check(world.execute_decision("miller", "inputs", legitimate)
		and world.snapshot().entities.laborer.inventory.wheat == 0 and world.snapshot().entities.miller.inventory.wheat == 4,
		"actor is authoritative and proposal cannot redirect buyer")
	suite._check(world.snapshot().entities.farmer_2.money == 34, "second farmer receives exact real sale proceeds")
	suite._audit(world.events(), world.snapshot())
	# Switching supplier uses fresh public stock, with no preference for a name.
	world.harvest("farmer", 6)
	suite._check(Policy.selected_observation(world.observe("miller")).market.wheat.seller == "farmer",
		"supplier choice switches when the other public offer becomes larger")
	# Money becomes stale independently of public offers.
	world = World.new(entities)
	legitimate = _choose(world, "miller", "inputs")
	world.transfer_money("miller", "laborer", 20)
	before = world.snapshot()
	suite._check(not world.execute_decision("miller", "inputs", legitimate) and world.snapshot() == before,
		"stale affordability cannot bypass atomic purchase")


static func _test_agreements(suite: SceneTree) -> void:
	var entities: Array = Runner.market_entities()
	_person(entities, "miller").inventory.flour = 2
	_person(entities, "baker_2").money = 0
	var world = World.new(entities)
	suite._check(world.post_request("miller", "wheat", 2), "public request is not tied to the historical single farmer")
	for actor in ["farmer", "farmer_2"]:
		suite._check(world.observe(actor).requests.size() == 1
			and _choose(world, actor, "accept").action.type == "accept_request", "both farmers can independently evaluate public request")
	suite._check(world.execute_decision("farmer_2", "accept", _choose(world, "farmer_2", "accept")), "second farmer voluntarily accepts with real prepayment")
	CommercialTests._reject(suite, world, "accept_request", ["farmer", "r1"], "invalid_status")
	suite._check(world.observe("farmer").requests.is_empty() and world.observe("laborer").requests.is_empty(),
		"unrelated accepted commitments are private")
	CommercialTests._reject(suite, world, "fulfill_request", ["farmer_2", "r1"], "insufficient_stock")
	world.execute_decision("farmer_2", "work", _choose(world, "farmer_2", "work"), 4)
	suite._check(world.execute_decision("farmer_2", "delivery", _choose(world, "farmer_2", "delivery")), "second farmer harvests and fulfills actual promised wheat")
	CommercialTests._reject(suite, world, "fulfill_request", ["farmer_2", "r1"], "invalid_status")
	suite._check(world.post_request("farmer", "bread", 2), "customer requests bread from public baker pool")
	for actor in ["baker", "baker_2"]:
		suite._check(_choose(world, actor, "accept").action.type == "accept_request", "both bakers evaluate the same production opportunity")
	suite._check(world.execute_decision("baker_2", "accept", _choose(world, "baker_2", "accept")), "second baker accepts prepaid bread request")
	CommercialTests._reject(suite, world, "accept_request", ["baker", "r2"], "invalid_status")
	# Initial bread is real deliverable stock; move it through the authoritative sink
	# before testing the prepaid-input production chain.
	world.consume("baker_2")
	world.execute_decision("baker_2", "inputs", _choose(world, "baker_2", "inputs"))
	world.execute_decision("baker_2", "work", _choose(world, "baker_2", "work"))
	suite._check(world.execute_decision("baker_2", "delivery", _choose(world, "baker_2", "delivery"))
		and world.snapshot().requests.r2.status == "fulfilled",
		"second baker uses prepaid coins for flour, production, and one-time delivery")
	suite._check(world.snapshot().entities.baker_2.inventory.bread == 1
		and world.snapshot().entities.farmer.inventory.bread == 3, "bread recipe and transfer conserve declared stock")
	suite._audit(world.events(), world.snapshot())
	world = World.new(Runner.market_entities())
	world.post_request("laborer", "bread", 1)
	world.post_request("farmer", "bread", 1)
	world.post_request("farmer_2", "bread", 1)
	world.accept_request("baker", "r1")
	world.accept_request("baker_2", "r2")
	CommercialTests._reject(suite, world, "accept_request", ["baker_2", "r3"], "supplier_busy")
	CommercialTests._reject(suite, world, "post_request", ["farmer_2", "bread", 1], "active_request_exists")
	CommercialTests._reject(suite, world, "accept_request", ["farmer_2", "r3"], "ineligible_supplier")
	CommercialTests._reject(suite, world, "post_request", ["baker_2", "bread", 1], "self_supply")
	suite._audit(world.events(), world.snapshot())


static func _test_baselines(suite: SceneTree) -> void:
	var hashes = {"commitment-first": ["0f90a40f0e3f32e19bbbdbb44ba2f783dee42cdee2c989d1db0b6ddcecf1ad72",
		"61318efc50bea7b7fe0a75fa72ee414d209f981e90de9d58fda39774d3170469"],
		"immediate-needs-first": ["a085c5bc2f0cbf1ca5da044393f69c4f1bc232bb4a34c845b782bd70aacc3585",
		"3ca879b7e9f4294e8eef97e7419d4ded56447a05ccec4f9b295eb90415030ddb"]}
	for priority in hashes:
		for index in 2:
			var baseline = Planning.new(42, [], Goals.DEFAULT_GOALS, priority)
			baseline.run([30, 365][index])
			var payload: String = JSON.stringify({"report": baseline.report(), "events": baseline.world.events()}, "\t", true) + "\n"
			suite._check(payload.sha256_text() == hashes[priority][index], "historical M5 full JSON hash unchanged")


static func _check_report(suite: SceneTree, runner: RefCounted) -> void:
	var report: Dictionary = runner.report()
	var history: Array = runner.world.events()
	var money: int = 0
	var holdings: Dictionary = {"wheat": 0, "flour": 0, "bread": 0}
	var counts: Dictionary = {}
	for actor in runner.participant_ids():
		money += report.final.entities[actor].money
		for item in holdings:
			holdings[item] += report.final.entities[actor].inventory[item]
		counts[actor] = {"cash_in": 0, "cash_out": 0, "consumed": 0, "unmet": 0, "bought": 0, "failed": 0,
			"sales": 0, "sales_failed": 0, "selected": {}, "produced": {"wheat": 0, "flour": 0, "bread": 0},
			"bought_items": {"wheat": 0, "flour": 0, "bread": 0}, "sold_items": {"wheat": 0, "flour": 0, "bread": 0}}
	var valid_decisions: bool = true
	var made: int = 0
	var fulfilled: int = 0
	var prepaid: int = 0
	for event in history:
		var d: Dictionary = event.details
		if event.action == "decision":
			if d.command_event_id != null:
				var command: Dictionary = history[d.command_event_id - 1]
				valid_decisions = valid_decisions and command.actor == event.actor and command.success == event.success
				valid_decisions = valid_decisions and command.id == event.id - 1
			if d.selected_action.type == "purchase":
				var selection: Dictionary = d.selected_action.supplier_selection
				valid_decisions = valid_decisions and Policy.select_offer(selection.candidates) == selection.offer
				valid_decisions = valid_decisions and selection.offer.seller == d.selected_action.seller
			continue
		if event.action == "purchase":
			counts[event.actor]["bought" if event.success else "failed"] += 1
			counts[event.target]["sales" if event.success else "sales_failed"] += 1
			var selections: Dictionary = counts[event.actor].selected
			selections[event.target] = selections.get(event.target, 0) + 1
			if event.success:
				counts[event.actor].cash_out += d.total_price
				counts[event.target].cash_in += d.total_price
				counts[event.actor].bought_items[d.item] += d.quantity
				counts[event.target].sold_items[d.item] += d.quantity
		elif event.action == "consume":
			counts[event.actor]["consumed" if event.success else "unmet"] += d.amount
		elif event.success:
			match event.action:
				"transfer_money":
					counts[event.actor].cash_out += d.amount
					counts[event.target].cash_in += d.amount
				"harvest":
					counts[event.actor].produced.wheat += d.amount
				"produce":
					for item in d.outputs:
						counts[event.actor].produced[item] += d.outputs[item]
				"agreement_accepted":
					made += 1
					prepaid += d.request.payment
				"agreement_fulfilled":
					fulfilled += 1
	var total_meals: int = 0
	var total_unmet: int = 0
	var successful: int = 0
	var failed: int = 0
	for actor in counts:
		var actual: Dictionary = counts[actor]
		var flow: Dictionary = report.cash_flow[actor]
		var person: Dictionary = report.participants[actor]
		suite._check(flow.earned == actual.cash_in and flow.spent == actual.cash_out
			and report.final.entities[actor].money == report.initial.entities[actor].money + flow.earned - flow.spent,
			"market cash flow reconciles for " + actor)
		suite._check(flow.earned == flow.sales + flow.payments_received + flow.prepayments_received
			and flow.spent == flow.purchases + flow.payments_sent + flow.prepayments_sent, "prepayments counted exactly once: " + actor)
		suite._check(person.consumed == actual.consumed and person.unmet_meals == actual.unmet
			and actual.consumed + actual.unmet == report.days, "per-person meals reconcile: " + actor)
		suite._check(person.purchases_successful == actual.bought and person.purchases_failed == actual.failed
			and person.sales_successful == actual.sales and person.sales_failed == actual.sales_failed, "purchases and sales reconcile: " + actor)
		suite._check(person.spot_bought == actual.bought_items and person.spot_sold == actual.sold_items
			and person.produced == actual.produced and person.selected_suppliers == actual.selected, "supplier volumes/selection/production reconcile: " + actor)
		var accepted: int = 0
		var delivered: int = 0
		var outstanding: int = 0
		var goods: Dictionary = {"wheat": 0, "flour": 0, "bread": 0}
		for request in report.final.requests.values():
			if request.supplier == actor and request.accepted_day != null:
				accepted += 1
				if request.status == "fulfilled":
					delivered += 1
					goods[request.item] += request.quantity
				elif request.status == "accepted":
					outstanding += 1
		suite._check(person.agreements_accepted == accepted and person.agreements_fulfilled == delivered
			and person.agreements_outstanding == outstanding and person.agreement_delivered == goods, "supplier agreements reconcile: " + actor)
		total_meals += actual.consumed
		total_unmet += actual.unmet
		successful += actual.bought
		failed += actual.failed
	suite._check(money == 125 and report.final.entities.size() == 6, "exactly six participants conserve 125 initialized coins")
	suite._check(holdings.wheat == report.totals.harvested.wheat - report.totals.production_inputs.wheat
		and holdings.flour == report.totals.production_outputs.flour - report.totals.production_inputs.flour
		and holdings.bread == 6 + report.totals.production_outputs.bread - total_meals, "six-person commodity sources/sinks reconcile")
	suite._check(total_meals == report.totals.consumed.bread and total_meals + total_unmet == 6 * report.days, "all six meal needs accounted for")
	suite._check(successful == report.purchases.successful and failed == report.purchases.rejected, "aggregate purchases reconcile with participants")
	suite._check(made == report.agreements.made and fulfilled == report.agreements.fulfilled and prepaid == report.agreements.prepaid,
		"aggregate agreement events and prepayments reconcile")
	suite._check(report.decisions.total == 37 * report.days and valid_decisions, "37 daily decisions link commands and deterministic supplier selection")
	var before: Dictionary = runner.world.snapshot()
	report.participants.farmer.produced.wheat = -1
	suite._check(runner.world.snapshot() == before and runner.report().participants.farmer.produced.wheat >= 0,
		"report is an isolated projection, without authoritative mutations")
