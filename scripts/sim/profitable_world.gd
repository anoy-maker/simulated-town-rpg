extends "res://scripts/sim/equilibrium_world.gd"
## M14-only contracts and realized cash distributions; native commands own all money/goods.

const Terms = preload("res://scripts/sim/profitable_config.gd")
var _cash_results: Dictionary = {}
var _contract_day_closed: bool = true
var _day_start: int = 0


func _init(seed_value: int = 42, initial: Dictionary = Terms.initial()) -> void:
	for business in initial.businesses:
		_cash_results[business] = {"sales": 0, "inputs": 0, "payroll": 0, "distributions": 0}
	for job in initial.employment.values():
		var employees: Array = initial.businesses[job.business].employees.duplicate()
		employees.sort()
		assert(job.wage == Terms.WAGE and job.contract == {"cycle_days": 3, "shifts_per_cycle": 2,
			"cycle_compensation": 12, "phases": Terms.PHASES[employees.find(job.worker)]})
	super(seed_value, initial)


func _minimum_owner_compensation() -> int:
	return 0


func snapshot() -> Dictionary:
	var state: Dictionary = super()
	state["cash_results"] = _cash_results.duplicate(true)
	state["contract_day_closed"] = _contract_day_closed
	return state


func _record(action: String, actor: String, target: String, success: bool, details: Dictionary) -> void:
	# Capture the actual failed-work constraint, which can differ from an earlier offer.
	if action == "work_shift" and not success:
		details = details.duplicate(true)
		details["constraints"] = _constraints(target, actor)
	# Derived books update only from successful native financial receipts, once.
	if success and action == "purchase":
		if _cash_results.has(actor):
			_cash_results[actor].inputs += details.total_price
		if _cash_results.has(target):
			_cash_results[target].sales += details.total_price
	elif success and action == "transfer_money" and _cash_results.has(actor):
		var category: String = "distributions" if target == _businesses[actor].owner else "payroll"
		_cash_results[actor][category] += details.amount
	super(action, actor, target, success, details)


func advance_day() -> void:
	if not _contract_day_closed:
		close_contract_day()
	_contract_day_closed = false
	_day_start = _events.size()
	super()
	for business in Config.BUSINESS_ORDER:
		for worker in Terms.workers(_businesses[business], _day):
			_record("contract_due", worker, business, true, {"contract_id": _contract_id(business, worker),
				"employer": _businesses[business].owner, "expected_compensation": Terms.WAGE, "phase": (_day - 1) % 3 + 1})


func _contract_id(business: String, worker: String) -> String:
	return "%d:%s:%s" % [_day, business, worker]


func _settlement_ready() -> bool:
	if _day == 0:
		return false
	var attempted: Dictionary = {}
	for e in _events.slice(_day_start):
		if e.action == "consume" and _entities.has(e.actor) and _entities[e.actor].kind == "resident" \
				and e.details.get("amount") == 1 and e.details.get("reason", "") in ["", "insufficient_stock"]:
			attempted[e.actor] = true
	return attempted.size() == 12


func _shift_error(worker: String, business: String) -> String:
	if _businesses.has(business) and _businesses[business].owner == worker:
		return "owner_management_only"
	var reason: String = super(worker, business)
	if reason.is_empty():
		if _contract_day_closed or _settlement_ready():
			return "productive_day_finished"
		if worker not in Terms.workers(_businesses[business], _day):
			return "no_contract_shift_due"
	return reason


func _constraints(business: String, worker: String) -> Dictionary:
	if not _businesses.has(business) or not _entities.has(worker):
		return {}
	var firm: Dictionary = _businesses[business]
	return {"cash": _entities[business].money, "inventory": _entities[business].inventory.duplicate(),
		"wage": _wage(worker, business), "qualified": firm.industry in _entities[worker].get("skills", []),
		"employee_active": _employment.get(worker, {}).get("active", false),
		"worker_labor_used": _labor_used.get(worker, 0), "business_labor_used": _business_labor.get(business, 0),
		"business_capacity": firm.assets.daily_slots}


