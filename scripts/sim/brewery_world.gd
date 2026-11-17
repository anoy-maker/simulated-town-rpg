extends "res://scripts/sim/spatial_world.gd"
## M23 scenario authority. All exchange/payroll/production uses inherited native commands.
const Brew=preload("res://scripts/sim/brewery_config.gd")
const Policy=preload("res://scripts/sim/brewery_policy.gd")
var _experiment: String
var _starting: Dictionary
var _harvested: int=0
var _requests: Dictionary={}
var _seen: Dictionary={}
var _bought: Dictionary={}
var _drunk: Dictionary={}
var _cleared: bool=false
var _clearing: bool=false

func _init(seed_value: int=42, experiment: String="reference", initial: Dictionary={}) -> void:
	assert(experiment in Brew.CASES)
	_experiment=experiment
	_starting=Brew.initial() if initial.is_empty() else initial.duplicate(true)
	assert(_starting.entities.reduce(func(total,e):return total+e.money,0)==9192)
	super(seed_value,experiment)
func _items() -> Array:return Brew.GOODS
func _recipe_rules() -> Dictionary:return Brew.RECIPES
func _industries() -> Dictionary:return Brew.INDUSTRIES
func _initial_economy() -> Dictionary:return _starting
func _initial_space(economy: Dictionary, experiment: String) -> Dictionary:return Brew.space(economy,experiment)
func _sites() -> Dictionary:return Brew.SITES
func _windows() -> Dictionary:return Brew.WINDOWS
func _trade() -> Dictionary:return Brew.TRADE
func _initial_quote_price(item: String) -> int:return Brew.PRICES[item]
func _asset_requirements() -> Dictionary:return Brew.REQUIREMENTS
func _resident_count() -> int:return 15
func _valid_entity_role(entity: Dictionary) -> bool:
	return entity.role in Brew.INDUSTRIES or entity.role=="laborer" or (entity.kind=="external" and entity.role=="account")
func _validate_initial_contracts(initial: Dictionary) -> void:
	for job in initial.employment.values():
		assert(job.wage==10 and job.contract=={"cycle_days":1,"shifts_per_cycle":1,"cycle_compensation":10,"phases":[1]})
func _harvest_opportunity() -> int:return 7
func _harvest_quantity(_worker: String) -> int:return mini(7,Brew.CASES[_experiment]-_harvested)
func _productive_shift_error(worker: String, business: String, wage: int) -> String:
	if business=="farm" and _harvest_quantity(worker)<=0:return "no_harvest_capacity"
	return super(worker,business,wage)
func advance_day() -> void:
	if _day>0 and (_space.minute!=1440 or not _contract_day_closed):
		super()
		return
	_harvested=0;_requests.clear();_seen.clear();_bought.clear();_drunk.clear();_cleared=false
	super()
func snapshot() -> Dictionary:
	return super().merged({"brewery":{"case":_experiment,"supply_cap":Brew.CASES[_experiment],"harvested_today":_harvested,"requests":_requests.duplicate(true),"cleared":_cleared,"bought":_bought.duplicate(true),"drunk":_drunk.duplicate()}})
func _on_recorded_event(e: Dictionary) -> void:
	if not e.success:return
	if e.action=="harvest":_harvested+=e.details.amount
	if e.action=="purchase" and _entities[e.actor].kind=="resident":
		var key: String=e.actor+":"+e.details.item
		_bought[key]=_bought.get(key,0)+e.details.quantity
func inspect_offers(id: String, seller: String) -> Dictionary:
	var result: Dictionary=super(id,seller)
	if result.success:_seen[id+":"+seller]={"day":_day,"minute":_space.minute,"offers":result.offers.duplicate(true)}
	return result
func _observed(id: String, q: Dictionary) -> bool:
	var seen: Dictionary=_seen.get(id+":"+str(q.get("seller","")),{})
	if seen.is_empty() or seen.day!=_day or seen.minute!=_space.minute:return false
	return seen.offers.any(func(o):return o==q)
func _current_quote(q: Dictionary) -> bool:
	var current: Dictionary=_quotes.get(q.get("seller",""),{}).get(q.get("item",""),{})
	return not current.is_empty() and current.active and current.keys().all(func(k):return q.has(k) and typeof(q[k])==typeof(current[k]) and q[k]==current[k])
