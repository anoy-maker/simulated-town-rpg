extends "res://scripts/sim/brewery_world.gd"
## M24-only fungible labor/local notices; native employment/payroll remain authoritative.
const Market=preload("res://scripts/sim/labor_market_policy.gd")
const MarketConfig=preload("res://scripts/sim/labor_market_config.gd")
var mode: String
var tie: String
var fixture: String
var _notices: Dictionary={}
var _known_jobs: Dictionary={}
var _known_offers: Dictionary={}
var _contingent: Dictionary={}
var _history: Dictionary={}
var _sales: Dictionary={}
var _input_terms: Dictionary={}
var _in_boundary: bool=false

func _init(seed_value: int=42, condition: String="reference", selected_mode: String="matching", selected_tie: String="neutral_rotate", selected_fixture: String="none") -> void:
	assert(selected_mode in MarketConfig.MODES and selected_tie in MarketConfig.TIES)
	mode=selected_mode;tie=selected_tie;fixture=selected_fixture
	super(seed_value,condition,_labor_market_initial(fixture))
func _labor_market_initial(selected_fixture: String) -> Dictionary:return MarketConfig.initial(selected_fixture)
func _job_duration() -> int:return 30
func _labor_qualified(worker: String, _industry: String) -> bool:
	return _entities.has(worker) and _entities[worker].kind=="resident" and worker not in Brew.OWNERS.values()
func _posting_skills(_business: String) -> Array:return []
func _initial_space(economy: Dictionary, condition: String) -> Dictionary:
	var space: Dictionary=Brew.space(economy,condition)
	for id in space.presences:
		if id in Brew.OWNERS.values():continue
		var job: Dictionary=economy.employment.get(id,{})
		var business: String=job.business if job.get("active",false) else ""
		space.presences[id].schedule.merge(_schedule_fields(business,space.presences[id].home),true)
	return space
func _schedule_fields(business: String, home: Array) -> Dictionary:
	return {"business":business,"first_destination":home.duplicate() if business.is_empty() else Brew.SITES[business].duplicate(),
		"work_start":0 if business.is_empty() else Brew.WINDOWS[business][0],"work_end":0 if business.is_empty() else Brew.WINDOWS[business][1],"owner":false,"courier":{}}
func _active_staff(business: String) -> Array:
	var ids: Array=[]
	for id in _businesses[business].employees:
		if _employment.has(id) and _employment[id].active and _employment[id].business==business and _affiliations.get(id,{})=={"business":business,"kind":"employee"}:ids.append(id)
	ids.sort();return ids
func _workers(business: String) -> Array:
	var rows: Array=[]
	for id in _active_staff(business):rows.append({"id":id,"wage":_wage(id,business),"available":_labor_qualified(id,_businesses[business].industry) and _labor_used.get(id,0)==0 and _available(id) and _at(id,Brew.SITES[business])})
	return Market.order(rows,_day,tie)
func _shift_error(worker: String, business: String) -> String:
	var reason: String=super(worker,business)
	if reason.is_empty() and (_employment[worker].wage!=10 or worker in Brew.OWNERS.values()):return "fixed_wage_employee_required"
	return reason
func snapshot() -> Dictionary:
	return super().merged({"labor_market":{"mode":mode,"tie":tie,"fixture":fixture,"homogeneous":true,"notices":_notices.duplicate(true),"known_jobs":_known_jobs.duplicate(true),"known_offers":_known_offers.duplicate(true),"contingent":_contingent.duplicate(true),"history":_history.duplicate(true),"sales":_sales.duplicate(true),"input_terms":_input_terms.duplicate(true)}})
