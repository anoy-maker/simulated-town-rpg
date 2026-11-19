extends RefCounted
## Fixed M10 experimental choices; no economic endowment or price changes.

const Labor = preload("res://scripts/sim/labor_config.gd")
const Kernel = preload("res://scripts/sim/world_state.gd")
const POLICIES = {"none": 0, "needs": 1, "half-surplus": 2}
const RESERVE_DAYS = 2
const HOUSEHOLD_MEALS = 2


static func operating_reserve(business: Dictionary, employment: Dictionary) -> int:
	var wage: int = business.owner_compensation
	for worker in business.employees:
		if employment[worker].active:
			wage = maxi(wage, employment[worker].wage)
	var rule: Dictionary = Labor.INDUSTRIES[business.industry]
	var inputs: int = 0
	if not rule.recipe.is_empty():
		for item in Kernel.RECIPES[rule.recipe].inputs:
			inputs += Kernel.RECIPES[rule.recipe].inputs[item] * business.assets.batches_per_shift * Labor.PRICES[item]
	# Trusted M9 assets have <=12 slots, wages <=MAX; this multiplication fits int64.
	# A reserve above the money bound means no cash is ever distributable.
	return mini(Kernel.MAX_AMOUNT, RESERVE_DAYS * business.assets.daily_slots * (wage + inputs))
