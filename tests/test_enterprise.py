"""M15 independent short-trace receipts; annual reports stay compact."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts/tools"))
from enterprise_audit import audit


class EnterpriseTests(unittest.TestCase):
    def capture(self, scenario, days, flag="--json"):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, XDG_DATA_HOME=directory, XDG_CONFIG_HOME=directory, XDG_CACHE_HOME=directory)
            result = subprocess.run(["godot","--headless","--no-header","--path",str(ROOT),"--script",
                                     "res://scripts/tools/run_simulation.gd","--","--scenario",scenario,str(days),"42",flag],
                                    env=env,capture_output=True,check=True,timeout=90)
            self.assertFalse(result.stderr,result.stderr)
            return result.stdout

    def test_external_currency_and_real_bread_have_separate_village_and_world_boundaries(self):
        data=json.loads(self.capture("settlement_external_trade_reference",3))
        audit(data)
        self.assertEqual((data["report"]["open_economy"]["village_money"],data["report"]["money"]["final"]),(504,9192))
        self.assertEqual(data["report"]["open_economy"]["visitor_bread"],18)

    def test_founding_capital_and_finite_assets_are_not_operating_income(self):
        data=json.loads(self.capture("enterprise_startup_fixture",1))
        audit(data)
        r=data["report"]
        self.assertEqual(r["final"]["entities"]["finn_bakery"]["money"],68)
        self.assertEqual(r["final"]["cash_results"]["finn_bakery"]["capital_purchases"],240)
        self.assertEqual(r["open_economy"]["retained_earnings"]["finn_bakery"],8)

    def test_delegation_records_real_employment_and_one_employee_wage(self):
        data=json.loads(self.capture("enterprise_delegation_fixture",2))
        audit(data)
        r=data["report"]
        self.assertEqual(r["final"]["entities"]["finn_bakery"]["money"],70)
        self.assertEqual(r["accounts"]["iona"]["wages_received"],6)
        self.assertEqual(r["accounts"]["finn"]["wages_received"],0)

    def test_false_capital_or_asset_receipts_are_detected_without_money_creation(self):
        data=json.loads(self.capture("enterprise_startup_fixture",1))
        event=next(e for e in data["events"] if e["action"]=="asset_purchased")
        event["details"]["asset_state"]["holder"]="bakery"
        with self.assertRaises(AssertionError):audit(data)

    def test_annual_compact_reference_replays_with_finite_external_funds(self):
        first=self.capture("settlement_external_trade_reference",365,"--report-json")
        self.assertEqual(first,self.capture("settlement_external_trade_reference",365,"--report-json"))
        data=json.loads(first)
        self.assertNotIn("events",data)
        self.assertLess(len(first),60_000)
        r=data["report"]
        self.assertEqual(r["open_economy"]["external_money"],0)
        self.assertEqual(r["open_economy"]["village_money"],9192)
        self.assertEqual(r["accounts"]["visitors"]["consumed"],2190)
        self.assertTrue(all(r["profitable"]["verification"]["accounting"].values()))


if __name__=="__main__":unittest.main()