func _on_recorded_event(e: Dictionary) -> void:
	# Native boundaries precede day_started. Stamp the same midnight instant as the
	# closed day's24:00, never the old day00:00 after it has already finished.
	if _in_boundary:
		e.day=_day;e.minute=1440 if _day>0 else 0;e.absolute_minute=_day*1440
	super(e)
	if e.action=="day_started":
		_known_jobs.clear();_known_offers.clear()
		for day in _history.keys():
			if day<_day-2:_history.erase(day)
		for day in _sales.keys():
			if day<_day-1:_sales.erase(day)
	if e.success and e.action=="business_plan":e.details["selection"]=Market.selection(e.details.observation,e.details.proposal,tie)
	if e.success and e.action=="purchase":
		if not _sales.has(e.day):_sales[e.day]={}
		_sales[e.day][e.target]=_sales[e.day].get(e.target,0)+e.details.quantity
	if e.action in ["contract_due","work_shift","contract_shift"] and _entities.has(e.actor) and _entities[e.actor].kind=="resident":
		if not _history.has(e.day):_history[e.day]={}
		if not _history[e.day].has(e.actor):_history[e.day][e.actor]={"day":e.day,"due":0,"paid":0,"due_event_id":null,"wage_event_id":null,"shift_event_id":null,"closure_event_id":null}
		var h: Dictionary=_history[e.day][e.actor]
		if e.action=="contract_due" and e.success:h.due+=1;h.due_event_id=e.id
		if e.action=="work_shift" and e.success:h.paid+=1;h.wage_event_id=e.details.payment_event_id;h.shift_event_id=e.id
		if e.action=="contract_shift":h.closure_event_id=e.id
	if e.success and e.action in ["employment_ended","employment_started"]:
		var removed: Array=[]
		var business: String=_affiliations.get(e.actor,{}).get("business","")
		for id in Brew.ORDER:
			if id!=business and e.actor in _businesses[id].employees:_businesses[id].employees.erase(e.actor);removed.append(id)
		var schedule: Dictionary=_space.presences[e.actor].schedule
		schedule.merge(_schedule_fields(business,_space.presences[e.actor].home),true)
		_record("labor_assignment",e.actor,business,true,{"employment_event_id":e.id,"removed_from":removed,"schedule":schedule.duplicate(true)})
func _at_board(id: String) -> bool:
	return mode=="matching" and _space.minute==955 and _space.presences.has(id) and _space.presences[id].kind=="resident" and _at(id,Brew.SITES.bakery) and _space.presences[id].activity=="board" and _space.presences[id].until==960
func begin_board(id: String) -> bool:
	if mode!="matching" or _space.minute!=955 or not _space.presences.has(id) or _space.presences[id].kind!="resident" or not _at(id,Brew.SITES.bakery):return _reject("labor_board_entered",id,"bakery",{},"not_at_local_meeting")
	return _begin(id,"board",5,"bakery")
func _reserved(business: String) -> int:
	var n: int=0
	for p in _postings.values():
		if p.business==business and p.active:n+=p.reserved
	return n
func inspect_offers(id: String, seller: String) -> Dictionary:
	var result: Dictionary=super(id,seller)
	if result.success:
		for business in Brew.ORDER:
			if Brew.OWNERS[business]!=id:continue
			var input: String=Brew.INDUSTRIES[_businesses[business].industry].input
			for q in result.offers:
				if q.item==input:_input_terms[business]={"day":_day,"inspection_event_id":_events.back().id,"quote":q.duplicate(true)}
	return result
func vacancy_observation(owner: String, business: String) -> Dictionary:
	assert(_businesses.has(business) and _businesses[business].owner==owner)
	var production: Dictionary=business_observation(owner,business,true)
	if not production.rule.input.is_empty() and _input_terms.has(business):
		production.input_quote=_input_terms[business].quote.duplicate(true)
		production.input_price=production.input_quote.unit_price
		production.allow_procurement=true
	var previous: int=_sales.get(_day-1,{}).get(business,production.rule.target if _day<=1 else 0)
	return {"owner":owner,"business":business,"day":_day,"production":production,"previous_sales":previous,
		"staff":_active_staff(business),"reserved":_reserved(business),"capacity":_asset_capacity(business),"farm_cap":Brew.CASES[_experiment] if business=="farm" else 0,"disabled":_experiment=="no_brew_request" and business=="brewery"}
