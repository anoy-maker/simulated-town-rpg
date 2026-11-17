extends RefCounted
const Base=preload("res://scripts/sim/brewery_policy.gd")
static func within(o: Dictionary) -> Dictionary:
	var projected: Dictionary=o.duplicate(true)
	projected.cash=maxi(0,o.cash-o.committed_payroll)
	for w in projected.workers:w.wage=0;w.available=w.available and w.id in o.funded_workers
	var result: Dictionary=Base.plan(projected)
	result["cost_basis"]="incremental_inputs_only_committed_wages_reserved_once"
	result["committed_payroll"]=o.committed_payroll
	return result
static func forecast(o: Dictionary, count: int) -> Dictionary:
	var stock: int=maxi(0,o.production.output_stock-o.remaining_sales)
	var cash: int=o.production.cash+o.remaining_sales*o.production.output_price-o.arrears
	var raw: int=o.production.input_stock
	var receipts: int=0;var inputs: int=0;var feasible: bool=cash>=0
	for day in 3:
		var p: Dictionary=o.production.duplicate(true)
		p.cash=maxi(0,cash-10*count);p.output_stock=stock;p.input_stock=raw;p.harvest_remaining=o.farm_cap
		p.workers=[]
		for i in count:p.workers.append({"id":"slot:%d"%i,"wage":0,"available":cash>=10*count})
		var plan: Dictionary=Base.plan(p)
		var cost: int=plan.lots*p.rule.take*p.input_price
		cash-=cost+10*count;inputs+=cost;feasible=feasible and cash>=0
		@warning_ignore("integer_division")
		stock+=plan.expected_receipts/p.output_price
		raw+=plan.lots*p.rule.take-plan.shifts*p.rule.take
		var sold: int=mini(stock,o.demand);stock-=sold;cash+=sold*p.output_price;receipts+=sold*p.output_price
	return {"headcount":count,"receipts":receipts,"inputs":inputs,"guaranteed_wages":30*count,"contribution":receipts-inputs-30*count,"feasible":feasible,"cash":cash}
static func renewal(o: Dictionary) -> Dictionary:
	var baseline: Dictionary=forecast(o,o.retained)
	var best: Dictionary=baseline;var candidates: Array=[baseline]
	var maximum: int=o.capacity
	if o.mode=="obligations_only":maximum=mini(maximum,o.retained+o.expiring.size())
	if o.disabled:maximum=o.retained
	for count in range(o.retained+1,maximum+1):
		var candidate: Dictionary=forecast(o,count);candidates.append(candidate)
		if candidate.feasible and candidate.contribution>best.contribution:best=candidate
	return {"vacancies":maxi(0,best.headcount-o.retained-o.reserved),"headcount":best.headcount,"baseline":baseline,"candidates":candidates,
		"reason":"positive_full_term_contribution" if best.headcount>o.retained else "no_profitable_new_commitment"}
static func income(o: Dictionary, business: String) -> Dictionary:
	var due: int=0;var paid: int=0
	for row in o.history:
		if row.business==business:due+=1;paid+=row.paid
	return {"numerator":paid+10,"denominator":due+2}
static func search(o: Dictionary) -> Dictionary:
	var best: Dictionary={};var score: Dictionary={}
	if o.eligible:
		for notice in o.notices:
			if not notice.active or notice.reserved+notice.filled>=notice.vacancies:continue
			if o.mode=="obligations_only" and notice.business!=o.business:continue
			var value: Dictionary=income(o,notice.business)
			var greater: bool=best.is_empty() or value.numerator*score.get("denominator",1)>score.get("numerator",0)*value.denominator
			var tied: bool=not best.is_empty() and value.numerator*score.denominator==score.numerator*value.denominator
			if greater or (tied and ((notice.business==o.business and best.business!=o.business) or ((notice.business==o.business)==(best.business==o.business) and notice.id<best.id))):best=notice;score=value
	return {"action":"apply" if not best.is_empty() else "stay","posting":best.get("id",""),"income":score,"reason":"best_observed_post_expiry_income" if not best.is_empty() else "binding_term_or_no_eligible_offer"}
