extends RefCounted
## One worker/one request slot. No world/SceneTree references, no worker resource loads.
const Job=preload("res://scripts/sim/planning_job.gd")
var error: String=""
var _math: RefCounted
var _cache: Dictionary={"tables":{},"components":{}}
var _thread=Thread.new()
var _mutex=Mutex.new()
var _ready=Semaphore.new()
var _request=PackedByteArray()
var _response=PackedByteArray()
var _status: String="idle"
var _stopping: bool=false
var _cancel: bool=false
var _delay_ms: int=0
var _queued_usec: int=0
var _started_usec: int=0
var _finished_usec: int=0
var _last_id: int=0

func start() -> bool:
	assert(OS.get_thread_caller_id()==OS.get_main_thread_id())
	if _thread.is_started() or _stopping: return false
	# Extension loading/registration/instance construction occurs only on the main thread.
	_math=preload("res://scripts/sim/native_math.gd").new("rust")
	error=_math.error
	if not error.is_empty(): return false
	var code=_thread.start(_work)
	if code!=OK: error="Thread start failed: %d"%code
	return code==OK

func submit(bytes: PackedByteArray,delay_ms: int=0) -> bool:
	assert(OS.get_thread_caller_id()==OS.get_main_thread_id())
	var job=Job.decode(bytes)
	if not _thread.is_started() or delay_ms<0 or delay_ms>2000 or job.is_empty(): return false
	_mutex.lock()
	if _status!="idle" or _stopping or job.id<=_last_id:
		_mutex.unlock()
		return false
	_last_id=job.id
	_request=bytes.duplicate()
	_response=PackedByteArray()
	_cancel=false
	_delay_ms=delay_ms
	_queued_usec=Time.get_ticks_usec()
	_status="queued"
	_mutex.unlock()
	_ready.post()
	return true

func poll() -> Dictionary:
	assert(OS.get_thread_caller_id()==OS.get_main_thread_id())
	# Never wait for the worker on a normal frame callback, even on the tiny mailbox lock.
	if not _mutex.try_lock(): return {"status":"pending"}
	var result={"status":_status,"queued_usec":_queued_usec,"started_usec":_started_usec,"finished_usec":_finished_usec}
	if _status in ["completed","canceled"]:
		result["bytes"]=_response.duplicate()
	_mutex.unlock()
	return result

func acknowledge() -> bool:
	_mutex.lock()
	var ok: bool=_status in ["completed","canceled"]
	if ok:
		_status="idle"
		_request=PackedByteArray()
		_response=PackedByteArray()
	_mutex.unlock()
	return ok

func cancel() -> bool:
	_mutex.lock()
	var ok: bool=_status in ["queued","running","completed"]
	if ok:
		_cancel=true
		if _status=="completed":
			_status="canceled"
			_response=PackedByteArray()
	_mutex.unlock()
	return ok

func _work() -> void:
	while true:
		_ready.wait()
		_mutex.lock()
		if _stopping:
			_mutex.unlock()
			return
		var request: PackedByteArray=_request
		var delay: int=_delay_ms
		_status="running"
		_started_usec=Time.get_ticks_usec()
		_mutex.unlock()
		# Controlled fixture only; sleeps on worker, never pumps/spins on main thread.
		if delay>0: OS.delay_msec(delay)
		_mutex.lock()
		var canceled: bool=_cancel or _stopping
		_mutex.unlock()
		_cache.components.clear()
		var response: PackedByteArray=PackedByteArray() if canceled else Job.compute(request,_math,_cache)
		_mutex.lock()
		_finished_usec=Time.get_ticks_usec()
		_response=PackedByteArray() if _cancel or _stopping else response
		_status="canceled" if _cancel or _stopping else "completed"
		_mutex.unlock()

func shutdown() -> void:
	# Explicit teardown only, never called by ordinary frame servicing/polling.
	assert(OS.get_thread_caller_id()==OS.get_main_thread_id())
	_mutex.lock()
	_stopping=true
	_cancel=true
	_mutex.unlock()
	_ready.post()
	if _thread.is_started(): _thread.wait_to_finish()
	_status="closed"
	_math=null
	_cache.clear()
	_request=PackedByteArray()
	_response=PackedByteArray()
