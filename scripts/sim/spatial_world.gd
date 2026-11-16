extends "res://scripts/sim/pricing_world.gd"
## M17-only spatial authority; original purchases/payroll/recipes remain authoritative.
const Town=preload("res://scripts/sim/spatial_config.gd")
var _space: Dictionary={}
var _cargo: Dictionary={}
var _courier: String=""
var _shopper: String=""
var _completing: String=""
var _external_consumer: String=""


func _init(seed_value: int=42, experiment: String="control") -> void:
	var economy: Dictionary=Enterprise.initial()
	_space=Town.initial(economy,experiment)
	for business in economy.businesses:
		_cargo[business]={"holder":economy.businesses[business].owner,"inventory":{"wheat":0,"flour":0,"bread":0}}
	super(seed_value,economy)


func snapshot() -> Dictionary:
	var _profile_scope=ExecutionProfile.scope("state_copy") if ExecutionProfile.enabled else null
	var state: Dictionary=super()
	state["spatial"]=_space.duplicate(true)
	state["cargo"]=_cargo.duplicate(true)
	return state


func _absolute() -> int:
	return maxi(0,_day-1)*1440+_space.minute


func _body(account: String) -> String:
	return _courier if _businesses.has(account) else _shopper if account=="visitors" else account


func _record(action: String, actor: String, target: String, success: bool, details: Dictionary) -> void:
	var _profile_scope=ExecutionProfile.scope("logging") if ExecutionProfile.enabled else null
	details=details.duplicate(true)
	var physical: String=_completing if not _completing.is_empty() else _external_consumer if not _external_consumer.is_empty() else _body(actor)
	if success and action=="purchase" and _businesses.has(actor):
		details["custody"]={"business":actor,"holder":_courier}
	if success and action=="purchase" and actor=="visitors":
		_space.presences[_shopper].purchased=true
		_space.presences[_shopper].loaf+=details.quantity
	if success and action=="consume" and actor=="visitors":
		_space.presences[_external_consumer].loaf-=details.amount
	if action=="contract_day_closed":
		for parcel in _cargo.values():
			for item in ITEMS: details.goods[item]+=parcel.inventory[item]
	super(action,actor,target,success,details)
	_events.back()["minute"]=_space.minute
	_events.back()["absolute_minute"]=_absolute()
	_events.back()["physical_actor"]=physical if _space.presences.has(physical) else ""

	_on_recorded_event(_events.back())


func _on_recorded_event(_event: Dictionary) -> void:
	pass


func _revise_market_quote(owner: String, business: String, item: String, price: Variant, active: Variant=true, limit: Variant=MAX_AMOUNT) -> bool:
	return super.revise_quote(owner,business,item,price,active,limit)


func _valid_tile(tile: Variant) -> bool:
	return tile is Array and tile.size()==2 and tile[0] is int and tile[1] is int and tile[0]>=0 and tile[0]<10 and tile[1]>=0 and tile[1]<7


func _available(id: String) -> bool:
	return _space.presences.has(id) and _space.presences[id].active and _space.presences[id].activity=="idle"


func _at(id: String, tile: Array) -> bool:
	return _space.presences.has(id) and _space.presences[id].active and _space.presences[id].tile==tile


func _witnesses(tile: Array) -> Array:
	var ids: Array=_space.presences.keys()
	ids.sort()
	return ids.filter(func(id):return _at(id,tile))


func _encounter(id: String, seller: String, kind: String, item: String="", quantity: int=0) -> void:
	var tile: Array=_space.presences[id].tile
	_record("spatial_encounter",id,seller,true,{"kind":kind,"item":item,"quantity":quantity,"tile":tile.duplicate(),"witnesses":_witnesses(tile)})


func advance_day() -> void:
	if not (_day==0 or (_space.minute==1440 and _contract_day_closed)):
		_reject("spatial_day_advanced","world","",{},"unfinished_spatial_day")
		return
	_space.minute=0
	super()


