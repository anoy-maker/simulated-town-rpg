extends "res://scripts/sim/spatial_runner.gd"
const ExecutionProfile=preload("res://scripts/sim/execution_profile.gd")
const LearningWorld=preload("res://scripts/sim/learning_world.gd")
const LearningPolicy=preload("res://scripts/sim/bakery_policy.gd")
const ShortMemory=preload("res://scripts/sim/pricing_policy.gd")
var stage: String
var decisions: Array=[]
var posted: Array=[4]
var numerical_backend: RefCounted
var decision_timings: Array=[]

func select_backend(name: String) -> String:
	if name=="gdscript":
		numerical_backend=null
		return ""
	var math=preload("res://scripts/sim/native_math.gd").new(name)
	if not math.error.is_empty(): return math.error
	numerical_backend=math
	return ""

func _init(seed_value: int=42, selected_stage: String="A") -> void:
	super(seed_value)
	assert(selected_stage in ["A","B","C","D"])
	stage=selected_stage
	world=LearningWorld.new(seed_value)
	_initial=world.snapshot()

func _day_started() -> void:
	world.begin_memory_day()

func _day_completed() -> void:
	world.end_memory_day()

func _after_appointments(minute: int) -> void:
	if minute!=745: return
	var decision_started: int=Time.get_ticks_usec()
	var profile_start: Dictionary=ExecutionProfile.decision_start() if ExecutionProfile.enabled else {}
	var o: Dictionary=world.planning_observation(posted)
	var proposal: Dictionary={"selected_price":4,"reason":"fixed","candidates":[]}
	if stage=="B":
		var recent: Dictionary=world.memory.cora.back().accounting if not world.memory.cora.is_empty() else {"sold":18,"stockout_requests":0}
		proposal=ShortMemory.decide({"current_price":o.current_price,"reference_price":o.current_price,
			"reference_demand":recent.sold+recent.stockout_requests,"sensitivity":1,
			"available":int(o.state[2])+18,"planned_inputs":48,"planned_payroll":18})
	elif stage in ["C","D"]:
		proposal=LearningPolicy.decide(o,world.beliefs,stage) if numerical_backend==null else preload("res://scripts/sim/batched_bakery_policy.gd").decide(o,world.beliefs,stage,numerical_backend)
	_commit_proposal(o,world.beliefs,proposal)
	decision_timings.append({"day":o.day,"minute":minute,"usec":Time.get_ticks_usec()-decision_started})
	if ExecutionProfile.enabled: ExecutionProfile.decision_end(profile_start,o.day,world.memory.cora.size())

func _commit_proposal(o: Dictionary,b: Dictionary,proposal: Dictionary) -> void:
	var success: bool=true
	if proposal.selected_price!=o.current_price: success=world.revise_quote("cora","bakery","bread",proposal.selected_price)
	decisions.append({"day":o.day,"observation":o,"beliefs":b.duplicate(true),"proposal":proposal,"success":success})
	if success and proposal.selected_price not in posted: posted.append(proposal.selected_price)

func _reference_verification(history: Array,final: Dictionary) -> Dictionary:
	return preload("res://scripts/sim/spatial_audit.gd").verify(history,final,true)

func report() -> Dictionary:
	var r: Dictionary=super()
	r.scenario="settlement_spatial_learning"
	r.profitable.mode="M18 "+stage
	r.prices="farm 2, mill 4, bakery versioned learned bread quotes"
	r["learning"]={"stage":stage,"memory":world.memory.duplicate(true),"beliefs":world.beliefs.duplicate(true),"decisions":decisions.duplicate(true)}
	return r
