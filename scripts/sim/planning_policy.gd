extends RefCounted
## Both priorities use the same observations, cost model, and available actions.

const Commercial = preload("res://scripts/sim/coordination_policy.gd")
const Base = preload("res://scripts/sim/npc_policy.gd")
const Rules = preload("res://scripts/sim/world_state.gd")
const PRIORITIES = ["commitment-first", "immediate-needs-first"]


static func working_capital(observation: Dictionary, goals: Dictionary) -> Dictionary:
	var person: Dictionary = observation.self
	var food_missing: int = maxi(0, maxi(goals.food_target, observation.needs.meals_due) - person.inventory.bread)
	var food_cost: int = food_missing * observation.market.bread.unit_price \
		if observation.needs.meals_due > 0 and observation.market.bread.seller != person.id else 0
	var plan = {"active": false, "request_id": "", "item": "", "output_missing": 0, "recipe": "",
		"batches": 0, "input_item": "", "input_missing": 0, "input_cost": 0, "input_available": 0,
		"cash": person.money, "food_cost": food_cost, "status": "no_obligation"}
	for request in observation.requests:
		if request.status != "accepted" or request.supplier != person.id:
			continue
		plan.active = true
		plan.request_id = request.id
		plan.item = request.item
		plan.output_missing = maxi(0, request.quantity - person.inventory[request.item])
		if plan.output_missing == 0:
			plan.status = "delivery_ready"
			return plan
		if person.role == "farmer":
			plan.status = "harvest_required"
			return plan
		plan.recipe = "mill" if person.role == "miller" else "bake"
		var recipe: Dictionary = Rules.RECIPES[plan.recipe]
		@warning_ignore("integer_division")
		var batches: int = (plan.output_missing + recipe.outputs[request.item] - 1) / recipe.outputs[request.item]
		plan.batches = batches
		plan.input_item = recipe.inputs.keys()[0]
		plan.input_missing = maxi(0, batches * recipe.inputs[plan.input_item] - person.inventory[plan.input_item])
		plan.input_cost = plan.input_missing * observation.market[plan.input_item].unit_price
		plan.input_available = observation.market[plan.input_item].stock
		if plan.input_missing == 0:
			plan.status = "production_ready"
		elif person.money < plan.input_cost:
			plan.status = "insufficient_working_capital"
		elif plan.input_available < plan.input_missing:
			plan.status = "input_supply_shortage"
		else:
			plan.status = "fundable_inputs"
		return plan
	return plan


static func decide(observation: Dictionary, goals: Dictionary, phase: String, priority: String) -> Dictionary:
	assert(priority in PRIORITIES)
	var plan: Dictionary = working_capital(observation, goals)
	plan["priority"] = priority
	plan["input_budget"] = maxi(0, plan.cash - plan.food_cost) if priority == "immediate-needs-first" else plan.cash
	plan["discretionary_budget"] = maxi(0, plan.cash - plan.input_cost) if priority == "commitment-first" else plan.cash
	var proposal: Dictionary = _choose(observation, goals, phase, plan)
	# This is an explanatory annotation, not a world balance or execution constraint.
	proposal.action["planning"] = plan
	return proposal


static func _choose(observation: Dictionary, goals: Dictionary, phase: String, plan: Dictionary) -> Dictionary:
	var proposal: Dictionary = Commercial.decide(observation, goals, phase)
	if not plan.active:
		if phase == "food" and proposal.action.type == "purchase":
			proposal.reason = "spend_immediate_needs"
		return proposal
	if phase == "delivery":
		proposal.reason = "fulfill_obligation" if proposal.action.type == "fulfill_request" else "unable_to_satisfy_obligation"
		return proposal
	if phase == "inputs":
		if plan.input_missing == 0:
			return _wait("obligation_inputs_owned")
		if Commercial._incoming(observation, plan.input_item):
			return _wait("awaiting_obligation_inputs")
		proposal = Base._buy(observation, plan.input_item, plan.input_missing, plan.input_budget, "acquire_obligation_inputs")
		if proposal.action.type == "wait":
			proposal.reason = "unable_to_satisfy_obligation"
		return proposal
	if phase == "work":
		if plan.output_missing == 0:
			return _wait("obligation_ready_for_delivery")
		if observation.self.role == "farmer":
			proposal.reason = "produce_for_obligation"
			return proposal
		var recipe: Dictionary = Rules.RECIPES[plan.recipe]
		@warning_ignore("integer_division")
		var available: int = observation.self.inventory[plan.input_item] / recipe.inputs[plan.input_item]
		var batches: int = mini(goals.max_batches, mini(plan.batches, available))
		if batches == 0:
			return _wait("unable_to_satisfy_obligation")
		return {"action": {"type": "produce", "recipe": plan.recipe, "batches": batches}, "reason": "produce_for_obligation"}
	if phase == "food" and proposal.action.type == "purchase":
		var needed: int = maxi(goals.food_target, observation.needs.meals_due) - observation.self.inventory.bread
		proposal = Base._buy(observation, "bread", needed, plan.discretionary_budget, "spend_immediate_needs")
		if proposal.action.type == "wait":
			proposal.reason = "reserve_obligation_capital"
		return proposal
	if phase == "requests" and proposal.action.type == "post_request":
		var item: String = proposal.action.item
		var for_inputs: bool = item == plan.input_item
		var budget: int = plan.input_budget if for_inputs else plan.discretionary_budget
		@warning_ignore("integer_division")
		var affordable: int = budget / observation.market[item].unit_price
		var needed: int = plan.input_missing if for_inputs else proposal.action.quantity
		var quantity: int = mini(needed, mini(proposal.action.quantity, affordable))
		if quantity == 0:
			return _wait("unable_to_satisfy_obligation" if for_inputs else "reserve_obligation_capital")
		proposal.action.quantity = quantity
		proposal.reason = "acquire_obligation_inputs" if for_inputs else "spend_immediate_needs"
	return proposal


static func _wait(reason: String) -> Dictionary:
	return {"action": {"type": "wait"}, "reason": reason}
