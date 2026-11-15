#!/usr/bin/env python3
"""Fixed M13 2×2 study: compact reports, independent process replay, matched controls."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess

from run_labor import tables

CONDITIONS = {
    "settlement_equilibrium_reference": ("prescribed", "rotating"),
    "settlement_fixed_owner_first": ("prescribed", "owner_first"),
    "settlement_sales_rotating": ("sales", "rotating"),
    "settlement_employer_choice": ("sales", "owner_first"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path, default=Path("work/m13"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    root = Path(__file__).resolve().parents[2]
    env = dict(os.environ, XDG_DATA_HOME=str(args.output.resolve() / "data"),
               XDG_CONFIG_HOME=str(args.output.resolve() / "config"), XDG_CACHE_HOME=str(args.output.resolve() / "cache"))
    cli = [args.godot, "--headless", "--no-header", "--path", str(root), "--script", "res://scripts/tools/run_simulation.gd", "--"]
    published = {}
    for milestone in (11, 12):
        with (root / f"docs/M{milestone}_RUNS.csv").open() as handle:
            for row in csv.DictReader(handle):
                scenario = row.get("scenario", "settlement_equilibrium_reference")
                published[scenario, int(row["days"])] = row["summary_sha256"]
    runs, residents, businesses = [], [], []
    initial = None
    for days in (2, 7, 30, 365):
        for scenario, (production, staffing) in CONDITIONS.items():
            command = cli + ["--scenario", scenario, str(days), "42", "--study-json"]
            first = subprocess.run(command, env=env, capture_output=True, check=True, timeout=90)
            replay = subprocess.run(command, env=env, capture_output=True, check=True, timeout=90)
            assert not first.stderr and not replay.stderr, (first.stderr, replay.stderr)
            assert first.stdout == replay.stdout, (scenario, days, "replay mismatch")
            data = json.loads(first.stdout)
            r, d = data["report"], data["diagnostics"]
            assert "events" not in data and d["currency_after_every_event"] and d["accounting_and_labor_verified"]
            if initial is None:
                initial = r["initial"]
            assert r["initial"] == initial and r["final"]["employment"] == initial["employment"]
            assert r["money"]["final"] == 432
            assert r["totals"]["consumed"]["bread"] + sum(r["unmet_meals"].values()) == 12 * days
            if (scenario, days) in published:
                assert data["summary_sha256"] == published[scenario, days], "historical control changed"
            (args.output / f"{scenario}-{days}-study.json").write_bytes(first.stdout)
            run, people, firms = tables(data, data["summary_sha256"])
            run["summary_sha256"] = run.pop("sha256")
            run.update(study_sha256=hashlib.sha256(first.stdout).hexdigest(), ledger_sha256=data["ledger_sha256"],
                       economic_sha256=d["economic_sha256"])
            owners = {b["owner"] for b in initial["businesses"].values()}
            employees = set(initial["employment"])
            run.update(owner_wages=sum(r["accounts"][a]["wages_received"] for a in owners),
                       employee_wages=sum(r["accounts"][a]["wages_received"] for a in employees),
                       business_cash=sum(r["final"]["entities"][a]["money"] for a in initial["businesses"]),
                       owner_cash=sum(r["final"]["entities"][a]["money"] for a in owners),
                       employee_cash=sum(r["final"]["entities"][a]["money"] for a in employees),
                       residents_without_shifts=sum(r["accounts"][a]["shifts"] == 0 for a in owners | employees))
            for field in ("first_unmet_meal_day", "first_bread_stock_shortage_day", "first_financial_constraint_day",
                          "first_sustained_inactivity_day", "trailing_inactivity_start", "unmet_with_bread_unsold",
                          "unaffordable_food_turns_with_stock", "food_turns_without_stock"):
                run[field] = d[field]
            for firm in firms:
                for key, value in d["by_business"][firm["actor"]].items():
                    if key == "plans_first_eight_days":
                        continue
                    firm["plan_" + key] = json.dumps(value, sort_keys=True) if isinstance(value, dict) else value
            for row in [run] + people + firms:
                row.update(scenario=scenario, production_rule=production, staffing_rule=staffing)
            runs.append(run)
            residents.extend(people)
            businesses.extend(firms)
            print(scenario, days, "meals", run["meals"], "missed", run["unmet"], "shifts", run["paid"],
                  "first cash short", d["first_financial_constraint_day"], "audited/replayed", flush=True)
    for name, rows in (("runs", runs), ("residents", residents), ("businesses", businesses)):
        with (args.output / (name + ".csv")).open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    main()
