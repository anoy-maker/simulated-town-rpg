extends "res://scripts/sim/binding_world.gd"
## M26 only. New public requests disclose intent, never private purchasing power.
const Memory=preload("res://scripts/sim/demand_memory.gd")
var demand_arm: String
var _demand_live: Dictionary={}
var _demand_days: Array=[]
var _demand_orders: Dictionary={}
var _demand_points: Dictionary={}
var _demand_forecasts: Array=[]
func _init(seed_value: int=42,condition: String="reference",arm: String="legacy_instrumented",selected_fixture: String="none") -> void:
	assert(arm in Memory.ARMS)
	demand_arm=arm
	super(seed_value,condition,"matching",selected_fixture)
func snapshot() -> Dictionary:
	return super().merged({"demand_observations":{"arm":demand_arm,"live":_demand_live.duplicate(true),"days":_demand_days.duplicate(true),"orders":_demand_orders.duplicate(true),"points":_demand_points.duplicate(true),"forecasts":_demand_forecasts.duplicate(true)}})
func _witness(b: String) -> String:
	var owner: String=Brew.OWNERS[b]
	return owner if _at(owner,Brew.SITES[b]) and _space.presences[owner].activity!="walking" else ""
func _on_recorded_event(e: Dictionary) -> void:
	super(e)
	if not e.success:return
	if e.action=="day_started":
		_demand_live.clear();_demand_points.clear()
		for b in Brew.ORDER:
			var item: String=Brew.INDUSTRIES[_businesses[b].industry].output
			_demand_live[b]=Memory.day_record(_day,b,item,_quotes[b][item])
	if e.action=="spatial_clock":
		for b in Brew.ORDER:
			if not _demand_live.has(b) or e.details.from<Brew.TRADE[b][0] or e.details.to>Brew.TRADE[b][1]:continue
			var r: Dictionary=_demand_live[b];var q: Dictionary=_quotes[b][r.item]
			r.coverage_ticks+=1
			r.quote_consistent=r.quote_consistent and q.active and q.version==r.version and q.unit_price==r.price
			if not _witness(b).is_empty():r.witness_ticks+=1;r.witness_clock_ids.append(e.id)
	if e.action=="spatial_encounter" and e.details.kind=="inspected" and _demand_live.has(e.target):
		var r: Dictionary=_demand_live[e.target]
		if not _witness(e.target).is_empty() and _entities[e.target].inventory[r.item]==0:r.empty_inspection_ids.append(e.id)
	if e.action=="purchase" and _demand_live.has(e.target):
		var r: Dictionary=_demand_live[e.target]
		r.sales+=e.details.quantity;r.sale_ids.append(e.id)
func close_demand_windows(minute: int) -> void:
	for b in Brew.ORDER:
		if minute!=Brew.TRADE[b][1]:continue
		var r: Dictionary=Memory.close(_demand_live[b],_events.size()+1)
		_demand_days.append(r)
		_record("demand_day_closed",Brew.OWNERS[b],b,true,r)
func _intent_key(buyer: String,seller: String,q: Dictionary) -> String:
	return "%04d:%s:%s:%s:%d"%[_day,buyer,seller,q.item,q.version]
func _publish_order(buyer: String,seller: String,q: Dictionary,quantity: int,filled: int,source_ids: Array,receipt_ids: Array,kind: String) -> void:
	var key: String=_intent_key(buyer,seller,q)
	if quantity<=0 or _demand_orders.has(key):return
	var row={"key":key,"buyer":buyer,"seller":seller,"item":q.item,"quote":q.duplicate(true),"quantity":quantity,"filled":filled,"unfilled":quantity-filled,"reason":"stockout" if quantity>filled else "fulfilled","kind":kind,"source_ids":source_ids.duplicate(),"receipt_ids":receipt_ids.duplicate(),"witness":_witness(seller),"day":_day,"minute":_space.minute}
	_demand_orders[key]=row
	_record("demand_order_observed",buyer,seller,true,row)
	var r: Dictionary=_demand_live[seller]
	r.order_ids.append(_events.back().id);r.unfilled+=quantity-filled
