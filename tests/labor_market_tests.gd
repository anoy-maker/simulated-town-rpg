extends RefCounted
const Runner=preload("res://scripts/sim/labor_market_runner.gd")
const Policy=preload("res://scripts/sim/labor_market_policy.gd")
static func meeting(fixture: String="vacancy:dain") -> RefCounted:
	var r=Runner.new(42,"reference","matching","neutral_rotate",fixture)
	r.world.advance_day()
	var times: Array=Runner.TIMES.duplicate();times.append(900);times.sort()
	for minute in times:
		if minute>930:break
		r.appointment(minute)
	r.world.advance_time(955)
	for id in r.residents():r.world.begin_board(id)
	r.world.advertise("ada","farm")
	return r
static func offered(r: RefCounted, worker: String="finn") -> String:
	var w=r.world;var id: String="notice:0001:farm"
	w.inspect_jobs(worker);w.apply_for_job(worker,id);w.make_job_offer("ada",id+":"+worker)
	return id+":"+worker
static func boundary(r: RefCounted) -> void:
	for minute in Runner.TIMES:
		if minute>=960:r.appointment(minute)
	r.world.advance_day()
static func run(t: SceneTree) -> void:
	var rows=[{"id":"z","wage":8,"available":true},{"id":"a","wage":10,"available":true},{"id":"b","wage":10,"available":true},{"id":"c","wage":1,"available":false}]
	for tie in ["legacy_sorted","neutral_rotate"]:
		var ordered: Array=Policy.order(rows,1,tie)
		t._check(ordered[0].id=="z" and ordered.back().id=="c","financial/availability preference precedes tie rule")
	t._check(Policy.order(rows,1,"neutral_rotate")[1].id=="b" and Policy.order(rows,1,"legacy_sorted")[1].id=="a","neutral rotation acts only on financial ties")
	var o={"worker":"finn","day":1,"business":"bakery","history":[{"due":1,"paid":0}],"notices":[{"id":"p","business":"farm","active":true,"filled":0,"reserved":0,"vacancies":1}]}
	t._check(Policy.search(o).action=="apply" and Policy.accept(o),"own unpaid shift makes observed prior strictly preferable")
	o.history=[{"due":2,"paid":1}]
	t._check(Policy.search(o).action=="stay" and not Policy.accept(o),"exact expected income tie preserves current job")
	o.history=[{"due":1,"paid":1}]
	t._check(Policy.search(o).action=="stay","paid worker retains better status quo")
	o.business="";o.notices=[]
	t._check(Policy.search(o).action=="stay","unemployed cannot invent unseen opportunities")
	var remote=Runner.new(42,"reference","matching","neutral_rotate","vacancy:dain");var w=remote.world
	t._check(w.job_board("finn").is_empty() and not w.apply_for_job("finn","forged"),"no remote global board or forged notice")
	t._check(not w.post_job("ada","farm","remote",10,1,1,30),"owner cannot post away from local board")
	t._check(not w.request_resignation("finn","bakery") and w._affiliations.finn.business=="bakery","blind resignation cannot discard current employment")
	var r=meeting();w=r.world;var id: String="notice:0001:farm"
	var observation: Dictionary=w.worker_observation("finn")
	w._entities.visitors.money-=1;w._entities.mill.money+=1
	t._check(observation==w.worker_observation("finn"),"worker plan excludes unrelated private balances")
	t._check(not w.post_job("ada","farm","wrong-wage",9,1,1,30),"fixed wage authority rejects underbidding")
	t._check(not w.post_job("ada","farm","duplicate",10,1,1,30),"overlapping same-day notice cannot multiply installed slots")
	t._check(not w.apply_for_job("finn",id),"co-location alone does not authorize unseen application")
	w.inspect_jobs("finn");w.inspect_jobs("hale")
	t._check(w.apply_for_job("finn",id) and w.apply_for_job("hale",id),"incumbents can compete without quitting")
	t._check(w._affiliations.finn.business=="bakery" and w._affiliations.hale.business=="mill","applications preserve both current affiliations")
	t._check(w.make_job_offer("ada",id+":finn") and not w.make_job_offer("ada",id+":hale"),"one genuine vacancy cannot promise two arrivals")
	t._check(not w.accept_job_offer("finn",id+":finn"),"acceptance requires personal observation of offered terms")
	w.inspect_job_offers("finn")
	t._check(not w.accept_job_offer("hale",id+":finn"),"another applicant cannot accept an offered contract")
	var before: Dictionary=w.snapshot().entities
	t._check(w.accept_job_offer("finn",id+":finn") and before==w.snapshot().entities,"contingent acceptance moves no goods or money")
	t._check(w._affiliations.finn.business=="bakery" and w._pending_hires.finn.effective_day==2,"accepted incumbent remains in old job today")
	t._check(not w.accept_job_offer("finn",id+":finn"),"duplicate acceptance cannot reserve a second affiliation")
	t._check(not w.start_shift("finn","farm"),"future affiliation cannot work same day")
	t._check(w.cancel_notice("ada",id) and w._pending_hires.is_empty() and w._resignations.is_empty() and w._affiliations.finn.business=="bakery","withdrawal atomically cancels pending entry and contingent exit")
	r=meeting();w=r.world;offered(r);boundary(r)
	t._check(w._affiliations.finn.business=="bakery" and w._pending_hires.is_empty(),"unaccepted offer expires without ending incumbent job")
	r=meeting();w=r.world;var app: String=offered(r);w.inspect_job_offers("finn");w.accept_job_offer("finn",app)
	# Fault-injection fixture: changed funds must cancel the entire transition.
	w._entities.visitors.money+=w._entities.farm.money;w._entities.farm.money=0
	boundary(r)
	t._check(w._affiliations.finn.business=="bakery" and w._pending_hires.is_empty() and w._resignations.is_empty(),"boundary funding failure preserves old job atomically")
	r=meeting();w=r.world;app=offered(r)
	w._space.presences.ada.activity="idle"
	t._check(not w.make_job_offer("ada",app),"absent or busy owner cannot issue offers")
	w._space.presences.ada.activity="board";w._space.presences.finn.activity="rest"
	t._check(w.inspect_jobs("finn").notices.is_empty() and not w.accept_job_offer("finn",app),"busy worker cannot observe or accept")
	r=meeting();w=r.world
	# Controlled two-vacancy authority fixture; production/cash are not endowed.
	w._employment.hale.active=false;w._affiliations.erase("hale")
	w.advertise("bram","mill");w.inspect_jobs("finn")
	w.apply_for_job("finn",id);w.apply_for_job("finn","notice:0001:mill")
	w.make_job_offer("ada",id+":finn");w.make_job_offer("bram","notice:0001:mill:finn");w.inspect_job_offers("finn")
	t._check(w.accept_job_offer("finn",id+":finn") and not w.accept_job_offer("finn","notice:0001:mill:finn") and w._pending_hires.size()==1,"conflicting employers cannot reserve two accepted jobs for one worker")
	var full=Runner.new();full.run(3)
	t._check(full.report().labor.counts.postings==0 and full.report().labor.counts.employment_started==0,"full reference staffing does not fabricate vacancies")
	var moved=Runner.new(42,"reference","matching","neutral_rotate","vacancy:dain");moved.run(3);w=moved.world
	t._check(w._affiliations.finn.business=="farm" and w._entities.finn.skills==["baker"],"cross-industry authorization uses homogeneous labor without falsifying skill history")
	var paid_new: bool=false;var ended: int=0;var started: int=0;var old_breach: bool=false
	for e in w.events():
		if e.actor=="finn" and e.action=="employment_ended":ended=e.id
		if e.actor=="finn" and e.action=="employment_started":started=e.id
		if e.actor=="farm" and e.target=="finn" and e.action=="transfer_money" and e.success and e.day==2:paid_new=true
		if e.actor=="finn" and e.action=="contract_shift" and e.day==1 and not e.success:old_breach=true
	t._check(paid_new and ended>0 and started>ended and old_breach,"old breach retained; midnight end precedes start; new productive shift pays ten")
	var split=Runner.new(42,"reference","matching","neutral_rotate","vacancy:dain");split.run(1);split.run(2)
	t._check(split.report()==moved.report() and split.world.events()==w.events(),"transfer and route state replay across split runner calls")
	var zero=Runner.new(42,"tight","matching","neutral_rotate","vacancy:dain");zero.run(1)
	t._check(zero.report().labor.counts.postings==0,"zero-margin third farm shift cannot create profitable vacancy")
