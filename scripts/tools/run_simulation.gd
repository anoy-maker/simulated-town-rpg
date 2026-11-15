extends SceneTree

const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const Trading = preload("res://scripts/sim/trading_runner.gd")
const Agents = preload("res://scripts/sim/agents_runner.gd")
const Coordination = preload("res://scripts/sim/coordination_runner.gd")
const Planning = preload("res://scripts/sim/planning_runner.gd")


func _init() -> void:
	var args = OS.get_cmdline_user_args()
	var scenario: String = "m0"
	if not args.is_empty() and args[0] == "--scenario":
		if args.size() < 2 or args[1] not in ["m0", "trading", "agents", "coordination", "planning"]:
			_fail("Scenario must be m0, trading, agents, coordination, or planning.")
			return
		scenario = args[1]
		args = args.slice(2)
	var priority: String = "commitment-first"
	if not args.is_empty() and args[0] == "--priority":
		if scenario != "planning" or args.size() < 2 or args[1] not in ["commitment-first", "immediate-needs-first"]:
			_fail("Planning priority must be commitment-first or immediate-needs-first; use --scenario planning.")
			return
		priority = args[1]
		args = args.slice(2)
	if args.size() > 3 or (args.size() > 0 and not args[0].is_valid_int()) \
			or (args.size() > 1 and not args[1].is_valid_int()) \
			or (args.size() > 2 and args[2] != "--json"):
		_fail("Usage: run_simulation.gd -- [--scenario m0|trading|agents|coordination|planning] [--priority commitment-first|immediate-needs-first] [days (0..10000)] [seed] [--json]")
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
	simulation.run(days)
	var report: Dictionary = simulation.report()
	if args.size() > 2:
		print(JSON.stringify({"report": report, "events": simulation.world.events()}, "\t", true))
	else:
		if scenario == "planning":
			print("Simulated Town RPG M5 planning (%s) | days=%d seed=%d" % [priority, days, seed_value])
		elif scenario == "coordination":
			print("Simulated Town RPG M4 coordination | days=%d seed=%d" % [days, seed_value])
		elif scenario == "agents":
			print("Simulated Town RPG M3 agents | days=%d seed=%d" % [days, seed_value])
		elif scenario == "trading":
			print("Simulated Town RPG M2 trading | days=%d seed=%d" % [days, seed_value])
		else:
			print("Simulated Town RPG M0 | days=%d seed=%d" % [days, seed_value])
		for actor in Simulation.IDS:
			var before: Dictionary = report.initial.entities[actor]
			var after: Dictionary = report.final.entities[actor]
			print("%s (%s, %s): money %d -> %d; inventory %s -> %s; unmet meals %d" % [
				before.name, actor, before.role, before.money, after.money,
				JSON.stringify(before.inventory), JSON.stringify(after.inventory), report.unmet_meals[actor]])
		print("Totals: " + JSON.stringify(report.totals, "", true))
		if scenario in ["trading", "agents", "coordination", "planning"]:
			print("Prices: " + JSON.stringify(report.prices, "", true))
			print("Purchases: " + JSON.stringify(report.purchases, "", true))
			print("Cash flow: " + JSON.stringify(report.cash_flow, "", true))
			print("Employer payments: " + JSON.stringify(report.payments, "", true))
			print("Failure groups: " + JSON.stringify(report.failure_groups, "", true))
		if scenario in ["agents", "coordination", "planning"]:
			print("Goals: " + JSON.stringify(report.goals, "", true))
			print("Decisions: " + JSON.stringify(report.decisions, "", true))
		if scenario in ["coordination", "planning"]:
			print("Agreements: " + JSON.stringify(report.agreements, "", true))
		if scenario == "planning":
			print("Activity after day 26: " + JSON.stringify(report.activity_after_day_26, "", true))
			print("Final working-capital estimates: " + JSON.stringify(report.final_working_capital, "", true))
		print("Failures: " + JSON.stringify(report.failures, "", true))
		print("Events: %d; first failures:" % report.event_count)
		for event in report.notable_events:
			print(JSON.stringify(event, "", true))
	quit(0)


func _fail(message: String) -> void:
	printerr(message)
	quit(2)
