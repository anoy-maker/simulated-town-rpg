"""Reuse the labor auditor on a short trace; keep annual replay output ledger-free."""
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


class EquilibriumReferenceTests(unittest.TestCase):
    def capture(self, days, flag):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CONFIG_HOME=directory, XDG_CACHE_HOME=directory)
            result = subprocess.run(["godot", "--headless", "--no-header", "--path", str(ROOT),
                                     "--script", "res://scripts/tools/run_simulation.gd", "--",
                                     "--scenario", "settlement_equilibrium_reference", str(days), "42", flag],
                                    env=env, capture_output=True, check=True, timeout=30)
            self.assertFalse(result.stderr, result.stderr)
            return result.stdout

    def test_short_reference_passes_unmodified_independent_labor_audit(self):
        data = json.loads(self.capture(2, "--json"))
        audit(data)
        self.assertEqual(data["report"]["prices"], dict(wheat=2, flour=4, bread=4))
        self.assertEqual(data["report"]["shifts"]["paid"], 12)
        self.assertTrue(all(e["money"] == (120 if e["kind"] == "business" else 6)
                            for e in data["report"]["final"]["entities"].values()))

    def test_annual_report_and_ledger_hash_replay_without_an_event_dump(self):
        first = self.capture(365, "--report-json")
        second = self.capture(365, "--report-json")
        self.assertEqual(first, second)
        data = json.loads(first)
        self.assertNotIn("events", data)
        self.assertLess(len(first), 25_000)
        report = data["report"]
        self.assertEqual(report["totals"]["consumed"]["bread"], 4380)
        self.assertEqual(report["shifts"]["paid"], 2190)
        self.assertFalse(any(report["unmet_meals"].values()))
        self.assertEqual(len(report["reference"]["ledger_sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
