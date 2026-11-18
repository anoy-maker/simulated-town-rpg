extends "res://scripts/sim/cash_allocation_world.gd"
## M30 opt-in authority. Policies receive copied, actor-authorized observations.
const Wages=preload("res://scripts/sim/wage_policy.gd")
var wage_arm: String
var _wage_notices: Dictionary={}
var _wage_bids: Dictionary={}
var _wage_known: Dictionary={}
var _wage_offers: Dictionary={}
var _wage_memory: Dictionary={}
var _wage_anchors: Dictionary={}
var _wage_quotes: Dictionary={}
var _wage_settlements: Dictionary={}
var _wage_proposals: Dictionary={}
var _wage_selected: Dictionary={}
var _wage_shopping: Dictionary={}

func _init(seed_value: int=42,condition: String="reference",arm: String="fixed10_instrumented",selected_allocation: String="original") -> void:
	assert(arm in Wages.ARMS and selected_allocation in ["original","households_330"]);wage_arm=arm
	for w in Bound.initial().employment:
		var j: Dictionary=Bound.initial().employment[w]
		_wage_anchors[w]={"wage":10,"term":_term_id(w,j.business,1),"source_event_id":1}
	super(seed_value,condition,"R_input_aware",selected_allocation)
func snapshot() -> Dictionary:
	return super().merged({"wage_market":{"arm":wage_arm,"notices":_wage_notices.duplicate(true),"bids":_wage_bids.duplicate(true),"known":_wage_known.duplicate(true),"offers":_wage_offers.duplicate(true),"memory":_wage_memory.duplicate(true),"anchors":_wage_anchors.duplicate(true),"quotes":_wage_quotes.duplicate(true),"shopping":_wage_shopping.duplicate(true),"settlements":_wage_settlements.duplicate(true)}})
func _binding_salary(w: String,b: String) -> int:
	if wage_arm=="fixed10_instrumented":return 10
	if not _employment.has(w) or not _employment[w].active or _employment[w].business!=b:return 10
	var job: Dictionary=_employment[w]
	assert(job.business==b and job.wage is int and job.wage>=1 and job.wage<=20)
	return job.wage
func _allowed_employee_salary(w: String,b: String) -> bool:
	if wage_arm=="fixed10_instrumented":return super(w,b)
	var job: Dictionary=_employment[w];var term: Dictionary=_terms.get(_active_terms.get(w,""),{})
	return not term.is_empty() and job.wage is int and job.wage>=1 and job.wage<=20 and term.wage==job.wage and job.contract=={"cycle_days":1,"shifts_per_cycle":1,"cycle_compensation":job.wage,"phases":[1]}
func _on_recorded_event(e: Dictionary) -> void:
	super(e)
	if e.action=="consumer_decision" and e.actor in _wage_anchors:
		var d: Dictionary=e.details
		if not _wage_shopping.has(e.actor):_wage_shopping[e.actor]=[]
		_wage_shopping[e.actor].append({"day":e.day,"minute":e.minute,"source_event_id":e.id,"item":d.item,"purchased":d.purchased,"price":d.observation.prices.get(d.item,null),"money_before":d.observation.money,"reason":d.proposal.reason,"success":e.success})
		_wage_shopping[e.actor]=_wage_shopping[e.actor].slice(-6)
	if not e.success:return
	if e.action=="spatial_encounter" and e.details.kind=="inspected" and e.actor in _wage_anchors:
		if not _wage_quotes.has(e.actor):_wage_quotes[e.actor]={}
		for q in public_quotes():
			if q.seller==e.target and q.item in ["bread","ale"] and q.active:
				_wage_quotes[e.actor][q.item]={"quote":q.duplicate(true),"inspection_event_id":e.id,"day":e.day,"minute":e.minute}
	if e.action=="employment_started":
		_wage_anchors[e.actor]={"wage":e.details.job.wage,"term":_active_terms[e.actor],"source_event_id":e.id}
		if wage_arm=="worker_bids":
			var bid: Dictionary=_wage_bids[_wage_offers[e.details.posting].bid]
			assert(bid.wage==e.details.job.wage)
			bid.status="hired";bid["term"]=_active_terms[e.actor];bid["employment_event_id"]=e.id
			_record("wage_contract_started",e.actor,e.target,true,{"bid":bid.id,"term":bid.term,"employment_event_id":e.id,"wage":bid.wage})
