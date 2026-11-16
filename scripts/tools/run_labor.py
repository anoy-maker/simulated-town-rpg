#!/usr/bin/env python3
"""Run the fixed M9/M10 experiments twice, independently audit receipts, and export tables."""
import argparse
import copy
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess

ITEMS = ("wheat", "flour", "bread")
RECIPES = {"mill": ({"wheat": 4}, {"flour": 4}), "bake": ({"flour": 4}, {"bread": 6})}
OUTPUTS = {"farmer": "wheat", "miller": "flour", "baker": "bread"}
INPUTS = {"farmer": "", "miller": "wheat", "baker": "flour"}
PAYOUTS = {"none": 0, "needs": 1, "half-surplus": 2}


def operating_reserve(state, business):
    firm = state["businesses"][business]
    wages = [firm["owner_compensation"]] + [state["employment"][w]["wage"] for w in firm["employees"] if state["employment"][w]["active"]]
    inputs_per_shift = {"farmer": 0, "miller": 4, "baker": 8}[firm["industry"]]
    return min(1_000_000_000, 2 * firm["assets"]["daily_slots"] * (max(wages) + inputs_per_shift))


def legacy_report(report):
    """M10's no-withdrawal report projected to its exact, unchanged M9 schema."""
    report = copy.deepcopy(report)
    report.pop("finance")
    report["scenario"] = "settlement_labor"
    for account in report["accounts"].values():
        account.pop("owner_withdrawals_received")
        account.pop("owner_withdrawals_paid")
    return report


