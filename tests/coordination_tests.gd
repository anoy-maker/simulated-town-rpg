extends RefCounted

const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const Agents = preload("res://scripts/sim/agents_runner.gd")
const World = preload("res://scripts/sim/coordination_world.gd")
const Runner = preload("res://scripts/sim/coordination_runner.gd")
const Policy = preload("res://scripts/sim/coordination_policy.gd")
const Goals = preload("res://scripts/sim/npc_policy.gd")


static func run(suite: SceneTree) -> void:
	_test_lifecycle(suite)
	_test_failures(suite)
	_test_choices(suite)
	var empty = Runner.new(42)
	empty.run(0)
	suite._check(empty.report().initial == empty.report().final and empty.report().agreements.requests == 0,
		"zero-day coordination creates no implicit agreements")
	for days in [30, 365]:
		var first = Runner.new(42)
		var second = Runner.new(42)
		first.run(days)
		second.run(12)
		second.run(days - 12)
		suite._check(first.world.snapshot() == second.world.snapshot(), "coordination state replays across split runs")
		suite._check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()), "coordination events replay")
		suite._check(JSON.stringify(first.report()) == JSON.stringify(second.report()), "coordination report replays")
		suite._audit(first.world.events(), first.world.snapshot())
		_check_report(suite, first)
		var baseline = Agents.new(42)
		baseline.run(days)
		var payload = JSON.stringify({"report": baseline.report(), "events": baseline.world.events()}, "\t", true) + "\n"
		var expected: String = "53ca0029214319d352453c62e637340a7ae6b2e75bc42c29504885f5c0acef82" if days == 30 \
			else "d8f65499e0fe1d08cebc4485d18220a20f361fef42c9abdf92193e7b720ac2b2"
		suite._check(payload.sha256_text() == expected, "historical M3 output is unchanged")
		suite._check(first.report().initial.entities == baseline.report().initial.entities
			and first.report().prices == baseline.report().prices and first.report().goals == baseline.report().goals
			and first.report().daily_payment == baseline.report().daily_payment, "coordination preserves M3 economic parameters")


static func _reject(suite: SceneTree, world: RefCounted, method: String, args: Array, reason: String) -> void:
	var before: Dictionary = world.snapshot()
	var result: bool = world.callv(method, args)
	suite._unchanged(world, before, result, method + ":" + reason)
	suite._check(world.events().back().details.reason == reason, "lifecycle rejection gives exact reason")


static func _test_lifecycle(suite: SceneTree) -> void:
	var entities = Simulation.default_entities()
	entities[0].inventory.wheat = 10
	entities[1].money = 0
	var world = World.new(entities)
	suite._check(world.post_request("baker", "flour", 4), "buyer advertises a fixed-price supply request")
	var request: Dictionary = world.snapshot().requests.r1
	suite._check(request.status == "open" and request.payment == 8 and request.unit_price == 2
		and request.buyer == "baker" and request.supplier == "", "request states exact terms and status")
	suite._check(world.snapshot().entities.baker.money == 20 and world.snapshot().entities.miller.money == 0,
		"posting transfers no money")
	_reject(suite, world, "post_request", ["baker", "flour", 2], "active_request_exists")
	_reject(suite, world, "accept_request", ["laborer", "r1"], "ineligible_supplier")
	suite._check(world.accept_request("miller", "r1"), "eligible supplier accepts request")
	suite._check(world.snapshot().entities.baker.money == 12 and world.snapshot().entities.miller.money == 8,
		"acceptance transfers exact prepayment once")
	_reject(suite, world, "accept_request", ["miller", "r1"], "invalid_status")
	_reject(suite, world, "fulfill_request", ["baker", "r1"], "not_supplier")
	_reject(suite, world, "fulfill_request", ["miller", "r1"], "insufficient_stock")
	suite._check(world.snapshot().requests.r1.status == "accepted" and world.snapshot().entities.baker.money == 12,
		"failed delivery preserves obligation without refund")
	world.advance_day()
	world.record_outstanding()
	suite._check(world.events().back().action == "agreement_outstanding"
		and world.snapshot().requests.r1.status == "accepted", "unfulfilled commitments remain recorded across days")
	suite._check(world.purchase("miller", "farmer", "wheat", 4, 1), "supplier spends prepaid money in ordinary purchase")
	suite._check(world.produce("miller", "mill", 2), "prepaid inputs enable actual production")
	suite._check(world.fulfill_request("miller", "r1"), "supplier delivers real produced goods")
	suite._check(world.snapshot().entities.baker.inventory.flour == 4 and world.snapshot().entities.miller.inventory.flour == 0
		and world.snapshot().requests.r1.status == "fulfilled", "delivery transfers exact stock and settles obligation")
	suite._check(world.snapshot().entities.baker.money == 12 and world.snapshot().entities.miller.money == 4,
		"delivery never charges a second payment")
	_reject(suite, world, "fulfill_request", ["miller", "r1"], "invalid_status")
	_reject(suite, world, "close_request", ["baker", "r1", "done"], "invalid_closure")
	suite._check(world.events()[1].details.request.status == "open", "later changes cannot alter past event records")
	suite._audit(world.events(), world.snapshot())


