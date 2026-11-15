extends "res://scripts/sim/labor_runner.gd"
## Same M11 resources/authority, with daily employer plans replacing its fixed schedule.

const Reference = preload("res://scripts/sim/equilibrium_config.gd")
const EmployerWorld = preload("res://scripts/sim/employer_world.gd")
const EmployerPolicy = preload("res://scripts/sim/employer_policy.gd")


func _init(seed_value: int = 42, initial: Dictionary = Reference.initial()) -> void:
	super(seed_value, initial)
	world = EmployerWorld.new(seed_value, initial)
	_initial = world.snapshot()


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		for business in Config.BUSINESS_ORDER:
			var owner: String = _initial.businesses[business].owner
			world.execute_plan(owner, business, EmployerPolicy.decide(world.observe(owner, business)))
		for phase in ["food", "meal"]:
			for actor in participant_ids():
				world.execute_decision(actor, phase, Policy.decide(world.observe(actor), phase))


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "settlement_employer_choice"
	summary.prices = Reference.PRICES.duplicate()
	summary.potential.bread_including_initial_bound = summary.days * 24
	var employers = {"forecast_rule": "previous calendar day's realized output sales; one-time 8/8/12 startup",
		"by_business": {}, "first_unmet_meal_day": null, "first_bread_stock_shortage_day": null,
		"first_sustained_inactivity_day": null, "trailing_inactivity_start": null,
		"unmet_with_bread_unsold": 0, "timeline_first_eight_days": []}
	for business in Config.BUSINESS_ORDER:
		employers.by_business[business] = {"plans": 0, "planned_shifts": 0, "offered_shifts": 0, "completed_shifts": 0,
			"rejected_plans": 0, "forecast_total": 0, "planned_output": 0, "reasons": {}, "reductions": {}, "selected": {}, "skipped": {}}
	var daily: Dictionary = {}
	for e in world.events():
		var d: Dictionary = e.details
		if e.action == "day_started":
			daily[e.day] = {"day": e.day, "bread_produced": 0, "bread_before_food": 0, "bread_sold": 0,
				"eaten": 0, "missed": 0, "paid_shifts": 0, "activity": false}
		if e.action == "employer_plan":
			var row: Dictionary = employers.by_business[e.target]
			var plan: Dictionary = d.proposal
			row.plans += 1
			row.rejected_plans += 0 if e.success else 1
			row.forecast_total += plan.get("forecast", 0)
			row.planned_shifts += plan.get("planned_shifts", 0)
			row.planned_output += plan.get("planned_output", 0)
			if d.has("execution"):
				row.offered_shifts += d.execution.offer_event_ids.size()
				row.completed_shifts += d.execution.work_event_ids.size()
				if e.target == "bakery":
					daily[e.day].bread_before_food = d.execution.output_stock_after
			for reason in plan.get("reductions", []):
				row.reductions[reason] = row.reductions.get(reason, 0) + 1
			var why: String = plan.get("reason", "invalid_plan")
			row.reasons[why] = row.reasons.get(why, 0) + 1
			for actor in plan.get("workers", []):
				row.selected[actor] = row.selected.get(actor, 0) + 1
			for skip in plan.get("skipped", []):
				row.skipped[skip.worker] = row.skipped.get(skip.worker, 0) + 1
		if e.action == "consume":
			daily[e.day]["eaten" if e.success else "missed"] += 1
			if not e.success and employers.first_unmet_meal_day == null:
				employers.first_unmet_meal_day = e.day
		if not e.success:
			continue
		if e.action in ["purchase", "harvest", "produce", "work_shift"]:
			daily[e.day].activity = true
		if e.action == "produce":
			daily[e.day].bread_produced += d.outputs.get("bread", 0)
		elif e.action == "purchase" and d.item == "bread":
			daily[e.day].bread_sold += d.quantity
		elif e.action == "work_shift":
			daily[e.day].paid_shifts += 1
	var inactive: int = 0
	for day in daily:
		var row: Dictionary = daily[day]
		row["bread_unsold"] = row.bread_before_food - row.bread_sold
		if row.bread_before_food < 12 and employers.first_bread_stock_shortage_day == null:
			employers.first_bread_stock_shortage_day = day
		if row.bread_unsold > 0:
			employers.unmet_with_bread_unsold += row.missed
		inactive = 0 if row.activity else inactive + 1
		if inactive == 7 and employers.first_sustained_inactivity_day == null:
			employers.first_sustained_inactivity_day = day - 6
		if day <= 8:
			employers.timeline_first_eight_days.append(row)
	if inactive >= 7:
		employers.trailing_inactivity_start = summary.days - inactive + 1
	# Plan failures annotate native execution failures; keep their counts separate.
	for key in summary.failures.keys():
		if key.begins_with("employer_plan:"):
			summary.failures.erase(key)
	summary.notable_events = summary.notable_events.filter(func(e): return e.action != "employer_plan")
	employers["ledger_sha256"] = JSON.stringify(world.events(), "", true).sha256_text()
	summary["employers"] = employers
	return summary
