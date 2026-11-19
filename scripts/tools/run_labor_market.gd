extends SceneTree
const Runner=preload("res://scripts/sim/labor_market_runner.gd")
func _init() -> void:run_cli(self,OS.get_cmdline_user_args())
static func run_cli(host: SceneTree, arguments: PackedStringArray) -> void:
	var args: Array=Array(arguments)
	var settings={"--condition":"reference","--mode":"matching","--tie":"neutral_rotate","--fixture":"none"}
	while args.size()>=2 and str(args[0]).begins_with("--"):
		if not settings.has(args[0]):break
		settings[args[0]]=args[1];args=args.slice(2)
	if settings["--condition"] not in Runner.Brew.CASES or settings["--mode"] not in Runner.LaborWorld.MarketConfig.MODES or settings["--tie"] not in Runner.LaborWorld.MarketConfig.TIES or settings["--fixture"] not in Runner.LaborWorld.MarketConfig.fixtures() or args.size()>3 or (args.size()>0 and not str(args[0]).is_valid_int()) or (args.size()>1 and not str(args[1]).is_valid_int()) or (args.size()>2 and args[2] not in ["--json","--report-json","--measure"]):
		printerr("Usage: settlement_labor_market [--condition reference|tight|scarce|no_brew_request] [--mode shift_selection|matching] [--tie legacy_sorted|neutral_rotate] [--fixture none|vacancy|vacancy:<worker>] [days0..30] [seed] [--json|--report-json|--measure]");host.quit(2);return
	var days: int=int(args[0]) if args.size()>0 else 30
	if days<0 or days>30:printerr("M24 supports0..30 days");host.quit(2);return
	var seed: int=int(args[1]) if args.size()>1 else 42
	var runner=Runner.new(seed,settings["--condition"],settings["--mode"],settings["--tie"],settings["--fixture"])
	var measured: bool=args.size()>2 and args[2]=="--measure";runner.measure=measured;runner.world.measure_ticks=measured
	var stamp: int=Time.get_ticks_usec();runner.run(days);var elapsed: int=Time.get_ticks_usec()-stamp
	stamp=Time.get_ticks_usec();var r: Dictionary=runner.report();var report_usec: int=Time.get_ticks_usec()-stamp
	var data={"report":r}
	if args.size()>2 and args[2] in ["--json","--measure"]:data["events"]=runner.world.events()
	if measured:data["measurement"]={"run_usec":elapsed,"report_usec":report_usec,"appointments":runner.appointments,"ticks":runner.world.tick_timings}
	print(JSON.stringify(data,"",true));host.quit()
