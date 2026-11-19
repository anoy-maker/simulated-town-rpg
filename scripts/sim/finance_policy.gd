extends RefCounted
## Pure ownership-income decision; wages and every M9 production/food policy stay intact.

const Config = preload("res://scripts/sim/finance_config.gd")


static func decide(observation: Dictionary, policy: String) -> Dictionary:
	assert(policy in Config.POLICIES)
	var action: Dictionary = {"type": "wait"}
	var reason: String = "withdrawals_disabled"
	if policy != "none":
		var firm: Dictionary = observation.business
		reason = "no_owned_business"
		if not firm.is_empty():
			var shortfall: int = maxi(0, maxi(0, Config.HOUSEHOLD_MEALS - observation.self.inventory.bread) * Config.Labor.PRICES.bread - observation.self.money)
			reason = "household_budget_satisfied"
			if shortfall > 0:
				@warning_ignore("integer_division")
				var available: int = firm.withdrawal.distributable_cash / Config.POLICIES[policy]
				var amount: int = mini(shortfall, available)
				reason = "ownership_income_for_food"
				if available == 0:
					reason = "operating_reserve_retained" if firm.withdrawal.distributable_cash == 0 else "payout_fraction_rounds_to_zero"
				if amount > 0:
					action = {"type": "owner_withdrawal", "amount": amount}
	return {"action": action, "reason": reason}
