extends "res://scripts/sim/labor_market_world.gd"
## M25-only binding terms, verified attendance and earned wage claims.
const Bound=preload("res://scripts/sim/binding_config.gd")
const Planning=preload("res://scripts/sim/binding_policy.gd")
var renewal_mode: String
var _terms: Dictionary={}
var _active_terms: Dictionary={}
var _obligations: Dictionary={}
var _attendance: Dictionary={}
var _releases: Dictionary={}
var _processed_boundary: int=-1
var _wage_command: bool=false
func _init(seed_value: int=42, condition: String="reference", selected_mode: String="matching", selected_fixture: String="none") -> void:
	assert(selected_mode in Bound.MODES)
	renewal_mode=selected_mode
	var state: Dictionary=Bound.initial(selected_fixture)
	for w in state.employment:
		var j: Dictionary=state.employment[w];var id: String=_term_id(w,j.business,j.start_day)
		_terms[id]={"id":id,"worker":w,"business":j.business,"start_day":j.start_day,"end_day":j.end_day,"wage":10,"status":"active","predecessor":"","source":"initial"}
		_active_terms[w]=id
	super(seed_value,condition,"matching","neutral_rotate",selected_fixture)
func _labor_market_initial(selected_fixture: String) -> Dictionary:return Bound.initial(selected_fixture)
func _job_duration() -> int:return 3
func _term_id(w: String,b: String,start: int) -> String:return "term:%04d:%s:%s"%[start,b,w]
func _claim_id(w: String,b: String) -> String:return "%04d:%s:%s"%[_day,b,w]
func snapshot() -> Dictionary:
	return super().merged({"binding_contracts":{"mode":renewal_mode,"terms":_terms.duplicate(true),"active_terms":_active_terms.duplicate(),"obligations":_obligations.duplicate(true),"attendance":_attendance.duplicate(true),"releases":_releases.duplicate(true),"processed_boundary":_processed_boundary}})
func _unpaid_shift_wage(w: String,b: String,wage: int) -> int:
	return 0 if _obligations.get(_claim_id(w,b),{}).get("paid",0)==10 else wage
func _pay_shift_wage(w: String,b: String,_wage: int) -> int:
	var claim: Dictionary=_obligations[_claim_id(w,b)]
	assert(claim.paid==10 and claim.payments.size()==1)
	return claim.payments[0].payment_event_id
func work_shift(w: String,b: String) -> bool:
	if _obligations.get(_claim_id(w,b),{}).get("paid",0)!=10:return _reject("work_shift",w,b,{"wage":0},"guarantee_not_fully_paid")
	if _obligations[_claim_id(w,b)].payments.size()!=1:return _reject("work_shift",w,b,{"wage":0},"single_full_wage_receipt_required")
	return super(w,b)
func _pay(actor: String,target: String,amount: int,purpose: String) -> bool:
	if purpose=="wage" and not _wage_command:return _reject("transfer_money",actor,target,{"amount":amount},"verified_wage_command_required")
	return super(actor,target,amount,purpose)
func _on_recorded_event(e: Dictionary) -> void:
	super(e)
	if not e.success:return
	if e.action=="business_plan":e.details.selection.objective="incremental_receipts_minus_inputs_committed_wage_excluded"
	if e.action=="spatial_clock":
		for b in Brew.ORDER:
			if e.details.to==Brew.WINDOWS[b][1]:_verify_window(b,e.id)
	if e.action=="employment_ended":
		var id: String=_active_terms[e.actor];var term: Dictionary=_terms[id]
		term.status="released" if _releases.has(e.actor) else "expired"
		term["closed_day"]=e.details.effective_day
		_active_terms.erase(e.actor)
		_record("binding_term_closed",e.actor,e.target,true,{"term":term.duplicate(true),"employment_event_id":e.id,"release":_releases.get(e.actor,{}).duplicate(true)})
	if e.action=="employment_started":
		var predecessor: String=""
		for id in _terms:
			if _terms[id].worker==e.actor and (predecessor.is_empty() or _terms[id].start_day>_terms[predecessor].start_day):predecessor=id
		var j: Dictionary=e.details.job;var id: String=_term_id(e.actor,e.target,j.start_day)
		var term={"id":id,"worker":e.actor,"business":e.target,"start_day":j.start_day,"end_day":j.end_day,"wage":10,"status":"active","predecessor":predecessor,"source":"accepted"}
		_terms[id]=term;_active_terms[e.actor]=id
		var same: bool=not predecessor.is_empty() and _terms[predecessor].business==e.target
		var continuous: bool=same and _terms[predecessor].closed_day==j.start_day
		_record("binding_term_started",e.actor,e.target,true,{"term":term.duplicate(true),"employment_event_id":e.id,"renewed":continuous,"entry_kind":"renewal" if continuous else "rehire" if same else "new_employer"})
