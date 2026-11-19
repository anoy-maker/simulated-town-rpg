extends "res://scripts/sim/labor_runner.gd"
## M10 changes only the optional ownership-income phase and its report projection.

const FinanceWorld = preload("res://scripts/sim/finance_world.gd")
const FinancePolicy = preload("res://scripts/sim/finance_policy.gd")
const Finance = preload("res://scripts/sim/finance_config.gd")
var _distribution: String


func _init(seed_value: int = 42, distribution: String = "needs", initial: Dictionary = Config.initial()) -> void:
	assert(distribution in Finance.POLICIES)
	super(seed_value, initial)
	_distribution = distribution
	world = FinanceWorld.new(seed_value, initial)
	_initial = world.snapshot()


func _before_food() -> void:
	# The unchanged control has exactly the M9 ledger, including decision events.
	if _distribution == "none":
		return
	for business in Config.BUSINESS_ORDER:
		var owner: String = _initial.businesses[business].owner
		world.execute_decision(owner, "finance", FinancePolicy.decide(world.observe(owner, business), _distribution), business)


func report() -> Dictionary:
	var summary: Dictionary = super()
	summary.scenario = "settlement_finance"
	var withdrawals = {"successful": 0, "rejected": 0, "amount": 0, "without_shift": 0, "by_business": {}}
	for account in summary.accounts.values():
		account["owner_withdrawals_received"] = 0
		account["owner_withdrawals_paid"] = 0
	for business in _initial.businesses:
		withdrawals.by_business[business] = {"successful": 0, "rejected": 0, "amount": 0, "without_shift": 0,
			"last_distribution_day": 0, "minimum_cash_after_withdrawal": null,
			"operating_reserve": world.withdrawal_budget(business).operating_reserve,
			"distributable_final": world.withdrawal_budget(business).distributable_cash}
	var worked: Dictionary = {}
	for event in world.events():
		if event.action == "work_shift" and event.success:
			worked[str(event.day) + ":" + event.actor] = true
		if event.action != "owner_withdrawal":
			continue
		var result: String = "successful" if event.success else "rejected"
		withdrawals[result] += 1
		if not withdrawals.by_business.has(event.target):
			continue
		var firm: Dictionary = withdrawals.by_business[event.target]
		firm[result] += 1
		if not event.success:
			continue
		var amount: int = event.details.amount
		var without_shift: int = 0 if worked.has(str(event.day) + ":" + event.actor) else 1
		withdrawals.amount += amount
		withdrawals.without_shift += without_shift
		firm.amount += amount
		firm.without_shift += without_shift
		firm.last_distribution_day = event.day
		if firm.minimum_cash_after_withdrawal == null or event.details.business_cash_after < firm.minimum_cash_after_withdrawal:
			firm.minimum_cash_after_withdrawal = event.details.business_cash_after
		summary.accounts[event.actor].earned += amount
		summary.accounts[event.actor].owner_withdrawals_received += amount
		summary.accounts[event.target].spent += amount
		summary.accounts[event.target].owner_withdrawals_paid += amount
		summary.money.circulation += amount
	summary["finance"] = {"policy": _distribution, "payout_divisor": Finance.POLICIES[_distribution],
		"reserve_days": Finance.RESERVE_DAYS, "household_meals": Finance.HOUSEHOLD_MEALS, "withdrawals": withdrawals}
	return summary
