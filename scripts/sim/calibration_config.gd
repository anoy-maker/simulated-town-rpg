extends RefCounted
## Fixed presets and the permitted economic variables. Never mutate defaults.

const Rules = preload("res://scripts/sim/world_state.gd")
const DEFAULT = {"harvest_bonus": 0, "farmer_target": 4,
	"prices": {"wheat": 1, "flour": 2, "bread": 3}, "daily_payment": 2,
	"initial_money": {"farmer": 30, "miller": 20, "miller_2": 20, "baker": 20, "baker_2": 20, "laborer": 5}}
const EXPERIMENTS = ["baseline", "higher_productivity", "higher_target", "lower_food_price", "higher_wage", "extra_liquidity"]


static func preset(experiment: String) -> Dictionary:
	assert(experiment in EXPERIMENTS)
	var config: Dictionary = DEFAULT.duplicate(true)
	match experiment:
		"higher_productivity": config.harvest_bonus = 2
		"higher_target": config.farmer_target = 8
		"lower_food_price": config.prices.bread = 2
		"higher_wage": config.daily_payment = 3
		"extra_liquidity":
			for actor in config.initial_money:
				config.initial_money[actor] += 10
	return config


static func validate(config: Variant) -> String:
	if not config is Dictionary or config.size() != DEFAULT.size():
		return "invalid_configuration"
	for key in DEFAULT:
		if not config.has(key):
			return "invalid_configuration"
	for key in ["harvest_bonus", "farmer_target", "daily_payment"]:
		var minimum: int = 0 if key == "harvest_bonus" else 1
		var maximum: int = Rules.MAX_AMOUNT - 6 if key == "harvest_bonus" else Rules.MAX_AMOUNT
		if not _integer(config[key], minimum, maximum):
			return "invalid_" + key
	# Policies divide by public prices; this laboratory requires strictly positive prices.
	for key in ["prices", "initial_money"]:
		if not config[key] is Dictionary or config[key].size() != DEFAULT[key].size():
			return "invalid_" + key
		for entry in DEFAULT[key]:
			if not config[key].has(entry) or not _integer(config[key][entry], 1 if key == "prices" else 0, Rules.MAX_AMOUNT):
				return "invalid_" + key
	return ""


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return value is int and value >= minimum and value <= maximum


static func experiment_name(config: Dictionary) -> String:
	for name in EXPERIMENTS:
		if config == preset(name):
			return name
	return "custom"
