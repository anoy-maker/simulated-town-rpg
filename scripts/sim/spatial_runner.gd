extends "res://scripts/sim/external_trade_runner.gd"
## Prescribed appointments, not autonomous spatial planning or price learning.
const SpatialWorld=preload("res://scripts/sim/spatial_world.gd")
const Town=preload("res://scripts/sim/spatial_config.gd")
var measure_appointments: bool=false
var appointment_timings: Array=[]
var experiment: String


func _init(seed_value: int=42, spatial_case: String="control") -> void:
	super(seed_value)
	world=SpatialWorld.new(seed_value,spatial_case)
	_initial=world.snapshot()
	experiment=spatial_case


func _industry(business: String) -> void:
	var firm: Dictionary=_initial.businesses[business]
	world.manage(firm.owner,business)
	var workers: Array=firm.employees.duplicate()
	workers.sort()
	for worker in workers: world.start_shift(worker,business)


func run(days: int) -> void:
	assert(days>=0)
	for _index in days:
		world.advance_day()
		_day_started()
		for minute in [480,540,610,615,625,660,730,735,745,840,930,960,1020,1025,1030,1035,1110,1140,1440]:
			var appointment_start: int=Time.get_ticks_usec() if measure_appointments else 0
			world.advance_time(minute)
			for actor in participant_ids():
				var schedule: Dictionary=_initial.spatial.presences[actor].schedule
				if minute==schedule.depart: world.depart(actor,schedule.first_destination)
				var task: Dictionary=schedule.courier
				if not task.is_empty():
					if minute==task.purchase: world.procure(actor,schedule.business,task.seller,task.item)
					if minute==task.depart: world.depart(actor,Town.SITES[schedule.business])
					if minute==task.deposit: world.deposit(actor,schedule.business)
			match minute:
				540: _industry("farm")
				660: _industry("mill")
				840: _industry("bakery")
				930:
					for actor in participant_ids(): world.depart(actor,Town.SITES.bakery)
				960:
					for actor in participant_ids(): world.shop(actor)
				1020:
					for slot in range(1,7):
						world.enter_visitor(slot)
						world.depart("visitor:%04d:%d"%[world.snapshot().day,slot],Town.SITES.bakery)
				1025:
					for slot in range(1,7): world.shop("visitor:%04d:%d"%[world.snapshot().day,slot])
				1030:
					for slot in range(1,7):
						var id: String="visitor:%04d:%d"%[world.snapshot().day,slot]
						world.consume_visitor(id)
						world.depart(id,Town.GATE)
				1035:
					for slot in range(1,7): world.exit_visitor("visitor:%04d:%d"%[world.snapshot().day,slot])
					for actor in participant_ids(): world.depart(actor,_initial.spatial.presences[actor].home)
				1110:
					for actor in participant_ids():
						world.consume(actor)
						world.rest(actor)
				1140:
					for business in Config.BUSINESS_ORDER: world.settle_profit(_initial.businesses[business].owner,business)
					world.close_contract_day()

			_after_appointments(minute)
			if measure_appointments: appointment_timings.append({"day":world._day,"minute":minute,"usec":Time.get_ticks_usec()-appointment_start})
		_day_completed()


func _day_started() -> void:
	pass


func _day_completed() -> void:
	pass


func _after_appointments(_minute: int) -> void:
	pass


func _reference_verification(history: Array, final: Dictionary) -> Dictionary:
	return preload("res://scripts/sim/spatial_audit.gd").verify(history,final)


func report() -> Dictionary:
	var r: Dictionary=super()
	r.scenario="settlement_spatial"
	r.prices={"wheat":2,"flour":4,"bread":4}
	r.profitable.mode="M17 prescribed spatial "+experiment
	r.schedule={"map":"10x7; x then y; five minutes/tile", "work":"three parallel one-hour shifts per industry", "shopping":960,"visitor_requests":1025,"meals":1110,"closure":1140}
	r["spatial"]=preload("res://scripts/sim/spatial_report.gd").build(world.events(),r.final,experiment)
	return r
