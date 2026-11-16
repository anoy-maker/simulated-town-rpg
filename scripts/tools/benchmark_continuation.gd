extends SceneTree
## Replay D's permitted day-15 continuation inputs, without world/report work in timing.
const Finance=preload("res://scripts/sim/bakery_finance.gd")
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
const Policy=preload("res://scripts/sim/bakery_policy.gd")
const Profile=preload("res://scripts/sim/execution_profile.gd")

func _cohort(raw: Dictionary) -> Dictionary:
	var result: Dictionary=raw.duplicate()
	for key in ["arrivals","eligible","sales"]: result[key]=int(result[key])
	return result

func _init() -> void:
	Profile.reset(false)
	var path: String=OS.get_cmdline_user_args()[0]
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var decision: Dictionary=data.report.learning.decisions[14]
	var o: Dictionary=decision.observation
	var beliefs: Dictionary=decision.beliefs
	var tasks: Array=[]
	for row in decision.proposal.candidates:
		var posted: Array=[]
		for price in o.posted: posted.append(int(price))
		var prices: Array=Policy.candidates(int(row.price),posted+[int(row.price)])
		var frozen: Dictionary=Policy.forecasts(beliefs,prices,o.carry)
		for branch in row.branches:
			for price in prices: tasks.append([branch.state,price,frozen[price],o.supply])
			var posterior: Dictionary=Beliefs.update(beliefs,{"local":_cohort(branch.local),"visitor":_cohort(branch.visitor)},int(row.price),true)
			var updated: Dictionary=Policy.forecasts(posterior,prices,o.carry)
			tasks.append([branch.state,int(branch.frozen_price),updated[int(branch.frozen_price)],o.supply])
			for price in prices: tasks.append([branch.state,price,updated[price],o.supply])
	assert(tasks.size()==306)
	# Same one-task warm-up in each fresh process, excluded from measured batch.
	Finance.continuation(tasks[0][0],tasks[0][1],tasks[0][2],tasks[0][3])
	var values: Array=[]
	var start=Time.get_ticks_usec()
	for task in tasks: values.append(Finance.continuation(task[0],task[1],task[2],task[3]))
	var elapsed=Time.get_ticks_usec()-start
	print(JSON.stringify({"continuation_usec":elapsed,"tasks":tasks.size(),"input_sha256":JSON.stringify(tasks,"",true).sha256_text(),"values":values},"",true))
	quit()
