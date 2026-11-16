extends SceneTree
const Math=preload("res://scripts/sim/native_math.gd")
const Batched=preload("res://scripts/sim/batched_bakery_policy.gd")
const Policy=preload("res://scripts/sim/bakery_policy.gd")
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
func _init() -> void:
	var args=OS.get_cmdline_user_args()
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var output: String=args[1]
	DirAccess.make_dir_recursive_absolute(output)
	var manifest: Array=[]
	for day in [1,3,15,30]:
		var d: Dictionary=data.report.learning.decisions[day-1]
		var o: Dictionary=d.observation
		for key in ["current_price","carry","supply","day"]: o[key]=int(o[key])
		o.posted=o.posted.map(func(x):return int(x))
		o.minimum=o.minimum.map(func(x):return int(x))
		o.state=o.state.map(func(x):return int(x))
		var math=Math.new()
		math.record_packets=true
		var proposal=Batched.decide(o,d.beliefs,"D",math)
		assert(proposal==Policy.decide(o,d.beliefs,"D"))
		for i in math.packets.size():
			var name="D-day%d-pass%d"%[day,i+1]
			_save(output,name,math.packets[i],manifest)
	var math=Math.new()
	math.record_packets=true
	var forecast=Policy.forecasts(Beliefs.fresh(),[1,6,12],3)
	var jobs: Array=[]
	for supply in [0,1,7]:
		for price in [1,6,12]: jobs.append({"state":[54.0,0.0,24.0,0.0],"price":price,"forecast":forecast[price],"supply":supply})
	for cash in [0.0,3.999999998,4.0,17.999999998,18.0,54.0,70.0,120.0,300.0]:
		for bread in [0.0,23.999999998,24.0,24.000000002,1000.0]:
			for p in [1,6,12]: jobs.append({"state":[cash,4.0,bread,0.0],"price":p,"forecast":forecast[p],"supply":12})
	math.batch(2,jobs)
	_save(output,"boundaries",math.packets[0],manifest)
	var high_o={"current_price":11,"posted":[1,2,3,4,5,6,7,8,9,10,11],"state":[300,12,24,180],"carry":3,"minimum":[1,0],"supply":12}
	var high=Math.new()
	high.record_packets=true
	var high_proposal=Batched.decide(high_o,Beliefs.fresh(),"D",high)
	assert(high_proposal==Policy.decide(high_o,Beliefs.fresh(),"D"))
	assert(high_proposal.candidates.size()==12)
	for i in high.packets.size(): _save(output,"high-branch-pass%d"%[i+1],high.packets[i],manifest)
	FileAccess.open(output+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest))
	print(JSON.stringify({"packets":manifest.size(),"decisions":4,"boundary_jobs":jobs.size()}))
	quit()
func _save(folder: String,name: String,packet: Dictionary,manifest: Array) -> void:
	FileAccess.open(folder+"/"+name+".bin",FileAccess.WRITE).store_buffer(packet.input)
	FileAccess.open(folder+"/"+name+".json",FileAccess.WRITE).store_string(JSON.stringify(packet.results))
	manifest.append(name)
