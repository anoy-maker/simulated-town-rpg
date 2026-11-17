import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from brewery_feasibility import certificate, document
from brewery_audit import audit
from run_brewery import capture
from profile_simulation import ROOT, godot_environment


class BreweryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.data=capture('reference',1)
    def test_predeclared_certificate(self):
        self.assertEqual(certificate()['money'],9192)
        self.assertEqual((ROOT/'docs/M23_FEASIBILITY.md').read_text(),document())
    def test_authority_and_policies(self):
        p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_brewery_tests.gd'],capture_output=True,env=godot_environment(),timeout=60)
        self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'');self.assertEqual(json.loads(p.stdout)['failures'],0)
    def test_native_event_reconstruction(self):self.assertEqual(audit(self.data)['money'],9192)
    def test_scarcity_and_three_day_checkpoint(self):
        for condition in ('reference','tight','scarce','no_brew_request'):
            with self.subTest(condition=condition):
                a=capture(condition,3);b=capture(condition,3)
                self.assertEqual(a['report'],b['report']);self.assertEqual(a['events'],b['events']);audit(a)
    def test_independent_audit_rejects_forgery(self):
        # Rehash each corruption: tests must exercise reconstruction, not just a digest.
        def first(data,action):return next(e for e in data['events'] if e['action']==action and e['success'])
        def financial(d):first(d,'purchase')['details']['total_price']+=1
        def production(d):first(d,'produce')['details']['outputs']['flour']+=1
        def wage(d):first(d,'transfer_money')['details']['amount']+=1
        def quote(d):first(d,'purchase')['details']['quote']['unit_price']+=1
        def movement(d):first(d,'spatial_moved')['details']['to'][0]+=2
        def visitor(d):first(d,'spatial_visitor_entered')['details']['presence']['spent']=-10
        def privacy(d):first(d,'business_plan')['details']['observation']['other_cash']=100
        def need(d):first(d,'consumer_decision')['details']['observation']['need_bread']=0
        def report(d):d['report']['day_results'][0]['firms']['brewery']['sales']+=4
        def benefit(d):first(d,'discretionary_benefit')['details']['consumption_event_id']=1
        for corrupt in (financial,production,wage,quote,movement,visitor,privacy,need,report,benefit):
            with self.subTest(forgery=corrupt.__name__):
                data=copy.deepcopy(self.data);corrupt(data)
                data['report']['ledger_sha256']=hashlib.sha256(json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
                with self.assertRaises(AssertionError):audit(data)


if __name__=='__main__':unittest.main()
