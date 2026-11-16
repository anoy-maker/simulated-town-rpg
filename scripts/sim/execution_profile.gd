extends RefCounted
## Opt-in instrumentation only. Never enters world/model state or canonical reports.
static var enabled: bool=false
static var phases: Dictionary={}
static var counts: Dictionary={}
static var stack: Array=[]
static var decisions: Array=[]

class Scope extends RefCounted:
	var close: Callable
	func _notification(what: int) -> void:
		if what==NOTIFICATION_PREDELETE: close.call()

static func reset(active: bool=false) -> void:
	assert(stack.is_empty())
	enabled=active
	phases={}
	counts={}
	decisions=[]

static func scope(label: String) -> Scope:
	var frame={"label":label,"start":Time.get_ticks_usec(),"child":0}
	stack.append(frame)
	var result=Scope.new()
	result.close=func():
		assert(stack.back()==frame)
		var elapsed: int=Time.get_ticks_usec()-frame.start
		stack.pop_back()
		if not stack.is_empty(): stack.back().child+=elapsed
		if not phases.has(label): phases[label]={"calls":0,"inclusive_usec":0,"exclusive_usec":0}
		phases[label].calls+=1
		phases[label].inclusive_usec+=elapsed
		phases[label].exclusive_usec+=elapsed-frame.child
	return result

static func count(label: String, amount: int=1) -> void:
	counts[label]=counts.get(label,0)+amount

static func decision_start() -> Dictionary:
	return {"start":Time.get_ticks_usec(),"phases":phases.duplicate(true),"counts":counts.duplicate()}

static func decision_end(start: Dictionary, day: int, memory_days: int) -> void:
	var delta: Dictionary={}
	for key in counts: delta[key]=counts[key]-start.counts.get(key,0)
	var times: Dictionary={}
	for key in phases:
		var old: Dictionary=start.phases.get(key,{"inclusive_usec":0,"exclusive_usec":0})
		times[key]={"inclusive_usec":phases[key].inclusive_usec-old.inclusive_usec,"exclusive_usec":phases[key].exclusive_usec-old.exclusive_usec}
	decisions.append({"day":day,"memory_days":memory_days,"elapsed_usec":Time.get_ticks_usec()-start.start,"counts":delta,"phases":times})

static func snapshot() -> Dictionary:
	assert(stack.is_empty())
	return {"phases":phases.duplicate(true),"counts":counts.duplicate(),"decisions":decisions.duplicate(true)}
