extends "res://scripts/sim/labor_world.gd"
## Reference-only environmental/market constants; all commands retain M9 authority.

const Reference = preload("res://scripts/sim/equilibrium_config.gd")


func _unit_price(item: String) -> int:
	return Reference.PRICES[item]


func _harvest_opportunity() -> int:
	return Reference.HARVEST
