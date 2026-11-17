extends RefCounted
const Runner=preload("res://scripts/sim/binding_runner.gd")
const Planning=preload("res://scripts/sim/binding_policy.gd")
static func times() -> Array:
	var result: Array=Runner.TIMES.duplicate();result.append_array([900,955]);result.sort();return result
static func through(fixture: String,minute: int) -> RefCounted:
	var r=Runner.new(42,"reference","matching",fixture);r.world.advance_day()
	for value in times():
		if value>minute:break
		r.appointment(value)
	return r
static func finish(r: RefCounted,after: int) -> void:
	for minute in times():
		if minute>after:r.appointment(minute)
static func board_last_day() -> RefCounted:
	var r=Runner.new();r.run(2);r.world.advance_day()
	for minute in times():
		if minute>930:break
		r.appointment(minute)
	r.world.advance_time(955)
	for id in r.residents():r.world.begin_board(id)
	for b in r.Brew.ORDER:r.world.advertise(r.Brew.OWNERS[b],b)
	return r
static func board_first(fixture: String) -> RefCounted:
	var r=through(fixture,930);r.world.advance_time(955)
	for person in r.residents():r.world.begin_board(person)
	for b in r.Brew.ORDER:r.world.advertise(r.Brew.OWNERS[b],b)
	return r
static func offer(r: RefCounted,worker: String,b: String) -> String:
	var id: String="notice:%04d:%s"%[r.world._day,b]
	r.world.inspect_jobs(worker);assert(r.world.apply_for_job(worker,id))
	assert(r.world.make_job_offer(r.Brew.OWNERS[b],id+":"+worker));r.world.inspect_job_offers(worker)
	return id+":"+worker
static func breach(w: RefCounted,worker: String,kind: String) -> int:
	for e in w.events():
		if e.action=="binding_breach" and e.actor==worker and e.details.kind==kind:return e.id
	return 0
static func cash(w: RefCounted) -> int:
	var total: int=0
	for e in w.snapshot().entities.values():total+=e.money
	return total
static func deferred_sales() -> RefCounted:
	# Withhold bakery shopping only in this cash/expiry fault witness. Its21
	# initial bread remains real stock; day4 restores ordinary authorized sales.
	var r=Runner.new(42,"reference","matching","cash_short")
	for day in 3:
		r.world.advance_day()
		for minute in times():
			if minute not in [960,1025]:r.appointment(minute)
	return r
