extends RefCounted
## Independent event reconstruction; shared native audit owns monetary/recipe checks.
const Ledger=preload("res://scripts/sim/enterprise_audit.gd")
const SITES={"farm":[6,1],"mill":[6,3],"bakery":[8,3]}
const TIMES={"farm":[540,600],"mill":[660,720],"bakery":[840,900]}
const TRADE={"farm":[600,660],"mill":[720,780],"bakery":[900,1035]}


static func _at(s: Dictionary, id: String, tile: Array) -> bool:
	return s.presences.has(id) and s.presences[id].active and s.presences[id].tile==tile


static func _open(s: Dictionary, business: String) -> bool:
	return business in TRADE and s.minute>=TRADE[business][0] and s.minute<(s.retail_close if business=="bakery" else TRADE[business][1])


static func verify(history: Array, final: Dictionary) -> Dictionary:
	var checks={"clock_and_timestamps":true,"movement_and_arrivals":true,"appointments_and_presence":true,
		"located_purchases":true,"courier_custody":true,"visitor_requests":true,"witness_boundaries":true,"goods_each_event":true,"physical_snapshot":true}
	var expected={"wheat":0,"flour":0,"bread":0}
	var initial: Dictionary=history[0].details.state
	for p in initial.entities.values():
		for item in expected: expected[item]+=p.inventory[item]
	var seen: Dictionary={}
	var purchased: Dictionary={}
	var arrival: Dictionary={}
	var observer=func(state: Dictionary,e: Dictionary):
		var s: Dictionary=state.spatial
		var d: Dictionary=e.details
		if e.action=="day_started": s.minute=0
		if e.success and e.action=="spatial_clock":
			checks.clock_and_timestamps=checks.clock_and_timestamps and d.from==s.minute and d.to==s.minute+5 and d.to<=1440
			s.minute=d.to
		var absolute: int=maxi(0,state.day-1)*1440+s.minute
		checks.clock_and_timestamps=checks.clock_and_timestamps and e.minute==s.minute and e.absolute_minute==absolute and e.minute%5==0
		if e.success:
			match e.action:
				"spatial_departed":
					var p: Dictionary=s.presences[e.actor]
					var current: Array=p.tile.duplicate()
					var route: Array=[]
					for axis in [0,1]:
						while current[axis]!=d.destination[axis]:
							current[axis]+=1 if d.destination[axis]>current[axis] else -1
							route.append(current.duplicate())
					checks.movement_and_arrivals=checks.movement_and_arrivals and p.active and p.activity=="idle" and not route.is_empty() and route==d.route and s.minute+route.size()*5<=d.arrive_by
					p.destination=d.destination.duplicate()
					p.route=route
					p.activity="walking"
					p.until=0
					p.last_step=absolute
				"spatial_moved":
					var p: Dictionary=s.presences[e.actor]
					checks.movement_and_arrivals=checks.movement_and_arrivals and p.active and p.activity=="walking" and p.tile==d.from and not p.route.is_empty() and p.route[0]==d.to \
						and absi(d.to[0]-d.from[0])+absi(d.to[1]-d.from[1])==1 and absolute-p.last_step>=5
					p.tile=d.to.duplicate()
					p.route.pop_front()
					p.last_step=absolute
				"spatial_arrived":
					var p: Dictionary=s.presences[e.actor]
					checks.movement_and_arrivals=checks.movement_and_arrivals and p.tile==p.destination and p.route.is_empty() and p.tile==d.tile and p.activity=="walking"
					p.activity="idle"
					arrival[e.actor]=e.id
				"spatial_stayed": checks.movement_and_arrivals=checks.movement_and_arrivals and _at(s,e.actor,d.tile) and s.presences[e.actor].activity=="idle"
				"spatial_activity_started":
					var p: Dictionary=s.presences[e.actor]
					checks.appointments_and_presence=checks.appointments_and_presence and p.active and p.activity=="idle" and d.until==s.minute+d.duration and d.until<=1440
					if d.kind in ["work","manage"]:
						checks.appointments_and_presence=checks.appointments_and_presence and _at(s,e.actor,SITES[e.target]) and s.minute==TIMES[e.target][0] and d.duration==60
						if d.kind=="manage": checks.appointments_and_presence=checks.appointments_and_presence and state.businesses[e.target].owner==e.actor
					elif d.kind in ["shop","procure","deposit"]:
						checks.appointments_and_presence=checks.appointments_and_presence and d.duration==5
					elif d.kind=="rest": checks.appointments_and_presence=checks.appointments_and_presence and _at(s,e.actor,p.home) and s.minute>=1110 and d.until==1440
					else: checks.appointments_and_presence=false
					p.activity=d.kind
					p.until=d.until
					p.business=e.target
				"spatial_activity_ended":
					var p: Dictionary=s.presences[e.actor]
					checks.appointments_and_presence=checks.appointments_and_presence and p.activity==d.kind and p.until==s.minute
					if d.kind=="work":
						var work: Dictionary=history[d.result_event_id-1]
						checks.appointments_and_presence=checks.appointments_and_presence and work.action=="work_shift" and work.actor==e.actor and work.minute==s.minute
					p.activity="idle"
					p.until=0
					p.business=""
				"spatial_visitor_entered":
					checks.visitor_requests=checks.visitor_requests and not s.presences.has(e.actor) and e.actor=="visitor:%04d:%d"%[state.day,d.slot] and d.slot in range(1,7) \
						and d.account=="visitors" and d.presence.tile==[9,3] and d.presence.home==[9,3] and d.presence.account=="visitors" and d.presence.loaf==0 and s.minute==1020
					s.presences[e.actor]=d.presence.duplicate(true)
				"spatial_visitor_exited":
					checks.visitor_requests=checks.visitor_requests and _at(s,e.actor,[9,3]) and s.presences[e.actor].activity=="idle" and s.presences[e.actor].loaf==0
					s.presences[e.actor].active=false
				"purchase":
					var id: String=e.physical_actor
					checks.located_purchases=checks.located_purchases and _at(s,id,SITES[e.target]) and _open(s,e.target) and s.presences[id].activity in ["shop","procure"]
					purchased[id]=purchased.get(id,0)+d.quantity
					if state.businesses.has(e.actor):
						checks.courier_custody=checks.courier_custody and d.custody.holder==id and d.custody.business==e.actor and state.businesses[e.actor].owner==id and state.cargo[e.actor].holder==id
					elif e.actor=="visitors":
						var p: Dictionary=s.presences[id]
						checks.visitor_requests=checks.visitor_requests and p.kind=="visitor" and p.account=="visitors" and not p.purchased and d.quantity==1 and p.loaf==0
						p.purchased=true
						p.loaf+=d.quantity
					else: checks.located_purchases=checks.located_purchases and id==e.actor and d.quantity==1
				"spatial_deposited":
					checks.courier_custody=checks.courier_custody and _at(s,e.actor,SITES[e.target]) and state.businesses[e.target].owner==e.actor and s.presences[e.actor].activity=="deposit" \
						and s.presences[e.actor].until==s.minute+5 and state.cargo[e.target].inventory.values().all(func(q):return q==0)
				"transfer_money":
					if d.purpose=="wage":
						checks.appointments_and_presence=checks.appointments_and_presence and e.physical_actor==e.target and _at(s,e.target,SITES[e.actor]) and s.presences[e.target].activity=="work" and s.presences[e.target].until==s.minute
				"produce","harvest","work_shift":
					var id: String=e.physical_actor
					var business: String=e.target if e.action=="work_shift" else e.actor
					checks.appointments_and_presence=checks.appointments_and_presence and _at(s,id,SITES[business]) and s.presences[id].activity=="work" and s.presences[id].business==business and s.presences[id].until==s.minute
					if e.action=="harvest": expected.wheat+=d.amount
					elif e.action=="produce":
						for item in d.inputs: expected[item]-=d.inputs[item]
						for item in d.outputs: expected[item]+=d.outputs[item]
				"consume":
					expected.bread-=d.amount
					if e.actor=="visitors":
						var id: String=e.physical_actor
						checks.visitor_requests=checks.visitor_requests and _at(s,id,SITES.bakery) and s.presences[id].loaf==1 and s.presences[id].activity=="idle" and d.amount==1
						s.presences[id].loaf-=d.amount
					else: checks.appointments_and_presence=checks.appointments_and_presence and _at(s,e.actor,s.presences[e.actor].home) and s.presences[e.actor].activity=="idle" and s.minute>=1110 and s.minute<1140
				"spatial_encounter":
					var witnesses: Array=[]
					for id in s.presences:
						if _at(s,id,d.tile): witnesses.append(id)
					witnesses.sort()
					checks.witness_boundaries=checks.witness_boundaries and _at(s,e.actor,d.tile) and d.tile==SITES[e.target] and d.witnesses==witnesses and d.keys().size()==5
					if d.kind=="inspected":
						checks.witness_boundaries=checks.witness_boundaries and _open(s,e.target) and s.presences[e.actor].activity=="idle"
						seen[e.actor]=[state.day,s.minute]
						purchased[e.actor]=0
					elif d.kind in ["purchased","declined"]:
						checks.witness_boundaries=checks.witness_boundaries and seen.get(e.actor)==[state.day,s.minute] and purchased.get(e.actor,0)==d.quantity and (d.quantity>0 if d.kind=="purchased" else d.quantity==0)
					elif d.kind=="arrived": checks.witness_boundaries=checks.witness_boundaries and arrival.has(e.actor) and history[arrival[e.actor]-1].minute==s.minute
					elif d.kind=="closed_attempt": checks.witness_boundaries=checks.witness_boundaries and not _open(s,e.target)
					elif d.kind!="busy_attempt": checks.witness_boundaries=false
				"quote_revised": checks.located_purchases=false
				"spatial_clock","spatial_shop_closed": pass
				_:
					if e.action.begins_with("spatial_"): checks.physical_snapshot=false
		var goods={"wheat":0,"flour":0,"bread":0}
		for p in state.entities.values():
			for item in goods: goods[item]+=p.inventory[item]
		for parcel in state.cargo.values():
			for item in goods: goods[item]+=parcel.inventory[item]
		checks.goods_each_event=checks.goods_each_event and goods==expected
		var loaves: int=0
		for p in s.presences.values():
			checks.movement_and_arrivals=checks.movement_and_arrivals and p.tile[0]>=0 and p.tile[0]<10 and p.tile[1]>=0 and p.tile[1]<7
			if p.kind=="visitor": loaves+=p.loaf
		checks.visitor_requests=checks.visitor_requests and loaves==state.entities.visitors.inventory.bread
	var result: Dictionary=Ledger.verify(history,final,false,observer)
	result["spatial"]=checks
	return result
