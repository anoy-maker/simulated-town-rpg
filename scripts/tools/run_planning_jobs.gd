extends SceneTree
## Headless ~60-Hz service proof, not a graphical/player responsiveness benchmark.
var runner: RefCounted
var callbacks: Array=[]
var heartbeat_gaps: Array=[]
var barrier_heartbeats: int=0
var started: int
var previous: int=0
var selected_mode: String
var days: int
var entry_usec: int
var load_usec: int
var fixture: String
var finished: bool=false
func _init() -> void:
	entry_usec=Time.get_ticks_usec()
	var args=OS.get_cmdline_user_args()
	if args.size()<3 or args[0] not in ["C","D"] or not args[1].is_valid_int() or args[2] not in ["sync","scheduled"]:
		printerr("Usage: run_planning_jobs.gd -- C|D days sync|scheduled [delay_ms] [none|funds|inventory|quote|supplier|beliefs|presence|cancel]")
		quit(2)
		return
	days=int(args[1])
	selected_mode=args[2]
	fixture=args[4] if args.size()>4 else "none"
	runner=preload("res://scripts/sim/planning_jobs_runner.gd").new(42,args[0])
	runner.delay_ms=int(args[3]) if args.size()>3 else 0
	runner.fixture=fixture
	if fixture in ["inventory","presence"]:
		runner.world=preload("res://scripts/tools/planning_fixture_world.gd").new(42)
		runner._initial=runner.world.snapshot()
	var load_start=Time.get_ticks_usec()
	if fixture not in ["none","funds","inventory","quote","supplier","beliefs","presence","cancel"] or not runner.configure(days,selected_mode):
		printerr("Invalid planning configuration: "+runner.error)
		quit(2)
		return
	load_usec=Time.get_ticks_usec()-load_start
	Engine.max_fps=60
	started=Time.get_ticks_usec()
func _process(_delta: float) -> bool:
	if runner==null or finished: return false
	var begin=Time.get_ticks_usec()
	if previous!=0: heartbeat_gaps.append(begin-previous)
	previous=begin
	var was_pending: bool=not runner._pending.is_empty()
	var day: int=runner.world._day
	var minute: int=runner.world._space.minute
	var events: int=runner.world._events.size()
	var done: bool=runner.step()
	if was_pending:
		barrier_heartbeats+=1
		assert(runner.world._day==day and runner.world._space.minute==745)
		# Pending polling never performs later economy/time work; a commit can append only its quote.
		if runner.decisions.size()<day: assert(runner.world._events.size()==events or runner.fixture_applied)
	callbacks.append({"day":runner.world._day,"minute":runner.world._space.minute,"usec":Time.get_ticks_usec()-begin,"barrier":was_pending})
	if done:
		finished=true
		_export_results.call_deferred(Time.get_ticks_usec()-started)
	return false
func _export_results(run_usec: int) -> void:
	var start=Time.get_ticks_usec()
	runner.close()
	var shutdown_usec=Time.get_ticks_usec()-start
	if not runner.error.is_empty():
		printerr(runner.error)
		quit(1)
		return
	start=Time.get_ticks_usec()
	var report=runner.report()
	var report_usec=Time.get_ticks_usec()-start
	var canonical=JSON.stringify({"report":report},"",true)+"\n"
	var measurement={"mode":selected_mode,"stage":runner.stage,"days":days,"fixture":fixture,"run_usec":run_usec,"entry_usec":entry_usec,"load_usec":load_usec,
		"shutdown_usec":shutdown_usec,"report_usec":report_usec,"canonical_sha256":canonical.sha256_text(),"callbacks":callbacks,"heartbeat_gaps_usec":heartbeat_gaps,
		"barrier_heartbeats":barrier_heartbeats,"jobs":runner.jobs,"appointments":runner.appointment_timings,"appointment_latencies":runner.appointment_latencies,
		"decisions":runner.decision_timings,"preparations":runner.preparations,"fixture_evidence":runner.fixture_evidence,"main_thread_id":OS.get_main_thread_id()}
	start=Time.get_ticks_usec()
	var encoded=JSON.stringify({"report":report,"events":runner.world.events(),"measurement":measurement},"",true)
	var serialize_usec=Time.get_ticks_usec()-start
	print(encoded)
	print(JSON.stringify({"serialize_usec":serialize_usec}))
	quit()
