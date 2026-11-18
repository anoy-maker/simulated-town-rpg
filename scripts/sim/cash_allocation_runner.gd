extends "res://scripts/sim/input_runner.gd"
const CashWorld=preload("res://scripts/sim/cash_allocation_world.gd")
func _init(seed: int=42,condition: String="scarce",arm: String="R_baseline_instrumented",allocation: String="original") -> void:
	super(seed,condition,arm)
	world=CashWorld.new(seed,condition,arm,allocation);initial=world.snapshot()
func report() -> Dictionary:
	var r: Dictionary=super();r.scenario="settlement_cash_allocation"
	var accounts: Dictionary={}
	for id in initial.entities:accounts[id]=initial.entities[id].money
	r["cash_allocation"]={"name":world.allocation,"initial_accounts":accounts,"source_event_id":1,"kind":"initial_ownership_not_income"}
	return r
