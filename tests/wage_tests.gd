extends RefCounted
const Wage=preload("res://scripts/sim/wage_policy.gd")
const Math=preload("res://scripts/sim/wage_projection.gd")
const Old=preload("res://scripts/sim/input_projection.gd")
const Runner=preload("res://scripts/sim/input_runner.gd")
static func at_board(r) -> void:
	r.world.advance_day()
	var times: Array=r.TIMES.duplicate();times.append_array([900,955]);times.sort()
	for minute in times:
		if minute<=955:r.appointment(minute)
static func run(t: SceneTree) -> void:
	var r=Runner.new(42,"tight","R_input_aware");at_board(r)
	for b in r.Brew.ORDER:
		var o: Dictionary=r.world.vacancy_observation(r.Brew.OWNERS[b],b)
		for count in range(o.capacity+1):
			var salaries: Array=[];salaries.resize(count);salaries.fill(10)
			t._check(Math.project(o,salaries)==Old.project(o,count,true),"all-ten complete future trajectories "+b+str(count))
		for variant in [{"cash":0,"arrears":6},{"cash":40,"arrears":0},{"cash":120,"arrears":4}]:
			var p: Dictionary=o.duplicate(true);p.production.cash=variant.cash;p.arrears=variant.arrears;p.production.input_stock=2*p.production.rule.take
			if b!="farm":p.input_reliability={"numerator":1,"denominator":12}
			t._check(Math.project(p,[10,10])==Old.project(p,2,true),"all-ten owned goods, arrears, cash and poor fill "+b+str(variant.cash))
		var mixed: Dictionary=Math.project(o,[8,5])
		t._check(mixed.summary.guaranteed_wages==39 and mixed.days.all(func(d):return d.guaranteed_wages==13),"mixed all wages including standby "+b)
	var o: Dictionary=r.world.vacancy_observation("cora","bakery");o.capacity=1;o.retained=0;o.production.cash=120
	var bidders=[{"id":"incumbent","wage":10,"incumbent":true},{"id":"outsider","wage":8,"incumbent":false}]
	t._check(Wage.select(o,[],bidders).selected==["outsider"],"real lower wage can defeat incumbent")
	bidders[1].wage=10;t._check(Wage.select(o,[],bidders).selected==["incumbent"],"equal financial terms retain incumbent")
	t._check(Wage.select(o,[],[{"id":"expensive","wage":20,"incumbent":false}]).selected.is_empty(),"twenty cannot cover actual conditional marginal value")
	o.production.cash=0;t._check(Wage.select(o,[],bidders).selected.is_empty(),"no future sales fund a current offer")
	var known={"bread":{"quote":{"unit_price":6}},"ale":{"quote":{"unit_price":4}}}
	var worker={"worker":"fixture","money":0,"inventory":{"bread":0,"ale":0},"bread_eaten":false,"ale_drunk":false,"eligible":true,"anchor":{"wage":5},"quotes":known,"history":[],"notices":[{"id":"n","business":"bakery","context":{},"active":true,"vacancies":1}]}
	var p: Dictionary=Wage.worker(worker)
	t._check(p.action=="bid" and p.wage>0,"positive own income can motivate a bid")
	worker.anchor.wage=5;p=Wage.worker(worker)
	t._check(p.wage<6 and p.score.numerator>0,"own declared belief can rationally select below bread affordability")
	var low: int=p.wage;worker.money=100;p=Wage.worker(worker)
	t._check(p.wage>low,"better own savings can change the utility-optimal ask")
	worker.notices=[];t._check(Wage.worker(worker).reason=="no_observed_positive_vacancy","no job is not a lost application")
	worker.eligible=false;t._check(Wage.worker(worker).reason=="binding_term_active","locked wage cannot be renegotiated")
	worker.eligible=true;worker.quotes={};t._check(Wage.worker(worker).reason=="unknown_bread_quote","unknown private quote cannot be fabricated")
	# Native command boundary: real board, real notice, no direct balance writes.
	var live=preload("res://scripts/sim/wage_runner.gd").new(42,"reference","worker_bids")
	t._check(not live.world.work_shift("missing","farm") and not live.world.work_shift("dain","missing"),"invalid actors/businesses reject without salary lookup crash")
	live.run(1);t._check(not live.world.request_resignation("dain","farm"),"a locked contract cannot be abandoned")
	live.run(1);live.world.advance_day()
	var times: Array=live.TIMES.duplicate();times.append_array([900,955]);times.sort()
	for minute in times:
		if minute<955:live.appointment(minute)
	live.world.advance_time(955);live.world.freeze_demand()
	for w in live.residents():live.world.begin_board(w)
	for b in live.Brew.ORDER:live.world.advertise(live.Brew.OWNERS[b],b)
	var witnessed: Dictionary=live.world.inspect_jobs("dain")
	var notice: String="wage_notice:0003:farm";var money: Dictionary=live.world.snapshot().entities
	for bad in [0,-1,21,1.5,9223372036854775807,INF,NAN]:
		t._check(not live.world.submit_wage_bid("dain",notice,bad,witnessed.event_id),"invalid/overflow/noninteger salary rejects "+str(bad))
	t._check(not live.world.submit_wage_bid("dain",notice,8,1),"forged observation cannot authorize a bid")
	t._check(not live.world.submit_wage_bid("edda",notice,8,witnessed.event_id),"another worker's sighting is not own knowledge")
	t._check(live.world.snapshot().entities==money and live.world._wage_bids.is_empty(),"failed asks preserve cash, goods and commitments")
	t._check(live.world.submit_wage_bid("dain",notice,8,witnessed.event_id),"real eligible incumbent may request a new salary")
	t._check(not live.world.submit_wage_bid("dain",notice,7,witnessed.event_id),"one sealed bid per worker meeting")
	t._check(not live.world._make_wage_offer("ada","wage_bid:0003:dain",1),"unattested firm selection cannot create an offer")
	var finn_known: Dictionary=live.world.inspect_jobs("finn")
	t._check(live.world.submit_wage_bid("finn",notice,8,finn_known.event_id),"independent outsider can submit one observed ask")
	live.world.consider_applicants("ada","farm")
	var finn_app: String=live.world._wage_bids["wage_bid:0003:finn"].application_id
	live.world.inspect_job_offers("finn")
	t._check(live.world.decline_offer("finn",finn_app) and not live.world._postings[live.world._applications[finn_app].posting].active,"worker may voluntarily refuse an actual personally observed offer")
	live.world.consider_applicants("ada","farm")
	t._check(live.world.events().back().details.reason=="daily_selection_limit","one financial selection phase prevents overlapping offers")
	var app: String=live.world._wage_bids["wage_bid:0003:dain"].application_id
	t._check(not live.world.accept_job_offer("dain",app) and not live.world.accept_wage_offer("dain",app,1),"legacy bypass and unobserved acceptance reject")
	live.world.respond_to_offers("dain")
	t._check(live.world._pending_hires.dain.effective_day==4 and live.world._employment.dain.wage==10 and live.world._terms[live.world._active_terms.dain].wage==10,"accepted successor cannot change today's bound salary")
	t._check(live.world.snapshot().entities==money,"negotiation never transfers or invents money/goods")
	t._check(live.world.cancel_wage_notice("ada",notice) and live.world._pending_hires.is_empty() and live.world._resignations.is_empty(),"cancellation leaves no phantom employment or early resignation")
	for minute in times:
		if minute>955:live.appointment(minute)
	t._check(not live.world._affiliations.has("dain") and live.world._terms["term:0001:farm:dain"].status=="expired","cancelled entry still respects natural old-term expiration")
	live.world.advance_day()
	for minute in times:
		if minute<955:live.appointment(minute)
	live.world.advance_time(955);live.world.freeze_demand()
	for w in live.residents():live.world.begin_board(w)
	for b in live.Brew.ORDER:live.world.advertise(live.Brew.OWNERS[b],b)
	t._check(not live.world.cancel_wage_notice("ada",notice),"an old notice cannot cancel a later meeting's commitments")
	live.world.inspect_jobs("dain")
	t._check(live.world._wage_memory.get("dain",[]).is_empty(),"canceled posting is unknown, never a fictitious lost auction")
