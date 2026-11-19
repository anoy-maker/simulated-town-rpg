extends RefCounted

const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const Trading = preload("res://scripts/sim/trading_runner.gd")
const Agents = preload("res://scripts/sim/agents_runner.gd")
const AgentWorld = preload("res://scripts/sim/agent_world.gd")
const Policy = preload("res://scripts/sim/npc_policy.gd")


static func run(suite: SceneTree) -> void:
	_test_choices(suite)
	_test_privacy(suite)
	_test_execution(suite)
	for days in [30, 365]:
		var first = Agents.new(42)
		var second = Agents.new(42)
		first.run(days)
		second.run(12)
		second.run(days - 12)
		suite._check(first.world.snapshot() == second.world.snapshot(), "agents %d-day state replays" % days)
		suite._check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()),
			"agents %d-day events replay across split runs" % days)
		suite._check(JSON.stringify(first.report()) == JSON.stringify(second.report()), "agents report replays")
		suite._audit(first.world.events(), first.world.snapshot())
		_check_accounting(suite, first)
		var trading = Trading.new(42)
		trading.run(days)
		var payload = JSON.stringify({"report": trading.report(), "events": trading.world.events()}, "\t", true) + "\n"
		var expected = "5d569a193111d3ad5ff90dc6317b567596c4b51b4fe54c11e676e3eda0bcd9aa" if days == 30 \
			else "e564ebe6f5638be17f8cfe2b78748bbaebb7907d818a9ade1247b7624ea12278"
		suite._check(payload.sha256_text() == expected, "M2 %d-day historical hash preserved" % days)
		suite._check(first.report().initial == trading.report().initial and first.report().prices == trading.report().prices
			and first.report().daily_payment == trading.report().daily_payment, "agents retain M2 economic parameters")
		var harvests: Dictionary = {}
		for event in trading.world.events():
			if event.action == "harvest":
				harvests[event.day] = event.details.amount
		var same_environment: bool = true
		for event in first.world.events():
			if event.action == "harvest":
				same_environment = same_environment and event.details.amount == harvests[event.day]
		suite._check(same_environment, "agents use the same daily harvest opportunities as M2")
	var empty = Agents.new(42)
	empty.run(0)
	suite._check(empty.report().initial == empty.report().final and empty.report().decisions.total == 0,
		"zero-day agents create no decisions or economic changes")


static func _observation(role: String) -> Dictionary:
	var world = AgentWorld.new(Simulation.default_entities())
	return world.observe(role)


static func _test_choices(suite: SceneTree) -> void:
	var goals: Dictionary = Policy.DEFAULT_GOALS.duplicate(true)
	var observation: Dictionary = _observation("laborer")
	suite._check(Policy.decide(observation, goals, "food").reason == "food_already_covered", "owned food prevents redundant purchase")
	observation.self.inventory.bread = 0
	var choice: Dictionary = Policy.decide(observation, goals, "food")
	suite._check(choice.action.type == "purchase" and choice.action.quantity == 1, "hungry funded NPC buys missing food")
	observation.self.money = 2
	suite._check(Policy.decide(observation, goals, "food").reason == "unaffordable_with_priorities", "unaffordable food causes wait")
	observation.self.money = 5
	observation.market.bread.stock = 0
	suite._check(Policy.decide(observation, goals, "food").reason == "market_unavailable", "unavailable advertised food causes wait")
	observation.market.bread.stock = 1
	observation.needs.meals_due = 0
	suite._check(Policy.decide(observation, goals, "food").reason == "no_meal_due", "no current need avoids food spending")
	suite._check(Policy.decide(observation, goals, "meal").action.type == "wait", "no current meal need avoids eating twice")
	observation.needs.meals_due = 1
	suite._check(Policy.decide(observation, goals, "meal").action.type == "consume", "unmet daily need still attempts real-stock consumption")
	observation = _observation("miller")
	observation.market.wheat.stock = 20
	suite._check(Policy.decide(observation, goals, "inputs").action.quantity == 4, "miller buys only required wheat")
	observation.self.inventory.wheat = 3
	suite._check(Policy.decide(observation, goals, "inputs").action.quantity == 1, "owned inputs reduce required purchase")
	suite._check(Policy.decide(observation, goals, "work").action.batches == 1, "production limited to actual inputs")
	observation.self.inventory.wheat = 4
	suite._check(Policy.decide(observation, goals, "work").action.batches == 2, "adequate inputs allow two batches")
	suite._check(Policy.decide(observation, goals, "inputs").reason == "inputs_already_covered", "owned inputs prevent redundant purchase")
	observation.self.inventory.flour = 4
	suite._check(Policy.decide(observation, goals, "inputs").reason == "output_target_met", "full outputs prevent input spending")
	suite._check(Policy.decide(observation, goals, "work").reason == "output_target_met", "full outputs prevent redundant production")
	goals.output_targets.miller = 6
	suite._check(Policy.decide(observation, goals, "work").action.batches == 1, "configurable output target changes production")
	observation.self.inventory.flour = 0
	observation.self.inventory.wheat = 0
	observation.self.inventory.bread = 0
	observation.self.money = 4
	suite._check(Policy.decide(observation, goals, "inputs").action.quantity == 1, "food priority reserves three coins before buying inputs")
	goals.reserve_food_money = false
	suite._check(Policy.decide(observation, goals, "inputs").action.quantity == 4, "explicit priority setting changes input spending")
	observation.market.wheat.stock = 2
	suite._check(Policy.decide(observation, goals, "inputs").action.quantity == 2, "market information limits order size")
	observation = _observation("baker")
	observation.self.inventory.bread = 0
	observation.self.money = 4
	observation.market.flour.stock = 4
	suite._check(Policy.decide(observation, Policy.DEFAULT_GOALS, "inputs").action.quantity == 2,
		"baker funds food production instead of reserving coins for self-purchase")
	suite._check(Policy.decide(observation, goals, "work").reason == "missing_inputs", "missing actual inputs prevent production")
	observation = _observation("farmer")
	suite._check(Policy.decide(observation, goals, "work").action.type == "harvest", "farmer below target harvests")
	observation.self.inventory.wheat = 4
	suite._check(Policy.decide(observation, goals, "work").action.type == "wait", "farmer at target conserves output")
	observation = _observation("laborer")
	suite._check(Policy.decide(observation, goals, "work").reason == "no_production_role", "occupation controls work choices")
	var before: Dictionary = observation.duplicate(true)
	var goal_copy: Dictionary = goals.duplicate(true)
	Policy.decide(observation, goals, "food")
	suite._check(observation == before and goals == goal_copy, "policy is pure over observations and goals")


