extends SceneTree
var checks: int=0
var failures: int=0
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _init() -> void:
	preload("res://tests/wage_tests.gd").run(self)
	print("M30 focused checks: %d, failures: %d"%[checks,failures]);quit(1 if failures else 0)