func _workers(business: String) -> Array:
	var workers: Array=[]
	var ids: Array=_businesses[business].employees.duplicate();ids.sort()
	for id in ids:
		workers.append({"id":id,"wage":_wage(id,business),"available":_employment[id].active and _employment[id].business==business and _businesses[business].industry in _entities[id].skills and _labor_used.get(id,0)==0 and _available(id) and _at(id,_sites()[business])})
	return workers
func business_observation(owner: String, business: String, allow_procurement: bool=false) -> Dictionary:
	assert(_businesses.has(business) and _businesses[business].owner==owner)
	var f: Dictionary=_businesses[business]
	var rule: Dictionary=Brew.INDUSTRIES[f.industry]
	var known: Dictionary=_seen.get(owner+":"+("farm" if rule.input=="wheat" else "mill"),{})
	var input_quote: Dictionary={}
	if not rule.input.is_empty() and not known.is_empty():
		for q in known.offers:
			if q.item==rule.input:input_quote=q.duplicate(true)
	return {"owner":owner,"business":business,"day":_day,"rule":rule.duplicate(),"cash":_entities[business].money,
		"output_stock":_entities[business].inventory[rule.output],"input_stock":0 if rule.input.is_empty() else _entities[business].inventory[rule.input]+_cargo[business].inventory[rule.input],
		"output_price":_quotes[business][rule.output].unit_price,"input_price":input_quote.get("unit_price",0),"input_quote":input_quote,
		"allow_procurement":allow_procurement and (rule.input.is_empty() or not input_quote.is_empty()),"harvest_remaining":Brew.CASES[_experiment]-_harvested if business=="farm" else 0,"workers":_workers(business)}
func plan_business(owner: String, business: String) -> Dictionary:
	var o: Dictionary=business_observation(owner,business)
	# Production can spend only deposited inputs, not a parcel still in transit.
	var input: String=o.rule.input
	if not input.is_empty():o.input_stock=_entities[business].inventory[input]
	var plan: Dictionary=Policy.plan(o)
	_record("business_plan",owner,business,true,{"observation":o,"proposal":plan,"phase":"production"})
	return plan
func request_grain(owner: String, business: String, maximum: Variant, q: Variant) -> bool:
	var reason: String=""
	if business not in ["mill","brewery"] or _businesses[business].owner!=owner:reason="not_grain_courier"
	elif _space.minute!=610 or _cleared or _requests.has(business):reason="clearing_closed_or_duplicate"
	elif not maximum is int or maximum<0 or maximum>(3 if business=="mill" else 2):reason="invalid_whole_lots"
	elif not q is Dictionary or q.get("seller")!="farm" or q.get("item")!="wheat" or not _observed(owner,q) or not _current_quote(q):reason="unobserved_or_stale_quote"
	elif not _at(owner,_sites().farm) or not _available(owner):reason="absent_or_busy_courier"
	if not reason.is_empty():return _reject("grain_request",owner,business,{"maximum":maximum},reason)
	if not _begin(owner,"procure",5,business):return false
	_requests[business]={"owner":owner,"business":business,"maximum":maximum,"lot_size":5 if business=="mill" else 3,"quote":q.duplicate(true)}
	_record("grain_request",owner,business,true,_requests[business])
	return true
func propose_grain(owner: String, business: String) -> bool:
	var inspected: Dictionary=inspect_offers(owner,"farm")
	if not inspected.success:return false
	var o: Dictionary=business_observation(owner,business,true)
	var proposal: Dictionary=Policy.plan(o)
	if _experiment=="no_brew_request" and business=="brewery":proposal.lots=0;proposal.reason="control_no_brew_request"
	_record("business_plan",owner,business,true,{"observation":o,"proposal":proposal,"phase":"procurement"})
	return request_grain(owner,business,proposal.lots,o.input_quote)
func _request_max(business: String) -> int:
	if not _requests.has(business):return 0
	var r: Dictionary=_requests[business]
	if not _current_quote(r.quote) or not _at(r.owner,_sites().farm) or _space.presences[r.owner].activity!="procure" or _space.presences[r.owner].until!=615:
		_reject("grain_request_validated",r.owner,business,{},"changed_quote_or_presence")
		return 0
	var count: int=mini(_asset_capacity(business),_workers(business).filter(func(w):return w.available).size())
	@warning_ignore("integer_division")
	var funded: int=_entities[business].money/(r.lot_size*r.quote.unit_price+10)
	return mini(r.maximum,mini(count,funded))