func _assessment(business: String) -> Dictionary:
	return Market.vacancy(vacancy_observation(_businesses[business].owner,business))
func advertise(owner: String, business: String) -> bool:
	if not _at_board(owner) or not _businesses.has(business) or _businesses[business].owner!=owner:return _reject("labor_vacancy_assessed",owner,business,{},"owner_not_at_board")
	var o: Dictionary=vacancy_observation(owner,business);var proposal: Dictionary=Market.vacancy(o)
	_record("labor_vacancy_assessed",owner,business,true,{"observation":o,"proposal":proposal})
	if proposal.vacancies==0:return true
	return post_job(owner,business,"notice:%04d:%s"%[_day,business],10,1,1,30,proposal.vacancies)
func post_job(owner: String, business: String, id: String, wage: Variant, minimum: Variant, cycle: Variant, duration: Variant, vacancies: Variant=1) -> bool:
	var reason: String=""
	if not _at_board(owner) or not _businesses.has(business) or _businesses[business].owner!=owner:reason="owner_not_at_board"
	elif wage!=10 or not wage is int or minimum!=1 or cycle!=1 or duration!=_job_duration() or not vacancies is int or vacancies<1:reason="fixed_terms_required"
	elif vacancies>_assessment(business).vacancies:reason="no_funded_positive_vacancy"
	elif _notices.values().any(func(n):return n.business==business and n.day==_day):reason="daily_notice_limit"
	if not reason.is_empty():return _reject("job_posted",owner,business,{"id":id},reason)
	if not super(owner,business,id,wage,minimum,cycle,duration,vacancies):return false
	var receipt: int=_events.back().id
	_notices[id]={"id":id,"business":business,"day":_day,"latest_start":_day+1,"schedule":Brew.WINDOWS[business].duplicate(),"status":"open"}
	_record("labor_notice_opened",owner,business,true,{"posting_event_id":receipt,"notice":_notices[id].duplicate(true)})
	return true
func _public_notice(id: String) -> Dictionary:
	return _postings[id].duplicate(true).merged({"posted_day":_notices[id].day,"latest_start":_notices[id].latest_start,"schedule":_notices[id].schedule.duplicate()})
func job_board(actor: String) -> Array:
	return _known_jobs.get(actor,{}).get("notices",[]).duplicate(true)
func inspect_jobs(actor: String) -> Dictionary:
	if not _at_board(actor):
		_reject("labor_notices_observed",actor,"bakery",{},"not_at_local_meeting")
		return {"notices":[],"event_id":null}
	var ids: Array=_notices.keys();ids.sort();var notices: Array=[]
	for id in ids:
		if _postings[id].active and _notices[id].day==_day:notices.append(_public_notice(id))
	_record("labor_notices_observed",actor,"bakery",true,{"notices":notices,"witnesses":_witnesses(Brew.SITES.bakery)})
	_known_jobs[actor]={"day":_day,"event_id":_events.back().id,"notices":notices.duplicate(true)}
	return _known_jobs[actor].duplicate(true)
func _eligible_applicant(worker: String, posting: Dictionary) -> String:
	if not _entities.has(worker) or _entities[worker].kind!="resident":return "not_resident"
	if worker in Brew.OWNERS.values():return "management_only"
	if _pending_hires.has(worker) or _resignations.has(worker):return "already_committed"
	if _affiliations.get(worker,{}).get("business","")==posting.business:return "same_employer"
	if posting.wage!=10 or not posting.required_skills.is_empty():return "invalid_fixed_labor_terms"
	return ""
func apply_for_job(worker: String, id: String) -> bool:
	var known: Array=job_board(worker)
	if not _at_board(worker) or not known.any(func(n):return n.id==id):return _reject("application_submitted",worker,id,{},"unobserved_or_remote_notice")
	return super(worker,id)
