extends "res://scripts/sim/spatial_runner.gd"
const ExecutionProfile=preload("res://scripts/sim/execution_profile.gd")
const LearningWorld=preload("res://scripts/sim/learning_world.gd")
const LearningPolicy=preload("res://scripts/sim/bakery_policy.gd")
const ShortMemory=preload("res://scripts/sim/pricing_policy.gd")
var stage: String
var decisions: Array=[]
var posted: Array=[4]

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
	var profile_start: Dictionary=ExecutionProfile.decision_start() if ExecutionProfile.enabled else {}
	var o: Dictionary=world.planning_observation(posted)
	var proposal: Dictionary={"selected_price":4,"reason":"fixed","candidates":[]}
	if stage=="B":
		var recent: Dictionary=world.memory.cora.back().accounting if not world.memory.cora.is_empty() else {"sold":18,"stockout_requests":0}
		proposal=ShortMemory.decide({"current_price":o.current_price,"reference_price":o.current_price,
			"reference_demand":recent.sold+recent.stockout_requests,"sensitivity":1,
			"available":int(o.state[2])+18,"planned_inputs":48,"planned_payroll":18})
	elif stage in ["C","D"]: proposal=LearningPolicy.decide(o,world.beliefs,stage)
	var success: bool=true
	if proposal.selected_price!=o.current_price: success=world.revise_quote("cora","bakery","bread",proposal.selected_price)
	decisions.append({"day":o.day,"observation":o,"beliefs":world.beliefs.duplicate(true),"proposal":proposal,"success":success})
	if success and proposal.selected_price not in posted: posted.append(proposal.selected_price)
	if ExecutionProfile.enabled: ExecutionProfile.decision_end(profile_start,o.day,world.memory.cora.size())

func _reference_verification(history: Array,final: Dictionary) -> Dictionary:
	return preload("res://scripts/sim/spatial_audit.gd").verify(history,final,true)

func report() -> Dictionary:
	var r: Dictionary=super()
	r.scenario="settlement_spatial_learning"
	r.profitable.mode="M18 "+stage
	r.prices="farm 2, mill 4, bakery versioned learned bread quotes"
	r["learning"]={"stage":stage,"memory":world.memory.duplicate(true),"beliefs":world.beliefs.duplicate(true),"decisions":decisions.duplicate(true)}
	return r