func _retained_salaries(b: String) -> Array:
	var rows: Array=[]
	for w in _active_staff(b):
		if _employment[w].end_day>_day+1:rows.append({"id":w,"wage":_employment[w].wage,"term":_active_terms[w],"end_day":_employment[w].end_day})
	return rows
func _wage_context(b: String) -> Dictionary:
	return {"business":b,"role":_businesses[b].industry,"schedule":Brew.WINDOWS[b].duplicate(),"term_days":3,"guaranteed_days":1,"minimum_wage":1,"maximum_wage":20}
func _wage_observation(w: String) -> Dictionary:
	var j: Dictionary=_employment.get(w,{})
	var owed: int=0
	for c in _obligations.values():
		if c.worker==w:owed+=c.amount-c.paid
	return {"worker":w,"day":_day,"minute":_space.minute,"money":_entities[w].money,"inventory":_entities[w].inventory.duplicate(),"bread_eaten":_meals.has(w),"ale_drunk":_drunk.has(w),"business":_affiliations.get(w,{}).get("business",""),"end_day":j.get("end_day",0),"eligible":not j.get("active",false) or j.end_day==_day+1,"anchor":_wage_anchors[w].duplicate(true),"quotes":_wage_quotes.get(w,{}).duplicate(true),"history":_wage_memory.get(w,[]).duplicate(true),"wage_history":super.worker_observation(w).history,"owed_wages":owed,"current_term":_terms.get(_active_terms.get(w,""),{}).duplicate(true),"shopping_history":_wage_shopping.get(w,[]).duplicate(true),"notices":_wage_known.get(w,{}).get("notices",[]).duplicate(true),"notice_event_id":_wage_known.get(w,{}).get("event_id",null),"unobservables":["other_bids","firm_cash","future_sales","true_hiring_chance","guaranteed_food_stock"]}
func _bid_rows(b: String,statuses: Array=["submitted"]) -> Array:
	var rows: Array=[]
	for bid in _wage_bids.values():
		if bid.day==_day and bid.business==b and bid.status in statuses:
			rows.append({"id":bid.worker,"wage":bid.wage,"incumbent":_affiliations.get(bid.worker,{}).get("business","")==b,"bid":bid.id})
	return rows
func _portfolio(b: String,rows: Array) -> Dictionary:
	var o: Dictionary=vacancy_observation(Brew.OWNERS[b],b)
	var id: String="wage_notice:%04d:%s"%[_day,b]
	if _wage_notices.has(id):o.capacity=mini(o.capacity,o.retained+_wage_notices[id].vacancies)
	return {"observation":o,"retained":_retained_salaries(b),"proposal":Wages.select(o,_retained_salaries(b),rows)}
func advertise(owner: String,b: String) -> bool:
	if wage_arm=="fixed10_instrumented":
		var ok: bool=super(owner,b)
		if ok and _at_board(owner):
			var o: Dictionary=vacancy_observation(owner,b);var virtual: Array=[]
			for i in o.capacity-o.retained:virtual.append({"id":"slot:%d"%i,"wage":1,"incumbent":false})
			_record("wage_fixed_admission_observed",owner,b,true,{"observation":o,"retained":_retained_salaries(b),"minimum_wage":Wages.select(o,_retained_salaries(b),virtual)})
		return ok
	if not _at_board(owner) or Brew.OWNERS.get(b,"")!=owner:return _reject("wage_notice_posted",owner,b,{},"owner_not_at_board")
	var id: String="wage_notice:%04d:%s"%[_day,b]
	if _wage_notices.has(id):return _reject("wage_notice_posted",owner,b,{},"daily_notice_limit")
	var o: Dictionary=vacancy_observation(owner,b);var virtual: Array=[]
	for i in o.capacity-o.retained:virtual.append({"id":"slot:%d"%i,"wage":1,"incumbent":false})
	var plan: Dictionary=Wages.select(o,_retained_salaries(b),virtual)
	_record("wage_vacancy_assessed",owner,b,true,{"observation":o,"retained":_retained_salaries(b),"proposal":plan})
	if plan.selected.is_empty():return true
	var notice={"id":id,"business":b,"employer":owner,"day":_day,"start_day":_day+1,"end_day":_day+4,"vacancies":plan.selected.size(),"context":_wage_context(b),"active":true,"assessment_event_id":_events.back().id}
	_wage_notices[id]=notice
	_record("wage_notice_posted",owner,b,true,{"notice":notice.duplicate(true)})
	return true
