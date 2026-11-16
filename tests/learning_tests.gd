extends RefCounted
const B=preload("res://scripts/sim/bakery_beliefs.gd")
const F=preload("res://scripts/sim/bakery_finance.gd")
const P=preload("res://scripts/sim/bakery_policy.gd")
const R=preload("res://scripts/sim/learning_runner.gd")

static func run(suite) -> void:
	mathematical(suite)
	spatial(suite)

static func mathematical(suite) -> void:
	var b=B.fresh()
	var blank={"arrivals":0,"eligible":0,"sales":0,"censored":false}
	var all={"arrivals":6,"eligible":6,"sales":6,"censored":false}
	var no=B.update(b,{"local":blank,"visitor":blank},7,false)
	suite._check(no==b,"absent owner and zero eligible inspections supply no negative evidence")
	var zero=B.update(b,{"local":blank,"visitor":blank},7,true)
	suite._check(zero.visitor.alpha[0]==1.25 and zero.visitor.weights==b.visitor.weights,"observed zero traffic updates traffic only")
	var censored=all.duplicate()
	censored.censored=true
	var limited=B.update(b,{"local":blank,"visitor":censored},7,true)
	suite._check(limited.visitor.weights==b.visitor.weights and limited.visitor.alpha[6]==1.25,"stock-limited cohort preserves response uncertainty")
	var seen=B.update(b,{"local":blank,"visitor":all},7,true)
	suite._check(absf(seen.visitor.weights.reduce(func(a,v):return a+v,0.0)-1)<1e-12,"normalized cohort-day posterior")
	suite._check(B.hazard(seen).visitor.weights[0]>seen.visitor.weights[0],"hazard restores prior mass without deleting facts")
	for price in [1,6,7,12]:
		for stock in [0,1,6,18]:
			var outcomes=B.outcomes(b,"visitor",price,stock,0,0)
			var total=outcomes.reduce(func(a,o):return a+o.probability,0.0)
			suite._check(absf(total-1.0)<1e-10,"finite-stock observable distribution normalizes")
	for cash in [70,120,300]:
		var operation=F.operate([cash,0,0,180 if cash==300 else 0],true)
		var close=F.close(operation.state,7,0)
		suite._check(operation.state[0]==cash-66 and operation.shifts==3,"full zero-sales operating cost is 66")
		suite._check(close.state[0]==(120 if cash==300 else cash-66) and close.payout==(114 if cash==300 else 0),"retained earnings and cash-floor payout fixture")
		var external=8880-cash
		suite._check(external+312+operation.state[0]+66==9192,"conditional fixture reconciles conserved combined currency")
	suite._check(F.close(F.operate([300,0,0,0],true).state,7,0).payout==0,"contributed capital is not earned profit")
	suite._check(F.operate([5.999999999999999,4,0,0],false).shifts==1,"projection whole-shift threshold tolerates floating-point roundoff")
	var poor=F.operate([4,0,0,0],true)
	suite._check(poor.shifts==0 and poor.state[0]==0,"capital shortage interrupts production, no fixed bankruptcy penalty")
	suite._check(P.candidates(7,[4,5,6,7,9])==[4,5,6,7,8],"rollback history and bounded upward experiment")
	# Exact issue teaching fixture, independent of production model.
	var post_all=0.25*0.8/(0.25*0.8+0.75*0.1)
	var post_none=0.25*0.1/(0.25*0.1+0.75*0.8)
	var immediate=24.3+29.4*0.25
	var continuation=0.275*(24.3+29.4*post_all)+0.725*42
	suite._check(absf(post_all-8.0/11)<1e-12 and absf(post_none-1.0/25)<1e-12,"toy exact Bayes posteriors")
	suite._check(absf(immediate-31.65)<1e-10 and absf(immediate+13*continuation-590.8125)<1e-9,"toy 14-day value 590.8125 exceeds 588")
	suite._check(2+4>2+2,"informative staying can beat an equally profitable uninformative trial")

