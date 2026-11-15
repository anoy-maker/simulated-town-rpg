extends RefCounted
## Post-run observer for the four fixed M11–M13 conditions. Never supplied to policies.

const Config = preload("res://scripts/sim/labor_config.gd")
const Reference = preload("res://scripts/sim/equilibrium_config.gd")
const Employer = preload("res://scripts/sim/employer_policy.gd")
const Treatment = preload("res://scripts/sim/causality_policy.gd")


static func project(report: Dictionary, history: Array) -> Dictionary:
	var entities: Dictionary = report.initial.entities.duplicate(true)
	var daily: Dictionary = {}
	var sources: Dictionary = {}
	var claimed: Dictionary = {}
	var worked: Dictionary = {}
	var valid: bool = true
	var result = {"currency_after_every_event": true, "accounting_and_labor_verified": true,
		"first_unmet_meal_day": null, "first_bread_stock_shortage_day": null,
		"first_financial_constraint_day": null, "first_sustained_inactivity_day": null,
		"trailing_inactivity_start": null, "unmet_with_bread_unsold": 0,
		"unaffordable_food_turns_with_stock": 0, "food_turns_without_stock": 0,
		"by_business": {}, "timeline_first_eight_days": []}
	for business in Config.BUSINESS_ORDER:
		result.by_business[business] = {"desired_output": 0, "feasible_output": 0, "actual_output": 0,
			"desired_shifts": 0, "planned_shifts": 0, "actual_shifts": 0,
			"fully_financed_desired_plans": 0, "financially_constrained_plans": 0,
			"zero_demand_plans": 0, "input_shortage_plans": 0, "output_shortfall_plans": 0,
			"first_financial_constraint_day": null, "first_unfundable_shift_day": null,
			"selected": {}, "skipped": {}, "reasons": {}, "reductions": {}, "plans_first_eight_days": []}
	for index in history.size():
		var e: Dictionary = history[index]
		var d: Dictionary = e.details
		valid = valid and e.id == index + 1
		if e.action == "day_started":
			worked.clear()
			var firms: Dictionary = {}
			for business in Config.BUSINESS_ORDER:
				firms[business] = {"opening": {}, "proposal": {}, "shifts": 0, "output": 0, "sold": 0}
			daily[e.day] = {"day": e.day, "firms": firms, "bread_before_food": entities.bakery.inventory.bread,
				"bread_produced": 0, "bread_sold": 0, "eaten": 0, "missed": 0,
				"paid_shifts": 0, "activity": false, "food_checked": {}}
		var business: String = ""
		if e.action == "purchase" and report.initial.businesses.has(e.actor):
			business = e.actor
		elif e.action in ["shift_offered", "employer_plan"] or (e.action == "labor_decision" and d.phase in ["inputs", "schedule"]):
			business = e.target
		if not business.is_empty() and daily[e.day].firms[business].opening.is_empty():
			var input: String = Config.INDUSTRIES[report.initial.businesses[business].industry].input
			daily[e.day].firms[business].opening = {"cash": entities[business].money,
				"input_stock": 0 if input.is_empty() else entities[business].inventory[input],
				"output_stock": entities[business].inventory[Config.INDUSTRIES[report.initial.businesses[business].industry].output],
				"public_input_stock": 0 if input.is_empty() else entities["farm" if input == "wheat" else "mill"].inventory[input]}
		var food_turn: bool = (e.action == "purchase" and not report.initial.businesses.has(e.actor)) \
			or (e.action == "labor_decision" and d.phase == "food") or e.action == "consume"
		if food_turn and not daily[e.day].food_checked.has(e.actor):
			daily[e.day].food_checked[e.actor] = true
			if entities[e.actor].inventory.bread == 0:
				if entities.bakery.inventory.bread == 0:
					result.food_turns_without_stock += 1
				elif entities[e.actor].money < Reference.PRICES.bread:
					result.unaffordable_food_turns_with_stock += 1
		if e.action == "employer_plan" and d.has("execution"):
			daily[e.day].firms[e.target].proposal = d.proposal
		if e.action == "consume" and not e.success:
			daily[e.day].missed += 1
			if result.first_unmet_meal_day == null:
				result.first_unmet_meal_day = e.day
		if e.success:
			match e.action:
				"purchase":
					valid = valid and d.quantity > 0 and d.unit_price == Reference.PRICES[d.item] and d.total_price == d.quantity * d.unit_price
					entities[e.actor].money -= d.total_price
					entities[e.target].money += d.total_price
					entities[e.actor].inventory[d.item] += d.quantity
					entities[e.target].inventory[d.item] -= d.quantity
					daily[e.day].firms[e.target].sold += d.quantity
					daily[e.day].activity = true
					if d.item == "bread":
						daily[e.day].bread_sold += d.quantity
				"transfer_money":
					entities[e.actor].money -= d.amount
					entities[e.target].money += d.amount
					sources[e.id] = true
				"harvest", "produce":
					var inputs: Dictionary = {} if e.action == "harvest" else d.inputs
					var outputs: Dictionary = {"wheat": d.amount} if e.action == "harvest" else d.outputs
					valid = valid and (e.actor == "farm" and d.amount == 4 if e.action == "harvest" else d.batches == 2 \
						and inputs == ({"wheat": 4} if e.actor == "mill" else {"flour": 4}) \
						and outputs == ({"flour": 4} if e.actor == "mill" else {"bread": 6}))
					for item in inputs:
						entities[e.actor].inventory[item] -= inputs[item]
					for item in outputs:
						entities[e.actor].inventory[item] += outputs[item]
						daily[e.day].firms[e.actor].output += outputs[item]
						if item == "bread":
							daily[e.day].bread_produced += outputs[item]
							daily[e.day].bread_before_food += outputs[item]
					sources[e.id] = true
					daily[e.day].activity = true
				"work_shift":
					var pay: Dictionary = history[d.payment_event_id - 1]
					var production: Dictionary = history[d.production_event_id - 1]
					valid = valid and not worked.has(e.actor) and d.wage == 8 and d.labor == 1 \
						and pay.success and pay.action == "transfer_money" and pay.actor == e.target and pay.target == e.actor and pay.details.amount == 8 \
						and production.success and production.actor == e.target and production.action in ["harvest", "produce"] \
						and pay.day == e.day and production.day == e.day and pay.id < e.id and production.id < e.id \
						and not claimed.has(pay.id) and not claimed.has(production.id)
					claimed[pay.id] = true
					claimed[production.id] = true
					worked[e.actor] = true
					daily[e.day].firms[e.target].shifts += 1
					daily[e.day].paid_shifts += 1
					daily[e.day].activity = true
				"consume":
					entities[e.actor].inventory.bread -= d.amount
					daily[e.day].eaten += d.amount
				"initialize", "day_started", "labor_environment", "shift_offered", "labor_decision", "employer_plan":
					pass
				_:
					valid = false
		var money: int = 0
		for entity in entities.values():
			money += entity.money
			valid = valid and entity.money >= 0 and entity.money <= 1_000_000_000
			for amount in entity.inventory.values():
				valid = valid and amount >= 0 and amount <= 1_000_000_000
		result.currency_after_every_event = result.currency_after_every_event and money == 432
	result.accounting_and_labor_verified = valid and sources == claimed and entities == report.final.entities
	var inactive: int = 0
	for day in daily:
		var row: Dictionary = daily[day]
		row["bread_unsold"] = row.bread_before_food - row.bread_sold
		if row.bread_before_food < 12 and result.first_bread_stock_shortage_day == null:
			result.first_bread_stock_shortage_day = day
		if row.bread_unsold > 0:
			result.unmet_with_bread_unsold += row.missed
		inactive = 0 if row.activity else inactive + 1
		if inactive == 7 and result.first_sustained_inactivity_day == null:
			result.first_sustained_inactivity_day = day - 6
		for business in Config.BUSINESS_ORDER:
			_summarize_plan(report, daily, day, business, result)
		if day <= 8:
			var compact: Dictionary = row.duplicate(true)
			compact.erase("food_checked")
			compact.erase("firms")
			result.timeline_first_eight_days.append(compact)
	if inactive >= 7:
		result.trailing_inactivity_start = report.days - inactive + 1
	result["economic_sha256"] = JSON.stringify(economic_trace(history), "", true).sha256_text()
	return result


