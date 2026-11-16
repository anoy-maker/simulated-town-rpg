extends "res://scripts/sim/enterprise_world.gd"
## M16 quoted market authority; financial/production/labor commands remain native.
const SellerPolicy = preload("res://scripts/sim/pricing_policy.gd")
const BuyerPolicy = preload("res://scripts/sim/buyer_policy.gd")
var _quotes: Dictionary = {}
var _market_bought: Dictionary = {}
var _executing_quote: Dictionary = {}


func _init(seed_value: int = 42, initial: Dictionary = Enterprise.initial()) -> void:
	for business in initial.businesses:
		var item: String = Config.INDUSTRIES[initial.businesses[business].industry].output
		_quotes[business] = {item: {"seller": business, "item": item, "unit_price": Reference.PRICES[item], "active": true,
			"limit": MAX_AMOUNT, "version": 1, "effective_day": 0, "revised_day": -1}}
	super(seed_value, initial)


func snapshot() -> Dictionary:
	var state: Dictionary = super()
	state["commodity_quotes"] = _quotes.duplicate(true)
	state["market_bought"] = _market_bought.duplicate()
	return state


func _record(action: String, actor: String, target: String, success: bool, details: Dictionary) -> void:
	if action == "purchase" and not _executing_quote.is_empty():
		details = details.duplicate(true)
		details["quote"] = _executing_quote.duplicate(true)
		if success and _entities[actor].kind != "business" and details.item == "bread":
			_market_bought[actor] = _market_bought.get(actor, 0) + details.quantity
	super(action, actor, target, success, details)


func advance_day() -> void:
	if not _contract_day_closed:
		close_contract_day()
	_market_bought.clear()
	super()


func revise_quote(owner: String, business: String, item: String, price: Variant, active: Variant = true, limit: Variant = MAX_AMOUNT) -> bool:
	var reason: String = ""
	if not _businesses.has(business) or _businesses[business].owner != owner:
		reason = "not_owner"
	elif item not in ITEMS or not price is int or price < 1 or price > MAX_AMOUNT or not active is bool or not limit is int or limit < 0 or limit > MAX_AMOUNT:
		reason = "invalid_offer"
	elif _quotes.get(business, {}).get(item, {}).get("revised_day", -1) == _day:
		reason = "already_revised_today"
	if not reason.is_empty():
		return _reject("quote_revised", owner, business, {"item": item, "price": price}, reason)
	var previous: Dictionary = _quotes.get(business, {}).get(item, {})
	var quote = {"seller": business, "item": item, "unit_price": price, "active": active, "limit": limit,
		"version": previous.get("version", 0) + 1, "effective_day": _day, "revised_day": _day}
	if not _quotes.has(business):
		_quotes[business] = {}
	_quotes[business][item] = quote
	_record("quote_revised", owner, business, true, {"quote": quote.duplicate(true), "previous_version": previous.get("version", 0)})
	return true


func public_quotes() -> Array:
	var result: Array = []
	var sellers: Array = _quotes.keys()
	sellers.sort()
	for seller in sellers:
		var items: Array = _quotes[seller].keys()
		items.sort()
		for item in items:
			var quote: Dictionary = _quotes[seller][item].duplicate(true)
			quote["available"] = mini(quote.limit, _entities[seller].inventory[item])
			result.append(quote)
	return result


func observe(actor: String, business: String = "") -> Dictionary:
	var o: Dictionary = super(actor, business)
	o.offers = public_quotes()
	return o


func purchase(buyer: String, seller: String, item: String, quantity: Variant, unit_price: Variant) -> bool:
	return _reject("purchase", buyer, seller, {"item": item, "quantity": quantity, "unit_price": unit_price}, "quote_required")


func purchase_quote(buyer: String, supplied: Variant, quantity: Variant) -> bool:
	var seller: String = supplied.get("seller", "") if supplied is Dictionary and supplied.get("seller") is String else ""
	var item: String = supplied.get("item", "") if supplied is Dictionary and supplied.get("item") is String else ""
	var reason: String = _actor_amount_error(buyer, quantity)
	var current: Dictionary = _quotes.get(seller, {}).get(item, {})
	if reason.is_empty():
		if current.is_empty() or not supplied is Dictionary or not supplied.get("version") is int or supplied.version != current.version:
			reason = "stale_or_unknown_quote"
		else:
			for key in current:
				if not supplied.has(key) or typeof(supplied[key]) != typeof(current[key]) or supplied[key] != current[key]:
					reason = "forged_quote"
	if reason.is_empty():
		if not current.active:
			reason = "inactive_quote"
		elif quantity > mini(current.limit, _entities[seller].inventory[item]):
			reason = "insufficient_stock"
		elif _entities[buyer].kind == "resident" and item == "bread" and (quantity > 1 - _market_bought.get(buyer, 0) or quantity > 1 - int(_meals.has(buyer)) - _entities[buyer].inventory.bread):
			reason = "excess_daily_food"
		elif _entities[buyer].kind == "external" and (buyer != "visitors" or item != "bread" or quantity > 6 - _market_bought.get(buyer, 0)):
			reason = "excess_external_request"
		elif _entities[buyer].kind == "external" and current.unit_price > 6:
			reason = "reservation_price"
	if not reason.is_empty():
		return _reject("purchase", buyer, seller, {"item": item, "quantity": quantity, "unit_price": current.get("unit_price", 0), "quote": supplied}, reason)
	_executing_quote = current.duplicate(true)
	_executing_quote["available"] = mini(current.limit, _entities[seller].inventory[item])
	var result: bool = _commodity_purchase(buyer, seller, item, quantity, current.unit_price)
	_executing_quote = {}
	return result


