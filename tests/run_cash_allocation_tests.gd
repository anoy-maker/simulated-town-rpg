extends SceneTree
var checks: int=0
var failures: int=0
func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _init() -> void:
	preload("res://tests/cash_allocation_tests.gd").run(self)
	print("M29 checks: %d, failures: %d"%[checks,failures]);quit(1 if failures else 0)
