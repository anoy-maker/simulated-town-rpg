extends RefCounted
const Memory=preload("res://scripts/sim/input_memory.gd")
const Forecast=preload("res://scripts/sim/input_projection.gd")
const Bound=preload("res://scripts/sim/binding_policy.gd")
const Runner=preload("res://scripts/sim/input_runner.gd")
static func record(b: String,day: int,r: int,f: int) -> Dictionary:
	var q: Dictionary=Memory.INPUTS[b]
	return {"business":b,"day":day,"supplier":q.supplier,"item":q.item,"price":2 if q.item=="wheat" else 5,"requested":r,"filled":f,"eligible":true,"order_event_id":100+day,"receipt_ids":[200+day] if f else []}
static func terms(b: String,day: int) -> Dictionary:
	var q: Dictionary=Memory.INPUTS[b]
	return {"day":day,"inspection_event_id":10,"quote":{"seller":q.supplier,"item":q.item,"unit_price":2 if q.item=="wheat" else 5,"active":true}}
static func run(t: SceneTree) -> void:
	for b in Memory.INPUTS:
		var k: int=Memory.INPUTS[b].K
		var history: Array=[record(b,1,k,k),record(b,2,k,1),record(b,3,k,0)]
		var point: Dictionary=Memory.estimate(history,b,4,terms(b,4))
		t._check(point.numerator==2*k+1 and point.denominator==4*k and point.sample_days==[1,2,3],"exact full/partial/entirely-rationed own lots "+b)
		t._check(Memory.estimate(history,b,1,terms(b,1)).numerator==k,"today's morning cannot enter completed-day history "+b)
		var duplicate: Array=history.duplicate(true);duplicate.append(history[0].duplicate(true))
		t._check(Memory.estimate(duplicate,b,4,terms(b,4))==point,"duplicate order and receipt cannot inflate fill belief "+b)
		var altered: Array=history.duplicate(true);altered[2].requested=0;altered[1].eligible=false
		t._check(Memory.estimate(altered,b,4,terms(b,4)).sample_days==[1],"zero order and ineligible demand are not failures "+b)
		for field in ["price","supplier","item"]:
			altered=history.duplicate(true);altered[2][field]=99 if field=="price" else "unobserved"
			t._check(Memory.estimate(altered,b,4,terms(b,4)).sample_days==[1,2],"exact input quote context "+b+":"+field)
		var full: Array=[record(b,1,k,k),record(b,2,k,k),record(b,3,k,k),record(b,4,k,k)]
		var p: Dictionary=Memory.estimate(full,b,5,terms(b,5))
		t._check(p.numerator==p.denominator and p.sample_days==[2,3,4],"last three comparable days and full-reliability identity "+b)
		t._check(Memory.estimate(history,b,4,{}).status=="unknown_quote","no inspected terms cannot gain supplier information "+b)
	t._check(Memory.estimate([],"farm",1,{}).status=="inapplicable","farm has no purchased-input estimate")
	t._check(Memory.predicted_lots(1,1,2)==1 and Memory.predicted_lots(3,1,2)==2 and Memory.predicted_lots(2,1,4)==1,"exact half-up ties")
	t._check(Memory.predicted_lots(0,1,12)==0 and Memory.predicted_lots(3,1,12)==0,"zero desired and low ratio stay integer bounded")
	for bad in [[3,1,0],[4,1,2],[3,-1,2],[3,3,2],[3,1,9223372036854775807],[3,9223372036854775807,9223372036854775807],[1.5,1,2]]:
		t._check(Memory.predicted_lots(bad[0],bad[1],bad[2])==-1,"invalid/overflow inputs reject before multiplication "+str(bad))
	var r=Runner.new(42,"tight","R_input_aware");r.world.advance_day()
	var times: Array=r.TIMES.duplicate();times.append_array([900,955]);times.sort()
	for minute in times:
		if minute>955:break
		r.appointment(minute)
	var before: Dictionary=r.world.snapshot().entities
	for b in r.Brew.ORDER:
		var o: Dictionary=r.world.vacancy_observation(r.Brew.OWNERS[b],b)
		for n in range(o.capacity+1):
			var old: Dictionary=Bound.forecast(o,n);var same: Dictionary=Forecast.project(o,n,true)
			t._check(old==same.summary and same==Forecast.project(o,n,false),"no history every candidate and three-day cash/wage trajectory identical "+b+str(n))
		if b=="farm":continue
		o.input_reliability={"numerator":1,"denominator":12};o.production.input_stock=2*o.production.rule.take
		var poor: Dictionary=Forecast.project(o,2,true)
		t._check(poor.days[0].shifts==2 and poor.days[0].desired_lots==0 and poor.summary.guaranteed_wages==60,"owned input retained despite poor future delivery; all wages owed "+b)
		o.production.input_stock=0;poor=Forecast.project(o,2,true)
		t._check(poor.days.all(func(d):return d.shifts==0 and d.predicted_lots==0 and d.guaranteed_wages==20) and poor.summary.inputs==0,"short supply makes standby, never wage haircut or phantom output "+b)
		var current: Dictionary=o.production.duplicate(true);current.committed_payroll=20;current.funded_workers=current.workers.map(func(w):return w.id);current.cash=120;current.output_stock=0;current.input_stock=0
		t._check(Bound.within(current).committed_payroll==20 and poor.summary.guaranteed_wages==60,"current guaranteed work and new term keep distinct cost basis "+b)
	t._check(r.world.snapshot().entities==before,"pure forecasts never change authoritative goods or coins")