func depart(id: String, destination: Variant, arrive_by: Variant=1440) -> bool:
	var reason: String=""
	if not _valid_tile(destination) or not arrive_by is int or arrive_by<0 or arrive_by>1440 or arrive_by%5!=0:
		reason="invalid_route_or_deadline"
	elif _day==0 or not _available(id):
		reason="unavailable_presence"
	var route: Array=[]
	if reason.is_empty():
		route=Town.route(_space.presences[id].tile,destination)
		if _space.minute+route.size()*5>arrive_by: reason="insufficient_travel_time"
	if not reason.is_empty(): return _reject("spatial_departed",id,"",{},reason)
	if route.is_empty():
		_record("spatial_stayed",id,"",true,{"tile":destination.duplicate()})
		return true
	var p: Dictionary=_space.presences[id]
	p.destination=destination.duplicate()
	p.route=route
	p.activity="walking"
	p.until=0
	p.last_step=_absolute()
	_record("spatial_departed",id,"",true,{"destination":destination.duplicate(),"route":route.duplicate(true),"arrive_by":arrive_by})
	return true


func move_step(id: String, tile: Variant) -> bool:
	var _profile_scope=ExecutionProfile.scope("spatial") if ExecutionProfile.enabled else null
	if not _valid_tile(tile) or not _space.presences.has(id):
		return _reject("spatial_moved",id,"",{},"invalid_step")
	var p: Dictionary=_space.presences[id]
	if not p.active or p.activity!="walking" or p.route.is_empty() or p.route[0]!=tile or p.last_step>_absolute()-5:
		return _reject("spatial_moved",id,"",{},"no_step_budget_or_wrong_route")
	var distance: int=absi(tile[0]-p.tile[0])+absi(tile[1]-p.tile[1])
	if distance!=1: return _reject("spatial_moved",id,"",{},"non_adjacent_step")
	var before: Array=p.tile.duplicate()
	p.tile=tile.duplicate()
	p.route.pop_front()
	p.last_step=_absolute()
	_record("spatial_moved",id,"",true,{"from":before,"to":tile.duplicate()})
	if p.route.is_empty():
		p.activity="idle"
		_record("spatial_arrived",id,"",true,{"tile":p.tile.duplicate()})
		for business in Town.SITES:
			if Town.SITES[business]==p.tile: _encounter(id,business,"arrived")
	return true


func advance_time(target: Variant) -> bool:
	var _profile_scope=ExecutionProfile.scope("spatial") if ExecutionProfile.enabled else null
	if _day==0 or not target is int or target<_space.minute or target>1440 or target%5!=0:
		return _reject("spatial_clock", "world","",{},"invalid_clock_target")
	while _space.minute<target:
		var before: int=_space.minute
		_space.minute+=5
		_record("spatial_clock","world","",true,{"from":before,"to":_space.minute})
		var ids: Array=_space.presences.keys()
		ids.sort()
		for id in ids:
			var p: Dictionary=_space.presences[id]
			if p.active and p.activity=="walking":
				var moved: bool=move_step(id,p.route[0])
				assert(moved)
		for id in ids:
			var p: Dictionary=_space.presences[id]
			if p.active and p.activity not in ["idle","walking"] and p.until==_space.minute:
				var result: Variant=null
				if p.activity=="work":
					_completing=id
					work_shift(id,p.business)
					_completing=""
					result=_events.back().id
				var kind: String=p.activity
				p.activity="idle"
				p.until=0
				p.business=""
				_record("spatial_activity_ended",id,"",true,{"kind":kind,"result_event_id":result})
		if _space.minute==_space.retail_close:
			_record("spatial_shop_closed","world","bakery",true,{"tile":Town.SITES.bakery.duplicate()})
	return true


