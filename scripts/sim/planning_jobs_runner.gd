extends "res://scripts/sim/learning_runner.gd"
## M21 event-loop experiment. Historical run()/CLI paths remain synchronous.
const Job=preload("res://scripts/sim/planning_job.gd")
const Worker=preload("res://scripts/sim/planning_worker.gd")
var mode: String
var error: String=""
var worker: RefCounted
var jobs: Array=[]
var preparations: Array=[]
var appointment_latencies: Array=[]
var _remaining: int=0
var _cursor: int=-1
var _pending: Dictionary={}
var _next_id: int=1
var _last_key: Array=[]
var delay_ms: int=0
var fixture: String="none"
var fixture_applied: bool=false
var _closed: bool=false
var fixture_evidence: Dictionary={}

func _init(seed_value: int=42,selected_stage: String="D") -> void:
	super(seed_value,selected_stage)
	world=preload("res://scripts/sim/planning_jobs_world.gd").new(seed_value)
	_initial=world.snapshot()

func configure(days: int,selected_mode: String) -> bool:
	if not mode.is_empty() or days<0 or days>10000 or selected_mode not in ["sync","scheduled"] or stage not in ["C","D"]: return false
	mode=selected_mode
	_remaining=days
	measure_appointments=true
	if mode=="sync": error=select_backend("rust")
	else:
		worker=Worker.new()
		if not worker.start(): error=worker.error
	return error.is_empty()

func _validity() -> String:
	# Main-thread authority tokens only. No extra state is sent to the policy.
	# Public supplier/own quote revisions invalidate even if remembered inspection terms don't change.
	return Job.fingerprint([world._day,world._space.minute,stage,posted,
		world._quotes.mill.flour,world._quotes.bakery.bread,
		world._space.presences.cora,world._cargo.bakery])

func _after_appointments(minute: int) -> void:
	if minute==730:
		# Diagnostic of genuinely consulted terms, not an early planning_observation().
		preparations.append({"day":world._day,"minute":minute,"belief_hash":Job.fingerprint(world.beliefs),
			"known_quote":world._consulted.duplicate(true),"own_cargo":world._cargo.bakery.duplicate(true),
			"own_state":[world._entities.bakery.money,world._entities.bakery.inventory.flour,world._entities.bakery.inventory.bread],
			"posted":posted.duplicate(),"carry_known_here":false,"full_proposal_prepared":false})
	if minute!=745: return
	if mode=="sync":
		super(minute)
		return
	_submit(0)

func _submit(retries: int,previous_id: int=0) -> void:
	var start=Time.get_ticks_usec()
	var o: Dictionary=world.planning_observation(posted)
	var b: Dictionary=world.beliefs.duplicate(true)
	if retries==0 and not preparations.is_empty():
		preparations.back()["at_commit_own_state"]=o.state.slice(0,3)
		preparations.back()["same_beliefs_at_commit"]=preparations.back().belief_hash==Job.fingerprint(b)
		preparations.back()["carry_at_commit"]=o.carry
	var bytes=Job.create(_next_id,o,b,stage)
	if bytes.is_empty() or not worker.submit(bytes,delay_ms):
		error="Job submission rejected"
		return
	if not world.hold_planning(_next_id,previous_id):
		worker.cancel()
		error="Cannot acquire planning barrier"
		return
	_pending={"id":_next_id,"day":o.day,"minute":745,"owner":"cora","status":"queued","retries":retries,
		"observation_hash":Job.fingerprint(o),"belief_hash":Job.fingerprint(b),"input_hash":Job.fingerprint([o,b,stage,Job.PARAMS]),
		"validity_hash":_validity(),"snapshot":bytes,"submitted_usec":start,"barrier_frames":0,"submit_usec":Time.get_ticks_usec()-start}
	_next_id+=1

func _fixture_change() -> void:
	fixture_applied=true
	var before: String=_pending.input_hash
	match fixture:
		"funds": assert(world.contribute_capital("cora","bakery",1))
		"inventory": assert(world.release_deposit())
		"quote": assert(world.revise_quote("cora","bakery","bread",5))
		"supplier": assert(world._revise_market_quote("bram","mill","flour",5))
		"beliefs":
			var revised: Dictionary=world.beliefs.duplicate(true)
			revised.local.weights[0]+=0.01
			revised.local.weights[12]-=0.01
			world.beliefs=revised
		"presence": assert(world.depart("cora",[7,3]))
		"cancel": assert(worker.cancel())
	fixture_evidence={"kind":fixture,"day":world._day,"minute":world._space.minute,"original_input_hash":before,
		"decisions_before":decisions.size(),"event_count_after_change":world._events.size()}

