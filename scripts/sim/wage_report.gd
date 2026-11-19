extends RefCounted
static func correct(report: Dictionary,state: Dictionary,events: Array) -> Dictionary:
	var r: Dictionary=report.duplicate(true);r.wage="by_term"
	for w in r.workers:r.workers[w].attended=0;r.workers[w].standby=0
	var closures: Array=events.filter(func(e):return e.action=="contract_shift")
	for i in closures.size():
		var e: Dictionary=closures[i];var attended: int=int(e.details.guaranteed_wage_due>0)
		r.worker_days[i].attended=attended;r.worker_days[i].standby=int(attended>0 and not e.success)
		r.workers[e.actor].attended+=attended;r.workers[e.actor].standby+=r.worker_days[i].standby
	for b in r.businesses:r.businesses[b].future_guaranteed_wages=0
	for id in state.binding_contracts.active_terms.values():
		var term: Dictionary=state.binding_contracts.terms[id]
		r.businesses[term.business].future_guaranteed_wages+=term.wage*maxi(0,term.end_day-maxi(term.start_day,state.day+1))
	return r
