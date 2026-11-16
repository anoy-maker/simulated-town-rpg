extends RefCounted
## Authoritative state. Callers receive copies; commands validate before writing.

const ITEMS = ["wheat", "flour", "bread"]
const ROLES = ["farmer", "miller", "baker", "laborer"]
# A deliberate bound keeps all arithmetic comfortably inside signed 64-bit integers.
const MAX_AMOUNT = 1_000_000_000
const RECIPES = {
	"mill": {"role": "miller", "inputs": {"wheat": 2}, "outputs": {"flour": 2}},
	"bake": {"role": "baker", "inputs": {"flour": 2}, "outputs": {"bread": 3}},
}

var _entities: Dictionary = {}
var _events: Array = []
var _day: int = 0


func _init(initial_entities: Array) -> void:
	for entity in initial_entities:
		assert(entity.id is String and not entity.id.is_empty())
		assert(not _entities.has(entity.id) and _valid_entity_role(entity))
		assert(entity.money is int and entity.money >= 0 and entity.money <= MAX_AMOUNT)
		assert(entity.inventory.size() == ITEMS.size())
		for item in ITEMS:
			assert(entity.inventory.has(item))
			assert(entity.inventory[item] is int)
			assert(entity.inventory[item] >= 0 and entity.inventory[item] <= MAX_AMOUNT)
		_entities[entity.id] = entity.duplicate(true)
	_record("initialize", "world", "", true, {"state": snapshot()})


func _valid_entity_role(entity: Dictionary) -> bool:
	return entity.role in ROLES


func snapshot() -> Dictionary:
	return {"day": _day, "entities": _entities.duplicate(true)}


func events() -> Array:
	return _events.duplicate(true)


func advance_day() -> void:
	_day += 1
	_record("day_started", "world", "", true, {})


func transfer_item(actor: String, target: String, item: String, amount: Variant) -> bool:
	var details = {"item": item, "amount": amount}
	var reason = _transfer_error(actor, target, amount)
	if reason.is_empty() and item not in ITEMS:
		reason = "unknown_item"
	if reason.is_empty() and _entities[actor].inventory[item] < amount:
		reason = "insufficient_stock"
	if reason.is_empty() and _entities[target].inventory[item] + amount > MAX_AMOUNT:
		reason = "amount_limit"
	if not reason.is_empty():
		return _reject("transfer_item", actor, target, details, reason)
	_entities[actor].inventory[item] -= amount
	_entities[target].inventory[item] += amount
	_record("transfer_item", actor, target, true, details)
	return true


func transfer_money(actor: String, target: String, amount: Variant) -> bool:
	var details = {"amount": amount}
	var reason = _transfer_error(actor, target, amount)
	if reason.is_empty() and _entities[actor].money < amount:
		reason = "insufficient_money"
	if reason.is_empty() and _entities[target].money + amount > MAX_AMOUNT:
		reason = "amount_limit"
	if not reason.is_empty():
		return _reject("transfer_money", actor, target, details, reason)
	_entities[actor].money -= amount
	_entities[target].money += amount
	_record("transfer_money", actor, target, true, details)
	return true


func purchase(buyer: String, seller: String, item: String, quantity: Variant, unit_price: Variant) -> bool:
	var details = {"buyer": buyer, "seller": seller, "item": item,
		"quantity": quantity, "unit_price": unit_price, "total_price": null}
	var reason = _transfer_error(buyer, seller, quantity)
	if reason.is_empty() and item not in ITEMS:
		reason = "unknown_item"
	if reason.is_empty() and (not unit_price is int or unit_price < 0 or unit_price > MAX_AMOUNT):
		reason = "invalid_unit_price"
	if not reason.is_empty():
		return _reject("purchase", buyer, seller, details, reason)
	# Divide before multiplying: the total must fit the existing money bound.
	# Both operands are validated integers; avoid float division/rounding.
	@warning_ignore("integer_division")
	var max_unit_price: int = MAX_AMOUNT / quantity
	if unit_price > max_unit_price:
		return _reject("purchase", buyer, seller, details, "total_price_limit")
	var total_price: int = quantity * unit_price
	details["total_price"] = total_price
	if _entities[seller].inventory[item] < quantity:
		reason = "insufficient_stock"
	elif _entities[buyer].money < total_price:
		reason = "insufficient_money"
	elif _entities[buyer].inventory[item] > MAX_AMOUNT - quantity:
		reason = "buyer_inventory_limit"
	elif _entities[seller].money > MAX_AMOUNT - total_price:
		reason = "seller_money_limit"
	if not reason.is_empty():
		return _reject("purchase", buyer, seller, details, reason)
	# No fallible calls or nested transfer commands between these four writes.
	_entities[seller].inventory[item] -= quantity
	_entities[buyer].inventory[item] += quantity
	_entities[buyer].money -= total_price
	_entities[seller].money += total_price
	_record("purchase", buyer, seller, true, details)
	return true