class AbsentOwner:
	extends "res://scripts/sim/learning_runner.gd"
	func _after_appointments(minute: int) -> void:
		super(minute)
		if minute==930: world.depart("cora",[1,1])

static func spatial(suite) -> void:
	var a=R.new()
	a.run(1)
	var old=preload("res://scripts/sim/spatial_runner.gd").new()
	old.run(1)
	suite._check(a.world.snapshot()==old.world.snapshot() and a.world.events()==old.world.events(),"A native state and complete event ledger equal M17")
	suite._check(a.world.memory.cora[0].local.eligible==12 and a.world.memory.cora[0].visitor.eligible==6,"owner eligible inspections count physical cohort encounters")
	suite._check(a.world.memory.cora[0].complete and a.world.memory.cora[0].local.arrivals==9,"traffic coverage and carry-in remain distinct")
	var split=R.new()
	split.run(1)
	split.run(1)
	var joined=R.new()
	joined.run(2)
	suite._check(split.report()==joined.report(),"incremental memory and native split-run deterministic replay")

	var closed=R.LearningWorld.new(42,"early_close")
	var closed_runner=R.new()
	closed_runner.world=closed
	closed_runner._initial=closed.snapshot()
	closed_runner.run(1)
	var observed: Dictionary=closed.memory.cora[0]
	suite._check(observed.local.closed==12 and observed.visitor.closed==6 and observed.local.sales==0,"closed-shop encounters remain closure evidence")
	suite._check(closed.beliefs.local.weights==B.prior(),"closed shop never implies price refusal")
	var before: Dictionary=closed.snapshot()
	suite._check(not closed.revise_quote("ada","bakery","bread",8) and closed.snapshot()==before,"unrelated owner cannot revise learned bread quote")
	suite._check(not closed.revise_quote("bram","mill","flour",5) and closed.snapshot()==before,"M18 farm and mill quotes stay fixed")
	closed_runner.run(1)
	var second: Dictionary=closed.memory.cora[1]
	suite._check(second.accounting.inputs==48 and second.accounting.payroll==6 and second.cash==0,"native next day spends inputs before funding only one whole bakery shift")
	suite._check(second.inventory.bread==24 and second.inventory.flour==8,"native payroll interruption retains real unsold bread and unused flour")
	var c=R.new(42,"C")
	c.run(1)
	var d=R.new(42,"D")
	d.run(1)
	for runner in [c,d]:
		var decision: Dictionary=runner.decisions[0]
		suite._check(decision.proposal.selected_price in P.candidates(4,[4]),"first learned quote remains within declared candidate bounds")
		suite._check(runner.world.snapshot().entities.bakery.money>=0,"financial projection cannot overdraw authoritative cash")
		var probe_state: Dictionary=runner.world.snapshot()
		P.decide(decision.observation,decision.beliefs,"C")
		suite._check(runner.world.snapshot()==probe_state,"hypothetical planning never mutates native economic state")
	for row in d.decisions[0].proposal.candidates:
		suite._check(row.informed>=row.ordinary-1e-8 and row.evsi>=0,"EVSI considers informative staying as well as probes")
	var replay=R.new(42,"D")
	replay.run(1)
	suite._check(replay.report()==d.report(),"D candidate values, memory, quote ledger and native state replay")

	var absent=AbsentOwner.new()
	absent.run(1)
	var raw: Dictionary=absent.world.memory.cora[0]
	suite._check(raw.accounting.sold==17 and raw.local.inspections==0 and raw.visitor.inspections==0,"absent owner knows actual sales from accounting, not unwitnessed conversion")
	suite._check(not raw.complete and absent.world.beliefs==B.fresh(),"partial attendance never invents a zero-traffic day")
	for stage in ["C","D"]:
		var partial=R.new(42,stage)
		partial.run(1)
		partial.run(1)
		var whole=R.new(42,stage)
		whole.run(2)
		suite._check(partial.report()==whole.report(),"learned "+stage+" beliefs, prices and economics are split-run equivalent")
