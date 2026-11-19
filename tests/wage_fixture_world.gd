extends "res://scripts/sim/wage_world.gd"
var technical_fixture: String
func _init(seed_value: int=42,condition: String="reference",arm: String="worker_bids",selected_allocation: String="original",selected_fixture: String="manual_mixed") -> void:
	assert(condition=="reference" and arm=="worker_bids" and selected_allocation=="original" and selected_fixture in ["manual_mixed","manual_partial","manual_no_show"])
	technical_fixture=selected_fixture
	super(seed_value,condition,arm,selected_allocation)
func _labor_market_initial(selected_fixture: String) -> Dictionary:
	var state: Dictionary=super(selected_fixture)
	if technical_fixture=="manual_partial":
		for e in state.entities:
			if e.id=="farm":e.money-=90
			if e.id=="visitors":e.money+=90
	return state