func _begin(id: String, kind: String, duration: int, business: String="") -> bool:
	if _day==0 or not _available(id) or duration<=0 or _space.minute+duration>1440:
		return _reject("spatial_activity_started",id,business,{},"overlapping_or_invalid_appointment")
	var p: Dictionary=_space.presences[id]
	p.activity=kind
	p.until=_space.minute+duration
	p.business=business
	_record("spatial_activity_started",id,business,true,{"kind":kind,"until":p.until,"duration":duration})
	return true


func _shift_error(worker: String, business: String) -> String:
	var reason: String=super(worker,business)
	if not reason.is_empty(): return reason
	if not _at(worker,Town.SITES[business]): return "worker_not_at_workplace"
	if not _available(worker) and _completing!=worker: return "worker_busy"
	return ""


func start_shift(worker: String, business: String) -> bool:
	if not Town.WINDOWS.has(business) or not _available(worker) or not _at(worker,Town.SITES[business]):
		return _reject("spatial_shift_started",worker,business,{},"absent_or_busy_worker")
	if _space.minute!=Town.WINDOWS[business][0]:
		return _reject("spatial_shift_started",worker,business,{},"outside_shift_start")
	var active: int=_space.presences.values().filter(func(p):return p.active and p.activity=="work" and p.business==business).size()
	if active+_business_labor.get(business,0)>=_asset_capacity(business):
		return _reject("spatial_shift_started",worker,business,{},"workplace_capacity")
	if not offer_shift(_businesses[business].owner,business,worker): return false
	return _begin(worker,"work",60,business)


func work_shift(worker: String, business: String) -> bool:
	if _completing!=worker or not _space.presences.has(worker) or _space.presences[worker].activity!="work" or _space.presences[worker].until!=_space.minute:
		return _reject("work_shift",worker,business,{"wage":0},"completed_spatial_shift_required")
	return super(worker,business)


func owner_work_shift(owner: String, business: String) -> bool:
	return _reject("owner_work_shift",owner,business,{"wage":0},"fixed_employee_spatial_schedule")


func manage(owner: String, business: String) -> bool:
	if not _businesses.has(business) or _businesses[business].owner!=owner or not _at(owner,Town.SITES[business]) or _space.minute!=Town.WINDOWS[business][0]:
		return _reject("spatial_management",owner,business,{},"invalid_management_appointment")
	return _begin(owner,"manage",60,business)


func _open(seller: String) -> bool:
	if not Town.TRADE.has(seller): return false
	var end: int=_space.retail_close if seller=="bakery" else Town.TRADE[seller][1]
	return _space.minute>=Town.TRADE[seller][0] and _space.minute<end


func inspect_offers(id: String, seller: String) -> Dictionary:
	if not Town.SITES.has(seller) or not _at(id,Town.SITES[seller]) or not _available(id) or not _open(seller):
		_reject("spatial_inspection",id,seller,{},"not_available_at_open_seller")
		return {"success":false,"offers":[]}
	var offers: Array=public_quotes().filter(func(q):return q.seller==seller)
	_encounter(id,seller,"inspected")
	return {"success":true,"offers":offers}


func buyer_observation(buyer: String, item: String, requested: int) -> Dictionary:
	var o: Dictionary=super(buyer,item,requested)
	var id: String=_body(buyer)
	o.offers=o.offers.filter(func(q):return _at(id,Town.SITES[q.seller]) and _open(q.seller))
	return o


