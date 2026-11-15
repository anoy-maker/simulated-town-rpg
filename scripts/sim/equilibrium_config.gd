extends RefCounted
## Exact M11 reference assumptions. Does not alter M9/M10 configuration.

const Labor = preload("res://scripts/sim/labor_config.gd")
const PRICES = {"wheat": 2, "flour": 4, "bread": 4}
const WAGE = 8
const HARVEST = 4


static func initial() -> Dictionary:
	var state: Dictionary = Labor.initial()
	for entity in state.entities:
		entity.money = 6 if entity.kind == "resident" else 120
		for item in entity.inventory:
			entity.inventory[item] = 0
	for business in state.businesses.values():
		business.owner_compensation = WAGE
	for job in state.employment.values():
		job.wage = WAGE
	return state


static func workers(business: Dictionary, day: int) -> Array:
	var employees: Array = business.employees.duplicate()
	employees.sort()
	var roster: Array = [business.owner] + employees
	return roster.slice(0, 2) if day % 2 == 1 else roster.slice(2, 4)
