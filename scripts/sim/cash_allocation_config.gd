extends RefCounted
## Initial ownership only. Historical configuration and operating books stay intact.
const ALLOCATIONS=["original","households_330","firms_330"]
const NONOWNERS=["dain","edda","finn","gale","hale","iona","jory","kira","lyle","nell","oren"]
const FIRMS={"farm":83,"mill":83,"bakery":82,"brewery":82}
static func allocate(original: Dictionary,allocation: String) -> Dictionary:
	assert(allocation in ALLOCATIONS)
	var state: Dictionary=original.duplicate(true)
	for e in state.entities:
		if allocation=="original":continue
		if e.id=="visitors":e.money-=330
		elif allocation=="households_330" and e.id in NONOWNERS:e.money+=30
		elif allocation=="firms_330" and e.id in FIRMS:e.money+=FIRMS[e.id]
	assert(state.entities.reduce(func(n,e):return n+e.money,0)==9192)
	return state
