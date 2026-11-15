extends RefCounted

const Runner = preload("res://scripts/sim/finance_runner.gd")
const World = preload("res://scripts/sim/finance_world.gd")
const Policy = preload("res://scripts/sim/finance_policy.gd")
const Rules = preload("res://scripts/sim/finance_config.gd")
const Labor = preload("res://scripts/sim/labor_runner.gd")
const LaborTests = preload("res://tests/labor_tests.gd")


static func _reject(suite: SceneTree, world: RefCounted, owner: String, business: String, amount: Variant, reason: String) -> void:
	var before: Dictionary = world.snapshot()
	suite._check(not world.owner_withdrawal(owner, business, amount) and world.snapshot() == before
		and world.events().back().details.reason == reason, "M10 atomic rejection: " + reason)


static func run(suite: SceneTree) -> void:
	var world = World.new(42, Labor.Config.initial())
	suite._check(world.withdrawal_budget("farm") == {"operating_reserve": 24, "distributable_cash": 96}
		and world.withdrawal_budget("mill").operating_reserve == 56
		and world.withdrawal_budget("bakery").operating_reserve == 88, "two-day cash reserves use unchanged capacities, wage terms and recipe costs")
	for amount in [0, -1, true, null, 0.5, "3", NAN, INF, World.MAX_AMOUNT + 1, 9223372036854775807]:
		_reject(suite, world, "ada", "farm", amount, "invalid_amount")
	_reject(suite, world, "missing", "farm", 1, "unknown_owner")
	_reject(suite, world, "ada", "missing", 1, "unknown_business")
	_reject(suite, world, "dain", "farm", 1, "not_owner")
	_reject(suite, world, "ada", "mill", 1, "not_owner")
	_reject(suite, world, "ada", "farm", 121, "insufficient_money")
	_reject(suite, world, "ada", "farm", 97, "operating_reserve")
	var before: Dictionary = world.snapshot()
	suite._check(world.owner_withdrawal("ada", "farm", 96), "an owner may withdraw all permitted surplus without working")
	var after: Dictionary = world.snapshot()
	suite._check(after.entities.farm.money == 24 and after.entities.ada.money == 102
		and after.labor_used.is_empty() and after.entities.farm.inventory == before.entities.farm.inventory,
		"ownership income transfers real cash, preserves goods/labor and retains the exact reserve")
	suite._check(world.events().back().action == "owner_withdrawal" and world.events().back().details.business_cash_after == 24,
		"distribution has its own accounting receipt, independent of wages")
	_reject(suite, world, "ada", "farm", 1, "operating_reserve")
	world.advance_day()
	world.offer_shift("ada", "farm", "dain")
	suite._check(world.work_shift("dain", "farm") and world.snapshot().entities.farm.money == 21,
		"retained operating capital remains spendable for real productive payroll")
	_reject(suite, world, "ada", "farm", 1, "operating_reserve")
	var initial: Dictionary = Labor.Config.initial()
	LaborTests._entity(initial, "ada").money = World.MAX_AMOUNT
	world = World.new(42, initial)
	_reject(suite, world, "ada", "farm", 1, "owner_money_limit")
	initial = Labor.Config.initial()
	initial.employment.dain.wage = World.MAX_AMOUNT
	LaborTests._entity(initial, "farm").money = World.MAX_AMOUNT
	world = World.new(42, initial)
	suite._check(world.withdrawal_budget("farm").operating_reserve == World.MAX_AMOUNT, "very large payroll reserve is safely capped at the cash bound")
	_reject(suite, world, "ada", "farm", 1, "operating_reserve")
	_test_policy_and_authority(suite)
	var baseline = Labor.new(42)
	var control = Runner.new(42, "none")
	baseline.run(30)
	control.run(30)
	suite._check(control.world.events() == baseline.world.events() and control.world.snapshot() == baseline.world.snapshot(),
		"no-withdrawal control preserves every original M9 event and all state")
	var projected: Dictionary = control.report()
	projected.erase("finance")
	projected.scenario = "settlement_labor"
	for account in projected.accounts.values():
		account.erase("owner_withdrawals_received")
		account.erase("owner_withdrawals_paid")
	suite._check(projected == baseline.report(), "control's inherited M9 report is exactly unchanged")
	for policy in ["needs", "half-surplus"]:
		var first = Runner.new(42, policy)
		var split = Runner.new(42, policy)
		first.run(30)
		split.run(12)
		split.run(18)
		suite._check(first.world.events() == split.world.events() and first.world.snapshot() == split.world.snapshot()
			and first.report() == split.report(), policy + " preserves complete deterministic split replay")
		var reconciled: bool = first.report().money.final == 432
		var comparison: Dictionary = first.report()
		for id in comparison.accounts:
			reconciled = reconciled and comparison.final.entities[id].money == comparison.initial.entities[id].money \
				+ comparison.accounts[id].earned - comparison.accounts[id].spent
		suite._check(reconciled, policy + " conserves money and reconciles every business/household including ownership income")
	# Synthetic transaction fixture: test classification without observing an economy.
	var receipt = Runner.new(42, "needs")
	receipt.world.owner_withdrawal("ada", "farm", 6)
	var report: Dictionary = receipt.report()
	suite._check(report.accounts.ada.owner_withdrawals_received == 6 and report.accounts.ada.wages_received == 0
		and report.accounts.farm.owner_withdrawals_paid == 6 and report.accounts.farm.wages_paid == 0
		and report.finance.withdrawals.without_shift == 1 and report.money.circulation == 6,
		"cash flows separate ownership income from wages even without productive labor")