func _observe_past_bids(w: String) -> void:
	for bid in _wage_bids.values():
		if bid.worker!=w or bid.day>=_day or bid.has("observation_event_id"):continue
		var close: Dictionary=_wage_settlements.get(bid.notice,{})
		if close.is_empty():continue
		var outcome: String="hired" if bid.status=="hired" else "lost_filled" if bid.status=="submitted" and close.filled>0 else "unknown"
		var row={"bid":bid.id,"business":bid.business,"context":bid.context.duplicate(true),"wage":bid.wage,"outcome":outcome,"bid_event_id":bid.bid_event_id,"closure_event_id":close.event_id,"day":_day}
		_record("wage_outcome_observed",w,bid.business,true,row)
		bid["observation_event_id"]=_events.back().id;row["observation_event_id"]=_events.back().id
		if outcome!="unknown":
			if not _wage_memory.has(w):_wage_memory[w]=[]
			_wage_memory[w].append(row.duplicate(true));_wage_memory[w]=_wage_memory[w].slice(-6)
func inspect_jobs(w: String) -> Dictionary:
	if wage_arm=="fixed10_instrumented":
		var old: Dictionary=super(w)
		if _at_board(w) and w in _wage_anchors:
			var own: Dictionary=_wage_observation(w);own.notices=old.notices;own.notice_event_id=old.event_id
			_record("wage_fixed_worker_observed",w,"bakery",true,{"observation":own,"native_observation_event_id":old.event_id})
		return old
	if not _at_board(w) or w not in _wage_anchors:
		_reject("wage_board_observed",w,"bakery",{},"not_at_local_meeting");return {"notices":[],"event_id":null}
	_observe_past_bids(w)
	var ids: Array=_wage_notices.keys();ids.sort();var notices: Array=[]
	for id in ids:
		if _wage_notices[id].day==_day and _wage_notices[id].active:notices.append(_wage_notices[id].duplicate(true))
	_record("wage_board_observed",w,"bakery",true,{"notices":notices,"witnesses":_witnesses(Brew.SITES.bakery)})
	_wage_known[w]={"day":_day,"event_id":_events.back().id,"notices":notices.duplicate(true)}
	return _wage_known[w].duplicate(true)
func search_job(w: String) -> bool:
	if wage_arm=="fixed10_instrumented":return super(w)
	if not _at_board(w) or w in Brew.OWNERS.values():return false
	var o: Dictionary=_wage_observation(w);var proposal: Dictionary=Wages.worker(o)
	_record("wage_worker_decision",w,proposal.notice,true,{"observation":o,"proposal":proposal})
	_wage_proposals[w]={"day":_day,"event_id":_events.back().id,"notice":proposal.notice,"wage":proposal.wage}
	return submit_wage_bid(w,proposal.notice,proposal.wage,o.notice_event_id) if proposal.action=="bid" else true
func submit_wage_bid(w: String,id: String,wage: Variant,source: Variant) -> bool:
	var reason: String="";var n: Dictionary=_wage_notices.get(id,{})
	if wage_arm!="worker_bids" or not _at_board(w) or not _wage_anchors.has(w):reason="not_eligible_local_worker"
	elif not wage is int or wage<1 or wage>20:reason="invalid_wage"
	elif n.is_empty() or not n.active or n.day!=_day or not _wage_known.get(w,{}).get("notices",[]).any(func(row):return row==n):reason="unobserved_or_closed_notice"
	elif not source is int or source!=_wage_known[w].event_id:reason="invalid_observation_source"
	elif _wage_selected.get(n.business,{}).get("day",-1)==_day:reason="selection_window_closed"
	elif not _wage_observation(w).eligible or _pending_hires.has(w) or _resignations.has(w):reason="binding_or_exclusive_commitment"
	elif _wage_bids.values().any(func(row):return row.worker==w and row.day==_day):reason="daily_bid_limit"
	if not reason.is_empty():return _reject("wage_bid_submitted",w,id,{"wage":wage,"source_event_id":source},reason)
	var bid={"id":"wage_bid:%04d:%s"%[_day,w],"worker":w,"business":n.business,"notice":id,"context":n.context.duplicate(true),"day":_day,"wage":wage,"source_event_id":source,"decision_event_id":_wage_proposals[w].event_id if _wage_proposals.get(w,{}).get("day",-1)==_day and _wage_proposals[w].notice==id and _wage_proposals[w].wage==wage else null,"status":"submitted"}
	_wage_bids[bid.id]=bid
	_record("wage_bid_submitted",w,n.business,true,{"bid":bid.duplicate(true)})
	bid["bid_event_id"]=_events.back().id
	return true
