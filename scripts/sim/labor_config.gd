extends RefCounted
## M9's predeclared endowments. Business accounts are not residents.

const PRICES = {"wheat": 1, "flour": 2, "bread": 3}
const WAGE = 3
const INDUSTRIES = {
	"farmer": {"output": "wheat", "input": "", "recipe": "", "batches": 0, "target": 16},
	"miller": {"output": "flour", "input": "wheat", "recipe": "mill", "batches": 2, "target": 16},
	"baker": {"output": "bread", "input": "flour", "recipe": "bake", "batches": 2, "target": 18},
}
const BUSINESS_ORDER = ["farm", "mill", "bakery"]


static func initial() -> Dictionary:
	var roster = [
		["ada", "Ada", "farmer", "farmer"], ["bram", "Bram", "miller", "miller"],
		["cora", "Cora", "baker", "baker"], ["dain", "Dain", "laborer", "farmer"],
		["edda", "Edda", "farmer", "farmer"], ["finn", "Finn", "baker", "baker"],
		["gale", "Gale", "laborer", "farmer"], ["hale", "Hale", "miller", "miller"],
		["iona", "Iona", "baker", "baker"], ["jory", "Jory", "laborer", "miller"],
		["kira", "Kira", "laborer", "baker"], ["lyle", "Lyle", "miller", "miller"],
	]
	var entities: Array = []
	for person in roster:
		entities.append({"id": person[0], "name": person[1], "role": person[2], "kind": "resident",
			"skills": [person[3]], "labor_capacity": 1, "money": 6,
			"inventory": {"wheat": 0, "flour": 0, "bread": 1}})
	var businesses: Dictionary = {}
	var employment: Dictionary = {}
	var firms = [
		["farm", "farmer", "ada", ["dain", "edda", "gale"], {"wheat": 8, "flour": 0, "bread": 0}],
		["mill", "miller", "bram", ["hale", "jory", "lyle"], {"wheat": 8, "flour": 4, "bread": 0}],
		["bakery", "baker", "cora", ["finn", "iona", "kira"], {"wheat": 0, "flour": 8, "bread": 6}],
	]
	for firm in firms:
		var id: String = firm[0]
		entities.append({"id": id, "name": id.capitalize(), "role": firm[1], "kind": "business",
			"money": 120, "inventory": firm[4].duplicate()})
		businesses[id] = {"id": id, "industry": firm[1], "owner": firm[2], "employees": firm[3].duplicate(),
			"account": id, "assets": {"daily_slots": 4, "batches_per_shift": INDUSTRIES[firm[1]].batches},
			"output_target": INDUSTRIES[firm[1]].target, "owner_compensation": WAGE}
		for worker in firm[3]:
			employment[worker] = {"worker": worker, "business": id, "wage": WAGE, "active": true}
	return {"entities": entities, "businesses": businesses, "employment": employment}
