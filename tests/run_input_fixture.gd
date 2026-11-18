extends SceneTree
const Runner=preload("res://scripts/sim/input_runner.gd")
const FixtureWorld=preload("res://tests/input_fixture_world.gd")
func _init() -> void:
	var label: String=OS.get_cmdline_user_args()[0]
	var r=Runner.new(42,"scarce","R_input_aware");r.world=FixtureWorld.new(label);r.initial=r.world.snapshot();r.world.advance_day()
	var times: Array=r.TIMES.duplicate();times.append_array([900,955]);times.sort()
	for minute in times:
		if label=="remote_buyer" and minute==610:
			r.world.advance_time(minute);r.world.depart("bram",r.Brew.SITES.mill)
			for b in ["mill","brewery"]:r.world.propose_grain(r.Brew.OWNERS[b],b)
			r.world.clear_grain("ada");r.world.tender_early_receipts()
		else:r.appointment(minute)
		if label=="invalid_attempts" and minute in [610,730]:
			var before: Dictionary=r.world.snapshot().entities
			assert(not r.world.request_grain("cora","mill",1,{}))
			var q: Dictionary=r.world._requests.mill.quote.duplicate(true);q.version+=1
			assert(not r.world.request_grain("bram","mill",1,q))
			assert(not r.world.purchase_quote("mill",q,5))
			assert(before==r.world.snapshot().entities)
	print(JSON.stringify({"report":r.report(),"events":r.world.events()},"",true));quit()
