extends RefCounted
## Pure offer selection, followed by the shared M5 commitment-first policy.

const Planning = preload("res://scripts/sim/planning_policy.gd")


static func select_offer(offers: Array) -> Dictionary:
	var ranked: Array = offers.duplicate(true)
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.unit_price != b.unit_price:
			return a.unit_price < b.unit_price
		if a.stock != b.stock:
			return a.stock > b.stock
		return a.seller < b.seller)
	for offer in ranked:
		if offer.stock > 0:
			return offer
	# Retain an eligible zero-stock producer for public price/request reasoning.
	return ranked[0] if not ranked.is_empty() else {}


static func selected_observation(observation: Dictionary) -> Dictionary:
	var selected: Dictionary = observation.duplicate(true)
	for item in observation.offers:
		var offer: Dictionary = select_offer(observation.offers[item])
		# Preserve M5's own-output food/input budget rule for every producer.
		if item in observation.supplies:
			for own in observation.offers[item]:
				if own.seller == observation.self.id:
					offer = own.duplicate(true)
		if not offer.is_empty():
			selected.market[item] = offer
	return selected


static func decide(observation: Dictionary, goals: Dictionary, phase: String) -> Dictionary:
	var selected: Dictionary = selected_observation(observation)
	var proposal: Dictionary = Planning.decide(selected, goals, phase, "commitment-first")
	if proposal.action.type == "purchase":
		proposal.action["supplier_selection"] = {"criteria": "price_stock_id", "offer": selected.market[proposal.action.item],
			"candidates": observation.offers[proposal.action.item].duplicate(true)}
	return proposal
