extends RefCounted
const ExecutionProfile=preload("res://scripts/sim/execution_profile.gd")
## Cohort-day Bayesian model. No world reference or private customer facts.
static var _tables: Dictionary={}
static var _components: Dictionary={}

static func prior() -> Array:
	var w: Array=[]
	for k in 12: w.append(0.8/12.0)
	w.append(0.2)
	return w

static func initial() -> Dictionary:
	return {"local":{"alpha":Array(),"weights":prior()},"visitor":{"alpha":Array(),"weights":prior()}}

static func fresh() -> Dictionary:
	var b=initial()
	for c in b:
		for n in 13: b[c].alpha.append(0.25)
	return b

static func hazard(b: Dictionary) -> Dictionary:
	var _profile_scope=ExecutionProfile.scope("bayes") if ExecutionProfile.enabled else null
	var result=b.duplicate(true)
	var p=prior()
	for c in result:
		for h in 13: result[c].weights[h]=0.98*result[c].weights[h]+0.02*p[h]
	return result

static func q(h: int, price: int) -> float:
	return (0.9 if price<=h+1 else 0.1) if h<12 else clampf(0.8-0.075*(price-4),0.1,0.9)

static func row(h: int, price: int, n: int) -> Array:
	var key=Vector3i(h,price,n)
	if _tables.has(key): return _tables[key]
	if ExecutionProfile.enabled: ExecutionProfile.count("beta_table_misses")
	var a=2.0*q(h,price)
	var b=2.0-a
	var r: Array=[1.0]
	for i in n: r[0]*=(b+i)/(2.0+i)
	for s in n: r.append(r[s]*float(n-s)/(s+1)*(a+s)/(b+n-s-1))
	var total: float=0.0
	for v in r: total+=v
	for s in r.size(): r[s]/=total
	_tables[key]=r
	return r

static func update(b: Dictionary, observations: Dictionary, price: int, complete: bool) -> Dictionary:
	var _profile_scope=ExecutionProfile.scope("bayes") if ExecutionProfile.enabled else null
	var result=b.duplicate(true)
	for c in ["local","visitor"]:
		var o: Dictionary=observations[c]
		if complete: result[c].alpha[mini(12,o.arrivals)]+=1.0
		if o.eligible==0 or o.censored or o.get("unresolved",0)>0: continue
		var scores: Array=[]
		var scale=0.0
		for h in 13:
			var value: float=result[c].weights[h]*row(h,price,o.eligible)[o.sales]
			scores.append(value)
			scale=maxf(scale,value)
		var total=0.0
		for h in 13:
			scores[h]/=scale
			total+=scores[h]
		for h in 13: result[c].weights[h]=scores[h]/total
	return result

static func demand(b: Dictionary, price: int, carry: int=3, minimum: Array=[0,0]) -> Array:
	var _profile_scope=ExecutionProfile.scope("forecast") if ExecutionProfile.enabled else null
	var pmfs: Array=[]
	for ci in 2:
		var c: String=["local","visitor"][ci]
		var mass: Array=[]
		mass.resize(13)
		mass.fill(0.0)
		var total=0.0
		for n in range(minimum[ci],13): total+=b[c].alpha[n]
		var key=str([b[c].alpha,price,carry if ci==0 else 0,minimum[ci]])
		if not _components.has(key):
			if ExecutionProfile.enabled: ExecutionProfile.count("traffic_component_misses")
			var components: Array=[]
			for h in 13:
				var component: Array=[]
				component.resize(13)
				component.fill(0.0)
				for n in range(minimum[ci],13):
					var people=mini(12,n+(carry if ci==0 else 0))
					var r=row(h,price,people)
					for v in r.size(): component[v]+=b[c].alpha[n]/total*r[v]
				components.append(component)
			_components[key]=components
		for h in 13:
			for v in 13: mass[v]+=b[c].weights[h]*_components[key][h][v]
		pmfs.append(mass)
	return pmfs

static func sales(pmf: Array, stock: int) -> Array:
	var out: Array=[]
	out.resize(mini(24,stock)+1)
	out.fill(0.0)
	for l in 13:
		for v in 13: out[mini(stock,l+v)]+=pmf[0][l]*pmf[1][v]
	return out

static func outcomes(b: Dictionary, c: String, price: int, stock: int, carry: int, minimum: int) -> Array:
	var _profile_scope=ExecutionProfile.scope("evsi_outcomes") if ExecutionProfile.enabled else null
	var merged: Dictionary={}
	var total=0.0
	for n in range(minimum,13): total+=b[c].alpha[n]
	for n in range(minimum,13):
		var m=mini(12,n+carry)
		for h in 13:
			var weight: float=b[c].alpha[n]/total*b[c].weights[h]
			var r=row(h,price,m)
			for s in range(mini(stock,m)+1):
				if s==stock and stock<m: continue
				_add(merged,n,m,s,false,weight*r[s])
			if stock<m:
				if stock==0: _add(merged,n,0,0,m>0,weight)
				else:
					for k in range(stock,m+1):
						# P(first stock-th success at k), exchangeable beta-binomial.
						_add(merged,n,k,stock,k<m,weight*row(h,price,k)[stock]*float(stock)/k)
	var out: Array=merged.values()
	out.sort_custom(func(a,z):
		for key in ["sales","arrivals","eligible","censored"]:
			if a[key]!=z[key]: return int(a[key])<int(z[key])
		return false)
	return out

static func _add(out: Dictionary,n: int,e: int,s: int,c: bool,p: float) -> void:
	var key="%d:%d:%d:%d"%[n,e,s,int(c)]
	if not out.has(key): out[key]={"arrivals":n,"eligible":e,"sales":s,"censored":c,"probability":0.0}
	out[key].probability+=p

static func quadrature(out: Array) -> Array:
	var _profile_scope=ExecutionProfile.scope("evsi_outcomes") if ExecutionProfile.enabled else null
	var result: Array=[]
	var cumulative=0.0
	var index=0
	for bin in 3:
		var target=(bin+0.5)/3.0
		while index<out.size()-1 and cumulative+out[index].probability<target:
			cumulative+=out[index].probability
			index+=1
		var representative: Dictionary=out[index].duplicate()
		representative.probability=1.0/3.0
		result.append(representative)
	return result