func begin_attendance(w: String,b: String,productive: bool) -> bool:
	var id: String=_claim_id(w,b)
	if w not in _active_staff(b) or _space.minute!=Brew.WINDOWS[b][0] or not _available(w) or not _at(w,Brew.SITES[b]) or _attendance.has(id):return _reject("binding_attendance_started",w,b,{},"not_eligible_at_due_window")
	var started: bool=productive and start_shift(w,b)
	var ok: bool=started or _begin(w,"standby",60,b)
	if not ok:return false
	var session={"id":id,"worker":w,"business":b,"term":_active_terms[w],"day":_day,"start_event_id":_events.back().id,"due_event_id":_due_receipt(w,b),"kind":"work" if started else "standby","status":"started","attendance_event_id":null,"breach_event_id":null}
	_attendance[id]=session
	_record("binding_attendance_started",w,b,true,{"session":session.duplicate(true)})
	return true
func _due_receipt(w: String,b: String) -> int:
	for e in _events.slice(_day_start):
		if e.action=="contract_due" and e.actor==w and e.target==b:return e.id
	return 0
func _verify_window(b: String,clock_id: int) -> void:
	for w in _active_staff(b):
		var id: String=_claim_id(w,b);var session: Dictionary=_attendance.get(id,{})
		var p: Dictionary=_space.presences[w]
		var attended: bool=not session.is_empty() and session.status=="started" and _at(w,Brew.SITES[b]) and p.business==b and p.activity==session.kind and p.until==_space.minute
		if attended:
			session.status="attended"
			_record("contract_attended",w,b,true,{"term":_active_terms[w],"session":id,"start_event_id":session.start_event_id,"clock_event_id":clock_id,"due_event_id":session.due_event_id,"kind":session.kind})
			session.attendance_event_id=_events.back().id
			var claim={"id":id,"worker":w,"business":b,"term":_active_terms[w],"day":_day,"minute":_space.minute,"amount":10,"paid":0,"due_event_id":session.due_event_id,"attendance_event_id":session.attendance_event_id,"payments":[],"breach_event_id":null}
			_obligations[id]=claim
			_record("guaranteed_wage_due",w,b,true,{"claim":claim.duplicate(true)})
		else:
			var absent={"id":id,"worker":w,"business":b,"term":_active_terms[w],"day":_day,"start_event_id":session.get("start_event_id",null),"due_event_id":_due_receipt(w,b),"kind":session.get("kind","absent"),"status":"absent","attendance_event_id":null,"breach_event_id":null}
			_attendance[id]=absent
			_record("binding_breach",w,b,true,{"kind":"worker_nonattendance","term":absent.term,"session":id,"clock_event_id":clock_id,"presence":p.duplicate(true),"due_event_id":absent.due_event_id})
			absent.breach_event_id=_events.back().id
	settle_wages(Brew.OWNERS[b],b)
	for w in _active_staff(b):
		var claim: Dictionary=_obligations.get(_claim_id(w,b),{})
		if not claim.is_empty() and claim.paid<10:
			_record("binding_breach",w,b,true,{"kind":"employer_unpaid","term":claim.term,"claim":claim.id,"amount_paid":claim.paid,"arrears":10-claim.paid,"clock_event_id":clock_id})
			claim.breach_event_id=_events.back().id
func _queue(b: String) -> Array:
	var ids: Array=_obligations.keys().filter(func(id):return _obligations[id].business==b and _obligations[id].paid<_obligations[id].amount)
	ids.sort();return ids
func arrears(b: String) -> int:
	var total: int=0
	for id in _queue(b):total+=_obligations[id].amount-_obligations[id].paid
	return total
