extends "res://scripts/sim/simulation_runner.gd"
## A fixed experiment; no adaptive policies, subsidies, or fallback transactions.

const PRICES = {"wheat": 1, "flour": 2, "bread": 3}
const DAILY_PAYMENT = 2


func _init(seed_value: int = 42, initial_entities: Array = []) -> void:
	# Deliberately retain the M0 endowments, kernel, and private seeded RNG.
	super(seed_value, initial_entities)


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		world.transfer_money("farmer", "laborer", DAILY_PAYMENT)
		world.harvest("farmer", _rng.randi_range(2, 6))
		world.purchase("miller", "farmer", "wheat", 4, PRICES.wheat)
		world.produce("miller", "mill", 2)
		world.purchase("baker", "miller", "flour", 4, PRICES.flour)
		world.produce("baker", "bake", 2)
		for buyer in ["farmer", "miller", "laborer"]:
			world.purchase(buyer, "baker", "bread", 1, PRICES.bread)
		for actor in IDS:
			world.consume(actor)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary["scenario"] = "trading"
	summary["prices"] = PRICES.duplicate()
	summary["daily_payment"] = {"employer": "farmer", "worker": "laborer", "amount": DAILY_PAYMENT}
	var purchases = {"successful": 0, "rejected": 0, "by_item": {}}
	var payments = {"successful": 0, "rejected": 0, "amount": 0}
	var cash_flow: Dictionary = {}
	var traded: Dictionary = {}
	var failure_groups: Dictionary = {}
	for item in World.ITEMS:
		purchases.by_item[item] = {"successful": 0, "rejected": 0, "quantity": 0, "money": 0}
		traded[item] = 0
	for actor in IDS:
		cash_flow[actor] = {"earned": 0, "spent": 0, "sales": 0, "purchases": 0,
			"payments_received": 0, "payments_sent": 0}
	for event in world.events():
		var details: Dictionary = event.details
		if not event.success:
			var resource: String = details.get("item", details.get("recipe", "money"))
			var key: String = ":".join([event.action, event.actor, event.target, resource, details.reason])
			if not failure_groups.has(key):
				failure_groups[key] = {"action": event.action, "actor": event.actor, "target": event.target,
					"resource": resource, "reason": details.reason, "count": 0,
					"first_day": event.day, "last_day": event.day}
			failure_groups[key].count += 1
			failure_groups[key].last_day = event.day
		if event.action == "purchase":
			var result: String = "successful" if event.success else "rejected"
			purchases[result] += 1
			purchases.by_item[details.item][result] += 1
			if event.success:
				traded[details.item] += details.quantity
				purchases.by_item[details.item].quantity += details.quantity
				purchases.by_item[details.item].money += details.total_price
				cash_flow[event.actor].spent += details.total_price
				cash_flow[event.actor].purchases += details.total_price
				cash_flow[event.target].earned += details.total_price
				cash_flow[event.target].sales += details.total_price
		elif event.action == "transfer_money":
			var result: String = "successful" if event.success else "rejected"
			payments[result] += 1
			if event.success:
				payments.amount += details.amount
				cash_flow[event.actor].spent += details.amount
				cash_flow[event.actor].payments_sent += details.amount
				cash_flow[event.target].earned += details.amount
				cash_flow[event.target].payments_received += details.amount
	summary["purchases"] = purchases
	summary["payments"] = payments
	summary["cash_flow"] = cash_flow
	summary["failure_groups"] = failure_groups
	summary.totals["traded"] = traded
	return summary
