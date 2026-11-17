import copy
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from labor_market_audit import audit
from run_labor_market import capture
from run_brewery import digest
from profile_simulation import ROOT, godot_environment


class LaborMarketTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reference=capture(days=1)
        cls.transfer=capture(fixture='vacancy:dain')

    def test_authority_and_pure_policies(self):
        p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_labor_market_tests.gd'],capture_output=True,env=godot_environment(),timeout=60)
        self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'');self.assertEqual(json.loads(p.stdout)['failures'],0)

    def test_native_economic_and_employment_replay(self):
        for data in (self.reference,self.transfer):self.assertEqual(audit(data)['money'],9192)
        events=self.transfer['events']
        ends=[e for e in events if e['action']=='employment_ended' and e['actor']=='finn']
        starts=[e for e in events if e['action']=='employment_started' and e['actor']=='finn']
        self.assertEqual(len(ends),1);self.assertEqual(len(starts),1)
        self.assertLess(ends[0]['id'],starts[0]['id']);self.assertEqual(starts[0]['minute'],1440)
        self.assertTrue(any(e['success'] and e['day']==2 and e['action']=='work_shift' and e['actor']=='finn' and e['target']=='farm' for e in events))

    def test_complete_fresh_process_replay(self):
        again=capture(fixture='vacancy:dain');audit(again)
        self.assertEqual(again['report'],self.transfer['report']);self.assertEqual(again['events'],self.transfer['events'])

    def test_published_reference_and_transfer_pins(self):
        for file,data in [('M24_RUNS.csv',self.reference),('M24_VACANCIES.csv',self.transfer)]:
            r=data['report'];labor=r['labor']
            with (ROOT/'docs'/file).open() as f:
                pin=next(row for row in csv.DictReader(f) if row['condition']==r['condition'] and int(row['days'])==r['days'] and row['mode']==labor['mode'] and row['fixture']==labor['fixture'])
            self.assertEqual(digest(dict(report=r)),pin['summary_sha256']);self.assertEqual(r['ledger_sha256'],pin['ledger_sha256'])

    def test_no_vacancy_does_not_force_mobility(self):
        for key in ('postings','applications','offers','employment_started','employment_ended'):
            self.assertEqual(self.reference['report']['labor']['counts'][key],0)

    def test_cancel_and_unaccepted_ledgers_independently_replayed(self):
        for fixture in ('cancel','unaccepted','no_vacancy'):
            p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_labor_market_lifecycle.gd','--',fixture],capture_output=True,env=godot_environment(),timeout=60)
            self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'')
            data=json.loads(p.stdout);audit(data)
            closures=[e for e in data['events'] if e['action']=='labor_notice_closed' and e['success']]
            if fixture=='no_vacancy':
                self.assertEqual(data['report']['labor']['counts']['postings'],0)
                self.assertTrue(any(e['action']=='job_posted' and not e['success'] and e['details']['reason']=='no_funded_positive_vacancy' for e in data['events']))
            else:self.assertTrue(any(e['details']['reason']==('withdrawn' if fixture=='cancel' else 'expired_unaccepted') for e in closures))
            self.assertFalse(any(e['action']=='employment_ended' and e['actor']=='finn' for e in data['events']))

    def test_legacy_and_neutral_ties_keep_financial_objective(self):
        for condition in ('reference','tight','scarce','no_brew_request'):
            a=capture(condition,3,'shift_selection','legacy_sorted');b=capture(condition,3,'shift_selection','neutral_rotate')
            audit(a);audit(b)
            # A different employee may be paid, but no tie may alter conditional
            # contribution, affordable production, or installed shift capacity.
            for data in (a,b):
                for e in data['events']:
                    if e['action']=='business_plan' and e['success']:
                        p=e['details']['proposal'];self.assertGreaterEqual(p['expected_receipts']-p['committed_cash'],0)
            self.assertEqual(a['report']['totals']['produced'],b['report']['totals']['produced'])

    def test_private_information_and_labor_forgeries_rejected(self):
        def first(d,action):return next(e for e in d['events'] if e['action']==action and e['success'])
        def observation(d):first(d,'labor_search_decision')['details']['observation']['other_cash']=120
        def witnesses(d):first(d,'labor_notices_observed')['details']['witnesses'].remove('ada')
        def vacancy(d):first(d,'labor_vacancy_assessed')['details']['proposal']['vacancies']+=1
        def terms(d):first(d,'job_posted')['details']['posting']['wage']=9
        def history(d):next(e for e in d['events'] if e['action']=='labor_search_decision' and e['details']['observation']['history'])['details']['observation']['history'][0]['paid']+=1
        def notice(d):first(d,'labor_notices_observed')['details']['notices']=[]
        def date(d):first(d,'employment_started')['details']['effective_day']=1
        def affiliation(d):first(d,'employment_ended')['details']['affiliation']['business']='mill'
        def report(d):d['report']['labor']['counts']['accepted']+=1
        def assignment(d):next(e for e in d['events'] if e['action']=='labor_assignment' and e['target']=='farm')['details']['schedule']['work_start']=0
        for corrupt in (observation,witnesses,vacancy,terms,history,notice,date,affiliation,report,assignment):
            with self.subTest(forgery=corrupt.__name__):
                data=copy.deepcopy(self.transfer);corrupt(data)
                data['report']['ledger_sha256']=hashlib.sha256(json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
                with self.assertRaises(AssertionError):audit(data)

    def test_economic_forgery_not_hidden_by_labor_extension(self):
        data=copy.deepcopy(self.transfer)
        next(e for e in data['events'] if e['action']=='purchase' and e['success'])['details']['total_price']+=1
        with self.assertRaises(AssertionError):audit(data)


if __name__=='__main__':unittest.main()