func pay_obligation(owner: String,id: String,amount: Variant) -> bool:
	var reason: String="";var claim: Dictionary=_obligations.get(id,{})
	if claim.is_empty():reason="unknown_obligation"
	elif Brew.OWNERS[claim.business]!=owner:reason="not_owner"
	elif not ((_space.minute<960 and (claim.day<_day or _space.minute>=Brew.WINDOWS[claim.business][1])) or (_space.minute==1140 and _settlement_ready())):reason="outside_wage_tender"
	elif not amount is int or amount<=0 or amount>claim.amount-claim.paid:reason="invalid_or_overpaid_obligation"
	elif _queue(claim.business).front()!=id:reason="older_wage_priority"
	elif amount!=mini(claim.amount-claim.paid,mini(_entities[claim.business].money,MAX_AMOUNT-_entities[claim.worker].money)):reason="not_authorized_clearing_amount"
	if not reason.is_empty():return _reject("wage_payment_applied",owner,id,{"amount":amount},reason)
	var previous: String=_completing;_completing=owner;_wage_command=true
	var paid: bool=_pay(claim.business,claim.worker,amount,"wage")
	_wage_command=false;_completing=previous
	assert(paid)
	var payment={"payment_event_id":_events.back().id,"amount":amount,"day":_day,"minute":_space.minute}
	claim.paid+=amount;claim.payments.append(payment)
	_record("wage_payment_applied",claim.worker,claim.business,true,{"claim":id,"payment":payment,"paid":claim.paid,"arrears":claim.amount-claim.paid})
	return true
func settle_wages(owner: String,b: String) -> bool:
	if not _businesses.has(b) or Brew.OWNERS[b]!=owner:return _reject("wage_tender",owner,b,{},"not_owner")
	for id in _queue(b):
		var c: Dictionary=_obligations[id]
		var amount: int=mini(c.amount-c.paid,mini(_entities[b].money,MAX_AMOUNT-_entities[c.worker].money))
		if amount<=0:break
		if not pay_obligation(owner,id,amount):return false
	return true
func tender_early_receipts() -> void:
	if _space.minute>=960:return
	for b in Brew.ORDER:
		if _space.minute>=Brew.WINDOWS[b][1] or _queue(b).any(func(id):return _obligations[id].day<_day):settle_wages(Brew.OWNERS[b],b)
func _committed_payroll(b: String) -> int:
	var total: int=arrears(b)
	for w in _active_staff(b):
		if not _attendance.has(_claim_id(w,b)):total+=10
	return total
func _funded_workers(b: String) -> Array:
	var cash: int=_entities[b].money-arrears(b);var ids: Array=[]
	for w in _active_staff(b):
		var c: Dictionary=_obligations.get(_claim_id(w,b),{})
		if not c.is_empty():
			if c.paid==10:ids.append(w)
		elif cash>=10:ids.append(w);cash-=10
	return ids
func business_observation(owner: String,b: String,allow_procurement: bool=false) -> Dictionary:
	return super(owner,b,allow_procurement).merged({"committed_payroll":_committed_payroll(b),"funded_workers":_funded_workers(b)})
func plan_business(owner: String,b: String) -> Dictionary:
	var o: Dictionary=business_observation(owner,b);var input: String=o.rule.input
	if not input.is_empty():o.input_stock=_entities[b].inventory[input]
	var proposal: Dictionary=Planning.within(o)
	_record("business_plan",owner,b,true,{"observation":o,"proposal":proposal,"phase":"production"})
	return proposal
func propose_grain(owner: String,b: String) -> bool:
	if not inspect_offers(owner,"farm").success:return false
	var o: Dictionary=business_observation(owner,b,true);var proposal: Dictionary=Planning.within(o)
	if _experiment=="no_brew_request" and b=="brewery":proposal.lots=0;proposal.reason="control_no_brew_request"
	_record("business_plan",owner,b,true,{"observation":o,"proposal":proposal,"phase":"procurement"})
	return request_grain(owner,b,proposal.lots,o.input_quote)
