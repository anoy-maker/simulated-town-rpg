extends RefCounted
## Bounded direct asks and tiny firm portfolios. No authority reference.
const Basket=preload("res://scripts/sim/brewery_policy.gd")
const WageForecast=preload("res://scripts/sim/wage_projection.gd")
const ARMS=["fixed10_instrumented","worker_bids"]

static func _budget(o: Dictionary,wage: int) -> Dictionary:
	var cash: int=o.money;var goods: Dictionary=o.inventory.duplicate();var prelude: Dictionary={};var rows: Array=[];var benefit: int=0
	for day in range(4):
		if day>0:cash+=wage
		var bread: int=int(day>0 or not o.bread_eaten);var ale: int=int(day>0 or not o.ale_drunk)
		var held_bread: int=mini(bread,goods.get("bread",0));var held_ale: int=mini(ale,goods.get("ale",0))
		var prices: Dictionary={};var stock: Dictionary={}
		for item in ["bread","ale"]:
			if o.quotes.has(item):prices[item]=o.quotes[item].quote.unit_price;stock[item]=1
		var basket: Dictionary=Basket.basket({"money":cash,"need_bread":bread-held_bread,"need_ale":ale-held_ale,"prices":prices,"stock":stock,"bread_ceiling":1000000000})
		goods.bread=goods.get("bread",0)-held_bread;goods.ale=goods.get("ale",0)-held_ale
		cash=basket.remaining
		var row={"offset":day,"wage_before_shopping":wage if day>0 else 0,"basket":basket,"held_bread":held_bread,"held_ale":held_ale,"closing_cash":cash,"availability":"assumed_for_affordability_only"}
		if day==0:prelude=row
		else:rows.append(row);benefit+=100*(held_bread+basket.bread)+5*(held_ale+basket.ale)
	return {"wage":wage,"prelude":prelude,"days":rows,"utility":benefit+cash,"terminal_cash":cash}

static func worker(o: Dictionary) -> Dictionary:
	var reason: String="binding_term_active" if not o.eligible else "unknown_bread_quote" if not o.quotes.has("bread") else "no_observed_positive_vacancy"
	var result={"action":"abstain","notice":"","wage":0,"reason":reason,"baseline":{},"budgets":[],"candidates":[],"score":{"numerator":0,"denominator":1}}
	if not o.eligible or not o.quotes.has("bread") or o.notices.is_empty():return result
	var baseline: Dictionary=_budget(o,0);var budgets: Array=[]
	for wage in range(1,21):budgets.append(_budget(o,wage))
	result.baseline=baseline;result.budgets=budgets
	for notice in o.notices:
		if not notice.active or notice.vacancies<1:continue
		for wage in range(1,21):
			var alpha: int=2 if wage<=o.anchor.wage else 1;var beta: int=1 if wage<=o.anchor.wage else 4
			var wins: int=0;var losses: int=0;var ids: Array=[]
			for h in o.history:
				if h.business!=notice.business or h.context!=notice.context or h.wage!=wage:continue
				wins+=int(h.outcome=="hired");losses+=int(h.outcome=="lost_filled");ids.append(h.observation_event_id)
			var gain: int=budgets[wage-1].utility-baseline.utility
			var score={"numerator":(alpha+wins)*gain,"denominator":alpha+beta+wins+losses}
			result.candidates.append({"notice":notice.id,"business":notice.business,"wage":wage,"alpha":alpha,"beta":beta,"wins":wins,"losses":losses,"source_ids":ids,"p_num":alpha+wins,"p_den":score.denominator,"gain":gain,"score":score,"budget_index":wage-1})
			var better: bool=score.numerator*result.score.denominator>result.score.numerator*score.denominator
			var tied: bool=score.numerator*result.score.denominator==result.score.numerator*score.denominator
			if score.numerator>0 and (better or (tied and (wage>result.wage or (wage==result.wage and notice.id<result.notice)))):
				result.action="bid";result.notice=notice.id;result.wage=wage;result.score=score;result.reason="best_positive_belief_weighted_private_utility"
	return result

static func acceptance(o: Dictionary,offer: Dictionary,request: Dictionary) -> Dictionary:
	var reason: String="binding_term_active" if not o.eligible else "request_terms_mismatch" if offer.bid!=request.id or offer.terms.wage!=request.wage else "unknown_bread_quote" if not o.quotes.has("bread") else "positive_actual_offer_utility"
	var gain: int=0
	if reason=="positive_actual_offer_utility":gain=_budget(o,request.wage).utility-_budget(o,0).utility
	return {"accepts":gain>0,"gain":gain,"reason":reason if gain>0 or reason!="positive_actual_offer_utility" else "nonpositive_actual_offer_utility"}

static func _subsets(rows: Array,limit: int,start: int,current: Array,all_rows: Array) -> void:
	all_rows.append(current.duplicate())
	if current.size()==limit:return
	for i in range(start,rows.size()):
		current.append(rows[i]);_subsets(rows,limit,i+1,current,all_rows);current.pop_back()

static func evaluate(o: Dictionary,retained: Array,asks: Array) -> Dictionary:
	var salaries: Array=retained.map(func(w):return w.wage)+asks.map(func(w):return w.wage)
	var p: Dictionary=WageForecast.project(o,salaries)
	var front: int=o.arrears+p.days[0].input_cost+salaries.reduce(func(n,w):return n+w,0)
	return {"ids":asks.map(func(w):return w.id),"salaries":salaries,"projection":p,"front_cost":front,"front_funded":o.production.cash>=front,"incumbents":asks.filter(func(w):return w.incumbent).size()}

static func select(o: Dictionary,retained: Array,bidders: Array) -> Dictionary:
	assert(retained.size()<=o.capacity and bidders.size()<=11)
	var ordered: Array=bidders.duplicate(true);ordered.sort_custom(func(a,b):return a.id<b.id)
	var subsets: Array=[];_subsets(ordered,0 if o.disabled else o.capacity-retained.size(),0,[],subsets)
	var candidates: Array=[];var lookup: Dictionary={};var base: Dictionary=evaluate(o,retained,[]);var best: Dictionary=base
	for rows in subsets:
		var row: Dictionary=evaluate(o,retained,rows);candidates.append(row);lookup[JSON.stringify(row.ids)]=row
	for row in candidates:
		if row.ids.is_empty() or not row.front_funded or not row.projection.summary.feasible or row.projection.summary.contribution<=base.projection.summary.contribution:continue
		var marginal: bool=true
		for id in row.ids:
			var fewer: Array=row.ids.filter(func(w):return w!=id)
			if row.projection.summary.contribution<=lookup[JSON.stringify(fewer)].projection.summary.contribution:marginal=false
		if not marginal:continue
		var value: int=row.projection.summary.contribution;var old: int=best.projection.summary.contribution
		var tied: bool=value==old and (row.incumbents>best.incumbents or (row.incumbents==best.incumbents and _lex_less(row.ids,best.ids)))
		if value>old or tied:best=row
	return {"selected":best.ids,"baseline":base,"best":best,"candidates":candidates,"reason":"strict_positive_funded_portfolio" if not best.ids.is_empty() else "no_profitable_funded_submitted_portfolio"}

static func _lex_less(a: Array,b: Array) -> bool:
	for i in mini(a.size(),b.size()):
		if a[i]!=b[i]:return a[i]<b[i]
	return a.size()<b.size()
