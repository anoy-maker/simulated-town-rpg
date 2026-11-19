extends SceneTree
## Authority-only lifecycle witnesses for the independent Python replay.
func _init() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	assert(args.size()==1 and args[0] in ["cancel","unaccepted","no_vacancy"])
	var helpers=preload("res://tests/labor_market_tests.gd")
	var r=helpers.meeting("none" if args[0]=="no_vacancy" else "vacancy:dain");var w=r.world
	if args[0]=="no_vacancy":
		assert(not w.post_job("ada","farm","no-slot",10,1,1,30))
		assert(w.events().back().details.reason=="no_funded_positive_vacancy")
	else:
		var app: String=helpers.offered(r)
		if args[0]=="cancel":
			w.inspect_job_offers("finn");assert(w.accept_job_offer("finn",app));assert(w.cancel_notice("ada","notice:0001:farm"))
	for minute in r.TIMES:
		if minute>=960:r.appointment(minute)
	r.run(1)
	print(JSON.stringify({"report":r.report(),"events":w.events()},"",true))
	quit()
