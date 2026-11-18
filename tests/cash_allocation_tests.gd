extends RefCounted
const Config=preload("res://scripts/sim/cash_allocation_config.gd")
const Runner=preload("res://scripts/sim/cash_allocation_runner.gd")
const Old=preload("res://scripts/sim/input_runner.gd")
const Bound=preload("res://scripts/sim/binding_config.gd")
const Policy=preload("res://scripts/sim/brewery_policy.gd")
static func run(t: SceneTree) -> void:
	var original: Dictionary=Bound.initial()
	for allocation in Config.ALLOCATIONS:
		var state: Dictionary=Config.allocate(original,allocation)
		var restored: Dictionary=state.duplicate(true)
		for i in state.entities.size():
			var e: Dictionary=state.entities[i];var old: Dictionary=original.entities[i]
			var delta: int=-330 if e.id=="visitors" and allocation!="original" else 30 if allocation=="households_330" and e.id in Config.NONOWNERS else Config.FIRMS.get(e.id,0) if allocation=="firms_330" else 0
			t._check(e.money==old.money+delta,"exact named initial ownership "+allocation+":"+e.id)
			restored.entities[i].money=old.money
		t._check(restored==original and original==Bound.initial(),"only cash differs, original initializer immutable "+allocation)
		var r=Runner.new(42,"scarce","R_input_aware",allocation)
		t._check(r.world.events().size()==1 and r.world.events()[0].action=="initialize","no synthetic post-start transfer "+allocation)
		for b in r.Brew.ORDER:t._check(r.world.profit_budget(b).eligible==0 and r.initial.businesses[b].distribution_policy.reserve==120,"initial capital is not earned income "+allocation+b)
	var r=Runner.new(42,"scarce","R_input_aware","original");var old=Old.new(42,"scarce","R_input_aware");r.run(1);old.run(1)
	t._check(r.world.events()==old.world.events() and r.world.snapshot()==old.world.snapshot(),"original native ledger/state/receipt parity")
	var o={"money":36,"need_bread":1,"need_ale":0,"bread_ceiling":1000000000,"prices":{"bread":6},"stock":{"bread":1}}
	t._check(Policy.basket(o).bread==1,"legitimate household money buys available food")
	o.money=5;t._check(Policy.basket(o).bread==0,"cashless need is not solvent intent")
	o.money=36;o.need_bread=0;t._check(Policy.basket(o).bread==0,"extra initial money does not bypass used allowance")
