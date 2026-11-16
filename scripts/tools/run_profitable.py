#!/usr/bin/env python3
"""Run M14's five prescribed horizons twice; retain compact reports and CSVs only."""
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
    parser.add_argument("--output", type=Path, default=Path("work/m14"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    root = Path(__file__).resolve().parents[2]
    env = dict(os.environ, XDG_DATA_HOME=str(args.output.resolve() / "data"),
               XDG_CONFIG_HOME=str(args.output.resolve() / "config"), XDG_CACHE_HOME=str(args.output.resolve() / "cache"))
    command = [args.godot, "--headless", "--no-header", "--path", str(root), "--script", "res://scripts/tools/run_simulation.gd", "--"]
    runs, residents, businesses = [], [], []
    for days in (1, 2, 3, 30, 365):
        cli = command + ["--scenario", "settlement_profitable_reference", str(days), "42", "--report-json"]
        first = subprocess.run(cli, env=env, capture_output=True, check=True, timeout=90)
        replay = subprocess.run(cli, env=env, capture_output=True, check=True, timeout=90)
        assert not first.stderr and not replay.stderr, (first.stderr, replay.stderr)
        assert first.stdout == replay.stdout, (days, "independent-process replay mismatch")
        data = json.loads(first.stdout)
        r = data["report"]
        assert "events" not in data
        for group in ("accounting", "reference"):
            assert all(r["profitable"]["verification"][group].values()), (days, r["profitable"]["verification"])
        assert r["money"]["final"] == 432 and r["shifts"]["paid"] == 6 * days and r["shifts"]["wages"] == 36 * days
        assert r["totals"]["consumed"]["bread"] == 12 * days and not any(r["unmet_meals"].values())
        assert r["profitable"]["distributions"]["amount"] == 12 * days and r["profitable"]["contracts"]["breaches"] == 0
        digest = hashlib.sha256(first.stdout).hexdigest()
        (args.output / f"reference-{days}-summary.json").write_bytes(first.stdout)
        run, people, firms = tables(data, digest)
        run["summary_sha256"] = run.pop("sha256")
        run.update(ledger_sha256=r["profitable"]["ledger_sha256"], owner_distributions=r["profitable"]["distributions"]["amount"],
                   distribution_transactions=r["profitable"]["distributions"]["transactions"],
                   contract_due=r["profitable"]["contracts"]["due"], contract_completed=r["profitable"]["contracts"]["completed"],
                   contract_breaches=r["profitable"]["contracts"]["breaches"])
        for person in people:
            if person["actor"] in r["profitable"]["contracts"]["by_employee"]:
                person.update({"contract_" + k: v for k, v in r["profitable"]["contracts"]["by_employee"][person["actor"]].items()})
            else:
                person.update(dict.fromkeys(("contract_" + k for k in ("due", "attempted", "completed", "breaches", "expected_compensation", "paid_compensation")), 0))
        for firm in firms:
            firm.update({"operating_" + k: v for k, v in r["profitable"]["cash_results"][firm["actor"]].items()})
        for row in [run] + people + firms:
            row["scenario"] = r["scenario"]
        runs.append(run)
        residents.extend(people)
        businesses.extend(firms)
        print(days, "days; meals", run["meals"], "employee wages", run["wages"], "owner income", run["owner_distributions"],
              "breaches", run["contract_breaches"], "audited/replayed", flush=True)
    for name, rows in (("runs", runs), ("residents", residents), ("businesses", businesses)):
        with (args.output / (name + ".csv")).open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    main()
