extends SceneTree
## Benchmark harness; timing is a separate envelope, never a canonical report field.
const Profile=preload("res://scripts/sim/execution_profile.gd")

func _hwm_kib() -> Variant:
	var status=FileAccess.open("/proc/self/status",FileAccess.READ)
	if status==null: return null
	for _index in 128:
		var line: String=status.get_line()
		if status.eof_reached(): break
		if line.begins_with("VmHWM:"): return int(line.trim_prefix("VmHWM:").strip_edges().get_slice(" ",0))
	return null

func _init() -> void:
	var entry=Time.get_ticks_usec()
	var args=OS.get_cmdline_user_args()
	assert(args.size()>=2)
	var stage: String=args[0]
	var days: int=int(args[1])
	var scenario: String="learning"
	if "m16" in args: scenario="m16"
	if "m17" in args: scenario="m17"
	var active: bool="profile" in args
	Profile.reset(active)
	var start=Time.get_ticks_usec()
	var runner: RefCounted
	if scenario=="m16": runner=preload("res://scripts/sim/pricing_runner.gd").new(42,stage)
	elif scenario=="m17": runner=preload("res://scripts/sim/spatial_runner.gd").new(42)
	else: runner=preload("res://scripts/sim/learning_runner.gd").new(42,stage)
	var init_usec=Time.get_ticks_usec()-start
	var init_profile=Profile.snapshot()
	Profile.reset(active)
	start=Time.get_ticks_usec()
	runner.run(days)
	var run_usec=Time.get_ticks_usec()-start
	var run_profile=Profile.snapshot()
	var run_hwm=_hwm_kib()
	Profile.reset(active)
	start=Time.get_ticks_usec()
	var report: Dictionary=runner.report()
	var report_usec=Time.get_ticks_usec()-start
	var report_profile=Profile.snapshot()
	Profile.reset(false)
	start=Time.get_ticks_usec()
	var canonical: String=JSON.stringify({"report":report},"",true)+"\n"
	var canonical_usec=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	var history: Array=runner.world.events()
	var history_copy_usec=Time.get_ticks_usec()-start
	var envelope={"report":report,"events":history,"measurement":{"scenario":scenario,"stage":stage,"days":days,"seed":42,"profiled":active,
		"engine_entry_usec":entry,"init_usec":init_usec,"run_usec":run_usec,"report_usec":report_usec,"canonical_json_usec":canonical_usec,
		"history_copy_usec":history_copy_usec,"run_hwm_kib":run_hwm,"init_profile":init_profile,"run_profile":run_profile,"report_profile":report_profile,
		"canonical_sha256":canonical.sha256_text(),"event_count":history.size()}}
	start=Time.get_ticks_usec()
	var encoded: String=JSON.stringify(envelope,"",true)
	var envelope_usec=Time.get_ticks_usec()-start
	# A short trailer accounts for large-envelope encoding without self-timing recursion.
	print(encoded)
	print(JSON.stringify({"envelope_json_usec":envelope_usec,"command_hwm_kib":_hwm_kib()},"",true))
	quit()
