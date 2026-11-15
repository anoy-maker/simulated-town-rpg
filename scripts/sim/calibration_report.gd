extends RefCounted
## Post-run diagnostics only. No metric or private ledger data reaches a policy.

const Rules = preload("res://scripts/sim/world_state.gd")


static func potential(seed_value: int, days: int, bonus: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var underlying: Array = []
	var grain: int = 0
	var food: int = 6
	var wheat: int = 0
	var bread: int = 0
	var meals: int = 0
	for _day in days:
		var draw: int = rng.randi_range(2, 6)
		underlying.append(draw)
		wheat += draw + bonus
		grain += draw + bonus
		@warning_ignore("integer_division")
		var batches: int = mini(4, grain / 2)
		grain -= batches * 2
		bread += batches * 3
		food += batches * 3
		var eaten: int = mini(6, food)
		meals += eaten
		food -= eaten
	return {"underlying_draws_hash": JSON.stringify(underlying).sha256_text(),
		"underlying_draws": underlying,
		"underlying_wheat": wheat - bonus * days, "opportunity_wheat": wheat,
		"food_required": 6 * days, "bread_upper_bound": bread,
		"production_buffer": bread - 6 * days, "timely_meals_upper_bound": meals,
		"initial_bread": 6, "mill_wheat_capacity": 8 * days, "bake_flour_capacity": 8 * days}


static func metrics(summary: Dictionary, history: Array) -> Dictionary:
	var ids: Array = summary.schedule
	var balances: Dictionary = {}
	var bread: Dictionary = {}
	var people: Dictionary = {}
	var business: Dictionary = {}
	var work: Dictionary = {}
	var active_days: Dictionary = {}
	for actor in ids:
		balances[actor] = summary.initial.entities[actor].money
		bread[actor] = summary.initial.entities[actor].inventory.bread
		business[actor] = {}
		work[actor] = {}
		people[actor] = {"cash_affordable_food_days": 0, "owned_food_days": 0,
			"last_production_day": null, "last_business_day": null}
	for event in history:
		var d: Dictionary = event.details
		if event.action == "decision" and d.phase == "food" and people.has(event.actor):
			var cash_before: int = balances[event.actor]
			var bread_before: int = bread[event.actor]
			if d.command_event_id != null:
				var command: Dictionary = history[d.command_event_id - 1]
				if command.action == "purchase" and command.success:
					cash_before += command.details.total_price
					if command.details.item == "bread":
						bread_before -= command.details.quantity
			if cash_before >= summary.prices.bread:
				people[event.actor].cash_affordable_food_days += 1
			if bread_before >= 1:
				people[event.actor].owned_food_days += 1
		if not event.success:
			continue
		match event.action:
			"purchase":
				balances[event.actor] -= d.total_price
				balances[event.target] += d.total_price
				if d.item == "bread":
					bread[event.actor] += d.quantity
					bread[event.target] -= d.quantity
			"transfer_money":
				balances[event.actor] -= d.amount
				balances[event.target] += d.amount
			"transfer_item":
				if d.item == "bread":
					bread[event.actor] -= d.amount
					bread[event.target] += d.amount
			"produce":
				bread[event.actor] += d.outputs.get("bread", 0)
			"consume":
				bread[event.actor] -= d.amount
		if event.action in ["harvest", "produce"]:
			work[event.actor][event.day] = true
			people[event.actor].last_production_day = event.day
		if event.action in ["harvest", "produce", "purchase", "agreement_accepted", "agreement_fulfilled"]:
			active_days[event.day] = true
			business[event.actor][event.day] = true
			people[event.actor].last_business_day = event.day
			if people.has(event.target):
				business[event.target][event.day] = true
				people[event.target].last_business_day = event.day
	var total: int = 0
	var largest: int = 0
	var holders: Array = []
	var circulation: int = 0
	for actor in ids:
		var person: Dictionary = summary.final.entities[actor]
		var stats: Dictionary = people[actor]
		assert(balances[actor] == person.money and bread[actor] == person.inventory.bread)
		total += person.money
		circulation += summary.cash_flow[actor].earned
		if person.money > largest:
			largest = person.money
			holders.clear()
		if person.money == largest:
			holders.append(actor)
		stats["business_inactive_days"] = summary.days - business[actor].size()
		stats["trailing_business_inactive_days"] = summary.days - (stats.last_business_day if stats.last_business_day != null else 0)
		stats["production_idle_days"] = null if person.role == "laborer" else summary.days - work[actor].size()
		stats["minimum_batch_input_cost"] = 0
		stats["underfunded_without_active_request"] = false
		if person.role not in ["miller", "baker"]:
			continue
		var recipe: Dictionary = Rules.RECIPES["mill" if person.role == "miller" else "bake"]
		var input: String = recipe.inputs.keys()[0]
		var output: String = recipe.outputs.keys()[0]
		var cost: int = maxi(0, recipe.inputs[input] - person.inventory[input]) * summary.prices[input]
		stats.minimum_batch_input_cost = cost
		var waiting: bool = false
		for request in summary.final.requests.values():
			if request.status in ["open", "accepted"] and actor in [request.buyer, request.supplier]:
				waiting = true
		stats.underfunded_without_active_request = not waiting and person.inventory[output] == 0 and person.money < cost
	@warning_ignore("integer_division")
	var share: int = largest * 10000 / total if total > 0 else 0
	return {"per_npc": people, "business_inactive_days": summary.days - active_days.size(),
		"cash_circulation": circulation, "wealth": {"total_money": total, "largest_balance": largest,
			"holders": holders, "share_basis_points": share}}
