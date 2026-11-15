extends RefCounted
## Two treatments only; reuse M12's planning and M11's exclusive rotating pairs.

const Employer = preload("res://scripts/sim/employer_policy.gd")
const Reference = preload("res://scripts/sim/equilibrium_config.gd")
const Labor = preload("res://scripts/sim/labor_config.gd")
const FIXED_OWNER = "settlement_fixed_owner_first"
const SALES_ROTATING = "settlement_sales_rotating"


static func decide(observation: Dictionary, condition: String) -> Dictionary:
	assert(condition in [FIXED_OWNER, SALES_ROTATING])
	var firm: Dictionary = observation.business
	var output: String = Labor.INDUSTRIES[firm.industry].output
	var roster: Array = Employer.owner_first(firm)
	var plan: Dictionary
	if condition == FIXED_OWNER:
		plan = Employer.production_plan(observation, Employer.STARTUP[output], false, roster, "prescribed_daily_output")
	else:
		var group: Array = Reference.workers(firm, observation.day)
		var candidates: Array = []
		for id in group:
			for worker in roster:
				if worker.id == id:
					candidates.append(worker)
		plan = Employer.sales_plan(observation, candidates)
		for worker in roster:
			if worker.id not in group:
				plan.skipped.append({"worker": worker.id, "reason": "outside_rotating_group"})
		roster = candidates
	plan["staffing"] = "owner_first" if condition == FIXED_OWNER else "rotating"
	plan["candidate_workers"] = roster.map(func(w): return w.id)
	plan["observed_sales"] = firm.history.sold[output]
	return plan
