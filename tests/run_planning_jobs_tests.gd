extends SceneTree
var checks: int=0
var failures: int=0
func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+label)
func _init() -> void:
	Engine.max_fps=60
	_run_checks.call_deferred()
func _run_checks() -> void:
	var Tests=preload("res://tests/planning_jobs_tests.gd")
	Tests.run_pure(self)
	var stats=await Tests.run_worker(self)
	print(JSON.stringify({"checks":checks,"failures":failures,"statistics":stats}))
	quit(0 if failures==0 else 1)