func worker_observation(worker: String) -> Dictionary:
	assert(_entities.has(worker) and _entities[worker].kind=="resident")
	var history: Array=[];var days: Array=_history.keys();days.sort()
	for day in days:
		if day>=_day-2 and _history[day].has(worker):history.append(_history[day][worker].duplicate(true))
	return {"worker":worker,"day":_day,"business":_affiliations.get(worker,{}).get("business",""),"history":history,"notices":job_board(worker),"notice_event_id":_known_jobs.get(worker,{}).get("event_id",null)}
func search_job(worker: String) -> bool:
	if not _at_board(worker) or worker in Brew.OWNERS.values():return false
	var o: Dictionary=worker_observation(worker);var proposal: Dictionary=Market.search(o)
	_record("labor_search_decision",worker,proposal.posting,true,{"observation":o,"proposal":proposal})
	return apply_for_job(worker,proposal.posting) if proposal.action=="apply" else true
func make_job_offer(owner: String, application_id: String) -> bool:
	if not _applications.has(application_id):return _reject("job_offer_made",owner,application_id,{},"unknown_application")
	var a: Dictionary=_applications[application_id];var p: Dictionary=_postings[a.posting]
	if not _at_board(owner) or not _at_board(a.worker):return _reject("job_offer_made",owner,p.business,{},"parties_not_at_board")
	if p.employer!=owner:return _reject("job_offer_made",owner,p.business,{},"not_owner")
	if _assessment(p.business).vacancies<1:return _reject("job_offer_made",owner,p.business,{},"no_funded_positive_vacancy")
	return super(owner,application_id)
func consider_applicants(owner: String, business: String) -> void:
	if not _at_board(owner) or _businesses[business].owner!=owner:return
	var candidates: Array=[]
	for a in _applications.values():
		if _postings[a.posting].business==business and a.status=="applied" and _at_board(a.worker):candidates.append({"id":a.worker,"wage":10,"available":true,"application_id":a.id})
	var ranked: Array=Market.order(candidates,_day,tie)
	_record("labor_applicants_ranked",owner,business,true,{"candidates":ranked,"tie":tie,"reason":"equal_financial_contribution"})
	for row in ranked:
		if _assessment(business).vacancies<1:break
		make_job_offer(owner,row.application_id)
func inspect_job_offers(worker: String) -> Array:
	if not _at_board(worker):return []
	var offers: Array=[];var ids: Array=_applications.keys();ids.sort()
	for id in ids:
		var a: Dictionary=_applications[id];var p: Dictionary=_postings[a.posting]
		if a.worker==worker and a.status=="offered" and p.active and _at_board(p.employer):offers.append({"application_id":id,"posting":_public_notice(a.posting)})
	_record("labor_offers_observed",worker,"bakery",true,{"offers":offers,"witnesses":_witnesses(Brew.SITES.bakery)})
	_known_offers[worker]={"day":_day,"event_id":_events.back().id,"offers":offers.duplicate(true)}
	return offers
func _entry_reason(worker: String, posting: Dictionary) -> String:
	if not _notices.has(posting.id) or not posting.active or _notices[posting.id].latest_start!=_day+1:return "expired_or_closed_notice"
	if posting.wage!=10 or posting.cycle_days!=1 or posting.guaranteed_shifts!=1 or posting.duration_days!=30 or not posting.required_skills.is_empty():return "changed_fixed_terms"
	var o: Dictionary=vacancy_observation(posting.employer,posting.business);var p: Dictionary=Market.vacancy(o)
	if o.staff.size()+o.reserved>o.capacity or p.projected_shifts<o.staff.size()+o.reserved:return "changed_capacity_or_funding"
	return ""