func purchase_quote(buyer: String, supplied: Variant, quantity: Variant) -> bool:
	var _profile_scope=ExecutionProfile.scope("transactions") if ExecutionProfile.enabled else null
	var seller: String=supplied.get("seller","") if supplied is Dictionary and supplied.get("seller") is String else ""
	var id: String=_body(buyer)
	var reason: String=""
	if not _space.presences.has(id) or not Town.SITES.has(seller) or not _at(id,Town.SITES[seller]): reason="buyer_not_at_seller"
	elif not _open(seller): reason="seller_closed"
	elif _businesses.has(buyer) and (_businesses[buyer].owner!=id or _courier!=id): reason="unauthorized_courier"
	elif id!=_shopper and id!=_courier: reason="physical_interaction_required"
	elif _space.presences[id].activity not in ["shop","procure"]: reason="buyer_busy"
	elif buyer=="visitors" and (_space.presences[id].kind!="visitor" or _space.presences[id].purchased or quantity!=1): reason="visitor_request_used_or_invalid"
	if reason.is_empty() and _businesses.has(buyer) and supplied.get("item") in ITEMS and quantity is int and quantity>0 and quantity<=MAX_AMOUNT:
		var item: String=supplied.item
		if _entities[buyer].inventory[item]+_cargo[buyer].inventory[item]+quantity>MAX_AMOUNT: reason="owned_inventory_limit"
	if not reason.is_empty():
		return _reject("purchase",buyer,seller,{"item":supplied.get("item","") if supplied is Dictionary else "","quantity":quantity,"unit_price":supplied.get("unit_price",0) if supplied is Dictionary else 0},reason)
	return super(buyer,supplied,quantity)


func _purchase_inventory(buyer: String) -> Dictionary:
	return _cargo[buyer].inventory if _businesses.has(buyer) else super(buyer)


func procure(owner: String, business: String, seller: String, item: String) -> bool:
	if not _businesses.has(business) or _businesses[business].owner!=owner or not _cargo.has(business) or _cargo[business].holder!=owner:
		return _reject("spatial_procurement",owner,business,{},"unauthorized_courier")
	if Config.INDUSTRIES[_businesses[business].industry].input!=item or not inspect_offers(owner,seller).success:
		return false
	if not _begin(owner,"procure",5,business): return false
	_courier=owner
	var bought: int=0
	for _lot in 3: bought+=buy_from_market(business,item,4)
	_courier=""
	_encounter(owner,seller,"purchased" if bought>0 else "declined",item,bought)
	return true


func deposit(owner: String, business: String) -> bool:
	var _profile_scope=ExecutionProfile.scope("spatial") if ExecutionProfile.enabled else null
	var reason: String=""
	if not _cargo.has(business) or _cargo[business].holder!=owner or _businesses[business].owner!=owner: reason="unauthorized_courier"
	elif not _at(owner,Town.SITES[business]) or not _available(owner): reason="not_available_at_warehouse"
	elif _cargo[business].inventory.values().all(func(q):return q==0): reason="empty_cargo"
	if reason.is_empty():
		for item in ITEMS:
			if _entities[business].inventory[item]>MAX_AMOUNT-_cargo[business].inventory[item]: reason="warehouse_limit"
	if not reason.is_empty(): return _reject("spatial_deposited",owner,business,{},reason)
	var goods: Dictionary=_cargo[business].inventory.duplicate()
	if not _begin(owner,"deposit",5,business): return false
	for item in ITEMS:
		_entities[business].inventory[item]+=goods[item]
		_cargo[business].inventory[item]=0
	_record("spatial_deposited",owner,business,true,{"goods":goods})
	return true


func shop(id: String) -> bool:
	if not _space.presences.has(id) or not _at(id,Town.SITES.bakery) or not _available(id) or not _open("bakery"):
		_reject("spatial_shopping",id,"bakery",{},"not_available_at_open_shop")
		if _at(id,Town.SITES.bakery): _encounter(id,"bakery","closed_attempt" if not _open("bakery") else "busy_attempt")
		return false
	var p: Dictionary=_space.presences[id]
	if p.kind=="visitor" and p.purchased:
		return _reject("spatial_shopping",id,"bakery",{},"visitor_request_already_fulfilled")
	inspect_offers(id,"bakery")
	_begin(id,"shop",5,"bakery")
	_shopper=id
	var bought: int=buy_from_market(p.account,"bread",1)
	_shopper=""
	_encounter(id,"bakery","purchased" if bought==1 else "declined","bread",bought)
	return true


