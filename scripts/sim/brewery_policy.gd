extends RefCounted
## Pure, bounded inventory-target continuation; no authoritative state reference.
static func plan(o: Dictionary) -> Dictionary:
	var rule: Dictionary=o.rule
	var shifts: int=0
	var lots: int=0
	var selected: Array=[]
	var stock: int=o.output_stock
	var cash: int=o.cash
	var raw: int=o.input_stock
	var harvested: int=0
	var reason="output_target_met" if stock>=rule.target else "no_eligible_worker"
	for worker in o.workers:
		if stock>=rule.target: break
		if not worker.available: continue
		var make: int=mini(rule.make,o.harvest_remaining-harvested) if rule.input.is_empty() else rule.make
		if make<=0:
			reason="harvest_capacity"
			break
		var missing: int=1 if not rule.input.is_empty() and raw<rule.take else 0
		var cost: int=missing*rule.take*o.input_price+worker.wage
		if make*o.output_price<=cost:
			reason="nonpositive_expected_contribution"
			break
		if cash<cost:
			reason="working_capital"
			break
		if missing>0 and not o.allow_procurement:
			reason="missing_deposited_inputs"
			break
		cash-=cost
		raw+=missing*rule.take-rule.take
		lots+=missing
		shifts+=1
		stock+=make
		harvested+=make if rule.input.is_empty() else 0
		selected.append(worker.id)
		reason="positive_expected_contribution"
	return {"workers":selected,"shifts":shifts,"lots":lots,"expected_receipts":(stock-o.output_stock)*o.output_price,"committed_cash":o.cash-cash,"reason":reason}

static func basket(o: Dictionary) -> Dictionary:
	var best={"bread":0,"ale":0,"utility":o.money,"remaining":o.money,"cost":0}
	for bread in 2:
		for ale in 2:
			if bread>o.need_bread or ale>o.need_ale: continue
			if bread>0 and (not o.prices.has("bread") or o.stock.get("bread",0)<1 or o.prices.bread>o.bread_ceiling): continue
			if ale>0 and (not o.prices.has("ale") or o.stock.get("ale",0)<1): continue
			var cost: int=bread*o.prices.get("bread",0)+ale*o.prices.get("ale",0)
			if cost>o.money: continue
			var value: int=100*bread+5*ale+o.money-cost
			if value>best.utility or (value==best.utility and o.money-cost>best.remaining):
				best={"bread":bread,"ale":ale,"utility":value,"remaining":o.money-cost,"cost":cost}
	best["reason"]="positive_marginal_utility" if best.cost>0 else "allowance_used" if o.need_bread+o.need_ale==0 else "no_stock" if o.stock.values().all(func(n):return n==0) else "retain_cash_or_unaffordable"
	return best

static func allocation(grain: int, mill: int, brewer: int, price: int) -> Dictionary:
	var best={"mill":0,"brewery":0,"grain":0,"revenue":0}
	for m in range(mill+1):
		for b in range(brewer+1):
			var used: int=5*m+3*b
			if used>grain:continue
			var revenue: int=used*price
			if revenue>best.revenue or (revenue==best.revenue and m>best.mill):best={"mill":m,"brewery":b,"grain":used,"revenue":revenue}
	return best
