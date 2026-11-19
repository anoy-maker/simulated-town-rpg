extends "res://scripts/sim/coordination_runner.gd"

const PlanningPolicy = preload("res://scripts/sim/planning_policy.gd")
var _priority: String


func _init(seed_value: int = 42, initial_entities: Array = [], goals: Dictionary = Policy.DEFAULT_GOALS,
		priority: String = "commitment-first") -> void:
	assert(priority in PlanningPolicy.PRIORITIES)
	super(seed_value, initial_entities, goals)
	_priority = priority


func _decide(actor: String, phase: String, harvest_yield: int = 0) -> void:
	var proposal: Dictionary = PlanningPolicy.decide(world.observe(actor), _goals.duplicate(true), phase, _priority)
	world.execute_decision(actor, phase, proposal, harvest_yield)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "planning"
	summary["priority"] = _priority
	var activity = {"purchases_successful": 0, "purchases_failed": 0, "production_commands": 0,
		"agreements_accepted": 0, "agreements_fulfilled": 0, "last_purchase_day": null,
		"last_production_day": null, "last_fulfillment_day": null}
	for event in world.events():
		if event.action == "purchase":
			if event.success:
				activity.last_purchase_day = event.day
			if event.day > 26:
				activity["purchases_successful" if event.success else "purchases_failed"] += 1
		if not event.success:
			continue
		if event.action == "produce":
			activity.last_production_day = event.day
			if event.day > 26:
				activity.production_commands += 1
		elif event.action == "agreement_fulfilled":
			activity.last_fulfillment_day = event.day
			if event.day > 26:
				activity.agreements_fulfilled += 1
		elif event.action == "agreement_accepted" and event.day > 26:
			activity.agreements_accepted += 1
	summary["activity_after_day_26"] = activity
	var budgets: Dictionary = {}
	for actor in participant_ids():
		budgets[actor] = _working_capital(actor)
	summary["final_working_capital"] = budgets
	return summary


func _working_capital(actor: String) -> Dictionary:
	return PlanningPolicy.working_capital(world.observe(actor), _goals)
