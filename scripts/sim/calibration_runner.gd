extends "res://scripts/sim/market_downstream_runner.gd"
## Same policies/schedule, with isolated fixed economics and post-run diagnostics.

const Config = preload("res://scripts/sim/calibration_config.gd")
const CalibrationWorld = preload("res://scripts/sim/calibration_world.gd")
const Diagnostics = preload("res://scripts/sim/calibration_report.gd")
var _configuration: Dictionary


func _init(seed_value: int = 42, configuration: Dictionary = Config.DEFAULT) -> void:
	assert(Config.validate(configuration).is_empty())
	_configuration = configuration.duplicate(true)
	var entities: Array = downstream_entities()
	for person in entities:
		person.money = _configuration.initial_money[person.id]
	var goals: Dictionary = Policy.DEFAULT_GOALS.duplicate(true)
	goals.output_targets.farmer = _configuration.farmer_target
	super(seed_value, entities, goals)
	world = CalibrationWorld.new(entities, _configuration)
	_initial = world.snapshot()


func configuration() -> Dictionary:
	return _configuration.duplicate(true)


func _daily_payment() -> int:
	return _configuration.daily_payment


func _harvest_opportunity() -> int:
	return super() + _configuration.harvest_bonus


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "calibration"
	summary.prices = _configuration.prices.duplicate(true)
	summary.daily_payment.amount = _configuration.daily_payment
	summary["configuration"] = configuration()
	summary["experiment"] = Config.experiment_name(_configuration)
	summary["potential"] = Diagnostics.potential(_seed, summary.days, _configuration.harvest_bonus)
	summary["calibration"] = Diagnostics.metrics(summary, world.events())
	return summary
