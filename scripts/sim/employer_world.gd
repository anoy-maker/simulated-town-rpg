extends "res://scripts/sim/equilibrium_world.gd"
## Own-firm history projection and command dispatch; no new accounting operations.

const WorkerPolicy = preload("res://scripts/sim/labor_policy.gd")


func observe(actor: String, business: String = "") -> Dictionary:
	var obs: Dictionary = super(actor, business)
	if obs.business.is_empty():
		return obs
	var previous: int = maxi(0, _day - 1)
	var history = {"day": previous, "sold": {"wheat": 0, "flour": 0, "bread": 0},
		"bought": {"wheat": 0, "flour": 0, "bread": 0}, "revenue": 0, "input_spending": 0, "previous_forecast": null}
	for index in range(_events.size() - 1, -1, -1):
		var e: Dictionary = _events[index]
		if e.day < previous:
			break
		if e.day != previous:
			continue
		if e.action == "employer_plan" and e.actor == actor and e.target == business and history.previous_forecast == null:
			history.previous_forecast = e.details.proposal.get("forecast")
		if e.action != "purchase" or not e.success:
			continue
		if e.target == business:
			history.sold[e.details.item] += e.details.quantity
			history.revenue += e.details.total_price
		if e.actor == business:
			history.bought[e.details.item] += e.details.quantity
			history.input_spending += e.details.total_price
	obs.business["history"] = history
	return obs


func execute_plan(owner: String, business: String, proposal: Dictionary) -> bool:
	var details = {"proposal": proposal.duplicate(true)}
	if not _businesses.has(business) or _businesses[business].owner != owner:
		return _reject("employer_plan", owner, business, details, "not_owner")
	var workers: Variant = proposal.get("workers")
	var purchase: Variant = proposal.get("input_purchase")
	if not workers is Array or workers.size() > _businesses[business].assets.daily_slots or not purchase is Dictionary:
		return _reject("employer_plan", owner, business, details, "invalid_plan")
	var unique: Array = []
	var payroll: int = 0
	for worker in workers:
		if not worker is String or worker in unique or worker not in [_businesses[business].owner] + _businesses[business].employees:
			return _reject("employer_plan", owner, business, details, "invalid_worker")
		unique.append(worker)
		payroll += _wage(worker, business)
	var input_cost: int = 0
	if not purchase.is_empty():
		var item: String = Config.INDUSTRIES[_businesses[business].industry].input
		if item.is_empty() or purchase.get("type") != "purchase" or purchase.get("item") != item \
				or not purchase.get("seller") is String or not purchase.get("quantity") is int \
				or purchase.quantity <= 0 or purchase.quantity > 4 * workers.size() \
				or not purchase.get("unit_price") is int or purchase.unit_price != _unit_price(item):
			return _reject("employer_plan", owner, business, details, "invalid_input_purchase")
		input_cost = purchase.quantity * _unit_price(item)
	if _entities[business].money < payroll + input_cost:
		return _reject("employer_plan", owner, business, details, "insufficient_operating_funds")
	var first: int = _events.size()
	var input_ok: bool = true
	if not purchase.is_empty():
		var why: String = "inputs_for_prescribed_output" if proposal.get("forecast_source") == "prescribed_daily_output" else "inputs_for_expected_sales"
		input_ok = execute_decision(owner, "inputs", {"action": purchase, "reason": why}, business)
	if input_ok:
		for worker in workers:
			var why: String = "owner_first" if worker == owner else "employee_id_order"
			if proposal.get("staffing") == "rotating":
				why = "rotating_group_order"
			if execute_decision(owner, "schedule", {"action": {"type": "offer_shift"}, "reason": why}, business, worker):
				execute_decision(worker, "work", WorkerPolicy.decide(observe(worker), "work"), business)
	var execution = {"purchase_event_id": null, "offer_event_ids": [], "work_event_ids": [],
		"cash_after": _entities[business].money,
		"output_stock_after": _entities[business].inventory[Config.INDUSTRIES[_businesses[business].industry].output]}
	for e in _events.slice(first):
		if e.action == "purchase":
			execution.purchase_event_id = e.id
		if e.action == "shift_offered" and e.success:
			execution.offer_event_ids.append(e.id)
		if e.action == "work_shift" and e.success:
			execution.work_event_ids.append(e.id)
	var complete: bool = input_ok and execution.work_event_ids.size() == workers.size()
	details["execution"] = execution
	details["outcome"] = ("wait" if workers.is_empty() else "executed") if complete else ("partial" if not execution.work_event_ids.is_empty() else "rejected")
	if not complete:
		details["reason"] = "execution_rejected"
	_record("employer_plan", owner, business, complete, details)
	return complete
