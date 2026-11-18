extends "res://scripts/sim/demand_world.gd"
## M28 opt-in owner-local memories. All economic authority stays inherited.
const InputMemory=preload("res://scripts/sim/input_memory.gd")
const InputForecast=preload("res://scripts/sim/input_projection.gd")
var input_arm: String
var _input_orders: Array=[]
var _input_points: Dictionary={}
var _input_forecasts: Array=[]
var _input_projections: Array=[]
func _init(seed_value: int=42,condition: String="reference",arm: String="R_baseline_instrumented",selected_fixture: String="none") -> void:
	assert(arm in InputMemory.ARMS);input_arm=arm
	super(seed_value,condition,"requests_smoothed",selected_fixture)
func snapshot() -> Dictionary:
	return super().merged({"input_reliability":{"arm":input_arm,"orders":_input_orders.duplicate(true),"points":_input_points.duplicate(true),"forecasts":_input_forecasts.duplicate(true),"projections":_input_projections.duplicate(true)}})
func _on_recorded_event(e: Dictionary) -> void:
	super(e)
	if not e.success:return
	if e.action=="day_started":_input_points.clear()
	if e.action!="demand_order_observed" or e.details.kind=="retail":return
	var d: Dictionary=e.details
	var b: String="bakery" if d.kind=="flour" else "mill" if e.actor=="bram" else "brewery"
	var rule: Dictionary=InputMemory.INPUTS[b]
	assert(e.actor==Brew.OWNERS[b] and d.seller==rule.supplier and d.item==rule.item)
	if _input_orders.any(func(r):return r.order_event_id==e.id or (r.business==b and r.day==e.day)):return
	assert(d.quantity%rule.lot_size==0 and d.filled%rule.lot_size==0)
	var inspected: Dictionary=_input_terms[b]
	assert(inspected.day==e.day and inspected.quote==d.quote)
	@warning_ignore("integer_division")
	var requested: int=d.quantity/rule.lot_size
	@warning_ignore("integer_division")
	var filled: int=d.filled/rule.lot_size
	_input_orders.append({"business":b,"owner":e.actor,"supplier":d.seller,"item":d.item,"price":d.quote.unit_price,"quote":d.quote.duplicate(true),"day":e.day,"minute":e.minute,"lot_size":rule.lot_size,"requested":requested,"filled":filled,"rationed":requested-filled,"eligible":true,"order_event_id":e.id,"inspection_event_id":inspected.inspection_event_id,"source_ids":d.source_ids.duplicate(),"receipt_ids":d.receipt_ids.duplicate()})
	# Never emit recursively here: the parent still links its native last receipt.
func freeze_demand() -> void:
	super()
	if not _input_points.is_empty():return
	for b in Brew.ORDER:
		var own: Array=_input_orders.filter(func(r):return r.business==b)
		var point: Dictionary=InputMemory.estimate(own,b,_day,_input_terms.get(b,{}))
		_input_points[b]=point;_input_forecasts.append(point)
		_record("input_reliability_frozen",Brew.OWNERS[b],b,true,point)
func vacancy_observation(owner: String,b: String) -> Dictionary:
	var o: Dictionary=super(owner,b)
	assert(_input_points.has(b))
	if input_arm=="R_input_aware" and b!="farm":o["input_reliability"]=_input_points[b].duplicate(true)
	return o
func _renewal_plan(o: Dictionary) -> Dictionary:
	return Planning.renewal(o,InputForecast.forecast) if input_arm=="R_input_aware" else super(o)
func advertise(owner: String,b: String) -> bool:
	if _at_board(owner) and Brew.OWNERS.get(b,"")==owner:
		var o: Dictionary=vacancy_observation(owner,b);var p: Dictionary=_renewal_plan(o)
		var observed: Dictionary=o.duplicate(true);observed["input_reliability"]=_input_points[b].duplicate(true)
		var candidates: Array=[]
		for c in p.candidates:candidates.append(InputForecast.project(observed,c.headcount,input_arm=="R_input_aware"))
		var row={"day":_day,"business":b,"arm":input_arm,"estimate":_input_points[b].duplicate(true),"candidates":candidates,"headcount":p.headcount}
		_input_projections.append(row);_record("input_forecast_projection",owner,b,true,row)
	return super(owner,b)
