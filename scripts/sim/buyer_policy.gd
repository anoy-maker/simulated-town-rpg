extends RefCounted
## Generic essential/input procurement from authorized own information and public quotes.


static func choose(o: Dictionary, excluded: Array = []) -> Dictionary:
	if o.needed <= 0:
		return {"action": "wait", "reason": "need_already_satisfied"}
	var offers: Array = o.offers.filter(func(q): return q.active and q.item == o.item and q.available > 0 and q.seller != o.buyer \
		and q.unit_price <= o.money and q.unit_price <= o.ceiling and (q.seller + ":" + str(q.version)) not in excluded)
	if offers.is_empty():
		return {"action": "wait", "reason": "no_eligible_affordable_offer"}
	offers.sort_custom(func(a,b): return a.seller < b.seller if a.unit_price == b.unit_price else a.unit_price < b.unit_price)
	var cheapest: Array = offers.filter(func(q):return q.unit_price == offers[0].unit_price)
	var offset: int = o.day
	for index in o.buyer.length():
		offset += o.buyer.unicode_at(index)
	var selected: Dictionary = cheapest[offset % cheapest.size()]
	@warning_ignore("integer_division")
	var quantity: int = mini(o.needed, mini(selected.available, o.money / selected.unit_price))
	return {"action": "purchase", "reason": "least_price_rotating_tie", "quote": selected.duplicate(true), "quantity": quantity}
