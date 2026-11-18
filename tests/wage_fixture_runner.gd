extends "res://scripts/sim/wage_runner.gd"
const FixtureWorld=preload("res://tests/wage_fixture_world.gd")
var technical_fixture: String
func _init(seed_value: int=42,condition: String="reference",arm: String="worker_bids",allocation: String="original",selected_fixture: String="manual_mixed") -> void:
	technical_fixture=selected_fixture
	super(seed_value,condition,arm,allocation)
	world=FixtureWorld.new(seed_value,condition,arm,allocation,selected_fixture);initial=world.snapshot()
func appointment(minute: int) -> void:
	if technical_fixture=="manual_no_show" and world._day==4 and minute==480:
		world.advance_time(minute)
		for w in residents():
			if w in Brew.OWNERS.values():world.depart(w,initial.spatial.presences[w].schedule.first_destination)
			elif w=="kira":world.depart(w,Brew.SITES.bakery)
			elif world._affiliations.has(w):world.depart(w,Brew.SITES[world._affiliations[w].business])
		world.tender_early_receipts();return
	if minute!=955:super(minute);return
	var stamp: int=Time.get_ticks_usec()
	world.advance_time(minute);world.freeze_demand()
	for w in residents():world.begin_board(w)
	for b in Brew.ORDER:world.advertise(Brew.OWNERS[b],b)
	for w in residents():
		if w not in Brew.OWNERS.values():world.inspect_jobs(w)
	if world._day==3:
		var notice: String="wage_notice:0003:farm"
		for row in [{"worker":"dain","wage":10},{"worker":"finn","wage":8},{"worker":"kira","wage":5}]:
			assert(world.submit_wage_bid(row.worker,notice,row.wage,world._wage_known[row.worker].event_id))
	for b in Brew.ORDER:world.consider_applicants(Brew.OWNERS[b],b)
	for w in residents():
		if w not in Brew.OWNERS.values():world.respond_to_offers(w)
	world.tender_early_receipts();world.close_demand_windows(minute)
	if measure:appointments.append({"day":world._day,"minute":minute,"usec":Time.get_ticks_usec()-stamp})
func report() -> Dictionary:
	var r: Dictionary=super();r["wage_fixture"]=technical_fixture
	if technical_fixture=="manual_partial":r.cash_allocation.name="technical_partial"
	return r
