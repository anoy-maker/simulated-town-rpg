extends RefCounted
const Runner=preload("res://scripts/sim/demand_runner.gd")
const Memory=preload("res://scripts/sim/demand_memory.gd")
const Helpers=preload("res://tests/binding_tests.gd")
static func run(t: SceneTree) -> void:
	var rows: Array=[]
	for day in 5:
		rows.append({"business":"bakery","day":day+1,"price":6,"eligible":true,"sales":0,"unfilled":12,"closed_event_id":day+100})
	var sales: Dictionary=Memory.estimate(rows,"bakery",5,6,21,"sales_smoothed")
	var requests: Dictionary=Memory.estimate(rows,"bakery",5,6,21,"requests_smoothed")
	t._check(sales.forecast==6 and requests.forecast==15 and sales.sample_days==[2,3,4] and sales.denominator==4,"same three completed days and one exact prior; only unfilled signal differs")
	t._check(Memory.estimate(rows,"bakery",1,6,21,"requests_smoothed").forecast==21 and Memory.estimate(rows,"bakery",6,5,21,"requests_smoothed").forecast==21,"future-day embargo and same-price filtering preserve target fallback")
	rows[3].eligible=false
	t._check(Memory.estimate(rows,"bakery",5,6,21,"requests_smoothed").sample_days==[1,2,3],"unknown day is skipped, never manufactured zero")
	rows[0].unfilled=1000
	t._check(Memory.estimate(rows.slice(0,1),"bakery",2,6,21,"requests_smoothed").forecast==30,"disclosed model guard bounds estimates")
	var q: Dictionary={"unit_price":6,"version":1,"active":true}
	var empty: Dictionary=Memory.day_record(1,"bakery","bread",q)
	empty.coverage_ticks=30;empty.witness_ticks=30
	var complete: Dictionary=Memory.close(empty,1)
	t._check(complete.complete and complete.eligible and not complete.censored and complete.sales==0,"actually witnessed zero-interest open window is a real zero")
	empty.witness_ticks=0
	t._check(not Memory.close(empty,1).eligible and Memory.close(empty,1).censored,"absent owner and empty books are unknown partial coverage")
	empty.empty_inspection_ids=[42]
	t._check(Memory.close(empty,1).unfilled==0 and not Memory.close(empty,1).eligible,"sold-out inspection without request proves no latent interest")
	empty.order_ids=[43];empty.unfilled=1
	t._check(Memory.close(empty,1).eligible and Memory.close(empty,1).censored,"real partial-window order is a labeled low-biased sample")
	for c in ["reference","tight","scarce"]:
		var r=Runner.new(42,c,"requests_smoothed");r.run(1);var w=r.world;var events: Array=w.events()
		var grain: Array=events.filter(func(e):return e.action=="demand_order_observed" and e.target=="farm")
		t._check(grain.size()==2 and grain[0].details.quantity==15 and grain[1].details.quantity==6,"funded own inbound whole-lot grain requests independent of cap "+c)
		var shortage: int=grain.reduce(func(n,e):return n+e.details.unfilled,0)
		t._check(shortage==(0 if c=="reference" else 3 if c=="tight" else 5),"rationed demand is actual request minus real clearing, not output gap "+c)
		var report: Dictionary=r.report()
		t._check(report.money.final==9192 and report.contracts.wage==10 and report.contracts.term_days==3,"currency and original binding terms remain authoritative "+c)
		var forecast: Dictionary=w._demand_forecasts.filter(func(f):return f.business=="bakery")[0]
		t._check(forecast.sample_days.is_empty() and forecast.forecast==21,"15:55 cannot know later visitor requests "+c)
		if c=="reference":
			var ale: Array=events.filter(func(e):return e.action=="demand_order_observed" and e.target=="brewery" and e.details.unfilled>0)
			t._check(ale.size()==5 and ale.all(func(e):return e.details.quantity==1 and e.details.reason=="stockout"),"solvent quoted ale stockout comes from real visitor requests")
			var refusals: Array=events.filter(func(e):return e.action=="demand_customer_intent" and e.success and e.target=="brewery" and e.details.quantity==0)
			t._check(not refusals.is_empty(),"stocked voluntary/unaffordable refusals are not unfilled requests")
		if c=="scarce":
			t._check(events.any(func(e):return e.action=="demand_order_observed" and e.target=="bakery" and e.details.unfilled==1),"interested solvent bread shopper makes real empty-shelf request")
			t._check(events.any(func(e):return e.action=="demand_order_observed" and e.target=="mill" and e.details.unfilled==5),"12:10 funded flour request exposes direct stock shortage")
	var r=Runner.new();r.world.advance_day()
	for minute in Helpers.times():
		if minute>610:break
		r.appointment(minute)
	var w=r.world;var before: Dictionary=w.snapshot().entities
	t._check(not w.request_grain("cora","mill",1,{}) and w.snapshot().entities==before,"ineligible B2B identity cannot create money or valid demand")
	var stale: Dictionary=w._requests.mill.quote.duplicate(true);stale.version+=1
	t._check(not w.purchase_quote("mill",stale,5) and w.snapshot().entities==before,"changed/unobserved quote rejects atomically")
	t._check(not w.request_grain("bram","mill",1,stale),"overlapping/late grain request cannot generate extra demand")
	var first=Runner.new(42,"tight","requests_smoothed");first.run(3)
	var split=Runner.new(42,"tight","requests_smoothed");split.run(1);split.run(2)
	t._check(first.world.events()==split.world.events() and first.report()==split.report(),"split replay preserves memory, quotes, transactions and contract decisions")
