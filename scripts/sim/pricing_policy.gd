extends RefCounted
## Pure one-period belief evaluation; never reads world state or moves money.
const MODES = ["fixed", "rational_pricing", "personality"]


static func decide(o: Dictionary, mode: String = "rational_pricing", beliefs: Dictionary = {}) -> Dictionary:
	if mode not in MODES or mode == "personality":
		return {"mode": mode, "reason": "unsupported_mode", "candidates": [], "selected_price": null}
	var current: int = o.current_price
	var prices: Array = [current] if mode == "fixed" else [maxi(1, current - 1), current, mini(1000000000, current + 1)]
	var candidates: Array = []
	var selected: Dictionary = {}
	for price in prices:
		if candidates.any(func(c): return c.price == price):
			continue
		var demand: int = clampi(o.reference_demand + (o.reference_price - price) * o.sensitivity, 0, o.available)
		if beliefs.has("demand_by_price"):
			demand = clampi(beliefs.demand_by_price[str(price)], 0, o.available)
		var candidate = {"price": price, "demand": demand, "revenue": price * demand,
			"operating_cash": price * demand - o.planned_inputs - o.planned_payroll}
		candidates.append(candidate)
		if selected.is_empty() or candidate.operating_cash > selected.operating_cash \
				or (candidate.operating_cash == selected.operating_cash and (price == current or (selected.price != current and price < selected.price))):
			selected = candidate
	return {"mode": mode, "reason": "fixed" if mode == "fixed" else "maximum_estimated_operating_cash",
		"candidates": candidates, "selected_price": selected.price}
