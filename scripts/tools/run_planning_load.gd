extends SceneTree
## M22 synthetic complete jobs. No world exists in this process.
const Pool=preload("res://scripts/sim/planning_dispatcher.gd")
const Fixtures=preload("res://scripts/tools/planning_load_fixtures.gd")
const Job=preload("res://scripts/sim/planning_job.gd")
var pool: RefCounted
var fixtures: Dictionary
var count: int
var workers: int
var mixed: bool
var forced: bool
var warming: bool=true
var submitted: int=0
var released: int=0
var started: int=0
var previous: int=0
var finished: bool=false
var callbacks: Array=[]
var gaps: Array=[]
var memory: Array=[]
var expected_ids: Array=[]
var actual_hashes: Array=[]
var serialized_usec: int=0
var validation_usec: int=0
var before: Dictionary
var warm_memory: Dictionary
func _init() -> void:
	var args=OS.get_cmdline_user_args()
	if args.size()<2 or not args[0].is_valid_int() or not args[1].is_valid_int():
		printerr("Usage: run_planning_load.gd -- jobs(1|10|100) workers(1|2|4) [homogeneous|mixed|ordering]")
		quit(2)
		return
	count=int(args[0]);workers=int(args[1])
	var kind: String=args[2] if args.size()>2 else "homogeneous"
	if count not in [1,10,100] or workers not in [1,2,4] or kind not in ["homogeneous","mixed","ordering"]:
		quit(2)
		return
	mixed=kind!="homogeneous";forced=kind=="ordering"
	before=_memory()
	fixtures=Fixtures.load_all()
	pool=Pool.new()
	if not pool.start(workers):
		printerr(pool.error)
		quit(2)
		return
	for i in workers: assert(pool.submit("warm-%03d"%i,[0,0,i],fixtures["D-15"].packet).is_empty())
	Engine.max_fps=60
func _process(_delta: float) -> bool:
	if finished: return false
	var begin=Time.get_ticks_usec()
	if not warming:
		if previous!=0:gaps.append(begin-previous)
		previous=begin
	if not warming:
		# Bound producer work per frame and apply explicit backpressure without drops.
		for attempt in 4:
			if submitted==count: break
			var id="work-%03d"%submitted
			var stamp=Time.get_ticks_usec()
			var name=Fixtures.name_for(submitted,mixed)
			var packet: PackedByteArray=fixtures[name].packet.duplicate()
			serialized_usec+=Time.get_ticks_usec()-stamp
			var reason: String=pool.submit(id,[1,0,submitted],packet,-1,250 if forced and submitted==0 else 0)
			if reason=="full":break
			assert(reason.is_empty(),reason)
			expected_ids.append(id)
			submitted+=1
	pool.service()
	for item in pool.release_ready(4):
		assert(item.status=="completed")
		var stamp=Time.get_ticks_usec()
		var response: Dictionary=bytes_to_var(item.bytes)
		var index: int=released
		var name: String="D-15" if warming else Fixtures.name_for(index,mixed)
		assert(response.thread_id!=OS.get_main_thread_id())
		assert(Job.fingerprint(response.proposal)==fixtures[name].proposal_hash)
		validation_usec+=Time.get_ticks_usec()-stamp
		assert(pool.acknowledge(item.id,item.epoch))
		if not warming:
			assert(item.id==expected_ids[released])
			actual_hashes.append(fixtures[name].proposal_hash)
			released+=1
	if warming:
		if pool._outstanding==0:
			assert(pool.reset_metrics())
			warming=false
			serialized_usec=0;validation_usec=0
			warm_memory=_memory()
			started=Time.get_ticks_usec()
		return false
	if callbacks.size()%60==0:memory.append({"elapsed_usec":Time.get_ticks_usec()-started,"memory":_memory()})
	callbacks.append(Time.get_ticks_usec()-begin)
	if not pool.error.is_empty():
		finished=true
		_end_run.call_deferred(Time.get_ticks_usec()-started)
	elif released==count:
		finished=true
		_end_run.call_deferred(Time.get_ticks_usec()-started)
	return false
func _end_run(elapsed: int) -> void:
	var diagnostics: Dictionary=pool.diagnostics()
	var records: Array=diagnostics.records.filter(func(r):return r.id.begins_with("work-"))
	var ledger: Array=diagnostics.ledger.filter(func(r):return r.id.begins_with("work-"))
	assert(ledger.size()==count and records.size()==count)
	var final_memory=_memory()
	var start=Time.get_ticks_usec()
	pool.shutdown()
	var cleanup=Time.get_ticks_usec()-start
	if not pool.error.is_empty():
		printerr(pool.error)
		quit(1)
		return
	print(JSON.stringify({"count":count,"workers":workers,"kind":"ordering" if forced else "mixed" if mixed else "homogeneous",
		"run_usec":elapsed,"cleanup_usec":cleanup,"fixture_copy_usec":serialized_usec,"validation_usec":validation_usec,
		"callbacks_usec":callbacks,"heartbeat_gaps_usec":gaps,"records":records,"ledger":ledger,
		"maxima":diagnostics.maxima,"rejection_counts":diagnostics.rejection_counts,"memory_before":before,
		"memory_warm":warm_memory,"memory_final":final_memory,"memory_after_cleanup":_memory(),"memory_samples":memory,
		"proposal_digest":Job.fingerprint(actual_hashes),"release_digest":Job.fingerprint(ledger),"world_events":0},"",true))
	quit()
func _memory() -> Dictionary:
	var status=FileAccess.open("/proc/self/status",FileAccess.READ)
	var result: Dictionary={}
	if status==null:return result
	while not status.eof_reached():
		var line=status.get_line()
		for field in ["VmRSS:","VmHWM:"]:
			if line.begins_with(field):result[field.trim_suffix(":")]=int(line.trim_prefix(field).strip_edges().get_slice(" ",0))
	return result
