extends RefCounted
## M23-only endowments. See the committed, independently checked feasibility witness.
const GOODS=["wheat","flour","bread","ale"]
const PRICES={"wheat":2,"flour":5,"bread":6,"ale":4}
const ORDER=["farm","mill","bakery","brewery"]
const OWNERS={"farm":"ada","mill":"bram","bakery":"cora","brewery":"mara"}
const INDUSTRIES={
	"farmer":{"output":"wheat","input":"","recipe":"","batches":0,"target":21,"take":0,"make":7},
	"miller":{"output":"flour","input":"wheat","recipe":"mill","batches":1,"target":15,"take":5,"make":5},
	"baker":{"output":"bread","input":"flour","recipe":"bake","batches":1,"target":21,"take":5,"make":7},
	"brewer":{"output":"ale","input":"wheat","recipe":"brew","batches":1,"target":12,"take":3,"make":6}}
const RECIPES={"mill":{"role":"miller","inputs":{"wheat":5},"outputs":{"flour":5}},
	"bake":{"role":"baker","inputs":{"flour":5},"outputs":{"bread":7}},
	"brew":{"role":"brewer","inputs":{"wheat":3},"outputs":{"ale":6}}}
const REQUIREMENTS={"farmer":["workshop","farm_tools"],"miller":["workshop","millstone"],"baker":["workshop","oven"],"brewer":["workshop","brew_vat"]}
const SITES={"farm":[6,1],"mill":[6,3],"bakery":[8,3],"brewery":[8,5]}
const WINDOWS={"farm":[540,600],"mill":[660,720],"bakery":[840,900],"brewery":[780,840]}
const TRADE={"farm":[600,660],"mill":[720,780],"bakery":[900,1050],"brewery":[900,1050]}
const CASES={"reference":21,"tight":19,"scarce":16,"no_brew_request":21}
static func empty_goods() -> Dictionary:
	return {"wheat":0,"flour":0,"bread":0,"ale":0}
static func initial() -> Dictionary:
	var state=preload("res://scripts/sim/enterprise_config.gd").initial(8622)
	for p in [["mara","Mara"],["nell","Nell"],["oren","Oren"]]:
		state.entities.append({"id":p[0],"name":p[1],"role":"brewer","kind":"resident","skills":["brewer"],"labor_capacity":1,"money":6,"inventory":empty_goods()})
	state.entities.append({"id":"brewery","name":"Brewery","role":"brewer","kind":"business","money":120,"inventory":empty_goods()})
	state.businesses["brewery"]={"id":"brewery","account":"brewery","industry":"brewer","owner":"mara","employees":["nell","oren"],"owner_compensation":0,"output_target":12,
		"assets":{"daily_slots":2,"batches_per_shift":1},"distribution_policy":{"mode":"full","reserve":120}}
	for worker in ["nell","oren"]: state.employment[worker]={"worker":worker,"business":"brewery","wage":10,"active":true,"start_day":1,"end_day":0}
	for entity in state.entities: entity.inventory=empty_goods()
	for job in state.employment.values():
		job.wage=10
		job.contract={"cycle_days":1,"shifts_per_cycle":1,"cycle_compensation":10,"phases":[1]}
	state.productive_assets={}
	for firm in state.businesses.values():
		firm.assets.daily_slots=firm.employees.size()
		firm.assets.batches_per_shift=INDUSTRIES[firm.industry].batches
		firm.output_target=INDUSTRIES[firm.industry].target
		for kind in REQUIREMENTS[firm.industry]:
			state.productive_assets[firm.id+":"+kind]={"holder":firm.id,"industry":firm.industry,"kind":kind,"capacity":firm.employees.size(),"price":0,"for_sale":false}
	return state
static func space(economy: Dictionary, experiment: String) -> Dictionary:
	assert(experiment in CASES)
	var old=economy.duplicate(true)
	old.entities=old.entities.filter(func(e):return e.id not in ["mara","nell","oren","brewery"])
	old.businesses.erase("brewery")
	var spatial=preload("res://scripts/sim/spatial_config.gd").initial(old,"control")
	for id in ["mara","nell","oren"]:
		var home: Array={"mara":[2,0],"nell":[2,2],"oren":[2,4]}[id]
		spatial.presences[id]={"id":id,"kind":"resident","account":id,"active":true,"home":home.duplicate(),"tile":home.duplicate(),"destination":home.duplicate(),"activity":"idle","until":0,"business":"","route":[],"last_step":-5,
			"schedule":{"depart":480,"first_destination":SITES.farm.duplicate() if id=="mara" else SITES.brewery.duplicate(),"business":"brewery","owner":id=="mara"}}
	spatial.case=experiment
	spatial.retail_close=1050
	return spatial
