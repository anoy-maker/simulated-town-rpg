extends RefCounted
## Independent policy/observation checks complement the shared full-state receipt audit.
const Ledger = preload("res://scripts/sim/enterprise_audit.gd")


static func _offers(quotes: Dictionary, people: Dictionary) -> Array:
	var offers: Array = []
	var sellers: Array = quotes.keys()
	sellers.sort()
	for seller in sellers:
		var items: Array = quotes[seller].keys()
		items.sort()
		for item in items:
			var q: Dictionary = quotes[seller][item].duplicate(true)
			q["available"] = mini(q.limit, people[seller].inventory[item])
			offers.append(q)
	return offers


static func verify(history: Array, final: Dictionary) -> Dictionary:
	var result: Dictionary = Ledger.verify(history, final)
	var checks = {"seller_observations": true, "candidate_objective": true, "buyer_observations": true, "buyer_selection": true, "linked_execution": true}
	var initial: Dictionary = history[0].details.state
	var people: Dictionary = initial.entities.duplicate(true)
	var quotes: Dictionary = initial.commodity_quotes.duplicate(true)
	var stats: Dictionary = {}
	var observation_points: Dictionary = {}
	var views: Dictionary = {}
	for e in history:
		if e.action == "buyer_decision":
			observation_points[e.details.observation.observed_after_event] = true
	var pre_revision: Dictionary = {}
	for e in history:
		var d: Dictionary = e.details
		if observation_points.has(e.id - 1):
			var money: Dictionary = {}
			for id in people: money[id] = people[id].money
			views[e.id - 1] = {"cash": money, "offers": _offers(quotes, people)}
		if e.success and e.action == "quote_revised":
			pre_revision[e.id] = quotes.get(e.target, {}).get(d.quote.item, {}).duplicate(true)
			if not quotes.has(e.target):
				quotes[e.target] = {}
			quotes[e.target][d.quote.item] = d.quote.duplicate(true)
		if e.action == "pricing_decision":
			if not d.has("observation"):
				checks.linked_execution = checks.linked_execution and not e.success
				continue
			var o: Dictionary = d.observation
			var p: Dictionary = d.proposal
			var firm: Dictionary = initial.businesses[e.target]
			var previous: Dictionary = stats.get(str(e.day - 1) + ":" + e.target, {"sold": 0, "revenue": 0, "stockout_requests": 0, "inputs": 0, "payroll": 0}).duplicate()
			previous["day"] = e.day - 1
			var count: int = firm.employees.size()
			var output: int = count * (6 if firm.industry == "baker" else 4)
			var input: String = "wheat" if firm.industry == "miller" else "flour" if firm.industry == "baker" else ""
			var public: Array = _offers(quotes, people)
			var inputs: Array = public.filter(func(q):return q.item == input and q.active and q.seller != e.target)
			inputs.sort_custom(func(a,b):return a.unit_price < b.unit_price)
			var expected_cost: int = 0 if inputs.is_empty() else count * 4 * inputs[0].unit_price
			var prior_quote: Dictionary = pre_revision[d.revision_event_id] if d.revision_event_id != null and pre_revision.has(d.revision_event_id) else quotes[e.target][o.item]
			checks.seller_observations = checks.seller_observations and o.current_price == prior_quote.unit_price and o.item == {"farmer":"wheat","miller":"flour","baker":"bread"}[firm.industry]
			var expected = {"day": e.day, "business": e.target, "owner": firm.owner, "item": o.item, "current_price": o.current_price,
				"cash": people[e.target].money, "inventory": people[e.target].inventory, "planned_output": output,
				"available": people[e.target].inventory[o.item] + output, "planned_inputs": expected_cost, "planned_payroll": count * 6,
				"recent": previous, "reference_price": o.current_price, "reference_demand": output if e.day <= 1 else previous.sold + previous.stockout_requests,
				"sensitivity": 1, "competing_offers": public.filter(func(q):return q.item == o.item and q.seller != e.target)}
			checks.seller_observations = checks.seller_observations and o == expected and e.actor == firm.owner
			if p.selected_price == null:
				checks.candidate_objective = checks.candidate_objective and not e.success and p.reason == "unsupported_mode"
				continue
			var prices: Array = [o.current_price] if p.mode == "fixed" else [maxi(1,o.current_price-1),o.current_price,mini(1000000000,o.current_price+1)]
			var expected_candidates: Array = []
			for price in prices:
				if expected_candidates.any(func(c):return c.price == price):
					continue
				var qty: int = clampi(o.reference_demand + (o.reference_price-price)*o.sensitivity,0,o.available)
				expected_candidates.append({"price": price, "demand": qty, "revenue": qty*price, "operating_cash": qty*price-o.planned_inputs-o.planned_payroll})
			var ranked: Array = expected_candidates.duplicate(true)
			ranked.sort_custom(func(a,b):
				if a.operating_cash != b.operating_cash: return a.operating_cash > b.operating_cash
				if a.price == o.current_price or b.price == o.current_price: return a.price == o.current_price
				return a.price < b.price)
			checks.candidate_objective = checks.candidate_objective and p.candidates == expected_candidates and p.selected_price == ranked[0].price
			if d.revision_event_id != null:
				var revision: Dictionary = history[d.revision_event_id-1]
				checks.linked_execution = checks.linked_execution and revision.action == "quote_revised" and revision.actor == e.actor and revision.target == e.target \
					and revision.success == e.success
				if revision.success:
					checks.linked_execution = checks.linked_execution and revision.details.previous_version+1 == quotes[e.target][o.item].version and revision.details.quote.unit_price == p.selected_price
			else:
				checks.linked_execution = checks.linked_execution and p.selected_price == o.current_price and quotes[e.target][o.item].unit_price == o.current_price
		if e.action == "buyer_decision":
			var o: Dictionary = d.observation
			var p: Dictionary = d.proposal
			var before: Dictionary = views[o.observed_after_event]
			checks.buyer_observations = checks.buyer_observations and o.keys().size() == 8 and o.observed_after_event < e.id and o.buyer == e.actor and o.day == e.day and o.money == before.cash[e.actor] and o.offers == before.offers \
				and o.ceiling == (6 if people[e.actor].kind == "external" else 1000000000)
			var eligible: Array = o.offers.filter(func(q):return q.item == o.item and q.active and q.available>0 and q.seller != e.actor and q.unit_price<=mini(o.money,o.ceiling))
			eligible.sort_custom(func(a,b):return a.seller < b.seller if a.unit_price==b.unit_price else a.unit_price<b.unit_price)
			if p.action == "wait":
				checks.buyer_selection = checks.buyer_selection and (o.needed<=0 or eligible.is_empty())
			else:
				var tied: Array = eligible.filter(func(q):return q.unit_price==eligible[0].unit_price)
				var rotation: int = e.day
				for index in e.actor.length():
					rotation += e.actor.unicode_at(index)
				@warning_ignore("integer_division")
				var amount: int = mini(o.needed,mini(p.quote.available,o.money/p.quote.unit_price))
				checks.buyer_selection = checks.buyer_selection and p.quote == tied[rotation%tied.size()] and p.quantity==amount and amount>0
				var receipt: Dictionary = history[d.command_event_id-1]
				checks.linked_execution = checks.linked_execution and receipt.action=="purchase" and receipt.actor==e.actor and receipt.target==e.target and receipt.success==e.success and receipt.details.quantity==p.quantity
		if e.action == "purchase" and initial.businesses.has(e.target):
			var key: String = str(e.day)+":"+e.target
			if not stats.has(key):
				stats[key] = {"sold":0,"revenue":0,"stockout_requests":0,"inputs":0,"payroll":0}
			var output_item: String = {"farmer":"wheat","miller":"flour","baker":"bread"}[initial.businesses[e.target].industry]
			if e.success and d.item == output_item:
				stats[key].sold += d.quantity
				stats[key].revenue += d.total_price
			elif not e.success and d.item == output_item and d.get("reason")=="insufficient_stock":
				stats[key].stockout_requests += d.quantity
			if e.success and initial.businesses.has(e.actor):
				var buying: String = str(e.day)+":"+e.actor
				if not stats.has(buying):
					stats[buying] = {"sold":0,"revenue":0,"stockout_requests":0,"inputs":0,"payroll":0}
				stats[buying].inputs += d.total_price
		if not e.success:
			continue
		match e.action:
			"purchase":
				people[e.actor].money -= d.total_price
				people[e.target].money += d.total_price
				people[e.actor].inventory[d.item] += d.quantity
				people[e.target].inventory[d.item] -= d.quantity
			"transfer_money":
				people[e.actor].money -= d.amount
				people[e.target].money += d.amount
				if d.purpose=="wage":
					var key: String = str(e.day)+":"+e.actor
					if not stats.has(key):
						stats[key] = {"sold":0,"revenue":0,"stockout_requests":0,"inputs":0,"payroll":0}
					stats[key].payroll += d.amount
			"harvest": people[e.actor].inventory.wheat += d.amount
			"produce":
				for item in d.inputs: people[e.actor].inventory[item] -= d.inputs[item]
				for item in d.outputs: people[e.actor].inventory[item] += d.outputs[item]
			"consume": people[e.actor].inventory.bread -= d.amount
	result["pricing"] = checks
	return result
