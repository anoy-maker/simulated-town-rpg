extends RefCounted
## M18's original unoptimized calculation is an arithmetic-order oracle, not a new policy.
const F=preload("res://scripts/sim/bakery_finance.gd")
const P=preload("res://scripts/sim/bakery_policy.gd")
const B=preload("res://scripts/sim/bakery_beliefs.gd")
const Profile=preload("res://scripts/sim/execution_profile.gd")

static func original(state: Array, price: int, forecasts: Array, supply: int) -> float:
	var first=F.operate(state,true,supply)
	var totals: Array=[]
	totals.resize(mini(24,int(first.state[2]))+1)
	totals.fill(0.0)
	for quantity in forecasts[0].size(): totals[mini(quantity,int(first.state[2]))]+=forecasts[0][quantity]
	var value=0.0
	for sold in totals.size():
		if totals[sold]<0.000000000001: continue
		var result=F.close(first.state,price,sold)
		var branch: float=result.payout
		var s: Array=result.state
		var discount=0.99
		for t in range(1,13):
			var operation=F.operate(s,true,supply)
			result=F.close(operation.state,price,F.mean_sales(forecasts[t],operation.state[2]))
			branch+=discount*result.payout
			s=result.state
			discount*=0.99
		branch+=pow(0.99,12)*s[0]
		value+=totals[sold]*branch
	return value

static func run(suite) -> void:
	var matrix=P.forecasts(B.fresh(),[1,6,12],3)
	var states: Array=[[4,0,0,-116],[54,12,0,-48],[120,0,24,0],[300,16,23.999999999,180],[120,0,24.000000001,0],[120,12,100,0]]
	var identical=true
	for price in [1,6,12]:
		for state in states:
			for supply in [0,12]:
				identical=identical and F.continuation(state,price,matrix[price],supply)==original(state,price,matrix[price],supply)
	suite._check(identical,"36 cash/input/price/stock cases match M18 arithmetic exactly, not merely within tolerance")
	var row: Array=[]
	row.resize(25)
	row.fill(0.0)
	row[0]=0.5
	row[24]=0.5
	var expected: float=F.mean_sales(row,24)
	suite._check(F.mean_sales(row,24.000000001)==expected and F.mean_sales(row,100)==expected,"nonbinding stock has the identical support-bound expectation")
	suite._check(F.mean_sales(row,23.999999999)!=expected,"stock just below support remains stock-limited")
	var state: Array=[120,12,100,0]
	var before_state=state.duplicate()
	var before_matrix=matrix.duplicate(true)
	var previous: float=F.continuation(state,6,matrix[6],12)
	suite._check(state==before_state and matrix==before_matrix,"local reuse never changes finance state or forecast arrays")
	var changed=matrix[6].duplicate(true)
	changed[8]=row.duplicate()
	suite._check(F.continuation(state,6,changed,12)==original(state,6,changed,12) and original(state,6,changed,12)!=previous,"a different forecast row cannot reuse an earlier call's result")
	Profile.reset(true)
	F.continuation(state,6,matrix[6],12)
	var counts=Profile.snapshot().counts
	suite._check(counts.full_mean_hits>0 and counts.full_mean_misses<=12 and counts.continuation_calls==1,"one-call cache reuses nonbinding means and holds at most twelve tail entries")
	Profile.reset(false)

	var zeros: Array=[]
	for day in 13:
		var zero: Array=[]
		zero.resize(25)
		zero.fill(0.0)
		zero[0]=1.0
		zeros.append(zero)
	zeros[0][0]=0.5
	zeros[0][1]=0.5
	Profile.reset(true)
	var zero_value=F.continuation(state,6,zeros,12)
	var zero_counts=Profile.snapshot().counts
	Profile.reset(false)
	suite._check(zero_value==original(state,6,zeros,12) and zero_counts.full_mean_misses==12 and zero_counts.full_mean_hits==12,"zero expected sales is cached as a real value, not mistaken for a missing entry")
