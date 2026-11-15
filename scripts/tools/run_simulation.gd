extends SceneTree

const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const Trading = preload("res://scripts/sim/trading_runner.gd")
const Agents = preload("res://scripts/sim/agents_runner.gd")
const Coordination = preload("res://scripts/sim/coordination_runner.gd")
const Planning = preload("res://scripts/sim/planning_runner.gd")
const Market = preload("res://scripts/sim/market_runner.gd")
const MarketDownstream = preload("res://scripts/sim/market_downstream_runner.gd")
const Calibration = preload("res://scripts/sim/calibration_runner.gd")
const Labor = preload("res://scripts/sim/labor_runner.gd")
const Finance = preload("res://scripts/sim/finance_runner.gd")
const Equilibrium = preload("res://scripts/sim/equilibrium_runner.gd")
const Employer = preload("res://scripts/sim/employer_runner.gd")


func _init() -> void:
	var args = OS.get_cmdline_user_args()
	var scenario: String = "m0"
	if not args.is_empty() and args[0] == "--scenario":
		if args.size() < 2 or args[1] not in ["m0", "trading", "agents", "coordination", "planning", "market", "market_downstream", "calibration", "settlement_labor", "settlement_finance", "settlement_equilibrium_reference", "settlement_employer_choice"]:
			_fail("Scenario must be m0, trading, agents, coordination, planning, market, market_downstream, calibration, settlement_labor, settlement_finance, settlement_equilibrium_reference, or settlement_employer_choice.")
			return
		scenario = args[1]
		args = args.slice(2)
	var experiment: String = "baseline"
	if not args.is_empty() and args[0] == "--experiment":
		if scenario != "calibration" or args.size() < 2 or args[1] not in Calibration.Config.available_experiments():
			_fail("Use --scenario calibration --experiment " + "|".join(Calibration.Config.available_experiments()))
			return
		experiment = args[1]
		args = args.slice(2)
	var priority: String = "commitment-first"
	if not args.is_empty() and args[0] == "--priority":
		if scenario != "planning" or args.size() < 2 or args[1] not in ["commitment-first", "immediate-needs-first"]:
			_fail("Planning priority must be commitment-first or immediate-needs-first; use --scenario planning.")
			return
		priority = args[1]
		args = args.slice(2)
	var distribution: String = "needs"
	if not args.is_empty() and args[0] == "--distribution":
		if scenario != "settlement_finance" or args.size() < 2 or args[1] not in Finance.Finance.POLICIES:
			_fail("Use --scenario settlement_finance --distribution none|needs|half-surplus")
			return
		distribution = args[1]
		args = args.slice(2)
	if args.size() > 3 or (args.size() > 0 and not args[0].is_valid_int()) \
			or (args.size() > 1 and not args[1].is_valid_int()) \
			or (args.size() > 2 and args[2] != "--json" and not (scenario in ["settlement_equilibrium_reference", "settlement_employer_choice"] and args[2] == "--report-json")):
		_fail("Usage: run_simulation.gd -- [--scenario m0|trading|agents|coordination|planning|market|market_downstream|calibration|settlement_labor|settlement_finance|settlement_equilibrium_reference|settlement_employer_choice] [--experiment name] [--priority commitment-first|immediate-needs-first] [--distribution none|needs|half-surplus] [days (0..10000)] [seed] [--json or --report-json (M11/M12 only)]")
		return
	var days: int = int(args[0]) if args.size() > 0 else 30
	var seed_value: int = int(args[1]) if args.size() > 1 else 42
	if days < 0 or days > 10000:
		_fail("Days must be between 0 and 10000.")
		return
	var simulation = Trading.new(seed_value) if scenario == "trading" else Simulation.new(seed_value)
	if scenario == "agents":
		simulation = Agents.new(seed_value)
	elif scenario == "coordination":
		simulation = Coordination.new(seed_value)
	elif scenario == "planning":
		simulation = Planning.new(seed_value, [], Planning.Policy.DEFAULT_GOALS, priority)
	elif scenario == "market":
		simulation = Market.new(seed_value)
	elif scenario == "market_downstream":
		simulation = MarketDownstream.new(seed_value)
	elif scenario == "calibration":
		simulation = Calibration.new(seed_value, Calibration.Config.preset(experiment))
	elif scenario == "settlement_labor":
		simulation = Labor.new(seed_value)
	elif scenario == "settlement_finance":
		simulation = Finance.new(seed_value, distribution)
	elif scenario == "settlement_equilibrium_reference":
		simulation = Equilibrium.new(seed_value)
	elif scenario == "settlement_employer_choice":
		simulation = Employer.new(seed_value)
	simulation.run(days)
	var report: Dictionary = simulation.report()
	if scenario in ["settlement_equilibrium_reference", "settlement_employer_choice"] and (args.size() < 3 or args[2] == "--report-json"):
		if args.size() > 2:
			print(JSON.stringify({"report": report}, "", true))
		else:
			_print_reference(report)
		quit(0)
		return
	if args.size() > 2:
		print(JSON.stringify({"report": report, "events": simulation.world.events()}, "\t", true))
	else:
		if scenario == "settlement_finance":
			print("Simulated Town RPG M10 settlement_finance (%s) | days=%d seed=%d" % [distribution, days, seed_value])
		elif scenario == "settlement_labor":
			print("Simulated Town RPG M9 settlement_labor | days=%d seed=%d" % [days, seed_value])
		elif scenario == "calibration":
			print("Simulated Town RPG M7 calibration (%s) | days=%d seed=%d" % [experiment, days, seed_value])
		elif scenario == "market_downstream":
			print("Simulated Town RPG M6B market_downstream | days=%d seed=%d" % [days, seed_value])
		elif scenario == "market":
			print("Simulated Town RPG M6 market | days=%d seed=%d" % [days, seed_value])
		elif scenario == "planning":
			print("Simulated Town RPG M5 planning (%s) | days=%d seed=%d" % [priority, days, seed_value])
		elif scenario == "coordination":
			print("Simulated Town RPG M4 coordination | days=%d seed=%d" % [days, seed_value])
		elif scenario == "agents":
			print("Simulated Town RPG M3 agents | days=%d seed=%d" % [days, seed_value])
		elif scenario == "trading":
			print("Simulated Town RPG M2 trading | days=%d seed=%d" % [days, seed_value])
		else:
			print("Simulated Town RPG M0 | days=%d seed=%d" % [days, seed_value])
		for actor in simulation.participant_ids():
			var before: Dictionary = report.initial.entities[actor]
			var after: Dictionary = report.final.entities[actor]
			print("%s (%s, %s): money %d -> %d; inventory %s -> %s; unmet meals %d" % [
				before.name, actor, before.role, before.money, after.money,
				JSON.stringify(before.inventory), JSON.stringify(after.inventory), report.unmet_meals[actor]])
		print("Totals: " + JSON.stringify(report.totals, "", true))
		if scenario in ["settlement_labor", "settlement_finance"]:
			for key in ["prices", "shifts", "potential", "accounts", "business_activity", "money"]:
				print(key + ": " + JSON.stringify(report[key], "", true))
			print("Business holdings: " + JSON.stringify(report.final.entities, "", true))
			if scenario == "settlement_finance":
				print("Ownership income: " + JSON.stringify(report.finance, "", true))
		if scenario in ["trading", "agents", "coordination", "planning", "market", "market_downstream", "calibration"]:
			print("Prices: " + JSON.stringify(report.prices, "", true))
			print("Purchases: " + JSON.stringify(report.purchases, "", true))
			print("Cash flow: " + JSON.stringify(report.cash_flow, "", true))
			print("Employer payments: " + JSON.stringify(report.payments, "", true))
			print("Failure groups: " + JSON.stringify(report.failure_groups, "", true))
		if scenario in ["agents", "coordination", "planning", "market", "market_downstream", "calibration"]:
			print("Goals: " + JSON.stringify(report.goals, "", true))
			print("Decisions: " + JSON.stringify(report.decisions, "", true))
		if scenario in ["coordination", "planning", "market", "market_downstream", "calibration"]:
			print("Agreements: " + JSON.stringify(report.agreements, "", true))
		if scenario in ["planning", "market", "market_downstream", "calibration"]:
			print("Activity after day 26: " + JSON.stringify(report.activity_after_day_26, "", true))
			print("Final working-capital estimates: " + JSON.stringify(report.final_working_capital, "", true))
		if scenario in ["market", "market_downstream", "calibration"]:
			print("Market participants: " + JSON.stringify(report.participants, "", true))
			print("Schedule: " + JSON.stringify(report.schedule))
		if scenario == "calibration":
			print("Configuration: " + JSON.stringify(report.configuration, "", true))
			print("Potential: " + JSON.stringify(report.potential, "", true))
			print("Calibration: " + JSON.stringify(report.calibration, "", true))
		print("Failures: " + JSON.stringify(report.failures, "", true))
		print("Events: %d; first failures:" % report.event_count)
		for event in report.notable_events:
			print(JSON.stringify(event, "", true))
	quit(0)


