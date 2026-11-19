extends "res://scripts/sim/coordination_world.gd"
## Public stock from every eligible producer; no cash or unrelated inventory.

const OUTPUTS = {"farmer": "wheat", "miller": "flour", "baker": "bread"}


func _can_sell(seller: String, item: String) -> bool:
	return _entities.has(seller) and OUTPUTS.get(_entities[seller].role, "") == item


func _request_target(_item: String) -> String:
	# An untargeted public request can be accepted by any eligible producer.
	return ""


func _market(_actor: String) -> Dictionary:
	# The policy selects offers, not the world. Keep known fixed prices available.
	var market: Dictionary = {}
	for item in ITEMS:
		market[item] = {"seller": "", "unit_price": _unit_price(item), "stock": 0}
	return market


func observe(actor: String) -> Dictionary:
	var observation: Dictionary = super(actor)
	var offers: Dictionary = {"wheat": [], "flour": [], "bread": []}
	var ids: Array = _entities.keys()
	ids.sort()
	for seller in ids:
		var item: String = OUTPUTS.get(_entities[seller].role, "")
		if not item.is_empty():
			offers[item].append({"seller": seller, "unit_price": _unit_price(item),
				"stock": _entities[seller].inventory[item]})
	observation["offers"] = offers
	var output: String = OUTPUTS.get(_entities[actor].role, "")
	observation["supplies"] = [] if output.is_empty() else [output]
	return observation
