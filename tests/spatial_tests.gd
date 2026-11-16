extends RefCounted
const Runner=preload("res://scripts/sim/spatial_runner.gd")
const World=preload("res://scripts/sim/spatial_world.gd")
const Audit=preload("res://scripts/sim/spatial_audit.gd")
const Historical=preload("res://scripts/sim/external_trade_runner.gd")
const Pricing=preload("res://scripts/sim/pricing_runner.gd")


static func unchanged(suite,w,call: Callable,label: String) -> void:
	var before: Dictionary=w.snapshot()
	var result: bool=call.call()
	suite._check(not result and w.snapshot()==before,label)


static func verified(w) -> bool:
	var v: Dictionary=Audit.verify(w.events(),w.snapshot())
	return v.accounting.values().all(func(x):return x) and v.spatial.values().all(func(x):return x)


static func quote(w, seller: String="bakery") -> Dictionary:
	return w.public_quotes().filter(func(q):return q.seller==seller)[0]


static func farm_ready() -> RefCounted:
	var w=World.new()
	w.advance_day()
	w.advance_time(480)
	for id in ["ada","bram","dain","edda","gale"]: w.depart(id,[6,1])
	w.depart("hale",[6,3])
	w.advance_time(540)
	for id in ["dain","edda","gale"]: w.start_shift(id,"farm")
	return w


