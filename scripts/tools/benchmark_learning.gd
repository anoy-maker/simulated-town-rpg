extends SceneTree
## Noncanonical timing wrapper: run-only clock kept outside canonical CLI reports.
func _init() -> void:
	var a=OS.get_cmdline_user_args()
	var stage: String=a[0]
	var horizon: int=int(a[1])
	var spatial: bool=a.size()<3 or a[2]!="nonspatial"
	var runner=preload("res://scripts/sim/learning_runner.gd").new(42,stage) if spatial else preload("res://scripts/sim/pricing_runner.gd").new(42,stage)
	var start=Time.get_ticks_usec()
	if "split" in a and horizon>0:
		runner.run(1)
		runner.run(horizon-1)
	else: runner.run(horizon)
	var elapsed=Time.get_ticks_usec()-start
	print(JSON.stringify({"simulation_seconds":elapsed/1000000.0,"report":runner.report(),"events":runner.world.events()},"",true))
	quit()
