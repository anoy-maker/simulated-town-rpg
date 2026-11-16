extends "res://scripts/sim/profitable_world.gd"
## M15 authority only. No entrepreneurial or applicant decision policy.
const Enterprise = preload("res://scripts/sim/enterprise_config.gd")
var _assets: Dictionary = {}
var _affiliations: Dictionary = {}
var _resignations: Dictionary = {}
var _pending_hires: Dictionary = {}
var _postings: Dictionary = {}
var _applications: Dictionary = {}
var _transfer_purpose: String = "wage"


func _init(seed_value: int = 42, initial: Dictionary = Enterprise.initial()) -> void:
	_assets = initial.productive_assets.duplicate(true)
	for id in _assets:
		var asset: Dictionary = _assets[id]
		assert(asset.price is int and asset.price >= 0 and asset.price <= MAX_AMOUNT and asset.capacity is int and asset.capacity > 0)
	for worker in initial.employment:
		if initial.employment[worker].active:
			_affiliations[worker] = {"business": initial.employment[worker].business, "kind": "employee"}
	super(seed_value, initial)
	for asset in _assets.values():
		assert(_entities.has(asset.holder))


func _account_kinds() -> Array:
	return super() + ["external"]


func _valid_entity_role(entity: Dictionary) -> bool:
	return entity.role == "account" if entity.get("kind") == "external" else super(entity)


func _new_cash_book() -> Dictionary:
	return super().merged({"capital_contributions": 0, "capital_purchases": 0, "capital_asset_sales": 0})


func snapshot() -> Dictionary:
	var state: Dictionary = super()
	state.merge({"productive_assets": _assets.duplicate(true), "affiliations": _affiliations.duplicate(true),
		"resignations": _resignations.duplicate(true), "pending_hires": _pending_hires.duplicate(true),
		"job_postings": _postings.duplicate(true), "applications": _applications.duplicate(true)})
	return state


func _record(action: String, actor: String, target: String, success: bool, details: Dictionary) -> void:
	if action == "contract_day_closed":
		details = details.duplicate(true)
		details["external_cash"] = {}
		for id in _entities:
			if _entities[id].kind == "external":
				details.external_cash[id] = _entities[id].money
	if success and action == "transfer_money":
		details = details.duplicate(true)
		details["purpose"] = _transfer_purpose
		if _transfer_purpose == "capital_contribution":
			_cash_results[target].capital_contributions += details.amount
		elif _transfer_purpose == "asset_purchase" and _cash_results.has(target):
			_cash_results[target].capital_asset_sales += details.amount
	super(action, actor, target, success, details)


func _book_transfer(actor: String, target: String, amount: int) -> void:
	var category: String = {"asset_purchase": "capital_purchases", "distribution": "distributions", "wage": "payroll"}[_transfer_purpose]
	_cash_results[actor][category] += amount


func _pay(actor: String, target: String, amount: int, purpose: String) -> bool:
	var previous: String = _transfer_purpose
	_transfer_purpose = purpose
	var result: bool = _account_transfer(actor, target, amount)
	_transfer_purpose = previous
	return result


func _contract_business_ids() -> Array:
	var ids: Array = _businesses.keys()
	ids.sort()
	return ids


func _contract_phase(worker: String) -> int:
	var job: Dictionary = _employment[worker]
	return (_day - job.get("start_day", 1)) % job.contract.cycle_days + 1


func _contract_wage(worker: String) -> int:
	return _employment[worker].wage


func _contract_workers(business: String) -> Array:
	var result: Array = []
	for worker in _employment:
		var job: Dictionary = _employment[worker]
		if job.business == business and job.active and _contract_phase(worker) in job.contract.phases:
			result.append(worker)
	result.sort()
	return result


func advance_day() -> void:
	if not _contract_day_closed:
		close_contract_day()
	_apply_boundary(_day + 1)
	super()


