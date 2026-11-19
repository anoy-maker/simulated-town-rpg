"""M16 short financial reconstruction and compact process replay."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts/tools'))
from enterprise_audit import audit


class PricingTests(unittest.TestCase):
    def capture(self, stage, days=3, flag='--json'):
        with tempfile.TemporaryDirectory() as directory:
            env=dict(os.environ,XDG_DATA_HOME=directory,XDG_CONFIG_HOME=directory,XDG_CACHE_HOME=directory)
            scenario=['--scenario','pricing_competition_fixture'] if stage is None else ['--scenario','settlement_pricing','--stage',stage]
            r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_simulation.gd','--']+
                             scenario+[str(days),'42',flag],env=env,capture_output=True,check=True,timeout=90)
            self.assertFalse(r.stderr,r.stderr)
            return r.stdout

    def test_all_stages_have_independent_money_goods_assets_and_wage_reconstruction(self):
        for stage in 'ABCD':
            with self.subTest(stage=stage):
                data=json.loads(self.capture(stage))
                audit(data)
                self.assertEqual(data['report']['money']['final'],9192)
                self.assertTrue(all(data['report']['profitable']['verification']['pricing'].values()))

    def test_isolated_competition_fixture_has_two_real_sellers_and_no_added_productive_assets(self):
        data=json.loads(self.capture(None,1))
        audit(data)
        r=data['report']
        self.assertEqual(r['money']['final'],430)
        self.assertEqual((r['final']['entities']['ada']['money'],r['final']['entities']['bram']['money']),(1,1))
        self.assertEqual((r['final']['entities']['bakery']['money'],r['final']['entities']['rival']['money']),(123,5))
        self.assertEqual(len(r['final']['productive_assets']),6)
        self.assertEqual(r['shifts']['paid'],0)

    def test_fixed_market_preserves_m15_reference_resources_and_income(self):
        r=json.loads(self.capture('A',30,'--report-json'))['report']
        self.assertEqual((r['open_economy']['resident_meals'],r['open_economy']['visitor_bread'],r['shifts']['paid']),(360,180,270))
        self.assertEqual((r['open_economy']['village_money'],r['open_economy']['external_money']),(1152,8040))
        self.assertTrue(all(p['money']==66 for p in r['final']['entities'].values() if p['kind']=='resident'))
        self.assertEqual(r['profitable']['distributions']['amount'],540)

    def test_adaptive_compact_reports_replay_without_saved_events(self):
        first=self.capture('D',30,'--report-json')
        self.assertEqual(first,self.capture('D',30,'--report-json'))
        data=json.loads(first)
        self.assertNotIn('events',data)
        self.assertEqual(len(data['report']['pricing']['business_days']),90)
        self.assertTrue(data['report']['pricing']['report_reconciles'])

    def test_forged_purchase_quote_fails_even_with_recomputed_ledger_fingerprint(self):
        data=json.loads(self.capture('B'))
        receipt=next(e for e in data['events'] if e['action']=='purchase' and e['success'])
        receipt['details']['quote']['unit_price']+=1
        encoded=json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()
        data['report']['profitable']['ledger_sha256']=hashlib.sha256(encoded).hexdigest()
        with self.assertRaises(AssertionError):audit(data)

    def test_public_quotes_and_private_pricing_observations_contain_no_customer_finances(self):
        data=json.loads(self.capture('D'))
        for e in data['events']:
            if e['action']=='pricing_decision':
                o=e['details']['observation']
                self.assertNotIn('entities',o)
                self.assertNotIn('reservation_price',o)
                self.assertNotIn('customer_money',o)
                self.assertTrue(all('money' not in q and 'inventory' not in q for q in o['competing_offers']))
        altered=copy.deepcopy(data)
        quote=next(e for e in altered['events'] if e['action']=='quote_revised' and e['success'])
        quote['details']['quote']['unit_price']=0
        with self.assertRaises(AssertionError):audit(altered)


if __name__=='__main__':unittest.main()