func harvest(actor: String, amount: Variant) -> bool:
	var details = {"item": "wheat", "amount": amount}
	var reason = _actor_amount_error(actor, amount)
	if reason.is_empty() and _entities[actor].role != "farmer":
		reason = "wrong_role"
	if reason.is_empty() and _entities[actor].inventory.wheat + amount > MAX_AMOUNT:
		reason = "amount_limit"
	if not reason.is_empty():
		return _reject("harvest", actor, "", details, reason)
	_entities[actor].inventory.wheat += amount
	_record("harvest", actor, "", true, details)
	return true


func produce(actor: String, recipe_id: String, batches: Variant = 1) -> bool:
	var details = {"recipe": recipe_id, "batches": batches}
	var reason = _actor_amount_error(actor, batches)
	if reason.is_empty() and not RECIPES.has(recipe_id):
		reason = "unknown_recipe"
	if not reason.is_empty():
		return _reject("produce", actor, "", details, reason)
	var recipe: Dictionary = RECIPES[recipe_id]
	if _entities[actor].role != recipe.role:
		return _reject("produce", actor, "", details, "wrong_role")
	var inputs: Dictionary = {}
	var outputs: Dictionary = {}
	for item in recipe.inputs:
		inputs[item] = recipe.inputs[item] * batches
		if _entities[actor].inventory[item] < inputs[item]:
			return _reject("produce", actor, "", details, "insufficient_stock")
	for item in recipe.outputs:
		outputs[item] = recipe.outputs[item] * batches
		if _entities[actor].inventory[item] + outputs[item] > MAX_AMOUNT:
			return _reject("produce", actor, "", details, "amount_limit")
	# All checks precede all mutations, including output capacity checks.
	for item in inputs:
		_entities[actor].inventory[item] -= inputs[item]
	for item in outputs:
		_entities[actor].inventory[item] += outputs[item]
	details["inputs"] = inputs
	details["outputs"] = outputs
	_record("produce", actor, "", true, details)
	return true


func consume(actor: String, amount: Variant = 1) -> bool:
	var details = {"item": "bread", "amount": amount}
	var reason = _actor_amount_error(actor, amount)
	if reason.is_empty() and _entities[actor].inventory.bread < amount:
		reason = "insufficient_stock"
	if not reason.is_empty():
		return _reject("consume", actor, "", details, reason)
	_entities[actor].inventory.bread -= amount
	_record("consume", actor, "", true, details)
	return true


func _actor_amount_error(actor: String, amount: Variant) -> String:
	if not _entities.has(actor):
		return "unknown_actor"
	if not amount is int or amount <= 0 or amount > MAX_AMOUNT:
		return "invalid_amount"
	return ""


func _transfer_error(actor: String, target: String, amount: Variant) -> String:
	var reason = _actor_amount_error(actor, amount)
	if not reason.is_empty():
		return reason
	if not _entities.has(target):
		return "unknown_target"
	if actor == target:
		return "same_entity"
	return ""


func _reject(action: String, actor: String, target: String, details: Dictionary, reason: String) -> bool:
	details["reason"] = reason
	_record(action, actor, target, false, details)
	return false


func _record(action: String, actor: String, target: String, success: bool, details: Dictionary) -> void:
	_events.append({
		"id": _events.size() + 1, "day": _day, "action": action,
		"actor": actor, "target": target, "success": success,
		"details": details.duplicate(true),
	})
