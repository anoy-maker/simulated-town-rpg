extends "res://scripts/sim/market_runner.gd"
## Alternate population only; scheduling, authority, reporting, and policies are inherited.


static func downstream_entities() -> Array:
	var entities: Array = default_entities()
	entities.append({"id": "miller_2", "name": "Edda", "role": "miller", "money": 20,
		"inventory": {"wheat": 0, "flour": 0, "bread": 1}})
	entities.append({"id": "baker_2", "name": "Finn", "role": "baker", "money": 20,
		"inventory": {"wheat": 0, "flour": 0, "bread": 1}})
	return entities


func _init(seed_value: int = 42, initial_entities: Array = [], goals: Dictionary = Policy.DEFAULT_GOALS) -> void:
	super(seed_value, downstream_entities() if initial_entities.is_empty() else initial_entities, goals)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "market_downstream"
	return summary
