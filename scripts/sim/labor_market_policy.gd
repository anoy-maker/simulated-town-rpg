extends RefCounted
## M24 pure financial comparisons. Fixed wages in the world; rotation only on ties.
const Base=preload("res://scripts/sim/brewery_policy.gd")
static func order(workers: Array, day: int, tie: String) -> Array:
	var sorted: Array=workers.duplicate(true)
	sorted.sort_custom(func(a,b):return a.available if a.available!=b.available else a.wage<b.wage if a.wage!=b.wage else a.id<b.id)
	if tie=="legacy_sorted":return sorted
	var result: Array=[];var index: int=0
	while index<sorted.size():
		var stop: int=index+1
		while stop<sorted.size() and sorted[stop].available==sorted[index].available and sorted[stop].wage==sorted[index].wage:stop+=1
		var group: Array=sorted.slice(index,stop);var offset: int=day%group.size()
		result.append_array(group.slice(offset)+group.slice(0,offset));index=stop
	return result
static func selection(o: Dictionary, proposal: Dictionary, tie: String) -> Dictionary:
	var candidates: Array=[]
	for w in o.workers:
		candidates.append({"id":w.id,"wage":w.wage,"available":w.available,"selected":w.id in proposal.workers,
			"reason":"not_available" if not w.available else "equal_financial_return_"+tie if w.id in proposal.workers else "outside_profitable_funded_plan"})
	return {"tie":tie,"objective":"conditional_receipts_minus_missing_inputs_and_wages","candidates":candidates}
static func vacancy(o: Dictionary) -> Dictionary:
	var projected: Dictionary=o.production.duplicate(true)
	projected.output_stock=maxi(0,o.production.output_stock-o.previous_sales)
	projected.harvest_remaining=o.farm_cap if projected.rule.input.is_empty() else 0
	projected.workers=[]
	for i in o.capacity:projected.workers.append({"id":"slot:%d"%i,"wage":10,"available":true})
	var plan: Dictionary=Base.plan(projected)
	var count: int=maxi(0,mini(o.capacity-o.staff.size()-o.reserved,plan.shifts-o.staff.size()-o.reserved))
	if o.disabled:count=0
	return {"vacancies":count,"projected_shifts":plan.shifts,"forecast_carry":projected.output_stock,
		"expected_receipts":plan.expected_receipts,"committed_cash":plan.committed_cash,"contribution":plan.expected_receipts-plan.committed_cash,
		"reason":"positive_funded_unfilled_position" if count>0 else "control_no_brew_request" if o.disabled else "no_profitable_unfilled_position"}
static func current_income(o: Dictionary) -> Dictionary:
	var paid: int=0;var due: int=0
	for row in o.history:paid+=row.paid;due+=row.due
	return {"numerator":0 if o.business.is_empty() else 10*(paid+1),"denominator":1 if o.business.is_empty() else due+2,"paid":paid,"due":due}
static func search(o: Dictionary) -> Dictionary:
	var current: Dictionary=current_income(o)
	var best: Dictionary={}
	if o.business.is_empty() or current.paid<current.due:
		for notice in o.notices:
			if not notice.active or notice.business==o.business or notice.filled+notice.reserved>=notice.vacancies:continue
			if 5*current.denominator<=current.numerator:continue # wage10 × unfamiliar prior1/2
			if best.is_empty() or notice.id<best.id:best=notice
	return {"action":"apply" if not best.is_empty() else "stay","posting":best.get("id",""),"current_income":current,
		"offer_income":{"numerator":5,"denominator":1} if not best.is_empty() else {},"reason":"strictly_better_observed_income" if not best.is_empty() else "status_quo_or_no_better_observed_vacancy"}
static func accept(o: Dictionary) -> bool:
	var current: Dictionary=current_income(o)
	return 5*current.denominator>current.numerator
