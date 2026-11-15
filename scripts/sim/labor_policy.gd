extends RefCounted
## Pure owner/worker decisions. No world reference and no access to other accounts.

const Config = preload("res://scripts/sim/labor_config.gd")


static func _proposal(kind: String, reason: String, fields: Dictionary = {}) -> Dictionary:
	var action: Dictionary = fields.duplicate(true)
	action["type"] = kind
	return {"action": action, "reason": reason}


static func _offer(observation: Dictionary, item: String) -> Dictionary:
	var offers: Array = []
	for offer in observation.offers:
		if offer.item == item and offer.stock > 0:
			offers.append(offer)
	offers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.unit_price != b.unit_price:
			return a.unit_price < b.unit_price
		if a.stock != b.stock:
			return a.stock > b.stock
		return a.seller < b.seller)
	return offers[0] if not offers.is_empty() else {}


static func decide(observation: Dictionary, phase: String, worker: String = "") -> Dictionary:
	var own: Dictionary = observation.self
	if phase == "meal":
		return _proposal("consume", "daily_meal")
	if phase == "food":
		if own.inventory.bread >= 1 or not observation.meals_due:
			return _proposal("wait", "food_owned")
		var food: Dictionary = _offer(observation, "bread")
		if food.is_empty():
			return _proposal("wait", "no_food_offer")
		if own.money < food.unit_price:
			return _proposal("wait", "unaffordable_food")
		return _proposal("purchase", "personal_food", {"seller": food.seller, "item": "bread", "quantity": 1, "unit_price": food.unit_price})
	if phase == "work":
		if own.labor_used >= own.labor_capacity:
			return _proposal("wait", "daily_labor_limit")
		for offer in observation.shift_offers:
			if offer.industry in own.skills and offer.wage > 0:
				return _proposal("work_shift", "accept_paid_work")
		return _proposal("wait", "no_eligible_shift")
	var firm: Dictionary = observation.business
	if firm.is_empty():
		return _proposal("wait", "no_owned_business")
	var rule: Dictionary = Config.INDUSTRIES[firm.industry]
	if firm.inventory[rule.output] >= firm.output_target:
		return _proposal("wait", "output_target_met")
	var candidate: Dictionary = {}
	for person in firm.workers:
		if person.id == worker:
			candidate = person
	if candidate.is_empty() or not candidate.qualified or candidate.wage == 0:
		return _proposal("wait", "ineligible_worker")
	if not candidate.available:
		return _proposal("wait", "daily_labor_limit")
	if firm.labor_used >= firm.assets.daily_slots:
		return _proposal("wait", "workplace_capacity")
	if firm.money < candidate.wage:
		return _proposal("wait", "unfunded_payroll")
	if phase == "inputs":
		if rule.input.is_empty() or firm.inventory[rule.input] >= 4:
			return _proposal("wait", "inputs_owned")
		var supply: Dictionary = _offer(observation, rule.input)
		if supply.is_empty():
			return _proposal("wait", "no_input_offer")
		@warning_ignore("integer_division")
		var quantity: int = mini(4 - firm.inventory[rule.input], mini(supply.stock, (firm.money - candidate.wage) / supply.unit_price))
		if quantity <= 0:
			return _proposal("wait", "inputs_unaffordable_after_payroll")
		return _proposal("purchase", "inputs_for_paid_shift", {"seller": supply.seller, "item": rule.input,
			"quantity": quantity, "unit_price": supply.unit_price})
	if phase == "schedule":
		if not rule.input.is_empty() and firm.inventory[rule.input] < 4:
			return _proposal("wait", "insufficient_inputs")
		return _proposal("offer_shift", "funded_productive_shift")
	return _proposal("wait", "unknown_phase")
