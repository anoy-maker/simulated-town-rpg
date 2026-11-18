extends "res://scripts/sim/demand_runner.gd"
const InputWorld=preload("res://scripts/sim/input_world.gd")
func _init(seed: int=42,condition: String="reference",arm: String="R_baseline_instrumented",selected_fixture: String="none") -> void:
	super(seed,condition,"requests_smoothed",selected_fixture)
	world=InputWorld.new(seed,condition,arm,selected_fixture);initial=world.snapshot()
func report() -> Dictionary:
	var r: Dictionary=super();r.scenario="settlement_input_reliability"
	r["input_reliability"]={"arm":world.input_arm,"orders":world._input_orders.duplicate(true),"forecasts":world._input_forecasts.duplicate(true),"projections":world._input_projections.duplicate(true),"note":"Local endogenous fill heuristic, not a future supply guarantee."}
	return r
