extends RefCounted
## Pure last-realized-sales production plan. No world reference or fixed output floor.

const Kernel = preload("res://scripts/sim/world_state.gd")
const Labor = preload("res://scripts/sim/labor_config.gd")
const OfferPolicy = preload("res://scripts/sim/labor_policy.gd")
const Reference = preload("res://scripts/sim/equilibrium_config.gd")
const STARTUP = {"wheat": 8, "flour": 8, "bread": 12}


static func decide(observation: Dictionary) -> Dictionary:
	var firm: Dictionary = observation.business
	assert(not firm.is_empty())
	var rule: Dictionary = Labor.INDUSTRIES[firm.industry]
	var forecast: int = STARTUP[rule.output] if observation.day == 1 else firm.history.sold[rule.output]
	var stock: int = firm.inventory[rule.output]
	var deficit: int = maxi(0, forecast - stock)
	var output_per_shift: int = Reference.HARVEST if rule.recipe.is_empty() else Kernel.RECIPES[rule.recipe].outputs[rule.output] * firm.assets.batches_per_shift
	@warning_ignore("integer_division")
	var requested: int = (deficit + output_per_shift - 1) / output_per_shift
	var roster: Array = firm.workers.duplicate(true)
	roster.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if (a.id == firm.owner) != (b.id == firm.owner):
			return a.id == firm.owner
		return a.id < b.id)
	var eligible: Array = roster.filter(func(w): return w.qualified and w.available and w.wage > 0)
	var count: int = mini(requested, mini(firm.assets.daily_slots - firm.labor_used, eligible.size()))
	var reductions: Array = []
	if stock > 0 and forecast > 0:
		reductions.append("unsold_inventory_offset")
	if firm.history.previous_forecast != null and forecast < firm.history.previous_forecast:
		reductions.append("declining_realized_sales")
	if count < requested:
		reductions.append("workforce_or_capacity")
	var supply: Dictionary = {} if rule.input.is_empty() else OfferPolicy._offer(observation, rule.input)
	var payroll: int = 0
	var input_cost: int = 0
	var missing: int = 0
	while count > 0:
		payroll = 0
		for worker in eligible.slice(0, count):
			payroll += worker.wage
		missing = 0 if rule.input.is_empty() else maxi(0, 4 * count - firm.inventory[rule.input])
		var limit: String = ""
		if missing > 0 and (supply.is_empty() or supply.stock < missing):
			limit = "insufficient_inputs"
		else:
			input_cost = 0 if missing == 0 else missing * supply.unit_price
			if firm.money < payroll + input_cost:
				limit = "insufficient_operating_funds"
		if limit.is_empty():
			break
		if limit not in reductions:
			reductions.append(limit)
		count -= 1
	if count == 0:
		payroll = 0
		input_cost = 0
		missing = 0
	var reason: String = "meet_expected_sales"
	if forecast == 0:
		reason = "no_realized_sales"
	elif deficit == 0:
		reason = "unsold_inventory_covers_forecast"
	elif count < requested:
		reason = "production_limited"
	var chosen: Array = []
	for worker in eligible.slice(0, count):
		chosen.append(worker.id)
	var skipped: Array = []
	for worker in roster:
		if worker.id not in chosen:
			var skip_reason: String = "additional_labor_not_needed" if count == requested else "outside_feasible_plan"
			if count == 0:
				skip_reason = reason
			if not worker.qualified or worker.wage <= 0:
				skip_reason = "ineligible"
			elif not worker.available:
				skip_reason = "daily_labor_limit"
			skipped.append({"worker": worker.id, "reason": skip_reason})
	var purchase: Dictionary = {}
	if missing > 0:
		purchase = {"type": "purchase", "seller": supply.seller, "item": rule.input, "quantity": missing, "unit_price": supply.unit_price}
	return {"forecast": forecast, "forecast_source": "one_time_startup" if observation.day == 1 else "previous_realized_sales",
		"unsold_stock": stock, "required_output": deficit, "requested_shifts": requested,
		"planned_shifts": count, "planned_output": count * output_per_shift, "workers": chosen,
		"input_purchase": purchase, "input_cost": input_cost, "payroll": payroll,
		"reason": reason, "reductions": reductions, "skipped": skipped}