func commit_result(response: Dictionary) -> bool:
	# A caller cannot choose another actor, timestamp, job or input, or commit twice.
	if _pending.is_empty() or _pending.status not in ["queued","running"]: return false
	for key in ["id","owner","day","minute","input_hash"]:
		if response.get(key)!=_pending[key]: return false
	if not response.get("ok",false) or not Job._keys(response.get("proposal"),["selected_price","candidates","today","information_evaluated","reason"]): return false
	if world._planning_id!=_pending.id or world._day!=_pending.day or world._space.minute!=745: return false
	var o: Dictionary=world.planning_observation(posted)
	if _pending.validity_hash!=_validity() or _pending.input_hash!=Job.fingerprint([o,world.beliefs,stage,Job.PARAMS]): return false
	var proposal: Dictionary=response.proposal
	if not proposal.get("selected_price") is int or proposal.selected_price not in preload("res://scripts/sim/bakery_policy.gd").candidates(o.current_price,posted): return false
	var key: Array=[_pending.day,745,"cora",_pending.id]
	if not _last_key.is_empty() and key<=_last_key: return false
	_commit_proposal(o,world.beliefs,proposal)
	_last_key=key
	_pending.status="committed"
	assert(world.release_planning(_pending.id))
	return true

func _service_barrier() -> bool:
	_pending.barrier_frames+=1
	var mail: Dictionary=worker.poll()
	if mail.status=="running": _pending.status="running"
	if fixture!="none" and not fixture_applied and mail.status=="running": _fixture_change()
	if mail.status not in ["completed","canceled"]: return false
	var now=Time.get_ticks_usec()
	_pending["worker_started_usec"]=mail.started_usec
	_pending["worker_finished_usec"]=mail.finished_usec
	_pending["queue_usec"]=mail.started_usec-mail.queued_usec
	_pending["worker_wall_usec"]=mail.finished_usec-mail.started_usec
	_pending["poll_delay_usec"]=now-mail.finished_usec
	_pending["barrier_usec"]=now-_pending.submitted_usec
	var response: Dictionary=bytes_to_var(mail.bytes) if not mail.bytes.is_empty() else {}
	if mail.status=="completed":
		_pending["compute_usec"]=response.get("compute_usec",0)
		_pending["worker_thread_id"]=response.get("thread_id",0)
		var commit_started=Time.get_ticks_usec()
		var accepted: bool=commit_result(response)
		_pending["commit_work_usec"]=Time.get_ticks_usec()-commit_started
		if not accepted: _pending.status="stale"
	else: _pending.status="canceled"
	_pending["commit_latency_usec"]=Time.get_ticks_usec()-_pending.submitted_usec
	var status: String=_pending.status
	var retries: int=_pending.retries
	var expected_day: int=_pending.day
	var previous_id: int=_pending.id
	_pending.erase("snapshot")
	jobs.append(_pending.duplicate(true))
	_pending={}
	assert(worker.acknowledge())
	if status!="committed":
		if world._day!=expected_day or world._space.minute!=745 or retries>=2:
			error="Cannot resubmit at the original decision boundary"
			return false
		# Refresh only permitted information at this same simulated timestamp.
		_submit(retries+1,previous_id)
		return false
	appointment_latencies.append({"day":expected_day,"minute":745,"usec":jobs.back().commit_latency_usec})
	return true

func step() -> bool:
	assert(OS.get_thread_caller_id()==OS.get_main_thread_id())
	if _closed or not error.is_empty(): return true
	if not _pending.is_empty():
		if not _service_barrier(): return not error.is_empty()
		_cursor+=1
		return false
	if _cursor<0:
		if _remaining==0: return true
		world.advance_day()
		_day_started()
		_cursor=0
	var minute: int=APPOINTMENTS[_cursor]
	_run_appointment(minute)
	if _pending.is_empty(): _cursor+=1
	if _cursor==APPOINTMENTS.size():
		_day_completed()
		_remaining-=1
		_cursor=-1
	return _remaining==0 and _pending.is_empty()

func close() -> void:
	if _closed: return
	if worker!=null: worker.shutdown()
	if not _pending.is_empty():
		if _pending.status!="committed": _pending.status="canceled"
		_pending.erase("snapshot")
		jobs.append(_pending.duplicate(true))
		_pending={}
	if world._planning_id!=0: assert(world.release_planning(world._planning_id))
	_closed=true
	if _remaining>0: error="Planning run canceled before completion"
