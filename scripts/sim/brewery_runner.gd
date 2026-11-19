extends RefCounted
## M23-only feasible timetable. Policies choose quantities/work; authority owns outcomes.
const Brew=preload("res://scripts/sim/brewery_config.gd")
const World=preload("res://scripts/sim/brewery_world.gd")
const TIMES=[480,540,610,615,625,645,660,730,735,745,780,840,930,960,965,975,980,1020,1025,1030,1040,1045,1050,1060,1110,1140,1440]
var world: RefCounted
var initial: Dictionary
var seed_value: int
var experiment: String
var measure: bool=false
var appointments: Array=[]
func _init(seed: int=42, condition: String="reference", endowments: Dictionary={}) -> void:
	seed_value=seed;experiment=condition
	world=World.new(seed,condition,endowments)
	initial=world.snapshot()
func residents() -> Array:
	var ids: Array=initial.entities.keys().filter(func(id):return initial.entities[id].kind=="resident")
	ids.sort();return ids
func _industry(business: String) -> void:
	var owner: String=initial.businesses[business].owner
	world.manage(owner,business)
	var plan: Dictionary=world.plan_business(owner,business)
	for worker in plan.workers:world.start_shift(worker,business)
func run(days: int) -> void:
	for day in days:
		world.advance_day()
		for minute in TIMES:appointment(minute)
func appointment(minute: int) -> void:
	var started: int=Time.get_ticks_usec() if measure else 0
	world.advance_time(minute)
	match minute:
		480:
			for id in residents():world.depart(id,initial.spatial.presences[id].schedule.first_destination)
		540:_industry("farm")
		610:
			for business in ["mill","brewery"]:world.propose_grain(initial.businesses[business].owner,business)
			world.clear_grain("ada")
		615:
			for business in ["mill","brewery"]:world.depart(initial.businesses[business].owner,Brew.SITES[business])
		625:
			if world._cargo.mill.inventory.wheat>0:world.deposit("bram","mill")
		645:
			if world._cargo.brewery.inventory.wheat>0:world.deposit("mara","brewery")
		660:_industry("mill")
		730:world.procure_flour("cora")
		735:world.depart("cora",Brew.SITES.bakery)
		745:
			if world._cargo.bakery.inventory.flour>0:world.deposit("cora","bakery")
		780:_industry("brewery")
		840:_industry("bakery")
		930:
			for id in residents():world.depart(id,Brew.SITES.bakery)
		960:
			for id in residents():world.shop_at(id,"bakery")
		965:
			for id in residents():world.depart(id,Brew.SITES.brewery)
		975:
			for id in residents():world.shop_at(id,"brewery")
		980:
			for id in residents():
				if world._entities[id].inventory.ale>0:world.drink_ale(id)
			world.depart("cora",Brew.SITES.bakery)
		1020:
			for slot in range(1,7):
				world.enter_visitor(slot)
				world.depart(_visitor(slot),Brew.SITES.bakery)
		1025:
			for slot in range(1,7):world.shop_at(_visitor(slot),"bakery")
		1030:
			for slot in range(1,7):
				if world._space.presences[_visitor(slot)].loaf>0:world.consume_visitor(_visitor(slot))
				world.depart(_visitor(slot),Brew.SITES.brewery)
		1040:
			for slot in range(1,7):world.shop_at(_visitor(slot),"brewery")
		1045:
			for slot in range(1,7):
				if world._space.presences[_visitor(slot)].ale>0:world.drink_ale(_visitor(slot))
				world.depart(_visitor(slot),World.Town.GATE)
		1050:
			for id in residents():world.depart(id,initial.spatial.presences[id].home)
		1060:
			for slot in range(1,7):world.exit_visitor(_visitor(slot))
		1110:
			for id in residents():world.consume(id);world.rest(id)
		1140:
			for business in Brew.ORDER:world.settle_profit(initial.businesses[business].owner,business)
			world.close_contract_day()
	if measure:appointments.append({"day":world._day,"minute":minute,"usec":Time.get_ticks_usec()-started})
func _visitor(slot: int) -> String:return "visitor:%04d:%d"%[world._day,slot]
func report() -> Dictionary:
	return preload("res://scripts/sim/brewery_report.gd").build(initial,world.snapshot(),world.events(),seed_value,experiment)