func _apply_boundary(next_day: int) -> void:
	var workers: Array = _affiliations.keys()
	workers.sort()
	for worker in workers:
		var affiliation: Dictionary = _affiliations[worker]
		var expired: bool = affiliation.kind == "employee" and _employment[worker].get("end_day", 0) > 0 and _employment[worker].end_day <= next_day
		if not _resignations.has(worker) and not expired:
			continue
		if affiliation.kind == "employee":
			_employment[worker].active = false
			_employment[worker]["end_day"] = next_day
		_affiliations.erase(worker)
		_resignations.erase(worker)
		_record("employment_ended", worker, affiliation.business, true, {"affiliation": affiliation.duplicate(true),
			"job": _employment.get(worker, {}).duplicate(true), "effective_day": next_day, "reason": "duration_complete" if expired else "resigned"})
	workers = _pending_hires.keys()
	workers.sort()
	for worker in workers:
		var pending: Dictionary = _pending_hires[worker]
		assert(not _affiliations.has(worker)) # Acceptance reserves this worker's next affiliation.
		var posting: Dictionary = _postings[pending.posting]
		var phases: Array = []
		for phase in range(1, posting.guaranteed_shifts + 1):
			phases.append(phase)
		var job = {"worker": worker, "business": posting.business, "wage": posting.wage, "active": true,
			"start_day": next_day, "end_day": next_day + posting.duration_days,
			"contract": {"cycle_days": posting.cycle_days, "shifts_per_cycle": posting.guaranteed_shifts,
				"cycle_compensation": posting.guaranteed_shifts * posting.wage, "phases": phases}}
		_employment[worker] = job
		_affiliations[worker] = {"business": posting.business, "kind": "employee"}
		if worker not in _businesses[posting.business].employees:
			_businesses[posting.business].employees.append(worker)
		posting.reserved -= 1
		posting.filled += 1
		posting.active = posting.filled < posting.vacancies
		_applications[pending.application_id].status = "started"
		_pending_hires.erase(worker)
		_record("employment_started", worker, posting.business, true, {"posting": posting.id, "job": job.duplicate(true),
			"affiliation": _affiliations[worker].duplicate(), "effective_day": next_day})


func request_resignation(actor: String, business: String) -> bool:
	if not _affiliations.has(actor) or _affiliations[actor].business != business:
		return _reject("resignation_requested", actor, business, {}, "no_matching_affiliation")
	if _resignations.has(actor):
		return _reject("resignation_requested", actor, business, {}, "already_requested")
	_resignations[actor] = {"business": business, "effective_day": _day + 1}
	_record("resignation_requested", actor, business, true, _resignations[actor])
	return true


func start_self_employment(owner: String, business: String) -> bool:
	if not _businesses.has(business) or _businesses[business].owner != owner:
		return _reject("self_employment_started", owner, business, {}, "not_owner")
	if _affiliations.has(owner) or _pending_hires.has(owner):
		return _reject("self_employment_started", owner, business, {}, "already_committed")
	if _day == 0 or _contract_day_closed or _labor_used.get(owner, 0) > 0:
		return _reject("self_employment_started", owner, business, {}, "not_work_boundary")
	_affiliations[owner] = {"business": business, "kind": "self_employed"}
	_record("self_employment_started", owner, business, true, {"affiliation": _affiliations[owner].duplicate()})
	return true


func _asset_error(business: String) -> String:
	for kind in Enterprise.REQUIREMENTS[_businesses[business].industry]:
		var found: bool = false
		for asset in _assets.values():
			if asset.holder == business and asset.kind == kind and asset.industry == _businesses[business].industry:
				found = true
		if not found:
			return "missing_" + kind
	return ""


func _asset_capacity(business: String) -> int:
	var capacity: int = _businesses[business].assets.daily_slots
	for kind in Enterprise.REQUIREMENTS[_businesses[business].industry]:
		var available: int = 0
		for asset in _assets.values():
			if asset.holder == business and asset.kind == kind and asset.industry == _businesses[business].industry:
				available = maxi(available, asset.capacity)
		capacity = mini(capacity, available)
	return capacity


func _shift_error(worker: String, business: String) -> String:
	var reason: String = _paid_shift_error(worker, business)
	if not reason.is_empty():
		return reason
	if not _affiliations.has(worker) or _affiliations[worker] != {"business": business, "kind": "employee"}:
		return "wrong_affiliation"
	if _contract_day_closed:
		return "productive_day_finished"
	var setup: String = _asset_error(business)
	return setup if not setup.is_empty() else "productive_asset_capacity" if _business_labor.get(business, 0) >= _asset_capacity(business) else ""


