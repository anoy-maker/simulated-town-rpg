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
const ExternalTrade = preload("res://scripts/sim/external_trade_runner.gd")
const PricingFixture = preload("res://scripts/sim/pricing_fixtures.gd")
const Learning = preload("res://scripts/sim/learning_runner.gd")
const Spatial = preload("res://scripts/sim/spatial_runner.gd")
const Pricing = preload("res://scripts/sim/pricing_runner.gd")
const EnterpriseFixtures = preload("res://scripts/sim/enterprise_fixtures.gd")
const ENTERPRISE_SCENARIOS = ["settlement_external_trade_reference", "enterprise_startup_fixture", "enterprise_delegation_fixture"]
const Profitable = preload("res://scripts/sim/profitable_runner.gd")
const Causality = preload("res://scripts/sim/causality_runner.gd")
const CausalityReport = preload("res://scripts/sim/causality_report.gd")
const STUDY_SCENARIOS = ["settlement_equilibrium_reference", "settlement_employer_choice", "settlement_fixed_owner_first", "settlement_sales_rotating"]


func _init() -> void:
	var args = OS.get_cmdline_user_args()
	var scenario: String = "m0"
	if not args.is_empty() and args[0] == "--scenario":
		if args.size() < 2 or args[1] not in ["m0", "trading", "agents", "coordination", "planning", "market", "market_downstream", "calibration", "settlement_labor", "settlement_finance", "settlement_equilibrium_reference", "settlement_employer_choice", "settlement_fixed_owner_first", "settlement_sales_rotating", "settlement_profitable_reference", "settlement_external_trade_reference", "enterprise_startup_fixture", "enterprise_delegation_fixture", "settlement_pricing", "pricing_competition_fixture", "settlement_spatial", "settlement_spatial_learning"]:
			_fail("Scenario must be m0, trading, agents, coordination, planning, market, market_downstream, calibration, settlement_labor, settlement_finance, settlement_equilibrium_reference, settlement_employer_choice, settlement_fixed_owner_first, settlement_sales_rotating, settlement_profitable_reference, settlement_external_trade_reference, enterprise_startup_fixture, enterprise_delegation_fixture, settlement_pricing, pricing_competition_fixture, or settlement_spatial.")
			return
		scenario = args[1]
		args = args.slice(2)
	var stage: String = "A"
	if not args.is_empty() and args[0] == "--stage":
		if scenario not in ["settlement_pricing","settlement_spatial_learning"] or args.size() < 2 or args[1] not in Pricing.ENABLED:
			_fail("Use --scenario %s --stage A|B|C|D" % ("settlement_spatial_learning" if scenario == "settlement_spatial_learning" else "settlement_pricing"))
			return
		stage = args[1]
		args = args.slice(2)
	var spatial_case: String = "control"
	if not args.is_empty() and args[0] == "--spatial-case":
		if scenario != "settlement_spatial" or args.size() < 2 or args[1] not in Spatial.Town.CASES:
			_fail("Use --scenario settlement_spatial --spatial-case control|late_worker|early_close")
			return
		spatial_case = args[1]
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
			or (args.size() > 2 and args[2] != "--json" and not ((scenario in STUDY_SCENARIOS and args[2] in ["--report-json", "--study-json"]) or (scenario in ["settlement_profitable_reference", "settlement_pricing", "pricing_competition_fixture", "settlement_spatial", "settlement_spatial_learning"] + ENTERPRISE_SCENARIOS and args[2] == "--report-json"))):
		_fail("Usage: run_simulation.gd -- [--scenario m0|trading|agents|coordination|planning|market|market_downstream|calibration|settlement_labor|settlement_finance|settlement_equilibrium_reference|settlement_employer_choice|settlement_fixed_owner_first|settlement_sales_rotating|settlement_profitable_reference|settlement_external_trade_reference|enterprise_startup_fixture|enterprise_delegation_fixture|settlement_pricing|pricing_competition_fixture|settlement_spatial] [--spatial-case control|late_worker|early_close] [--stage A|B|C|D] [--experiment name] [--priority commitment-first|immediate-needs-first] [--distribution none|needs|half-surplus] [days (0..10000)] [seed] [--json, --report-json, or --study-json (M11–M17 reports; M11–M13 study)]")
		return
	var days: int = int(args[0]) if args.size() > 0 else 30
	var seed_value: int = int(args[1]) if args.size() > 1 else 42
	if days < 0 or days > 10000:
		_fail("Days must be between 0 and 10000.")
		return
	if scenario in ["enterprise_startup_fixture", "enterprise_delegation_fixture", "pricing_competition_fixture"]:
		var fixture_days: int = 2 if scenario == "enterprise_delegation_fixture" else 1
		if (args.size() > 0 and days != fixture_days) or seed_value != 42:
			_fail("Transaction fixtures use their fixed %d-day sequence and seed 42." % fixture_days)
			return
		days = fixture_days
	if scenario == "settlement_spatial" and spatial_case != "control":
		if (args.size() > 0 and days != 1) or seed_value != 42:
			_fail("Spatial disruption fixtures use one day and seed 42.")
			return
		days = 1
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
	elif scenario == "pricing_competition_fixture":
		simulation = PricingFixture.run()
	elif scenario == "settlement_spatial_learning":
		simulation = Learning.new(seed_value, stage)
	elif scenario == "settlement_spatial":
		simulation = Spatial.new(seed_value, spatial_case)
	elif scenario == "settlement_pricing":
		simulation = Pricing.new(seed_value, stage)
	elif scenario == "settlement_external_trade_reference":
		simulation = ExternalTrade.new(seed_value)
	elif scenario == "enterprise_startup_fixture":
		simulation = EnterpriseFixtures.owner_sale()
	elif scenario == "enterprise_delegation_fixture":
		simulation = EnterpriseFixtures.delegation()
	elif scenario == "settlement_profitable_reference":
		simulation = Profitable.new(seed_value)
	elif scenario in [Causality.Treatment.FIXED_OWNER, Causality.Treatment.SALES_ROTATING]:
		simulation = Causality.new(seed_value, scenario)
	if scenario not in ["enterprise_startup_fixture", "enterprise_delegation_fixture", "pricing_competition_fixture"]:
		simulation.run(days)
	var report: Dictionary = simulation.report()
	if scenario in STUDY_SCENARIOS and args.size() > 2 and args[2] == "--study-json":
		var history: Array = simulation.world.events()
		var diagnostics: Dictionary = CausalityReport.project(report, history)
		print(JSON.stringify({"report": report, "diagnostics": diagnostics,
			"summary_sha256": (JSON.stringify({"report": report}, "", true) + "\n").sha256_text(),
			"ledger_sha256": JSON.stringify(history, "", true).sha256_text()}, "", true))
		quit(0)
		return
	if scenario in STUDY_SCENARIOS + ["settlement_profitable_reference", "settlement_pricing", "pricing_competition_fixture", "settlement_spatial", "settlement_spatial_learning"] + ENTERPRISE_SCENARIOS and (args.size() < 3 or args[2] == "--report-json"):
		if args.size() > 2:
			print(JSON.stringify({"report": report}, "", true))
		else:
			if scenario in ["settlement_spatial","settlement_spatial_learning"]:
				_print_spatial(report)
			elif scenario in ["settlement_pricing", "pricing_competition_fixture"]:
				_print_pricing(report)
			elif scenario in ENTERPRISE_SCENARIOS:
				_print_enterprise(report)
			elif scenario == "settlement_profitable_reference":
				_print_profitable(report)
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
	if report.scenario != "settlement_equilibrium_reference":
		if report.scenario == "settlement_employer_choice":
			print("Simulated Town RPG M12 employer choice | days=%d seed=%d" % [report.days, report.seed])
			print("Previous realized sales forecast; owner-first staffing; no rotation or guaranteed output.")
		else:
			print("Simulated Town RPG M13 %s | days=%d seed=%d" % [report.scenario, report.days, report.seed])
			print(report.employers.forecast_rule + "; " + report.schedule.workers)
	else:
		print("Simulated Town RPG M11 equilibrium reference | days=%d seed=%d" % [report.days, report.seed])
		print("Prescribed decisions: feasibility reference, not autonomous economic stability.")
	print("Production: wheat=%d flour=%d bread=%d" % [report.totals.harvested.wheat, report.totals.production_outputs.flour, report.totals.production_outputs.bread])
	print("Meals=%d missed=%d paid shifts=%d currency=%d circulation=%d" % [report.totals.consumed.bread, missed, report.shifts.paid, report.money.final, report.money.circulation])
	print("Business cash: " + JSON.stringify(business_cash, "", true))
	print("Household cash: " + JSON.stringify(household_cash, "", true))
	print("Final commodities: " + JSON.stringify(commodities, "", true))
	print("Failures: " + JSON.stringify(report.failures, "", true))
	if report.scenario != "settlement_equilibrium_reference":
		print("First unmet meal day=%s; first bread stock shortage=%s; sustained inactivity=%s" % [str(report.employers.first_unmet_meal_day), str(report.employers.first_bread_stock_shortage_day), str(report.employers.first_sustained_inactivity_day)])