func enter_visitor(slot: Variant) -> bool:
	if _day==0 or _space.minute!=1020 or not slot is int or slot<1 or slot>6:
		return _reject("spatial_visitor_entered","visitors","",{},"invalid_visitor_request")
	var id: String="visitor:%04d:%d"%[_day,slot]
	if _space.presences.has(id): return _reject("spatial_visitor_entered",id,"",{},"duplicate_visitor_request")
	var p={"id":id,"kind":"visitor","account":"visitors","active":true,"home":Town.GATE.duplicate(),"tile":Town.GATE.duplicate(),
		"destination":Town.GATE.duplicate(),"activity":"idle","until":0,"business":"","route":[],"last_step":_absolute()-5,
		"schedule":{"entry":1020,"shop":1025,"consume":1030,"exit":1035},"purchased":false,"loaf":0}
	_space.presences[id]=p
	_record("spatial_visitor_entered",id,"",true,{"presence":p.duplicate(true),"slot":slot,"account":"visitors"})
	return true


func consume_visitor(id: String) -> bool:
	if not _available(id) or _space.presences[id].kind!="visitor" or not _at(id,Town.SITES.bakery) or _space.presences[id].loaf!=1:
		return _reject("spatial_visitor_meal",id,"",{},"no_available_owned_loaf")
	_external_consumer=id
	var result: bool=_consume_account_goods("visitors",1)
	_external_consumer=""
	return result


func exit_visitor(id: String) -> bool:
	if not _available(id) or _space.presences[id].kind!="visitor" or not _at(id,Town.GATE) or _space.presences[id].loaf!=0:
		return _reject("spatial_visitor_exited",id,"",{},"not_available_empty_at_gate")
	_space.presences[id].active=false
	_record("spatial_visitor_exited",id,"",true,{"tile":Town.GATE.duplicate()})
	return true


func consume_external(actor: String) -> bool:
	return _reject("external_consumption",actor,"",{},"individual_visitor_required")


func consume(actor: String, amount: Variant=1) -> bool:
	if actor=="visitors" or (_space.presences.has(actor) and _space.presences[actor].kind=="visitor"):
		return _reject("spatial_visitor_meal",actor,"",{},"individual_visitor_required")
	if not _space.presences.has(actor) or not _available(actor) or not _at(actor,_space.presences[actor].home) or _space.minute<1110 or _space.minute>=1140:
		return _reject("consume",actor,"",{"amount":amount,"item":"bread"},"not_available_at_home_mealtime")
	return super(actor,amount)


func rest(actor: String) -> bool:
	if not _space.presences.has(actor) or _space.presences[actor].kind!="resident" or not _at(actor,_space.presences[actor].home) or _space.minute<1110:
		return _reject("spatial_rest",actor,"",{},"not_home_at_night")
	return _begin(actor,"rest",1440-_space.minute)


func revise_quote(owner: String, business: String, item: String, price: Variant, active: Variant=true, limit: Variant=MAX_AMOUNT) -> bool:
	return _reject("quote_revised",owner,business,{"item":item,"price":price},"fixed_spatial_prices")


func witnessed_encounters(observer: String) -> Array:
	var result: Array=[]
	for e in _events:
		if e.action=="spatial_encounter" and observer in e.details.witnesses:
			result.append({"day":e.day,"minute":e.minute,"presence":e.actor,"seller":e.target,"kind":e.details.kind,
				"item":e.details.item,"quantity":e.details.quantity,"tile":e.details.tile.duplicate(),"witnesses":e.details.witnesses.duplicate()})
	return result


func observe(actor: String, _business: String="") -> Dictionary:
	assert(_entities.has(actor) and _entities[actor].kind=="resident")
	var p: Dictionary=_space.presences[actor]
	return {"self":_entities[actor].duplicate(true),"spatial":p.duplicate(true),"minute":_space.minute,
		"nearby":_witnesses(p.tile),"offers":public_quotes().filter(func(q):return _at(actor,Town.SITES[q.seller]) and _open(q.seller)),
		"local_jobs":job_board(actor),"encounters":witnessed_encounters(actor)}
