extends RefCounted
## Post-run observer only; daily results never enter pricing decisions.


static func build(history: Array, final: Dictionary, stage: String) -> Dictionary:
	var initial: Dictionary = history[0].details.state
	var people: Dictionary = initial.entities.duplicate(true)
	var quotes: Dictionary = initial.commodity_quotes.duplicate(true)
	var rows: Array = []
	var days: Array = []
	var current: Dictionary = {}
	var day: Dictionary = {}
	var price_changes: Dictionary = {}
	for business in initial.businesses: price_changes[business]=0
	for e in history:
		var d: Dictionary = e.details
		if e.action == "day_started":
			current.clear()
			day = {"day":e.day,"resident_purchases":0,"resident_meals":0,"missed_meals":0,"visitor_purchases":0,"visitor_unfilled_requests":0,"purchase_rejections":0,"contract_breaches":0}
			for business in initial.businesses:
				var item: String = {"farmer":"wheat","miller":"flour","baker":"bread"}[initial.businesses[business].industry]
				current[business] = {"day":e.day,"business":business,"commodity":item,"posted_price":quotes[business][item].unit_price,
					"price_changed":false,"candidates":[],"recent_demand":0,"forecast_selected":0,"sold":0,"revenue":0,"stockout_requests":0,
					"produced":0,"input_quantity":0,"input_expenditure":0,"payroll":0,"distributions":0,"operating_cash":0,"cash":0,"inventory":{},"contract_breaches":0}
		if e.action == "pricing_decision":
			var row: Dictionary = current[e.target]
			row.candidates = d.proposal.candidates.duplicate(true)
			row.recent_demand = d.observation.reference_demand
			for candidate in row.candidates:
				if candidate.price == d.proposal.selected_price: row.forecast_selected=candidate.demand
		if e.action == "purchase" and not e.success:
			day.purchase_rejections += 1
			if current.has(e.target) and d.get("reason")=="insufficient_stock": current[e.target].stockout_requests += d.quantity
		if e.action=="market_unmet" and e.actor=="visitors": day.visitor_unfilled_requests += d.quantity
		if e.action=="consume" and not e.success and initial.entities.get(e.actor,{}).get("kind")=="resident": day.missed_meals += 1
		if e.action=="contract_shift" and not e.success:
			day.contract_breaches += 1
			current[e.target].contract_breaches += 1
		if not e.success: continue
		match e.action:
			"quote_revised":
				quotes[e.target][d.quote.item]=d.quote.duplicate(true)
				current[e.target].posted_price=d.quote.unit_price
				current[e.target].price_changed=true
				price_changes[e.target]+=1
			"purchase":
				people[e.actor].money-=d.total_price
				people[e.target].money+=d.total_price
				people[e.actor].inventory[d.item]+=d.quantity
				people[e.target].inventory[d.item]-=d.quantity
				current[e.target].sold+=d.quantity
				current[e.target].revenue+=d.total_price
				if current.has(e.actor):
					current[e.actor].input_quantity+=d.quantity
					current[e.actor].input_expenditure+=d.total_price
				elif people[e.actor].kind=="resident": day.resident_purchases+=d.quantity
				elif e.actor=="visitors": day.visitor_purchases+=d.quantity
			"transfer_money":
				people[e.actor].money-=d.amount
				people[e.target].money+=d.amount
				if current.has(e.actor):
					if d.purpose=="wage": current[e.actor].payroll+=d.amount
					elif d.purpose=="distribution": current[e.actor].distributions+=d.amount
			"harvest":
				people[e.actor].inventory.wheat+=d.amount
				current[e.actor].produced+=d.amount
			"produce":
				for item in d.inputs: people[e.actor].inventory[item]-=d.inputs[item]
				for item in d.outputs:
					people[e.actor].inventory[item]+=d.outputs[item]
					current[e.actor].produced+=d.outputs[item]
			"consume":
				people[e.actor].inventory.bread-=d.amount
				if people[e.actor].kind=="resident": day.resident_meals+=d.amount
			"contract_day_closed":
				day["resident_cash"]={}
				day["village_money"]=0
				day["external_money"]=0
				for id in people:
					if people[id].kind=="external": day.external_money+=people[id].money
					else: day.village_money+=people[id].money
					if people[id].kind=="resident": day.resident_cash[id]=people[id].money
				for business in current:
					var row: Dictionary = current[business]
					row.cash=people[business].money
					row.inventory=people[business].inventory.duplicate(true)
					row.operating_cash=row.revenue-row.input_expenditure-row.payroll
					rows.append(row.duplicate(true))
				days.append(day.duplicate(true))
	return {"stage":stage,"business_days":rows,"days":days,"price_changes":price_changes,
		"forecast_scope":"conditional one-period operating cash; fixed production/payroll, subjective sensitivity=1",
		"report_reconciles":people==final.entities}
