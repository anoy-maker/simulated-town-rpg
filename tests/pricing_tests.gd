extends RefCounted
const Fixtures=preload("res://scripts/sim/pricing_fixtures.gd")
const Runner=preload("res://scripts/sim/pricing_runner.gd")
const World=preload("res://scripts/sim/pricing_world.gd")
const Config=preload("res://scripts/sim/enterprise_config.gd")
const Buyer=preload("res://scripts/sim/buyer_policy.gd")
const Seller=preload("res://scripts/sim/pricing_policy.gd")
const Audit=preload("res://scripts/sim/pricing_audit.gd")
const Historical=preload("res://scripts/sim/external_trade_runner.gd")


class RaceWorld extends World:
	var interleave: bool = true
	func purchase_quote(buyer: String, q: Variant, quantity: Variant) -> bool:
		if buyer=="ada" and interleave:
			interleave=false
			super.purchase_quote("bram",q,1)
		return super.purchase_quote(buyer,q,quantity)


static func fixture(cash: int=4, stock: int=1) -> Dictionary:
	return Fixtures.initial(cash,stock)


static func ready(w, a: int=3, b: int=5) -> void:
	w.advance_day()
	w.revise_quote("cora","bakery","bread",a)
	w.revise_quote("finn","rival","bread",b)


static func q(w, seller: String, item: String="bread") -> Dictionary:
	return w.public_quotes().filter(func(o):return o.seller==seller and o.item==item)[0]


static func unchanged(suite,w,call: Callable,label: String) -> void:
	var before: Dictionary=w.snapshot()
	var success: bool=call.call()
	suite._check(not success and w.snapshot()==before,label)


static func valid(r: Dictionary) -> bool:
	var v: Dictionary=r.profitable.verification
	return v.accounting.values().all(func(x):return x) and v.pricing.values().all(func(x):return x) and r.pricing.report_reconciles