static func economic_trace(history: Array) -> Array:
	var trace: Array = []
	for e in history:
		if e.success and e.action in ["purchase", "transfer_money", "harvest", "produce", "consume"]:
			trace.append({"day": e.day, "action": e.action, "actor": e.actor, "target": e.target, "details": e.details})
	return trace


static func _summarize_plan(report: Dictionary, daily: Dictionary, day: int, business: String, result: Dictionary) -> void:
	var row: Dictionary = daily[day].firms[business]
	var firm: Dictionary = report.initial.businesses[business]
	var output: String = Config.INDUSTRIES[firm.industry].output
	var input: String = Config.INDUSTRIES[firm.industry].input
	var p: Dictionary = row.proposal
	if p.is_empty(): # M11 is observed without modifying its prescribed runner or ledger.
		p = {"forecast": Employer.STARTUP[output], "forecast_source": "prescribed_daily_output", "required_output": Employer.STARTUP[output],
			"requested_shifts": 2, "planned_shifts": 2, "planned_output": Employer.STARTUP[output],
			"workers": Reference.workers(firm, day), "skipped": [], "reason": "prescribed_reference", "reductions": []}
		for worker in [firm.owner] + firm.employees:
			if worker not in p.workers:
				p.skipped.append({"worker": worker, "reason": "outside_rotating_group"})
	var missing: int = 0 if input.is_empty() else maxi(0, p.requested_shifts * 4 - row.opening.input_stock)
	var full_cost: int = p.requested_shifts * Reference.WAGE + missing * (0 if input.is_empty() else Reference.PRICES[input])
	var cash_short: bool = row.opening.cash < full_cost
	var missing_one: int = 0 if input.is_empty() else maxi(0, 4 - row.opening.input_stock)
	var one_cost: int = Reference.WAGE + missing_one * (0 if input.is_empty() else Reference.PRICES[input])
	var b: Dictionary = result.by_business[business]
	b.desired_output += p.required_output
	b.feasible_output += p.planned_output
	b.actual_output += row.output
	b.desired_shifts += p.requested_shifts
	b.planned_shifts += p.planned_shifts
	b.actual_shifts += row.shifts
	b.zero_demand_plans += 1 if p.requested_shifts == 0 else 0
	b.fully_financed_desired_plans += 1 if p.requested_shifts > 0 and not cash_short else 0
	b.financially_constrained_plans += 1 if cash_short else 0
	b.input_shortage_plans += 1 if missing > row.opening.public_input_stock else 0
	b.output_shortfall_plans += 1 if row.output < p.required_output else 0
	if cash_short and b.first_financial_constraint_day == null:
		b.first_financial_constraint_day = day
		if result.first_financial_constraint_day == null:
			result.first_financial_constraint_day = day
	if p.requested_shifts > 0 and row.opening.cash < one_cost and b.first_unfundable_shift_day == null:
		b.first_unfundable_shift_day = day
	for worker in p.workers:
		b.selected[worker] = b.selected.get(worker, 0) + 1
	for skip in p.skipped:
		b.skipped[skip.worker] = b.skipped.get(skip.worker, 0) + 1
	b.reasons[p.reason] = b.reasons.get(p.reason, 0) + 1
	for reason in p.reductions:
		b.reductions[reason] = b.reductions.get(reason, 0) + 1
	if day <= 8:
		var trace: Dictionary = p.duplicate(true)
		trace.merge({"day": day, "opening": row.opening, "full_desired_cost": full_cost,
			"cash_short": cash_short, "actual_shifts": row.shifts, "actual_output": row.output,
			"observed_previous_sales": 0 if day == 1 else daily[day - 1].firms[business].sold})
		b.plans_first_eight_days.append(trace)
