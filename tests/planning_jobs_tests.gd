extends RefCounted
const Job=preload("res://scripts/sim/planning_job.gd")
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
static func observation() -> Dictionary:
	return {"day":1,"current_price":4,"posted":[4],"state":[72,12,0,0],"supply":12,"input_price":4,"carry":3,"minimum":[1,0]}
static func run_pure(t: SceneTree) -> void:
	var o=observation()
	var b=Beliefs.fresh()
	var bytes=Job.create(1,o,b,"D")
	var job=Job.decode(bytes)
	t._check(job.observation==o and job.beliefs==b,"job roundtrip preserves all inputs exactly")
	o.state[0]=0
	t._check(Job.decode(bytes).observation.state[0]==72,"submitted bytes own their snapshot")
	t._check(Job.decode(PackedByteArray([1,2])).is_empty(),"malformed serialization rejected")
	job.owner="dain"
	t._check(Job.decode(var_to_bytes(job)).is_empty(),"unauthorized job owner rejected")
	job=Job.decode(bytes)
	job.beliefs.local.weights[0]+=0.01
	t._check(Job.decode(var_to_bytes(job)).is_empty(),"altered beliefs invalidate seal")
	job=Job.decode(bytes)
	job.observation.state[0]+=1
	t._check(Job.decode(var_to_bytes(job)).is_empty(),"altered observation invalidates seal")
	job=Job.decode(bytes)
	job.parameters.horizon=1
	t._check(Job.decode(var_to_bytes(job)).is_empty(),"shortened policy horizon rejected")
	o=observation()
	o["customer_money"]=1000
	t._check(Job.create(1,o,b,"D").is_empty(),"unauthorized information rejected at schema boundary")
	o=observation()
	o.state[0]=NAN
	t._check(Job.create(1,o,b,"D").is_empty(),"nonfinite state rejected")
	t._check(Job.create(1,observation(),b,"A").is_empty(),"nonplanning stage rejected")

static func run_worker(t: SceneTree) -> Dictionary:
	var stats: Dictionary={}
	if not FileAccess.file_exists("res://native/m20/math.gdextension"):
		stats["skipped"]="optional native build absent"
		return stats
	var math=preload("res://scripts/sim/native_math.gd").new("rust")
	var cache={"tables":{},"components":{}}
	var tables=Job.fingerprint([Beliefs._tables,Beliefs._components])
	var o=observation()
	var b=Beliefs.fresh()
	var bytes=Job.create(1,o,b,"D")
	var Profile=preload("res://scripts/sim/execution_profile.gd")
	Profile.reset(true)
	var reference: Dictionary=bytes_to_var(Job.compute(bytes,math,cache))
	t._check(Profile.snapshot().phases.is_empty() and Profile.snapshot().counts.is_empty(),"private job math never mutates profiler statics")
	Profile.reset(false)
	t._check(tables==Job.fingerprint([Beliefs._tables,Beliefs._components]),"private job math never mutates historical forecast caches")
	var worker=preload("res://scripts/sim/planning_worker.gd").new()
	t._check(worker.start(),"worker starts with main-thread initialized bridge")
	t._check(not worker.submit(PackedByteArray([1])),"worker rejects malformed request")
	t._check(worker.submit(bytes,100),"worker accepts valid bounded request")
	t._check(not worker.submit(bytes),"single-slot queue rejects overlapping job")
	var mail: Dictionary={}
	for frame in 180:
		await t.process_frame
		mail=worker.poll()
		if mail.status=="completed": break
	t._check(mail.status=="completed","worker completes without busy waiting")
	if mail.status=="completed":
		var result: Dictionary=bytes_to_var(mail.bytes)
		t._check(result.proposal==reference.proposal,"complete worker proposal exactly matches synchronous private computation")
		stats["worker_thread_id"]=result.thread_id
		t._check(result.thread_id!=OS.get_main_thread_id(),"entire policy computation executes off main thread")
		var copied: PackedByteArray=mail.bytes
		copied[0]=0
		t._check(worker.poll().bytes!=copied,"result mailbox copies preserve immutable ownership")
		t._check(worker.acknowledge(),"finished job acknowledged exactly once")
		t._check(not worker.acknowledge(),"duplicate acknowledgement rejected")
	t._check(not worker.submit(bytes),"reused job ID rejected after completed acknowledgement")
	t._check(worker.submit(Job.create(2,o,b,"D"),300),"worker accepts subsequent request after acknowledgement")
	t._check(worker.cancel(),"running/queued request can be canceled")
	for frame in 180:
		await t.process_frame
		mail=worker.poll()
		if mail.status=="canceled": break
	t._check(mail.status=="canceled" and mail.bytes.is_empty(),"cancellation suppresses result publication")
	worker.acknowledge()
	t._check(worker.submit(Job.create(3,o,b,"D"),100),"shutdown fixture submits active work")
	await t.process_frame
	var start=Time.get_ticks_usec()
	worker.shutdown()
	stats["active_shutdown_usec"]=Time.get_ticks_usec()-start
	t._check(not worker._thread.is_started(),"explicit shutdown joins active worker")
	worker.shutdown()
	t._check(not worker.submit(bytes),"closed worker cannot accept work")
	var runner=preload("res://scripts/sim/planning_jobs_runner.gd").new(42,"D")
	t._check(runner.configure(1,"scheduled"),"isolated commit fixture starts")
	while runner._pending.is_empty(): runner.step()
	t._check(not runner.world.advance_time(750) and runner.world._space.minute==745,"world authority rejects bypassing the pending clock barrier")
	var day: int=runner.world._day
	runner.world.advance_day()
	t._check(runner.world._day==day,"pending planning also prevents direct day advance")
	for frame in 180:
		await t.process_frame
		mail=runner.worker.poll()
		if mail.status=="completed": break
	var response: Dictionary=bytes_to_var(mail.bytes)
	var forged=response.duplicate(true)
	forged.owner="dain"
	var events: int=runner.world._events.size()
	t._check(not runner.commit_result(forged) and runner.world._events.size()==events,"unauthorized commit changes no world state")
	forged=response.duplicate(true)
	forged.id+=1
	t._check(not runner.commit_result(forged),"wrong job ID rejected")
	t._check(runner.commit_result(response),"matching result commits at exact 12:25")
	events=runner.world._events.size()
	t._check(not runner.commit_result(response) and runner.world._events.size()==events,"duplicate commit rejected without another economic event")
	runner.close()
	var stopped=preload("res://scripts/sim/planning_jobs_runner.gd").new(42,"D")
	stopped.configure(1,"scheduled")
	stopped.delay_ms=100
	while stopped._pending.is_empty(): stopped.step()
	stopped.close()
	var stopped_events: int=stopped.world._events.size()
	t._check(stopped.jobs.back().status=="canceled" and stopped.decisions.is_empty(),"shutdown records cancellation without applying a provisional decision")
	t._check(stopped.step() and stopped.world._events.size()==stopped_events,"closed runner cannot resume authoritative progression")
	return stats