func _valid_private_offer(w: String,p: Dictionary) -> String:
	var origin: Dictionary=_wage_offers.get(p.get("id",""),{});var bid: Dictionary=_wage_bids.get(origin.get("bid",""),{})
	if bid.is_empty() or bid.worker!=w or bid.business!=p.business or bid.wage!=p.wage:return "signed_bid_terms_changed"
	if not p.wage is int or p.wage<1 or p.wage>20 or p.cycle_days!=1 or p.guaranteed_shifts!=1 or p.duration_days!=3 or not p.required_skills.is_empty():return "invalid_wage_terms"
	if bid.day!=_day or not _wage_notices[bid.notice].active or not p.active or p.reserved<1:return "expired_or_closed_notice"
	if _employment.get(w,{}).get("active",false) and _employment[w].end_day>_day+1:return "binding_term_active"
	return ""
func _accepted_portfolio(b: String,extra: String="") -> Dictionary:
	var rows: Array=[]
	for bid in _wage_bids.values():
		if bid.day==_day and bid.business==b and (bid.status in ["offered","accepted"] or bid.worker==extra):rows.append({"id":bid.worker,"wage":bid.wage,"incumbent":_affiliations.get(bid.worker,{}).get("business","")==b,"bid":bid.id})
	return _portfolio(b,rows)
func _entry_reason(w: String,p: Dictionary) -> String:
	if wage_arm=="fixed10_instrumented":return super(w,p)
	var reason: String=_valid_private_offer(w,p)
	if not reason.is_empty():return reason
	var packet: Dictionary=_accepted_portfolio(p.business,w)
	var required: Array=_bid_rows(p.business,["offered","accepted"]).map(func(row):return row.id)
	if w not in required:required.append(w)
	return "changed_capacity_or_funding" if not required.all(func(id):return id in packet.proposal.selected) else ""
func consider_applicants(owner: String,b: String) -> void:
	if wage_arm=="fixed10_instrumented":super(owner,b);return
	if not _at_board(owner) or Brew.OWNERS.get(b,"")!=owner:return
	if _wage_selected.get(b,{}).get("day",-1)==_day:
		_reject("wage_portfolio_selected",owner,b,{},"daily_selection_limit");return
	var rows: Array=_bid_rows(b);var packet: Dictionary=_portfolio(b,rows)
	_record("wage_portfolio_selected",owner,b,true,packet)
	var selection: int=_events.back().id
	_wage_selected[b]={"day":_day,"event_id":selection}
	for w in packet.proposal.selected:
		var bid: Dictionary=_wage_bids["wage_bid:%04d:%s"%[_day,w]]
		_make_wage_offer(owner,bid.id,selection)
func _make_wage_offer(owner: String,id: String,selection: Variant) -> bool:
	var bid: Dictionary=_wage_bids.get(id,{});var reason: String=""
	if bid.is_empty() or bid.status!="submitted":reason="no_live_bid"
	elif bid.day!=_day or not _wage_notices[bid.notice].active:reason="expired_or_closed_notice"
	elif Brew.OWNERS.get(bid.business,"")!=owner or not _at_board(owner) or not _at_board(bid.worker):reason="parties_not_at_board"
	elif not selection is int or selection<1 or selection>_events.size():reason="invalid_selection_receipt"
	else:
		var e: Dictionary=_events[selection-1]
		if not e.success or e.action!="wage_portfolio_selected" or e.actor!=owner or e.target!=bid.business or e.day!=_day or _wage_selected.get(bid.business,{}).get("event_id",0)!=selection or bid.worker not in e.details.proposal.selected:reason="unselected_bid"
	if not reason.is_empty():return _reject("wage_offer_rejected",owner,id,{},reason)
	var packet: Dictionary=_portfolio(bid.business,_bid_rows(bid.business,["submitted","offered","accepted"]))
	if bid.worker not in packet.proposal.selected:return _reject("wage_offer_rejected",owner,id,{},"changed_capacity_or_funding")
	var post: String="wage_contract:%04d:%s:%s"%[_day,bid.business,bid.worker]
	var app: String=post+":"+bid.worker
	if _postings.has(post) or _pending_hires.has(bid.worker) or _resignations.has(bid.worker):return _reject("wage_offer_rejected",owner,id,{},"duplicate_or_exclusive_offer")
	var p={"id":post,"employer":owner,"business":bid.business,"role":_businesses[bid.business].industry,"wage":bid.wage,"guaranteed_shifts":1,"cycle_days":1,"duration_days":3,"required_skills":[],"vacancies":1,"reserved":0,"filled":0,"active":true}
	_wage_offers[post]={"bid":id,"selection_event_id":selection,"application_id":app}
	_postings[post]=p;_record("job_posted",owner,bid.business,true,{"posting":p.duplicate(true)})
	_applications[app]={"id":app,"worker":bid.worker,"posting":post,"status":"applied"}
	_record("application_submitted",bid.worker,bid.business,true,{"application":_applications[app].duplicate(true)})
	_applications[app].status="offered";p.reserved=1;bid.status="offered";bid["application_id"]=app
	_record("job_offer_made",owner,bid.business,true,{"application_id":app,"worker":bid.worker,"posting":post})
	return true
