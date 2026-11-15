extends "res://scripts/sim/labor_world.gd"
## Only new economic command: bounded, atomic business-to-owner cash withdrawal.

const Finance = preload("res://scripts/sim/finance_config.gd")


func withdrawal_budget(business: String) -> Dictionary:
	assert(_businesses.has(business))
	var reserve: int = Finance.operating_reserve(_businesses[business], _employment)
	return {"operating_reserve": reserve, "distributable_cash": maxi(0, _entities[business].money - reserve)}


func owner_withdrawal(owner: String, business: String, amount: Variant) -> bool:
	var details = {"amount": amount, "operating_reserve": null, "distributable_before": null}
	var reason: String = ""
	if not _entities.has(owner) or _entities[owner].kind != "resident":
		reason = "unknown_owner"
	elif not _businesses.has(business):
		reason = "unknown_business"
	elif _businesses[business].owner != owner:
		reason = "not_owner"
	else:
		reason = _actor_amount_error(owner, amount)
	if not reason.is_empty():
		return _reject("owner_withdrawal", owner, business, details, reason)
	var budget: Dictionary = withdrawal_budget(business)
	details.operating_reserve = budget.operating_reserve
	details.distributable_before = budget.distributable_cash
	if amount > _entities[business].money:
		reason = "insufficient_money"
	elif amount > budget.distributable_cash:
		reason = "operating_reserve"
	elif _entities[owner].money > MAX_AMOUNT - amount:
		reason = "owner_money_limit"
	if not reason.is_empty():
		return _reject("owner_withdrawal", owner, business, details, reason)
	# All validation precedes both writes; this event is distinct from paid-labor receipts.
	_entities[business].money -= amount
	_entities[owner].money += amount
	details["business_cash_after"] = _entities[business].money
	_record("owner_withdrawal", owner, business, true, details)
	return true


func observe(actor: String, business: String = "") -> Dictionary:
	var observation: Dictionary = super(actor, business)
	if not observation.business.is_empty():
		observation.business["withdrawal"] = withdrawal_budget(business)
	return observation


func execute_decision(actor: String, phase: String, proposal: Dictionary, business: String = "", worker: String = "") -> bool:
	if phase != "finance":
		return super(actor, phase, proposal, business, worker)
	var action: Dictionary = proposal.get("action", {}) if proposal.get("action", {}) is Dictionary else {}
	var success: bool = false
	var reason: String = "invalid_action"
	var command_id: Variant = null
	if not _businesses.has(business) or actor != _businesses[business].owner:
		reason = "not_owner"
	elif action.get("type", "") == "wait":
		success = true
	elif action.get("type", "") == "owner_withdrawal":
		success = owner_withdrawal(actor, business, action.get("amount"))
		command_id = _events.back().id
		reason = _events.back().details.get("reason", "")
	_record("labor_decision", actor, business, success, {"phase": phase, "worker": "",
		"selected_action": action, "reason": proposal.get("reason", "unspecified"),
		"outcome": ("wait" if action.get("type", "") == "wait" else "executed") if success else "rejected",
		"execution_reason": "" if success else reason, "command_event_id": command_id})
	return success
