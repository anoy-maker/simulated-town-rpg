extends "res://scripts/sim/employer_runner.gd"
## Share the M12 daily runner, authority, observations, initial state and reporting.

const Treatment = preload("res://scripts/sim/causality_policy.gd")
var _condition: String


func _init(seed_value: int = 42, condition: String = Treatment.FIXED_OWNER, initial: Dictionary = Reference.initial()) -> void:
	assert(condition in [Treatment.FIXED_OWNER, Treatment.SALES_ROTATING])
	_condition = condition
	super(seed_value, initial)


func _employer_plan(observation: Dictionary) -> Dictionary:
	return Treatment.decide(observation, _condition)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = _condition
	summary.schedule.workers = "owner then employee ID" if _condition == Treatment.FIXED_OWNER else "exclusive M11 alternating pair, established order"
	summary.employers.forecast_rule = "prescribed NEW daily output 8/8/12; no output-stock offset" if _condition == Treatment.FIXED_OWNER else summary.employers.forecast_rule
	return summary
