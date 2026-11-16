extends "res://scripts/sim/world_state.gd"
## Business ownership, employment and paid productive shifts; historical worlds unchanged.

const Config = preload("res://scripts/sim/labor_config.gd")
var _businesses: Dictionary
var _employment: Dictionary
var _labor_used: Dictionary = {}
var _business_labor: Dictionary = {}
var _offers: Dictionary = {}
var _harvests: Dictionary = {}
var _meals: Dictionary = {}
var _rng = RandomNumberGenerator.new()


func _init(seed_value: int = 42, initial: Dictionary = Config.initial()) -> void:
	_businesses = initial.businesses.duplicate(true)
	_employment = initial.employment.duplicate(true)
	_rng.seed = seed_value
	var people: Dictionary = {}
	for entity in initial.entities:
		people[entity.id] = entity
		assert(entity.kind in _account_kinds())
		if entity.kind == "resident":
			assert(entity.labor_capacity == 1 and entity.skills is Array)
			for skill in entity.skills:
				assert(skill in Config.INDUSTRIES)
	for id in _businesses:
		var business: Dictionary = _businesses[id]
		assert(business.id == id and business.account == id and people[id].kind == "business")
		assert(business.industry in Config.INDUSTRIES and people[id].role == business.industry)
		assert(people[business.owner].kind == "resident" and business.owner not in business.employees)
		assert(business.assets.daily_slots is int and business.assets.daily_slots in range(1, 13))
		assert(business.assets.batches_per_shift == Config.INDUSTRIES[business.industry].batches)
		assert(business.output_target is int and business.output_target > 0 and business.output_target <= MAX_AMOUNT)
		assert(business.owner_compensation is int and business.owner_compensation >= _minimum_owner_compensation() and business.owner_compensation <= MAX_AMOUNT)
		var unique: Array = []
		for worker in business.employees:
			assert(worker not in unique and people[worker].kind == "resident")
			unique.append(worker)
			assert(_employment.has(worker) and _employment[worker].business == id)
	for worker in _employment:
		var job: Dictionary = _employment[worker]
		assert(job.worker == worker and _businesses.has(job.business) and job.active is bool)
		assert(worker in _businesses[job.business].employees)
		assert(job.wage is int and job.wage > 0 and job.wage <= MAX_AMOUNT)
	super(initial.entities)


func _account_kinds() -> Array:
	return ["resident", "business"]


func _consume_account_goods(actor: String, amount: Variant) -> bool:
	return super.consume(actor, amount)


func snapshot() -> Dictionary:
	var state: Dictionary = super()
	state.merge({"businesses": _businesses.duplicate(true), "employment": _employment.duplicate(true),
		"labor_used": _labor_used.duplicate(), "business_labor": _business_labor.duplicate(),
		"offers": _offers.duplicate(true), "harvest_opportunities": _harvests.duplicate(), "meals": _meals.duplicate()})
	return state


func advance_day() -> void:
	_labor_used.clear()
	_business_labor.clear()
	_offers.clear()
	_meals.clear()
	_harvests.clear()
	super()
	# Fixed opportunities are drawn even when work is skipped; agents cannot inspect them.
	var ids: Array = _entities.keys()
	ids.sort()
	for worker in ids:
		if _entities[worker].kind != "resident":
			continue
		for business in _businesses.values():
			if business.industry == "farmer" and (worker == business.owner or worker in business.employees):
				_harvests[worker] = _harvest_opportunity()
	_record("labor_environment", "world", "", true, {"opportunities": _harvests.duplicate()})


func _harvest_opportunity() -> int:
	return _rng.randi_range(2, 6)


func _unit_price(item: String) -> int:
	return Config.PRICES[item]


func _minimum_owner_compensation() -> int:
	return 1


func _account_transfer(actor: String, target: String, amount: Variant) -> bool:
	# Protected command adapter: public ordinary money transfers remain forbidden.
	return super.transfer_money(actor, target, amount)


func _wage(worker: String, business: String) -> int:
	if _businesses[business].owner == worker:
		return _businesses[business].owner_compensation
	var job: Dictionary = _employment.get(worker, {})
	return job.wage if job.get("business", "") == business and job.get("active", false) else 0


func _shift_error(worker: String, business: String) -> String:
	return _paid_shift_error(worker, business)


func _paid_shift_error(worker: String, business: String) -> String:
	if not _entities.has(worker) or _entities[worker].kind != "resident":
		return "unknown_worker"
	if not _businesses.has(business):
		return "unknown_business"
	if _day == 0:
		return "no_work_day"
	var firm: Dictionary = _businesses[business]
	var wage: int = _wage(worker, business)
	if wage == 0:
		return "not_employed"
	return _productive_shift_error(worker, business, wage)


