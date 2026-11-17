extends RefCounted
const Runner=preload("res://scripts/sim/brewery_runner.gd")
const Brew=preload("res://scripts/sim/brewery_config.gd")
const Policy=preload("res://scripts/sim/brewery_policy.gd")
static func held(grain: int, mill_cash: int=120) -> RefCounted:
	var initial: Dictionary=Brew.initial()
	for e in initial.entities:
		if e.id=="farm":e.inventory.wheat=grain
		if e.id=="mill":e.money=mill_cash
		if e.id=="visitors":e.money+=120-mill_cash
	var r=Runner.new(42,"reference",initial)
	r.world.advance_day();r.appointment(480);r.world.advance_time(610)
	return r
static func run(t: SceneTree) -> void:
	for pair in [[21,3,2],[19,3,1],[16,2,2]]:
		var results: Array=[]
		for order in [["mill","brewery"],["brewery","mill"]]:
			var r=held(pair[0]);var w=r.world
			for f in order:w.propose_grain(Brew.OWNERS[f],f)
			t._check(w.clear_grain("ada"),"on-site common-price clearing executes")
			var d: Dictionary=w.events().back().details
			t._check(d.allocation.mill==pair[1] and d.allocation.brewery==pair[2],"seller maximizes paid whole-lot grain receipts")
			results.append({"cargo":w.snapshot().cargo,"entities":w.snapshot().entities,"allocation":d.allocation})
		t._check(results[0]==results[1],"allocation and actual economic state independent of submission order")
	var empty=held(21);var w=empty.world
	w.clear_grain("ada")
	t._check(w._entities.farm.inventory.wheat==21,"zero demand does not fabricate sales")
	var zero=held(21,0);zero.world.propose_grain("bram","mill");zero.world.propose_grain("mara","brewery");zero.world.clear_grain("ada")
	t._check(zero.world._cargo.mill.inventory.wheat==0 and zero.world._cargo.brewery.inventory.wheat==6,"cashless mill cannot displace funded brewery")
	var poor=held(21,20);poor.world.propose_grain("bram","mill");poor.world.propose_grain("mara","brewery");poor.world.clear_grain("ada")
	t._check(poor.world._cargo.mill.inventory.wheat==5 and poor.world._entities.mill.money==10,"procurement retains actual payroll for affordable lots")
	var invalid=held(21);w=invalid.world
	var q: Dictionary=w.inspect_offers("bram","farm").offers[0]
	var before: Dictionary=w.snapshot().entities
	t._check(not w.request_grain("bram","mill",1.5,q) and w.snapshot().entities==before,"fractional whole-lot request rejects atomically")
	var stale: Dictionary=q.duplicate();stale.version+=1
	t._check(not w.request_grain("bram","mill",3,stale),"stale/unobserved request quote rejects")
	w.request_grain("bram","mill",3,q);w.propose_grain("mara","brewery")
	w.depart("hale",w._space.presences.hale.home)
	w.clear_grain("ada")
	t._check(w.events().back().details.eligible.mill==2,"changed worker presence revalidates request capacity")
	t._check(not w.clear_grain("ada"),"duplicate clearing cannot deliver twice")
	var changed=held(21);w=changed.world
	w.propose_grain("bram","mill");w.propose_grain("mara","brewery")
	w._revise_market_quote("ada","farm","wheat",3)
	w.clear_grain("ada")
	t._check(w._cargo.mill.inventory.wheat==0 and w._cargo.brewery.inventory.wheat==0,"real quote revision after request invalidates both old quotes")
	var shortage=held(21);w=shortage.world
	w.propose_grain("bram","mill");w.propose_grain("mara","brewery")
	# Controlled fault fixture, not an auditable simulated removal or a harvest mandate.
	w._entities.farm.inventory.wheat=16
	w.clear_grain("ada")
	t._check(w._cargo.mill.inventory.wheat==10 and w._cargo.brewery.inventory.wheat==6,"advisory old stock is not an inventory reservation")
	var base=Runner.new();base.run(1);var report: Dictionary=base.report()
	t._check(report.totals.produced=={"wheat":21,"flour":15,"bread":21,"ale":12} and report.day_results[0].resident_meals==15,"funded reference witness executes real recipes and meals")
	t._check(report.purchases.rejected==0 and report.money.final==9192 and report.day_results[0].ale_consumed==12,"four-item accounting and discretionary sink")
	t._check(report.accounts.visitors.ale_spending==4 and report.day_results[0].firms.brewery.operating_surplus==16,"visitor combined budget and realized brewery income")
	var split=Runner.new();split.run(1);split.run(2);var continuous=Runner.new();continuous.run(3)
	t._check(split.report()==continuous.report() and split.world.events()==continuous.world.events(),"split replay preserves complete decisions and native events")
	var disabled=Runner.new(42,"no_brew_request");disabled.run(1)
	t._check(disabled.report().totals.produced.ale==0 and disabled.report().day_results[0].shifts==9,"matched no-request control has no free brewery production/payroll")
	var cash=Brew.initial()
	for e in cash.entities:
		if e.id=="bakery":e.money=20
		if e.id=="visitors":e.money+=100
	var constrained=Runner.new(42,"reference",cash);constrained.run(1)
	t._check(constrained.report().totals.produced.bread==0 and constrained.report().day_results[0].unmet_meals==15,"cash-short bakery cannot spend future customer revenue")
	var privacy=held(21);w=privacy.world
	w.inspect_offers("bram","farm")
	var observed: Dictionary=w.business_observation("bram","mill",true)
	w._entities.visitors.money-=1;w._entities.bakery.money+=1
	t._check(observed==w.business_observation("bram","mill",true),"owner plan excludes private consumer and unrelated business finances")
	for wheat_price in [2,3,4]:
		var o: Dictionary=observed.duplicate(true);o.input_price=wheat_price
		var p: Dictionary=Policy.plan(o)
		t._check(p.lots==(3 if wheat_price==2 else 0),"mill declines zero/negative conditional contribution")
	w.inspect_offers("mara","farm")
	var brewing: Dictionary=w.business_observation("mara","brewery",true)
	brewing.input_price=4
	var positive: Dictionary=Policy.plan(brewing)
	t._check(positive.lots==2 and positive.expected_receipts-positive.committed_cash==4,"two brewery batches at wheat4/ale4 contribute two coins each")
	brewing.output_price=3
	t._check(Policy.plan(brewing).lots==0,"brewery declines negative wheat4/ale3 contribution")
	var consumer={"money":10,"need_bread":1,"need_ale":1,"bread_ceiling":6,"prices":{"bread":6,"ale":4},"stock":{"bread":1,"ale":1}}
	t._check(Policy.basket(consumer).bread==1 and Policy.basket(consumer).ale==1,"affordable essential plus discretionary basket")
	consumer.money=6
	t._check(Policy.basket(consumer).bread==1 and Policy.basket(consumer).ale==0,"essential food dominates discretionary ale")
	consumer.money=11;consumer.prices.ale=5
	t._check(Policy.basket(consumer).ale==0,"ale utility tie retains cash")
	consumer.prices.ale=3
	t._check(Policy.basket(consumer).ale==1,"lower ale price has positive marginal utility")
	consumer.stock.ale=0
	t._check(Policy.basket(consumer).ale==0,"unavailable ale cannot enter feasible basket")
	# Actual authority allowance, not just policy suppression.
	var allowance=Runner.new();allowance.world.advance_day()
	for minute in Runner.TIMES:
		if minute>975:break
		allowance.appointment(minute)
	w=allowance.world;var old_inventory: Dictionary=w._entities.dain.duplicate(true)
	w._shopper="dain";q=w._seen["dain:brewery"].offers[0]
	t._check(not w.purchase_quote("dain",q,1) and old_inventory==w._entities.dain,"duplicate daily ale purchase rejects without partial balance change")
	w._shopper=""
	var visit=Runner.new()
	visit.world._revise_market_quote("mara","brewery","ale",5) # Isolated price fixture, never a longitudinal preset.
	visit.world.advance_day()
	for minute in Runner.TIMES:
		if minute>1040:break
		visit.appointment(minute)
	w=visit.world
	var visitor: String="visitor:0001:1"
	t._check(w._space.presences[visitor].spent==6 and w._space.presences[visitor].bought.ale==0,"visitor rationally retains cash at ale5 after bread6")
	before=w.snapshot().entities
	w._shopper=visitor;q=w._seen[visitor+":brewery"].offers[0]
	t._check(not w.purchase_quote("visitors",q,1) and w.events().back().details.reason=="visitor_budget_exhausted" and w.snapshot().entities==before,"authority enforces one combined ten-coin visitor allowance")
	w._shopper=""
	t._check(not w.purchase_quote("visitors",q,1) and w.snapshot().entities==before,"finite visitor account cannot shop without its physical body")
	t._check(not w._items().has("iron") and not preload("res://scripts/sim/world_state.gd").ITEMS.has("ale"),"historical static commodity registry remains three items")
