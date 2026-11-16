"""Independent M14 cash, paid labor, contract and distribution receipt verification."""
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


class ProfitableReferenceTests(unittest.TestCase):
    def capture(self, days, flag="--json"):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CONFIG_HOME=directory, XDG_CACHE_HOME=directory)
            result = subprocess.run(["godot", "--headless", "--no-header", "--path", str(ROOT), "--script",
                                     "res://scripts/tools/run_simulation.gd", "--", "--scenario", "settlement_profitable_reference",
                                     str(days), "42", flag], env=env, capture_output=True, check=True, timeout=60)
            self.assertFalse(result.stderr, result.stderr)
            return result.stdout

    def test_three_day_trace_reconstructs_currency_recipes_contracts_and_income(self):
        data = json.loads(self.capture(3))
        audit(data)
        r = data["report"]
        self.assertTrue(all(p["money"] == (120 if p["kind"] == "business" else 6) for p in r["final"]["entities"].values()))
        self.assertEqual(r["shifts"]["wages"], 108)
        self.assertEqual(r["profitable"]["distributions"]["amount"], 36)

    def test_forged_surplus_cannot_be_supported_by_unchanged_real_cash(self):
        data = json.loads(self.capture(1))
        e = next(e for e in data["events"] if e["action"] == "profit_distribution")
        e["details"]["cumulative_before"]["sales"] += 4
        with self.assertRaises(AssertionError):
            audit(data)

    def test_a_distribution_cannot_reuse_a_previously_claimed_transfer(self):
        data = json.loads(self.capture(1))
        distributions = [e for e in data["events"] if e["action"] == "profit_distribution"]
        distributions[1]["details"]["payment_event_id"] = distributions[0]["details"]["payment_event_id"]
        with self.assertRaises(AssertionError):
            audit(data)

    def test_unworked_contract_cannot_be_reported_as_paid_fulfillment(self):
        data = json.loads(self.capture(1))
        e = next(e for e in data["events"] if e["action"] == "contract_shift")
        e["details"]["actual_compensation"] = 12
        with self.assertRaises(AssertionError):
            audit(data)

    def test_annual_compact_report_replays_and_separates_wages_from_ownership_income(self):
        first = self.capture(365, "--report-json")
        self.assertEqual(first, self.capture(365, "--report-json"))
        self.assertLess(len(first), 40_000)
        data = json.loads(first)
        self.assertNotIn("events", data)
        r = data["report"]
        self.assertEqual((r["totals"]["consumed"]["bread"], r["shifts"]["paid"]), (4380, 2190))
        self.assertEqual((r["shifts"]["wages"], r["profitable"]["distributions"]["amount"]), (13140, 4380))
        for actor in ("ada", "bram", "cora"):
            self.assertEqual(r["accounts"][actor]["wages_received"], 0)
            self.assertEqual(r["accounts"][actor]["profit_distributions_received"], 1460)
        self.assertEqual(len(r["profitable"]["ledger_sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