func _productive_shift_error(worker: String, business: String, wage: int) -> String:
	var firm: Dictionary = _businesses[business]
	if firm.industry not in _entities[worker].skills:
		return "missing_skill"
	if _labor_used.get(worker, 0) >= _entities[worker].labor_capacity:
		return "daily_labor_limit"
	if _business_labor.get(business, 0) >= firm.assets.daily_slots:
		return "workplace_capacity"
	if _entities[business].money < wage:
		return "unfunded_payroll"
	if _entities[worker].money > MAX_AMOUNT - wage:
		return "worker_money_limit"
	var rule: Dictionary = Config.INDUSTRIES[firm.industry]
	if firm.industry == "farmer":
		if not _harvests.has(worker):
			return "no_harvest_opportunity"
		if _entities[business].inventory.wheat > MAX_AMOUNT - _harvests[worker]:
			return "output_limit"
	else:
		var recipe: Dictionary = RECIPES[rule.recipe]
		for item in recipe.inputs:
			if _entities[business].inventory[item] < recipe.inputs[item] * rule.batches:
				return "insufficient_inputs"
		for item in recipe.outputs:
			if _entities[business].inventory[item] > MAX_AMOUNT - recipe.outputs[item] * rule.batches:
				return "output_limit"
	return ""


func offer_shift(owner: String, business: String, worker: String) -> bool:
	var details = {"worker": worker}
	var reason: String = ""
	if not _businesses.has(business):
		reason = "unknown_business"
	elif owner != _businesses[business].owner:
		reason = "not_owner"
	else:
		reason = _shift_error(worker, business)
	var key: String = business + ":" + worker
	if reason.is_empty() and _offers.has(key):
		reason = "duplicate_offer"
	if not reason.is_empty():
		return _reject("shift_offered", owner, business, details, reason)
	var offer = {"id": key, "business": business, "worker": worker, "day": _day,
		"industry": _businesses[business].industry, "wage": _wage(worker, business), "labor": 1, "status": "offered"}
	_offers[key] = offer
	_record("shift_offered", owner, business, true, {"offer": offer})
	return true


func work_shift(worker: String, business: String) -> bool:
	var details = {"worker": worker, "labor": 1}
	var reason: String = _shift_error(worker, business)
	var key: String = business + ":" + worker
	if reason.is_empty() and (not _offers.has(key) or _offers[key].status != "offered" or _offers[key].day != _day):
		reason = "no_shift_offer"
	if not reason.is_empty():
		return _reject("work_shift", worker, business, details, reason)
	var wage: int = _wage(worker, business)
	# All wage, stock, capacity and labor checks precede every write. These native
	# commands cannot fail after the checks above in this synchronous execution.
	var paid: bool = _account_transfer(business, worker, wage)
	assert(paid)
	var payment_id: int = _events.back().id
	var produced: bool = _produce_for_shift(worker, business)
	assert(produced)
	var production_id: int = _events.back().id
	_labor_used[worker] = _labor_used.get(worker, 0) + 1
	_business_labor[business] = _business_labor.get(business, 0) + 1
	_offers[key].status = "accepted"
	_record("work_shift", worker, business, true, {"worker": worker, "labor": 1, "wage": wage,
		"offer_id": key, "payment_event_id": payment_id, "production_event_id": production_id})
	return true


func _produce_for_shift(worker: String, business: String) -> bool:
	var rule: Dictionary = Config.INDUSTRIES[_businesses[business].industry]
	return super.harvest(business, _harvests[worker]) if _businesses[business].industry == "farmer" else super.produce(business, rule.recipe, rule.batches)


func harvest(actor: String, amount: Variant) -> bool:
	return _reject("harvest", actor, "", {"amount": amount}, "paid_labor_required")


func produce(actor: String, recipe_id: String, batches: Variant = 1) -> bool:
	return _reject("produce", actor, "", {"recipe": recipe_id, "batches": batches}, "paid_labor_required")


func transfer_money(actor: String, target: String, amount: Variant) -> bool:
	return _reject("transfer_money", actor, target, {"amount": amount}, "payroll_only")


func transfer_item(actor: String, target: String, item: String, amount: Variant) -> bool:
	return _reject("transfer_item", actor, target, {"item": item, "amount": amount}, "market_only")