def audit(data):
    """Rebuild all authoritative state, bind payroll/production to unique real shifts."""
    report, history = data["report"], data["events"]
    state = copy.deepcopy(history[0]["details"]["state"])
    assert report["initial"] == state and history[0]["action"] == "initialize"
    initial_money = sum(e["money"] for e in state["entities"].values())
    initial_stock = {i: sum(e["inventory"][i] for e in state["entities"].values()) for i in ITEMS}
    flows = {a: dict(earned=0, spent=0, sales=0, purchases=0, wages_received=0, wages_paid=0,
                     shifts=0, produced=dict.fromkeys(ITEMS, 0), consumed=0, purchases_successful=0, purchases_failed=0,
                     last_production_day=0, last_business_day=0, last_work_day=0, schedule_reasons={}) for a in state["entities"]}
    profitable = report["scenario"] == "settlement_profitable_reference"
    contract_due, contract_outcomes, profit_before = {}, {}, {}
    contract_totals = dict(due=0, attempted=0, completed=0, breaches=0, expected_compensation=0, paid_compensation=0,
                           by_employee={}, breach_reasons={})
    income = dict(transactions=0, amount=0, rejected=0)
    if profitable:
        for account in flows.values():
            account.update(profit_distributions_received=0, profit_distributions_paid=0)
        for worker in state["employment"]:
            contract_totals["by_employee"][worker] = dict(due=0, attempted=0, completed=0, breaches=0,
                                                       expected_compensation=0, paid_compensation=0)
    finance = "finance" in report
    withdrawals = dict(successful=0, rejected=0, amount=0, without_shift=0, by_business={})
    if finance:
        for account in flows.values():
            account.update(owner_withdrawals_received=0, owner_withdrawals_paid=0)
        for business in state["businesses"]:
            withdrawals["by_business"][business] = dict(successful=0, rejected=0, amount=0, without_shift=0,
                last_distribution_day=0, minimum_cash_after_withdrawal=None,
                operating_reserve=operating_reserve(state, business), distributable_final=0)
    unmet = dict.fromkeys(report["unmet_meals"], 0)
    totals = dict(harvested={"wheat": 0}, production_inputs={"wheat": 0, "flour": 0},
                  production_outputs={"flour": 0, "bread": 0}, consumed={"bread": 0})
    claimed, economic_receipts, decisions = set(), set(), {}
    failures, notable = {}, []
    sales_by_day, employer_work, native_employer_work, employer_turns = {}, set(), set(), set()
    potential_wheat = circulation = 0
    shifts = dict(paid=0, rejected=0, unfunded=0, unavailable=0, wages=0)
    purchases = dict(successful=0, rejected=0)
    for index, event in enumerate(history, 1):
        assert event["id"] == index
        action, actor, target, d = (event[k] for k in ("action", "actor", "target", "details"))
        if not event["success"] and action not in ("labor_decision", "employer_plan", "contract_attempt", "contract_shift"):
            failure = action + ":" + d["reason"]
            failures[failure] = failures.get(failure, 0) + 1
            if len(notable) < 8:
                notable.append(event)
        if action == "day_started":
            state["day"] += 1
            if profitable:
                assert state["contract_day_closed"]
                state["contract_day_closed"] = False
                contract_due.clear()
                contract_outcomes.clear()
            for field in ("labor_used", "business_labor", "offers", "harvest_opportunities", "meals"):
                state[field].clear()
        assert event["day"] == state["day"]
        if action == "labor_decision":
            key = ":".join((actor, d["phase"], d["reason"], d["outcome"]))
            decisions[key] = decisions.get(key, 0) + 1
            if d["phase"] == "schedule" and d["outcome"] == "wait":
                shifts["unavailable"] += 1
                shifts["unfunded"] += d["reason"] == "unfunded_payroll"
                reasons = flows[target]["schedule_reasons"]
                reasons[d["reason"]] = reasons.get(d["reason"], 0) + 1
            if d["command_event_id"] is not None:
                command = history[d["command_event_id"] - 1]
                assert command["id"] == index - 1 and command["success"] == event["success"]
                expected_actor = target if d["phase"] == "inputs" else actor
                assert command["actor"] == expected_actor
                if d["phase"] in ("inputs", "schedule", "finance"):
                    assert state["businesses"][target]["owner"] == actor
            else:
                assert d["outcome"] in ("wait", "rejected")
        if action == "purchase":
            purchases["successful" if event["success"] else "rejected"] += 1
            flows[actor]["purchases_successful" if event["success"] else "purchases_failed"] += 1
        if action == "work_shift":
            if event["success"]:
                native_employer_work.add(index)
                shifts["paid"] += 1
                shifts["wages"] += d["wage"]
            else:
                shifts["rejected"] += 1
                shifts["unfunded"] += d["reason"] == "unfunded_payroll"
        if action == "consume" and not event["success"]:
            unmet[actor] += d["amount"]
        if action == "owner_withdrawal":
            assert finance
            result = "successful" if event["success"] else "rejected"
            withdrawals[result] += 1
            if target in withdrawals["by_business"]:
                withdrawals["by_business"][target][result] += 1
        if profitable and action == "profit_distribution" and not event["success"]:
            income["rejected"] += 1
        if profitable and action == "contract_attempt":
            command = history[d["command_event_id"] - 1]
            assert command["id"] == index - 1 and command["action"] == "shift_offered"
            assert command["actor"] == actor and command["target"] == target and command["success"] == event["success"]
        if profitable and action == "contract_shift":
            assert actor in contract_due and actor not in contract_outcomes and contract_due[actor] == target
            assert d["contract_id"] == f"{state['day']}:{target}:{actor}" and d["employer"] == state["businesses"][target]["owner"]
            assert d["completed"] == event["success"] and d["expected_compensation"] == 6 and d["actual_compensation"] == (6 if event["success"] else 0)
            assert d["attempted"] == (d["attempt_event_id"] is not None)
            if d["attempted"]:
                attempt = history[d["attempt_event_id"] - 1]
                assert attempt["action"] == "contract_attempt" and attempt["actor"] == d["employer"] and attempt["target"] == target
                assert attempt["details"]["worker"] == actor and attempt["details"]["authorized_attempt"]
            if event["success"]:
                shift = history[d["shift_event_id"] - 1]
                assert shift["action"] == "work_shift" and shift["success"] and shift["actor"] == actor and shift["target"] == target and shift["day"] == state["day"]
            else:
                assert d["shift_event_id"] is None and (d["attempted"] or d["reason"] == "employer_did_not_schedule")
                reasons = contract_totals["breach_reasons"]
                reasons[d["reason"]] = reasons.get(d["reason"], 0) + 1
            contract_outcomes[actor] = event["success"]
            for row in (contract_totals, contract_totals["by_employee"][actor]):
                row["due"] += 1
                row["attempted"] += d["attempted"]
                row["completed"] += event["success"]
                row["breaches"] += not event["success"]
                row["expected_compensation"] += d["expected_compensation"]
                row["paid_compensation"] += d["actual_compensation"]
        # A rejected multi-step plan can retain earlier successful native commands.
        # Its annotation still has to claim those real receipts, without applying them twice.
        if action == "employer_plan" and "execution" in d:
            assert state["businesses"][target]["owner"] == actor
            assert (state["day"], target) not in employer_turns
            employer_turns.add((state["day"], target))
            item = OUTPUTS[state["businesses"][target]["industry"]]
            prescribed = report["scenario"] == "settlement_fixed_owner_first"
            rotating = report["scenario"] == "settlement_sales_rotating"
            expected = dict(wheat=8, flour=8, bread=12)[item] if prescribed or state["day"] == 1 else sales_by_day.get((state["day"] - 1, target, item), 0)
            assert d["proposal"]["forecast"] == expected, "employer forecast must use its own last realized sales"
            assert d["proposal"]["forecast_source"] == ("prescribed_daily_output" if prescribed else "one_time_startup" if state["day"] == 1 else "previous_realized_sales")
            if prescribed:
                assert d["proposal"]["required_output"] == expected and d["proposal"]["requested_shifts"] == 2
                assert "unsold_inventory_offset" not in d["proposal"]["reductions"]
            if rotating:
                firm = state["businesses"][target]
                roster = [firm["owner"]] + sorted(firm["employees"])
                group = roster[:2] if state["day"] % 2 else roster[2:]
                assert d["proposal"]["candidate_workers"] == group, "rotation must have an exclusive candidate group"
                workers = d["proposal"]["workers"]
                assert len(workers) == len(set(workers)) and workers == [w for w in group if w in workers], "no outside-group substitute or reordered worker"
            execution = d["execution"]
            per_shift = 6 if item == "bread" else 4
            opening_output = state["entities"][target]["inventory"][item] - len(execution["work_event_ids"]) * per_shift
            plan = d["proposal"]
            assert plan["unsold_stock"] == opening_output
            required = expected if prescribed else max(0, expected - opening_output)
            assert plan["required_output"] == required, "production must apply exactly its treatment's stock-offset rule"
            assert plan["requested_shifts"] == (required + per_shift - 1) // per_shift
            assert 0 <= plan["planned_shifts"] <= plan["requested_shifts"]
            assert len(plan["workers"]) == plan["planned_shifts"] and plan["planned_output"] == plan["planned_shifts"] * per_shift
            assert execution["cash_after"] == state["entities"][target]["money"]
            assert execution["output_stock_after"] == state["entities"][target]["inventory"][item]
            for receipt_id in execution["work_event_ids"]:
                receipt = history[receipt_id - 1]
                assert receipt_id not in employer_work and receipt_id < index and receipt["success"] and receipt["action"] == "work_shift" and receipt["target"] == target
                assert receipt["day"] == state["day"] and receipt["actor"] in d["proposal"]["workers"]
                employer_work.add(receipt_id)
        if event["success"]:
            if action == "owner_withdrawal":
                assert state["businesses"][target]["owner"] == actor
                amount, source = d["amount"], state["entities"][target]
                reserve = operating_reserve(state, target)
                assert type(amount) is int and 0 < amount <= 1_000_000_000
                assert d["operating_reserve"] == reserve and d["distributable_before"] == max(0, source["money"] - reserve)
                assert source["money"] - amount >= reserve
                source["money"] -= amount
                state["entities"][actor]["money"] += amount
                assert d["business_cash_after"] == source["money"]
                flows[actor]["earned"] += amount
                flows[actor]["owner_withdrawals_received"] += amount
                flows[target]["spent"] += amount
                flows[target]["owner_withdrawals_paid"] += amount
                circulation += amount
                no_shift = int(state["labor_used"].get(actor, 0) == 0)
                withdrawals["amount"] += amount
                withdrawals["without_shift"] += no_shift
                firm = withdrawals["by_business"][target]
                firm["amount"] += amount
                firm["without_shift"] += no_shift
                firm["last_distribution_day"] = state["day"]
                previous = firm["minimum_cash_after_withdrawal"]
                firm["minimum_cash_after_withdrawal"] = source["money"] if previous is None else min(previous, source["money"])
            elif action == "labor_environment":
                eligible = {w for firm in state["businesses"].values() if firm["industry"] == "farmer"
                            for w in [firm["owner"]] + firm["employees"]}
                assert set(d["opportunities"]) == eligible and all(type(n) is int and 2 <= n <= 6 for n in d["opportunities"].values())
                assert not state["harvest_opportunities"]
                state["harvest_opportunities"] = copy.deepcopy(d["opportunities"])
                potential_wheat += sum(amount for worker, amount in d["opportunities"].items()
                                       if not profitable or worker in state["employment"])
            elif action == "shift_offered":
                offer = d["offer"]
                assert state["businesses"][target]["owner"] == actor and offer["id"] not in state["offers"]
                assert offer["day"] == state["day"] and offer["business"] == target and offer["status"] == "offered"
                state["offers"][offer["id"]] = copy.deepcopy(offer)
            elif action == "work_shift":
                firm, person = state["businesses"][target], state["entities"][actor]
                if profitable:
                    roster = sorted(firm["employees"])
                    pair = ((0, 2), (0, 1), (1, 2))[(state["day"] - 1) % 3]
                    assert actor != firm["owner"] and actor in [roster[i] for i in pair]
                offer = state["offers"][d["offer_id"]]
                assert offer["status"] == "offered" and offer["worker"] == actor and offer["business"] == target
                assert offer["day"] == state["day"] and offer["industry"] == firm["industry"]
                wage = firm["owner_compensation"]
                if actor != firm["owner"]:
                    job = state["employment"][actor]
                    assert job["active"] and job["business"] == target and actor in firm["employees"]
                    wage = job["wage"]
                assert person["kind"] == "resident" and firm["industry"] in person["skills"]
                assert d["labor"] == 1 and offer["labor"] == 1 and wage == d["wage"] == offer["wage"] > 0
                assert state["labor_used"].get(actor, 0) < person["labor_capacity"]
                assert state["business_labor"].get(target, 0) < firm["assets"]["daily_slots"]
                pay_id, production_id = d["payment_event_id"], d["production_event_id"]
                assert (pay_id, production_id) == (index - 2, index - 1)
                assert pay_id not in claimed and production_id not in claimed
                pay, production = history[pay_id - 1], history[production_id - 1]
                assert pay["success"] and pay["action"] == "transfer_money" and pay["actor"] == target and pay["target"] == actor and pay["details"]["amount"] == wage
                assert production["success"] and production["actor"] == target and production["day"] == state["day"]
                if firm["industry"] == "farmer":
                    assert production["action"] == "harvest" and production["details"]["amount"] == state["harvest_opportunities"][actor]
                else:
                    assert production["action"] == "produce"
                    assert production["details"]["recipe"] == ("mill" if firm["industry"] == "miller" else "bake")
                    assert production["details"]["batches"] == firm["assets"]["batches_per_shift"] == 2
                claimed.update((pay_id, production_id))
                state["labor_used"][actor] = state["labor_used"].get(actor, 0) + 1
                state["business_labor"][target] = state["business_labor"].get(target, 0) + 1
                offer["status"] = "accepted"
                flows[actor]["shifts"] += 1
                flows[target]["shifts"] += 1
                flows[actor]["last_work_day"] = state["day"]
            elif action == "purchase":
                item, q, price = d["item"], d["quantity"], d["unit_price"]
                assert type(q) is int and q > 0 and price == report["prices"][item] and q * price == d["total_price"]
                assert OUTPUTS[state["businesses"][target]["industry"]] == item
                assert item == (INPUTS[state["businesses"][actor]["industry"]] if actor in state["businesses"] else "bread")
                sales_key = (state["day"], target, item)
                sales_by_day[sales_key] = sales_by_day.get(sales_key, 0) + q
                state["entities"][actor]["inventory"][item] += q
                state["entities"][target]["inventory"][item] -= q
                state["entities"][actor]["money"] -= q * price
                state["entities"][target]["money"] += q * price
                if profitable:
                    state["cash_results"][target]["sales"] += q * price
                    if actor in state["cash_results"]:
                        state["cash_results"][actor]["inputs"] += q * price
                flows[actor]["spent"] += q * price
                flows[actor]["purchases"] += q * price
                flows[target]["earned"] += q * price
                flows[target]["sales"] += q * price
                flows[target]["last_business_day"] = state["day"]
                if actor in state["businesses"]:
                    flows[actor]["last_business_day"] = state["day"]
                circulation += q * price
            elif action == "transfer_money":
                assert type(d["amount"]) is int and d["amount"] > 0
                distribution = profitable and state["businesses"][actor]["owner"] == target
                if profitable:
                    profit_before[index] = (state["entities"][actor]["money"], copy.deepcopy(state["cash_results"][actor]))
                    state["cash_results"][actor]["distributions" if distribution else "payroll"] += d["amount"]
                state["entities"][actor]["money"] -= d["amount"]
                state["entities"][target]["money"] += d["amount"]
                flows[actor]["spent"] += d["amount"]
                flows[actor]["profit_distributions_paid" if distribution else "wages_paid"] += d["amount"]
                flows[target]["earned"] += d["amount"]
                flows[target]["profit_distributions_received" if distribution else "wages_received"] += d["amount"]
                circulation += d["amount"]
                economic_receipts.add(index)
            elif action in ("harvest", "produce"):
                assert actor in state["businesses"]
                if action == "harvest":
                    inputs, outputs = {}, {"wheat": d["amount"]}
                    assert state["businesses"][actor]["industry"] == "farmer"
                    totals["harvested"]["wheat"] += d["amount"]
                else:
                    inputs, outputs = RECIPES[d["recipe"]]
                    assert d["batches"] == 2 and d["inputs"] == inputs and d["outputs"] == outputs
                    for item, amount in inputs.items():
                        totals["production_inputs"][item] += amount
                    for item, amount in outputs.items():
                        totals["production_outputs"][item] += amount
                for item, amount in inputs.items():
                    state["entities"][actor]["inventory"][item] -= amount
                for item, amount in outputs.items():
                    state["entities"][actor]["inventory"][item] += amount
                    flows[actor]["produced"][item] += amount
                flows[actor]["last_production_day"] = flows[actor]["last_business_day"] = state["day"]
                economic_receipts.add(index)
            elif action == "consume":
                assert actor not in state["businesses"] and actor not in state["meals"] and d["amount"] == 1
                state["entities"][actor]["inventory"]["bread"] -= 1
                state["meals"][actor] = True
                flows[actor]["consumed"] += 1
                totals["consumed"]["bread"] += 1
            elif profitable and action == "profit_distribution":
                assert state["businesses"][target]["owner"] == actor
                receipt_id = d["payment_event_id"]
                receipt = history[receipt_id - 1]
                cash, book = profit_before[receipt_id]
                realized = book["sales"] - book["inputs"] - book["payroll"] - book["distributions"]
                assert d["amount"] == max(0, min(realized, cash - 120)) > 0
                assert receipt_id == index - 1 and receipt_id not in claimed and receipt["success"]
                assert receipt["action"] == "transfer_money" and receipt["actor"] == target and receipt["target"] == actor and receipt["details"]["amount"] == d["amount"]
                assert d["capital_floor"] == 120 and d["cash_before"] == cash and d["realized_before"] == realized and d["cumulative_before"] == book
                assert state["entities"][target]["money"] == d["business_cash_after"] >= 120
                claimed.add(receipt_id)
                income["transactions"] += 1
                income["amount"] += d["amount"]
            elif profitable and action == "contract_due":
                roster = sorted(state["businesses"][target]["employees"])
                pair = ((0, 2), (0, 1), (1, 2))[(state["day"] - 1) % 3]
                assert actor in [roster[i] for i in pair] and actor not in contract_due and d["expected_compensation"] == 6
                contract_due[actor] = target
            elif profitable and action == "contract_day_closed":
                assert not state["contract_day_closed"] and len(contract_due) == len(contract_outcomes) == d["due"] == 6
                assert d["completed"] == sum(contract_outcomes.values()) and d["breaches"] == 6 - d["completed"]
                assert d["cash_results"] == state["cash_results"]
                assert d["household_cash"] == {a: p["money"] for a, p in state["entities"].items() if a not in state["businesses"]}
                assert d["business_cash"] == {a: state["entities"][a]["money"] for a in state["businesses"]}
                assert d["goods"] == {item: sum(p["inventory"][item] for p in state["entities"].values()) for item in ITEMS}
                state["contract_day_closed"] = True
            else:
                assert action in ("initialize", "day_started", "labor_decision", "employer_plan", "contract_attempt", "contract_shift"), action
        assert sum(e["money"] for e in state["entities"].values()) == initial_money
        for entity in state["entities"].values():
            assert type(entity["money"]) is int and 0 <= entity["money"] <= 1_000_000_000
            assert all(type(v) is int and 0 <= v <= 1_000_000_000 for v in entity["inventory"].values())
    assert claimed == economic_receipts, "every payroll/production receipt must fund one real shift"
    if "employers" in report:
        assert employer_work == native_employer_work, "every actual shift belongs to one employer decision"
        assert len(employer_turns) == report["days"] * 3
    assert state == report["final"] and flows == report["accounts"] and totals == report["totals"]
    assert unmet == report["unmet_meals"] and shifts == report["shifts"] and purchases == report["purchases"]
    assert decisions == report["decisions"]
    assert failures == report["failures"] and notable == report["notable_events"]
    if finance:
        for business, firm in withdrawals["by_business"].items():
            firm["distributable_final"] = max(0, state["entities"][business]["money"] - operating_reserve(state, business))
        settings = report["finance"]
        assert settings == dict(policy=settings["policy"], payout_divisor=PAYOUTS[settings["policy"]],
                                reserve_days=2, household_meals=2, withdrawals=withdrawals)
    assert report["money"] == dict(initial=initial_money, final=initial_money, circulation=circulation)
    if profitable:
        assert report["profitable"]["contracts"] == contract_totals and report["profitable"]["distributions"] == income
        assert report["profitable"]["cash_results"] == state["cash_results"]
    assert report["potential"]["wheat"] == potential_wheat
    mill_capacity, bake_capacity = (12, 18) if profitable else (16, 24)
    assert report["potential"]["bread_including_initial_bound"] == min((min(potential_wheat + initial_stock["wheat"], state["day"] * mill_capacity) + initial_stock["flour"]) // 2 * 3, state["day"] * bake_capacity) + initial_stock["bread"]
    for actor, p in state["entities"].items():
        assert p["money"] == report["initial"]["entities"][actor]["money"] + flows[actor]["earned"] - flows[actor]["spent"]
        if actor in unmet:
            assert flows[actor]["consumed"] + unmet[actor] == state["day"]
    for item in ITEMS:
        actual = sum(e["inventory"][item] for e in state["entities"].values())
        expected = initial_stock[item] + totals["harvested"].get(item, 0) + totals["production_outputs"].get(item, 0) - totals["production_inputs"].get(item, 0) - totals["consumed"].get(item, 0)
        assert actual == expected, (item, actual, expected)
    for firm, activity in report["business_activity"].items():
        assert activity == dict(production_idle_days_at_end=state["day"] - flows[firm]["last_production_day"],
                                business_idle_days_at_end=state["day"] - flows[firm]["last_business_day"],
                                can_fund_one_shift=state["entities"][firm]["money"] >= (6 if profitable else state["businesses"][firm]["owner_compensation"]))


def tables(data, digest):
    r = data["report"]
    run = dict(seed=r["seed"], days=r["days"], potential_wheat=r["potential"]["wheat"],
               harvested=r["totals"]["harvested"]["wheat"], flour=r["totals"]["production_outputs"]["flour"],
               bread=r["totals"]["production_outputs"]["bread"], meals=r["totals"]["consumed"]["bread"], unmet=sum(r["unmet_meals"].values()),
               **r["shifts"], purchases=r["purchases"]["successful"], failed_purchases=r["purchases"]["rejected"],
               money=r["money"]["final"], circulation=r["money"]["circulation"], events=r["event_count"], sha256=digest)
    if "finance" in r:
        run.update(distribution=r["finance"]["policy"], **{"withdrawals_" + k: v for k, v in r["finance"]["withdrawals"].items() if k != "by_business"})
    people, businesses = [], []
    owners = {b["owner"] for b in r["final"]["businesses"].values()}
    for actor, entity in sorted(r["final"]["entities"].items()):
        account = r["accounts"][actor]
        row = dict(seed=r["seed"], days=r["days"], actor=actor, name=entity["name"], role=entity["role"],
                   coins=entity["money"], **entity["inventory"], **{k: v for k, v in account.items() if k not in ("produced", "schedule_reasons")})
        if "finance" in r:
            row["distribution"] = r["finance"]["policy"]
        if entity["kind"] == "resident":
            row.update(owner=actor in owners, employer=r["final"]["employment"].get(actor, {}).get("business", "own_business"), unmet=r["unmet_meals"][actor])
            people.append(row)
        else:
            row.update({"produced_" + k: v for k, v in account["produced"].items()})
            row.update(r["business_activity"][actor])
            row["schedule_reasons"] = json.dumps(account["schedule_reasons"], sort_keys=True)
            if "finance" in r:
                row.update({"distribution_" + k: v for k, v in r["finance"]["withdrawals"]["by_business"][actor].items()})
            businesses.append(row)
    return run, people, businesses


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--study", choices=("m9", "m10"), default="m9")
    parser.add_argument("--baseline", type=Path, help="M10 only: reuse M9 captures after published-hash verification")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    args.output = args.output or Path("work") / args.study
    if args.baseline and (args.study != "m10" or args.baseline.resolve() == args.output.resolve()):
        parser.error("--baseline requires --study m10 and a separate output directory")
    args.output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, XDG_DATA_HOME=str(args.output.resolve() / "data"), XDG_CACHE_HOME=str(args.output.resolve() / "cache"))
    command = [args.godot, "--headless", "--no-header", "--path", str(Path(__file__).resolve().parents[2]),
               "--script", "res://scripts/tools/run_simulation.gd", "--"]
    published = {}
    if args.study == "m10":
        with (Path(__file__).resolve().parents[2] / "docs/M9_RUNS.csv").open() as handle:
            published = {(int(r["seed"]), int(r["days"])): r["sha256"] for r in csv.DictReader(handle)}
    runs, people, businesses = [], [], []
    for seed in (7, 42, 99):
        for days in (30, 365):
            baseline = None
            environment = None
            if args.study == "m10":
                path = f"settlement_labor-{seed}-{days}.json"
                if args.baseline:
                    payload = (args.baseline / path).read_bytes()
                else:
                    captured = subprocess.run(command + ["--scenario", "settlement_labor", str(days), str(seed), "--json"],
                                              env=env, capture_output=True, check=True, timeout=180)
                    assert not captured.stderr, captured.stderr
                    payload = captured.stdout
                assert hashlib.sha256(payload).hexdigest() == published[seed, days], "M9 baseline hash mismatch"
                baseline = json.loads(payload)
                audit(baseline)
                (args.output / ("m9-" + path)).write_bytes(payload)
                environment = [e["details"] for e in baseline["events"] if e["action"] == "labor_environment"]
            for policy in (PAYOUTS if args.study == "m10" else (None,)):
                scenario = "settlement_finance" if policy is not None else "settlement_labor"
                cli = command + ["--scenario", scenario] + (["--distribution", policy] if policy is not None else []) + [str(days), str(seed), "--json"]
                first = subprocess.run(cli, env=env, capture_output=True, check=True, timeout=180)
                second = subprocess.run(cli, env=env, capture_output=True, check=True, timeout=180)
                assert not first.stderr and not second.stderr, (first.stderr, second.stderr)
                assert first.stdout == second.stdout, (policy, seed, days, "replay mismatch")
                data = json.loads(first.stdout)
                audit(data)
                digest = hashlib.sha256(first.stdout).hexdigest()
                case_name = scenario + ("-" + policy if policy is not None else "")
                (args.output / f"{case_name}-{seed}-{days}.json").write_bytes(first.stdout)
                run, npc_rows, business_rows = tables(data, digest)
                if baseline is not None:
                    assert [e["details"] for e in data["events"] if e["action"] == "labor_environment"] == environment, "matched opportunities"
                    if policy == "none":
                        assert data["events"] == baseline["events"] and legacy_report(data["report"]) == baseline["report"], "unchanged M9 control"
                    run["baseline_sha256"] = published[seed, days]
                    run["environment_hash"] = hashlib.sha256(json.dumps(environment, sort_keys=True).encode()).hexdigest()
                runs.append(run)
                people.extend(npc_rows)
                businesses.extend(business_rows)
                prefix = (seed, days) if policy is None else (case_name, seed, days)
                print(*prefix, "meals", run["meals"], "unmet", run["unmet"], "paid shifts", run["paid"], "audited/replayed", flush=True)
    for name, records in (("runs", runs), ("residents", people), ("businesses", businesses)):
        with (args.output / (name + ".csv")).open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(records[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(records)


if __name__ == "__main__":
    main()