static func run(suite) -> void:
	for days in [1,3,30]:
		var first=Runner.new()
		var split=Runner.new()
		first.run(days)
		var portion: int=3 if days==30 else 1
		split.run(portion)
		split.run(days-portion)
		var r: Dictionary=first.report()
		suite._check(r.profitable.verification.accounting.values().all(func(x):return x) and r.profitable.verification.spatial.values().all(func(x):return x),"M17 %dd every-event economic/custody/space/time/physical witness reconstruction"%days)
		suite._check(first.world.events()==split.world.events() and r==split.report() and first.world.snapshot()==split.world.snapshot(),"M17 %dd exact split state, ledger, compact report and timestamp replay"%days)
		var previous=Historical.new()
		previous.run(days)
		var old: Dictionary=previous.report()
		var state: Dictionary=r.final.duplicate(true)
		for key in ["spatial","cargo","commodity_quotes","market_bought"]: state.erase(key)
		suite._check(state==old.final and r.initial.entities==old.initial.entities and r.accounts==old.accounts and r.totals==old.totals and r.money==old.money and r.shifts==old.shifts and r.purchases==old.purchases and r.profitable.contracts==old.profitable.contracts,
			"M17 actual final economic state and all accounts, purchases, meals, currency, production and paid/minimum shifts match M15")
		var pricing=Pricing.new(42,"A")
		pricing.run(days)
		var control: Dictionary=pricing.report()
		suite._check(r.accounts==control.accounts and r.totals==control.totals and r.money==control.money and r.profitable.cash_results==control.profitable.cash_results and r.unmet_meals==control.unmet_meals,
			"M17 fixed spatial control matches M16 A's actual financial and commodity outcomes")
		suite._check(r.spatial.days.size()==days and r.spatial.days.all(func(d):return d.steps==220 and d.cargo_purchased==24 and d.cargo_deposited==24 and d.visitor_entries==6 and d.visitor_exits==6 and d.paid_shifts==9 and d.resident_meals==12 and d.breaches==0),"M17 daily movement, transit, genuine visitor requests, meals and nine paid shifts")
		var people: Dictionary=r.final.spatial.presences
		suite._check(first.participant_ids().all(func(id):return people[id].tile==people[id].home and people[id].activity=="idle" and people[id].route.is_empty()) and r.final.cargo.values().all(func(p):return p.inventory.values().all(func(q):return q==0)),"M17 all residents return home by real routes; no outstanding cargo at control closure")
		var visitors: Array=people.values().filter(func(p):return p.kind=="visitor")
		suite._check(visitors.size()==days*6 and visitors.all(func(p):return not p.active and p.tile==[9,3] and p.loaf==0 and p.purchased and p.account=="visitors" and not p.has("money")) and r.final.entities.size()==16,
			"M17 six separate temporary visitors per day share one unchanged account and exit at gate without personal money")
		print("M17 control days=%d meals=%d visitors=%d shifts=%d money=%d steps=%d"%[days,r.open_economy.resident_meals,r.open_economy.visitor_bread,r.shifts.paid,r.money.final,days*220])
	var w=World.new()
	var initial: Dictionary=w.snapshot()
	var ids: Array=initial.spatial.presences.keys()
	ids.sort()
	var homes: bool=true
	for index in ids.size():
		@warning_ignore("integer_division")
		homes=homes and initial.spatial.presences[ids[index]].home==[1,1+2*(index/4)]
	suite._check(homes and initial.spatial.width==10 and initial.spatial.height==7,"M17 exact map/housing assignment by sorted stable resident IDs")
	w.advance_day()
	var before_day: Dictionary=w.snapshot()
	w.advance_day()
	suite._check(w.snapshot()==before_day,"day advance cannot reset an unfinished spatial clock or erase actual appointments")
	unchanged(suite,w,func():return w.purchase_quote("ada",quote(w),1),"remote quoted purchase cannot move goods or money")
	unchanged(suite,w,func():return w.work_shift("dain","farm"),"remote and instantaneous paid work cannot bypass actual shift duration")
	unchanged(suite,w,func():return w.owner_work_shift("ada","farm"),"inherited owner-production entry point cannot bypass fixed on-site employee shifts")
	unchanged(suite,w,func():return w.consume("visitors"),"shared external account is not a permanent household with a remote meal need")
	unchanged(suite,w,func():return w.procure("ada","mill","farm","wheat"),"unrelated owner cannot act as a business-funded courier")
	for tile in [[-1,1],[10,1],[1,7],[1.0,2],["1",2],[true,2],[1],[1,2,3]]:
		unchanged(suite,w,func():return w.depart("ada",tile),"malformed or out-of-grid destinations reject atomically")
	unchanged(suite,w,func():return w.depart("ada",[9,6],5),"insufficient commute time does not teleport a resident")
	for target in [-5,3,5.0,true,1445]:
		unchanged(suite,w,func():return w.advance_time(target),"invalid spatial clock targets leave the complete state unchanged")
	w.advance_time(480)
	w.depart("ada",[6,1])
	unchanged(suite,w,func():return w.move_step("ada",[2,1]),"departure cannot spend a movement step before five minutes elapse")
	unchanged(suite,w,func():return w.move_step("ada",[2,2]),"diagonal or contradictory route step cannot change position")
	w.advance_time(505)
	suite._check(w.snapshot().spatial.presences.ada.tile==[6,1] and w.events().filter(func(e):return e.action=="spatial_moved" and e.success and e.actor=="ada").size()==5,"orthogonal commute covers five real tiles in twenty-five simulated minutes")
	unchanged(suite,w,func():return w.advance_time(500),"clock cannot move backwards")
	w=farm_ready()
	unchanged(suite,w,func():return w.depart("dain",[8,3]),"working resident cannot commute to another place simultaneously")
	unchanged(suite,w,func():return w.start_shift("dain","farm"),"worker cannot book simultaneous appointments")
	unchanged(suite,w,func():return w.work_shift("dain","farm"),"starting a shift does not award wages or output before completion")
	w.advance_time(600)
	w.advance_time(610)
	var purchase: bool=w.procure("bram","mill","farm","wheat")
	var state: Dictionary=w.snapshot()
	suite._check(purchase and state.cargo.mill.inventory.wheat==12 and state.entities.mill.inventory.wheat==0 and state.entities.bram.inventory.wheat==0 and state.entities.mill.money==96,"business pays for actual wheat held only in authorized courier custody, never private or warehouse inventory")
	unchanged(suite,w,func():return w.deposit("bram","mill"),"cargo cannot be remotely deposited or used while courier remains at seller")
	w.advance_time(615)
	w.advance_time(660)
	unchanged(suite,w,func():return w.start_shift("hale","mill"),"production cannot spend undelivered in-transit business inputs")
	w.depart("bram",[6,3])
	w.advance_time(670)
	var deposited: bool=w.deposit("bram","mill")
	suite._check(deposited and w.snapshot().entities.mill.inventory.wheat==12 and w.snapshot().cargo.mill.inventory.wheat==0,"real courier arrival deposits existing goods exactly once without another payment")
	w.advance_time(675)
	unchanged(suite,w,func():return w.deposit("bram","mill"),"a consumed cargo manifest cannot be deposited twice")
	suite._check(verified(w),"partial-day transit, failed dependent shift and delivery remain independently auditable")
	w=World.new()
	w.advance_day()
	w.advance_time(480)
	w.depart("ada",[8,3])
	w.depart("cora",[8,3])
	w.advance_time(900)
	w.depart("cora",[1,1])
	w.advance_time(960)
	var before: Dictionary=w.snapshot()
	var offsite: Dictionary=w.inspect_offers("bram","bakery")
	suite._check(not offsite.success and offsite.offers.is_empty() and w.snapshot()==before,"off-site inspection reveals no offers and changes no authoritative facts")
	var witnessed: int=w.witnessed_encounters("cora").size()
	w.shop("ada")
	suite._check(w.witnessed_encounters("cora").size()==witnessed and w.observe("cora").offers.is_empty(),"off-site Cora cannot witness a remote customer's inspection or decline")
	w.advance_time(1040)
	unchanged(suite,w,func():return w.shop("ada"),"resident arriving or shopping after closure cannot purchase")
	unchanged(suite,w,func():return w.purchase_quote("ada",quote(w),1),"direct purchase cannot bypass closed-shop authority")
	w=World.new()
	w.advance_day()
	w.advance_time(480)
	w.depart("cora",[8,3])
	w.advance_time(1020)
	w.enter_visitor(1)
	var id: String="visitor:0001:1"
	unchanged(suite,w,func():return w.enter_visitor(1),"one visitor request cannot enter twice")
	unchanged(suite,w,func():return w.enter_visitor(7),"unadvertised extra visitors cannot create extra daily demand")
	w.exit_visitor(id)
	suite._check(not w.events().any(func(e):return e.action=="spatial_encounter" and e.actor==id and e.target=="bakery"),"visitor who leaves at gate and never arrives produces no fabricated bakery encounter")
	w.enter_visitor(2)
	w.depart("visitor:0001:2",[8,3])
	w.advance_time(1025)
	w.shop("visitor:0001:2")
	var observations: Array=w.witnessed_encounters("cora")
	suite._check(observations.any(func(o):return o.presence=="visitor:0001:2" and o.kind=="declined") and observations.all(func(o):return not o.has("money") and not o.has("ceiling") and not o.has("reason") and not o.has("balance")),"co-located Cora can witness actual arrival/inspection/no-purchase without private funds, reservation price or hidden reasons")
	suite._check(verified(w),"never-arrival and visibly declining visitor observations reconstruct correctly")
	for name in ["late_worker","early_close"]:
		var s=Runner.new(42,name)
		s.run(1)
		var r: Dictionary=s.report()
		suite._check(verified(s.world) and r.money.final==9192,"spatial disruption "+name+" preserves every money/goods/custody/location invariant")
		if name=="late_worker":
			suite._check(r.shifts.paid==6 and r.profitable.contracts.breaches==3 and r.open_economy.resident_meals==12 and r.open_economy.visitor_bread==0 and r.totals.harvested.wheat==8,"late Dain loses his real shift, dependent flour/bread work and visitor sales without replacement or fabricated inputs")
		else:
			suite._check(r.shifts.paid==9 and r.profitable.contracts.breaches==0 and r.open_economy.resident_meals==0 and r.open_economy.visitor_bread==0 and r.final.entities.bakery.inventory.bread==18 and r.spatial.days[0].closed_attempts==18,"early closing preserves produced unsold bread and actual missed meals instead of remote sales")
	var s=Runner.new()
	s.run(1)
	var arrivals: Array=s.world.events().filter(func(e):return e.action=="spatial_arrived" and e.actor.begins_with("visitor:") and e.minute==1025)
	suite._check(arrivals.map(func(e):return e.actor)==["visitor:0001:1","visitor:0001:2","visitor:0001:3","visitor:0001:4","visitor:0001:5","visitor:0001:6"],"simultaneous visitor arrivals serialize deterministically by stable presence ID")
	var shops: Array=s.world.events().filter(func(e):return e.action=="spatial_encounter" and e.details.kind=="inspected" and e.target=="bakery" and e.minute==960)
	suite._check(shops.map(func(e):return e.actor)==s.participant_ids(),"resident shopping order stays deterministic and separately recorded")
	var corrupt: Array=s.world.events()
	for e in corrupt:
		if e.action=="spatial_moved":
			e.details.to=[9,6]
			break
	suite._check(not Audit.verify(corrupt,s.world.snapshot()).spatial.movement_and_arrivals,"independent spatial audit rejects teleportation in a forged movement receipt")
	corrupt=s.world.events()
	for e in corrupt:
		if e.action=="spatial_encounter" and "cora" not in e.details.witnesses:
			e.details.witnesses.append("cora")
			break
	suite._check(not Audit.verify(corrupt,s.world.snapshot()).spatial.witness_boundaries,"independent audit rejects fabricated off-site witnesses")
	corrupt=s.world.events()
	for e in corrupt:
		if e.action=="spatial_deposited":
			e.details.goods.wheat+=1
			break
	var bad_cargo: Dictionary=Audit.verify(corrupt,s.world.snapshot())
	suite._check(not bad_cargo.accounting.goods_and_assets and not bad_cargo.spatial.courier_custody,"independent commodity audit rejects a duplicated cargo unit through nonnegative custody and bounded holdings")
