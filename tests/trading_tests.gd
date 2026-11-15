extends RefCounted

const Simulation = preload("res://scripts/sim/simulation_runner.gd")
const Trading = preload("res://scripts/sim/trading_runner.gd")
const M0_HASH = "6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9"


static func run(suite: SceneTree) -> void:
	_test_first_day(suite)
	_test_no_rescue(suite)
	for days in [30, 365]:
		var first = Trading.new(42)
		var second = Trading.new(42)
		first.run(days)
		second.run(12)
		second.run(days - 12)
		suite._check(first.world.snapshot() == second.world.snapshot(), "trading %d-day state replays" % days)
		suite._check(JSON.stringify(first.world.events()) == JSON.stringify(second.world.events()),
			"trading %d-day events replay across split runs" % days)
		suite._check(JSON.stringify(first.report()) == JSON.stringify(second.report()),
			"trading %d-day reports replay" % days)
		suite._audit(first.world.events(), first.world.snapshot())
		_check_accounting(suite, first)
	var empty = Trading.new(42)
	empty.run(0)
	suite._check(empty.report().initial == empty.report().final
		and empty.report().purchases.successful == 0 and empty.report().failure_groups.is_empty(),
		"zero-day trading leaves only endowments")
	var other = Trading.new(43)
	other.run(30)
	var original = Trading.new(42)
	original.run(30)
	suite._check(original.world.events() != other.world.events(), "trading harvest depends on seed")
	var m0 = Simulation.new(42)
	m0.run(30)
	var payload = JSON.stringify({"report": m0.report(), "events": m0.world.events()}, "\t", true) + "\n"
	suite._check(payload.sha256_text() == M0_HASH, "historical M0 JSON hash remains unchanged")


static func _test_first_day(suite: SceneTree) -> void:
	var simulation = Trading.new(42)
	simulation.run(1)
	var report: Dictionary = simulation.report()
	var events: Array = simulation.world.events()
	var actions: Array = []
	for event in events.slice(1):
		actions.append(event.action)
	suite._check(actions == ["day_started", "transfer_money", "harvest", "purchase", "produce",
		"purchase", "produce", "purchase", "purchase", "purchase", "consume", "consume", "consume", "consume"],
		"trading tick follows the documented order")
	suite._check(report.initial.entities == Simulation.default_entities().reduce(
		func(result, entity): result[entity.id] = entity; return result, {}), "trading keeps M0 initial endowments")
	var expected_balances = {"farmer": 29, "miller": 21, "baker": 21, "laborer": 4}
	var expected_flow = {"farmer": [4, 5], "miller": [8, 7], "baker": [9, 8], "laborer": [2, 3]}
	for actor in Simulation.IDS:
		suite._check(report.final.entities[actor].money == expected_balances[actor], "first-day balance: " + actor)
		suite._check(report.cash_flow[actor].earned == expected_flow[actor][0]
			and report.cash_flow[actor].spent == expected_flow[actor][1], "first-day cash flow: " + actor)
	suite._check(report.purchases.successful == 5 and report.purchases.rejected == 0,
		"first day executes real wheat, flour, and bread purchases")
	suite._check(report.totals.traded == {"wheat": 4, "flour": 4, "bread": 3}, "first-day traded volumes")
	suite._check(report.totals.production_outputs == {"flour": 4, "bread": 6}
		and report.totals.consumed.bread == 4, "first-day production and actual eating")
	var before: Dictionary = simulation.world.snapshot()
	report.prices.bread = 999
	report.final.entities.farmer.money = -1
	suite._check(simulation.world.snapshot() == before and simulation.report().prices.bread == 3,
		"report edits cannot change world or fixed prices")


static func _test_no_rescue(suite: SceneTree) -> void:
	var entities = Simulation.default_entities()
	for entity in entities:
		entity.money = 0
		entity.inventory.bread = 0
	var simulation = Trading.new(42, entities)
	simulation.run(1)
	var report: Dictionary = simulation.report()
	var money: int = 0
	var bread: int = 0
	for entity in report.final.entities.values():
		money += entity.money
		bread += entity.inventory.bread
	suite._check(money == 0 and bread == 0, "failed payments/purchases do not fabricate money or food")
	suite._check(report.payments.successful == 0 and report.payments.rejected == 1
		and report.purchases.successful == 0 and report.purchases.rejected == 5,
		"distressed scenario retains all rejected attempts")
	suite._check(report.unmet_meals == {"farmer": 1, "miller": 1, "baker": 1, "laborer": 1},
		"distressed villagers genuinely miss meals")
	suite._check(report.totals.production_outputs == {"flour": 0, "bread": 0}
		and report.totals.harvested.wheat > 0, "harvest remains explicit while unfunded production fails")
	suite._audit(simulation.world.events(), simulation.world.snapshot())


