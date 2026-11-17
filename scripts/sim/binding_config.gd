extends RefCounted
const Brew=preload("res://scripts/sim/brewery_config.gd")
const MODES=["matching","obligations_only"]
const FIXTURES=["none","cash_short","cash_zero","mill_zero","insolvent","no_show","staggered"]
static func initial(fixture: String="none") -> Dictionary:
	assert(fixture in FIXTURES)
	var state: Dictionary=Brew.initial()
	var ids: Array=state.employment.keys();ids.sort()
	for index in ids.size():
		state.employment[ids[index]].end_day=2+index%3 if fixture=="staggered" else 4
	if fixture in ["cash_short","cash_zero","insolvent"]:
		var removed: int=0
		for e in state.entities:
			if e.id=="bakery":
				var cash: int=6 if fixture=="cash_short" else 0
				removed+=e.money-cash;e.money=cash
				if fixture!="insolvent":e.inventory.bread=21
			if e.id=="finn":removed+=e.money;e.money=0
		for e in state.entities:
			if e.id=="visitors":e.money+=removed
	if fixture=="mill_zero":
		for e in state.entities:
			if e.id=="mill":e.money=0;e.inventory.flour=15
			if e.id=="hale":e.money=0
			if e.id=="visitors":e.money+=126
	return state