func job_board(w: String) -> Array:
	return super(w) if wage_arm=="fixed10_instrumented" else _wage_known.get(w,{}).get("notices",[]).duplicate(true)
func inspect_job_offers(w: String) -> Array:
	if wage_arm=="fixed10_instrumented":return super(w)
	if not _at_board(w):return []
	var offers: Array=[]
	for p in _wage_offers:
		var app: String=_wage_offers[p].application_id
		if _applications[app].worker==w and _applications[app].status=="offered" and _postings[p].active:offers.append({"application_id":app,"terms":_postings[p].duplicate(true),"bid":_wage_offers[p].bid})
	_record("wage_offer_observed",w,"bakery",true,{"offers":offers})
	if not offers.is_empty():_wage_known[w]["offer_event_id"]=_events.back().id
	return offers
func respond_to_offers(w: String) -> void:
	if wage_arm=="fixed10_instrumented":super(w);return
	var offers: Array=inspect_job_offers(w)
	if offers.is_empty():return
	var offer: Dictionary=offers[0];var source: int=_wage_known[w].offer_event_id
	var o: Dictionary=_wage_observation(w);var request: Dictionary=_wage_bids[offer.bid]
	var proposal: Dictionary=Wages.acceptance(o,offer,request)
	_record("wage_acceptance_decision",w,request.business,true,{"observation":o,"offer_event_id":source,"proposal":proposal})
	if proposal.accepts:accept_wage_offer(w,offer.application_id,source)
	else:decline_wage_offer(w,offer.application_id,source)
func decline_offer(w: String,app: String) -> bool:
	return super(w,app) if wage_arm=="fixed10_instrumented" else decline_wage_offer(w,app,_wage_known.get(w,{}).get("offer_event_id",null))
func decline_wage_offer(w: String,app: String,source: Variant) -> bool:
	var a: Dictionary=_applications.get(app,{})
	if wage_arm!="worker_bids" or not _at_board(w) or a.is_empty() or a.worker!=w or a.status!="offered" or not source is int or source!=_wage_known.get(w,{}).get("offer_event_id",null):return _reject("wage_offer_declined",w,app,{},"unobserved_or_unavailable_offer")
	var p: Dictionary=_postings[a.posting]
	if not p.active or p.reserved<1:return _reject("wage_offer_declined",w,app,{},"unavailable_offer")
	a.status="declined";p.reserved=0;p.active=false;_wage_bids[_wage_offers[p.id].bid].status="declined"
	_record("wage_offer_declined",w,p.business,true,{"application_id":app,"source_event_id":source})
	return true
func accept_wage_offer(w: String,app: String,source: Variant) -> bool:
	var a: Dictionary=_applications.get(app,{});var reason: String=""
	if wage_arm!="worker_bids" or a.is_empty() or a.worker!=w or a.status!="offered" or _pending_hires.has(w) or _resignations.has(w):reason="no_exclusive_offer"
	elif not _at_board(w) or not _at_board(_postings[a.posting].employer):reason="parties_not_at_board"
	elif not source is int or source!=_wage_known.get(w,{}).get("offer_event_id",null):reason="unobserved_offer"
	else:reason=_entry_reason(w,_postings[a.posting])
	if not reason.is_empty():return _reject("offer_accepted",w,app,{},reason)
	var p: Dictionary=_postings[a.posting];var origin: Dictionary=_wage_offers[a.posting];var bid: Dictionary=_wage_bids[origin.bid]
	a.status="accepted";bid.status="accepted"
	_pending_hires[w]={"posting":p.id,"application_id":app,"effective_day":_day+1}
	_record("offer_accepted",w,p.business,true,{"application_id":app,"pending":_pending_hires[w].duplicate(true)})
	_contingent[w]={"application_id":app,"posting":p.id,"old":_affiliations.get(w,{}).duplicate(),"effective_day":_day+1}
	_record("labor_transfer_scheduled",w,p.business,true,_contingent[w])
	return true