static func _test_privacy(suite: SceneTree) -> void:
	var entities = Simulation.default_entities()
	var world = AgentWorld.new(entities)
	var original: Dictionary = world.observe("laborer")
	entities[0].money = 999
	entities[0].inventory.flour = 77
	entities[1].inventory.bread = 88
	entities[2].inventory.wheat = 99
	var changed = AgentWorld.new(entities)
	suite._check(original == changed.observe("laborer"), "other NPC money and unadvertised inventory are inaccessible")
	suite._check(original.keys().size() == 4 and not original.has("entities") and not original.has("events")
		and original.self.keys().size() == 4, "observation exposes only day, self, needs, and public offers")
	for offer in original.market.values():
		suite._check(offer.keys().size() == 3 and not offer.has("money") and not offer.has("inventory"), "public offers exclude private seller state")
	var before: Dictionary = world.snapshot()
	original.self.inventory.bread = 999
	original.market.bread.stock = 999
	suite._check(world.snapshot() == before and world.observe("laborer").market.bread.stock == 1,
		"observation mutation cannot affect authoritative or public stock")
	entities[2].inventory.bread = 4
	changed = AgentWorld.new(entities)
	suite._check(changed.observe("laborer").market.bread.stock == 4, "explicitly advertised stock is public")
	world.consume("laborer")
	suite._check(world.observe("laborer").needs.meals_due == 0, "successful consumption clears the observed daily need")
	suite._check(Policy.decide(world.observe("laborer"), Policy.DEFAULT_GOALS, "food").reason == "no_meal_due",
		"authoritative meal receipt prevents unnecessary food spending")
	world.advance_day()
	suite._check(world.observe("laborer").needs.meals_due == 1, "a new day resets the meal requirement")


