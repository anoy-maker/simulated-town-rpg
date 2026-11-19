extends SceneTree
var checks: int=0
var failures: int=0
func _check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: "+label)
func _init() -> void:
	preload("res://tests/profile_tests.gd").run(self)
	preload("res://tests/continuation_tests.gd").run(self)
	print("M19 checks: %d, failures: %d"%[checks,failures])
	quit(0 if failures==0 else 1)
