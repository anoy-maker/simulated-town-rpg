extends SceneTree
var checks: int=0
var failures: int=0
func _check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(label)
func _init() -> void:
	var tests=preload("res://tests/learning_tests.gd")
	if "--math" in OS.get_cmdline_user_args(): tests.mathematical(self)
	else: tests.run(self)
	print("M18 checks: %d; failures: %d"%[checks,failures])
	quit(0 if failures==0 else 1)
