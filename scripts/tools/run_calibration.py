#!/usr/bin/env python3
"""Run the fixed M7 matrix twice, audit ledgers, and save compact result tables.

From the repository root: python3 scripts/tools/run_calibration.py --output work/m7
Uses only the standard library and the installed Godot executable.
"""
import argparse
import copy
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess

EXPERIMENTS = ("baseline", "higher_productivity", "higher_target", "lower_food_price", "higher_wage", "extra_liquidity")
ITEMS = ("wheat", "flour", "bread")


def audit(data):
    report, history = data["report"], data["events"]
    state = copy.deepcopy(history[0]["details"]["state"])
    total = sum(p["money"] for p in state["entities"].values())
    receipts, before = set(), {}
    counts = {actor: dict(earned=0, spent=0, consumed=0, unmet=0, affordable=0, owned=0,
                         produced=dict.fromkeys(ITEMS, 0), bought=dict.fromkeys(ITEMS, 0),
                         sold=dict.fromkeys(ITEMS, 0)) for actor in state["entities"]}
    for index, event in enumerate(history, 1):
        assert event["id"] == index
        action, actor, target, d = (event[k] for k in ("action", "actor", "target", "details"))
        if action == "day_started":
            state["day"] += 1
        assert event["day"] == state["day"]
        if action == "decision" and d["phase"] == "food":
            person = before[d["command_event_id"]] if d["command_event_id"] is not None else state["entities"][actor]
            counts[actor]["affordable"] += person["money"] >= report["prices"]["bread"]
            counts[actor]["owned"] += person["inventory"]["bread"] > 0
        if action == "consume" and not event["success"]:
            counts[actor]["unmet"] += d["amount"]
        if actor in state["entities"]:
            before[index] = copy.deepcopy(state["entities"][actor])
        if event["success"]:
            if action == "purchase":
                item, quantity, amount = d["item"], d["quantity"], d["total_price"]
                assert d["unit_price"] == report["prices"][item] and amount == quantity * d["unit_price"]
                state["entities"][actor]["inventory"][item] += quantity
                state["entities"][target]["inventory"][item] -= quantity
                state["entities"][actor]["money"] -= amount
                state["entities"][target]["money"] += amount
                counts[actor]["spent"] += amount
                counts[target]["earned"] += amount
                counts[actor]["bought"][item] += quantity
                counts[target]["sold"][item] += quantity
            elif action == "transfer_money":
                state["entities"][actor]["money"] -= d["amount"]
                state["entities"][target]["money"] += d["amount"]
                counts[actor]["spent"] += d["amount"]
                counts[target]["earned"] += d["amount"]
            elif action == "transfer_item":
                state["entities"][actor]["inventory"][d["item"]] -= d["amount"]
                state["entities"][target]["inventory"][d["item"]] += d["amount"]
            elif action == "harvest":
                assert actor == "farmer" and d["amount"] == report["potential"]["underlying_draws"][event["day"] - 1] + report["configuration"]["harvest_bonus"]
                state["entities"][actor]["inventory"][d["item"]] += d["amount"]
                counts[actor]["produced"][d["item"]] += d["amount"]
            elif action == "produce":
                for item, amount in d["inputs"].items():
                    state["entities"][actor]["inventory"][item] -= amount
                for item, amount in d["outputs"].items():
                    state["entities"][actor]["inventory"][item] += amount
                    counts[actor]["produced"][item] += amount
            elif action == "consume":
                state["entities"][actor]["inventory"][d["item"]] -= d["amount"]
                counts[actor]["consumed"] += d["amount"]
            elif action in ("request_posted", "agreement_accepted", "agreement_fulfilled", "request_closed"):
                request = d["request"]
                previous = state["requests"].get(request["id"])
                if action == "request_posted":
                    assert previous is None and request["status"] == "open"
                    assert request["payment"] == request["quantity"] * report["prices"][request["item"]]
                else:
                    for key in ("id", "buyer", "item", "quantity", "unit_price", "payment", "created_day"):
                        assert previous[key] == request[key]
                    if action in ("agreement_accepted", "agreement_fulfilled"):
                        accepting = action == "agreement_accepted"
                        assert previous["status"] == ("open" if accepting else "accepted")
                        assert request["status"] == ("accepted" if accepting else "fulfilled")
                        receipt = d["payment_event_id" if accepting else "item_event_id"]
                        assert receipt not in receipts and receipt < index
                        receipts.add(receipt)
                        command = history[receipt - 1]
                        assert command["success"] and command["actor"] == request["buyer" if accepting else "supplier"]
                        assert command["target"] == request["supplier" if accepting else "buyer"]
                        assert command["action"] == ("transfer_money" if accepting else "transfer_item")
                        assert command["details"]["amount"] == request["payment" if accepting else "quantity"]
                        if not accepting:
                            assert command["details"]["item"] == request["item"]
                state["requests"][request["id"]] = copy.deepcopy(request)
            elif action == "agreement_outstanding":
                assert state["requests"][d["request"]["id"]] == d["request"]
            else:
                assert action in ("initialize", "day_started", "decision"), action
        assert sum(p["money"] for p in state["entities"].values()) == total
        assert all(type(p["money"]) is int and 0 <= p["money"] <= 10**9
                   and all(type(n) is int and 0 <= n <= 10**9 for n in p["inventory"].values()) for p in state["entities"].values())
    assert state == report["final"]
    business = {actor: set() for actor in counts}
    work = {actor: set() for actor in counts}
    active = set()
    for event in history:
        if not event["success"]:
            continue
        if event["action"] in ("harvest", "produce"):
            work[event["actor"]].add(event["day"])
        if event["action"] in ("harvest", "produce", "purchase", "agreement_accepted", "agreement_fulfilled"):
            active.add(event["day"])
            business[event["actor"]].add(event["day"])
            if event["target"] in business:
                business[event["target"]].add(event["day"])
    for actor, actual in counts.items():
        flow, person, metric = report["cash_flow"][actor], report["participants"][actor], report["calibration"]["per_npc"][actor]
        assert flow["earned"] == actual["earned"] and flow["spent"] == actual["spent"]
        assert person["produced"] == actual["produced"] and person["spot_bought"] == actual["bought"] and person["spot_sold"] == actual["sold"]
        assert person["consumed"] == actual["consumed"] and person["unmet_meals"] == actual["unmet"]
        assert actual["consumed"] + actual["unmet"] == report["days"]
        assert metric["cash_affordable_food_days"] == actual["affordable"] and metric["owned_food_days"] == actual["owned"]
        assert metric["business_inactive_days"] == report["days"] - len(business[actor])
        assert metric["trailing_business_inactive_days"] == report["days"] - max(business[actor], default=0)
        assert metric["last_business_day"] == max(business[actor], default=None)
        assert metric["last_production_day"] == max(work[actor], default=None)
        assert metric["production_idle_days"] == (None if state["entities"][actor]["role"] == "laborer" else report["days"] - len(work[actor]))
    metric = report["calibration"]
    largest = max(p["money"] for p in state["entities"].values())
    assert metric["business_inactive_days"] == report["days"] - len(active)
    assert metric["cash_circulation"] == sum(p["earned"] for p in counts.values())
    assert metric["wealth"]["total_money"] == total and metric["wealth"]["largest_balance"] == largest
    assert metric["wealth"]["share_basis_points"] == (largest * 10000 // total if total else 0)
    assert report["totals"]["production_outputs"]["bread"] <= report["potential"]["bread_upper_bound"]
    assert report["totals"]["consumed"]["bread"] <= report["potential"]["timely_meals_upper_bound"]


def rows(report, digest):
    c, p, a, t = (report[k] for k in ("calibration", "potential", "agreements", "totals"))
    common = dict(experiment=report["experiment"], seed=report["seed"], days=report["days"])
    run = dict(common, wheat=t["harvested"]["wheat"], flour=t["production_outputs"]["flour"],
               bread=t["production_outputs"]["bread"], potential_wheat=p["opportunity_wheat"],
               potential_bread=p["bread_upper_bound"], timely_meals_upper_bound=p["timely_meals_upper_bound"],
               meals=t["consumed"]["bread"], unmet=sum(report["unmet_meals"].values()),
               purchases_ok=report["purchases"]["successful"], purchases_failed=report["purchases"]["rejected"],
               agreements=a["made"], fulfilled=a["fulfilled"], outstanding=a["outstanding"], prepaid=a["prepaid"],
               wages_paid=report["payments"]["amount"], wages_ok=report["payments"]["successful"], wages_failed=report["payments"]["rejected"],
               circulation=c["cash_circulation"], total_money=c["wealth"]["total_money"],
               richest=";".join(c["wealth"]["holders"]), largest_balance=c["wealth"]["largest_balance"],
               top_share_basis_points=c["wealth"]["share_basis_points"], business_inactive_days=c["business_inactive_days"],
               environment_hash=p["underlying_draws_hash"], sha256=digest)
    people = []
    for actor in report["schedule"]:
        entity, flow, person, metric = (report["final"]["entities"][actor], report["cash_flow"][actor],
                                        report["participants"][actor], c["per_npc"][actor])
        row = dict(common, actor=actor, name=entity["name"], role=entity["role"], money=entity["money"],
                   eaten=person["consumed"], unmet=person["unmet_meals"], **flow, **metric)
        for label, quantities in (("inventory", entity["inventory"]), ("produced", person["produced"]),
                                  ("spot_bought", person["spot_bought"]), ("spot_sold", person["spot_sold"]),
                                  ("agreement_delivered", person["agreement_delivered"])):
            row.update({label + "_" + item: amount for item, amount in quantities.items()})
        for key in ("purchases_successful", "purchases_failed", "sales_successful", "sales_failed",
                    "agreements_accepted", "agreements_fulfilled", "agreements_outstanding"):
            row[key] = person[key]
        row["selected_suppliers"] = json.dumps(person["selected_suppliers"], sort_keys=True, separators=(",", ":"))
        people.append(row)
    return run, people


def write_csv(path, records):
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(records[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path, default=Path("work/m7"))
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, XDG_DATA_HOME=str(output / "data"), XDG_CACHE_HOME=str(output / "cache"))
    command = [args.godot, "--headless", "--no-header", "--path", str(Path(__file__).resolve().parents[2]),
               "--script", "res://scripts/tools/run_simulation.gd", "--"]
    runs, people = [], []
    for seed in (7, 42, 99):
        for days in (30, 365):
            baseline = None
            for experiment in EXPERIMENTS:
                cli = command + ["--scenario", "calibration", "--experiment", experiment, str(days), str(seed), "--json"]
                first = subprocess.run(cli, env=env, capture_output=True, check=True)
                second = subprocess.run(cli, env=env, capture_output=True, check=True)
                assert not first.stderr and not second.stderr, (first.stderr, second.stderr)
                assert first.stdout == second.stdout, (experiment, seed, days, "replay")
                (output / f"{experiment}-{seed}-{days}.json").write_bytes(first.stdout)
                data = json.loads(first.stdout)
                audit(data)
                report = data["report"]
                run, participants = rows(report, hashlib.sha256(first.stdout).hexdigest())
                if experiment == "baseline":
                    baseline = run
                    legacy = subprocess.run(command + ["--scenario", "market_downstream", str(days), str(seed), "--json"],
                                            env=env, capture_output=True, check=True)
                    assert not legacy.stderr and json.loads(legacy.stdout)["events"] == data["events"], "M6B baseline equivalence"
                assert run["environment_hash"] == baseline["environment_hash"], "matched environmental opportunities"
                for key in ("meals", "bread", "circulation", "top_share_basis_points"):
                    run["delta_" + key] = run[key] - baseline[key]
                runs.append(run)
                people.extend(participants)
                print(experiment, seed, days, "meals", run["meals"], "unmet", run["unmet"], "audited/replayed", flush=True)
    write_csv(output / "runs.csv", runs)
    write_csv(output / "npcs.csv", people)


if __name__ == "__main__":
    main()