static func _test_failures(suite: SceneTree) -> void:
	var world = World.new(Simulation.default_entities())
	for quantity in [0, -1, 1.0, NAN, INF, "1", null, true, World.MAX_AMOUNT + 1, 9223372036854775807]:
		_reject(suite, world, "post_request", ["baker", "flour", quantity], "invalid_amount")
	for args in [["baker", "gold", 1, "unknown_item"], ["missing", "flour", 1, "unknown_actor"],
		["miller", "flour", 1, "self_supply"], ["baker", "flour", World.MAX_AMOUNT, "payment_limit"],
		["baker", "flour", 11, "insufficient_money"]]:
		_reject(suite, world, "post_request", args.slice(0, 3), args[3])
	_reject(suite, world, "accept_request", ["miller", "missing"], "unknown_request")
	world.post_request("baker", "flour", 4)
	world.transfer_money("baker", "farmer", 20)
	_reject(suite, world, "accept_request", ["miller", "r1"], "insufficient_money")
	suite._check(world.snapshot().requests.r1.status == "open", "failed prepayment cannot activate agreement")
	var entities = Simulation.default_entities()
	entities[1].money = World.MAX_AMOUNT
	world = World.new(entities)
	world.post_request("baker", "flour", 4)
	_reject(suite, world, "accept_request", ["miller", "r1"], "amount_limit")
	entities = Simulation.default_entities()
	entities[2].inventory.flour = World.MAX_AMOUNT
	world = World.new(entities)
	_reject(suite, world, "post_request", ["baker", "flour", 1], "buyer_inventory_limit")
	entities[2].inventory.flour = World.MAX_AMOUNT - 4
	entities[1].inventory.flour = 5
	world = World.new(entities)
	world.post_request("baker", "flour", 4)
	world.accept_request("miller", "r1")
	world.transfer_item("miller", "baker", "flour", 1)
	_reject(suite, world, "fulfill_request", ["miller", "r1"], "amount_limit")
	suite._check(world.snapshot().requests.r1.status == "accepted", "delivery capacity is revalidated without losing obligation")
	world = World.new(Simulation.default_entities())
	world.post_request("baker", "flour", 2)
	world.post_request("farmer", "flour", 1)
	world.accept_request("miller", "r1")
	_reject(suite, world, "accept_request", ["miller", "r2"], "supplier_busy")
	_reject(suite, world, "close_request", ["miller", "r1", "waive"], "not_buyer")
	_reject(suite, world, "close_request", ["baker", "r1", ""], "invalid_closure")
	var money: int = world.snapshot().entities.baker.money
	suite._check(world.close_request("baker", "r1", "explicit buyer waiver"), "buyer explicitly closes an unfinished claim")
	suite._check(world.snapshot().entities.baker.money == money and world.snapshot().requests.r1.status == "closed",
		"closure preserves history and never refunds prepayment")
	_reject(suite, world, "fulfill_request", ["miller", "r1"], "invalid_status")
	suite._check(world.accept_request("miller", "r2"), "closure releases supplier commitment slot")
	suite._check(world.post_request("baker", "flour", 2), "new request identity after explicit closure")
	suite._audit(world.events(), world.snapshot())


