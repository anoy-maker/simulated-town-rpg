extends RefCounted
const Pool=preload("res://scripts/sim/planning_dispatcher.gd")
const Job=preload("res://scripts/sim/planning_job.gd")
const Fixtures=preload("res://scripts/tools/planning_load_fixtures.gd")
class Dormant extends RefCounted:
	var error: String=""
	func start() -> bool:return true
	func shutdown() -> void:pass
class Dies extends "res://scripts/sim/planning_worker.gd":
	func _work() -> void:
		_ready.wait()
		return # Controlled actual thread termination: no result/fallback.
static func packet() -> PackedByteArray:
	return FileAccess.get_file_as_bytes("res://tests/fixtures/m22/D-15.request")
static func run_pure(t: SceneTree) -> void:
	var p=Pool.new()
	t._check(not p.start(4,2),"worker count cannot exceed bounded capacity")
	t._check(p.start(1,2,1,func():return Dormant.new()),"pure queue starts without native dependency")
	var bytes=packet()
	t._check(p.submit("a",[1,745,0],bytes).is_empty(),"first immutable request admitted")
	var altered=bytes.duplicate();altered[0]=0
	t._check(p.submit("bad",[1,745,1],altered)=="invalid_packet","malformed packet rejects without consuming order")
	t._check(p.submit("a",[1,745,1],bytes)=="invalid_or_duplicate_id","duplicate task ID rejects")
	t._check(p.submit("b",[1,745,0],bytes).is_empty(),"equal order fields tie deterministically by task ID")
	t._check(p.submit("c",[1,745,2],bytes)=="full","full queue explicitly applies backpressure")
	t._check(p.cancel("a") and p.cancel("b"),"queued jobs cancel without compute")
	var out=p.release_ready()
	t._check(out.map(func(x):return x.id)==["a","b"] and out.all(func(x):return x.status=="canceled" and x.bytes.is_empty()),"ordered tombstones never fabricate proposals")
	t._check(p.release_ready().is_empty(),"duplicate release impossible")
	t._check(not p.acknowledge("a",2),"wrong epoch rejects acknowledgement")
	t._check(p.acknowledge("a",1) and not p.acknowledge("a",1),"one-shot acknowledgement releases capacity")
	t._check(p.acknowledge("b",1),"every canceled slot is accounted for")
	t._check(p.submit("a",[2,745,0],bytes)=="invalid_or_duplicate_id","acknowledged task IDs remain deduplicated")
	t._check(p.submit("0",[1,745,0],bytes)=="nonmonotone_key","earlier tie cannot enter after release watermark")
	t._check(p.submit("c",[2,745,0],bytes).is_empty(),"backpressure retry admits after acknowledgement")
	var copy=p.diagnostics();copy.records[2].key[0]=99
	t._check(p.diagnostics().records[2].key[0]==2,"diagnostics do not expose mutable ordering state")
	p.shutdown()
	t._check(p.release_ready().is_empty() and p.diagnostics().current_input_bytes==0 and p.diagnostics().current_output_bytes==0,"shutdown retains no payloads or late releases")
	t._check(p.submit("x",[3,0,0],bytes)=="closed","closed dispatcher rejects reuse")
static func _drain(t: SceneTree,p: RefCounted,count: int,now: int=0,hashes: Dictionary={}) -> Array:
	var out: Array=[]
	for frame in 300:
		await t.process_frame
		p.service(now,hashes)
		for item in p.release_ready():
			out.append(item)
			assert(p.acknowledge(item.id,item.epoch))
		if out.size()==count:break
	return out
static func run_async(t: SceneTree) -> void:
	if not FileAccess.file_exists("res://native/m20/math.gdextension"):return
	var f=Fixtures.load_all();var bytes: PackedByteArray=f["D-15"].packet
	var p=Pool.new();t._check(p.start(2,4,1),"two genuine worker-owned bridges start")
	var first: String=p.submit("a",[1,745,0],bytes,-1,250)
	var second: String=p.submit("b",[1,745,1],f["C-1"].packet)
	t._check(first.is_empty() and second.is_empty(),"independent heterogeneous jobs enqueue")
	var out=await _drain(t,p,2)
	t._check(out.map(func(x):return x.id)==["a","b"],"out-of-order execution releases strictly in key order")
	var records=p.diagnostics().records
	t._check(records[1].finished_usec<records[0].finished_usec,"injected delay actually reverses finish order")
	for i in out.size():
		var actual: Dictionary=bytes_to_var(out[i].bytes)
		t._check(Job.fingerprint(actual.proposal)==f["D-15" if i==0 else "C-1"].proposal_hash,"complete proposal exactly matches original M21 fixture")
	var producer=Thread.new()
	producer.start(func():return p.submit("wrong-thread",[2,0,0],bytes))
	t._check(producer.wait_to_finish()=="main_thread_only","off-thread concurrent producer rejects before touching queue")
	p.shutdown()
	var next=Pool.new();next.start(1,4,2)
	next.submit("cancel-running",[1,0,0],bytes,-1,150)
	next.submit("cancel-queued",[1,0,1],bytes)
	next.service()
	t._check(next.cancel("cancel-running") and next.cancel("cancel-queued"),"running and queued cancellation supported")
	out=await _drain(t,next,2)
	t._check(out.all(func(x):return x.status=="canceled" and x.bytes.is_empty()),"late canceled work cannot publish a decision")
	# Canceled computation remains in its physical worker until it has safely finished.
	for frame in 180:
		await t.process_frame
		next.service()
		if next._active.all(func(x):return x.is_empty()):break
	next.submit("expired",[2,0,0],bytes,1)
	next.submit("stale",[2,0,1],bytes)
	out=await _drain(t,next,2,2,{"stale":"changed"})
	t._check(out.all(func(x):return x.status=="stale" and x.bytes.is_empty()),"expiry and changed input fingerprints fail closed")
	t._check(not next.acknowledge("a",1),"prior generation cannot acknowledge into restarted dispatcher")
	next.shutdown()
	var failure=Pool.new();failure.start(1,2,3,func():return Dies.new())
	failure.submit("failed",[1,0,0],bytes)
	out=await _drain(t,failure,1)
	t._check(not failure.error.is_empty() and out.size()==1 and out[0].bytes.is_empty(),"actual worker termination fails closed without fallback proposal")
	t._check(failure.submit("later",[2,0,0],bytes)=="dispatcher_failed","failed dispatcher rejects subsequent work")
	failure.shutdown()
	var privacy=Pool.new();privacy.start(2,2,4)
	privacy.submit("only-one",[1,0,0],bytes)
	await _drain(t,privacy,1)
	t._check(privacy._workers[0]._cache.tables.size()>0 and privacy._workers[1]._cache.tables.is_empty(),"worker forecast caches are separate mutable ownership domains")
	privacy.shutdown()
