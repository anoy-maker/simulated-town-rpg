extends RefCounted

const Runner = preload("res://scripts/sim/causality_runner.gd")
const Policy = preload("res://scripts/sim/causality_policy.gd")
const Report = preload("res://scripts/sim/causality_report.gd")
const Employer = preload("res://scripts/sim/employer_runner.gd")
const EmployerTests = preload("res://tests/employer_tests.gd")
const Reference = preload("res://scripts/sim/equilibrium_runner.gd")
const LaborTests = preload("res://tests/labor_tests.gd")


static func run(suite: SceneTree) -> void:
	var original = Employer.new(42)
	var a = Runner.new(42, Policy.FIXED_OWNER)
	var b = Runner.new(42, Policy.SALES_ROTATING)
	suite._check(a.world.snapshot() == original.world.snapshot() and b.world.snapshot() == Reference.new(42).world.snapshot(), "M13 all treatments start with exactly M11/M12's resources, jobs and assets")
	for actor in original.participant_ids():
		var business: String = {"ada": "farm", "bram": "mill", "cora": "bakery"}.get(actor, "")
		suite._check(a.world.observe(actor, business) == original.world.observe(actor, business)
			and b.world.observe(actor, business) == original.world.observe(actor, business), "M13 preserves authorized information for " + actor)
	a.world.advance_day()
	var obs: Dictionary = a.world.observe("ada", "farm")
	obs.day = 2
	obs.business.inventory.wheat = 100
	obs.business.history.sold.wheat = 0
	obs.business.history.previous_forecast = 8
	var before: Dictionary = obs.duplicate(true)
	var p: Dictionary = Policy.decide(obs, Policy.FIXED_OWNER)
	suite._check(p.required_output == 8 and p.planned_output == 8 and p.requested_shifts == 2 and p.workers == ["ada", "dain"]
		and p.unsold_stock == 100 and p.forecast_source == "prescribed_daily_output" and p.reductions.is_empty(), "M13-A never offsets output stock or weak sales against its prescribed NEW daily production")
	suite._check(obs == before, "treatment composition does not modify the authorized observation")
	obs.business.money = 8
	p = Policy.decide(obs, Policy.FIXED_OWNER)
	suite._check(p.planned_shifts == 1 and p.workers == ["ada"] and "insufficient_operating_funds" in p.reductions, "M13-A reduces to one genuinely funded shift instead of borrowing or suppressing its target")
	obs.business.money = 7
	suite._check(Policy.decide(obs, Policy.FIXED_OWNER).planned_shifts == 0, "M13-A may fail to fund even one prescribed shift")
	obs = a.world.observe("ada", "farm")
	obs.day = 2
	obs.business.history.sold.wheat = 8
	p = Policy.decide(obs, Policy.SALES_ROTATING)
	suite._check(p.candidate_workers == ["edda", "gale"] and p.workers == ["edda", "gale"], "M13-B uses only the even-day pair, never the available owner")
	var base: Dictionary = Employer.EmployerPolicy.decide(obs)
	var same: bool = true
	for key in ["forecast", "forecast_source", "unsold_stock", "required_output", "requested_shifts", "planned_shifts", "planned_output", "input_purchase", "input_cost", "payroll", "reason", "reductions"]:
		same = same and p[key] == base[key]
	suite._check(same, "M13-B preserves M12 production, input and cash calculations on matched feasible observations")
	obs.business.history.sold.wheat = 4
	suite._check(Policy.decide(obs, Policy.SALES_ROTATING).workers == ["edda"], "M13-B selects only the necessary prefix when fewer than two shifts are needed")
	for worker in obs.business.workers:
		if worker.id == "edda":
			worker.available = false
	suite._check(Policy.decide(obs, Policy.SALES_ROTATING).workers == ["gale"], "an unavailable first candidate can only be replaced inside its group")
	for worker in obs.business.workers:
		if worker.id == "gale":
			worker.qualified = false
	suite._check(Policy.decide(obs, Policy.SALES_ROTATING).workers.is_empty(), "M13-B never substitutes an out-of-group worker even when owner and another employee are available")
	obs = a.world.observe("ada", "farm")
	obs.day = 2
	suite._check(Policy.decide(obs, Policy.SALES_ROTATING).planned_shifts == 0, "M13-B zero sales never restore startup forecasts or guaranteed shifts")
	obs.business.history.sold.wheat = 4
	obs.business.inventory.wheat = 4
	suite._check(Policy.decide(obs, Policy.SALES_ROTATING).planned_shifts == 0, "M13-B retains M12's output-stock offset")
	var initial: Dictionary = Runner.Reference.initial()
	LaborTests._entity(initial, "finn").money = 999
	LaborTests._entity(initial, "bakery").inventory.flour = 888
	var private_world = Runner.new(42, Policy.SALES_ROTATING, initial)
	private_world.world.advance_day()
	suite._check(private_world.world.observe("ada", "farm") == a.world.observe("ada", "farm"), "unrelated private household funds and firm inputs cannot influence either treatment")
	var first_day: Array = []
	for condition in [Policy.FIXED_OWNER, Policy.SALES_ROTATING]:
		for days in [2, 7, 30, 365]:
			var first = Runner.new(42, condition)
			var replay = Runner.new(42, condition)
			first.run(days)
			@warning_ignore("integer_division")
			var split: int = days / 2
			replay.run(split)
			replay.run(days - split)
			var history: Array = first.world.events()
			var r: Dictionary = first.report()
			suite._check(history == replay.world.events() and r == replay.report(), "M13 %s %dd full ledger/report split replay" % [condition, days])
			suite._check(EmployerTests.ledger_ok(history, first.world.snapshot(), condition == Policy.FIXED_OWNER), "M13 %s %dd every-event cash/goods and unique funded work receipts" % [condition, days])
			var diagnostics: Dictionary = Report.project(r, history)
			var isolated: bool = true
			for e in history:
				if e.action != "employer_plan":
					continue
				var plan: Dictionary = e.details.proposal
				if condition == Policy.FIXED_OWNER:
					isolated = isolated and plan.required_output == {"farm": 8, "mill": 8, "bakery": 12}[e.target] and plan.requested_shifts == 2
				else:
					var group: Array = Runner.Reference.workers(r.initial.businesses[e.target], e.day)
					isolated = isolated and plan.candidate_workers == group
					for worker in plan.workers:
						isolated = isolated and worker in group
				isolated = isolated and plan.payroll + plan.input_cost >= 0
			suite._check(isolated and diagnostics.currency_after_every_event and diagnostics.accounting_and_labor_verified
				and r.final.employment == r.initial.employment, "M13 %s %dd treatment boundaries, receipt observer and unchanged jobs" % [condition, days])
			print("M13 %s days=%d meals=%d missed=%d shifts=%d first_cash_short=%s" % [condition, days, r.totals.consumed.bread,
				_missed(r.unmet_meals), r.shifts.paid, str(diagnostics.first_financial_constraint_day)])
			if days == 2:
				first_day.append(Report.economic_trace(history).filter(func(e): return e.day == 1))
	var reference = Reference.new(42)
	reference.run(1)
	suite._check(first_day[0] == first_day[1] and first_day[0] == Report.economic_trace(reference.world.events()), "all treatments preserve day-one native economic movements before the declared mechanisms diverge")
	var sample = Runner.new(42, Policy.FIXED_OWNER)
	sample.run(2)
	var short_report: Dictionary = sample.report()
	var corrupt: Array = sample.world.events()
	for e in corrupt:
		if e.action == "transfer_money" and e.success:
			e.details.amount = 7
			break
	suite._check(not Report.project(short_report, corrupt).accounting_and_labor_verified, "a currency-conserving incorrect wage fails the independent receipt observer")


static func _missed(unmet: Dictionary) -> int:
	var total: int = 0
	for amount in unmet.values():
		total += amount
	return total
