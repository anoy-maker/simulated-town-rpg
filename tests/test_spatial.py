"""Independent M17 receipt, custody, location, timing and witness checks."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/tools'))
from spatial_audit import audit


def rehash(data):
    encoded=json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()
    data['report']['profitable']['ledger_sha256']=hashlib.sha256(encoded).hexdigest()


class SpatialTests(unittest.TestCase):
    def capture(self,days=1,experiment='control',flag='--json'):
        with tempfile.TemporaryDirectory() as directory:
            env=dict(os.environ,XDG_DATA_HOME=directory,XDG_CONFIG_HOME=directory,XDG_CACHE_HOME=directory)
            r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_simulation.gd','--',
                              '--scenario','settlement_spatial','--spatial-case',experiment,str(days),'42',flag],env=env,capture_output=True,check=True,timeout=180)
            self.assertFalse(r.stderr,r.stderr)
            return r.stdout

    def test_three_day_control_reconstructs_finance_custody_all_locations_and_times(self):
        data=json.loads(self.capture(3))
        audit(data)
        r=data['report']
        self.assertEqual((r['open_economy']['resident_meals'],r['open_economy']['visitor_bread'],r['shifts']['paid']),(36,18,27))
        self.assertEqual((r['open_economy']['village_money'],r['open_economy']['external_money']),(504,8688))
        self.assertEqual(r['money']['final'],9192)

    def test_thirty_day_compact_control_replays_and_matches_reference(self):
        first=self.capture(30,flag='--report-json')
        self.assertEqual(first,self.capture(30,flag='--report-json'))
        data=json.loads(first)
        self.assertNotIn('events',data)
        self.assertLess(len(first),256000)
        r=data['report']
        self.assertEqual((r['open_economy']['resident_meals'],r['open_economy']['visitor_bread'],r['shifts']['paid']),(360,180,270))
        self.assertEqual(r['profitable']['contracts']['breaches'],0)
        self.assertTrue(all(p['money']==66 for p in r['final']['entities'].values() if p['kind']=='resident'))
        self.assertTrue(all(r['profitable']['verification']['spatial'].values()))

    def test_declared_spatial_disruptions_keep_real_consequences(self):
        for case,shifts,meals,visitors,breaches in [('late_worker',6,12,0,3),('early_close',9,0,0,0)]:
            with self.subTest(case=case):
                data=json.loads(self.capture(experiment=case))
                audit(data)
                r=data['report']
                self.assertEqual((r['shifts']['paid'],r['open_economy']['resident_meals'],r['open_economy']['visitor_bread'],r['profitable']['contracts']['breaches']),(shifts,meals,visitors,breaches))
                self.assertEqual(r['money']['final'],9192)
                if case=='early_close': self.assertEqual(r['final']['entities']['bakery']['inventory']['bread'],18)

    def test_teleport_receipt_fails_even_with_matching_new_fingerprint(self):
        data=json.loads(self.capture())
        e=next(e for e in data['events'] if e['action']=='spatial_moved' and e['success'])
        e['details']['to']=[9,6]
        rehash(data)
        with self.assertRaises(AssertionError): audit(data)

    def test_offsite_witness_cannot_be_forged(self):
        data=json.loads(self.capture())
        e=next(e for e in data['events'] if e['action']=='spatial_encounter' and 'cora' not in e['details']['witnesses'])
        e['details']['witnesses'].append('cora')
        rehash(data)
        with self.assertRaises(AssertionError): audit(data)

    def test_duplicate_cargo_cannot_create_deliverable_inventory(self):
        data=json.loads(self.capture())
        e=next(e for e in data['events'] if e['action']=='spatial_deposited')
        e['details']['goods']['wheat']+=1
        rehash(data)
        with self.assertRaises(AssertionError): audit(data)

    def test_visitor_aliases_share_funds_and_public_encounters_are_sanitized(self):
        data=json.loads(self.capture())
        audit(data)
        r=data['report']
        visits=[p for p in r['final']['spatial']['presences'].values() if p['kind']=='visitor']
        self.assertEqual(len(visits),6)
        self.assertEqual(len(r['initial']['entities']),len(r['final']['entities']))
        self.assertTrue(all(p['account']=='visitors' and not p['active'] and p['tile']==[9,3] and 'money' not in p for p in visits))
        receipts=[e for e in data['events'] if e['action']=='purchase' and e['success'] and e['actor']=='visitors']
        self.assertEqual(len({e['physical_actor'] for e in receipts}),6)
        self.assertTrue(all(e['details']['quantity']==1 for e in receipts))
        for e in data['events']:
            if e['action']=='spatial_encounter': self.assertEqual(set(e['details']),{'kind','item','quantity','tile','witnesses'})


if __name__=='__main__':unittest.main()
