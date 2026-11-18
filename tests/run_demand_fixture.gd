extends SceneTree
const Runner=preload("res://scripts/sim/demand_runner.gd")
const FixtureWorld=preload("res://tests/demand_fixture_world.gd")
func _init() -> void:
	var label: String=OS.get_cmdline_user_args()[0]
	var r=Runner.new(42,"reference","requests_smoothed")
	r.world=FixtureWorld.new(label);r.initial=r.world.snapshot();r.world.advance_day()
	var times: Array=r.TIMES.duplicate();times.append_array([900,955]);times.sort()
	for minute in times:
		if label=="remote_farm" and minute==610:
			r.world.advance_time(minute);r.world.depart("bram",r.Brew.SITES.mill)
			for b in ["mill","brewery"]:r.world.propose_grain(r.Brew.OWNERS[b],b)
			r.world.clear_grain("ada");r.world.tender_early_receipts()
		else:
			if label=="duplicate" and minute==965:
				r.world.advance_time(minute);r.world.shop_at("ada","bakery")
			r.appointment(minute)
	print(JSON.stringify({"report":r.report(),"events":r.world.events()},"",true));quit()
