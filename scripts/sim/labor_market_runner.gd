extends "res://scripts/sim/brewery_runner.gd"
## Reuse M23's entire physical economy; only routes/meeting/current labor differ.
const LaborWorld=preload("res://scripts/sim/labor_market_world.gd")
var labor_mode: String
var tie_rule: String
var labor_fixture: String
func _init(seed: int=42, condition: String="reference", selected_mode: String="matching", selected_tie: String="neutral_rotate", selected_fixture: String="none") -> void:
	super(seed,condition)
	labor_mode=selected_mode;tie_rule=selected_tie;labor_fixture=selected_fixture
	world=LaborWorld.new(seed,condition,selected_mode,selected_tie,selected_fixture)
	initial=world.snapshot()
func run(days: int) -> void:
	var times: Array=TIMES.duplicate()
	times.append(900)
	if labor_mode=="matching":times.append(955)
	times.sort()
	for day in days:
		world.advance_day()
		for minute in times:appointment(minute)
func appointment(minute: int) -> void:
	if minute not in [480,900,930,955]:
		super(minute)
		return
	var started: int=Time.get_ticks_usec() if measure else 0
	world.advance_time(minute)
	if minute==480:
		for id in residents():
			if id in Brew.OWNERS.values():world.depart(id,initial.spatial.presences[id].schedule.first_destination)
			elif world._affiliations.has(id):world.depart(id,Brew.SITES[world._affiliations[id].business])
	elif minute==900:
		for id in residents():
			if id not in Brew.OWNERS.values() and not world._affiliations.has(id):world.depart(id,Brew.SITES.bakery,955)
	elif minute==930:
		for id in residents():
			var p: Dictionary=world._space.presences[id]
			if p.activity!="walking" or p.destination!=Brew.SITES.bakery:world.depart(id,Brew.SITES.bakery)
	elif minute==955:
		for id in residents():world.begin_board(id)
		for business in Brew.ORDER:world.advertise(Brew.OWNERS[business],business)
		for id in residents():
			if id not in Brew.OWNERS.values():world.inspect_jobs(id);world.search_job(id)
		for business in Brew.ORDER:world.consider_applicants(Brew.OWNERS[business],business)
		for id in residents():
			if id not in Brew.OWNERS.values():world.respond_to_offers(id)
	if measure:appointments.append({"day":world._day,"minute":minute,"usec":Time.get_ticks_usec()-started})
func report() -> Dictionary:
	var r: Dictionary=super()
	r.scenario="settlement_labor_market"
	var counts: Dictionary={"postings":0,"applications":0,"offers":0,"accepted":0,"employment_started":0,"employment_ended":0,"canceled_pending":0,"rejections":0}
	var transitions: Array=[];var searches: Dictionary={}
	for e in world.events():
		if not e.success:
			if e.action in ["job_posted","application_submitted","job_offer_made","offer_accepted","resignation_requested"]:counts.rejections+=1
			continue
		if e.action=="job_posted":counts.postings+=1
		if e.action=="application_submitted":counts.applications+=1
		if e.action=="job_offer_made":counts.offers+=1
		if e.action=="offer_accepted":counts.accepted+=1
		if e.action in ["employment_started","employment_ended"]:
			counts[e.action]+=1;transitions.append({"day":e.day,"minute":e.minute,"worker":e.actor,"business":e.target,"action":e.action,"details":e.details.duplicate(true)})
		if e.action=="labor_notice_closed":counts.canceled_pending+=e.details.canceled_pending.size()
		if e.action=="labor_search_decision":searches[e.details.proposal.reason]=searches.get(e.details.proposal.reason,0)+1
	r["labor"]={"mode":labor_mode,"tie":tie_rule,"fixture":labor_fixture,"wage":10,"counts":counts,"search_reasons":searches,"transitions":transitions,"qualification":"M24 homogeneous labor; historical skill arrays unchanged"}
	for id in r.accounts:
		if r.final.entities[id].kind=="resident":
			r.accounts[id]["employer"]=r.final.affiliations.get(id,{}).get("business","")
	return r
