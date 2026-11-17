extends RefCounted
static func build(initial: Dictionary,final: Dictionary,events: Array,economy: Dictionary,mode: String) -> Dictionary:
	var state: Dictionary=final.binding_contracts
	var workers: Dictionary={};var businesses: Dictionary={};var days: Array=[];var rows: Array=[]
	for id in initial.entities:
		if initial.entities[id].kind=="resident":workers[id]={"scheduled":0,"attended":0,"productive":0,"standby":0,"breaches":0,"accrued":0,"cash_wages":economy.accounts[id].wages,"arrears":0,"future_guaranteed_days":0,"initial_employer":initial.affiliations.get(id,{}).get("business",""),"final_employer":final.affiliations.get(id,{}).get("business","")}
	for b in initial.businesses:
		var book: Dictionary=final.cash_results[b]
		businesses[b]={"sales":book.sales,"inputs":book.inputs,"cash_payroll":book.payroll,"distributions":book.distributions,"accrued_wages":0,"arrears":0,"future_guaranteed_wages":0,"cash_margin":book.sales-book.inputs-book.payroll,"cash":final.entities[b].money,"inventory":final.entities[b].inventory.duplicate(),"productive":economy.accounts[b].shifts}
	for e in events:
		if e.action=="binding_day_closed":days.append({"day":e.day,"minute":e.minute,"event_id":e.id}.merged(e.details.duplicate(true)))
		if e.action!="contract_shift":continue
		var d: Dictionary=e.details;var w: Dictionary=workers[e.actor];var attended: bool=d.guaranteed_wage_due==10
		w.scheduled+=1;w.attended+=int(attended);w.productive+=int(e.success);w.standby+=int(attended and not e.success);w.breaches+=int(d.breach)
		rows.append({"day":e.day,"worker":e.actor,"business":e.target,"scheduled":1,"attended":int(attended),"productive":int(e.success),"standby":int(attended and not e.success),"accrued":d.guaranteed_wage_due,"claim_paid_by_close":d.actual_compensation,"claim_arrears_by_close":d.arrears,"breach":d.breach,"attendance_event_id":d.attendance_event_id,"shift_event_id":d.shift_event_id,"closure_event_id":e.id,"cash_wages_on_day":economy.day_results[e.day-1].households[e.actor].wages,"meals":economy.day_results[e.day-1].households[e.actor].meals,"missed_meals":economy.day_results[e.day-1].households[e.actor].missed_meals})
	for c in state.obligations.values():
		workers[c.worker].accrued+=c.amount;workers[c.worker].arrears+=c.amount-c.paid
		businesses[c.business].accrued_wages+=c.amount;businesses[c.business].arrears+=c.amount-c.paid
	for b in businesses:businesses[b]["accrued_margin"]=businesses[b].cash_margin-businesses[b].arrears
	for w in state.active_terms:
		var term: Dictionary=state.terms[state.active_terms[w]]
		var remaining: int=maxi(0,term.end_day-maxi(term.start_day,final.day+1))
		workers[w].future_guaranteed_days=remaining;businesses[term.business].future_guaranteed_wages+=10*remaining
	var counts={"expired":0,"released":0,"renewed":0,"nonrenewed":0,"hired":0,"rehired":0,"changed_employer":0}
	for e in events:
		if e.action=="binding_term_closed":counts[e.details.term.status]+=1
		if e.action=="binding_term_disposition" and e.details.disposition in ["renewed","nonrenewed","changed_employer"]:counts[e.details.disposition]+=1
		if e.action=="binding_term_started" and not e.details.renewed:counts.hired+=1
		if e.action=="binding_term_started" and e.details.entry_kind=="rehire":counts.rehired+=1
	return {"mode":mode,"term_days":3,"wage":10,"workers":workers,"businesses":businesses,"worker_days":rows,"days":days,"counts":counts,"utilization_note":"Legacy missed_shifts counts nonproductive due opportunities; only explicit binding breaches measure contract violation. Accrued margin expenses inputs without inventory valuation."}
