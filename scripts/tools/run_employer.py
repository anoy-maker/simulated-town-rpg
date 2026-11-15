#!/usr/bin/env python3
"""M12's fixed seed-42 comparison; save compact reports/tables, never annual event dumps."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess

from run_labor import tables


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path, default=Path("work/m12"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, XDG_DATA_HOME=str(args.output.resolve() / "data"), XDG_CACHE_HOME=str(args.output.resolve() / "cache"))
    root = Path(__file__).resolve().parents[2]
    command = [args.godot, "--headless", "--no-header", "--path", str(root), "--script", "res://scripts/tools/run_simulation.gd", "--"]
    with (root / "docs/M11_RUNS.csv").open() as handle:
        published = {int(r["days"]): r["summary_sha256"] for r in csv.DictReader(handle)}
    runs, residents, businesses = [], [], []
    for days in (2, 30, 365):
        for scenario in ("settlement_equilibrium_reference", "settlement_employer_choice"):
            cli = command + ["--scenario", scenario, str(days), "42", "--report-json"]
            first = subprocess.run(cli, env=env, capture_output=True, check=True, timeout=60)
            second = subprocess.run(cli, env=env, capture_output=True, check=True, timeout=60)
            assert not first.stderr and not second.stderr, (first.stderr, second.stderr)
            assert first.stdout == second.stdout, (scenario, days, "replay mismatch")
            digest = hashlib.sha256(first.stdout).hexdigest()
            data = json.loads(first.stdout)
            assert "events" not in data
            r = data["report"]
            if scenario == "settlement_equilibrium_reference":
                assert digest == published[days], "historical M11 control changed"
            (args.output / f"{scenario}-{days}-summary.json").write_bytes(first.stdout)
            run, people, firms = tables(data, digest)
            run["summary_sha256"] = run.pop("sha256")
            meta = r.get("employers", r.get("reference"))
            run["ledger_sha256"] = meta["ledger_sha256"]
            owners = {b["owner"] for b in r["initial"]["businesses"].values()}
            run["owner_wages"] = sum(r["accounts"][a]["wages_received"] for a in owners)
            run["employee_wages"] = r["shifts"]["wages"] - run["owner_wages"]
            run["household_needs"] = days * 12
            for field in ("first_unmet_meal_day", "first_bread_stock_shortage_day", "first_sustained_inactivity_day", "trailing_inactivity_start", "unmet_with_bread_unsold"):
                run[field] = meta.get(field)
            for row in [run] + people + firms:
                row["scenario"] = scenario
            runs.append(run)
            residents.extend(people)
            businesses.extend(firms)
            print(scenario, days, "meals", run["meals"], "missed", run["unmet"], "paid shifts", run["paid"], "compact replay verified", flush=True)
    for name, rows in (("runs", runs), ("residents", residents), ("businesses", businesses)):
        with (args.output / (name + ".csv")).open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    main()
