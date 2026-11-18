extends RefCounted
## Own validated direct-input receipts only. No world or researcher state.
const ARMS=["R_baseline_instrumented","R_input_aware"]
const INPUTS={"mill":{"supplier":"farm","item":"wheat","lot_size":5,"K":3},"bakery":{"supplier":"mill","item":"flour","lot_size":5,"K":3},"brewery":{"supplier":"farm","item":"wheat","lot_size":3,"K":2}}
static func estimate(history: Array,b: String,day: int,terms: Dictionary) -> Dictionary:
	var rule: Dictionary=INPUTS.get(b,{})
	var k: int=rule.get("K",0)
	var q: Dictionary=terms.get("quote",{})
	var known: bool=not rule.is_empty() and terms.get("day",0)==day and not q.is_empty() and q.get("active",false) and q.get("seller","")==rule.supplier and q.get("item","")==rule.item
	var rows: Array=[];var ids: Array=[];var receipts: Array=[];var days: Array=[]
	if known:
		var ordered: Array=history.duplicate(true)
		ordered.sort_custom(func(a,c):return a.day<c.day or (a.day==c.day and a.order_event_id<c.order_event_id))
		for r in ordered:
			if r.business!=b or r.day>=day or r.supplier!=q.seller or r.item!=q.item or r.price!=q.unit_price:continue
			if not r.eligible or not r.requested is int or not r.filled is int or r.requested<=0 or r.requested>k or r.filled<0 or r.filled>r.requested:continue
			if r.order_event_id in ids or r.day in days or r.receipt_ids.any(func(id):return id in receipts):continue
			rows.append(r);ids.append(r.order_event_id);days.append(r.day);receipts.append_array(r.receipt_ids)
	rows=rows.slice(maxi(0,rows.size()-3))
	var n: int=k;var d: int=k
	for r in rows:n+=r.filled;d+=r.requested
	return {"day":day,"business":b,"supplier":rule.get("supplier",""),"item":rule.get("item",""),"K":k,"numerator":n,"denominator":d,
		"price":q.get("unit_price",0) if known else 0,"quote":q.duplicate(true) if known else {},"inspection_event_id":terms.get("inspection_event_id",null) if known else null,
		"sample_order_ids":rows.map(func(r):return r.order_event_id),"sample_days":rows.map(func(r):return r.day),
		"status":"inapplicable" if rule.is_empty() else "unknown_quote" if not known else "prior_only" if rows.is_empty() else "observed_fill_heuristic"}

static func predicted_lots(k: Variant,n: Variant,d: Variant) -> int:
	# Fixed tiny operands also make integer overflow impossible before arithmetic.
	if not k is int or not n is int or not d is int or k<0 or k>3 or n<=0 or n>d or d>12:return -1
	@warning_ignore("integer_division")
	var result: int=(2*k*n+d)/(2*d)
	return clampi(result,0,k)