func shop_at(id: String,seller: String) -> bool:
	if seller not in ["bakery","brewery"] or not inspect_offers(id,seller).success:return false
	var inspection: int=_events.back().id
	var o: Dictionary=consumer_observation(id,seller);var proposal: Dictionary=Policy.basket(o)
	if not o.offers.is_empty() and _demand_orders.has(_intent_key(id,seller,o.offers[0])):
		return _reject("demand_customer_intent",id,seller,{},"duplicate_day_buyer_offer")
	if not _begin(id,"shop",5,seller):return false
	var item: String="bread" if seller=="bakery" else "ale"
	var quantity: int=proposal[item];var requested: int=quantity
	var q: Dictionary=o.offers[0] if not o.offers.is_empty() else {}
	# Private intent calculation. Neither this counterfactual nor money enters books.
	if not q.is_empty() and q.active and q.available==0:
		var intent: Dictionary=o.duplicate(true);intent.stock[item]=1
		requested=Policy.basket(intent)[item]
	if q.is_empty() or not _current_quote(q) or _demand_orders.has(_intent_key(id,seller,q)):requested=0
	var intent_id: Variant=null
	_record("demand_customer_intent",id,seller,true,{"item":item,"quantity":requested,"quote":q,"inspection_event_id":inspection,"witness":_witness(seller)})
	intent_id=_events.back().id
	var success: bool=true;var receipt: Variant=null;var attempted: Variant=null
	_shopper=id
	if requested>0:
		var accepted: bool=purchase_quote(_space.presences[id].account,q,1)
		attempted=_events.back().id
		if quantity>0:success=accepted;receipt=attempted
	_shopper=""
	if requested>0:_publish_order(id,seller,q,1,1 if quantity>0 and success else 0,[intent_id],[attempted],"retail")
	_record("consumer_decision",id,seller,success,{"observation":o,"proposal":proposal,"item":item,"purchased":quantity if success else 0,"command_event_id":receipt})
	_encounter(id,seller,"purchased" if success and quantity>0 else "declined",item,quantity if success else 0)
	return success
func request_grain(owner: String,b: String,maximum: Variant,q: Variant) -> bool:
	# A submitted order is a real funded production request, not an arbitrary
	# wishlist. The seller receives only its validated public quantity afterward.
	if b in ["mill","brewery"] and owner==Brew.OWNERS[b] and maximum is int:
		var allowed: int=Planning.within(business_observation(owner,b,true)).lots
		if _experiment=="no_brew_request" and b=="brewery":allowed=0
		if maximum>allowed:return _reject("grain_request",owner,b,{"maximum":maximum},"unsupported_production_request")
	return super(owner,b,maximum,q)
func clear_grain(owner: String) -> bool:
	var start: int=_events.size();var eligible: Dictionary={}
	for b in ["mill","brewery"]:eligible[b]=_request_max(b)
	var ok: bool=super(owner)
	if not ok:return false
	var clearing: Dictionary=_events.back()
	for b in ["mill","brewery"]:
		if eligible[b]<=0:continue
		var r: Dictionary=_requests[b];var source: int=0;var receipts: Array=[]
		for e in _events.slice(_day_start):
			if e.action=="grain_request" and e.success and e.target==b:source=e.id
		for e in _events.slice(start):
			if e.action=="purchase" and e.actor==b:receipts.append(e.id)
		_publish_order(r.owner,"farm",r.quote,eligible[b]*r.lot_size,clearing.details.allocation[b]*r.lot_size,[source,clearing.id],receipts,"grain")
	return true
func procure_flour(owner: String) -> bool:
	var start: int=_events.size();var ok: bool=super(owner)
	if not ok:return false
	var plan: Dictionary={};var receipts: Array=[];var filled: int=0
	for e in _events.slice(start):
		if e.action=="business_plan" and e.target=="bakery":plan=e
		if e.action=="purchase":
			receipts.append(e.id)
			if e.success:filled+=e.details.quantity
	if not plan.is_empty() and plan.details.proposal.lots>0:
		var q: Dictionary=plan.details.observation.input_quote
		# The existing funded profitable plan and actual native failures are evidence.
		var legitimate: bool=not receipts.is_empty() and _current_quote(q)
		for id in receipts:
			var e: Dictionary=_events[id-1]
			if not e.success and e.details.reason!="insufficient_stock":legitimate=false
		if legitimate:_publish_order(owner,"mill",q,5*plan.details.proposal.lots,filled,[plan.id],receipts,"flour")
	return true
func freeze_demand() -> void:
	assert(_space.minute==955)
	if not _demand_points.is_empty():return
	for b in Brew.ORDER:
		var q: Dictionary=_quotes[b][Brew.INDUSTRIES[_businesses[b].industry].output]
		# Filter at the authority boundary, before invoking the seller's policy.
		var own_history: Array=_demand_days.filter(func(r):return r.business==b)
		var row: Dictionary=Memory.estimate(own_history,b,_day,q.unit_price,Brew.INDUSTRIES[_businesses[b].industry].target,demand_arm)
		if demand_arm=="legacy_instrumented":row.forecast=_sales.get(_day-1,{}).get(b,Brew.INDUSTRIES[_businesses[b].industry].target if _day<=1 else 0)
		_demand_points[b]=row.forecast;_demand_forecasts.append(row)
		_record("demand_forecast",Brew.OWNERS[b],b,true,row)
func vacancy_observation(owner: String,b: String) -> Dictionary:
	var o: Dictionary=super(owner,b)
	if demand_arm=="legacy_instrumented":return o
	# Midnight authority rechecks funding using the SAME meeting-frozen estimate.
	assert(_space.minute in [955,1440] and _demand_points.has(b))
	o.demand=_demand_points[b]
	o.remaining_sales=mini(o.production.output_stock,maxi(0,o.demand-_sales.get(_day,{}).get(b,0))) if _space.minute<Brew.TRADE[b][1] else 0
	return o
