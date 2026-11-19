extends RefCounted
## M14 prescribed three-day contracts; no autonomous employment decisions.

const Reference = preload("res://scripts/sim/equilibrium_config.gd")
const WAGE = 6
const CAPITAL = 120
const PAIRS = [[0, 2], [0, 1], [1, 2]]
const PHASES = [[1, 2], [2, 3], [1, 3]]


static func initial() -> Dictionary:
	var state: Dictionary = Reference.initial()
	for firm in state.businesses.values():
		firm.owner_compensation = 0
		var employees: Array = firm.employees.duplicate()
		employees.sort()
		for index in employees.size():
			var job: Dictionary = state.employment[employees[index]]
			job.wage = WAGE
			job["contract"] = {"cycle_days": 3, "shifts_per_cycle": 2, "cycle_compensation": 12, "phases": PHASES[index].duplicate()}
	return state


static func workers(firm: Dictionary, day: int) -> Array:
	assert(day > 0)
	var employees: Array = firm.employees.duplicate()
	employees.sort()
	return PAIRS[(day - 1) % 3].map(func(index): return employees[index])
