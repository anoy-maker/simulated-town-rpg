extends RefCounted
const ExecutionProfile=preload("res://scripts/sim/execution_profile.gd")
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
const Finance=preload("res://scripts/sim/bakery_finance.gd")

static func candidates(current: int, posted: Array) -> Array:
	var out: Array=[current]
	for p in posted+[maxi(1,current-1),mini(12,current+1)]:
		if p>=1 and p<=12 and (p<current or p==current+1) and p not in out: out.append(p)
	out.sort()
	return out

static func forecasts(b: Dictionary, prices: Array, carry: int) -> Dictionary:
	var _profile_scope=ExecutionProfile.scope("forecast") if ExecutionProfile.enabled else null
	if ExecutionProfile.enabled: ExecutionProfile.count("forecast_prices",prices.size())
	var cache: Dictionary={}
	for p in prices: cache[p]=[]
	var next=Beliefs.hazard(b)
	for t in 13:
		for p in prices: cache[p].append(Beliefs.sales(Beliefs.demand(next,p,carry),24))
		next=Beliefs.hazard(next)
	return cache

static func better(value: float, price: int, best: float, selected: int, current: int) -> bool:
	return value>best+1e-9 or (absf(value-best)<=1e-9 and (price==current or (selected!=current and price<selected)))

static func best_continuation(state: Array, current: int, prices: Array, cache: Dictionary, supply: int) -> Dictionary:
	var best=-INF
	var selected=current
	for p in prices:
		var value=Finance.continuation(state,p,cache[p],supply)
		if better(value,p,best,selected,current):
			best=value
			selected=p
	return {"price":selected,"value":best}

static func decide(o: Dictionary, b: Dictionary, stage: String) -> Dictionary:
	var _profile_scope=ExecutionProfile.scope("price_search") if ExecutionProfile.enabled else null
	var prices=candidates(o.current_price,o.posted)
	var operated=Finance.operate(o.state,false)
	var stock: int=int(operated.state[2])
	var rows: Array=[]
	var selected: int=o.current_price
	var maximum=-INF
	for p in prices:
		if ExecutionProfile.enabled: ExecutionProfile.count("candidates")
		var next_prices=candidates(p,o.posted+[p])
		var frozen=forecasts(b,next_prices,o.carry)
		var ordinary=0.0
		var informed=0.0
		var branches: Array=[]
		var local=Beliefs.quadrature(Beliefs.outcomes(b,"local",p,stock,o.carry,o.minimum[0]))
		for l in local:
			var visitors=Beliefs.quadrature(Beliefs.outcomes(b,"visitor",p,stock-l.sales,0,o.minimum[1]))
			for v in visitors:
				if ExecutionProfile.enabled: ExecutionProfile.count("observable_branches")
				var probability: float=l.probability*v.probability
				var closing=Finance.close(operated.state,p,l.sales+v.sales)
				var old=best_continuation(closing.state,p,next_prices,frozen,o.supply)
				var posterior=Beliefs.update(b,{"local":l,"visitor":v},p,true)
				var updated=forecasts(posterior,next_prices,o.carry)
				var unadapted=Finance.continuation(closing.state,old.price,updated[old.price],o.supply)
				var adapted=best_continuation(closing.state,p,next_prices,updated,o.supply) if stage=="D" else {"price":old.price,"value":unadapted}
				ordinary+=probability*(closing.payout+0.99*unadapted)
				informed+=probability*(closing.payout+0.99*adapted.value)
				branches.append({"local":l,"visitor":v,"probability":probability,"state":closing.state,
					"payout":closing.payout,"frozen_price":old.price,"adaptive_price":adapted.price,
					"unadapted_value":unadapted,"adaptive_value":adapted.value})
		var value: float=informed if stage=="D" else ordinary
		rows.append({"price":p,"ordinary":ordinary,"informed":informed,"evsi":maxf(0.0,informed-ordinary),
			"sales_pmf":Beliefs.sales(Beliefs.demand(b,p,o.carry,o.minimum),stock),"branches":branches})
		if better(value,p,maximum,selected,o.current_price):
			maximum=value
			selected=p
	return {"selected_price":selected,"candidates":rows,"today":operated,"information_evaluated":stage=="D","reason":"one_step_evsi" if stage=="D" else "financial_continuation"}