func owner_work_shift(owner: String, business: String) -> bool:
	var reason: String = ""
	if not _businesses.has(business) or _businesses[business].owner != owner:
		reason = "not_owner"
	elif not _affiliations.has(owner) or _affiliations[owner] != {"business": business, "kind": "self_employed"}:
		reason = "wrong_affiliation"
	elif _day == 0 or _contract_day_closed:
		reason = "no_work_day"
	else:
		reason = _asset_error(business)
		if reason.is_empty() and _business_labor.get(business, 0) >= _asset_capacity(business):
			reason = "productive_asset_capacity"
		if reason.is_empty():
			reason = _productive_shift_error(owner, business, 0)
	if not reason.is_empty():
		return _reject("owner_work_shift", owner, business, {"wage": 0}, reason)
	var produced: bool = _produce_for_shift(owner, business)
	assert(produced)
	var production_id: int = _events.back().id
	_labor_used[owner] = _labor_used.get(owner, 0) + 1
	_business_labor[business] = _business_labor.get(business, 0) + 1
	_record("owner_work_shift", owner, business, true, {"wage": 0, "labor": 1, "production_event_id": production_id})
	return true


func found_business(owner: String, id: String, industry: String, capital: Variant = 0) -> bool:
	var reason: String = ""
	if not _entities.has(owner) or _entities[owner].kind != "resident":
		reason = "not_resident"
	elif id.is_empty() or _entities.has(id):
		reason = "invalid_business_id"
	elif industry not in Config.INDUSTRIES:
		reason = "unknown_industry"
	elif not capital is int or capital < 0 or capital > MAX_AMOUNT:
		reason = "invalid_amount"
	elif _entities[owner].money < capital:
		reason = "insufficient_money"
	if not reason.is_empty():
		return _reject("business_founded", owner, id, {"capital": capital}, reason)
	_entities[id] = {"id": id, "name": id, "role": industry, "kind": "business", "money": 0, "inventory": {"wheat": 0, "flour": 0, "bread": 0}}
	_businesses[id] = {"id": id, "account": id, "industry": industry, "owner": owner, "employees": [],
		"assets": {"daily_slots": 1, "batches_per_shift": Config.INDUSTRIES[industry].batches},
		"owner_compensation": 0, "output_target": Config.INDUSTRIES[industry].target,
		"distribution_policy": {"mode": "retain", "reserve": 24}}
	_cash_results[id] = _new_cash_book()
	_record("business_founded", owner, id, true, {"entity": _entities[id].duplicate(true), "business": _businesses[id].duplicate(true), "book": _cash_results[id].duplicate()})
	if capital > 0:
		var contributed: bool = contribute_capital(owner, id, capital)
		assert(contributed)
	return true


func contribute_capital(owner: String, business: String, amount: Variant) -> bool:
	var reason: String = "not_owner" if not _businesses.has(business) or _businesses[business].owner != owner else _actor_amount_error(owner, amount)
	if reason.is_empty() and (_entities[owner].money < amount or _entities[business].money > MAX_AMOUNT - amount):
		reason = "capital_funds_or_limit"
	if not reason.is_empty():
		return _reject("capital_contribution", owner, business, {"amount": amount}, reason)
	var paid: bool = _pay(owner, business, amount, "capital_contribution")
	assert(paid)
	_record("capital_contribution", owner, business, true, {"amount": amount, "payment_event_id": _events.back().id})
	return true


func buy_asset(owner: String, business: String, id: String) -> bool:
	var reason: String = ""
	if not _businesses.has(business) or _businesses[business].owner != owner:
		reason = "not_owner"
	elif not _assets.has(id):
		reason = "unknown_asset"
	elif _assets[id].holder == business:
		reason = "already_owned"
	elif not _assets[id].for_sale:
		reason = "asset_not_offered"
	elif _assets[id].industry != _businesses[business].industry:
		reason = "wrong_asset_industry"
	elif _entities[business].money < _assets[id].price or _entities[_assets[id].holder].money > MAX_AMOUNT - _assets[id].price:
		reason = "asset_funds_or_limit"
	if not reason.is_empty():
		return _reject("asset_purchased", owner, business, {"asset": id}, reason)
	var asset: Dictionary = _assets[id]
	var seller: String = asset.holder
	var payment: Variant = null
	if asset.price > 0:
		var paid: bool = _pay(business, seller, asset.price, "asset_purchase")
		assert(paid)
		payment = _events.back().id
	asset.holder = business
	asset.for_sale = false
	_businesses[business].assets.daily_slots = mini(_businesses[business].assets.daily_slots, asset.capacity)
	_record("asset_purchased", owner, business, true, {"asset": id, "seller": seller, "price": asset.price, "payment_event_id": payment,
		"asset_state": asset.duplicate(true), "operational": _asset_error(business).is_empty()})
	return true


