extends "res://scripts/sim/binding_runner.gd"
const DemandWorld=preload("res://scripts/sim/demand_world.gd")
func _init(seed: int=42,condition: String="reference",arm: String="legacy_instrumented",selected_fixture: String="none") -> void:
	super(seed,condition,"matching",selected_fixture)
	world=DemandWorld.new(seed,condition,arm,selected_fixture);initial=world.snapshot()
func appointment(minute: int) -> void:
	var start: int=Time.get_ticks_usec() if measure else 0
	if minute==955:
		world.advance_time(minute);world.freeze_demand()
	super(minute)
	world.close_demand_windows(minute)
	if measure:appointments.back().usec=Time.get_ticks_usec()-start
func report() -> Dictionary:
	var r: Dictionary=super();r.scenario="settlement_demand_observation"
	r["demand"]={"arm":world.demand_arm,"days":world._demand_days.duplicate(true),"forecasts":world._demand_forecasts.duplicate(true),"order_count":world._demand_orders.size(),"unfilled":world._demand_orders.values().reduce(func(n,o):return n+o.unfilled,0),"note":"Censored records are seller-local lower bounds, never latent demand truth."}
	return r
