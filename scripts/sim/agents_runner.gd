extends "res://scripts/sim/trading_runner.gd"

const AgentWorld = preload("res://scripts/sim/agent_world.gd")
const Policy = preload("res://scripts/sim/npc_policy.gd")

var _goals: Dictionary


func _init(seed_value: int = 42, initial_entities: Array = [], goals: Dictionary = Policy.DEFAULT_GOALS) -> void:
	super(seed_value, initial_entities)
	world = AgentWorld.new(default_entities() if initial_entities.is_empty() else initial_entities)
	_initial = world.snapshot()
	_goals = goals.duplicate(true)
	assert(_goals.food_target is int and _goals.food_target >= 1 and _goals.food_target <= World.MAX_AMOUNT)
	assert(_goals.max_batches is int and _goals.max_batches >= 1 and _goals.max_batches <= 2)
	assert(_goals.reserve_food_money is bool)
	for role in ["farmer", "miller", "baker"]:
		assert(_goals.output_targets[role] is int and _goals.output_targets[role] >= 1
			and _goals.output_targets[role] <= World.MAX_AMOUNT)


func run(days: int) -> void:
	assert(days >= 0)
	for _index in days:
		world.advance_day()
		world.transfer_money("farmer", "laborer", DAILY_PAYMENT)
		# Draw once per day even when Ada waits, matching M2's environmental sequence.
		var harvest_yield: int = _rng.randi_range(2, 6)
		_decide("farmer", "work", harvest_yield)
		for actor in ["miller", "baker"]:
			_decide(actor, "inputs")
			_decide(actor, "work")
		for actor in IDS:
			_decide(actor, "food")
		for actor in IDS:
			_decide(actor, "meal")


func _decide(actor: String, phase: String, harvest_yield: int = 0) -> void:
	var proposal: Dictionary = Policy.decide(world.observe(actor), _goals.duplicate(true), phase)
	world.execute_decision(actor, phase, proposal, harvest_yield)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "agents"
	summary["goals"] = _goals.duplicate(true)
	var decisions = {"total": 0, "executed": 0, "rejected": 0, "wait": 0,
		"by_actor": {}, "by_action": {}, "by_reason": {}}
	var failures: Dictionary = {}
	var notable: Array = []
	for event in world.events():
		if event.action == "decision":
			decisions.total += 1
			decisions[event.details.outcome] += 1
			for pair in [["by_actor", event.actor], ["by_action", event.details.selected_action.get("type", "invalid")],
					["by_reason", event.details.reason]]:
				decisions[pair[0]][pair[1]] = decisions[pair[0]].get(pair[1], 0) + 1
		elif not event.success:
			var key: String = event.action + ":" + event.details.reason
			failures[key] = failures.get(key, 0) + 1
			if notable.size() < 8:
				notable.append(event)
	# Decision failures describe their commands, not additional economic losses.
	for key in summary.failure_groups.keys():
		if summary.failure_groups[key].action == "decision":
			summary.failure_groups.erase(key)
	summary.failures = failures
	summary.notable_events = notable
	summary["decisions"] = decisions
	return summary
