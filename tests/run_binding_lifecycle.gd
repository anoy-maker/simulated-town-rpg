extends SceneTree
func _init() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	assert(args.size()==1 and args[0] in ["decline","renew","rehire","cancel","worker_release","employer_release","overlap","remote","oldest_after_expiry","declined_assignment"])
	var helpers=preload("res://tests/binding_tests.gd")
	var r: RefCounted
	if args[0] in ["decline","renew","rehire","cancel"]:
		r=helpers.board_last_day();var app: String=helpers.offer(r,"dain","farm")
		if args[0] in ["decline","rehire"]:assert(r.world.decline_offer("dain",app))
		else:
			assert(r.world.accept_job_offer("dain",app))
			if args[0]=="cancel":assert(r.world.cancel_notice("ada","notice:0003:farm"))
		helpers.finish(r,955)
		if args[0] in ["renew","rehire"]:r.run(1)
	elif args[0] in ["worker_release","employer_release"]:
		var employer: bool=args[0]=="employer_release"
		r=helpers.through("no_show" if employer else "insolvent",955)
		var worker: String="dain" if employer else "iona"
		var proof: int=helpers.breach(r.world,worker,"worker_nonattendance" if employer else "employer_unpaid")
		assert(r.world.release_for_breach("ada" if employer else worker,worker,proof));helpers.finish(r,955)
	elif args[0]=="overlap":
		r=helpers.board_first("staggered");var one: String=helpers.offer(r,"dain","farm");var two: String=helpers.offer(r,"dain","mill")
		r.world.inspect_job_offers("dain");assert(r.world.accept_job_offer("dain",one));assert(not r.world.accept_job_offer("dain",two));helpers.finish(r,955)
	elif args[0]=="oldest_after_expiry":r=helpers.deferred_sales();r.run(1)
	elif args[0]=="declined_assignment":
		r=helpers.through("cash_short",780);r.world.advance_time(840);r.world.manage("cora","bakery")
		for person in r.world._active_staff("bakery"):assert(r.world.begin_attendance(person,"bakery",person=="finn"))
		helpers.finish(r,840)
	else:
		r=preload("res://scripts/sim/binding_runner.gd").new();assert(not r.world.apply_for_job("finn","forged"));r.run(1)
	print(JSON.stringify({"report":r.report(),"events":r.world.events()},"",true));quit()
