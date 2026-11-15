extends "res://scripts/sim/world_state.gd"
## Agents-only projection and command boundary; M0/M2 use the original world.

const Trading = preload("res://scripts/sim/trading_runner.gd")
const SELLERS = {"wheat": "farmer", "flour": "miller", "bread": "baker"}
const PHASE_ACTIONS = {"inputs": ["purchase", "wait"], "work": ["harvest", "produce", "wait"],
	"food": ["purchase", "wait"], "meal": ["consume", "wait"]}


func observe(actor: String) -> Dictionary:
	assert(_entities.has(actor))
	# Derive need from authoritative receipts, without a second mutable needs store.
	var meals_due: int = 1
	for index in range(_events.size() - 1, -1, -1):
		var event: Dictionary = _events[index]
		if event.day != _day:
			break
		if event.action == "consume" and event.actor == actor and event.success:
			meals_due = 0
			break
	var person: Dictionary = _entities[actor]
	var market: Dictionary = {}
	for item in SELLERS:
		var seller: String = SELLERS[item]
		market[item] = {"seller": seller, "unit_price": Trading.PRICES[item],
			"stock": _entities[seller].inventory[item]}
	return {"day": _day, "self": {"id": actor, "role": person.role, "money": person.money,
		"inventory": person.inventory.duplicate(true)}, "needs": {"meals_due": meals_due}, "market": market}


func execute_decision(actor: String, phase: String, proposal: Dictionary, harvest_yield: int = 0) -> bool:
	var action: Dictionary = proposal.get("action", {}) if proposal.get("action", {}) is Dictionary else {}
	var success: bool = false
	var command_id: Variant = null
	var execution_reason: String = ""
	var outcome: String = "rejected"
	var before_count: int = _events.size()
	if not _entities.has(actor):
		execution_reason = "unknown_actor"
	elif not PHASE_ACTIONS.has(phase) or action.get("type", "") not in PHASE_ACTIONS[phase]:
		execution_reason = "invalid_action"
	elif action.get("type", "") == "wait":
		success = true
		outcome = "wait"
	elif action.get("type", "") == "purchase":
		var item: Variant = action.get("item")
		if not item is String or not SELLERS.has(item) or action.get("seller") != SELLERS[item] \
				or action.get("unit_price") != Trading.PRICES[item]:
			execution_reason = "invalid_market_offer"
		else:
			success = purchase(actor, SELLERS[item], item, action.get("quantity"), action.get("unit_price"))
	elif action.get("type", "") == "produce" and action.get("recipe") is String:
		success = produce(actor, action.recipe, action.get("batches"))
	elif action.get("type", "") == "harvest" and harvest_yield >= 2 and harvest_yield <= 6:
		success = harvest(actor, harvest_yield)
	elif action.get("type", "") == "consume":
		if observe(actor).needs.meals_due == 0:
			execution_reason = "no_meal_due"
		else:
			success = consume(actor)
	else:
		execution_reason = "invalid_action"
	if _events.size() > before_count:
		command_id = _events.back().id
		execution_reason = _events.back().details.get("reason", "")
	if success and outcome != "wait":
		outcome = "executed"
	_record("decision", actor, action.get("seller", "") if action.get("seller", "") is String else "", success,
		{"phase": phase, "selected_action": action, "reason": proposal.get("reason", "unspecified"),
		"outcome": outcome, "execution_reason": execution_reason, "command_event_id": command_id})
	return success
