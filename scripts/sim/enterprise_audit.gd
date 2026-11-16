extends RefCounted
## Reconstruct only receipts/facts, independently of the command implementations/policies.
const PRICES = {"wheat": 2, "flour": 4, "bread": 4}
const REQUIREMENTS = {"farmer": ["workshop", "farm_tools"], "miller": ["workshop", "millstone"], "baker": ["workshop", "oven"]}


static func _ready_assets(state: Dictionary, business: String) -> bool:
	for kind in REQUIREMENTS[state.businesses[business].industry]:
		if not state.productive_assets.values().any(func(a): return a.holder == business and a.kind == kind and a.industry == state.businesses[business].industry):
			return false
	return true


static func _capacity(state: Dictionary, business: String) -> int:
	var slots: int = state.businesses[business].assets.daily_slots
	for kind in REQUIREMENTS[state.businesses[business].industry]:
		var available: int = 0
		for asset in state.productive_assets.values():
			if asset.holder == business and asset.kind == kind and asset.industry == state.businesses[business].industry:
				available = maxi(available, asset.capacity)
		slots = mini(slots, available)
	return slots


static func _due(state: Dictionary, worker: String, business: String) -> bool:
	if not state.employment.has(worker):
		return false
	var job: Dictionary = state.employment[worker]
	return job.active and job.business == business and ((state.day - job.get("start_day", 1)) % job.contract.cycle_days + 1) in job.contract.phases