func clear_grain(owner: String) -> bool:
	if owner!="ada" or not _at(owner,_sites().farm) or not _available(owner) or _space.minute!=610 or _cleared:
		return _reject("grain_cleared",owner,"farm",{},"invalid_clearing_appointment")
	var m: int=_request_max("mill");var b: int=_request_max("brewery")
	var available: int=mini(_quotes.farm.wheat.limit,_entities.farm.inventory.wheat) if _quotes.farm.wheat.active else 0
	var allocation: Dictionary=Policy.allocation(available,m,b,_quotes.farm.wheat.unit_price)
	var receipts: Array=[]
	_cleared=true;_clearing=true
	for business in ["brewery","mill"]: # Stable receipt order; never an allocation priority.
		if not _requests.has(business):continue
		var r: Dictionary=_requests[business]
		_courier=r.owner
		var bought: int=0
		for lot in allocation[business]:
			var success: bool=purchase_quote(business,r.quote,r.lot_size)
			receipts.append(_events.back().id)
			if success:bought+=r.lot_size
		_encounter(r.owner,"farm","purchased" if bought>0 else "declined","wheat",bought)
	_courier="";_clearing=false
	_record("grain_cleared",owner,"farm",true,{"available":available,"eligible":{"mill":m,"brewery":b},"allocation":allocation,"purchase_event_ids":receipts})
	return true
func purchase_quote(buyer: String, q: Variant, quantity: Variant) -> bool:
	if not q is Dictionary:return _reject("purchase",buyer,"",{},"malformed_quote")
	var body: String=_body(buyer)
	var reason: String=""
	if not _observed(body,q):reason="unobserved_quote"
	elif _businesses.has(buyer):
		var input: String=Brew.INDUSTRIES[_businesses[buyer].industry].input
		if input.is_empty() or q.get("item")!=input:reason="wrong_business_input"
		elif input=="wheat" and (not _clearing or quantity!=(5 if buyer=="mill" else 3)):reason="whole_lot_clearing_required"
		elif input=="flour" and quantity!=5:reason="whole_flour_lot_required"
	if not reason.is_empty():return _reject("purchase",buyer,q.get("seller",""),{"item":q.get("item",""),"quantity":quantity,"quote":q},reason)
	return super(buyer,q,quantity)
func procure_flour(owner: String) -> bool:
	if owner!="cora" or _space.minute!=730:return _reject("spatial_procurement",owner,"bakery",{},"invalid_flour_appointment")
	var inspected: Dictionary=inspect_offers(owner,"mill")
	if not inspected.success:return false
	var o: Dictionary=business_observation(owner,"bakery",true);var proposal: Dictionary=Policy.plan(o)
	_record("business_plan",owner,"bakery",true,{"observation":o,"proposal":proposal,"phase":"procurement"})
	if not _begin(owner,"procure",5,"bakery"):return false
	_courier=owner
	var bought: int=0
	for lot in proposal.lots:
		if purchase_quote("bakery",o.input_quote,5):bought+=5
		else:break
	_courier=""
	_encounter(owner,"mill","purchased" if bought>0 else "declined","flour",bought)
	return true
func _visitor_presence(id: String) -> Dictionary:
	var p: Dictionary=super(id)
	p.merge({"ale":0,"spent":0,"bought":{"bread":0,"ale":0},"schedule":{"entry":1020,"bread":1025,"ale":1040,"exit":1060}},true)
	return p
func _visitor_economic_event(action: String, d: Dictionary) -> void:
	var p: Dictionary=_space.presences[_shopper if action=="purchase" else _external_consumer]
	if action=="purchase":
		p.bought[d.item]+=d.quantity;p.spent+=d.total_price
		if d.item=="bread":p.purchased=true;p.loaf+=d.quantity
		else:p.ale+=d.quantity
	elif d.item=="bread":p.loaf-=d.amount
	else:p.ale-=d.amount