static func _test_choices(suite: SceneTree) -> void:
	var entities = Simulation.default_entities()
	entities[0].money = 0
	entities[0].inventory.wheat = 5
	entities[1].money = 1
	entities[2].money = 73
	entities[3].money = 1
	for entity in entities:
		entity.inventory.bread = 0
	var world = World.new(entities)
	var proposal: Dictionary = Policy.decide(world.observe("baker"), Goals.DEFAULT_GOALS, "requests")
	suite._check(proposal.action.type == "post_request" and proposal.action.item == "flour" and proposal.action.quantity == 4,
		"funded baker requests missing inputs from a public opportunity")
	suite._check(world.execute_decision("baker", "requests", proposal), "posting is an actor-bound decision")
	suite._check(Policy.decide(world.observe("baker"), Goals.DEFAULT_GOALS, "requests").reason == "request_already_active",
		"policy avoids overlapping requests")
	var before: Dictionary = world.observe("miller")
	entities[2].money = 90
	entities[2].inventory.wheat = 99
	var other = World.new(entities)
	other.post_request("baker", "flour", 4)
	suite._check(before == other.observe("miller"), "private buyer cash and stock are excluded from supplier information")
	suite._check(world.observe("laborer").requests.is_empty(), "ineligible non-participants cannot inspect others' agreements")
	var copy: Dictionary = world.observe("miller")
	copy.requests[0].payment = 0
	suite._check(world.snapshot().requests.r1.payment == 8, "observations cannot modify request terms")
	proposal = Policy.decide(world.observe("miller"), Goals.DEFAULT_GOALS, "accept")
	suite._check(proposal.action.type == "accept_request", "supplier voluntarily recognizes prepaid opportunity")
	world.execute_decision("miller", "accept", proposal)
	suite._check(world.observe("miller").self.money == 9, "accepted money becomes supplier working capital")
	suite._check(world.observe("laborer").requests.is_empty(), "accepted agreements remain private to their parties")
	proposal = Policy.decide(world.observe("miller"), Goals.DEFAULT_GOALS, "inputs")
	suite._check(proposal.action.type == "purchase" and proposal.action.quantity == 4, "funded commitment inputs take priority")
	world.execute_decision("miller", "inputs", proposal)
	world.execute_decision("miller", "work", Policy.decide(world.observe("miller"), Goals.DEFAULT_GOALS, "work"))
	proposal = Policy.decide(world.observe("miller"), Goals.DEFAULT_GOALS, "delivery")
	suite._check(proposal.action.type == "fulfill_request", "real stock enables fulfillment decision")
	world.execute_decision("miller", "delivery", proposal)
	suite._check(world.snapshot().requests.r1.status == "fulfilled" and world.snapshot().entities.baker.inventory.flour == 4,
		"independent choices complete the multi-step supply chain")
	suite._audit(world.events(), world.snapshot())
	entities = Simulation.default_entities()
	entities[2].inventory.bread = 0
	world = World.new(entities)
	world.post_request("laborer", "bread", 1)
	suite._check(Policy.decide(world.observe("baker"), Goals.DEFAULT_GOALS, "accept").action.type == "wait",
		"supplier can decline payment below a whole recipe's missing-input cost")
	suite._check(world.snapshot().entities.laborer.money == 5 and world.snapshot().requests.r1.status == "open",
		"unaccepted requests cannot forcibly redistribute money")
	world = World.new(Simulation.default_entities())
	proposal = {"action": {"type": "post_request", "buyer": "farmer", "item": "flour", "quantity": 2, "payment": 0},
		"reason": "attempt_spoof"}
	suite._check(world.execute_decision("baker", "requests", proposal) and world.snapshot().requests.r1.buyer == "baker"
		and world.snapshot().requests.r1.payment == 4, "proposals cannot spoof buyer identity or fixed payment")
	var snapshot: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("miller", "inputs", {"action": {"type": "accept_request", "request_id": "r1"},
		"reason": "wrong_phase"}) and world.snapshot() == snapshot, "new agreements cannot bypass phase validation")