static func verify(history: Array, final: Dictionary, reference: bool = false, observer: Callable = Callable()) -> Dictionary:
	var initial: Dictionary = history[0].details.state
	var state: Dictionary = initial.duplicate(true)
	var checks = {"currency_each_event": true, "bounded_holdings": true, "goods_and_assets": true,
		"unique_receipts": true, "labor_and_affiliations": true, "contracts": true,
		"capital_and_earnings": true, "hiring": true, "final_state": true, "ordered_events": true}
	var a_checks = {"daily_currency_boundary": true, "production_and_food": true, "work_and_income": true, "closing_accounts": true}
	var combined: int = 0
	for entity in state.entities.values():
		combined += entity.money
	var sources: Dictionary = {}
	var claims: Dictionary = {}
	var before_money: Dictionary = {}
	var daily_work: Dictionary = {}
	var due: Dictionary = {}
	var outcomes: Dictionary = {}
	var production: Dictionary = {}
	var local_meals: int = 0
	var visitor_goods: int = 0
	var wages: int = 0
	var distributed: int = 0
	var day_count: int = 0
	for index in history.size():
		var e: Dictionary = history[index]
		var d: Dictionary = e.details
		checks.ordered_events = checks.ordered_events and e.id == index + 1
		if e.action == "day_started":
			checks.contracts = checks.contracts and state.contract_day_closed
			state.day += 1
			state.contract_day_closed = false
			for key in ["labor_used", "business_labor", "offers", "harvest_opportunities", "meals"]:
				state[key].clear()
			if state.has("commodity_quotes"):
				state.market_bought.clear()
			daily_work.clear()
			due.clear()
			outcomes.clear()
			production = {"wheat": 0, "flour": 0, "bread": 0}
			local_meals = 0
			visitor_goods = 0
			wages = 0
			distributed = 0
		checks.ordered_events = checks.ordered_events and e.day == state.day
		if e.action == "contract_shift":
			checks.contracts = checks.contracts and due.get(e.actor) == e.target and not outcomes.has(e.actor) \
				and d.expected_compensation == state.employment[e.actor].wage and d.actual_compensation == (d.expected_compensation if e.success else 0) \
				and d.completed == e.success and d.contract_id == "%d:%s:%s" % [state.day, e.target, e.actor]
			checks.contracts = checks.contracts and (daily_work.get(e.actor) == d.shift_event_id if e.success else not daily_work.has(e.actor))
			if d.attempted:
				var attempt: Dictionary = history[d.attempt_event_id - 1]
				checks.contracts = checks.contracts and attempt.action == "contract_attempt" and attempt.details.authorized_attempt and attempt.actor == d.employer and attempt.details.worker == e.actor
			else:
				checks.contracts = checks.contracts and d.attempt_event_id == null and not e.success and d.reason == "employer_did_not_schedule"
			outcomes[e.actor] = e.success
		if not e.success:
			if observer.is_valid(): observer.call(state,e)
			continue
		match e.action:
			"purchase":
				var price_valid: bool = PRICES[d.item] == d.unit_price
				if state.has("commodity_quotes"):
					var quote: Dictionary = state.commodity_quotes[e.target][d.item]
					price_valid = quote.active and d.unit_price == quote.unit_price and d.quantity <= quote.limit
					for key in quote:
						price_valid = price_valid and d.quote.get(key) == quote[key]
					price_valid = price_valid and d.quote.available == mini(quote.limit, state.entities[e.target].inventory[d.item])
				checks.goods_and_assets = checks.goods_and_assets and e.actor != e.target and d.quantity is int and d.quantity > 0 \
					and price_valid and d.total_price == d.quantity * d.unit_price
				if not state.has("commodity_quotes"):
					checks.goods_and_assets = checks.goods_and_assets and {"farmer": "wheat", "miller": "flour", "baker": "bread"}[state.businesses[e.target].industry] == d.item
				elif state.entities[e.actor].kind != "business" and d.item == "bread":
					state.market_bought[e.actor] = state.market_bought.get(e.actor, 0) + d.quantity
					checks.goods_and_assets = checks.goods_and_assets and state.market_bought[e.actor] <= (6 if state.entities[e.actor].kind == "external" else 1)
					if state.entities[e.actor].kind == "external":
						checks.goods_and_assets = checks.goods_and_assets and d.unit_price <= 6
				state.entities[e.actor].money -= d.total_price
				state.entities[e.target].money += d.total_price
				if d.has("custody") and state.has("cargo"):
					checks.goods_and_assets = checks.goods_and_assets and d.custody.business == e.actor and state.cargo[e.actor].holder == d.custody.holder
					state.cargo[e.actor].inventory[d.item] += d.quantity
				else:
					state.entities[e.actor].inventory[d.item] += d.quantity
				state.entities[e.target].inventory[d.item] -= d.quantity
				state.cash_results[e.target].sales += d.total_price
				if state.businesses.has(e.actor):
					state.cash_results[e.actor].inputs += d.total_price
				elif state.entities[e.actor].kind == "external":
					visitor_goods += d.quantity
			"transfer_money":
				before_money[e.id] = {"cash": state.entities[e.actor].money, "book": state.cash_results.get(e.actor, {}).duplicate(true)}
				checks.capital_and_earnings = checks.capital_and_earnings and d.amount is int and d.amount > 0
				state.entities[e.actor].money -= d.amount
				state.entities[e.target].money += d.amount
				match d.purpose:
					"capital_contribution":
						checks.capital_and_earnings = checks.capital_and_earnings and state.businesses[e.target].owner == e.actor
						state.cash_results[e.target].capital_contributions += d.amount
					"asset_purchase":
						state.cash_results[e.actor].capital_purchases += d.amount
						if state.cash_results.has(e.target):
							state.cash_results[e.target].capital_asset_sales += d.amount
					"distribution":
						state.cash_results[e.actor].distributions += d.amount
						distributed += d.amount
					"wage":
						state.cash_results[e.actor].payroll += d.amount
						wages += d.amount
					_: checks.capital_and_earnings = false
				sources[e.id] = true
			"produce", "harvest":
				var input: Dictionary = {} if e.action == "harvest" else d.inputs
				var output: Dictionary = {"wheat": d.amount} if e.action == "harvest" else d.outputs
				var industry: String = state.businesses[e.actor].industry
				checks.goods_and_assets = checks.goods_and_assets and _ready_assets(state, e.actor) and (d.amount == 4 if e.action == "harvest" else d.batches == 2 \
					and input == ({"wheat": 4} if industry == "miller" else {"flour": 4}) and output == ({"flour": 4} if industry == "miller" else {"bread": 6}))
				for item in input:
					state.entities[e.actor].inventory[item] -= input[item]
				for item in output:
					state.entities[e.actor].inventory[item] += output[item]
					production[item] += output[item]
				sources[e.id] = true
			"work_shift", "owner_work_shift":
				var firm: Dictionary = state.businesses[e.target]
				var own: bool = e.action == "owner_work_shift"
				checks.labor_and_affiliations = checks.labor_and_affiliations and state.affiliations.get(e.actor) == {"business": e.target, "kind": "self_employed" if own else "employee"} \
					and not daily_work.has(e.actor) and firm.industry in state.entities[e.actor].skills \
					and state.business_labor.get(e.target, 0) < _capacity(state, e.target) and d.labor == 1 and state.day > 0 and not state.contract_day_closed
				var production_receipt: Dictionary = history[d.production_event_id - 1]
				checks.unique_receipts = checks.unique_receipts and production_receipt.success and production_receipt.actor == e.target and production_receipt.action in ["produce", "harvest"] and not claims.has(production_receipt.id)
				claims[production_receipt.id] = true
				if own:
					checks.labor_and_affiliations = checks.labor_and_affiliations and firm.owner == e.actor and d.wage == 0 and production_receipt.id == e.id - 1
				else:
					var pay: Dictionary = history[d.payment_event_id - 1]
					var job: Dictionary = state.employment[e.actor]
					checks.labor_and_affiliations = checks.labor_and_affiliations and job.active and job.business == e.target and d.wage == job.wage and e.actor != firm.owner
					checks.unique_receipts = checks.unique_receipts and pay.id == e.id - 2 and production_receipt.id == e.id - 1 and pay.action == "transfer_money" and pay.actor == e.target and pay.target == e.actor and pay.details.amount == d.wage and pay.details.purpose == "wage" and not claims.has(pay.id)
					claims[pay.id] = true
					state.offers[d.offer_id].status = "accepted"
				daily_work[e.actor] = e.id
				state.labor_used[e.actor] = state.labor_used.get(e.actor, 0) + 1
				state.business_labor[e.target] = state.business_labor.get(e.target, 0) + 1
			"consume":
				state.entities[e.actor].inventory.bread -= d.amount
				if state.entities[e.actor].kind == "resident":
					checks.goods_and_assets = checks.goods_and_assets and d.amount == 1 and not state.meals.has(e.actor)
					state.meals[e.actor] = true
					local_meals += 1
				else:
					checks.goods_and_assets = checks.goods_and_assets and state.entities[e.actor].kind == "external"
			"business_founded":
				checks.capital_and_earnings = checks.capital_and_earnings and not state.entities.has(e.target) and d.entity.money == 0 and d.entity.inventory == {"wheat": 0, "flour": 0, "bread": 0} and d.business.owner == e.actor and d.business.employees.is_empty()
				checks.capital_and_earnings = checks.capital_and_earnings and d.book.values().all(func(value): return value == 0)
				state.entities[e.target] = d.entity.duplicate(true)
				state.businesses[e.target] = d.business.duplicate(true)
				state.cash_results[e.target] = d.book.duplicate(true)
			"capital_contribution", "asset_purchased", "profit_distribution":
				var payment_id: Variant = d.get("payment_event_id")
				if payment_id != null:
					var pay: Dictionary = history[payment_id - 1]
					checks.unique_receipts = checks.unique_receipts and pay.success and pay.action == "transfer_money" and pay.id == e.id - 1 and not claims.has(pay.id)
					claims[pay.id] = true
				if e.action == "capital_contribution":
					var pay: Dictionary = history[payment_id - 1]
					checks.capital_and_earnings = checks.capital_and_earnings and pay.actor == e.actor and pay.target == e.target and pay.details.amount == d.amount and pay.details.purpose == "capital_contribution" and state.businesses[e.target].owner == e.actor
				elif e.action == "asset_purchased":
					var asset: Dictionary = state.productive_assets[d.asset]
					checks.goods_and_assets = checks.goods_and_assets and asset.holder == d.seller and asset.for_sale and asset.price == d.price and state.businesses[e.target].owner == e.actor
					if d.price > 0:
						var pay: Dictionary = history[payment_id - 1]
						checks.capital_and_earnings = checks.capital_and_earnings and pay.actor == e.target and pay.target == d.seller and pay.details.purpose == "asset_purchase" and pay.details.amount == d.price
					asset.holder = e.target
					asset.for_sale = false
					checks.goods_and_assets = checks.goods_and_assets and asset == d.asset_state
					state.businesses[e.target].assets.daily_slots = mini(state.businesses[e.target].assets.daily_slots, asset.capacity)
				else:
					var pay: Dictionary = history[payment_id - 1]
					var book: Dictionary = before_money[payment_id].book
					var retained: int = book.sales - book.inputs - book.payroll - book.distributions
					var policy: Dictionary = state.businesses[e.target].distribution_policy
					@warning_ignore("integer_division")
					var portion: int = 0 if policy.mode == "retain" else maxi(0, retained) / (2 if policy.mode == "half" else 1)
					var amount: int = mini(portion, maxi(0, before_money[payment_id].cash - policy.reserve))
					checks.capital_and_earnings = checks.capital_and_earnings and state.businesses[e.target].owner == e.actor and pay.actor == e.target and pay.target == e.actor and pay.details.purpose == "distribution" and amount == d.amount and amount == pay.details.amount and amount > 0 and d.cumulative_before == book
			"distribution_policy": state.businesses[e.target].distribution_policy = d.duplicate()
			"shift_offered": state.offers[d.offer.id] = d.offer.duplicate(true)
			"labor_environment": state.harvest_opportunities = d.opportunities.duplicate()
			"contract_due":
				checks.contracts = checks.contracts and _due(state, e.actor, e.target) and not due.has(e.actor) and d.expected_compensation == state.employment[e.actor].wage
				due[e.actor] = e.target
			"contract_day_closed":
				checks.contracts = checks.contracts and not state.contract_day_closed and due.size() == outcomes.size() and due.size() == d.due and outcomes.values().count(true) == d.completed and d.breaches == d.due - d.completed
				var expected_due: Dictionary = {}
				for worker in state.employment:
					var employer: String = state.employment[worker].business
					if _due(state, worker, employer):
						expected_due[worker] = employer
				checks.contracts = checks.contracts and due == expected_due
				checks.capital_and_earnings = checks.capital_and_earnings and d.cash_results == state.cash_results
				state.contract_day_closed = true
				day_count += 1
				if reference:
					var village: int = 0
					for id in state.entities:
						var p: Dictionary = state.entities[id]
						if p.kind != "external":
							village += p.money
						if p.kind == "resident":
							a_checks.closing_accounts = a_checks.closing_accounts and p.money == 6 + 2 * state.day
						elif p.kind == "business":
							a_checks.closing_accounts = a_checks.closing_accounts and p.money == 120
						a_checks.closing_accounts = a_checks.closing_accounts and p.inventory == {"wheat": 0, "flour": 0, "bread": 0}
					checks.currency_each_event = checks.currency_each_event and combined == 9192
					a_checks.daily_currency_boundary = a_checks.daily_currency_boundary and village == 432 + 24 * state.day and state.entities.visitors.money == 8760 - 24 * state.day
					a_checks.production_and_food = a_checks.production_and_food and production == {"wheat": 12, "flour": 12, "bread": 18} and local_meals == 12 and visitor_goods == 6
					a_checks.work_and_income = a_checks.work_and_income and daily_work.size() == 9 and wages == 54 and distributed == 18 and d.due == 6 and d.breaches == 0
			"resignation_requested": state.resignations[e.actor] = d.duplicate(true)
			"employment_ended":
				checks.labor_and_affiliations = checks.labor_and_affiliations and state.contract_day_closed and state.affiliations.get(e.actor) == d.affiliation and d.effective_day == state.day + 1
				checks.labor_and_affiliations = checks.labor_and_affiliations and (state.resignations.has(e.actor) if d.reason == "resigned" else state.employment[e.actor].end_day <= d.effective_day)
				if d.affiliation.kind == "employee":
					state.employment[e.actor] = d.job.duplicate(true)
				state.affiliations.erase(e.actor)
				state.resignations.erase(e.actor)
			"self_employment_started":
				checks.labor_and_affiliations = checks.labor_and_affiliations and state.businesses[e.target].owner == e.actor and not state.affiliations.has(e.actor) and not state.pending_hires.has(e.actor)
				state.affiliations[e.actor] = d.affiliation.duplicate()
			"job_posted":
				checks.hiring = checks.hiring and not state.job_postings.has(d.posting.id) and state.businesses[e.target].owner == e.actor and d.posting.employer == e.actor
				state.job_postings[d.posting.id] = d.posting.duplicate(true)
			"application_submitted":
				checks.hiring = checks.hiring and d.application.worker == e.actor and not state.affiliations.has(e.actor) and not state.applications.has(d.application.id)
				state.applications[d.application.id] = d.application.duplicate(true)
			"job_offer_made":
				var app: Dictionary = state.applications[d.application_id]
				var post: Dictionary = state.job_postings[d.posting]
				checks.hiring = checks.hiring and app.status == "applied" and post.employer == e.actor and post.filled + post.reserved < post.vacancies
				app.status = "offered"
				post.reserved += 1
			"offer_accepted":
				var app: Dictionary = state.applications[d.application_id]
				checks.hiring = checks.hiring and app.worker == e.actor and app.status == "offered" and not state.affiliations.has(e.actor) and not state.pending_hires.has(e.actor)
				app.status = "accepted"
				state.pending_hires[e.actor] = d.pending.duplicate(true)
			"employment_started":
				var pending: Dictionary = state.pending_hires[e.actor]
				var post: Dictionary = state.job_postings[d.posting]
				checks.hiring = checks.hiring and not state.affiliations.has(e.actor) and pending.posting == d.posting and d.effective_day == state.day + 1 and d.job.wage == post.wage \
					and d.job.contract.shifts_per_cycle == post.guaranteed_shifts and d.job.end_day == d.effective_day + post.duration_days
				state.employment[e.actor] = d.job.duplicate(true)
				state.affiliations[e.actor] = d.affiliation.duplicate()
				if e.actor not in state.businesses[e.target].employees:
					state.businesses[e.target].employees.append(e.actor)
				post.reserved -= 1
				post.filled += 1
				post.active = post.filled < post.vacancies
				state.applications[pending.application_id].status = "started"
				state.pending_hires.erase(e.actor)
			"quote_revised":
				var quote: Dictionary = d.quote
				var old: Dictionary = state.commodity_quotes.get(e.target, {}).get(quote.item, {})
				checks.goods_and_assets = checks.goods_and_assets and state.businesses[e.target].owner == e.actor and quote.seller == e.target \
					and quote.unit_price is int and quote.unit_price >= 1 and quote.unit_price <= 1000000000 \
					and quote.active is bool and quote.limit is int and quote.limit >= 0 and quote.limit <= 1000000000 and quote.version is int \
					and old.get("revised_day", -1) != state.day and quote.revised_day == state.day and quote.effective_day == state.day \
					and quote.version == old.get("version", 0) + 1 and d.previous_version == old.get("version", 0)
				if not state.commodity_quotes.has(e.target):
					state.commodity_quotes[e.target] = {}
				state.commodity_quotes[e.target][quote.item] = quote.duplicate(true)
			"pricing_decision", "buyer_decision":
				checks.ordered_events = checks.ordered_events and state.has("commodity_quotes")
			"spatial_deposited":
				checks.goods_and_assets = checks.goods_and_assets and state.has("cargo") and state.cargo[e.target].holder == e.actor
				for item in d.goods:
					checks.goods_and_assets = checks.goods_and_assets and d.goods[item] is int and d.goods[item] >= 0
					state.cargo[e.target].inventory[item] -= d.goods[item]
					state.entities[e.target].inventory[item] += d.goods[item]
			"initialize", "day_started", "contract_attempt", "contract_shift": pass
			_: checks.ordered_events = checks.ordered_events and observer.is_valid() and e.action.begins_with("spatial_")
		if observer.is_valid(): observer.call(state,e)
		var money: int = 0
		for p in state.entities.values():
			money += p.money
			checks.bounded_holdings = checks.bounded_holdings and p.money >= 0 and p.money <= 1_000_000_000
			for quantity in p.inventory.values():
				checks.bounded_holdings = checks.bounded_holdings and quantity >= 0 and quantity <= 1_000_000_000
		checks.currency_each_event = checks.currency_each_event and money == combined
		if state.has("cargo"):
			for parcel in state.cargo.values():
				checks.goods_and_assets = checks.goods_and_assets and parcel.inventory.values().all(func(q):return q is int and q >= 0 and q <= 1000000000)
	checks.unique_receipts = checks.unique_receipts and sources == claims
	checks.goods_and_assets = checks.goods_and_assets and state.productive_assets.keys() == initial.productive_assets.keys()
	checks.final_state = state == final
	return {"accounting": checks, "reference_A": a_checks if reference else {}, "days_checked": day_count}