func _visitor_purchase_error(id: String, item: String, quantity: Variant) -> String:
	var p: Dictionary=_space.presences[id]
	return "visitor_allowance_used" if p.kind!="visitor" or item not in ["bread","ale"] or quantity!=1 or p.bought.get(item,1)>=1 else ""
func _consumer_quote_error(buyer: String, item: String, quantity: int, price: int) -> String:
	if _businesses.has(buyer):return ""
	if item not in ["bread","ale"] or quantity!=1:return "invalid_consumer_quantity"
	if buyer=="visitors":
		if _shopper.is_empty() or not _space.presences.has(_shopper):return "individual_visitor_required"
		var p: Dictionary=_space.presences[_shopper]
		if p.spent+price>10:return "visitor_budget_exhausted"
		return "reservation_price" if item=="bread" and price>6 else ""
	if item=="bread":return super(buyer,item,quantity,price)
	return "ale_allowance_used" if _bought.get(buyer+":ale",0)>=1 or _entities[buyer].inventory.ale>0 or _drunk.has(buyer) else ""
func consumer_observation(id: String, seller: String) -> Dictionary:
	var p: Dictionary=_space.presences[id]
	var visitor: bool=p.kind=="visitor"
	var offers: Array=_seen.get(id+":"+seller,{}).get("offers",[]).duplicate(true)
	var prices: Dictionary={};var stock: Dictionary={}
	for q in offers:
		if q.active:prices[q.item]=q.unit_price;stock[q.item]=q.available
	return {"buyer":id,"day":_day,"minute":_space.minute,"money":mini(10-p.spent,_entities.visitors.money) if visitor else _entities[id].money,
		"need_bread":int(p.bought.bread==0 and p.loaf==0) if visitor else int(not _meals.has(id) and _entities[id].inventory.bread==0 and _bought.get(id+":bread",0)==0),
		"need_ale":int(p.bought.ale==0) if visitor else int(not _drunk.has(id) and _bought.get(id+":ale",0)==0 and _entities[id].inventory.ale==0),
		"bread_ceiling":6 if visitor else MAX_AMOUNT,"prices":prices,"stock":stock,"offers":offers}
func shop_at(id: String, seller: String) -> bool:
	if seller not in ["bakery","brewery"] or not inspect_offers(id,seller).success:return false
	var o: Dictionary=consumer_observation(id,seller);var proposal: Dictionary=Policy.basket(o)
	if not _begin(id,"shop",5,seller):return false
	var item: String="bread" if seller=="bakery" else "ale"
	var quantity: int=proposal[item]
	var success: bool=true;var receipt: Variant=null
	_shopper=id
	if quantity>0:
		success=purchase_quote(_space.presences[id].account,o.offers[0],1)
		receipt=_events.back().id
	_shopper=""
	_record("consumer_decision",id,seller,success,{"observation":o,"proposal":proposal,"item":item,"purchased":quantity if success else 0,"command_event_id":receipt})
	_encounter(id,seller,"purchased" if success and quantity>0 else "declined",item,quantity if success else 0)
	return success
func drink_ale(id: String) -> bool:
	if not _space.presences.has(id) or not _available(id) or not _at(id,_sites().brewery) or _drunk.has(id):return _reject("discretionary_benefit",id,"brewery",{},"no_available_ale_consumer")
	var p: Dictionary=_space.presences[id]
	if (p.ale if p.kind=="visitor" else _entities[id].inventory.ale)!=1:return _reject("discretionary_benefit",id,"brewery",{},"no_owned_ale")
	_external_consumer=id if p.kind=="visitor" else ""
	var eaten: bool=_consume_item(p.account,"ale",1)
	_external_consumer=""
	if eaten:
		_drunk[id]=true
		_record("discretionary_benefit",id,"brewery",true,{"benefit":5,"consumption_event_id":_events.back().id})
	return eaten
func exit_visitor(id: String) -> bool:
	if _space.presences.has(id) and _space.presences[id].ale!=0:return _reject("spatial_visitor_exited",id,"",{},"owned_ale_remaining")
	return super(id)
func settle_profit(owner: String, business: String) -> bool:
	if _space.minute!=1140 or not _settlement_ready():return _reject("profit_distribution",owner,business,{},"settlement_not_ready")
	return super(owner,business)
