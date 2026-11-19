extends RefCounted
## M17's immutable map, housing and prescribed daily times; no economic parameters.
const SITES={"farm":[6,1],"mill":[6,3],"bakery":[8,3]}
const GATE=[9,3]
const WINDOWS={"farm":[540,600],"mill":[660,720],"bakery":[840,900]}
const TRADE={"farm":[600,660],"mill":[720,780],"bakery":[900,1035]}
const CASES=["control","late_worker","early_close"]
const COURIERS={"mill":{"seller":"farm","item":"wheat","purchase":610,"depart":615,"deposit":625},
	"bakery":{"seller":"mill","item":"flour","purchase":730,"depart":735,"deposit":745}}


static func initial(economy: Dictionary, experiment: String) -> Dictionary:
	assert(experiment in CASES)
	var people: Dictionary={}
	var ids: Array=[]
	for entity in economy.entities:
		if entity.kind=="resident": ids.append(entity.id)
	ids.sort()
	for index in ids.size():
		var id: String=ids[index]
		@warning_ignore("integer_division")
		var home: Array=[1,1+2*(index/4)]
		var business: String=""
		for firm in economy.businesses.values():
			if firm.owner==id or id in firm.employees: business=firm.id
		var owner: bool=economy.businesses[business].owner==id
		var first: String={"bram":"farm","cora":"mill"}.get(id,business)
		var schedule={"depart":540 if experiment=="late_worker" and id=="dain" else 480,"first_destination":SITES[first].duplicate(),
			"business":business,"work_start":WINDOWS[business][0],"work_end":WINDOWS[business][1],"owner":owner,
			"shop":960,"home_depart":1035,"meal":1110,"courier":COURIERS[business].duplicate(true) if owner and COURIERS.has(business) else {}}
		people[id]={"id":id,"kind":"resident","account":id,"active":true,"home":home.duplicate(),"tile":home.duplicate(),
			"destination":home.duplicate(),"activity":"idle","until":0,"business":"","route":[],"last_step":-5,"schedule":schedule}
	return {"minute":0,"case":experiment,"width":10,"height":7,"retail_close":960 if experiment=="early_close" else 1035,"presences":people}


static func route(start: Array, destination: Array) -> Array:
	var current: Array=start.duplicate()
	var result: Array=[]
	for axis in [0,1]:
		while current[axis]!=destination[axis]:
			current[axis]+=1 if destination[axis]>current[axis] else -1
			result.append(current.duplicate())
	return result
