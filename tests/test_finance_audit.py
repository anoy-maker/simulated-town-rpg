"""Independent M10 reconciliation and adversarial ownership/reserve/classification cases."""
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
from run_labor import audit, legacy_report


class FinanceAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CACHE_HOME=directory, XDG_CONFIG_HOME=directory)
            def capture(scenario, policy=None):
                args = ["godot", "--headless", "--no-header", "--path", str(ROOT), "--script",
                        "res://scripts/tools/run_simulation.gd", "--", "--scenario", scenario]
                if policy:
                    args += ["--distribution", policy]
                result = subprocess.run(args + ["30", "42", "--json"], env=env, capture_output=True, check=True, timeout=30)
                assert not result.stderr, result.stderr
                return json.loads(result.stdout)
            cls.fixture = capture("settlement_finance", "needs")
            cls.control = capture("settlement_finance", "none")
            cls.baseline = capture("settlement_labor")

    def changed_withdrawal(self):
        data = copy.deepcopy(self.fixture)
        event = next(e for e in data["events"] if e["action"] == "owner_withdrawal" and e["success"])
        return data, event

    def test_complete_finance_reconciliation_is_pure(self):
        original = copy.deepcopy(self.fixture)
        audit(self.fixture)
        self.assertEqual(self.fixture, original)

    def test_control_matches_every_baseline_event_and_legacy_report(self):
        audit(self.control)
        self.assertEqual(self.control["events"], self.baseline["events"])
        self.assertEqual(legacy_report(self.control["report"]), self.baseline["report"])

    def test_unrelated_household_cannot_receive_an_owner_withdrawal(self):
        data, event = self.changed_withdrawal()
        event["actor"] = "dain"
        with self.assertRaises(AssertionError):
            audit(data)

    def test_event_cannot_waive_the_authoritative_reserve(self):
        data, event = self.changed_withdrawal()
        event["details"]["operating_reserve"] = 0
        with self.assertRaises(AssertionError):
            audit(data)

    def test_withdrawal_cannot_cross_reserve_even_with_plausible_cash_metadata(self):
        data, event = self.changed_withdrawal()
        event["details"]["amount"] = event["details"]["distributable_before"] + 1
        event["details"]["business_cash_after"] = event["details"]["operating_reserve"] - 1
        with self.assertRaises(AssertionError):
            audit(data)

    def test_report_cannot_reclassify_ownership_income_as_wages(self):
        data, event = self.changed_withdrawal()
        account = data["report"]["accounts"][event["actor"]]
        account["wages_received"] += 1
        account["owner_withdrawals_received"] -= 1
        with self.assertRaises(AssertionError):
            audit(data)


if __name__ == "__main__":
    unittest.main()