func _print_profitable(report: Dictionary) -> void:
	print("Simulated Town RPG M14 profitable reference | days=%d seed=%d" % [report.days, report.seed])
	print("Prescribed three-day contracts; managing owners; realized cash distributions.")
	print("Production: " + JSON.stringify(report.totals.production_outputs.merged({"wheat": report.totals.harvested.wheat}), "", true))
	print("Meals=%d missed=%d paid shifts=%d wages=%d distributions=%d currency=%d" % [report.totals.consumed.bread,
		report.unmet_meals.values().reduce(func(a, b): return a + b, 0), report.shifts.paid, report.shifts.wages,
		report.profitable.distributions.amount, report.money.final])
	print("Contract due/completed/breached: %d/%d/%d" % [report.profitable.contracts.due, report.profitable.contracts.completed, report.profitable.contracts.breaches])
	var cash: Dictionary = {}
	for id in report.final.entities:
		cash[id] = report.final.entities[id].money
	print("Cash: " + JSON.stringify(cash, "", true))
	print("Realized operating cash: " + JSON.stringify(report.profitable.cash_results, "", true))
	print("Verification: " + JSON.stringify(report.profitable.verification, "", true))


func _print_enterprise(report: Dictionary) -> void:
	print("Simulated Town RPG M15 | %s days=%d seed=%d" % [report.scenario, report.days, report.seed])
	print("Prescribed reference/transaction fixtures; no autonomous entrepreneurship.")
	print("Boundary and activity: " + JSON.stringify(report.open_economy, "", true))
	print("Paid shifts=%d wages=%d distributions=%d" % [report.shifts.paid, report.shifts.wages, report.profitable.distributions.amount])
	print("Goods: " + JSON.stringify(report.totals, "", true))
	print("Contracts: due=%d fulfilled=%d breaches=%d" % [report.profitable.contracts.due, report.profitable.contracts.completed, report.profitable.contracts.breaches])
	print("Verification: " + JSON.stringify(report.profitable.verification, "", true))