func buyer_observation(buyer: String, item: String, requested: int) -> Dictionary:
	assert(_entities.has(buyer) and item in ITEMS and requested > 0 and requested <= MAX_AMOUNT)
	var p: Dictionary = _entities[buyer]
	var need: int = requested
	if p.kind == "resident" and item == "bread":
		need = mini(need, maxi(0, mini(1 - _market_bought.get(buyer, 0), 1 - int(_meals.has(buyer)) - p.inventory.bread)))
	elif p.kind == "external":
		need = mini(need, maxi(0, 6 - _market_bought.get(buyer, 0)))
	return {"buyer": buyer, "day": _day, "item": item, "needed": need, "money": p.money,
		"ceiling": 6 if p.kind == "external" else MAX_AMOUNT, "offers": public_quotes(), "observed_after_event": _events.size()}


func buy_from_market(buyer: String, item: String, requested: int) -> int:
	var bought: int = 0
	var excluded: Array = []
	while bought < requested:
		var observation: Dictionary = buyer_observation(buyer, item, requested - bought)
		var proposal: Dictionary = BuyerPolicy.choose(observation, excluded)
		var success: bool = true
		var command: Variant = null
		if proposal.action == "purchase":
			success = purchase_quote(buyer, proposal.quote, proposal.quantity)
			command = _events.back().id
			if success:
				bought += proposal.quantity
			else:
				excluded.append(proposal.quote.seller + ":" + str(proposal.quote.version))
		_record("buyer_decision", buyer, proposal.get("quote", {}).get("seller", ""), success,
			{"observation": observation, "proposal": proposal, "command_event_id": command, "outcome": "wait" if proposal.action == "wait" else "executed" if success else "rejected"})
		if proposal.action == "wait":
			if observation.needed > 0:
				_record("market_unmet", buyer, "", false, {"item": item, "quantity": observation.needed, "reason": proposal.reason})
			break
	return bought


func pricing_observation(owner: String, business: String) -> Dictionary:
	assert(_businesses.has(business) and _businesses[business].owner == owner)
	var firm: Dictionary = _businesses[business]
	var item: String = Config.INDUSTRIES[firm.industry].output
	var quote: Dictionary = _quotes[business][item]
	var recent = {"day": _day - 1, "sold": 0, "revenue": 0, "stockout_requests": 0, "inputs": 0, "payroll": 0}
	for e in _events:
		if e.day != _day - 1:
			continue
		if e.action == "purchase":
			if e.target == business and e.details.item == item:
				if e.success:
					recent.sold += e.details.quantity
					recent.revenue += e.details.total_price
				elif e.details.get("reason") == "insufficient_stock":
					recent.stockout_requests += e.details.quantity
			if e.success and e.actor == business:
				recent.inputs += e.details.total_price
		elif e.success and e.action == "transfer_money" and e.actor == business and e.details.purpose == "wage":
			recent.payroll += e.details.amount
	var shifts: int = firm.employees.filter(func(worker): return _employment[worker].active and _employment[worker].business == business).size()
	var output: int = shifts * (6 if firm.industry == "baker" else 4)
	var input: String = Config.INDUSTRIES[firm.industry].input
	var inputs: int = 0
	if not input.is_empty():
		var offers: Array = public_quotes().filter(func(q):return q.item == input and q.active and q.seller != business)
		offers.sort_custom(func(a,b): return a.unit_price < b.unit_price)
		inputs = shifts * 4 * (offers[0].unit_price if not offers.is_empty() else 0)
	return {"day": _day, "business": business, "owner": owner, "item": item, "current_price": quote.unit_price,
		"cash": _entities[business].money, "inventory": _entities[business].inventory.duplicate(true), "planned_output": output,
		"available": _entities[business].inventory[item] + output, "planned_inputs": inputs, "planned_payroll": shifts * 6,
		"recent": recent, "reference_price": quote.unit_price, "reference_demand": output if _day <= 1 else recent.sold + recent.stockout_requests,
		"sensitivity": 1, "competing_offers": public_quotes().filter(func(q):return q.item == item and q.seller != business)}


func execute_pricing(owner: String, business: String, mode: String) -> bool:
	if not _businesses.has(business) or _businesses[business].owner != owner:
		return _reject("pricing_decision", owner, business, {}, "not_owner")
	var observation: Dictionary = pricing_observation(owner, business)
	var proposal: Dictionary = SellerPolicy.decide(observation, mode)
	var success: bool = proposal.selected_price != null
	var revision: Variant = null
	if success and proposal.selected_price != observation.current_price:
		success = revise_quote(owner, business, observation.item, proposal.selected_price)
		revision = _events.back().id
	_record("pricing_decision", owner, business, success, {"observation": observation, "proposal": proposal,
		"revision_event_id": revision, "outcome": "retained" if success and revision == null else "revised" if success else "rejected"})
	return success
