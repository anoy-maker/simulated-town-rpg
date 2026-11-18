extends "res://scripts/sim/demand_world.gd"
## Labeled test-only initial endowments. No main-run resource changes.
var observation_fixture: String
func _init(label: String="poor_visitors") -> void:
	assert(label in ["poor_visitors","cashless_buyers","remote_farm","duplicate"])
	observation_fixture=label
	super(42,"reference","requests_smoothed")
func _labor_market_initial(_selected: String) -> Dictionary:
	var state: Dictionary=Bound.initial()
	for e in state.entities:
		if observation_fixture=="poor_visitors":
			if e.id=="visitors":e.money=0
			if e.id=="ada":e.money+=8622
		if observation_fixture=="cashless_buyers":
			if e.id in ["mill","brewery"]:e.money=0
			if e.id=="visitors":e.money+=240
			if e.id=="farm":e.inventory.wheat=21
	return state
func snapshot() -> Dictionary:return super().merged({"demand_fixture":observation_fixture})