func _request_max(b: String) -> int:
	if not _requests.has(b):return 0
	var r: Dictionary=_requests[b]
	if not _current_quote(r.quote) or not _at(r.owner,Brew.SITES.farm) or _space.presences[r.owner].activity!="procure" or _space.presences[r.owner].until!=615:return 0
	var count: int=_workers(b).filter(func(w):return w.available and w.id in _funded_workers(b)).size()
	@warning_ignore("integer_division")
	var funded: int=maxi(0,_entities[b].money-_committed_payroll(b))/(r.lot_size*r.quote.unit_price)
	return mini(r.maximum,mini(count,funded))
func procure_flour(owner: String) -> bool:
	if owner!="cora" or _space.minute!=730:return _reject("spatial_procurement",owner,"bakery",{},"invalid_flour_appointment")
	if not inspect_offers(owner,"mill").success:return false
	var o: Dictionary=business_observation(owner,"bakery",true);var proposal: Dictionary=Planning.within(o)
	_record("business_plan",owner,"bakery",true,{"observation":o,"proposal":proposal,"phase":"procurement"})
	if not _begin(owner,"procure",5,"bakery"):return false
	_courier=owner;var bought: int=0
	for lot in proposal.lots:
		if purchase_quote("bakery",o.input_quote,5):bought+=5
		else:break
	_courier="";_encounter(owner,"mill","purchased" if bought>0 else "declined","flour",bought)
	return true
func vacancy_observation(owner: String,b: String) -> Dictionary:
	var o: Dictionary=super(owner,b);var retained: int=0;var expiring: Array=[]
	for w in _active_staff(b):
		if _employment[w].end_day<=_day+1:expiring.append(w)
		else:retained+=1
	var remaining: int=mini(o.production.output_stock,maxi(0,o.previous_sales-_sales.get(_day,{}).get(b,0))) if _space.minute<Brew.TRADE[b][1] else 0
	return {"owner":owner,"business":b,"day":_day,"production":o.production,"demand":o.previous_sales,"remaining_sales":remaining,"retained":retained,"expiring":expiring,"reserved":o.reserved,"capacity":o.capacity,"farm_cap":o.farm_cap,"disabled":o.disabled,"arrears":arrears(b),"mode":renewal_mode}
func _renewal_plan(o: Dictionary) -> Dictionary:return Planning.renewal(o)
func _assessment(b: String) -> Dictionary:return _renewal_plan(vacancy_observation(Brew.OWNERS[b],b))
func advertise(owner: String,b: String) -> bool:
	if not _at_board(owner) or not _businesses.has(b) or Brew.OWNERS[b]!=owner:return _reject("labor_vacancy_assessed",owner,b,{},"owner_not_at_board")
	var o: Dictionary=vacancy_observation(owner,b);var p: Dictionary=_renewal_plan(o)
	_record("labor_vacancy_assessed",owner,b,true,{"observation":o,"proposal":p})
	return post_job(owner,b,"notice:%04d:%s"%[_day,b],10,1,1,3,p.vacancies) if p.vacancies>0 else true
func _eligible_applicant(w: String,p: Dictionary) -> String:
	if not _entities.has(w) or _entities[w].kind!="resident":return "not_resident"
	if w in Brew.OWNERS.values():return "management_only"
	if _pending_hires.has(w) or _resignations.has(w):return "already_committed"
	if _employment.get(w,{}).get("active",false) and _employment[w].end_day>_day+1:return "binding_term_active"
	if renewal_mode=="obligations_only" and (_affiliations.get(w,{}).get("business","")!=p.business or _employment[w].end_day!=_day+1):return "incumbent_renewal_only"
	if p.wage!=10 or p.duration_days!=3 or not p.required_skills.is_empty():return "invalid_fixed_labor_terms"
	return ""
func _entry_reason(w: String,p: Dictionary) -> String:
	if not _notices.has(p.id) or not p.active or _notices[p.id].latest_start!=_day+1:return "expired_or_closed_notice"
	if p.wage!=10 or p.duration_days!=3 or p.cycle_days!=1 or p.guaranteed_shifts!=1 or not p.required_skills.is_empty():return "changed_fixed_terms"
	if _employment.get(w,{}).get("active",false) and _employment[w].end_day>_day+1:return "binding_term_active"
	var o: Dictionary=vacancy_observation(p.employer,p.business);var plan: Dictionary=_renewal_plan(o)
	return "changed_capacity_or_funding" if o.retained+o.reserved>o.capacity or plan.headcount<o.retained+o.reserved else ""
