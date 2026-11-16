extends RefCounted

const Runner = preload("res://scripts/sim/profitable_runner.gd")
const World = preload("res://scripts/sim/profitable_world.gd")
const Terms = preload("res://scripts/sim/profitable_config.gd")
const Audit = preload("res://scripts/sim/profitable_audit.gd")
const LaborTests = preload("res://tests/labor_tests.gd")


static func _meals(world) -> void:
	for id in world.snapshot().entities:
		if world.snapshot().entities[id].kind == "resident":
			world.consume(id)


static func _farm(world) -> void:
	for worker in Terms.workers(world.snapshot().businesses.farm, world.snapshot().day):
		assert(world.offer_shift("ada", "farm", worker))
		assert(world.work_shift(worker, "farm"))


static func _outcome(world, worker: String) -> Dictionary:
	for e in world.events():
		if e.action == "contract_shift" and e.actor == worker:
			return e.details
	return {}


static func run(suite: SceneTree) -> void:
	var world = World.new(42)
	var initial: Dictionary = world.snapshot()
	suite._check(initial.entities.size() == 15 and initial.employment.size() == 9
		and initial.entities.ada.skills == ["farmer"] and initial.businesses.farm.owner_compensation == 0
		and initial.employment.dain.wage == 6 and initial.employment.dain.contract == {"cycle_days": 3, "shifts_per_cycle": 2, "cycle_compensation": 12, "phases": [1, 2]},
		"M14 keeps owners/skills/assets and explicit ongoing six-coin two-of-three employee contracts")
	var isolated: Dictionary = world.snapshot()
	isolated.cash_results.farm.sales = 1000
	suite._check(world.snapshot().cash_results.farm.sales == 0 and world.profit_budget("farm").eligible == 0,
		"snapshot edits cannot fabricate realized cash income or change distribution authority")
	world.advance_day()
	var before: Dictionary = world.snapshot()
	suite._check(not world.offer_shift("ada", "farm", "ada") and not world.work_shift("ada", "farm") and world.snapshot() == before,
		"M14 manager cannot perform productive work or collect management wages")
	suite._check(not world.offer_shift("ada", "farm", "edda") and world.snapshot() == before,
		"an eligible off-day employee cannot substitute for a due contractual worker")
	var poor: Dictionary = Terms.initial()
	LaborTests._entity(poor, "farm").money = 0
	world = World.new(42, poor)
	world.advance_day()
	before = world.snapshot()
	var rejected: bool = not world.offer_shift("ada", "farm", "dain")
	suite._check(rejected and world.snapshot() == before, "zero employer cash rejects the shift without imaginary payroll or stock")
	world.close_contract_day()
	var breach: Dictionary = _outcome(world, "dain")
	suite._check(breach.attempted and not breach.completed and breach.reason == "unfunded_payroll"
		and breach.expected_compensation == 6 and breach.actual_compensation == 0 and breach.constraints.cash == 0
		and world.snapshot().entities.dain.money == 6 and world.snapshot().entities.farm.inventory.wheat == 0,
		"zero-cash breach records due, real attempt, reason, expected six coins and actual zero without debt")
	var forged: Array = world.events()
	for e in forged:
		if e.action == "contract_shift" and e.actor == "dain":
			e.details.reason = "insufficient_inputs"
	suite._check(not Audit.verify(forged, world.snapshot()).accounting.contracts,
		"breach auditor rejects a fictional cause even when cash and goods are unchanged")
	breach = _outcome(world, "gale")
	suite._check(not breach.attempted and breach.reason == "employer_did_not_schedule" and breach.actual_compensation == 0,
		"declining to schedule is distinguishable from a genuinely constrained attempt")
	var count: int = world.events().size()
	world.close_contract_day()
	suite._check(world.events().size() == count and world.snapshot().employment.dain.active,
		"contract closure is idempotent and breaches do not suspend employment")
	world.advance_day()
	var due: Array = world.events().filter(func(e): return e.action == "contract_due" and e.day == 2 and e.target == "farm")
	suite._check(due.map(func(e): return e.actor) == ["dain", "edda"], "missed work is not automatically rescheduled into the next contractual pair")
	world = World.new(42)
	world.advance_day()
	before = world.snapshot()
	suite._check(not world.offer_shift("bram", "mill", "hale") and world.snapshot() == before, "contract does not permit milling without real wheat")
	world.close_contract_day()
	breach = _outcome(world, "hale")
	suite._check(breach.attempted and breach.reason == "insufficient_inputs" and breach.constraints.inventory.wheat == 0 and breach.actual_compensation == 0,
		"input shortage produces an explicit unpaid contractual breach")
	var stale: Dictionary = Terms.initial()
	LaborTests._entity(stale, "mill").inventory.wheat = 4
	world = World.new(42, stale)
	world.advance_day()
	assert(world.offer_shift("bram", "mill", "hale") and world.offer_shift("bram", "mill", "lyle"))
	assert(world.work_shift("lyle", "mill") and not world.work_shift("hale", "mill"))
	world.close_contract_day()
	breach = _outcome(world, "hale")
	suite._check(breach.attempted and breach.reason == "insufficient_inputs" and breach.constraints.inventory.wheat == 0
		and world.snapshot().entities.hale.money == 6 and _outcome(world, "lyle").actual_compensation == 6
		and Audit.verify(world.events(), world.snapshot()).accounting.values().all(func(v): return v),
		"offers reserve no inputs: later work failure records its actual depleted stock while retaining earlier genuine paid production")
	var limited: Dictionary = Terms.initial()
	limited.businesses.farm.assets.daily_slots = 1
	world = World.new(42, limited)
	world.advance_day()
	assert(world.offer_shift("ada", "farm", "dain") and world.work_shift("dain", "farm"))
	assert(not world.offer_shift("ada", "farm", "gale"))
	world.close_contract_day()
	suite._check(_outcome(world, "dain").completed and _outcome(world, "gale").reason == "workplace_capacity"
		and world.snapshot().entities.farm.inventory.wheat == 4 and world.snapshot().entities.dain.money == 12,
		"a partial contractual day preserves the completed paid shift and separately records capacity failure")
	suite._check(Audit.verify(world.events(), world.snapshot()).accounting.values().all(func(v): return v),
		"a valid constrained day with breaches still reconciles every real resource and financial receipt")
	limited = Terms.initial()
	LaborTests._entity(limited, "dain").skills = []
	world = World.new(42, limited)
	world.advance_day()
	assert(not world.offer_shift("ada", "farm", "dain"))
	world.close_contract_day()
	suite._check(_outcome(world, "dain").reason == "missing_skill" and not _outcome(world, "dain").constraints.qualified,
		"contractual entitlement never bypasses authoritative skill eligibility")
	# Initial capital, including synthetic capital above 120, is not realized income.
	limited = Terms.initial()
	LaborTests._entity(limited, "farm").money = 124
	world = World.new(42, limited)
	world.advance_day()
	_meals(world)
	before = world.snapshot()
	count = world.events().size()
	suite._check(world.profit_budget("farm").eligible == 0 and world.settle_profit("ada", "farm")
		and world.snapshot() == before and world.events().size() == count, "starting capital above the floor cannot be paid as operating profit")
	world = World.new(42)
	world.advance_day()
	_farm(world)
	_meals(world)
	before = world.snapshot()
	count = world.events().size()
	suite._check(world.profit_budget("farm").realized_remaining == -12 and world.settle_profit("ada", "farm")
		and world.snapshot() == before and world.events().size() == count and world.snapshot().entities.farm.inventory.wheat == 8,
		"unsold real production consumes payroll cash but creates neither sales income nor owner payout")
	# Recover a real -12 payroll result with actual stock sales; only receipts above recovery can pay out.
	world = World.new(42)
	world.advance_day()
	_farm(world)
	assert(world.purchase("mill", "farm", "wheat", 4, 2))
	_meals(world)
	suite._check(world.profit_budget("farm").realized_remaining == -4 and world.profit_budget("farm").eligible == 0,
		"partial sales leave earlier operating cash losses unrecovered")
	world.advance_day()
	assert(world.purchase("mill", "farm", "wheat", 2, 2))
	_meals(world)
	suite._check(world.profit_budget("farm").realized_remaining == 0 and world.profit_budget("farm").eligible == 0,
		"recovery to original capital creates no distributable surplus")
	world.advance_day()
	assert(world.purchase("mill", "farm", "wheat", 1, 2))
	_meals(world)
	assert(world.settle_profit("ada", "farm"))
	suite._check(world.snapshot().entities.farm.money == 120 and world.snapshot().cash_results.farm.distributions == 2
		and world.snapshot().entities.ada.money == 8, "only the actual two-coin surplus after cumulative loss recovery is distributed")
	world = World.new(42)
	world.advance_day()
	_farm(world)
	assert(world.purchase("mill", "farm", "wheat", 8, 2))
	before = world.snapshot()
	suite._check(not world.settle_profit("ada", "farm") and world.snapshot() == before, "profit settlement is unavailable before household consumption attempts")
	_meals(world)
	before = world.snapshot()
	suite._check(not world.settle_profit("bram", "farm") and world.snapshot() == before,
		"a foreign business owner cannot receive this firm's realized cash income")
	assert(world.settle_profit("ada", "farm"))
	var receipt: Dictionary = world.events().back()
	suite._check(receipt.action == "profit_distribution" and receipt.details.amount == 4
		and world.events()[receipt.details.payment_event_id - 1].action == "transfer_money"
		and world.snapshot().entities.farm.money == 120 and world.snapshot().entities.ada.money == 10,
		"owner distribution uses one existing authorized transfer receipt and retains all 120 capital coins")
	before = world.snapshot()
	count = world.events().size()
	suite._check(world.settle_profit("ada", "farm") and world.snapshot() == before and world.events().size() == count,
		"repeated settlement cannot pay the same surplus twice or emit a zero distribution")
	limited = Terms.initial()
	LaborTests._entity(limited, "ada").money = World.MAX_AMOUNT
	world = World.new(42, limited)
	world.advance_day()
	_farm(world)
	assert(world.purchase("mill", "farm", "wheat", 8, 2))
	_meals(world)
	before = world.snapshot()
	suite._check(not world.settle_profit("ada", "farm") and world.snapshot() == before, "destination overflow rejects owner income atomically with no cash-book mutation")
	limited = Terms.initial()
	LaborTests._entity(limited, "bakery").inventory.bread = 1000
	var stocked = Runner.new(42, limited)
	stocked.run(1)
	suite._check(stocked.report().accounts.bakery.produced.bread == 12 and stocked.world.snapshot().entities.bakery.inventory.bread == 1000,
		"high unsold inventory never suppresses contract production or silently discards goods")
	for days in [1, 2, 3, 30, 365]:
		var first = Runner.new(42)
		var split = Runner.new(42)
		first.run(days)
		@warning_ignore("integer_division")
		var middle: int = days / 2
		split.run(middle)
		split.run(days - middle)
		var r: Dictionary = first.report()
		var v: Dictionary = r.profitable.verification
		suite._check(v.accounting.values().all(func(value): return value) and v.reference.values().all(func(value): return value)
			and v.days_checked == days, "M14 %dd every-event accounting, funded unique labor, contracts and explicit daily/three-day recurrences" % days)
		suite._check(first.world.events() == split.world.events() and first.world.snapshot() == split.world.snapshot() and r == split.report(),
			"M14 %dd exact state/ledger/report split replay" % days)
		var valid: bool = r.shifts.paid == 6 * days and r.shifts.wages == 36 * days and r.profitable.distributions.amount == 12 * days
		valid = valid and r.profitable.contracts.due == 6 * days and r.profitable.contracts.completed == 6 * days and r.profitable.contracts.breaches == 0
		valid = valid and r.totals.harvested.wheat == 8 * days and r.totals.production_outputs == {"flour": 8 * days, "bread": 12 * days}
		valid = valid and r.totals.consumed.bread == 12 * days and r.money == {"initial": 432, "final": 432, "circulation": 144 * days} and r.failures.is_empty()
		var cash_ok: bool = true
		for actor in r.unmet_meals:
			var account: Dictionary = r.accounts[actor]
			valid = valid and account.consumed == days and r.unmet_meals[actor] == 0 and account.purchases == 4 * days
			if actor in ["ada", "bram", "cora"]:
				valid = valid and account.shifts == 0 and account.wages_received == 0 and account.profit_distributions_received == 4 * days and r.final.entities[actor].money == 6
			else:
				@warning_ignore("integer_division")
				var shifts: int = 2 * (days / 3)
				shifts += 1 if days % 3 >= 1 and actor in ["dain", "gale", "hale", "lyle", "finn", "kira"] else 0
				shifts += 1 if days % 3 == 2 and actor in ["dain", "edda", "hale", "jory", "finn", "iona"] else 0
				valid = valid and account.shifts == shifts and account.wages_received == 6 * shifts and account.profit_distributions_received == 0
				valid = valid and r.profitable.contracts.by_employee[actor].completed == shifts
			cash_ok = cash_ok and r.final.entities[actor].money == r.initial.entities[actor].money + account.earned - account.spent
		suite._check(cash_ok, "M14 %dd all twelve individual income/spending cash flows reconcile" % days)
		suite._check(valid, "M14 %dd matches predicted production, wages, profit distributions and food without owner labor" % days)
		print("M14 profitable reference: days=%d meals=%d shifts=%d employee_wages=%d owner_income=%d breaches=%d currency=%d" % [days,
			r.totals.consumed.bread, r.shifts.paid, r.shifts.wages, r.profitable.distributions.amount, r.profitable.contracts.breaches, r.money.final])
	var first = Runner.new(7)
	var second = Runner.new(99)
	first.run(3)
	second.run(3)
	suite._check(first.world.events() == second.world.events(), "fixed profitable reference uses no randomness")
	var corrupt: Array = first.world.events()
	for e in corrupt:
		if e.action == "profit_distribution":
			e.details.amount += 1
			break
	suite._check(not Audit.verify(corrupt, first.world.snapshot()).accounting.profit_accounting,
		"audit rejects an invented expected-profit annotation even when native money balances still conserve currency")