func _print_pricing(r: Dictionary) -> void:
	print("Simulated Town RPG M16 | stage=%s days=%d seed=%d" % [r.pricing.stage,r.days,r.seed])
	print("Conditional one-period pricing beliefs; prescribed production and employment.")
	print("Village/external money=%d/%d; resident meals=%d missed=%d; visitor bread=%d" % [r.open_economy.village_money,r.open_economy.external_money,r.open_economy.resident_meals,r.unmet_meals.values().reduce(func(a,b):return a+b,0),r.open_economy.visitor_bread])
	print("Final posted quotes: " + JSON.stringify(r.final.commodity_quotes,"",true))
	print("Price revisions: " + JSON.stringify(r.pricing.price_changes,"",true))
	print("Paid shifts=%d wages=%d owner distributions=%d contract breaches=%d" % [r.shifts.paid,r.shifts.wages,r.profitable.distributions.amount,r.profitable.contracts.breaches])
	print("Verification: " + JSON.stringify(r.profitable.verification,"",true))


func _print_spatial(r: Dictionary) -> void:
	if r.has("learning"):
		print("Simulated Town RPG M18 | stage=%s days=%d seed=%d" % [r.learning.stage,r.days,r.seed])
	else:
		print("Simulated Town RPG M17 | case=%s days=%d seed=%d" % [r.spatial.case,r.days,r.seed])
	print("Headless 10x7 grid; x then y; one orthogonal step per five minutes.")
	print("Resident meals=%d missed=%d visitor loaves=%d" % [r.open_economy.resident_meals,r.unmet_meals.values().reduce(func(a,b):return a+b,0),r.open_economy.visitor_bread])
	print("Paid shifts=%d wages=%d owner distributions=%d minimum breaches=%d" % [r.shifts.paid,r.shifts.wages,r.profitable.distributions.amount,r.profitable.contracts.breaches])
	print("Village/external/combined money=%d/%d/%d" % [r.open_economy.village_money,r.open_economy.external_money,r.money.final])
	print("Steps=%d visitor presences=%d clock=%d; cargo=" % [r.spatial.days.reduce(func(a,d):return a+d.steps,0),r.spatial.temporary_visitors,r.spatial.clock_minute]+JSON.stringify(r.spatial.cargo_final,"",true))
	print("Verification: "+JSON.stringify(r.profitable.verification,"",true))