func request_resignation(w: String,b: String) -> bool:
	if _pending_hires.has(w) and _employment.get(w,{}).get("business","")==b and _employment[w].end_day==_day+1:return true # Natural expiry; no resignation is created.
	return _reject("resignation_requested",w,b,{},"binding_term_cannot_be_cancelled")
func start_self_employment(owner: String,b: String) -> bool:
	return _reject("self_employment_started",owner,b,{},"management_only")
func worker_observation(w: String) -> Dictionary:
	var history: Array=[]
	for day in range(maxi(1,_day-2),_day+1):
		for b in Brew.ORDER:
			var id: String="%04d:%s:%s"%[day,b,w]
			if _attendance.has(id):history.append({"day":day,"business":b,"due_event_id":_attendance[id].due_event_id,"attendance_event_id":_attendance[id].attendance_event_id,"paid":_obligations.get(id,{}).get("paid",0),"payments":_obligations.get(id,{}).get("payments",[]).duplicate(true)})
	var job: Dictionary=_employment.get(w,{})
	return {"worker":w,"day":_day,"business":_affiliations.get(w,{}).get("business",""),"end_day":job.get("end_day",0),"eligible":not job.get("active",false) or job.end_day==_day+1,"history":history,"notices":job_board(w),"notice_event_id":_known_jobs.get(w,{}).get("event_id",null),"mode":renewal_mode}
func search_job(w: String) -> bool:
	if not _at_board(w) or w in Brew.OWNERS.values():return false
	var o: Dictionary=worker_observation(w);var p: Dictionary=Planning.search(o)
	_record("labor_search_decision",w,p.posting,true,{"observation":o,"proposal":p})
	return apply_for_job(w,p.posting) if p.action=="apply" else true
func consider_applicants(owner: String,b: String) -> void:
	if not _at_board(owner) or Brew.OWNERS[b]!=owner:return
	var groups: Array=[[],[]]
	for a in _applications.values():
		if _postings[a.posting].business==b and a.status=="applied" and _at_board(a.worker):
			var incumbent: bool=_affiliations.get(a.worker,{}).get("business","")==b
			groups[0 if incumbent else 1].append({"id":a.worker,"wage":10,"available":true,"application_id":a.id,"incumbent":incumbent})
	var ranked: Array=Market.order(groups[0],_day,tie)+Market.order(groups[1],_day,tie)
	_record("labor_applicants_ranked",owner,b,true,{"candidates":ranked,"tie":"incumbent_then_neutral_rotate","reason":"equal_full_term_financial_contribution"})
	for row in ranked:
		if _assessment(b).vacancies<1:break
		make_job_offer(owner,row.application_id)
func respond_to_offers(w: String) -> void:
	var offers: Array=inspect_job_offers(w);var o: Dictionary=worker_observation(w)
	_record("labor_acceptance_decision",w,"",true,{"observation":o,"offers_event_id":_known_offers.get(w,{}).get("event_id",null),"accepts":o.eligible and not offers.is_empty(),"reason":"positive_post_expiry_income" if o.eligible and not offers.is_empty() else "binding_term_or_no_observed_offer"})
	if o.eligible and not offers.is_empty():accept_job_offer(w,offers[0].application_id)
func decline_offer(w: String,id: String) -> bool:
	if not _at_board(w) or not _applications.has(id) or _applications[id].worker!=w or _applications[id].status!="offered" or not _known_offers.get(w,{}).get("offers",[]).any(func(o):return o.application_id==id):return _reject("binding_offer_declined",w,id,{},"unobserved_or_unavailable_offer")
	var a: Dictionary=_applications[id];a.status="declined";_postings[a.posting].reserved-=1
	_record("binding_offer_declined",w,_postings[a.posting].business,true,{"application_id":id})
	return true
