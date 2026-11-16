extends RefCounted
## Read-only conditional business cash flows. State: cash, flour, bread, retained earnings.
static func operate(state: Array, procure: bool, supply: int=12, input_price: int=4) -> Dictionary:
	var s=state.duplicate()
	var inputs=0
	if procure:
		inputs=mini(mini(12,supply),int((s[0]+1e-9)/input_price))
		s[0]-=inputs*input_price
		s[1]+=inputs
		s[3]-=inputs*input_price
	var shifts=mini(3,mini(int((s[0]+1e-9)/6),int((s[1]+1e-9)/4)))
	s[0]-=shifts*6
	s[1]-=shifts*4
	s[2]+=shifts*6
	s[3]-=shifts*6
	return {"state":s,"inputs":inputs,"shifts":shifts}

static func close(state: Array, price: int, quantity: float) -> Dictionary:
	var s=state.duplicate()
	var sold=minf(s[2],quantity)
	s[0]+=sold*price
	s[2]-=sold
	s[3]+=sold*price
	var payout=maxf(0.0,minf(s[3],s[0]-120.0))
	s[0]-=payout
	s[3]-=payout
	return {"state":s,"payout":payout}

static func mean_sales(pmf: Array, stock: float) -> float:
	var value=0.0
	for quantity in pmf.size(): value+=minf(stock,quantity)*pmf[quantity]
	return value

static func continuation(state: Array, price: int, forecasts: Array, supply: int) -> float:
	var first=operate(state,true,supply)
	var totals: Array=[]
	totals.resize(mini(24,int(first.state[2]))+1)
	totals.fill(0.0)
	for quantity in forecasts[0].size(): totals[mini(quantity,int(first.state[2]))]+=forecasts[0][quantity]
	var value=0.0
	for sold in totals.size():
		if totals[sold]<0.000000000001: continue
		var result=close(first.state,price,sold)
		var branch: float=result.payout
		var s: Array=result.state
		var discount=0.99
		for t in range(1,13):
			var operation=operate(s,true,supply)
			result=close(operation.state,price,mean_sales(forecasts[t],operation.state[2]))
			branch+=discount*result.payout
			s=result.state
			discount*=0.99
		branch+=pow(0.99,12)*s[0]
		value+=totals[sold]*branch
	return value