func offer_shift(owner: String, business: String, worker: String) -> bool:
	var before: Dictionary = _constraints(business, worker)
	var authorized: bool = _businesses.has(business) and _businesses[business].owner == owner \
		and _day > 0 and worker in Terms.workers(_businesses[business], _day)
	var success: bool = super(owner, business, worker)
	var command: Dictionary = _events.back()
	_record("contract_attempt", owner, business, success, {"worker": worker, "authorized_attempt": authorized,
		"command_event_id": command.id, "constraints": before, "reason": command.details.get("reason", "")})
	return success


func profit_budget(business: String) -> Dictionary:
	assert(_businesses.has(business))
	var book: Dictionary = _cash_results[business]
	var realized: int = book.sales - book.inputs - book.payroll - book.distributions
	return {"cash": _entities[business].money, "capital_floor": Terms.CAPITAL,
		"realized_remaining": realized, "eligible": maxi(0, mini(realized, _entities[business].money - Terms.CAPITAL)),
		"cumulative": book.duplicate()}


func settle_profit(owner: String, business: String) -> bool:
	var details: Dictionary = {}
	var reason: String = ""
	if not _businesses.has(business):
		reason = "unknown_business"
	elif _businesses[business].owner != owner:
		reason = "not_owner"
	elif not _settlement_ready():
		reason = "household_phase_incomplete"
	if not reason.is_empty():
		return _reject("profit_distribution", owner, business, details, reason)
	var budget: Dictionary = profit_budget(business)
	if budget.eligible == 0:
		return true # No zero-valued distribution or artificial expected-profit payment.
	details = {"amount": budget.eligible, "capital_floor": Terms.CAPITAL, "cash_before": budget.cash,
		"realized_before": budget.realized_remaining, "cumulative_before": budget.cumulative}
	if _entities[owner].money > MAX_AMOUNT - budget.eligible:
		return _reject("profit_distribution", owner, business, details, "owner_money_limit")
	var paid: bool = _account_transfer(business, owner, budget.eligible)
	assert(paid)
	details["payment_event_id"] = _events.back().id
	details["business_cash_after"] = _entities[business].money
	_record("profit_distribution", owner, business, true, details)
	return true


func close_contract_day() -> void:
	if _contract_day_closed:
		return
	var due: int = 0
	var completed: int = 0
	var history: Array = _events.slice(_day_start)
	for business in Config.BUSINESS_ORDER:
		for worker in Terms.workers(_businesses[business], _day):
			due += 1
			var attempt: Dictionary = {}
			var work: Dictionary = {}
			var failure: String = ""
			var failure_constraints: Dictionary = {}
			for e in history:
				if e.target != business:
					continue
				if e.action == "contract_attempt" and e.details.worker == worker and e.details.authorized_attempt:
					attempt = e
					if not e.success:
						failure = e.details.reason
				if e.action == "work_shift" and e.actor == worker:
					if e.success:
						work = e
					else:
						failure = e.details.reason
						failure_constraints = e.details.get("constraints", {})
			var fulfilled: bool = not work.is_empty()
			completed += 1 if fulfilled else 0
			var reason: String = "fulfilled" if fulfilled else ("employer_did_not_schedule" if attempt.is_empty() else failure if not failure.is_empty() else "offered_not_completed")
			_record("contract_shift", worker, business, fulfilled, {"contract_id": _contract_id(business, worker),
				"employer": _businesses[business].owner, "attempted": not attempt.is_empty(), "completed": fulfilled,
				"expected_compensation": Terms.WAGE, "actual_compensation": work.details.wage if fulfilled else 0,
				"reason": reason, "attempt_event_id": null if attempt.is_empty() else attempt.id,
				"shift_event_id": null if work.is_empty() else work.id,
				"constraints": failure_constraints if not fulfilled and not failure_constraints.is_empty() else _constraints(business, worker) if attempt.is_empty() else attempt.details.constraints})
	_contract_day_closed = true
	var business_cash: Dictionary = {}
	var household_cash: Dictionary = {}
	var goods = {"wheat": 0, "flour": 0, "bread": 0}
	for id in _entities:
		var entity: Dictionary = _entities[id]
		if entity.kind == "business":
			business_cash[id] = entity.money
		else:
			household_cash[id] = entity.money
		for item in goods:
			goods[item] += entity.inventory[item]
	_record("contract_day_closed", "world", "", true, {"due": due, "completed": completed, "breaches": due - completed,
		"business_cash": business_cash, "household_cash": household_cash, "goods": goods, "cash_results": _cash_results.duplicate(true)})