func set_distribution_policy(owner: String, business: String, mode: String, reserve: Variant) -> bool:
	if not _businesses.has(business) or _businesses[business].owner != owner:
		return _reject("distribution_policy", owner, business, {}, "not_owner")
	if mode not in ["retain", "half", "full"] or not reserve is int or reserve < 0 or reserve > MAX_AMOUNT:
		return _reject("distribution_policy", owner, business, {}, "invalid_policy")
	_businesses[business].distribution_policy = {"mode": mode, "reserve": reserve}
	_record("distribution_policy", owner, business, true, _businesses[business].distribution_policy)
	return true


func profit_budget(business: String) -> Dictionary:
	var book: Dictionary = _cash_results[business]
	var realized: int = book.sales - book.inputs - book.payroll - book.distributions
	var policy: Dictionary = _businesses[business].distribution_policy
	@warning_ignore("integer_division")
	var permitted: int = 0 if policy.mode == "retain" else maxi(0, realized) / (2 if policy.mode == "half" else 1)
	return {"eligible": mini(permitted, maxi(0, _entities[business].money - policy.reserve)),
		"realized_remaining": realized, "cash": _entities[business].money, "reserve": policy.reserve, "cumulative": book.duplicate()}


func settle_profit(owner: String, business: String) -> bool:
	if not _businesses.has(business) or _businesses[business].owner != owner:
		return _reject("profit_distribution", owner, business, {}, "not_owner")
	var budget: Dictionary = profit_budget(business)
	if budget.eligible == 0:
		return true
	if _entities[owner].money > MAX_AMOUNT - budget.eligible:
		return _reject("profit_distribution", owner, business, {}, "owner_money_limit")
	var paid: bool = _pay(business, owner, budget.eligible, "distribution")
	assert(paid)
	_record("profit_distribution", owner, business, true, {"amount": budget.eligible, "payment_event_id": _events.back().id,
		"cash_before": budget.cash, "realized_before": budget.realized_remaining, "reserve": budget.reserve,
		"policy": _businesses[business].distribution_policy.duplicate(), "cumulative_before": budget.cumulative,
		"business_cash_after": _entities[business].money})
	return true


func consume_external(actor: String) -> bool:
	if not _entities.has(actor) or _entities[actor].kind != "external":
		return _reject("external_consumption", actor, "", {}, "not_external")
	var amount: int = _entities[actor].inventory.bread
	if amount == 0:
		return true
	return _consume_account_goods(actor, amount)


func consume(actor: String, amount: Variant = 1) -> bool:
	if _entities.has(actor) and _entities[actor].kind == "external":
		return _reject("external_consumption", actor, "", {}, "use_external_consume")
	return super(actor, amount)


func post_job(owner: String, business: String, id: String, wage: Variant, minimum: Variant, cycle: Variant, duration: Variant, vacancies: Variant = 1) -> bool:
	if not _businesses.has(business) or _businesses[business].owner != owner:
		return _reject("job_posted", owner, business, {}, "not_owner")
	if id.is_empty() or _postings.has(id):
		return _reject("job_posted", owner, business, {}, "invalid_posting_id")
	if not wage is int or wage <= 0 or wage > MAX_AMOUNT or not minimum is int or not cycle is int \
			or cycle < 1 or cycle > 30 or minimum < 0 or minimum > cycle or not duration is int or duration < 1 or duration > 365 \
			or not vacancies is int or vacancies < 1 or vacancies > 12:
		return _reject("job_posted", owner, business, {}, "invalid_terms")
	@warning_ignore("integer_division")
	if minimum > 0 and (wage > MAX_AMOUNT / minimum or duration % cycle != 0):
		return _reject("job_posted", owner, business, {}, "invalid_guarantee_period")
	var posting = {"id": id, "employer": owner, "business": business, "role": _businesses[business].industry,
		"wage": wage, "guaranteed_shifts": minimum, "cycle_days": cycle, "duration_days": duration,
		"required_skills": [_businesses[business].industry], "vacancies": vacancies, "reserved": 0, "filled": 0, "active": true}
	_postings[id] = posting
	_record("job_posted", owner, business, true, {"posting": posting.duplicate(true)})
	return true


