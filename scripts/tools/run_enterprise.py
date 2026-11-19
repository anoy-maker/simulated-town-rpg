#!/usr/bin/env python3
"""Run M15 A/B/C twice; save compact audited reports and accounting tables."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess

from enterprise_audit import audit


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path, default=Path("work/m15"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    root = Path(__file__).resolve().parents[2]
    env = dict(os.environ, XDG_DATA_HOME=str(args.output.resolve() / "data"),
               XDG_CONFIG_HOME=str(args.output.resolve() / "config"), XDG_CACHE_HOME=str(args.output.resolve() / "cache"))
    command = [args.godot, "--headless", "--no-header", "--path", str(root), "--script", "res://scripts/tools/run_simulation.gd", "--"]
    cases = [("settlement_external_trade_reference", d) for d in (1, 3, 30, 365)]
    cases += [("enterprise_startup_fixture", 1), ("enterprise_delegation_fixture", 2)]
    runs, accounts, assets = [], [], []
    for scenario, days in cases:
        cli = command + ["--scenario", scenario, str(days), "42"]
        first = subprocess.run(cli + ["--report-json"], env=env, capture_output=True, check=True, timeout=90)
        replay = subprocess.run(cli + ["--report-json"], env=env, capture_output=True, check=True, timeout=90)
        assert not first.stderr and not replay.stderr, (first.stderr, replay.stderr)
        assert first.stdout == replay.stdout, (scenario, days, "independent-process replay mismatch")
        data = json.loads(first.stdout)
        r = data["report"]
        assert "events" not in data and len(first.stdout) < 60_000
        verification = r["profitable"]["verification"]
        assert all(all(verification[group].values()) for group in ("accounting", "reference_A")), verification
        assert verification["days_checked"] == days
        if days <= 3:
            traced = subprocess.run(cli + ["--json"], env=env, capture_output=True, check=True, timeout=90)
            assert not traced.stderr, traced.stderr
            trace = json.loads(traced.stdout)
            audit(trace)  # Independent Python reconstruction; no verbose trace files.
            assert trace["report"] == r
        op, contracts = r["open_economy"], r["profitable"]["contracts"]
        if op["experiment"] == "A":
            assert op["village_money"] == 432 + 24 * days and op["external_money"] == 8760 - 24 * days
            assert r["money"]["final"] == 9192 and op["resident_meals"] == 12 * days
            assert op["visitor_bread"] == 6 * days and r["shifts"]["paid"] == 9 * days
            assert r["shifts"]["wages"] == 54 * days and r["profitable"]["distributions"]["amount"] == 18 * days
            assert not any(r["unmet_meals"].values()) and not contracts["breaches"]
        else:
            expected = 68 if op["experiment"] == "B" else 70
            assert r["final"]["entities"]["finn_bakery"]["money"] == expected
            assert r["money"]["final"] == 1026 and op["retained_earnings"]["finn_bakery"] == expected - 60
        digest = hashlib.sha256(first.stdout).hexdigest()
        (args.output / f"{scenario}-{days}-summary.json").write_bytes(first.stdout)
        runs.append(dict(scenario=scenario, experiment=op["experiment"], seed=42, days=days,
                         village_money=op["village_money"], external_money=op["external_money"], combined_money=r["money"]["final"],
                         resident_meals=op["resident_meals"], missed_meals=sum(r["unmet_meals"].values()), visitor_bread=op["visitor_bread"],
                         wheat=r["totals"]["harvested"]["wheat"], flour=r["totals"]["production_outputs"]["flour"],
                         bread=r["totals"]["production_outputs"]["bread"], paid_shifts=r["shifts"]["paid"],
                         owner_shifts=op["unpaid_owner_shifts"], additional_paid_shifts=op["additional_paid_shifts"], wages=r["shifts"]["wages"],
                         distributions=r["profitable"]["distributions"]["amount"], contract_due=contracts["due"],
                         contract_completed=contracts["completed"], contract_breaches=contracts["breaches"],
                         successful_purchases=r["purchases"]["successful"], rejected_purchases=r["purchases"]["rejected"],
                         circulation=r["money"]["circulation"], events=r["event_count"],
                         summary_sha256=digest, ledger_sha256=r["profitable"]["ledger_sha256"]))
        for actor, entity in sorted(r["final"]["entities"].items()):
            account = r["accounts"][actor]
            book = r["final"]["cash_results"].get(actor, {})
            row = dict(scenario=scenario, days=days, seed=42, actor=actor, kind=entity["kind"], role=entity["role"], coins=entity["money"],
                       **entity["inventory"], **{k: v for k, v in account.items() if not isinstance(v, dict)})
            row.update(missed_meals=r["unmet_meals"].get(actor, 0),
                       produced_wheat=account["produced"]["wheat"], produced_flour=account["produced"]["flour"], produced_bread=account["produced"]["bread"],
                       operating_sales=book.get("sales", 0), operating_inputs=book.get("inputs", 0), operating_payroll=book.get("payroll", 0),
                       operating_distributions=book.get("distributions", 0), capital_asset_sales=book.get("capital_asset_sales", 0),
                       retained_earnings=op["retained_earnings"].get(actor, 0))
            accounts.append(row)
        if op["experiment"] != "A":
            for asset_id, asset in sorted(r["final"]["productive_assets"].items()):
                assets.append(dict(scenario=scenario, asset_id=asset_id, **asset))
        print(scenario, days, "days; village/external", op["village_money"], op["external_money"],
              "resident meals", op["resident_meals"], "paid/owner shifts", r["shifts"]["paid"], op["unpaid_owner_shifts"], "audited/replayed", flush=True)
    for name, rows in (("runs", runs), ("accounts", accounts), ("assets", assets)):
        with (args.output / (name + ".csv")).open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    main()
