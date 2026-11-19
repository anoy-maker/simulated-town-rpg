extends SceneTree
var checks: int=0
var failures: int=0
func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _init() -> void:
	preload("res://tests/labor_market_tests.gd").run(self)
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures==0 else 1)
