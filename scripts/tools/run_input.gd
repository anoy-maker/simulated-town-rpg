extends SceneTree
const Runner=preload("res://scripts/sim/input_runner.gd")
func _init() -> void:run_cli(self,OS.get_cmdline_user_args())
static func run_cli(host: SceneTree,arguments: PackedStringArray) -> void:
	var args: Array=Array(arguments);var settings={"--condition":"reference","--arm":"R_baseline_instrumented","--fixture":"none"}
	while args.size()>=2 and settings.has(args[0]):settings[args[0]]=args[1];args=args.slice(2)
	if settings["--condition"] not in Runner.Brew.CASES or settings["--arm"] not in Runner.InputWorld.InputMemory.ARMS or settings["--fixture"] not in ["none","staggered"] or args.size()>3 or (args.size()>0 and not str(args[0]).is_valid_int()) or (args.size()>1 and not str(args[1]).is_valid_int()) or (args.size()>2 and args[2] not in ["--json","--report-json","--measure"]):
		printerr("Usage: settlement_input_reliability [--condition reference|tight|scarce|no_brew_request] [--arm R_baseline_instrumented|R_input_aware] [--fixture none|staggered] [days0..30] [seed] [--json|--report-json|--measure]");host.quit(2);return
	var days: int=int(args[0]) if args.size()>0 else 30
	if days<0 or days>30:printerr("M28 supports0..30 days");host.quit(2);return
	var seed: int=int(args[1]) if args.size()>1 else 42
	var r=Runner.new(seed,settings["--condition"],settings["--arm"],settings["--fixture"])
	var measured: bool=args.size()>2 and args[2]=="--measure";r.measure=measured;r.world.measure_ticks=measured
	var stamp: int=Time.get_ticks_usec();r.run(days);var elapsed: int=Time.get_ticks_usec()-stamp
	stamp=Time.get_ticks_usec();var report: Dictionary=r.report();var report_usec: int=Time.get_ticks_usec()-stamp
	var data={"report":report}
	if args.size()>2 and args[2] in ["--json","--measure"]:data["events"]=r.world.events()
	if measured:data["measurement"]={"run_usec":elapsed,"report_usec":report_usec,"appointments":r.appointments,"ticks":r.world.tick_timings}
	print(JSON.stringify(data,"",true));host.quit()
