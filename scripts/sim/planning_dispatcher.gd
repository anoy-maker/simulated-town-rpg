extends RefCounted
## M22 bounded proposal dispatcher. No world references or authoritative commits.
const Job=preload("res://scripts/sim/planning_job.gd")
const Worker=preload("res://scripts/sim/planning_worker.gd")
const MAX_CAPACITY=16
const MAX_ADMISSIONS=1024
const MAX_RESPONSE_BYTES=524288
var error: String=""
var ledger: Array=[]
var rejections: Array=[]
var rejection_counts: Dictionary={}
var _workers: Array=[]
var _active: Array=[]
var _records: Dictionary={}
var _order: Array=[]
var _cursor: int=0
var _last_key: Array=[]
var _capacity: int=0
var _epoch: int=0
var _outstanding: int=0
var _request_bytes: int=0
var _response_bytes: int=0
var _started: bool=false
var _closed: bool=false
var _now: int=0
var _maxima={"outstanding":0,"waiting":0,"running":0,"completed":0,"input_bytes":0,"output_bytes":0}

func _main() -> bool:
	return OS.get_thread_caller_id()==OS.get_main_thread_id()
func start(count: int=1,capacity: int=16,epoch: int=1,factory: Callable=Callable()) -> bool:
	if not _main() or _started or _closed or count<1 or count>4 or capacity<count or capacity>MAX_CAPACITY or epoch<1: return false
	_capacity=capacity
	_epoch=epoch
	for i in count:
		var worker: RefCounted=factory.call() if factory.is_valid() else Worker.new()
		if not worker.start():
			error=worker.error
			worker.shutdown()
			for previous in _workers: previous.shutdown()
			_workers.clear()
			_closed=true
			return false
		_workers.append(worker)
		_active.append("")
	_started=true
	return true
func _reject(reason: String,id: String) -> String:
	rejection_counts[reason]=rejection_counts.get(reason,0)+1
	if rejections.size()<64: rejections.append({"id":id,"status":"rejected","reason":reason})
	return reason
func submit(id: String,key: Array,packet: PackedByteArray,deadline: int=-1,delay_ms: int=0) -> String:
	# Concurrent/off-thread producers fail before touching any shared container.
	if not _main(): return "main_thread_only"
	if not _started or _closed: return _reject("closed",id)
	if not error.is_empty(): return _reject("dispatcher_failed",id)
	if id.is_empty() or id.length()>64 or _records.has(id): return _reject("invalid_or_duplicate_id",id)
	if _outstanding>=_capacity: return _reject("full",id)
	if _order.size()>=MAX_ADMISSIONS: return _reject("admission_limit",id)
	if key.size()!=3 or not key.all(func(x):return x is int and x>=0 and x<=1000000000) or deadline< -1 or delay_ms<0 or delay_ms>2000: return _reject("invalid_key_or_deadline",id)
	var stable: Array=key+[id]
	if not _last_key.is_empty() and stable<=_last_key: return _reject("nonmonotone_key",id)
	var begin=Time.get_ticks_usec()
	var job=Job.decode(packet)
	if job.is_empty(): return _reject("invalid_packet",id)
	# Synthetic task identity is distinct from Cora's real source observation/owner.
	# Transport IDs increase on each worker; they never become world NPC IDs.
	var serial: int=_order.size()+1
	job.id=serial
	var encode_started=Time.get_ticks_usec()
	var owned=var_to_bytes(job)
	var encode_usec=Time.get_ticks_usec()-encode_started
	_records[id]={"id":id,"epoch":_epoch,"key":stable,"serial":serial,"status":"queued","outcome":"",
		"input_hash":job.input_hash,"source_day":job.day,"owner":job.owner,"minute":job.minute,
		"packet":owned,"result":PackedByteArray(),"deadline":deadline,"delay_ms":delay_ms,
		"enqueued_usec":begin,"serialize_usec":encode_usec,"admission_usec":Time.get_ticks_usec()-begin}
	_order.append(id)
	_last_key=stable
	_outstanding+=1
	_request_bytes+=owned.size()
	_track()
	return ""
func _free_input(r: Dictionary) -> void:
	_request_bytes-=r.packet.size()
	r.packet=PackedByteArray()
func _terminal(r: Dictionary,status: String,reason: String) -> void:
	if r.status in ["released","acknowledged"]: return
	r.status=status
	r.outcome=status
	r["reason"]=reason
	_free_input(r)
	_response_bytes-=r.result.size()
	r.result=PackedByteArray()
func cancel(id: String) -> bool:
	if not _main() or not _records.has(id): return false
	var r: Dictionary=_records[id]
	if r.status not in ["queued","running","completed"]: return false
	_terminal(r,"canceled","caller_canceled")
	for i in _active.size():
		if _active[i]==id: _workers[i].cancel()
	return true
func _fail(reason: String,id: String) -> void:
	if error.is_empty(): error=reason
	for name in _order:
		var r: Dictionary=_records[name]
		if r.status in ["queued","running","completed"]: _terminal(r,"failed" if name==id else "canceled",reason)
	for i in _active.size():
		if not _active[i].is_empty(): _workers[i].cancel()
func _track() -> void:
	var waiting=0
	var completed=0
	for r in _records.values():
		if r.status=="queued": waiting+=1
		if r.status in ["completed","released"]: completed+=1
	var running: int=_active.filter(func(x):return not x.is_empty()).size()
	for pair in [["outstanding",_outstanding],["waiting",waiting],["running",running],["completed",completed],["input_bytes",_request_bytes],["output_bytes",_response_bytes]]:
		_maxima[pair[0]]=maxi(_maxima[pair[0]],pair[1])
