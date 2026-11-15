extends "res://scripts/sim/agents_runner.gd"

const CoordinationWorld = preload("res://scripts/sim/coordination_world.gd")
const CommercialPolicy = preload("res://scripts/sim/coordination_policy.gd")


func _init(seed_value: int = 42, initial_entities: Array = [], goals: Dictionary = Policy.DEFAULT_GOALS) -> void:
	super(seed_value, initial_entities, goals)
	world = CoordinationWorld.new(default_entities() if initial_entities.is_empty() else initial_entities)
	_initial = world.snapshot()


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		world.transfer_money("farmer", "laborer", DAILY_PAYMENT)
		var harvest_yield: int = _rng.randi_range(2, 6)
		for actor in ["farmer", "miller", "baker"]:
			if actor != "farmer":
				_decide(actor, "inputs")
			_decide(actor, "work", harvest_yield if actor == "farmer" else 0)
			_decide(actor, "delivery")
		for actor in IDS:
			_decide(actor, "requests")
		for actor in IDS:
			_decide(actor, "accept")
		for actor in IDS:
			_decide(actor, "food")
		for actor in IDS:
			_decide(actor, "meal")
		world.record_outstanding()


func _decide(actor: String, phase: String, harvest_yield: int = 0) -> void:
	var proposal: Dictionary = CommercialPolicy.decide(world.observe(actor), _goals.duplicate(true), phase)
	world.execute_decision(actor, phase, proposal, harvest_yield)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "coordination"
	var agreements = {"requests": 0, "open": 0, "made": 0, "fulfilled": 0, "outstanding": 0,
		"closed": 0, "waived": 0, "prepaid": 0, "outstanding_payment": 0, "waived_payment": 0,
		"delivered": {"wheat": 0, "flour": 0, "bread": 0}, "rejections": {}}
	for flow in summary.cash_flow.values():
		flow["prepayments_received"] = 0
		flow["prepayments_sent"] = 0
	var failures: Dictionary = {}
	var groups: Dictionary = {}
	var notable: Array = []
	for event in world.events():
		var details: Dictionary = event.details
		if event.action in ["request_posted", "agreement_accepted", "agreement_fulfilled", "request_closed"] and not event.success:
			agreements.rejections[event.action] = agreements.rejections.get(event.action, 0) + 1
		if event.action == "agreement_accepted" and details.has("payment_event_id"):
			# The inherited projection counts every transfer as an employer payment.
			# Reclassify these exact receipts, without changing earned/spent totals.
			if event.success:
				var request: Dictionary = details.request
				summary.payments.successful -= 1
				summary.payments.amount -= request.payment
				var buyer: Dictionary = summary.cash_flow[request.buyer]
				var supplier: Dictionary = summary.cash_flow[request.supplier]
				buyer.payments_sent -= request.payment
				buyer.prepayments_sent += request.payment
				supplier.payments_received -= request.payment
				supplier.prepayments_received += request.payment
			else:
				summary.payments.rejected -= 1
		# Lifecycle failures with command receipts annotate the same failed operation.
		if not event.success and event.action != "decision" \
				and not details.has("payment_event_id") and not details.has("item_event_id"):
			var key: String = event.action + ":" + details.reason
			failures[key] = failures.get(key, 0) + 1
			var resource: String = details.get("item", details.get("recipe", "money"))
			key = ":".join([event.action, event.actor, event.target, resource, details.reason])
			if not groups.has(key):
				groups[key] = {"action": event.action, "actor": event.actor, "target": event.target,
					"resource": resource, "reason": details.reason, "count": 0, "first_day": event.day, "last_day": event.day}
			groups[key].count += 1
			groups[key].last_day = event.day
			if notable.size() < 8:
				notable.append(event)
	for request in world.snapshot().requests.values():
		agreements.requests += 1
		if request.status == "open":
			agreements.open += 1
		if request.status == "closed":
			agreements.closed += 1
		if request.accepted_day != null:
			agreements.made += 1
			agreements.prepaid += request.payment
			if request.status == "accepted":
				agreements.outstanding += 1
				agreements.outstanding_payment += request.payment
			elif request.status == "fulfilled":
				agreements.fulfilled += 1
				agreements.delivered[request.item] += request.quantity
			elif request.status == "closed":
				agreements.waived += 1
				agreements.waived_payment += request.payment
	summary.totals["spot_traded"] = summary.totals.traded.duplicate()
	summary.totals["agreement_delivered"] = agreements.delivered.duplicate()
	for item in agreements.delivered:
		summary.totals.traded[item] += agreements.delivered[item]
	summary["agreements"] = agreements
	summary.failures = failures
	summary.failure_groups = groups
	summary.notable_events = notable
	return summary
