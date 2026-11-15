"""Employer forecast/receipt audit and compact annual process replay."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts/tools"))
from run_labor import audit


class EmployerAuditTests(unittest.TestCase):
    def capture(self, days, flag):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CONFIG_HOME=directory, XDG_CACHE_HOME=directory)
            result = subprocess.run(["godot", "--headless", "--no-header", "--path", str(ROOT), "--script",
                                     "res://scripts/tools/run_simulation.gd", "--", "--scenario", "settlement_employer_choice",
                                     str(days), "42", flag], env=env, capture_output=True, check=True, timeout=30)
            self.assertFalse(result.stderr, result.stderr)
            return result.stdout

    def test_real_short_trace_reconciles_forecasts_money_goods_and_employment(self):
        data = json.loads(self.capture(2, "--json"))
        audit(data)
        self.assertEqual(data["report"]["employers"]["first_unmet_meal_day"], 2)
        self.assertEqual(data["report"]["final"]["entities"]["bakery"]["inventory"]["bread"], 6)

    def test_forged_realized_demand_is_rejected_even_if_cash_is_conserved(self):
        data = json.loads(self.capture(2, "--json"))
        event = next(e for e in data["events"] if e["action"] == "employer_plan" and e["day"] == 2)
        event["details"]["proposal"]["forecast"] += 1
        with self.assertRaises(AssertionError):
            audit(data)

    def test_reusing_a_work_receipt_cannot_inflate_employer_participation(self):
        data = json.loads(self.capture(2, "--json"))
        event = next(e for e in data["events"] if e["action"] == "employer_plan")
        ids = event["details"]["execution"]["work_event_ids"]
        ids[1] = ids[0]
        with self.assertRaises(AssertionError):
            audit(data)

    def test_annual_report_and_complete_ledger_fingerprint_replay_without_dump(self):
        first = self.capture(365, "--report-json")
        self.assertEqual(first, self.capture(365, "--report-json"))
        self.assertLess(len(first), 40_000)
        data = json.loads(first)
        self.assertNotIn("events", data)
        self.assertEqual(data["report"]["money"]["final"], 432)
        self.assertEqual(len(data["report"]["employers"]["ledger_sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
