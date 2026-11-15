extends RefCounted
## Pure decisions over copied observations and explicit goals. No world instance.

const Rules = preload("res://scripts/sim/world_state.gd")
const DEFAULT_GOALS = {"food_target": 1, "output_targets": {"farmer": 4, "miller": 4, "baker": 6},
	"max_batches": 2, "reserve_food_money": true}


static func decide(observation: Dictionary, goals: Dictionary, phase: String) -> Dictionary:
	var person: Dictionary = observation.self
	if phase == "meal":
		if observation.needs.meals_due == 0:
			return _wait("no_meal_due")
		return _proposal({"type": "consume"}, "meal_due" if person.inventory.bread > 0 else "meal_unavailable")
	if phase == "food":
		if observation.needs.meals_due == 0:
			return _wait("no_meal_due")
		var needed: int = maxi(goals.food_target, observation.needs.meals_due) - person.inventory.bread
		if needed <= 0:
			return _wait("food_already_covered")
		return _buy(observation, "bread", needed, person.money, "food_needed")
	if person.role == "farmer" and phase == "work":
		if person.inventory.wheat >= goals.output_targets.farmer:
			return _wait("output_target_met")
		return _proposal({"type": "harvest"}, "wheat_below_target")
	var recipe_id: String = "mill" if person.role == "miller" else "bake" if person.role == "baker" else ""
	if recipe_id.is_empty() or phase not in ["inputs", "work"]:
		return _wait("no_production_role")
	var recipe: Dictionary = Rules.RECIPES[recipe_id]
	var input: String = recipe.inputs.keys()[0]
	var output: String = recipe.outputs.keys()[0]
	var gap: int = goals.output_targets[person.role] - person.inventory[output]
	if gap <= 0:
		return _wait("output_target_met")
	@warning_ignore("integer_division")
	var planned: int = mini(goals.max_batches, (gap + recipe.outputs[output] - 1) / recipe.outputs[output])
	if phase == "inputs":
		var needed: int = planned * recipe.inputs[input] - person.inventory[input]
		if needed <= 0:
			return _wait("inputs_already_covered")
		var reserve: int = 0
		if goals.reserve_food_money and observation.market.bread.seller != person.id \
				and person.inventory.bread < maxi(goals.food_target, observation.needs.meals_due):
			reserve = observation.market.bread.unit_price * (maxi(goals.food_target, observation.needs.meals_due) - person.inventory.bread)
		return _buy(observation, input, needed, maxi(0, person.money - reserve), "production_inputs_needed")
	@warning_ignore("integer_division")
	var batches: int = mini(planned, person.inventory[input] / recipe.inputs[input])
	if batches == 0:
		return _wait("missing_inputs")
	return _proposal({"type": "produce", "recipe": recipe_id, "batches": batches}, "output_below_target")


static func _buy(observation: Dictionary, item: String, needed: int, budget: int, reason: String) -> Dictionary:
	if not observation.market.has(item):
		return _wait("no_market_offer")
	var offer: Dictionary = observation.market[item]
	if offer.seller == observation.self.id or offer.stock == 0:
		return _wait("market_unavailable")
	@warning_ignore("integer_division")
	var affordable: int = budget / offer.unit_price
	var quantity: int = mini(needed, mini(offer.stock, affordable))
	if quantity == 0:
		return _wait("unaffordable_with_priorities")
	return _proposal({"type": "purchase", "seller": offer.seller, "item": item,
		"quantity": quantity, "unit_price": offer.unit_price}, reason)


static func _wait(reason: String) -> Dictionary:
	return _proposal({"type": "wait"}, reason)


static func _proposal(action: Dictionary, reason: String) -> Dictionary:
	return {"action": action, "reason": reason}