func _fail(message: String) -> void:
	printerr(message)
	quit(2)


func _print_reference(report: Dictionary) -> void:
	var business_cash: Dictionary = {}
	var household_cash: Dictionary = {}
	var commodities: Dictionary = {"wheat": 0, "flour": 0, "bread": 0}
	var missed: int = 0
	for id in report.final.entities:
		var entity: Dictionary = report.final.entities[id]
		if entity.kind == "business":
			business_cash[id] = entity.money
		else:
			household_cash[id] = entity.money
		for item in commodities:
			commodities[item] += entity.inventory[item]
	for amount in report.unmet_meals.values():
		missed += amount
	if report.scenario == "settlement_employer_choice":
		print("Simulated Town RPG M12 employer choice | days=%d seed=%d" % [report.days, report.seed])
		print("Previous realized sales forecast; owner-first staffing; no rotation or guaranteed output.")
	else:
		print("Simulated Town RPG M11 equilibrium reference | days=%d seed=%d" % [report.days, report.seed])
		print("Prescribed decisions: feasibility reference, not autonomous economic stability.")
	print("Production: wheat=%d flour=%d bread=%d" % [report.totals.harvested.wheat, report.totals.production_outputs.flour, report.totals.production_outputs.bread])
	print("Meals=%d missed=%d paid shifts=%d currency=%d circulation=%d" % [report.totals.consumed.bread, missed, report.shifts.paid, report.money.final, report.money.circulation])
	print("Business cash: " + JSON.stringify(business_cash, "", true))
	print("Household cash: " + JSON.stringify(household_cash, "", true))
	print("Final commodities: " + JSON.stringify(commodities, "", true))
	print("Failures: " + JSON.stringify(report.failures, "", true))
	if report.scenario == "settlement_employer_choice":
		print("First unmet meal day=%s; first bread stock shortage=%s; sustained inactivity=%s" % [str(report.employers.first_unmet_meal_day), str(report.employers.first_bread_stock_shortage_day), str(report.employers.first_sustained_inactivity_day)])
