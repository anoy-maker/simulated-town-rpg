extends "res://scripts/sim/market_world.gd"
## Fixed instance prices/opportunities; all economic commands are inherited.

const Config = preload("res://scripts/sim/calibration_config.gd")
var _economics: Dictionary


func _init(initial_entities: Array, configuration: Dictionary) -> void:
	assert(Config.validate(configuration).is_empty())
	_economics = configuration.duplicate(true)
	super(initial_entities)


func _unit_price(item: String) -> int:
	return _economics.prices[item]


func _valid_harvest_yield(amount: int) -> bool:
	return amount >= 2 + _economics.harvest_bonus and amount <= 6 + _economics.harvest_bonus
