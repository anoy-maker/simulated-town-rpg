extends RefCounted
## M28 pure three-day projection; unchanged current-day planner and objective.
const Base=preload("res://scripts/sim/brewery_policy.gd")
const Bound=preload("res://scripts/sim/binding_policy.gd")
const Memory=preload("res://scripts/sim/input_memory.gd")
static func project(o: Dictionary,count: int,limited: bool) -> Dictionary:
	assert(count>=0 and count<=3)
	var ratio: Dictionary=o.get("input_reliability",{})
	var n: int=ratio.get("numerator",1);var d: int=ratio.get("denominator",1)
	var applicable: bool=not o.production.rule.input.is_empty()
	if applicable:assert(n>0 and n<=d and d<=12)
	var stock: int=maxi(0,o.production.output_stock-o.remaining_sales)
	var cash: int=o.production.cash+o.remaining_sales*o.production.output_price-o.arrears
	var raw: int=o.production.input_stock
	var receipts: int=0;var inputs: int=0;var feasible: bool=cash>=0;var days: Array=[]
	for day in 3:
		var p: Dictionary=o.production.duplicate(true)
		p.cash=maxi(0,cash-10*count);p.output_stock=stock;p.input_stock=raw;p.harvest_remaining=o.farm_cap;p.workers=[]
		for i in count:p.workers.append({"id":"slot:%d"%i,"wage":0,"available":cash>=10*count})
		var full: Dictionary=Base.plan(p);var k: int=full.lots
		var predicted: int=Memory.predicted_lots(k,n,d) if limited and applicable else k
		var plan: Dictionary=full
		if limited and applicable and predicted<k:
			var capped: Dictionary=p.duplicate(true)
			capped.cash-=predicted*p.rule.take*p.input_price
			capped.input_stock+=predicted*p.rule.take;capped.allow_procurement=false
			plan=Base.plan(capped)
		var cost: int=predicted*p.rule.take*p.input_price
		var opening: int=cash;cash-=cost+10*count;inputs+=cost;feasible=feasible and cash>=0
		@warning_ignore("integer_division")
		var output: int=plan.expected_receipts/p.output_price
		stock+=output;var owned: int=raw;raw+=(predicted-plan.shifts)*p.rule.take
		var sold: int=mini(stock,o.demand);stock-=sold;cash+=sold*p.output_price;receipts+=sold*p.output_price
		days.append({"projected_day":day+1,"owned_input_before":owned,"desired_lots":k,"predicted_lots":predicted,"input_cost":cost,"shifts":plan.shifts,"output":output,"owned_input_after":raw,"output_stock_after":stock,"sold":sold,"opening_cash":opening,"cash_before_sales":opening-cost-10*count,"closing_cash":cash,"guaranteed_wages":10*count})
	var summary={"headcount":count,"receipts":receipts,"inputs":inputs,"guaranteed_wages":30*count,"contribution":receipts-inputs-30*count,"feasible":feasible,"cash":cash}
	if not limited or not applicable or n==d:assert(summary==Bound.forecast(o,count))
	return {"summary":summary,"days":days}
static func forecast(o: Dictionary,count: int) -> Dictionary:return project(o,count,true).summary
