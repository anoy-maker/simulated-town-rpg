extends RefCounted
## Same policy graph as M18/M19, grouped into three numerical passes per decision.
const Policy=preload("res://scripts/sim/bakery_policy.gd")
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
const Finance=preload("res://scripts/sim/bakery_finance.gd")

static func _best(values: Array,offset: int,prices: Array,current: int) -> Dictionary:
	var best=-INF
	var selected=current
	for i in prices.size():
		if Policy.better(values[offset+i],prices[i],best,selected,current):
			best=values[offset+i]
			selected=prices[i]
	return {"price":selected,"value":best}

static func decide(o: Dictionary,b: Dictionary,stage: String,math: RefCounted) -> Dictionary:
	var prices=Policy.candidates(o.current_price,o.posted)
	var operated=Finance.operate(o.state,false)
	var stock: int=int(operated.state[2])
	var groups: Array=[]
	var forecasts: Array=[]
	# All inputs are copies of permitted observations. Policy cannot mutate world.
	for p in prices:
		var next_prices=Policy.candidates(p,o.posted+[p])
		var group={"price":p,"prices":next_prices,"frozen":forecasts.size(),"branches":[]}
		for np in next_prices: forecasts.append({"b":b,"price":np,"carry":o.carry})
		for l in Beliefs.quadrature(Beliefs.outcomes(b,"local",p,stock,o.carry,o.minimum[0])):
			for v in Beliefs.quadrature(Beliefs.outcomes(b,"visitor",p,stock-l.sales,0,o.minimum[1])):
				var closing=Finance.close(operated.state,p,l.sales+v.sales)
				var branch={"local":l,"visitor":v,"probability":l.probability*v.probability,
					"state":closing.state,"payout":closing.payout,"updated":forecasts.size()}
				var posterior=Beliefs.update(b,{"local":l,"visitor":v},p,true)
				for np in next_prices: forecasts.append({"b":posterior,"price":np,"carry":o.carry})
				group.branches.append(branch)
		groups.append(group)
	var pmfs=math.batch(1,forecasts)
	assert(math.error.is_empty(),math.error)
	var frozen_jobs: Array=[]
	for group in groups:
		for branch in group.branches:
			branch["frozen_offset"]=frozen_jobs.size()
			for i in group.prices.size(): frozen_jobs.append({"state":branch.state,"price":group.prices[i],"forecast":pmfs[group.frozen+i],"supply":o.supply})
	var frozen_values=math.batch(2,frozen_jobs)
	assert(math.error.is_empty(),math.error)
	var posterior_jobs: Array=[]
	for group in groups:
		for branch in group.branches:
			branch["old"]=_best(frozen_values,branch.frozen_offset,group.prices,group.price)
			branch["posterior_offset"]=posterior_jobs.size()
			var i: int=group.prices.find(branch.old.price)
			posterior_jobs.append({"state":branch.state,"price":branch.old.price,"forecast":pmfs[branch.updated+i],"supply":o.supply})
			if stage=="D":
				for j in group.prices.size(): posterior_jobs.append({"state":branch.state,"price":group.prices[j],"forecast":pmfs[branch.updated+j],"supply":o.supply})
	var posterior_values=math.batch(2,posterior_jobs)
	assert(math.error.is_empty(),math.error)
	var selected: int=o.current_price
	var maximum=-INF
	var rows: Array=[]
	for group in groups:
		var ordinary=0.0
		var informed=0.0
		var branches: Array=[]
		for branch in group.branches:
			var unadapted: float=posterior_values[branch.posterior_offset]
			var adapted=_best(posterior_values,branch.posterior_offset+1,group.prices,group.price) if stage=="D" else {"price":branch.old.price,"value":unadapted}
			ordinary+=branch.probability*(branch.payout+0.99*unadapted)
			informed+=branch.probability*(branch.payout+0.99*adapted.value)
			branches.append({"local":branch.local,"visitor":branch.visitor,"probability":branch.probability,"state":branch.state,
				"payout":branch.payout,"frozen_price":branch.old.price,"adaptive_price":adapted.price,
				"unadapted_value":unadapted,"adaptive_value":adapted.value})
		var p: int=group.price
		rows.append({"price":p,"ordinary":ordinary,"informed":informed,"evsi":maxf(0.0,informed-ordinary),
			"sales_pmf":Beliefs.sales(Beliefs.demand(b,p,o.carry,o.minimum),stock),"branches":branches})
		var value: float=informed if stage=="D" else ordinary
		if Policy.better(value,p,maximum,selected,o.current_price):
			maximum=value
			selected=p
	return {"selected_price":selected,"candidates":rows,"today":operated,"information_evaluated":stage=="D","reason":"one_step_evsi" if stage=="D" else "financial_continuation"}
