extends "res://scripts/sim/simulation_runner.gd"
## M9 only: common owner/employee policies, explicit business accounts, daily labor.

const LaborWorld = preload("res://scripts/sim/labor_world.gd")
const Config = preload("res://scripts/sim/labor_config.gd")
const Policy = preload("res://scripts/sim/labor_policy.gd")


func _init(seed_value: int = 42, initial: Dictionary = Config.initial()) -> void:
	_seed = seed_value
	world = LaborWorld.new(seed_value, initial)
	_initial = world.snapshot()


func participant_ids() -> Array:
	var ids: Array = []
	for id in _initial.entities:
		if _initial.entities[id].kind == "resident":
			ids.append(id)
	ids.sort()
	return ids


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		for business in Config.BUSINESS_ORDER:
			var firm: Dictionary = _initial.businesses[business]
			var employees: Array = firm.employees.duplicate()
			employees.sort()
			for worker in [firm.owner] + employees:
				for phase in ["inputs", "schedule"]:
					var proposal: Dictionary = Policy.decide(world.observe(firm.owner, business), phase, worker)
					world.execute_decision(firm.owner, phase, proposal, business, worker)
				var work: Dictionary = Policy.decide(world.observe(worker), "work")
				world.execute_decision(worker, "work", work, business)
		for phase in ["food", "meal"]:
			for actor in participant_ids():
				world.execute_decision(actor, phase, Policy.decide(world.observe(actor), phase))


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary["scenario"] = "settlement_labor"
	summary["prices"] = Config.PRICES.duplicate()
	summary["schedule"] = {"businesses": Config.BUSINESS_ORDER.duplicate(), "workers": "owner then employee ID", "food": participant_ids()}
	var accounts: Dictionary = {}
	var total_money: int = 0
	for id in _initial.entities:
		accounts[id] = {"earned": 0, "spent": 0, "sales": 0, "purchases": 0, "wages_received": 0, "wages_paid": 0,
			"shifts": 0, "produced": {"wheat": 0, "flour": 0, "bread": 0}, "consumed": 0,
			"purchases_successful": 0, "purchases_failed": 0, "last_production_day": 0,
			"last_business_day": 0, "last_work_day": 0, "schedule_reasons": {}}
		total_money += _initial.entities[id].money
	var shifts = {"paid": 0, "rejected": 0, "unfunded": 0, "unavailable": 0, "wages": 0}
	var purchases = {"successful": 0, "rejected": 0}
	var circulation: int = 0
	var potential_wheat: int = 0
	var decisions: Dictionary = {}
	var failures: Dictionary = {}
	var notable: Array = []
	for event in world.events():
		var d: Dictionary = event.details
		if not event.success and event.action != "labor_decision":
			var failure: String = event.action + ":" + d.reason
			failures[failure] = failures.get(failure, 0) + 1
			if notable.size() < 8:
				notable.append(event)
		if event.action == "labor_environment":
			for value in d.opportunities.values():
				potential_wheat += value
		if event.action == "labor_decision":
			var key: String = event.actor + ":" + d.phase + ":" + d.reason + ":" + d.outcome
			decisions[key] = decisions.get(key, 0) + 1
			if d.phase == "schedule" and d.outcome == "wait":
				shifts.unavailable += 1
				if d.reason == "unfunded_payroll":
					shifts.unfunded += 1
				var reasons: Dictionary = accounts[event.target].schedule_reasons
				reasons[d.reason] = reasons.get(d.reason, 0) + 1
		if event.action == "work_shift":
			if event.success:
				shifts.paid += 1
				shifts.wages += d.wage
				accounts[event.actor].shifts += 1
				accounts[event.actor].last_work_day = event.day
				accounts[event.target].shifts += 1
			else:
				shifts.rejected += 1
				if d.reason == "unfunded_payroll":
					shifts.unfunded += 1
		if event.action == "purchase":
			purchases["successful" if event.success else "rejected"] += 1
			accounts[event.actor]["purchases_successful" if event.success else "purchases_failed"] += 1
		if not event.success:
			continue
		if event.action == "purchase":
			accounts[event.actor].spent += d.total_price
			accounts[event.actor].purchases += d.total_price
			accounts[event.target].earned += d.total_price
			accounts[event.target].sales += d.total_price
			accounts[event.target].last_business_day = event.day
			if _initial.entities[event.actor].kind == "business":
				accounts[event.actor].last_business_day = event.day
			circulation += d.total_price
		elif event.action == "transfer_money":
			accounts[event.actor].spent += d.amount
			accounts[event.actor].wages_paid += d.amount
			accounts[event.target].earned += d.amount
			accounts[event.target].wages_received += d.amount
			circulation += d.amount
		elif event.action in ["harvest", "produce"]:
			var outputs: Dictionary = {"wheat": d.amount} if event.action == "harvest" else d.outputs
			for item in outputs:
				accounts[event.actor].produced[item] += outputs[item]
			accounts[event.actor].last_production_day = event.day
			accounts[event.actor].last_business_day = event.day
		elif event.action == "consume":
			accounts[event.actor].consumed += 1
	var businesses: Dictionary = {}
	for id in _initial.businesses:
		var activity: Dictionary = accounts[id]
		businesses[id] = {"production_idle_days_at_end": summary.days - activity.last_production_day,
			"business_idle_days_at_end": summary.days - activity.last_business_day,
			"can_fund_one_shift": summary.final.entities[id].money >= _initial.businesses[id].owner_compensation}
	# Pooled horizon bound, including real initial grain/flour/bread; not a trajectory.
	@warning_ignore("integer_division")
	var bread_bound: int = mini((mini(potential_wheat + 16, summary.days * 16) + 12) / 2 * 3, summary.days * 24) + 18
	summary["potential"] = {"labor_shifts": summary.days * 12, "wheat": potential_wheat,
		"milling_flour_capacity": summary.days * 16, "baking_bread_capacity": summary.days * 24,
		"bread_including_initial_bound": bread_bound, "meal_needs": summary.days * 12}
	summary["accounts"] = accounts
	summary["business_activity"] = businesses
	summary["shifts"] = shifts
	summary["purchases"] = purchases
	summary["decisions"] = decisions
	# Decision rejections annotate commands; count the economic failure only once.
	summary.failures = failures
	summary.notable_events = notable
	summary["money"] = {"initial": total_money, "final": 0, "circulation": circulation}
	for entity in summary.final.entities.values():
		summary.money.final += entity.money
	return summary
