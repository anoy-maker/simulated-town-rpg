extends RefCounted
## One fixed economic tick per day. No scenes, wall clock, or global RNG.

const World = preload("res://scripts/sim/world_state.gd")
const IDS = ["farmer", "miller", "baker", "laborer"]

var world: RefCounted
var _rng = RandomNumberGenerator.new()
var _seed: int
var _initial: Dictionary


static func default_entities() -> Array:
	var names = ["Ada", "Bram", "Cora", "Dain"]
	var balances = [30, 20, 20, 5]
	var entities: Array = []
	for index in IDS.size():
		entities.append({
			"id": IDS[index], "name": names[index], "role": IDS[index],
			"money": balances[index], "inventory": {"wheat": 0, "flour": 0, "bread": 1},
		})
	return entities


func _init(seed_value: int = 42, initial_entities: Array = []) -> void:
	_seed = seed_value
	_rng.seed = seed_value
	world = World.new(default_entities() if initial_entities.is_empty() else initial_entities)
	_initial = world.snapshot()


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		world.harvest("farmer", _rng.randi_range(2, 6))
		world.transfer_item("farmer", "miller", "wheat", 4)
		world.produce("miller", "mill", 2)
		world.transfer_item("miller", "baker", "flour", 4)
		world.produce("baker", "bake", 2)
		for recipient in ["farmer", "miller", "laborer"]:
			world.transfer_item("baker", recipient, "bread", 1)
		# An unconditional daily gift, independent of goods; no purchase or wage model yet.
		world.transfer_money("farmer", "laborer", 1)
		for actor in IDS:
			world.consume(actor)


func report() -> Dictionary:
	var totals = {"harvested": {"wheat": 0}, "production_inputs": {"wheat": 0, "flour": 0},
		"production_outputs": {"flour": 0, "bread": 0}, "consumed": {"bread": 0}}
	var unmet: Dictionary = {}
	for actor in participant_ids():
		unmet[actor] = 0
	var failures: Dictionary = {}
	var notable: Array = []
	var history: Array = world.events()
	for event in history:
		var details: Dictionary = event.details
		if not event.success:
			var key: String = event.action + ":" + details.reason
			failures[key] = failures.get(key, 0) + 1
			if notable.size() < 8:
				notable.append(event)
			if event.action == "consume":
				unmet[event.actor] += details.amount
		elif event.action == "harvest":
			totals.harvested.wheat += details.amount
		elif event.action == "produce":
			for item in details.inputs:
				totals.production_inputs[item] += details.inputs[item]
			for item in details.outputs:
				totals.production_outputs[item] += details.outputs[item]
		elif event.action == "consume":
			totals.consumed.bread += details.amount
	return {"seed": _seed, "days": world.snapshot().day, "initial": _initial.duplicate(true),
		"final": world.snapshot(), "totals": totals, "unmet_meals": unmet,
		"failures": failures, "notable_events": notable, "event_count": history.size()}


func participant_ids() -> Array:
	return IDS.duplicate()
