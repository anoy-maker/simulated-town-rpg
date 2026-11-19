extends SceneTree
const Runner=preload("res://scripts/sim/brewery_runner.gd")
func _init() -> void:run_cli(self,OS.get_cmdline_user_args())
static func run_cli(host: SceneTree, arguments: PackedStringArray) -> void:
	var args: Array=Array(arguments)
	var condition: String="reference"
	if args.size()>=2 and args[0]=="--condition":condition=args[1];args=args.slice(2)
	if condition not in Runner.Brew.CASES or args.size()>3 or (args.size()>0 and not str(args[0]).is_valid_int()) or (args.size()>1 and not str(args[1]).is_valid_int()) or (args.size()>2 and args[2] not in ["--json","--report-json","--measure"]):
		printerr("Usage: --scenario settlement_brewery [--condition reference|tight|scarce|no_brew_request] [days 0..30] [seed] [--report-json|--json|--measure]");host.quit(2);return
	var days: int=int(args[0]) if args.size()>0 else 30
	if days<0 or days>30:printerr("M23 experiments support 0..30 days");host.quit(2);return
	var seed: int=int(args[1]) if args.size()>1 else 42
	var measured: bool=args.size()>2 and args[2]=="--measure"
	var runner=Runner.new(seed,condition);runner.measure=measured;runner.world.measure_ticks=measured
	var start: int=Time.get_ticks_usec();runner.run(days);var elapsed: int=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec();var report: Dictionary=runner.report();var report_usec: int=Time.get_ticks_usec()-start
	var data={"report":report}
	if args.size()>2 and args[2] in ["--json","--measure"]:data["events"]=runner.world.events()
	if measured:data["measurement"]={"run_usec":elapsed,"report_usec":report_usec,"appointments":runner.appointments,"ticks":runner.world.tick_timings}
	print(JSON.stringify(data,"",true));host.quit()