func accept_job_offer(worker: String, application_id: String) -> bool:
	if not _applications.has(application_id):return _reject("offer_accepted",worker,application_id,{},"unknown_application")
	var a: Dictionary=_applications[application_id];var p: Dictionary=_postings[a.posting]
	var reason: String=""
	if a.worker!=worker:reason="not_applicant"
	elif not _at_board(worker) or not _at_board(p.employer):reason="parties_not_at_board"
	elif not _known_offers.get(worker,{}).get("offers",[]).any(func(o):return o.application_id==application_id):reason="unobserved_offer"
	else:reason=_entry_reason(worker,p)
	if not reason.is_empty():return _reject("offer_accepted",worker,p.business,{},reason)
	var old: Dictionary=_affiliations.get(worker,{}).duplicate()
	if not super(worker,application_id):return false
	_contingent[worker]={"application_id":application_id,"posting":p.id,"old":old,"effective_day":_day+1}
	if not old.is_empty():assert(request_resignation(worker,old.business))
	_record("labor_transfer_scheduled",worker,p.business,true,_contingent[worker])
	return true
func request_resignation(worker: String, business: String) -> bool:
	if not _contingent.has(worker) or not _pending_hires.has(worker):return _reject("resignation_requested",worker,business,{},"contingent_offer_required")
	return super(worker,business)
func respond_to_offers(worker: String) -> void:
	var offers: Array=inspect_job_offers(worker)
	var o: Dictionary=worker_observation(worker);var accepts: bool=Market.accept(o)
	_record("labor_acceptance_decision",worker,"",true,{"observation":o,"offers_event_id":_known_offers.get(worker,{}).get("event_id",null),"accepts":accepts and not offers.is_empty(),"reason":"no_observed_offer" if offers.is_empty() else "strict_income_improvement" if accepts else "status_quo_wins"})
	if accepts and not offers.is_empty():accept_job_offer(worker,offers[0].application_id)
func _close_notice(id: String, reason: String) -> void:
	var p: Dictionary=_postings[id];var canceled: Array=[];var applications: Array=[]
	for a in _applications.values():
		if a.posting!=id or a.status=="started":continue
		if _pending_hires.get(a.worker,{}).get("application_id","")==a.id:
			_pending_hires.erase(a.worker);_resignations.erase(a.worker);_contingent.erase(a.worker);canceled.append(a.worker)
		a.status="closed";applications.append(a.duplicate(true))
	p.active=false;p.reserved=0;_notices[id].status=reason
	_record("labor_notice_closed",p.employer,p.business,true,{"posting":id,"reason":reason,"canceled_pending":canceled,"applications":applications,"state":p.duplicate(true)})
func cancel_notice(owner: String, id: String) -> bool:
	if not _postings.has(id) or _postings[id].employer!=owner or not _at_board(owner):return _reject("labor_notice_closed",owner,id,{},"not_owner_at_board")
	_close_notice(id,"withdrawn");return true
func _apply_boundary(next_day: int) -> void:
	_in_boundary=true
	var ids: Array=_notices.keys();ids.sort()
	for id in ids:
		if not _postings[id].active:continue
		var pending: Array=_pending_hires.keys().filter(func(w):return _pending_hires[w].posting==id)
		var reason: String="expired_unaccepted" if pending.is_empty() else _entry_reason(str(pending[0]),_postings[id])
		for w in pending:
			if _affiliations.get(w,{})!=_contingent[w].old or _pending_hires[w].effective_day!=next_day:reason="changed_old_affiliation"
		if not reason.is_empty():_close_notice(id,reason)
	if _day>0:_record("labor_boundary","world","",true,{"effective_day":next_day,"pending":_pending_hires.duplicate(true)})
	super(next_day)
	for worker in _contingent.keys():
		if not _pending_hires.has(worker):_contingent.erase(worker)
	for id in ids:
		if _notices[id].status=="open":_close_notice(id,"filled" if _postings[id].filled==_postings[id].vacancies else "partially_filled" if _postings[id].filled>0 else "expired")
	_in_boundary=false