func release_for_breach(actor: String,w: String,receipt: Variant) -> bool:
	var reason: String="";var b: String=_affiliations.get(w,{}).get("business","")
	if b.is_empty() or _releases.has(w) or _pending_hires.has(w):reason="no_exclusive_active_term"
	elif _space.minute!=955 or not _at_board(actor):reason="not_at_local_meeting"
	elif not receipt is int or receipt<1 or receipt>_events.size():reason="invalid_breach_receipt"
	else:
		var e: Dictionary=_events[receipt-1]
		if e.action!="binding_breach" or not e.success or e.actor!=w or e.target!=b or e.details.term!=_active_terms[w]:reason="unverified_breach"
		elif e.details.kind=="employer_unpaid":
			if actor!=w or _obligations[e.details.claim].paid==10:reason="worker_choice_with_unpaid_claim_required"
		elif actor!=Brew.OWNERS[b]:reason="owner_choice_required"
	if not reason.is_empty():return _reject("binding_release_requested",actor,w,{},reason)
	_releases[w]={"worker":w,"business":b,"actor":actor,"breach_event_id":receipt,"effective_day":_day+1}
	_resignations[w]={"business":b,"effective_day":_day+1}
	_record("binding_release_requested",actor,w,true,_releases[w])
	return true
func profit_budget(b: String) -> Dictionary:
	var budget: Dictionary=super(b)
	budget.realized_remaining-=arrears(b)
	if arrears(b)>0:budget.eligible=0
	return budget
func close_contract_day() -> void:
	if _contract_day_closed:return
	var completed: int=0;var due: int=0;var breaches: int=0
	for b in Brew.ORDER:
		for w in _active_staff(b):
			due+=1;var id: String=_claim_id(w,b);var session: Dictionary=_attendance[id];var claim: Dictionary=_obligations.get(id,{})
			var work: Dictionary={}
			for e in _events.slice(_day_start):
				if e.action=="work_shift" and e.success and e.actor==w and e.target==b:work=e
			var breach: bool=session.status=="absent" or claim.get("breach_event_id",null)!=null
			completed+=int(not work.is_empty());breaches+=int(breach)
			_record("contract_shift",w,b,not work.is_empty(),{"contract_id":_contract_id(b,w),"employer":Brew.OWNERS[b],"expected_compensation":10,"actual_compensation":claim.get("paid",0),"completed":not work.is_empty(),"reason":"productive_work" if not work.is_empty() else "worker_nonattendance" if session.status=="absent" else "attended_standby","shift_event_id":work.get("id",null),"attendance_event_id":session.attendance_event_id,"guaranteed_wage_due":claim.get("amount",0),"arrears":claim.get("amount",0)-claim.get("paid",0),"breach":breach})
	_contract_day_closed=true
	var business_cash: Dictionary={};var household_cash: Dictionary={};var goods: Dictionary=Brew.empty_goods()
	for id in _entities:
		var e: Dictionary=_entities[id]
		if e.kind=="business":business_cash[id]=e.money
		elif e.kind=="resident":household_cash[id]=e.money
		for item in goods:goods[item]+=e.inventory[item]
	_record("contract_day_closed","world","",true,{"due":due,"completed":completed,"breaches":breaches,"unutilized":due-completed,"business_cash":business_cash,"household_cash":household_cash,"goods":goods,"cash_results":_cash_results.duplicate(true)})
	var liabilities: Dictionary={};var receivables: Dictionary={}
	for b in Brew.ORDER:liabilities[b]=arrears(b)
	for c in _obligations.values():receivables[c.worker]=receivables.get(c.worker,0)+c.amount-c.paid
	_record("binding_day_closed","world","",true,{"liabilities":liabilities,"receivables":receivables,"terms":_active_terms.duplicate(),"breaches":breaches})
func close_boundary() -> void:
	assert(_space.minute==1440 and _contract_day_closed)
	_apply_boundary(_day+1)
func _apply_boundary(next_day: int) -> void:
	if _processed_boundary==_day:return
	var closing: Array=[]
	for id in _active_terms.values():
		if _terms[id].end_day<=next_day or _releases.has(_terms[id].worker):closing.append(id)
	super(next_day)
	for id in closing:
		var term: Dictionary=_terms[id];var new: Dictionary=_terms.get(_active_terms.get(term.worker,""),{})
		var disposition: String="released" if term.status=="released" else "nonrenewed" if new.is_empty() else "renewed" if new.business==term.business else "changed_employer"
		_record("binding_term_disposition",term.worker,term.business,true,{"term":id,"disposition":disposition,"successor":new.get("id","")})
	_releases.clear();_processed_boundary=_day
	if _day>0:_record("binding_boundary_closed","world","",true,{"effective_day":next_day,"processed_day":_day})
