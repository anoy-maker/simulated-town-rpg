extends RefCounted
## M26 bounded own-seller evidence adapter; no private consumer state.
const ARMS=["legacy_instrumented","sales_smoothed","requests_smoothed"]
static func day_record(day: int,b: String,item: String,q: Dictionary) -> Dictionary:
	return {"day":day,"business":b,"item":item,"price":q.unit_price,"version":q.version,"quote_consistent":q.active,"coverage_ticks":0,"witness_ticks":0,"witness_clock_ids":[],"empty_inspection_ids":[],"sale_ids":[],"order_ids":[],"sales":0,"unfilled":0}
static func close(r: Dictionary,event_id: int) -> Dictionary:
	var row: Dictionary=r.duplicate(true)
	row["complete"]=row.quote_consistent and row.coverage_ticks>0 and row.coverage_ticks==row.witness_ticks
	row["censored"]=not row.complete or not row.empty_inspection_ids.is_empty() or row.unfilled>0
	row["eligible"]=row.quote_consistent and (row.complete or row.sales>0 or not row.order_ids.is_empty())
	row["closed_event_id"]=event_id
	return row
static func estimate(history: Array,b: String,day: int,price: int,target: int,arm: String) -> Dictionary:
	assert(arm in ARMS)
	var rows: Array=[]
	for row in history:
		if row.business==b and row.day<day and row.price==price and row.eligible:rows.append(row)
	rows=rows.slice(maxi(0,rows.size()-3))
	var numerator: int=target
	for row in rows:numerator+=row.sales+(row.unfilled if arm=="requests_smoothed" else 0)
	@warning_ignore("integer_division")
	var point: int=clampi((numerator+rows.size())/(1+rows.size()),0,30)
	return {"arm":arm,"business":b,"day":day,"price":price,"target":target,"sample_ids":rows.map(func(r):return r.closed_event_id),"sample_days":rows.map(func(r):return r.day),"numerator":numerator,"denominator":1+rows.size(),"forecast":point,"uses_unfilled":arm=="requests_smoothed"}
