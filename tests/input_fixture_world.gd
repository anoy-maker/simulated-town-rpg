extends "res://scripts/sim/input_world.gd"
var input_fixture: String
func _init(label: String) -> void:
	assert(label in ["no_harvest","cashless_inputs","remote_buyer","invalid_attempts"])
	input_fixture=label
	super(42,"scarce","R_input_aware")
func _labor_market_initial(selected_fixture: String) -> Dictionary:
	var s: Dictionary=super(selected_fixture)
	for e in s.entities:
		var removed: int=120 if (input_fixture=="no_harvest" and e.id=="farm") or (input_fixture=="cashless_inputs" and e.id in ["mill","brewery"]) else 0
		if removed:
			e.money-=removed
			for account in s.entities:
				if account.id=="visitors":account.money+=removed
	return s
func snapshot() -> Dictionary:return super().merged({"input_fixture":input_fixture})
