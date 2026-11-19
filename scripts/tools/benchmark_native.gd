extends SceneTree
## Diagnostics stay outside canonical output and world state.
func _init() -> void:
	var entry=Time.get_ticks_usec()
	var args=OS.get_cmdline_user_args()
	var stage: String=args[0]
	var days: int=int(args[1])
	var backend: String=args[2]
	var start=Time.get_ticks_usec()
	var runner=preload("res://scripts/sim/learning_runner.gd").new(42,stage)
	var init_usec=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	var error: String=runner.select_backend(backend)
	if not error.is_empty():
		printerr(error)
		quit(2)
		return
	var load_usec=Time.get_ticks_usec()-start
	runner.measure_appointments=true
	runner.world.measure_ticks=true
	start=Time.get_ticks_usec()
	runner.run(days)
	var run_usec=Time.get_ticks_usec()-start
	var run_hwm=_hwm()
	start=Time.get_ticks_usec()
	var report=runner.report()
	var report_usec=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	var canonical=JSON.stringify({"report":report},"",true)+"\n"
	var canonical_usec=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	var history=runner.world.events()
	var copy_usec=Time.get_ticks_usec()-start
	var measurement={"stage":stage,"days":days,"backend":backend,"engine_entry_usec":entry,"init_usec":init_usec,"load_usec":load_usec,
		"run_usec":run_usec,"report_usec":report_usec,"canonical_json_usec":canonical_usec,"history_copy_usec":copy_usec,
		"canonical_sha256":canonical.sha256_text(),"run_hwm_kib":run_hwm,"decisions":runner.decision_timings,
		"appointments":runner.appointment_timings,"ticks":runner.world.tick_timings,
		"batches":runner.numerical_backend.measurements if runner.numerical_backend!=null else []}
	start=Time.get_ticks_usec()
	var encoded=JSON.stringify({"report":report,"events":history,"measurement":measurement},"",true)
	var serialization_usec=Time.get_ticks_usec()-start
	print(encoded)
	print(JSON.stringify({"envelope_json_usec":serialization_usec,"command_hwm_kib":_hwm()}))
	quit()
func _hwm() -> Variant:
	var status=FileAccess.open("/proc/self/status",FileAccess.READ)
	for _i in 128:
		var line=status.get_line()
		if line.begins_with("VmHWM:"): return int(line.trim_prefix("VmHWM:").strip_edges().get_slice(" ",0))
		if status.eof_reached():break
	return null
