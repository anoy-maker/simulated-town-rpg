extends SceneTree
## Conditional evidence/capital experiments, never authoritative endowment changes.
const B=preload("res://scripts/sim/bakery_beliefs.gd")
const P=preload("res://scripts/sim/bakery_policy.gd")
func _init() -> void:
	var b=B.fresh()
	for day in 6:
		b=B.hazard(b)
		b=B.update(b,{"local":{"arrivals":9,"eligible":12,"sales":12,"censored":false},
			"visitor":{"arrivals":6,"eligible":6,"sales":6,"censored":false}},6,true)
	b=B.hazard(b)
	b=B.update(b,{"local":{"arrivals":9,"eligible":12,"sales":12,"censored":false},
		"visitor":{"arrivals":6,"eligible":6,"sales":0,"censored":false}},7,true)
	b=B.hazard(b)
	var rows: Array=[]
	for cash in [4,54,120,234,300]:
		var o={"day":8,"current_price":7,"posted":[4,5,6,7],"state":[cash,12,0,cash-120],"supply":12,"input_price":4,"carry":3,"minimum":[1,0]}
		for stage in ["C","D"]:
			var p=P.decide(o,b,stage)
			rows.append({"cash":cash,"external_cash":8880-cash,"other_accounts":312,"combined":9192,"stage":stage,"observation":o,"beliefs":b,"proposal":p})
	print(JSON.stringify({"capital_cases":rows},"",true))
	quit()