func purchase(buyer: String, seller: String, item: String, quantity: Variant, unit_price: Variant) -> bool:
	var valid: bool = _entities.has(buyer) and _businesses.has(seller) and item in ITEMS
	if valid:
		valid = Config.INDUSTRIES[_businesses[seller].industry].output == item and unit_price is int and unit_price == _unit_price(item)
		if _businesses.has(buyer):
			valid = valid and Config.INDUSTRIES[_businesses[buyer].industry].input == item
		else:
			valid = valid and item == "bread"
	if not valid:
		return _reject("purchase", buyer, seller, {"item": item, "quantity": quantity, "unit_price": unit_price}, "invalid_market_offer")
	return super(buyer, seller, item, quantity, unit_price)


func consume(actor: String, amount: Variant = 1) -> bool:
	var reason: String = ""
	if not _entities.has(actor) or _entities[actor].kind != "resident":
		reason = "not_resident"
	elif not amount is int or amount != 1:
		reason = "invalid_meal"
	elif _day == 0 or _meals.has(actor):
		reason = "no_meal_due"
	if not reason.is_empty():
		return _reject("consume", actor, "", {"item": "bread", "amount": amount}, reason)
	var eaten: bool = super(actor, amount)
	if eaten:
		_meals[actor] = true
	return eaten


func observe(actor: String, business: String = "") -> Dictionary:
	assert(_entities.has(actor) and _entities[actor].kind == "resident")
	var self_info: Dictionary = _entities[actor].duplicate(true)
	self_info["labor_used"] = _labor_used.get(actor, 0)
	var observation = {"day": _day, "self": self_info, "meals_due": not _meals.has(actor),
		"offers": [], "shift_offers": [], "business": {}}
	var ids: Array = _businesses.keys()
	ids.sort()
	for id in ids:
		var firm: Dictionary = _businesses[id]
		var item: String = Config.INDUSTRIES[firm.industry].output
		observation.offers.append({"seller": id, "item": item, "unit_price": _unit_price(item), "stock": _entities[id].inventory[item]})
	for offer in _offers.values():
		if offer.worker == actor and offer.status == "offered":
			observation.shift_offers.append(offer.duplicate(true))
	if _businesses.has(business) and _businesses[business].owner == actor:
		observation.business = _businesses[business].duplicate(true)
		observation.business["money"] = _entities[business].money
		observation.business["inventory"] = _entities[business].inventory.duplicate(true)
		observation.business["labor_used"] = _business_labor.get(business, 0)
		observation.business["workers"] = []
		for worker in [_businesses[business].owner] + _businesses[business].employees:
			observation.business.workers.append({"id": worker, "wage": _wage(worker, business),
				"qualified": _businesses[business].industry in _entities[worker].skills,
				"available": _entities[worker].labor_capacity > _labor_used.get(worker, 0)})
	return observation


func execute_decision(actor: String, phase: String, proposal: Dictionary, business: String = "", worker: String = "") -> bool:
	var action: Dictionary = proposal.get("action", {}) if proposal.get("action", {}) is Dictionary else {}
	var kind: String = action.get("type", "") if action.get("type", "") is String else ""
	var success: bool = false
	var reason: String = "invalid_action"
	var command_id: Variant = null
	var start: int = _events.size()
	if not _entities.has(actor) or _entities[actor].kind != "resident":
		reason = "unknown_actor"
	elif phase not in ["inputs", "schedule", "work", "food", "meal"]:
		pass
	elif kind == "wait":
		success = true
	elif phase in ["inputs", "schedule"] and (not _businesses.has(business) or _businesses[business].owner != actor):
		reason = "not_owner"
	elif phase == "inputs" and kind == "purchase" and action.get("seller") is String and action.get("item") is String:
		success = purchase(business, action.seller, action.item, action.get("quantity"), action.get("unit_price"))
	elif phase == "schedule" and kind == "offer_shift":
		success = offer_shift(actor, business, worker)
	elif phase == "work" and kind == "work_shift":
		success = work_shift(actor, business)
	elif phase == "food" and kind == "purchase" and action.get("seller") is String:
		success = purchase(actor, action.seller, "bread", action.get("quantity"), action.get("unit_price"))
	elif phase == "meal" and kind == "consume":
		success = consume(actor)
	if _events.size() > start:
		command_id = _events.back().id
		reason = _events.back().details.get("reason", "")
	_record("labor_decision", actor, business, success, {"phase": phase, "worker": worker,
		"selected_action": action, "reason": proposal.get("reason", "unspecified"),
		"outcome": ("wait" if kind == "wait" else "executed") if success else "rejected",
		"execution_reason": "" if success else reason, "command_event_id": command_id})
	return success