func post_job(owner: String,b: String,id: String,wage: Variant,minimum: Variant,cycle: Variant,duration: Variant,vacancies: Variant=1) -> bool:
	return super(owner,b,id,wage,minimum,cycle,duration,vacancies) if wage_arm=="fixed10_instrumented" else _reject("job_posted",owner,b,{},"wage_bid_required")
func apply_for_job(w: String,id: String) -> bool:
	return super(w,id) if wage_arm=="fixed10_instrumented" else _reject("application_submitted",w,id,{},"wage_bid_required")
func make_job_offer(owner: String,id: String) -> bool:
	return super(owner,id) if wage_arm=="fixed10_instrumented" else _reject("job_offer_made",owner,id,{},"wage_bid_required")
func accept_job_offer(w: String,id: String) -> bool:
	return super(w,id) if wage_arm=="fixed10_instrumented" else _reject("offer_accepted",w,id,{},"wage_bid_required")
func _cancel_wage_pending(b: String,reason: String,source: int) -> void:
	for w in _pending_hires.keys():
		var pending: Dictionary=_pending_hires[w];var p: Dictionary=_postings[pending.posting]
		if p.business!=b:continue
		_pending_hires.erase(w);_contingent.erase(w);_resignations.erase(w)
		_applications[pending.application_id].status="closed";p.reserved=0;p.active=false
		_wage_bids[_wage_offers[p.id].bid].status="cancelled"
		_record("wage_pending_cancelled",w,b,true,{"pending":pending,"reason":reason,"validation_event_id":source})
func cancel_notice(owner: String,id: String) -> bool:
	return super(owner,id) if wage_arm=="fixed10_instrumented" else cancel_wage_notice(owner,id)
func cancel_wage_notice(owner: String,id: String) -> bool:
	if not _at_board(owner) or not _wage_notices.has(id) or _wage_notices[id].employer!=owner:return _reject("wage_notice_cancelled",owner,id,{},"not_owner_at_board")
	if not _wage_notices[id].active or _wage_notices[id].day!=_day:return _reject("wage_notice_cancelled",owner,id,{},"expired_or_closed_notice")
	_wage_notices[id].active=false
	_record("wage_notice_cancelled",owner,id,true,{"notice":id})
	_cancel_wage_pending(_wage_notices[id].business,"withdrawn",_events.back().id)
	return true
func _apply_boundary(next_day: int) -> void:
	if wage_arm=="fixed10_instrumented":super(next_day);return
	if _processed_boundary==_day:return
	for p in _wage_offers:
		var origin: Dictionary=_wage_offers[p];var bid: Dictionary=_wage_bids[origin.bid]
		if bid.day==_day and bid.status=="offered":
			_applications[origin.application_id].status="closed";_postings[p].active=false;_postings[p].reserved=0;bid.status="unaccepted"
			_record("wage_offer_expired",bid.worker,bid.business,true,{"bid":bid.id,"application_id":origin.application_id})
	for b in Brew.ORDER:
		var rows: Array=_bid_rows(b,["accepted"])
		if rows.is_empty():continue
		var reason: String=""
		for row in rows:
			var pending: Dictionary=_pending_hires[row.id];var p: Dictionary=_postings[pending.posting]
			reason=_entry_reason(row.id,p)
			if not reason.is_empty():break
		var packet: Dictionary=_accepted_portfolio(b)
		_record("wage_boundary_assessed",Brew.OWNERS[b],b,true,{"packet":packet,"reason":reason})
		if not reason.is_empty():_cancel_wage_pending(b,reason,_events.back().id)
	super(next_day)
	for n in _wage_notices.values():
		if n.day!=_day or _wage_settlements.has(n.id):continue
		var hires: Array=_wage_bids.values().filter(func(bid):return bid.notice==n.id and bid.status=="hired")
		n.active=false
		var row={"notice":n.id,"filled":hires.size(),"status":"filled" if hires.size()==n.vacancies else "partially_filled" if not hires.is_empty() else "closed_without_hire","day":_day,"source_ids":hires.map(func(bid):return bid.employment_event_id)}
		_record("wage_notice_settled",n.employer,n.business,true,row)
		row["event_id"]=_events.back().id;_wage_settlements[n.id]=row
