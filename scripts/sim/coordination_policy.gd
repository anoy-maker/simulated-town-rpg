extends RefCounted
## Voluntary commercial choices from self state, public offers, and visible requests.

const Base = preload("res://scripts/sim/npc_policy.gd")
const Rules = preload("res://scripts/sim/world_state.gd")
const SELLERS = {"wheat": "farmer", "flour": "miller", "bread": "baker"}


static func decide(observation: Dictionary, goals: Dictionary, phase: String) -> Dictionary:
	var person: Dictionary = observation.self
	var adjusted: Dictionary = goals.duplicate(true)
	var obligation: Dictionary = {}
	for request in observation.requests:
		if request.status == "accepted" and request.supplier == person.id:
			obligation = request
			adjusted.reserve_food_money = false
			adjusted.output_targets[person.role] = maxi(goals.output_targets[person.role], request.quantity)
			break
	if phase == "delivery":
		if obligation.is_empty():
			return _wait("no_supply_obligation")
		if person.inventory[obligation.item] < obligation.quantity:
			return _wait("delivery_not_ready")
		return _proposal({"type": "fulfill_request", "request_id": obligation.id}, "promised_goods_available")
	if phase == "accept":
		if not obligation.is_empty():
			return _wait("supplier_busy")
		for request in observation.requests:
			if request.status == "open" and request.buyer != person.id and SELLERS[request.item] == person.id \
					and _can_supply(observation, adjusted, request):
				return _proposal({"type": "accept_request", "request_id": request.id}, "prepaid_production_opportunity")
		return _wait("no_viable_public_request")
	if phase == "requests":
		var need: Dictionary = _input_need(observation, adjusted)
		if need.is_empty() and observation.needs.meals_due > 0 and person.inventory.bread < goals.food_target:
			need = {"item": "bread", "quantity": goals.food_target - person.inventory.bread}
		if need.is_empty():
			return _wait("no_supply_shortfall")
		if _incoming(observation, need.item):
			return _wait("request_already_active")
		var offer: Dictionary = observation.market[need.item]
		if offer.seller == person.id or offer.stock > 0:
			return _wait("spot_market_preferred")
		var budget: int = _budget(observation, adjusted, need.item)
		@warning_ignore("integer_division")
		var quantity: int = mini(need.quantity, budget / offer.unit_price)
		if quantity == 0:
			return _wait("cannot_fund_request")
		return _proposal({"type": "post_request", "item": need.item, "quantity": quantity}, "prepay_missing_supply")
	if phase == "inputs":
		var need: Dictionary = _input_need(observation, adjusted)
		if not need.is_empty() and _incoming(observation, need.item):
			return _wait("awaiting_prepaid_supply")
	if phase == "food" and _incoming(observation, "bread"):
		return _wait("awaiting_prepaid_supply")
	return Base.decide(observation, adjusted, phase)


static func _input_need(observation: Dictionary, goals: Dictionary) -> Dictionary:
	var person: Dictionary = observation.self
	var recipe_id: String = "mill" if person.role == "miller" else "bake" if person.role == "baker" else ""
	if recipe_id.is_empty():
		return {}
	var recipe: Dictionary = Rules.RECIPES[recipe_id]
	var output: String = recipe.outputs.keys()[0]
	var input: String = recipe.inputs.keys()[0]
	var gap: int = goals.output_targets[person.role] - person.inventory[output]
	if gap <= 0:
		return {}
	@warning_ignore("integer_division")
	var batches: int = mini(goals.max_batches, (gap + recipe.outputs[output] - 1) / recipe.outputs[output])
	var quantity: int = batches * recipe.inputs[input] - person.inventory[input]
	return {"item": input, "quantity": quantity} if quantity > 0 else {}


static func _budget(observation: Dictionary, goals: Dictionary, item: String) -> int:
	var reserve: int = 0
	if item != "bread" and goals.reserve_food_money and observation.market.bread.seller != observation.self.id:
		reserve = maxi(0, goals.food_target - observation.self.inventory.bread) * observation.market.bread.unit_price
	return maxi(0, observation.self.money - reserve)


static func _incoming(observation: Dictionary, item: String) -> bool:
	for request in observation.requests:
		if request.buyer == observation.self.id and request.item == item and request.status in ["open", "accepted"]:
			return true
	return false


static func _can_supply(observation: Dictionary, goals: Dictionary, request: Dictionary) -> bool:
	var person: Dictionary = observation.self
	if person.money > Rules.MAX_AMOUNT - request.payment:
		return false
	var missing: int = maxi(0, request.quantity - person.inventory[request.item])
	if missing == 0:
		return true
	if person.role == "farmer":
		return missing <= 6
	var recipe_id: String = "mill" if person.role == "miller" else "bake"
	var recipe: Dictionary = Rules.RECIPES[recipe_id]
	@warning_ignore("integer_division")
	var batches: int = (missing + recipe.outputs[request.item] - 1) / recipe.outputs[request.item]
	if batches > goals.max_batches:
		return false
	var input: String = recipe.inputs.keys()[0]
	var input_needed: int = maxi(0, batches * recipe.inputs[input] - person.inventory[input])
	var cost: int = input_needed * observation.market[input].unit_price
	return request.payment >= cost


static func _wait(reason: String) -> Dictionary:
	return _proposal({"type": "wait"}, reason)


static func _proposal(action: Dictionary, reason: String) -> Dictionary:
	return {"action": action, "reason": reason}