static func run(suite) -> void:
	for stage in Runner.ENABLED:
		for days in [3,30]:
			var s=Runner.new(42,stage)
			var split=Runner.new(42,stage)
			s.run(days)
			split.run(1)
			split.run(days-1)
			var r: Dictionary=s.report()
			suite._check(valid(r) and r.money.final==9192,"M16 "+stage+" %dd every-event money/goods/assets/labor/contracts/quotes/observations/decisions audit"%days)
			suite._check(r==split.report() and s.world.events()==split.world.events() and s.world.snapshot()==split.world.snapshot(),"M16 "+stage+" %dd split state/ledger/report replay"%days)
			suite._check(r.pricing.business_days.size()==days*3 and r.pricing.days.size()==days,"M16 daily business/household reporting covers every period")
			if stage=="A":
				var baseline=Historical.new(42)
				baseline.run(days)
				var old: Dictionary=baseline.report()
				var state: Dictionary=r.final.duplicate(true)
				state.erase("commodity_quotes")
				state.erase("market_bought")
				suite._check(state==old.final and r.accounts==old.accounts and r.totals==old.totals and r.money==old.money and r.shifts==old.shifts and r.profitable.contracts==old.profitable.contracts,"M16 fixed market reproduces M15 actual economic state, accounts, food, production, circulation and minimum duties")
	var w=World.new(42,fixture())
	ready(w)
	var first: int=w.buy_from_market("ada","bread",1)
	var second: int=w.buy_from_market("bram","bread",1)
	suite._check(first==1 and second==1 and w.snapshot().entities.ada.money==1 and w.snapshot().entities.bram.money==1 and w.snapshot().entities.bakery.money==123 and w.snapshot().entities.rival.money==5,"different posted prices allocate actual finite stock to two independently purchasing affordable buyers")
	unchanged(suite,w,func():return w.purchase_quote("ada",q(w,"rival"),1),"empty seller cannot fabricate a daily replacement loaf")
	var reverse=World.new(42,fixture())
	ready(reverse)
	reverse.buy_from_market("bram","bread",1)
	var poor: int=reverse.buy_from_market("ada","bread",1)
	suite._check(poor==0 and reverse.snapshot().entities.bram.money==3 and reverse.snapshot().entities.ada.money==4 and reverse.snapshot().entities.rival.inventory.bread==1,"reversed buyer order legitimately excludes poorer buyer; no guaranteed seller assignment")
	var tie=World.new(42,fixture(10,4))
	ready(tie,3,3)
	tie.buy_from_market("ada","bread",1)
	var selected: String=tie.events().filter(func(e):return e.action=="purchase" and e.success).back().target
	tie.consume("ada")
	tie.advance_day()
	tie.buy_from_market("ada","bread",1)
	var next: String=tie.events().filter(func(e):return e.action=="purchase" and e.success).back().target
	suite._check(selected!=next,"equal-price tie rotates by buyer Unicode identity and day, without permanently favoring lowest seller ID")
	var race=RaceWorld.new(42,fixture(6))
	ready(race)
	var retried: int=race.buy_from_market("ada","bread",1)
	var race_audit: Dictionary=Audit.verify(race.events(),race.snapshot())
	suite._check(retried==1 and race.snapshot().entities.ada.money==1 and race.snapshot().entities.bram.money==3 and race.events().any(func(e):return e.action=="purchase" and not e.success and e.details.reason=="insufficient_stock")
		and race_audit.accounting.values().all(func(v):return v) and race_audit.pricing.values().all(func(v):return v),"stock changes after selection cause an audited real rejection, then buyer reconsiders the remaining legitimate offer")
	w=World.new(42,fixture())
	w.advance_day()
	var stale: Dictionary=q(w,"bakery")
	w.revise_quote("cora","bakery","bread",3)
	unchanged(suite,w,func():return w.purchase_quote("ada",stale,1),"obsolete quote rejected before economic mutation")
	suite._check(w.buy_from_market("ada","bread",1)==1 and w.snapshot().entities.ada.money==1,"buyer refreshes an obsolete observation from the current public quotes")
	var forged: Dictionary=q(w,"bakery")
	forged.unit_price=1
	unchanged(suite,w,func():return w.purchase_quote("ada",forged,1),"forged cheap price cannot determine execution amount")
	unchanged(suite,w,func():return w.purchase("ada","bakery","bread",1,1),"legacy buyer-supplied price path is disabled only in M16")
	unchanged(suite,w,func():return w.revise_quote("bram","rival","bread",1),"unrelated actor cannot control seller prices")
	unchanged(suite,w,func():return w.revise_quote("cora","bakery","bread",2),"one revision per seller/item/day is enforced")
	w.revise_quote("finn","rival","bread",5,true,100)
	var advertised: Dictionary=q(w,"rival")
	advertised.available=100
	unchanged(suite,w,func():return w.purchase_quote("visitors",advertised,2),"advertised availability cannot replace actual inventory")
	var money=World.new(42,fixture(4,2))
	ready(money)
	unchanged(suite,money,func():return money.purchase_quote("ada",q(money,"rival"),1),"insufficient funds reject current legitimate quotes atomically")
	unchanged(suite,money,func():return money.purchase_quote("bram",q(money,"bakery"),2),"one essential daily bread requirement rejects excess purchase quantity")
	money.buy_from_market("ada","bread",1)
	money.consume("ada")
	suite._check(money.buy_from_market("ada","bread",1)==0,"consumed food cannot create a second daily purchase requirement")
	var bounds=World.new(42,fixture())
	for price in [0,-1,true,1.5,"4",1000000001,9223372036854775807]:
		unchanged(suite,bounds,func():return bounds.revise_quote("cora","bakery","bread",price),"invalid or unsafe price rejects without mutating quote or accounts")
	var high_config: Dictionary=fixture()
	for entity in high_config.entities:
		if entity.id=="farm": entity.inventory.wheat=10
	var high=World.new(42,high_config)
	high.revise_quote("ada","farm","wheat",1000000000)
	unchanged(suite,high,func():return high.purchase_quote("mill",q(high,"farm","wheat"),2),"safe maximum unit price still rejects overflowing transaction totals")
	high.revise_quote("bram","mill","bread",7)
	suite._check(q(high,"mill","bread").unit_price==7 and q(high,"mill","flour").unit_price==4,"business offer authority is generic across existing commodities")
	var visitor=World.new(42,fixture(6,10))
	ready(visitor,7,7)
	suite._check(visitor.buy_from_market("visitors","bread",1)==0 and visitor.snapshot().entities.visitors.money==8760,"private visitor reservation price refuses costly goods despite sufficient cash")
	unchanged(suite,visitor,func():return visitor.purchase_quote("visitors",q(visitor,"bakery"),1),"authoritative visitor ceiling cannot be bypassed by a direct purchase proposal")
	var demand=World.new(42,fixture(6,10))
	ready(demand,4,4)
	suite._check(demand.buy_from_market("visitors","bread",6)==6,"finite visitor budget funds only actual requested goods")
	unchanged(suite,demand,func():return demand.purchase_quote("visitors",q(demand,"bakery"),1),"visitor cannot exceed its specified six-loaf daily demand even with more money and stock")
	var inputs_config: Dictionary=fixture()
	for entity in inputs_config.entities:
		if entity.id=="farm": entity.inventory.wheat=4
		if entity.id=="rival":
			entity.money=20
			entity.role="miller"
	inputs_config.businesses.rival.industry="miller"
	inputs_config.businesses.rival.owner="edda"
	inputs_config.businesses.rival.output_target=16
	var inputs=World.new(42,inputs_config)
	inputs.advance_day()
	var one: int=inputs.buy_from_market("mill","wheat",4)
	var two: int=inputs.buy_from_market("rival","wheat",4)
	suite._check(one==4 and two==0 and inputs.snapshot().entities.farm.inventory.wheat==0 and inputs.snapshot().entities.rival.money==20,"two funded millers compete for finite wheat through the same generic quote authority")
	var o={"current_price":4,"reference_price":4,"reference_demand":18,"sensitivity":1,"available":30,"planned_inputs":48,"planned_payroll":18}
	for demands in [[18,18,12],[25,15,10],[10,15,18]]:
		var beliefs={"demand_by_price":{"3":demands[0],"4":demands[1],"5":demands[2]}}
		var expected: int=4 if demands[0]==18 else 3 if demands[0]==25 else 5
		var proposal: Dictionary=Seller.decide(o,"rational_pricing",beliefs)
		suite._check(proposal.selected_price==expected and proposal==Seller.decide(o,"rational_pricing",beliefs),"explicit private demand beliefs select the correct profit-maximizing price deterministically")
	var tied: Dictionary=Seller.decide(o,"rational_pricing",{"demand_by_price":{"3":20,"4":15,"5":12}})
	suite._check(tied.selected_price==4,"equal expected operating cash prefers the current price")
	suite._check(Seller.decide(o,"rational_pricing",{"demand_by_price":{"3":20,"4":10,"5":12}}).selected_price==3,"noncurrent tied maximizers prefer the lower price")
	o.reference_demand=0
	o.current_price=1
	o.reference_price=1
	suite._check(Seller.decide(o).selected_price==1 and Seller.decide(o,"fixed").candidates.size()==1 and Seller.decide(o,"personality").selected_price==null,"price floor, fixed mode and reserved personality interface do not fabricate adaptive behavior")
	var hidden_config: Dictionary=Config.initial()
	for entity in hidden_config.entities:
		if entity.id in ["dain","visitors"]: entity.money=99
		if entity.id=="farm": entity.inventory.flour=99
	var hidden=World.new(42,hidden_config)
	var plain=World.new(42)
	hidden.advance_day()
	plain.advance_day()
	var left: Dictionary=hidden.pricing_observation("cora","bakery")
	var right: Dictionary=plain.pricing_observation("cora","bakery")
	suite._check(left==right and Seller.decide(left)==Seller.decide(right),"hidden customer money and unoffered competitor inventory cannot influence the owner's immediate decision")
	var public: Array=hidden.observe("dain").offers
	suite._check(public.all(func(offer):return not offer.has("money") and not offer.has("inventory") and not offer.has("profit")) and hidden.observe("dain","bakery").business.is_empty(),"public commodity quotes expose listed stock but no unrelated private financial information")
	public[0].unit_price=999
	suite._check(hidden.public_quotes()[0].unit_price==4,"public quote observations are copies")
	var s=Runner.new(42,"B")
	s.run(3)
	var corrupted: Array=s.world.events()
	for e in corrupted:
		if e.action=="pricing_decision" and e.target=="bakery": e.details.proposal.selected_price=1
	suite._check(not Audit.verify(corrupted,s.world.snapshot()).pricing.candidate_objective,"independent objective audit rejects a nonmaximizing claimed decision")