static func _check_accounting(suite: SceneTree, simulation: RefCounted) -> void:
	var report: Dictionary = simulation.report()
	var history: Array = simulation.world.events()
	var initial_stock = {"wheat": 0, "flour": 0, "bread": 0}
	var final_stock = initial_stock.duplicate()
	var initial_money: int = 0
	var final_money: int = 0
	var earned: int = 0
	var spent: int = 0
	var sales: int = 0
	var payments_received: int = 0
	var unmet: int = 0
	for actor in Simulation.IDS:
		var before: Dictionary = report.initial.entities[actor]
		var after: Dictionary = report.final.entities[actor]
		var flow: Dictionary = report.cash_flow[actor]
		initial_money += before.money
		final_money += after.money
		earned += flow.earned
		spent += flow.spent
		sales += flow.sales
		payments_received += flow.payments_received
		unmet += report.unmet_meals[actor]
		suite._check(after.money == before.money + flow.earned - flow.spent
			and flow.earned == flow.sales + flow.payments_received
			and flow.spent == flow.purchases + flow.payments_sent, "cash flow reconciles for " + actor)
		var meals: Array = history.filter(func(event): return event.action == "consume" and event.actor == actor and event.success)
		suite._check(meals.size() + report.unmet_meals[actor] == report.days, "meals reconcile for " + actor)
		for item in initial_stock:
			initial_stock[item] += before.inventory[item]
			final_stock[item] += after.inventory[item]
	suite._check(initial_money == 75 and final_money == 75 and earned == spent,
		"trading conserves all currency and reconciles aggregate cash flow")
	suite._check(final_stock.wheat == initial_stock.wheat + report.totals.harvested.wheat - report.totals.production_inputs.wheat
		and final_stock.flour == initial_stock.flour + report.totals.production_outputs.flour - report.totals.production_inputs.flour
		and final_stock.bread == initial_stock.bread + report.totals.production_outputs.bread - report.totals.consumed.bread,
		"every commodity reconciles to explicit sources and sinks")
	suite._check(unmet + report.totals.consumed.bread == 4 * report.days, "all trading meals are accounted for")
	var valid: bool = history.size() == 1 + 14 * report.days
	var success: int = 0
	var rejected: int = 0
	var failures: int = 0
	for event in history:
		if not event.success:
			failures += 1
		if event.action == "purchase":
			valid = valid and event.details.unit_price == Trading.PRICES[event.details.item]
			if event.success:
				success += 1
			else:
				rejected += 1
		elif event.action == "transfer_money":
			valid = valid and event.actor == "farmer" and event.target == "laborer" and event.details.amount == 2
		elif event.action == "transfer_item":
			valid = false
	suite._check(valid, "all trading exchanges use fixed-price purchases and explicit employer transfers")
	suite._check(success == report.purchases.successful and rejected == report.purchases.rejected
		and success + rejected == 5 * report.days, "purchase counts match all logged attempts")
	for item in Trading.PRICES:
		var quantities: int = 4 if item in ["wheat", "flour"] else 1
		var tally: Dictionary = report.purchases.by_item[item]
		var item_events: Array = history.filter(func(event): return event.action == "purchase" and event.details.item == item)
		var accepted: Array = item_events.filter(func(event): return event.success)
		suite._check(accepted.size() == tally.successful and item_events.size() - accepted.size() == tally.rejected,
			"per-item purchase outcomes match ledger: " + item)
		suite._check(tally.quantity == tally.successful * quantities and report.totals.traded[item] == tally.quantity
			and tally.money == tally.quantity * Trading.PRICES[item], "traded quantities and proceeds: " + item)
	suite._check(report.payments.successful + report.payments.rejected == report.days
		and report.payments.amount == 2 * report.payments.successful, "daily payments count only successful transfers")
	var proceeds: int = 0
	for tally in report.purchases.by_item.values():
		proceeds += tally.money
	suite._check(proceeds == sales and payments_received == report.payments.amount
		and earned == sales + payments_received, "sale proceeds and employer payments explain all earned money")
	var grouped_failures: int = 0
	for group in report.failure_groups.values():
		var matching: Array = history.filter(func(event):
			return (not event.success and event.action == group.action
				and event.actor == group.actor and event.target == group.target
				and event.details.reason == group.reason
				and event.details.get("item", event.details.get("recipe", "money")) == group.resource))
		valid = matching.size() == group.count and matching.front().day == group.first_day and matching.back().day == group.last_day
		suite._check(valid, "failure group identifies exact resource, participants, count, and day range")
		grouped_failures += group.count
	suite._check(grouped_failures == failures, "all shortages and transaction failures appear in report")
