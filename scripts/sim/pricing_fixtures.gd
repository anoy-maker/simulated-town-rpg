extends RefCounted
## Finite initial bread sellers only; no extra productive assets or autonomous entry.
const Config=preload("res://scripts/sim/enterprise_config.gd")
const Runner=preload("res://scripts/sim/pricing_runner.gd")


static func initial(cash: int=4, stock: int=1, visitors: int=8760) -> Dictionary:
	var state: Dictionary=Config.initial(visitors)
	for entity in state.entities:
		if entity.id=="ada": entity.money=cash
		if entity.id=="bakery": entity.inventory.bread=stock
	state.entities.append({"id":"rival","name":"Rival bakery","role":"baker","kind":"business","money":0,"inventory":{"wheat":0,"flour":0,"bread":stock}})
	state.businesses.rival={"id":"rival","account":"rival","industry":"baker","owner":"finn","employees":[],
		"assets":{"daily_slots":1,"batches_per_shift":2},"owner_compensation":0,"output_target":18,"distribution_policy":{"mode":"retain","reserve":24}}
	return state


static func run() -> RefCounted:
	var simulation=Runner.new(42,"A",initial(4,1,0))
	simulation.stage="competition_fixture"
	var w=simulation.world
	w.advance_day()
	w.revise_quote("cora","bakery","bread",3)
	w.revise_quote("finn","rival","bread",5)
	w.buy_from_market("ada","bread",1)
	w.buy_from_market("bram","bread",1)
	w.consume("ada")
	w.consume("bram")
	w.close_contract_day()
	return simulation
