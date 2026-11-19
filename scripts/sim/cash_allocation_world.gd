extends "res://scripts/sim/input_world.gd"
const CashConfig=preload("res://scripts/sim/cash_allocation_config.gd")
var allocation: String
func _init(seed_value: int=42,condition: String="scarce",arm: String="R_baseline_instrumented",selected_allocation: String="original") -> void:
	assert(selected_allocation in CashConfig.ALLOCATIONS);allocation=selected_allocation
	super(seed_value,condition,arm)
func _labor_market_initial(selected_fixture: String) -> Dictionary:
	assert(selected_fixture=="none")
	return CashConfig.allocate(super(selected_fixture),allocation)
