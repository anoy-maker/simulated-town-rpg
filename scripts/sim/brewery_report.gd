extends RefCounted
const Brew=preload("res://scripts/sim/brewery_config.gd")
static func _account() -> Dictionary:
	return {"wages":0,"distributions":0,"sales":0,"inputs":0,"bread_spending":0,"ale_spending":0,"meals":0,"missed_meals":0,"ale_consumed":0,"shifts":0,"shifts_due":0,"missed_shifts":0,"produced":Brew.empty_goods(),"purchased":Brew.empty_goods(),"sold":Brew.empty_goods()}
static func build(initial: Dictionary, final: Dictionary, history: Array, seed: int, condition: String) -> Dictionary:
	var accounts: Dictionary={};var balances: Dictionary={}
	for id in initial.entities:accounts[id]=_account();balances[id]=initial.entities[id].money
	var days: Array=[];var current: Dictionary={};var circulation: int=0
	var purchases={"successful":0,"rejected":0};var failures: Dictionary={}
	var totals={"produced":Brew.empty_goods(),"inputs":Brew.empty_goods(),"consumed":Brew.empty_goods()}
	var inventory: Dictionary={};var cargo: Dictionary=initial.cargo.duplicate(true)
	for id in initial.entities:inventory[id]=initial.entities[id].inventory.duplicate()
	for e in history:
		var d: Dictionary=e.details
		if e.action=="day_started":
			current={"day":e.day,"production":Brew.empty_goods(),"production_inputs":Brew.empty_goods(),"grain_allocation":{"mill":0,"brewery":0},"grain_available":0,"grain_residual":0,"resident_meals":0,"unmet_meals":0,"visitor_bread":0,"visitor_bread_declined":0,"ale_sold":0,"ale_consumed":0,"shifts_due":0,"shifts":0,"missed_shifts":0,"observed_quotes":0,"circulation":0,"firms":{},"households":{},"visitors":{},"declines":{}}
			for business in Brew.ORDER:current.firms[business]={"sales":0,"inputs":0,"wages":0,"distributions":0,"shifts":0,"shifts_due":0,"missed_shifts":0}
			for id in initial.entities:
				if initial.entities[id].kind=="resident":current.households[id]={"wages":0,"distributions":0,"bread_spending":0,"ale_spending":0,"meals":0,"missed_meals":0,"ale_consumed":0,"shifts":0,"shifts_due":0,"missed_shifts":0,"declines":{}}
		if e.action=="purchase":purchases["successful" if e.success else "rejected"]+=1
		if e.action=="consume" and d.get("item")=="bread" and initial.entities[e.actor].kind=="resident" and not e.success:
			accounts[e.actor].missed_meals+=1;current.unmet_meals+=1;current.households[e.actor].missed_meals+=1
		if not e.success:
			if e.action=="contract_shift":
				accounts[e.actor].missed_shifts+=1;accounts[e.target].missed_shifts+=1;current.households[e.actor].missed_shifts+=1;current.firms[e.target].missed_shifts+=1
			var reason: String=e.action+":"+d.get("reason","unspecified")
			failures[reason]=failures.get(reason,0)+1
			continue
		match e.action:
			"purchase":
				var qty: int=d.quantity;var cost: int=d.total_price
				balances[e.actor]-=cost;balances[e.target]+=cost;circulation+=cost;current.circulation+=cost
				accounts[e.actor].purchased[d.item]+=qty;accounts[e.target].sold[d.item]+=qty
				accounts[e.target].sales+=cost;current.firms[e.target].sales+=cost
				inventory[e.target][d.item]-=qty
				if cargo.has(e.actor):
					cargo[e.actor].inventory[d.item]+=qty
					accounts[e.actor].inputs+=cost;current.firms[e.actor].inputs+=cost
				else:
					inventory[e.actor][d.item]+=qty
					var field: String=d.item+"_spending"
					accounts[e.actor][field]+=cost
					if e.actor=="visitors":current.visitors[e.physical_actor][field]+=cost
					else:current.households[e.actor][field]+=cost
				if d.item=="bread" and e.actor=="visitors":current.visitor_bread+=qty
				if d.item=="ale":current.ale_sold+=qty
			"transfer_money":
				balances[e.actor]-=d.amount;balances[e.target]+=d.amount;circulation+=d.amount;current.circulation+=d.amount
				var field: String="wages" if d.purpose=="wage" else "distributions"
				accounts[e.target][field]+=d.amount;current.households[e.target][field]+=d.amount;current.firms[e.actor][field]+=d.amount
			"harvest","produce":
				var output: Dictionary={"wheat":d.amount} if e.action=="harvest" else d.outputs
				for item in output:
					inventory[e.actor][item]+=output[item];totals.produced[item]+=output[item];current.production[item]+=output[item];accounts[e.actor].produced[item]+=output[item]
				for item in d.get("inputs",{}):
					inventory[e.actor][item]-=d.inputs[item];totals.inputs[item]+=d.inputs[item];current.production_inputs[item]+=d.inputs[item]
			"consume":
				inventory[e.actor][d.item]-=d.amount;totals.consumed[d.item]+=d.amount
				var field: String="meals" if d.item=="bread" else "ale_consumed"
				accounts[e.actor][field]+=d.amount
				if e.actor!="visitors":current.households[e.actor][field]+=d.amount
				else:current.visitors[e.physical_actor][field]+=d.amount
				if d.item=="ale":current.ale_consumed+=d.amount
				elif e.actor!="visitors":current.resident_meals+=d.amount
			"spatial_deposited":
				for item in Brew.GOODS:inventory[e.target][item]+=d.goods[item];cargo[e.target].inventory[item]-=d.goods[item]
			"contract_due":
				current.shifts_due+=1;accounts[e.actor].shifts_due+=1;accounts[e.target].shifts_due+=1;current.households[e.actor].shifts_due+=1;current.firms[e.target].shifts_due+=1
			"work_shift":accounts[e.actor].shifts+=1;accounts[e.target].shifts+=1;current.shifts+=1;current.firms[e.target].shifts+=1;current.households[e.actor].shifts+=1
			"grain_cleared":
				current.grain_available=d.available
				current.grain_allocation={"mill":5*d.allocation.mill,"brewery":3*d.allocation.brewery}
				current.grain_residual=d.available-d.allocation.grain
			"spatial_visitor_entered":current.visitors[e.actor]={"bread_spending":0,"ale_spending":0,"meals":0,"ale_consumed":0,"declines":{}}
			"consumer_decision":
				if d.purchased==0:
					var reason: String=d.item+":"+d.proposal.reason
					current.declines[reason]=current.declines.get(reason,0)+1
					if d.item=="bread" and e.actor.begins_with("visitor:"):current.visitor_bread_declined+=1
					if e.actor.begins_with("visitor:"):current.visitors[e.actor].declines[d.item]=d.proposal.reason
					else:current.households[e.actor].declines[d.item]=d.proposal.reason
			"spatial_encounter":
				if d.kind=="inspected":current.observed_quotes+=1
			"contract_day_closed":
				current.missed_shifts=d.breaches
				for business in Brew.ORDER:
					var f: Dictionary=current.firms[business]
					f["operating_surplus"]=f.sales-f.inputs-f.wages
					f["cash"]=balances[business];f["inventory"]=inventory[business].duplicate()
				for id in current.households:
					current.households[id]["cash"]=balances[id];current.households[id]["inventory"]=inventory[id].duplicate()
				current["currency"]=balances.values().reduce(func(a,b):return a+b,0)
				current["external_cash"]=balances.visitors
				days.append(current.duplicate(true))
	for id in accounts:accounts[id]["cash"]=final.entities[id].money;accounts[id]["inventory"]=final.entities[id].inventory.duplicate()
	return {"scenario":"settlement_brewery","condition":condition,"seed":seed,"days":final.day,"initial":initial,"final":final,"prices":Brew.PRICES.duplicate(),"day_results":days,"accounts":accounts,"totals":totals,"purchases":purchases,"failures":failures,"money":{"initial":9192,"final":balances.values().reduce(func(a,b):return a+b,0),"circulation":circulation},"event_count":history.size(),"ledger_sha256":JSON.stringify(history,"",true).sha256_text()}