static func _test_execution(suite: SceneTree) -> void:
	var entities = Simulation.default_entities()
	entities[3].inventory.bread = 0
	var world = AgentWorld.new(entities)
	var proposal: Dictionary = Policy.decide(world.observe("laborer"), Policy.DEFAULT_GOALS, "food")
	world.transfer_money("laborer", "farmer", 5)
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("laborer", "food", proposal) and world.snapshot() == before,
		"stale affordable proposal is rejected atomically by current world validation")
	var decision: Dictionary = world.events().back()
	suite._check(decision.action == "decision" and not decision.success and decision.details.reason == "food_needed"
		and decision.details.execution_reason == "insufficient_money" and decision.details.outcome == "rejected",
		"decision records intent separately from actual rejection")
	suite._check(decision.details.command_event_id == world.events()[-2].id, "decision links exact underlying command event")
	var attempts = [
		{"action": {"type": "transfer_money", "amount": 999}, "reason": "unauthorized_action"},
		{"action": {"type": "purchase", "seller": "baker", "item": "bread", "quantity": 1, "unit_price": 0}, "reason": "fake_price"},
		{"action": {"type": "produce", "recipe": "bake", "batches": 1}, "reason": "wrong_phase"},
	]
	for attempt in attempts:
		suite._check(not world.execute_decision("laborer", "food", attempt) and world.snapshot() == before,
			"untrusted proposal cannot bypass phase, fixed price, or command allowlist")
	var count: int = world.events().size()
	suite._check(world.execute_decision("laborer", "food", {"action": {"type": "wait"}, "reason": "unaffordable"})
		and world.snapshot() == before and world.events().size() == count + 1, "wait records decision without economic changes")
	suite._check(world.events().back().details.command_event_id == null, "wait has no fabricated execution event")
	world.transfer_money("farmer", "laborer", 3)
	proposal.action["buyer"] = "farmer"
	suite._check(world.execute_decision("laborer", "food", proposal), "valid proposal executes existing purchase command")
	suite._check(world.snapshot().entities.laborer.money == 0 and world.snapshot().entities.farmer.money == 32,
		"proposal cannot spoof the account charged for a purchase")
	proposal.action.quantity = 999
	suite._check(world.events().back().details.selected_action.quantity == 1, "recorded proposal is isolated from caller mutations")
	suite._audit(world.events(), world.snapshot())
	world = AgentWorld.new(entities)
	proposal = Policy.decide(world.observe("laborer"), Policy.DEFAULT_GOALS, "food")
	world.consume("baker")
	before = world.snapshot()
	suite._check(not world.execute_decision("laborer", "food", proposal) and world.snapshot() == before
		and world.events().back().details.execution_reason == "insufficient_stock",
		"stale stock information cannot create goods or charge the buyer")
	suite._check(world.execute_decision("farmer", "work", {"action": {"type": "harvest", "amount": 999},
		"reason": "wheat_below_target"}, 2) and world.snapshot().entities.farmer.inventory.wheat == 2,
		"harvest uses authoritative environmental yield, not a proposed amount")
	entities[3].inventory.bread = 2
	world = AgentWorld.new(entities)
	world.execute_decision("laborer", "meal", {"action": {"type": "consume"}, "reason": "meal_due"})
	before = world.snapshot()
	suite._check(not world.execute_decision("laborer", "meal", {"action": {"type": "consume"}, "reason": "stale_meal"})
		and world.snapshot() == before and world.events().back().details.execution_reason == "no_meal_due",
		"executor rejects a duplicate daily meal even when bread remains")


static func _check_accounting(suite: SceneTree, simulation: RefCounted) -> void:
	var report: Dictionary = simulation.report()
	var events: Array = simulation.world.events()
	var money: int = 0
	var stock = {"wheat": 0, "flour": 0, "bread": 0}
	for actor in Simulation.IDS:
		var entity: Dictionary = report.final.entities[actor]
		var flow: Dictionary = report.cash_flow[actor]
		money += entity.money
		suite._check(entity.money == report.initial.entities[actor].money + flow.earned - flow.spent, "agents cash flow reconciles: " + actor)
		var meals: Array = events.filter(func(event): return event.action == "consume" and event.actor == actor and event.success)
		suite._check(meals.size() + report.unmet_meals[actor] == report.days, "agents meal accounting: " + actor)
		for item in stock:
			stock[item] += entity.inventory[item]
	suite._check(money == 75, "agents preserve total currency")
	suite._check(stock.wheat == report.totals.harvested.wheat - report.totals.production_inputs.wheat
		and stock.flour == report.totals.production_outputs.flour - report.totals.production_inputs.flour
		and stock.bread == 4 + report.totals.production_outputs.bread - report.totals.consumed.bread,
		"agents stock reconciles to explicit sources and sinks")
	var valid: bool = true
	var decision_count: int = 0
	var rejected: int = 0
	var operation_failures: int = 0
	for index in events.size():
		var event: Dictionary = events[index]
		if event.action == "decision":
			decision_count += 1
			var details: Dictionary = event.details
			if not event.success:
				rejected += 1
			if details.command_event_id != null:
				var command: Dictionary = events[index - 1]
				valid = valid and command.id == details.command_event_id and command.actor == event.actor
				valid = valid and command.success == event.success and command.action == details.selected_action.type
			else:
				valid = valid and details.outcome == "wait"
		elif not event.success:
			operation_failures += 1
	suite._check(valid, "every decision records its exact authoritative execution or explicit wait")
	suite._check(decision_count == 13 * report.days and report.decisions.total == decision_count
		and report.decisions.rejected == rejected, "decision counts match actor opportunities and execution outcomes")
	suite._check(report.decisions.executed + report.decisions.rejected + report.decisions.wait == decision_count,
		"decision execution outcomes partition all opportunities")
	for category in ["by_actor", "by_action", "by_reason"]:
		var count: int = 0
		for amount in report.decisions[category].values():
			count += amount
		suite._check(count == decision_count, "decision frequency totals reconcile: " + category)
	var count: int = 0
	for amount in report.failures.values():
		count += amount
	suite._check(count == operation_failures, "decision rejection does not double-count economic failures")
	var before: Dictionary = simulation.world.snapshot()
	suite._check(JSON.stringify(report) == JSON.stringify(simulation.report()) and simulation.world.snapshot() == before,
		"report is deterministic and does not modify world")