static func run(t: SceneTree) -> void:
	var declined=through("cash_short",780);declined.world.advance_time(840)
	t._check(declined.world.begin_attendance("finn","bakery",true) and declined.world._attendance["0001:bakery:finn"].kind=="standby","unfunded employer assignment falls back to attendance, never a worker no-show")
	declined.world.advance_time(900)
	t._check(declined.world._obligations["0001:bakery:finn"].amount==10 and declined.world._attendance["0001:bakery:finn"].status=="attended","employer failure to offer productive work cannot erase earned guarantee")
	var r=through("cash_short",900);var w=r.world;var id: String="0001:bakery:finn"
	t._check(w._attendance[id].status=="attended" and w._attendance[id].kind=="standby" and w._labor_used.get("finn",0)==0,"stocked idle worker attends one hour without fabricated production")
	t._check(w._obligations[id].paid==6 and w.arrears("bakery")==24 and w._entities.bakery.money==0 and w._entities.finn.money==6,"real six-coin partial guarantee uses protected capital and keeps exact arrears")
	var balances: Dictionary=w.snapshot().entities
	t._check(not w.pay_obligation("ada",id,4) and not w.pay_obligation("cora","forged",4) and not w.pay_obligation("cora",id,5) and not w.pay_obligation("cora",id,1.5) and w.snapshot().entities==balances,"unauthorized, forged, overpaid and fractional payouts reject atomically")
	t._check(not w.pay_obligation("cora","0001:bakery:iona",1),"older equally due worker has deterministic clearing priority")
	t._check(not w._pay("bakery","finn",4,"wage"),"raw wage transfer cannot bypass verified claim authority")
	for minute in times():
		if minute>900 and minute<=1060:r.appointment(minute)
	t._check(w._entities.bakery.money>120 and w.arrears("bakery")==24 and w.profit_budget("bakery").eligible==0,"real retail receipts above capital floor cannot bypass owed wages for distributions")
	finish(r,1060);var report: Dictionary=r.report()
	t._check(w.arrears("bakery")==0 and report.accounts.finn.wages==10 and report.accounts.finn.meals==1,"later retail cash discharges exact remainder without duplicate wage or lost meal")
	t._check(w._obligations[id].payments.size()==2 and w._obligations[id].payments[0].amount==6 and w._obligations[id].payments[1].amount==4 and w._obligations[id].payments[1].minute==1140,"partial and late receipts retain actual amount and timestamp")
	balances=w.snapshot().entities
	t._check(not w.pay_obligation("cora",id,1) and w.snapshot().entities==balances and cash(w)==9192,"already discharged guarantee cannot pay twice; currency conserved")
	var late=Runner.new(42,"reference","matching","cash_zero");late.run(1);report=late.report()
	t._check(report.accounts.finn.wages==10 and report.accounts.finn.meals==0 and report.accounts.finn.missed_meals==1 and report.accounts.finn.bread_spending==0,"19:00 wages cannot retroactively fund16:00 food or18:30 consumption")
	var full=Runner.new();full.run(3);report=full.report()
	t._check(report.contracts.counts.expired==11 and report.contracts.counts.renewed==11 and report.contracts.counts.nonrenewed==0,"day1–3 terms actually expire and voluntarily renew at day3 midnight")
	t._check(report.contracts.workers.dain.productive==3 and report.accounts.dain.wages==30 and full.world._employment.dain.start_day==4 and full.world._employment.dain.end_day==7,"productive wage is paid exactly once; new three-day term starts after old end")
	t._check(full.world._terms["term:0001:farm:dain"].end_day==4 and full.world._terms["term:0001:farm:dain"].status=="expired","immutable original end survives renewal archive")
	full.run(1);report=full.report()
	t._check(report.contracts.workers.dain.productive==4 and report.accounts.dain.wages==40,"first new-term productive day executes real paid work")
	var poor=Runner.new(42,"reference","matching","insolvent");poor.run(3);w=poor.world
	t._check(w.arrears("bakery")==90 and not w._employment.finn.active and not w._active_terms.has("finn"),"all ninety earned wage coins survive natural nonrenewal and expiration")
	t._check(poor.report().contracts.businesses.bakery.cash_margin==0 and poor.report().contracts.businesses.bakery.accrued_margin==-90,"unpaid wages are accrued expenses, not paper profit")
	var deferred=deferred_sales();w=deferred.world
	t._check(w.arrears("bakery")==84 and w._entities.bakery.inventory.bread==21,"withheld retail witness preserves real unsold goods and wage debt through expiry")
	deferred.run(1)
	t._check(w._obligations["0001:bakery:finn"].paid==10 and w.arrears("bakery")<84 and cash(w)==9192,"real later retail receipts discharge oldest claims after expiry without creating money")
	r=through("none",480);w=r.world;w.advance_time(540)
	var o: Dictionary=w.business_observation("ada","farm")
	o.harvest_remaining=19
	t._check(Planning.within(o).shifts==3 and preload("res://scripts/sim/brewery_policy.gd").plan(o).shifts==2,"already owed third wage is excluded from marginal farm use at cap19")
	o.harvest_remaining=16
	t._check(Planning.within(o).shifts==3,"two remaining wheat can be worth producing for an already guaranteed worker")
	var future: Dictionary=w.vacancy_observation("ada","farm");future.retained=0;future.expiring=w._active_staff("farm");future.production.output_stock=0;future.remaining_sales=0;future.demand=19;future.farm_cap=19
	t._check(Planning.renewal(future).headcount==2,"fresh three-day guarantee includes wages and rejects zero marginal third commitment")
	future.demand=20;future.farm_cap=20
	t._check(Planning.renewal(future).headcount==3,"one additional grain changes fresh commitment profitability without changing wage")
	future.production.output_price=1;future.demand=21;future.farm_cap=21
	t._check(Planning.renewal(future).headcount==0,"one-coin output-price sensitivity does not treat a new-term wage as sunk")
	o.output_price=1
	t._check(Planning.within(o).shifts==3,"same positive extra output may be useful within an already committed term")
	r=board_first("staggered");w=r.world
	t._check(not w.request_resignation("finn","bakery") and w._employment.finn.active,"active term cannot be cancelled for an attractive vacancy")
	w.inspect_jobs("finn")
	t._check(not w.apply_for_job("finn","notice:0001:farm") and w._pending_hires.is_empty(),"midterm employee may inspect but cannot accept an overlapping start")
	var farm_offer: String=offer(r,"dain","farm");var mill_offer: String=offer(r,"dain","mill")
	w.inspect_job_offers("dain")
	t._check(not w.accept_job_offer("finn",farm_offer),"offered guarantee cannot be accepted by another worker")
	t._check(w.accept_job_offer("dain",farm_offer) and not w.accept_job_offer("dain",mill_offer) and w._pending_hires.size()==1,"two real future employers cannot create overlapping contracts")
	t._check(w._employment.dain.start_day==1 and w._employment.dain.end_day==2 and not w.start_shift("dain","mill"),"old obligations survive final day and new employer cannot use a second labor unit")
	r=board_last_day();w=r.world;var app: String=offer(r,"dain","farm")
	t._check(w.decline_offer("dain",app) and w._employment.dain.active,"refusing a renewal does not cancel current final-day guarantee")
	finish(r,955)
	t._check(not w._employment.dain.active and w._obligations["0003:farm:dain"].paid==10,"voluntary nonrenewal expires only after final-day pay and closure")
	r=through("insolvent",955);w=r.world;var proof: int=breach(w,"iona","employer_unpaid")
	t._check(proof>0 and not w.release_for_breach("cora","iona",proof) and not w.release_for_breach("iona","iona",1),"employer wage breach needs verified unpaid proof and the worker's own choice")
	t._check(w.release_for_breach("iona","iona",proof) and w._employment.iona.active,"lawful wage-default opt-out takes effect next day only")
	finish(r,955)
	t._check(not w._employment.iona.active and w._obligations["0001:bakery:iona"].paid==0 and w.arrears("bakery")==30,"lawful release retains accrued unpaid liabilities")
	r=through("no_show",955);w=r.world;proof=breach(w,"dain","worker_nonattendance")
	t._check(proof>0 and not w._obligations.has("0001:farm:dain") and w._attendance["0001:farm:dain"].status=="absent","verified no-show differs from employer standby and earns no guarantee")
	t._check(w.release_for_breach("ada","dain",proof),"owner can invoke documented nonattendance for next-boundary termination")
	finish(r,955)
	t._check(not w._employment.dain.active and cash(w)==9192,"verified worker breach releases employment without an unearned wage")
	var remote=Runner.new();w=remote.world
	t._check(w.job_board("dain").is_empty() and not w.apply_for_job("dain","forged") and not w.post_job("ada","farm","remote",9,1,1,3),"remote forged notice and wrong fixed wage reject without private global knowledge")
	t._check(not w.start_self_employment("ada","farm") and not w._affiliations.has("ada"),"managing owner cannot acquire a simultaneous productive affiliation")
	var continuous=Runner.new();continuous.run(4);var split=Runner.new();split.run(3);split.run(1)
	t._check(continuous.report()==split.report() and continuous.world.events()==split.world.events(),"midnight expiry and renewal replay identically across split runs")