func service(now_tick: int=0,fingerprints: Dictionary={}) -> void:
	if not _main() or not _started or _closed: return
	if now_tick<_now:
		_fail("logical_time_reversed","")
		return
	_now=now_tick
	for id in _order:
		var r: Dictionary=_records[id]
		if r.status not in ["queued","running","completed"]: continue
		if (r.deadline>=0 and now_tick>r.deadline) or (fingerprints.has(id) and fingerprints[id]!=r.input_hash):
			_terminal(r,"stale","expired_or_changed_fingerprint")
			for i in _active.size():
				if _active[i]==id: _workers[i].cancel()
	for i in _workers.size():
		var worker: RefCounted=_workers[i]
		var id: String=_active[i]
		if not worker._thread.is_alive():
			_fail("worker_stopped",id)
			continue
		if id.is_empty(): continue
		var mail: Dictionary=worker.poll()
		if mail.status not in ["completed","canceled"]: continue
		var r: Dictionary=_records[id]
		r["started_usec"]=mail.started_usec
		r["finished_usec"]=mail.finished_usec
		r["polled_usec"]=Time.get_ticks_usec()
		if r.status=="running":
			if mail.status=="canceled": _terminal(r,"canceled","worker_canceled")
			elif mail.bytes.size()>MAX_RESPONSE_BYTES or mail.bytes.size()<4 or not mail.bytes.has_encoded_var(0,false): _fail("invalid_worker_packet",id)
			else:
				var response: Variant=bytes_to_var(mail.bytes)
				if not response is Dictionary or response.get("ok")!=true or response.get("id")!=r.serial or response.get("owner")!=r.owner or response.get("day")!=r.source_day or response.get("minute")!=r.minute or response.get("input_hash")!=r.input_hash or not response.get("proposal") is Dictionary:
					_fail("invalid_worker_result",id)
				else:
					_free_input(r)
					r.result=mail.bytes.duplicate()
					_response_bytes+=r.result.size()
					r.status="completed"
					r.outcome="completed"
					r["compute_usec"]=response.compute_usec
					r["thread_id"]=response.thread_id
					r["batches"]=response.batches
		assert(worker.acknowledge())
		_active[i]=""
	if error.is_empty():
		for i in _workers.size():
			if not _active[i].is_empty(): continue
			for id in _order:
				var r: Dictionary=_records[id]
				if r.status!="queued": continue
				r["dispatched_usec"]=Time.get_ticks_usec()
				if not _workers[i].submit(r.packet,r.delay_ms):
					_fail("worker_submit_rejected",id)
					break
				_active[i]=id
				r.status="running"
				break
	_track()
func release_ready(limit: int=4) -> Array:
	var out: Array=[]
	if not _main() or _closed or limit<1 or limit>MAX_CAPACITY: return out
	while _cursor<_order.size() and out.size()<limit:
		var r: Dictionary=_records[_order[_cursor]]
		if r.status not in ["completed","canceled","stale","failed"]: break
		r["released_usec"]=Time.get_ticks_usec()
		r.status="released"
		var release_started=Time.get_ticks_usec()
		var item={"id":r.id,"epoch":_epoch,"key":r.key.duplicate(),"status":r.outcome,"input_hash":r.input_hash,"bytes":r.result.duplicate()}
		ledger.append({"id":r.id,"epoch":_epoch,"key":r.key.duplicate(),"status":r.outcome})
		out.append(item)
		r["release_work_usec"]=Time.get_ticks_usec()-release_started
		_cursor+=1
	_track()
	return out
func acknowledge(id: String,epoch: int) -> bool:
	if not _main() or _closed or epoch!=_epoch or not _records.has(id) or _records[id].status!="released": return false
	var r: Dictionary=_records[id]
	_response_bytes-=r.result.size()
	r.result=PackedByteArray()
	r.status="acknowledged"
	_outstanding-=1
	return true
func diagnostics() -> Dictionary:
	var records: Array=[]
	for id in _order:
		var source: Dictionary=_records[id]
		var r: Dictionary={}
		for key in source:
			if key in ["packet","result"]: continue
			var value: Variant=source[key]
			r[key]=value.duplicate(true) if value is Array or value is Dictionary else value
		records.append(r)
	return {"epoch":_epoch,"capacity":_capacity,"worker_count":_workers.size(),"outstanding":_outstanding,"maxima":_maxima.duplicate(),
		"current_input_bytes":_request_bytes,"current_output_bytes":_response_bytes,"records":records,"ledger":ledger.duplicate(true),"rejections":rejections.duplicate(true),"rejection_counts":rejection_counts.duplicate(),"error":error}
func reset_metrics() -> bool:
	if not _main() or _outstanding!=0 or _active.any(func(x):return not x.is_empty()): return false
	for key in _maxima: _maxima[key]=0
	return true
func shutdown() -> void:
	if not _main() or _closed: return
	for id in _order:
		if _records[id].status in ["queued","running","completed"]: _terminal(_records[id],"canceled","shutdown")
	for worker in _workers: worker.shutdown()
	for r in _records.values():
		_free_input(r)
		r.result=PackedByteArray()
	_response_bytes=0
	_outstanding=0
	_active.fill("")
	_closed=true