static func _check_report(suite: SceneTree, simulation: RefCounted) -> void:
	var report: Dictionary = simulation.report()
	var history: Array = simulation.world.events()
	var earned: int = 0
	var spent: int = 0
	var total_money: int = 0
	var stock = {"wheat": 0, "flour": 0, "bread": 0}
	for actor in Simulation.IDS:
		var flow: Dictionary = report.cash_flow[actor]
		var entity: Dictionary = report.final.entities[actor]
		earned += flow.earned
		spent += flow.spent
		total_money += entity.money
		suite._check(entity.money == report.initial.entities[actor].money + flow.earned - flow.spent
			and flow.earned == flow.sales + flow.payments_received + flow.prepayments_received
			and flow.spent == flow.purchases + flow.payments_sent + flow.prepayments_sent, "prepaid cash flow reconciles: " + actor)
		var meals: Array = history.filter(func(event): return event.action == "consume" and event.actor == actor and event.success)
		suite._check(meals.size() + report.unmet_meals[actor] == report.days, "coordination meal accounting: " + actor)
		for item in stock:
			stock[item] += entity.inventory[item]
	suite._check(total_money == 75 and earned == spent, "ordinary and prepaid transfers conserve currency")
	suite._check(stock.wheat == report.totals.harvested.wheat - report.totals.production_inputs.wheat
		and stock.flour == report.totals.production_outputs.flour - report.totals.production_inputs.flour
		and stock.bread == 4 + report.totals.production_outputs.bread - report.totals.consumed.bread, "coordination sources and sinks reconcile")
	var accepted: Array = history.filter(func(event): return event.action == "agreement_accepted" and event.success)
	var delivered: Array = history.filter(func(event): return event.action == "agreement_fulfilled" and event.success)
	suite._check(accepted.size() == report.agreements.made and delivered.size() == report.agreements.fulfilled, "agreement report matches events")
	suite._check(report.agreements.made == report.agreements.fulfilled + report.agreements.outstanding + report.agreements.waived,
		"each paid obligation is fulfilled, outstanding, or explicitly waived")
	var prepaid: int = 0
	for event in accepted:
		prepaid += event.details.request.payment
	suite._check(prepaid == report.agreements.prepaid, "prepayment totals match real receipts")
	var outstanding: int = 0
	for request in report.final.requests.values():
		if request.status == "accepted":
			outstanding += 1
			var notifications: Array = history.filter(func(event):
				return event.action == "agreement_outstanding" and event.details.request.id == request.id and event.day == report.days)
			suite._check(not notifications.is_empty(), "each final obligation has an explicit outstanding event")
			notifications = history.filter(func(event): return event.action == "agreement_outstanding" and event.details.request.id == request.id)
			suite._check(notifications.size() == report.days - request.accepted_day + 1, "unfinished agreement is logged every day without silent closure")
	suite._check(outstanding == report.agreements.outstanding, "outstanding count matches authoritative state")
	suite._check(report.payments.successful + report.payments.rejected == report.days
		and report.payments.amount == 2 * report.payments.successful, "prepayments do not inflate employer wages")
	for item in stock:
		suite._check(report.totals.traded[item] == report.totals.spot_traded[item] + report.totals.agreement_delivered[item],
			"spot and agreement trade reconcile: " + item)
		var quantity: int = 0
		for event in delivered:
			if event.details.request.item == item:
				quantity += event.details.request.quantity
		suite._check(quantity == report.agreements.delivered[item] and quantity == report.totals.agreement_delivered[item],
			"reported delivery volumes match exact settled requests: " + item)
	suite._check(report.decisions.total == 24 * report.days, "coordination opportunities are explicit decisions")
	var actions = {"post_request": "request_posted", "accept_request": "agreement_accepted", "fulfill_request": "agreement_fulfilled",
		"close_request": "request_closed"}
	var valid: bool = true
	for index in history.size():
		var event: Dictionary = history[index]
		if event.action != "decision":
			continue
		if event.details.command_event_id == null:
			valid = valid and event.details.outcome == "wait"
		else:
			var command: Dictionary = history[index - 1]
			var selected: String = event.details.selected_action.type
			valid = valid and command.id == event.details.command_event_id and command.actor == event.actor
			valid = valid and command.success == event.success and command.action == actions.get(selected, selected)
	suite._check(valid, "all commercial and economic decisions link their actual authoritative outcomes")
	var before: Dictionary = simulation.world.snapshot()
	suite._check(JSON.stringify(report) == JSON.stringify(simulation.report()) and simulation.world.snapshot() == before,
		"reporting cannot close or mutate commitments")