static func _test_policy_and_authority(suite: SceneTree) -> void:
	var initial: Dictionary = Labor.Config.initial()
	var world = World.new(42, initial)
	var obs: Dictionary = world.observe("ada", "farm")
	var untouched: Dictionary = world.snapshot()
	suite._check(Policy.decide(obs, "needs").reason == "household_budget_satisfied", "owner declines unneeded withdrawals")
	obs.self.money = 0
	obs.self.inventory.bread = 0
	obs.business.withdrawal.distributable_cash = 5
	suite._check(Policy.decide(obs, "needs").action.amount == 5 and Policy.decide(obs, "half-surplus").action.amount == 2,
		"predeclared payout fraction changes a common household-need proposal with integer rounding")
	obs.business.withdrawal.distributable_cash = 0
	suite._check(Policy.decide(obs, "needs").reason == "operating_reserve_retained"
		and Policy.decide(obs, "none").reason == "withdrawals_disabled" and world.snapshot() == untouched,
		"policies preserve reserves and cannot mutate authoritative balances")
	obs.business.withdrawal.distributable_cash = 1
	suite._check(Policy.decide(obs, "half-surplus").reason == "payout_fraction_rounds_to_zero", "small fractional payout does not fabricate a coin")
	LaborTests._entity(initial, "finn").money = 999
	LaborTests._entity(initial, "bakery").money = 888
	LaborTests._entity(initial, "bakery").inventory.flour = 777
	var other = World.new(42, initial)
	suite._check(world.observe("ada", "farm") == other.observe("ada", "farm")
		and world.observe("dain", "farm").business.is_empty(), "withdrawal policies cannot see other households' or unrelated firms' private finances")
	var before: Dictionary = world.snapshot()
	suite._check(not world.execute_decision("dain", "finance", {"action": {"type": "owner_withdrawal", "amount": 3}}, "farm")
		and world.snapshot() == before, "decision executor rejects an employee's ownership withdrawal")
	suite._check(world.execute_decision("ada", "finance", {"action": {"type": "owner_withdrawal", "amount": 3, "owner": "dain", "business": "mill", "operating_reserve": 0}}, "farm")
		and world.snapshot().entities.ada.money == 9 and world.snapshot().entities.dain.money == 6
		and world.snapshot().entities.mill.money == 120, "withdrawal binds actual owner/business and ignores spoofed transaction participants/reserve")
	_reject(suite, world, "ada", "farm", 94, "operating_reserve")
	initial = Labor.Config.initial()
	LaborTests._entity(initial, "farm").money = 30
	world = World.new(42, initial)
	suite._check(world.owner_withdrawal("ada", "farm", 5), "first valid proposal spends unreserved surplus")
	_reject(suite, world, "ada", "farm", 2, "operating_reserve")
