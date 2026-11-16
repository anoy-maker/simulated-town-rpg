extends RefCounted
## M15's predeclared finite accounts/assets. Historical configurations are never edited.
const Reference = preload("res://scripts/sim/profitable_config.gd")
const REQUIREMENTS = {"farmer": ["workshop", "farm_tools"], "miller": ["workshop", "millstone"], "baker": ["workshop", "oven"]}


static func external(id: String, coins: int) -> Dictionary:
	return {"id": id, "name": id.capitalize(), "kind": "external", "role": "account", "money": coins,
		"inventory": {"wheat": 0, "flour": 0, "bread": 0}}


static func initial(visitor_money: int = 8760, fixture: bool = false) -> Dictionary:
	var state: Dictionary = Reference.initial()
	state["productive_assets"] = {}
	for firm in state.businesses.values():
		firm["distribution_policy"] = {"mode": "full", "reserve": 120}
		for kind in REQUIREMENTS[firm.industry]:
			state.productive_assets[firm.id + ":" + kind] = {"kind": kind, "holder": firm.id, "price": 0, "for_sale": false, "capacity": firm.assets.daily_slots, "industry": firm.industry}
	for job in state.employment.values():
		job["start_day"] = 1
		job["end_day"] = 0
	state.entities.append(external("visitors", 100 if fixture else visitor_money))
	if fixture:
		for entity in state.entities:
			if entity.id == "finn":
				entity.money = 500
			if entity.id == "mill":
				entity.inventory.flour = 12
		state.entities.append(external("equipment_seller", 0))
		state.productive_assets["spare_oven"] = {"kind": "oven", "holder": "equipment_seller", "price": 180, "for_sale": true, "capacity": 1, "industry": "baker"}
		state.productive_assets["spare_workshop"] = {"kind": "workshop", "holder": "ada", "price": 60, "for_sale": true, "capacity": 1, "industry": "baker"}
	return state
