"""Exercise independent M9 reconciliation, including plausible tampered receipts."""
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


class LaborAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CACHE_HOME=directory, XDG_CONFIG_HOME=directory)
            result = subprocess.run(["godot", "--headless", "--no-header", "--path", str(ROOT),
                                     "--script", "res://scripts/tools/run_simulation.gd", "--",
                                     "--scenario", "settlement_labor", "1", "42", "--json"],
                                    env=env, capture_output=True, check=True, timeout=30)
            assert not result.stderr, result.stderr
            cls.fixture = json.loads(result.stdout)

    def test_rebuilds_full_real_world_without_mutation(self):
        original = copy.deepcopy(self.fixture)
        audit(self.fixture)
        self.assertEqual(self.fixture, original)

    def test_rejects_wage_amount_inconsistent_with_work_terms(self):
        data = copy.deepcopy(self.fixture)
        pay = next(e for e in data["events"] if e["action"] == "transfer_money")
        pay["details"]["amount"] += 1
        with self.assertRaises(AssertionError):
            audit(data)

    def test_rejects_production_and_payroll_without_accepted_labor(self):
        data = copy.deepcopy(self.fixture)
        shift = next(e for e in data["events"] if e["action"] == "work_shift")
        # Keep identities, day, success and real accounting receipts. Remove only
        # the labor annotation so ordinary money/commodity conservation still holds.
        shift["action"] = "initialize"
        with self.assertRaises(AssertionError):
            audit(data)

    def test_rejects_reported_income_not_supported_by_receipts(self):
        data = copy.deepcopy(self.fixture)
        data["report"]["accounts"]["ada"]["wages_received"] += 3
        with self.assertRaises(AssertionError):
            audit(data)


if __name__ == "__main__":
    unittest.main()
