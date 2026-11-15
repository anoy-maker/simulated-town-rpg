"""Treatment isolation, independent short-trace audit and observation-only reporting."""
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

A = "settlement_fixed_owner_first"
B = "settlement_sales_rotating"


class CausalityTests(unittest.TestCase):
    def capture(self, scenario, days, flag="--json"):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CONFIG_HOME=directory, XDG_CACHE_HOME=directory)
            result = subprocess.run(["godot", "--headless", "--no-header", "--path", str(ROOT), "--script",
                                     "res://scripts/tools/run_simulation.gd", "--", "--scenario", scenario,
                                     str(days), "42", flag], env=env, capture_output=True, check=True, timeout=60)
            self.assertFalse(result.stderr, result.stderr)
            return json.loads(result.stdout)

    def test_fixed_output_retains_target_despite_unsold_inventory_and_limited_cash(self):
        data = self.capture(A, 7)
        audit(data)
        bakery = [e["details"]["proposal"] for e in data["events"] if e["action"] == "employer_plan" and e["target"] == "bakery"]
        self.assertTrue(any(p["unsold_stock"] > 12 for p in bakery))
        self.assertTrue(all(p["required_output"] == 12 and p["requested_shifts"] == 2 for p in bakery))
        self.assertTrue(any(p["planned_shifts"] < 2 and "insufficient_operating_funds" in p["reductions"] for p in bakery))

    def test_fixed_treatment_cannot_hide_an_inventory_offset_in_its_ledger(self):
        data = self.capture(A, 7)
        event = next(e for e in data["events"] if e["action"] == "employer_plan" and e["details"]["proposal"]["unsold_stock"] > 0)
        event["details"]["proposal"]["required_output"] -= 1
        with self.assertRaises(AssertionError):
            audit(data)

    def test_rotating_treatment_reconstructs_all_receipts_and_uses_exclusive_pairs(self):
        data = self.capture(B, 7)
        audit(data)
        event = next(e for e in data["events"] if e["action"] == "employer_plan" and e["day"] == 2 and e["target"] == "farm")
        self.assertEqual(event["details"]["proposal"]["workers"], ["edda", "gale"])
        event["details"]["proposal"]["required_output"] -= 1
        with self.assertRaises(AssertionError):
            audit(data)
        event["details"]["proposal"]["required_output"] += 1
        event["details"]["proposal"]["candidate_workers"] = ["ada", "dain", "edda", "gale"]
        with self.assertRaises(AssertionError):
            audit(data)

    def test_day_two_food_exclusion_is_financial_while_bread_is_available(self):
        data = self.capture(A, 2, "--study-json")
        d = data["diagnostics"]
        self.assertTrue(d["currency_after_every_event"] and d["accounting_and_labor_verified"])
        self.assertEqual(d["first_unmet_meal_day"], 2)
        self.assertIsNone(d["first_bread_stock_shortage_day"])
        self.assertEqual(d["unmet_with_bread_unsold"], 6)
        self.assertEqual(d["unaffordable_food_turns_with_stock"], 6)
        self.assertEqual(d["food_turns_without_stock"], 0)

    def test_financial_constraint_uses_actual_opening_cash_and_full_input_payroll_cost(self):
        data = self.capture(A, 7, "--study-json")
        d = data["diagnostics"]
        self.assertEqual(d["first_financial_constraint_day"], 6)
        plans = d["by_business"]["bakery"]["plans_first_eight_days"]
        self.assertTrue(all(p["opening"]["cash"] >= p["full_desired_cost"] for p in plans[:5]))
        self.assertEqual(plans[5]["opening"]["cash"], 24)
        self.assertEqual(plans[5]["full_desired_cost"], 48)
        self.assertTrue(plans[5]["cash_short"])

    def test_reporting_does_not_change_control_ledger_or_native_movements(self):
        control = self.capture("settlement_equilibrium_reference", 7, "--study-json")
        treatment = self.capture(B, 7, "--study-json")
        self.assertEqual(control["diagnostics"]["economic_sha256"], treatment["diagnostics"]["economic_sha256"])
        self.assertEqual(control["report"], self.capture("settlement_equilibrium_reference", 7, "--report-json")["report"])
        self.assertNotIn("events", control)
        self.assertLess(len(json.dumps(treatment)), 100_000)


if __name__ == "__main__":
    unittest.main()
