extends "res://scripts/sim/agent_world.gd"
## A request becomes one prepaid agreement; records are retained permanently.

var _requests: Dictionary = {}


func snapshot() -> Dictionary:
	var state: Dictionary = super()
	state["requests"] = _requests.duplicate(true)
	return state


func observe(actor: String) -> Dictionary:
	var observation: Dictionary = super(actor)
	var visible: Array = []
	for request in _requests.values():
		if request.status not in ["open", "accepted"]:
			continue
		if request.buyer == actor or request.supplier == actor \
				or (request.status == "open" and _can_sell(actor, request.item)):
			visible.append(request.duplicate(true))
	observation["requests"] = visible
	return observation


func post_request(buyer: String, item: String, quantity: Variant) -> bool:
	var details = {"buyer": buyer, "item": item, "quantity": quantity}
	var reason: String = _actor_amount_error(buyer, quantity)
	if reason.is_empty() and item not in ITEMS:
		reason = "unknown_item"
	if not reason.is_empty():
		return _reject("request_posted", buyer, "", details, reason)
	if _can_sell(buyer, item):
		return _reject("request_posted", buyer, buyer, details, "self_supply")
	@warning_ignore("integer_division")
	var quantity_limit: int = MAX_AMOUNT / Trading.PRICES[item]
	if quantity > quantity_limit:
		return _reject("request_posted", buyer, "", details, "payment_limit")
	var payment: int = quantity * Trading.PRICES[item]
	if _entities[buyer].money < payment:
		return _reject("request_posted", buyer, "", details, "insufficient_money")
	if _entities[buyer].inventory[item] > MAX_AMOUNT - quantity:
		return _reject("request_posted", buyer, "", details, "buyer_inventory_limit")
	for request in _requests.values():
		if request.buyer == buyer and request.item == item and request.status in ["open", "accepted"]:
			return _reject("request_posted", buyer, "", details, "active_request_exists")
	var request_id: String = "r%d" % (_requests.size() + 1)
	var request = {"id": request_id, "buyer": buyer, "supplier": "", "item": item,
		"quantity": quantity, "unit_price": Trading.PRICES[item], "payment": payment, "status": "open",
		"created_day": _day, "accepted_day": null, "fulfilled_day": null, "closed_day": null, "close_reason": "",
		"payment_event_id": null, "item_event_id": null}
	_requests[request_id] = request
	_record("request_posted", buyer, _request_target(item), true, {"request": request})
	return true


func accept_request(supplier: String, request_id: String) -> bool:
	var details = {"request_id": request_id}
	var reason: String = _request_error(supplier, request_id, "open")
	if not reason.is_empty():
		return _reject("agreement_accepted", supplier, "", details, reason)
	var request: Dictionary = _requests[request_id]
	if not _can_sell(supplier, request.item) or request.buyer == supplier:
		return _reject("agreement_accepted", supplier, request.buyer, details, "ineligible_supplier")
	for existing in _requests.values():
		if existing.status == "accepted" and existing.supplier == supplier and existing.item == request.item:
			return _reject("agreement_accepted", supplier, request.buyer, details, "supplier_busy")
	# All commitment checks precede payment. No fallible operation follows it.
	var paid: bool = transfer_money(request.buyer, supplier, request.payment)
	details["payment_event_id"] = _events.back().id
	if not paid:
		return _reject("agreement_accepted", supplier, request.buyer, details, _events.back().details.reason)
	request.supplier = supplier
	request.status = "accepted"
	request.accepted_day = _day
	request.payment_event_id = details.payment_event_id
	details["request"] = request
	_record("agreement_accepted", supplier, request.buyer, true, details)
	return true


func fulfill_request(supplier: String, request_id: String) -> bool:
	var details = {"request_id": request_id}
	var reason: String = _request_error(supplier, request_id, "accepted")
	if not reason.is_empty():
		return _reject("agreement_fulfilled", supplier, "", details, reason)
	var request: Dictionary = _requests[request_id]
	if request.supplier != supplier:
		return _reject("agreement_fulfilled", supplier, request.buyer, details, "not_supplier")
	var delivered: bool = transfer_item(supplier, request.buyer, request.item, request.quantity)
	details["item_event_id"] = _events.back().id
	if not delivered:
		return _reject("agreement_fulfilled", supplier, request.buyer, details, _events.back().details.reason)
	request.status = "fulfilled"
	request.fulfilled_day = _day
	request.item_event_id = details.item_event_id
	details["request"] = request
	_record("agreement_fulfilled", supplier, request.buyer, true, details)
	return true


func close_request(buyer: String, request_id: String, reason: String) -> bool:
	var details = {"request_id": request_id}
	if not _entities.has(buyer) or not _requests.has(request_id):
		return _reject("request_closed", buyer, "", details, "unknown_participant_or_request")
	var request: Dictionary = _requests[request_id]
	if request.buyer != buyer:
		return _reject("request_closed", buyer, "", details, "not_buyer")
	if request.status not in ["open", "accepted"] or reason.strip_edges().is_empty():
		return _reject("request_closed", buyer, "", details, "invalid_closure")
	# Closing an accepted request explicitly waives the claim; it never refunds.
	request.status = "closed"
	request.closed_day = _day
	request.close_reason = reason
	_record("request_closed", buyer, request.supplier, true, {"request": request})
	return true


func record_outstanding() -> void:
	for request in _requests.values():
		if request.status == "accepted":
			_record("agreement_outstanding", request.supplier, request.buyer, true, {"request": request})


func _request_error(actor: String, request_id: String, status: String) -> String:
	if not _entities.has(actor):
		return "unknown_actor"
	if not _requests.has(request_id):
		return "unknown_request"
	if _requests[request_id].status != status:
		return "invalid_status"
	return ""


func execute_decision(actor: String, phase: String, proposal: Dictionary, harvest_yield: int = 0) -> bool:
	if phase not in ["requests", "accept", "delivery"]:
		return super(actor, phase, proposal, harvest_yield)
	var action: Dictionary = proposal.get("action", {}) if proposal.get("action", {}) is Dictionary else {}
	var allowed = {"requests": ["post_request", "close_request", "wait"],
		"accept": ["accept_request", "wait"], "delivery": ["fulfill_request", "wait"]}
	var before_count: int = _events.size()
	var success: bool = false
	var reason: String = "invalid_action"
	var target: String = ""
	if _entities.has(actor) and action.get("type", "") in allowed[phase]:
		match action.type:
			"wait":
				success = true
				reason = ""
			"post_request":
				if action.get("item") is String:
					success = post_request(actor, action.item, action.get("quantity"))
			"accept_request":
				if action.get("request_id") is String:
					success = accept_request(actor, action.request_id)
			"fulfill_request":
				if action.get("request_id") is String:
					success = fulfill_request(actor, action.request_id)
			"close_request":
				if action.get("request_id") is String and action.get("close_reason") is String:
					success = close_request(actor, action.request_id, action.close_reason)
	var command_id: Variant = null
	if _events.size() > before_count:
		command_id = _events.back().id
		reason = _events.back().details.get("reason", "")
		target = _events.back().target
	var outcome: String = "wait" if success and action.type == "wait" else "executed" if success else "rejected"
	_record("decision", actor, target, success, {"phase": phase, "selected_action": action,
		"reason": proposal.get("reason", "unspecified"), "outcome": outcome,
		"execution_reason": reason, "command_event_id": command_id})
	return success
