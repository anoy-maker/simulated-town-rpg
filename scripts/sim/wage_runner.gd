extends "res://scripts/sim/cash_allocation_runner.gd"
const WageWorld=preload("res://scripts/sim/wage_world.gd")
func _init(seed_value: int=42,condition: String="reference",arm: String="fixed10_instrumented",allocation: String="original") -> void:
	super(seed_value,condition,"R_input_aware",allocation)
	world=WageWorld.new(seed_value,condition,arm,allocation);initial=world.snapshot()
func report() -> Dictionary:
	var r: Dictionary=super();r.scenario="settlement_dynamic_wages"
	r["wage_market"]={"arm":world.wage_arm,"note":"Direct sealed asks; conditional affordability and own application priors are fallible, never guaranteed hiring or food."}
	if world.wage_arm=="worker_bids":r.contracts=preload("res://scripts/sim/wage_report.gd").correct(r.contracts,world.snapshot(),world.events());r.labor.wage="by_term"
	return r
