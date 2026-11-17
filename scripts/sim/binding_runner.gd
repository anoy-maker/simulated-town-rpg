extends "res://scripts/sim/labor_market_runner.gd"
const BindingWorld=preload("res://scripts/sim/binding_world.gd")
var contract_mode: String
func _init(seed: int=42,condition: String="reference",selected_mode: String="matching",selected_fixture: String="none") -> void:
	super(seed,condition)
	contract_mode=selected_mode;labor_fixture=selected_fixture
	world=BindingWorld.new(seed,condition,selected_mode,selected_fixture);initial=world.snapshot()
func _industry(b: String) -> void:
	world.manage(Brew.OWNERS[b],b)
	var p: Dictionary=world.plan_business(Brew.OWNERS[b],b)
	for w in world._active_staff(b):world.begin_attendance(w,b,w in p.workers)
func appointment(minute: int) -> void:
	var start: int=Time.get_ticks_usec() if measure else 0
	if minute not in [480,1140,1440]:
		super(minute);world.tender_early_receipts()
		if measure:appointments.back().usec=Time.get_ticks_usec()-start
		return
	world.advance_time(minute)
	if minute==480:
		for id in residents():
			if id in Brew.OWNERS.values():world.depart(id,initial.spatial.presences[id].schedule.first_destination)
			elif labor_fixture=="no_show" and id=="dain":world.depart(id,Brew.SITES.bakery)
			elif world._affiliations.has(id):world.depart(id,Brew.SITES[world._affiliations[id].business])
		world.tender_early_receipts()
	elif minute==1140:
		for b in Brew.ORDER:world.settle_wages(Brew.OWNERS[b],b)
		for b in Brew.ORDER:world.settle_profit(Brew.OWNERS[b],b)
		world.close_contract_day()
	else:world.close_boundary()
	if measure:appointments.append({"day":world._day,"minute":minute,"usec":Time.get_ticks_usec()-start})
func report() -> Dictionary:
	var r: Dictionary=super();r.scenario="settlement_binding_contracts"
	r["contracts"]=preload("res://scripts/sim/binding_report.gd").build(initial,world.snapshot(),world.events(),r,contract_mode)
	return r
