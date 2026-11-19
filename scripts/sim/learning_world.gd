extends "res://scripts/sim/spatial_world.gd"
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
var memory: Dictionary={}
var current: Dictionary={}
var beliefs: Dictionary={}
var _pending: Dictionary={}
var _consulted: Array=[]

func _init(seed_value: int=42, experiment: String="control") -> void:
	beliefs=Beliefs.fresh()
	super(seed_value,experiment)

func _cohort() -> Dictionary:
	return {"arrivals":0,"inspections":0,"eligible":0,"sales":0,"purchases":0,"declines":0,"stock_limited":0,"closed":0,"unresolved":0,"censored":false,"events":[]}

func begin_memory_day() -> void:
	var _profile_scope=ExecutionProfile.scope("memory") if ExecutionProfile.enabled else null
	beliefs=Beliefs.hazard(beliefs)
	_pending.clear()
	_consulted=[]
	current={}
	for business in ["farm","mill","bakery"]:
		var owner: String=_businesses[business].owner
		if not memory.has(owner): memory[owner]=[]
		current[owner]={"day":_day,"business":business,"price":_quotes[business].values()[0].unit_price,
			"local":_cohort(),"visitor":_cohort(),"coverage":0,"accounting":{"sold":0,"revenue":0,"inputs":0,"payroll":0,"distributions":0,"stockout_requests":0},"receipts":[],"public_quotes":[]}

func end_memory_day() -> void:
	var _profile_scope=ExecutionProfile.scope("memory") if ExecutionProfile.enabled else null
	for key in _pending:
		var pending: Dictionary=_pending[key]
		if pending.eligible:
			current[pending.owner][pending.cohort].unresolved+=1
	for owner in current:
		var record: Dictionary=current[owner]
		record["complete"]=record.coverage==27 if owner=="cora" else false
		record["cash"]=_entities[record.business].money
		record["inventory"]=_entities[record.business].inventory.duplicate()
		record["book"]=_cash_results[record.business].duplicate()
		memory[owner].append(record.duplicate(true))
	beliefs=Beliefs.update(beliefs,current.cora,current.cora.price,current.cora.complete)

func _on_recorded_event(e: Dictionary) -> void:
	var _profile_scope=ExecutionProfile.scope("memory") if ExecutionProfile.enabled else null
	if current.is_empty(): return
	var d: Dictionary=e.details
	if e.action=="spatial_clock" and e.minute>=900 and e.minute<1035:
		for owner in current:
			if _at(owner,Town.SITES[current[owner].business]): current[owner].coverage+=1
	if e.success and e.action in ["purchase","transfer_money"]:
		for owner in current:
			var r: Dictionary=current[owner]
			var business: String=r.business
			var accounted=false
			if e.action=="purchase":
				if e.target==business:
					r.accounting.sold+=d.quantity
					r.accounting.revenue+=d.total_price
					accounted=true
				if e.actor==business:
					r.accounting.inputs+=d.total_price
					accounted=true
			elif e.actor==business and d.purpose in ["wage","distribution"]:
				r.accounting["payroll" if d.purpose=="wage" else "distributions"]+=d.amount
				accounted=true
			if accounted: r.receipts.append(e.id)
	if not e.success and e.action=="purchase" and d.get("reason")=="insufficient_stock":
		for owner in current:
			if e.target==current[owner].business: current[owner].accounting.stockout_requests+=d.quantity
	if e.action!="spatial_encounter": return
	for owner in current:
		if owner not in d.witnesses: continue
		if e.actor==owner and d.kind=="inspected":
			var consulted: Array=public_quotes().filter(func(q):return q.seller==e.target).duplicate(true)
			current[owner].public_quotes.append({"event":e.id,"seller":e.target,"offers":consulted})
			if owner=="cora" and e.target=="mill": _consulted=consulted
		var r: Dictionary=current[owner]
		if e.target!=r.business: continue
		var cohort: String="visitor" if e.actor.begins_with("visitor:") else "local"
		var c: Dictionary=r[cohort]
		c.events.append(e.id)
		var join: String=owner+":"+e.actor
		match d.kind:
			"arrived": c.arrivals+=1
			"closed_attempt":
				c.closed+=1
				c.censored=true
			"inspected":
				c.inspections+=1
				var offer: Dictionary=public_quotes().filter(func(q):return q.seller==r.business)[0]
				var eligible: bool=offer.active and offer.available>0 and _open(r.business)
				_pending[join]={"owner":owner,"cohort":cohort,"eligible":eligible}
				if eligible: c.eligible+=1
				else:
					c.stock_limited+=1
					c.censored=true
			"purchased","declined":
				c["purchases" if d.kind=="purchased" else "declines"]+=1
				if _pending.has(join):
					if _pending[join].eligible: c.sales+=d.quantity
					_pending.erase(join)

func planning_observation(posted: Array) -> Dictionary:
	var f: Dictionary=_entities.bakery
	var book: Dictionary=_cash_results.bakery
	var present: Array=_witnesses(Town.SITES.bakery).filter(func(id):return not id.begins_with("visitor:"))
	var carry: int=maxi(0,present.size()-current.cora.local.arrivals)
	return {"day":_day,"current_price":_quotes.bakery.bread.unit_price,"posted":posted.duplicate(),
		"state":[f.money,f.inventory.flour,f.inventory.bread,book.sales-book.inputs-book.payroll-book.distributions],
		"supply":mini(12,_consulted[0].available) if not _consulted.is_empty() else 0,
		"input_price":_consulted[0].unit_price if not _consulted.is_empty() else 4,
		"carry":carry,"minimum":[current.cora.local.arrivals,current.cora.visitor.arrivals]}

func revise_quote(owner: String,business: String,item: String,price: Variant,active: Variant=true,limit: Variant=MAX_AMOUNT) -> bool:
	if owner!="cora" or business!="bakery" or item!="bread": return super(owner,business,item,price,active,limit)
	var result=_revise_market_quote(owner,business,item,price,active,limit)
	if result and current.has("cora"): current.cora.price=price
	return result
