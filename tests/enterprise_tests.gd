extends RefCounted
const Runner = preload("res://scripts/sim/external_trade_runner.gd")
const World = preload("res://scripts/sim/enterprise_world.gd")
const Config = preload("res://scripts/sim/enterprise_config.gd")
const Fixtures = preload("res://scripts/sim/enterprise_fixtures.gd")
const Audit = preload("res://scripts/sim/enterprise_audit.gd")
const FIRM = "finn_bakery"


static func _unchanged(suite, w, call: Callable, label: String) -> void:
	var before: Dictionary = w.snapshot()
	var result: bool = call.call()
	suite._check(not result and w.snapshot() == before, label)


static func _verified(w) -> bool:
	return Audit.verify(w.events(), w.snapshot()).accounting.values().all(func(v): return v)


static func run(suite: SceneTree) -> void:
	for days in [1, 3, 30, 365]:
		var first = Runner.new(42)
		var split = Runner.new(42)
		first.run(days)
		split.run(1)
		split.run(days - 1)
		var r: Dictionary = first.report()
		var v: Dictionary = r.profitable.verification
		suite._check(v.accounting.values().all(func(x): return x) and v.reference_A.values().all(func(x): return x),
			"M15 A %dd every-event combined money/assets/goods/labor and daily actual external/village recurrence" % days)
		suite._check(first.world.events() == split.world.events() and first.world.snapshot() == split.world.snapshot() and r == split.report(), "M15 A %dd split state/ledger/report replay" % days)
		var valid: bool = r.open_economy.village_money == 432 + 24 * days and r.open_economy.external_money == 8760 - 24 * days and r.money.final == 9192
		valid = valid and r.shifts.paid == 9 * days and r.shifts.wages == 54 * days and r.profitable.distributions.amount == 18 * days
		valid = valid and r.profitable.contracts.due == 6 * days and r.profitable.contracts.completed == 6 * days and r.profitable.contracts.breaches == 0 and r.open_economy.additional_paid_shifts == 3 * days
		valid = valid and r.open_economy.resident_meals == 12 * days and r.open_economy.visitor_bread == 6 * days and r.totals.consumed.bread == 18 * days and r.accounts.visitors.consumed == 6 * days
		valid = valid and r.totals.harvested.wheat == 12 * days and r.totals.production_outputs == {"flour": 12 * days, "bread": 18 * days} and r.failures.is_empty()
		for actor in first.participant_ids():
			valid = valid and r.accounts[actor].consumed == days and r.final.entities[actor].money == 6 + 2 * days
		suite._check(valid, "M15 A %dd exact predicted reference results without refilling or replacing external demand" % days)
		print("M15 A days=%d village=%d external=%d combined=%d meals=%d visitor_bread=%d shifts=%d" % [days,r.open_economy.village_money,r.open_economy.external_money,r.money.final,r.open_economy.resident_meals,r.open_economy.visitor_bread,r.shifts.paid])
	var exhausted = Runner.new(42, Config.initial(20))
	exhausted.run(3)
	var r: Dictionary = exhausted.report()
	suite._check(_verified(exhausted.world) and r.open_economy.external_money == 0 and r.money.final == 452 and r.open_economy.visitor_bread == 5
		and r.open_economy.external_purchase_rejections == 13 and r.open_economy.resident_meals == 35 and r.profitable.cash_results.bakery.distributions == 2,
		"finite twenty-coin visitor purse exhausts after five loaves; failed purchases, unsold bread and Cora's missed meal remain real")
	var w = World.new(42, Config.initial(100, true))
	_unchanged(suite,w,func():return w.found_business("visitors",FIRM,"baker",300),"external account cannot found a local resident-owned firm")
	_unchanged(suite,w,func():return w.found_business("finn",FIRM,"baker",501),"insufficient personal capital cannot partially create a firm")
	var founded: bool = w.found_business("finn",FIRM,"baker",300)
	suite._check(founded and w.snapshot().entities.finn.money == 200 and w.snapshot().entities[FIRM].money == 300
		and w.snapshot().entities[FIRM].inventory == {"wheat":0,"flour":0,"bread":0} and w.snapshot().businesses[FIRM].employees.is_empty()
		and w.snapshot().cash_results[FIRM].sales == 0 and w.profit_budget(FIRM).eligible == 0 and not w._asset_error(FIRM).is_empty(),
		"founding transfers actual capital into a zero-endowment separate account without assets, employees, sales or profits")
	_unchanged(suite,w,func():return w.found_business("finn",FIRM,"baker",1),"business identity cannot be duplicated")
	_unchanged(suite,w,func():return w.contribute_capital("cora",FIRM,1),"only the actual sole owner contributes capital to that business")
	for amount in [0,-1,true,1.5,"2",9223372036854775807]:
		_unchanged(suite,w,func():return w.contribute_capital("finn",FIRM,amount),"invalid/overflowing capital amount rejects atomically")
	var more: bool = w.contribute_capital("finn",FIRM,10)
	suite._check(more and w.snapshot().entities.finn.money == 190 and w.snapshot().cash_results[FIRM].capital_contributions == 310 and w.profit_budget(FIRM).eligible == 0,"additional capital remains financing rather than sales or income")
	_unchanged(suite,w,func():return w.buy_asset("cora",FIRM,"spare_oven"),"unrelated owner cannot spend startup funds on equipment")
	_unchanged(suite,w,func():return w.buy_asset("finn",FIRM,"bakery:oven"),"a non-offered incumbent asset cannot be appropriated for free")
	var bought: bool = w.buy_asset("finn",FIRM,"spare_oven")
	suite._check(bought and w.snapshot().entities.equipment_seller.money == 180 and w.snapshot().productive_assets.spare_oven.holder == FIRM,"finite oven transfers only with actual seller payment")
	_unchanged(suite,w,func():return w.buy_asset("finn",FIRM,"spare_oven"),"an asset purchase cannot be duplicated")
	_unchanged(suite,w,func():return w.start_self_employment("finn",FIRM),"business ownership does not erase the founder's existing employment")
	w.request_resignation("finn","bakery")
	w.advance_day()
	w.start_self_employment("finn",FIRM)
	w.purchase(FIRM,"mill","flour",4,4)
	_unchanged(suite,w,func():return w.owner_work_shift("finn",FIRM),"missing workshop prevents skilled owner production even with flour and an oven")
	w.buy_asset("finn",FIRM,"spare_workshop")
	var worked: bool = w.owner_work_shift("finn",FIRM)
	suite._check(worked and w.snapshot().entities[FIRM].inventory.bread == 6 and w.snapshot().cash_results[FIRM].payroll == 0,"owner production is one real ingredient-consuming shift without a fabricated salary")
	_unchanged(suite,w,func():return w.owner_work_shift("finn",FIRM),"owner cannot produce twice on the same day's labor")
	var poor = World.new(42,Config.initial(100,true))
	poor.found_business("finn",FIRM,"baker",0)
	_unchanged(suite,poor,func():return poor.buy_asset("finn",FIRM,"spare_oven"),"insufficient business funds preserve both cash and asset holder")
	var seller_config: Dictionary = Config.initial(100,true)
	seller_config.productive_assets.spare_workshop.holder = "farm"
	var asset_seller = World.new(42,seller_config)
	asset_seller.found_business("finn",FIRM,"baker",300)
	asset_seller.buy_asset("finn",FIRM,"spare_workshop")
	suite._check(asset_seller.snapshot().entities.farm.money==180 and asset_seller.snapshot().cash_results.farm.capital_asset_sales==60
		and asset_seller.profit_budget("farm").eligible==0 and _verified(asset_seller),"asset-sale proceeds to an existing firm are capital receipts, not operating earnings")
	var limited_config: Dictionary = Config.initial(100,true)
	limited_config.productive_assets["farm:workshop"].capacity = 1
	var limited = World.new(42,limited_config)
	limited.advance_day()
	limited.offer_shift("ada","farm","dain")
	limited.work_shift("dain","farm")
	_unchanged(suite,limited,func():return limited.offer_shift("ada","farm","gale"),"finite owned asset capacity constrains paid work as well as abstract workplace slots")
	var b = Fixtures.owner_sale()
	r = b.report()
	var checkpoint: Dictionary = r.open_economy.fixture_checkpoints.after_startup
	suite._check(checkpoint.owner_cash == 200 and checkpoint.business_cash == 60 and checkpoint.book.capital_contributions == 300 and checkpoint.book.capital_purchases == 240 and checkpoint.book.sales == 0,
		"audited startup checkpoint matches the proposed personal/business/asset capital allocation")
	suite._check(_verified(b.world) and r.final.entities[FIRM].money == 68 and r.open_economy.retained_earnings[FIRM] == 8 and r.accounts.finn.wages_received == 0 and r.accounts.finn.owner_shifts == 1,
		"B real flour purchase/unpaid owner labor/specified sales retain eight coins; equipment is not an operating loss")
	var unsold = Fixtures.owner_sale(false)
	r = unsold.report()
	suite._check(_verified(unsold.world) and r.final.entities[FIRM].money == 44 and r.final.entities[FIRM].inventory.bread == 6 and r.open_economy.retained_earnings[FIRM] == -16,
		"unsold owner production retains real bread and an operating cash deficit, without invented customers")
	var c = Fixtures.delegation()
	r = c.report()
	suite._check(_verified(c.world) and r.final.entities[FIRM].money == 70 and r.open_economy.retained_earnings[FIRM] == 10 and r.accounts.iona.wages_received == 6
		and r.final.entities.finn.money == 200 and not r.final.affiliations.has("finn") and r.final.affiliations.iona == {"business":FIRM,"kind":"employee"}
		and r.final.businesses[FIRM].owner == "finn", "C public hiring delegates actual productive work while ownership remains with a nonworking Finn")
	suite._check(not c.world.events().any(func(e):return e.action=="contract_due" and e.actor=="iona" and e.target==FIRM),"casual paid work creates no fictional guaranteed shifts")
	_unchanged(suite,c.world,func():return c.world.work_shift("iona",FIRM),"employee cannot collect a second wage for the same day's shift")
	_unchanged(suite,c.world,func():return c.world.owner_work_shift("finn",FIRM),"delegated owner cannot bypass the ended self-employment affiliation")
	c.world.request_resignation("iona",FIRM)
	c.world.advance_day()
	var returned: bool = c.world.start_self_employment("finn",FIRM)
	c.world.purchase(FIRM,"mill","flour",4,4)
	var owner_return: bool = c.world.owner_work_shift("finn",FIRM)
	c.world.close_contract_day()
	suite._check(returned and owner_return and _verified(c.world) and c.world.snapshot().entities.finn.money == 200,"owner may return to legitimate unpaid productive work after authorized employee exit")
	var policy = Fixtures.delegation()
	w = policy.world
	w.set_distribution_policy("finn",FIRM,"half",24)
	var paid: bool = w.settle_profit("finn",FIRM)
	suite._check(paid and w.snapshot().entities[FIRM].money == 65 and w.snapshot().entities.finn.money == 205 and w.profit_budget(FIRM).realized_remaining == 5,"half policy pays only five genuinely earned coins and uses a non-120 reserve")
	w.set_distribution_policy("finn",FIRM,"full",24)
	w.settle_profit("finn",FIRM)
	var count: int = w.events().size()
	w.settle_profit("finn",FIRM)
	suite._check(w.events().size()==count and w.snapshot().entities[FIRM].money == 60 and w.snapshot().cash_results[FIRM].distributions == 10 and _verified(w),"full remaining-earnings payout cannot pay profit twice or extract contributed working capital")
	w.contribute_capital("finn",FIRM,10)
	suite._check(w.profit_budget(FIRM).eligible==0 and _verified(w),"new personal capital after distributions does not replenish distributable earnings")
	var board = Fixtures.startup()
	w = board.world
	w.post_job("finn",FIRM,"job",6,0,3,3)
	var listing: Array = w.job_board("dain")
	suite._check(listing==w.job_board("ada") and not listing[0].has("money") and not listing[0].has("inventory") and w.observe("dain",FIRM).business.is_empty(),"local board is public while firm financial data stays private")
	w.contribute_capital("finn",FIRM,10)
	listing[0].wage=999
	suite._check(w.job_board("dain")[0].wage==6 and not w.observe("dain").offers.any(func(o):return o.seller in ["visitors","equipment_seller"]),"board copies and local offers expose no remote-account finances")
	_unchanged(suite,w,func():return w.apply_for_job("kira","job"),"currently employed skilled worker cannot silently acquire another affiliation")
	w.apply_for_job("iona","job")
	_unchanged(suite,w,func():return w.make_job_offer("bram","job:iona"),"only posting's actual employer may accept an application")
	w.make_job_offer("finn","job:iona")
	_unchanged(suite,w,func():return w.make_job_offer("finn","job:iona"),"a vacancy cannot be reserved twice")
	_unchanged(suite,w,func():return w.accept_job_offer("finn","job:iona"),"only the applicant may accept the prescribed offer")
	w.accept_job_offer("iona","job:iona")
	_unchanged(suite,w,func():return w.work_shift("iona",FIRM),"accepted future job does not pay wages before its defined start boundary")
	var unskilled = Fixtures.startup()
	w = unskilled.world
	w.post_job("finn",FIRM,"skilled",6,0,3,3)
	w.request_resignation("dain","farm")
	w.advance_day()
	_unchanged(suite,w,func():return w.apply_for_job("dain","skilled"),"an uncommitted worker without baking skill cannot apply for productive bakery work")
	var prior = World.new(42,Config.initial(100,true))
	prior.advance_day()
	prior.request_resignation("finn","bakery")
	prior.close_contract_day()
	var breached: Array = prior.events().filter(func(e):return e.action=="contract_shift" and e.actor=="finn")
	prior.advance_day()
	prior.close_contract_day()
	suite._check(breached.size()==1 and not breached[0].success and prior.events().filter(func(e):return e.action=="contract_shift" and e.actor=="finn").size()==1
		and not prior.snapshot().employment.finn.active and _verified(prior),"resignation ceases future old-job obligations while preserving an already-due unfulfilled promise")
	var guarantee = Fixtures.startup()
	w = guarantee.world
	w.post_job("finn",FIRM,"regular",6,2,3,3)
	w.apply_for_job("iona","regular")
	w.make_job_offer("finn","regular:iona")
	w.accept_job_offer("iona","regular:iona")
	w.request_resignation("finn",FIRM)
	w.advance_day()
	w.offer_shift("finn",FIRM,"iona") # Missing actual flour.
	w.close_contract_day()
	var missing: Array = w.events().filter(func(e):return e.action=="contract_shift" and e.target==FIRM)
	suite._check(missing.size()==1 and not missing[0].success and missing[0].details.actual_compensation==0 and missing[0].details.reason=="insufficient_inputs" and _verified(w),"new guaranteed contracts create auditable breaches instead of unpaid fictional work")
	for _index in 3:
		w.advance_day()
		w.close_contract_day()
	suite._check(not w.snapshot().employment.iona.active and not w.snapshot().affiliations.has("iona") and _verified(w),"fixed contract duration ends future work without deleting prior breaches")
	var elsewhere = Fixtures.delegation()
	w = elsewhere.world
	w.post_job("cora","bakery","other",6,0,3,3)
	var may_apply: bool = w.apply_for_job("finn","other")
	w.make_job_offer("cora","other:finn")
	w.accept_job_offer("finn","other:finn")
	w.advance_day()
	w.purchase("bakery","mill","flour",4,4)
	w.offer_shift("cora","bakery","finn")
	var employee_work: bool = w.work_shift("finn","bakery")
	w.close_contract_day()
	suite._check(may_apply and employee_work and w.snapshot().businesses[FIRM].owner=="finn" and w.snapshot().affiliations.finn=={"business":"bakery","kind":"employee"} and _verified(w),"ownership alone does not prevent a valid paid affiliation at another employer")
	_unchanged(suite,w,func():return w.start_self_employment("finn",FIRM),"an employed owner cannot start a second productive affiliation")
	var corrupt: Array = b.world.events()
	for e in corrupt:
		if e.action=="owner_work_shift":
			e.details.wage=6
	suite._check(not Audit.verify(corrupt,b.world.snapshot()).accounting.labor_and_affiliations,"auditor detects invented owner salary without requiring lost currency")
	corrupt=b.world.events()
	for e in corrupt:
		if e.action=="capital_contribution":
			e.details.amount=1
	suite._check(not Audit.verify(corrupt,b.world.snapshot()).accounting.capital_and_earnings,"auditor distinguishes actual capital receipt from false contribution metadata")
	for fixture in [Fixtures.owner_sale(),Fixtures.delegation()]:
		var again = Fixtures.owner_sale() if fixture._case=="B" else Fixtures.delegation()
		suite._check(fixture.world.events()==again.world.events() and fixture.report()==again.report(),"M15 fixture deterministic receipts and report replay")
