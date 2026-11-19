extends "res://scripts/sim/planning_runner.gd"
## Six-person experiment. All peers use the same role policies and action slots.

const MarketWorld = preload("res://scripts/sim/market_world.gd")
const MarketPolicy = preload("res://scripts/sim/market_policy.gd")
const ROLE_ORDER = ["farmer", "miller", "baker", "laborer"]
var _participants: Array = []


static func market_entities() -> Array:
	var entities: Array = default_entities()
	entities.append({"id": "farmer_2", "name": "Edda", "role": "farmer", "money": 30,
		"inventory": {"wheat": 0, "flour": 0, "bread": 1}})
	entities.append({"id": "baker_2", "name": "Finn", "role": "baker", "money": 20,
		"inventory": {"wheat": 0, "flour": 0, "bread": 1}})
	return entities


func _init(seed_value: int = 42, initial_entities: Array = [], goals: Dictionary = Policy.DEFAULT_GOALS) -> void:
	var entities: Array = market_entities() if initial_entities.is_empty() else initial_entities
	super(seed_value, entities, goals, "commitment-first")
	world = MarketWorld.new(entities)
	_initial = world.snapshot()
	_participants = entities.duplicate(true)
	_participants.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.role != b.role:
			return ROLE_ORDER.find(a.role) < ROLE_ORDER.find(b.role)
		return a.id < b.id)


func participant_ids() -> Array:
	var ids: Array = []
	for person in _participants:
		ids.append(person.id)
	return ids


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		world.transfer_money("farmer", "laborer", _daily_payment())
		for person in _participants:
			if person.role == "laborer":
				continue
			# One opportunity per farmer/day, consumed even if that farmer waits.
			var harvest_yield: int = _harvest_opportunity() if person.role == "farmer" else 0
			if person.role != "farmer":
				_decide(person.id, "inputs")
			_decide(person.id, "work", harvest_yield)
			_decide(person.id, "delivery")
		for phase in ["requests", "accept", "food", "meal"]:
			for person in _participants:
				_decide(person.id, phase)
		world.record_outstanding()


func _daily_payment() -> int:
	return DAILY_PAYMENT


func _harvest_opportunity() -> int:
	return _rng.randi_range(2, 6)


func _decide(actor: String, phase: String, harvest_yield: int = 0) -> void:
	world.execute_decision(actor, phase, MarketPolicy.decide(world.observe(actor), _goals, phase), harvest_yield)


func _working_capital(actor: String) -> Dictionary:
	return PlanningPolicy.working_capital(MarketPolicy.selected_observation(world.observe(actor)), _goals)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "market"
	summary["schedule"] = participant_ids()
	summary["supplier_selection"] = "price ascending, stock descending, seller ID ascending; own output retained for own use"
	var people: Dictionary = {}
	for actor in participant_ids():
		people[actor] = {"produced": {"wheat": 0, "flour": 0, "bread": 0}, "consumed": 0,
			"unmet_meals": summary.unmet_meals[actor], "purchases_successful": 0, "purchases_failed": 0,
			"sales_successful": 0, "sales_failed": 0, "spot_sold": {"wheat": 0, "flour": 0, "bread": 0},
			"spot_bought": {"wheat": 0, "flour": 0, "bread": 0}, "selected_suppliers": {},
			"agreements_accepted": 0, "agreements_fulfilled": 0, "agreements_outstanding": 0,
			"agreement_delivered": {"wheat": 0, "flour": 0, "bread": 0}}
	for event in world.events():
		var details: Dictionary = event.details
		if event.action == "purchase":
			var buyer: Dictionary = people[event.actor]
			var seller: Dictionary = people[event.target]
			buyer["purchases_successful" if event.success else "purchases_failed"] += 1
			seller["sales_successful" if event.success else "sales_failed"] += 1
			buyer.selected_suppliers[event.target] = buyer.selected_suppliers.get(event.target, 0) + 1
			if event.success:
				buyer.spot_bought[details.item] += details.quantity
				seller.spot_sold[details.item] += details.quantity
		elif event.success and event.action == "harvest":
			people[event.actor].produced.wheat += details.amount
		elif event.success and event.action == "produce":
			for item in details.outputs:
				people[event.actor].produced[item] += details.outputs[item]
		elif event.success and event.action == "consume":
			people[event.actor].consumed += details.amount
	for request in summary.final.requests.values():
		if request.accepted_day == null:
			continue
		var supplier: Dictionary = people[request.supplier]
		supplier.agreements_accepted += 1
		if request.status == "accepted":
			supplier.agreements_outstanding += 1
		elif request.status == "fulfilled":
			supplier.agreements_fulfilled += 1
			supplier.agreement_delivered[request.item] += request.quantity
	summary["participants"] = people
	return summary
