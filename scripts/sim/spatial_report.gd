extends RefCounted
const ExecutionProfile=preload("res://scripts/sim/execution_profile.gd")
## Small day/resident projections, excluding global private encounter histories.


static func build(history: Array, final: Dictionary, experiment: String) -> Dictionary:
	var _profile_scope=ExecutionProfile.scope("spatial_report") if ExecutionProfile.enabled else null
	var days: Array=[]
	var day: Dictionary={}
	var agents: Dictionary={}
	for id in final.spatial.presences:
		if final.spatial.presences[id].kind=="resident":
			agents[id]={"id":id,"home":final.spatial.presences[id].home.duplicate(),"tile":final.spatial.presences[id].tile.duplicate(),"steps":0,"travel_minutes":0,"paid_shifts":0,"shopping_attempts":0,"meals":0}
	var witnesses: Dictionary={}
	for e in history:
		if e.action=="day_started": day={"day":e.day,"steps":0,"paid_shifts":0,"resident_meals":0,"visitor_loaves":0,"unmet_meals":0,"visitor_entries":0,"visitor_exits":0,"cargo_purchased":0,"cargo_deposited":0,"closed_attempts":0,"breaches":0}
		if e.action=="spatial_shopping" and not e.success and agents.has(e.actor): agents[e.actor].shopping_attempts+=1
		if e.action=="consume" and not e.success and agents.has(e.actor): day.unmet_meals+=1
		if e.action=="contract_shift" and not e.success: day.breaches+=1
		if not e.success: continue
		match e.action:
			"spatial_moved":
				day.steps+=1
				if agents.has(e.actor):
					agents[e.actor].steps+=1
					agents[e.actor].travel_minutes+=5
			"work_shift":
				day.paid_shifts+=1
				agents[e.actor].paid_shifts+=1
			"spatial_visitor_entered": day.visitor_entries+=1
			"spatial_visitor_exited": day.visitor_exits+=1
			"purchase":
				if e.details.has("custody"): day.cargo_purchased+=e.details.quantity
				elif e.actor=="visitors": day.visitor_loaves+=e.details.quantity
			"spatial_deposited":
				for quantity in e.details.goods.values(): day.cargo_deposited+=quantity
			"consume":
				if agents.has(e.actor):
					agents[e.actor].meals+=e.details.amount
					day.resident_meals+=e.details.amount
			"spatial_encounter":
				if e.details.kind=="inspected" and agents.has(e.actor) and e.target=="bakery": agents[e.actor].shopping_attempts+=1
				if e.details.kind=="closed_attempt": day.closed_attempts+=1
				for observer in e.details.witnesses:
					if not agents.has(observer): continue
					if not witnesses.has(observer): witnesses[observer]={}
					var key: String=e.target+":"+e.details.kind
					witnesses[observer][key]=witnesses[observer].get(key,0)+1
			"contract_day_closed":
				day["household_cash"]=e.details.household_cash.duplicate()
				day["business_cash"]=e.details.business_cash.duplicate()
				day["external_cash"]=e.details.external_cash.duplicate()
				days.append(day.duplicate(true))
	return {"case":experiment,"clock_minute":final.spatial.minute,"map":{"width":10,"height":7,"sites":{"farm":[6,1],"mill":[6,3],"bakery":[8,3]},"gate":[9,3]},
		"route_order":"x then y, five minutes per orthogonal tile; sorted simultaneous IDs","days":days,"residents":agents,"witnessed_counts":witnesses,
		"cargo_final":final.cargo.duplicate(true),"temporary_visitors":final.spatial.presences.size()-12}