func job_board(actor: String) -> Array:
	assert(_entities.has(actor) and _entities[actor].kind == "resident")
	var ids: Array = _postings.keys()
	ids.sort()
	return ids.map(func(id): return _postings[id].duplicate(true))


func observe(actor: String, business: String = "") -> Dictionary:
	var observation: Dictionary = super(actor, business)
	observation["local_jobs"] = job_board(actor)
	observation["affiliation"] = _affiliations.get(actor, {}).duplicate(true)
	return observation


func _eligible_applicant(worker: String, posting: Dictionary) -> String:
	if not _entities.has(worker) or _entities[worker].kind != "resident":
		return "not_resident"
	if worker == posting.employer:
		return "owner_self_hiring"
	if _affiliations.has(worker) or _pending_hires.has(worker):
		return "already_committed"
	for skill in posting.required_skills:
		if skill not in _entities[worker].skills:
			return "missing_skill"
	return ""


func apply_for_job(worker: String, id: String) -> bool:
	if not _postings.has(id) or not _postings[id].active:
		return _reject("application_submitted", worker, id, {}, "inactive_posting")
	var posting: Dictionary = _postings[id]
	var key: String = id + ":" + worker
	var reason: String = _eligible_applicant(worker, posting)
	if reason.is_empty() and (_applications.has(key) or posting.filled + posting.reserved >= posting.vacancies):
		reason = "duplicate_or_no_vacancy"
	if not reason.is_empty():
		return _reject("application_submitted", worker, id, {}, reason)
	_applications[key] = {"id": key, "worker": worker, "posting": id, "status": "applied"}
	_record("application_submitted", worker, posting.business, true, {"application": _applications[key].duplicate(true)})
	return true


func make_job_offer(owner: String, application_id: String) -> bool:
	if not _applications.has(application_id):
		return _reject("job_offer_made", owner, application_id, {}, "unknown_application")
	var application: Dictionary = _applications[application_id]
	var posting: Dictionary = _postings[application.posting]
	var reason: String = ""
	if owner != posting.employer or _businesses[posting.business].owner != owner:
		reason = "not_owner"
	elif not posting.active or posting.filled + posting.reserved >= posting.vacancies:
		reason = "no_vacancy"
	elif application.status != "applied":
		reason = "application_not_available"
	else:
		reason = _eligible_applicant(application.worker, posting)
	if not reason.is_empty():
		return _reject("job_offer_made", owner, posting.business, {}, reason)
	application.status = "offered"
	posting.reserved += 1
	_record("job_offer_made", owner, posting.business, true, {"application_id": application_id, "worker": application.worker, "posting": posting.id})
	return true


func accept_job_offer(worker: String, application_id: String) -> bool:
	if not _applications.has(application_id):
		return _reject("offer_accepted", worker, application_id, {}, "unknown_application")
	var application: Dictionary = _applications[application_id]
	var posting: Dictionary = _postings[application.posting]
	var reason: String = ""
	if worker != application.worker:
		reason = "not_applicant"
	elif application.status != "offered" or not posting.active or posting.reserved <= 0:
		reason = "no_available_offer"
	else:
		reason = _eligible_applicant(worker, posting)
	if not reason.is_empty():
		return _reject("offer_accepted", worker, posting.business, {}, reason)
	application.status = "accepted"
	_pending_hires[worker] = {"posting": posting.id, "application_id": application_id, "effective_day": _day + 1}
	_record("offer_accepted", worker, posting.business, true, {"application_id": application_id, "pending": _pending_hires[worker].duplicate(true)})
	return true
