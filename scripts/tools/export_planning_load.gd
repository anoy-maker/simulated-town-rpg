extends SceneTree
## Offline immutable fixture export; never a responsiveness benchmark.
const Job=preload("res://scripts/sim/planning_job.gd")
func _init() -> void:
	var args=OS.get_cmdline_user_args()
	if args.size()!=1:
		printerr("Usage: export_planning_load.gd -- output_directory")
		quit(2)
		return
	var folder: String=args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var manifest: Array=[]
	var pins: Dictionary={"C":"e4d15eb097eeaf1f31aa8b9b642dc29e9e1771989d0326724c007d0c1fce6711","D":"0ee67b3939cf202bfa6a9f3fd276beca814b9bdf8652f36b6278b730249d068f"}
	for stage in ["C","D"]:
		var runner=preload("res://scripts/sim/planning_jobs_runner.gd").new(42,stage)
		assert(runner.configure(30,"sync"))
		while not runner.step(): pass # Offline extraction, not an event-loop/worker poll.
		runner.close()
		var report: Dictionary=runner.report()
		var sha: String=(JSON.stringify({"report":report},"",true)+"\n").sha256_text()
		assert(sha==pins[stage])
		for day in [1,3,15,30]:
			var d: Dictionary=runner.decisions[day-1]
			var name: String="%s-%d"%[stage,day]
			var packet=Job.create(1,d.observation,d.beliefs,stage)
			FileAccess.open(folder+"/"+name+".request",FileAccess.WRITE).store_buffer(packet)
			var expected=var_to_bytes(d.proposal)
			FileAccess.open(folder+"/"+name+".proposal",FileAccess.WRITE).store_buffer(expected)
			manifest.append({"case":name,"stage":stage,"day":day,"source_report_sha256":sha,"source_ledger_sha256":report.profitable.ledger_sha256,
				"input_hash":Job.decode(packet).input_hash,"request_hash":Job.fingerprint(packet),"proposal_hash":Job.fingerprint(d.proposal),"selected_price":d.proposal.selected_price,
				"request_bytes":packet.size(),"proposal_bytes":expected.size()})
	FileAccess.open(folder+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify({"version":1,"source":"M21 unchanged synchronous Rust runner; seed42; source full hashes verified","godot":Engine.get_version_info().string,"cases":manifest},"\t",true)+"\n")
	print(JSON.stringify({"cases":manifest.size(),"source_reports_verified":2}))
	quit()
