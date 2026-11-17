extends RefCounted
const Brew=preload("res://scripts/sim/brewery_config.gd")
const MODES=["shift_selection","matching"]
const TIES=["legacy_sorted","neutral_rotate"]
static func initial(fixture: String="none") -> Dictionary:
	var state: Dictionary=Brew.initial()
	assert(fixture in fixtures())
	if fixture!="none":
		var worker: String="gale" if fixture=="vacancy" else fixture.trim_prefix("vacancy:")
		state.employment[worker].active=false
		state.employment[worker].end_day=1
	return state
static func fixtures() -> Array:
	var ids: Array=Brew.initial().employment.keys();ids.sort()
	return ["none","vacancy"]+ids.map(func(id):return "vacancy:"+str(id))
