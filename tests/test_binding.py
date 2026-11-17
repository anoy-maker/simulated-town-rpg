import copy
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from binding_audit import audit
from run_binding import capture
from profile_simulation import ROOT,godot_environment
from run_brewery import digest


class BindingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reference=capture(days=3)
        cls.partial=capture(days=1,fixture='cash_short')
        cls.insolvent=capture(days=4,fixture='insolvent')

    def test_native_authority_and_pure_policy(self):
        p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_binding_tests.gd'],capture_output=True,env=godot_environment(),timeout=90)
        self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'');self.assertEqual(json.loads(p.stdout)['failures'],0)

    def test_cash_goods_attendance_liabilities_and_decisions_replay(self):
        for data in (self.reference,self.partial,self.insolvent):self.assertEqual(audit(data)['money'],9192)

    def test_fresh_process_complete_replay(self):
        again=capture(days=3);audit(again)
        self.assertEqual(again['report'],self.reference['report']);self.assertEqual(again['events'],self.reference['events'])

    def test_expiration_is_real_at_end_of_horizon(self):
        r=self.reference['report'];state=r['final']['binding_contracts']
        self.assertEqual((r['contracts']['counts']['expired'],r['contracts']['counts']['renewed']),(11,11))
        self.assertEqual(state['terms']['term:0001:farm:dain']['status'],'expired')
        self.assertEqual((r['final']['employment']['dain']['start_day'],r['final']['employment']['dain']['end_day']),(4,7))
        self.assertEqual(r['contracts']['workers']['dain']['cash_wages'],30)

    def test_published_reference_standby_and_insolvency_pins(self):
        for file,data in [('M25_RUNS.csv',self.reference),('M25_FIXTURES.csv',self.partial),('M25_FIXTURES.csv',self.insolvent)]:
            r=data['report'];fixture=r['initial']['labor_market']['fixture']
            with (ROOT/'docs'/file).open() as f:pin=next(row for row in csv.DictReader(f) if row['condition']==r['condition'] and row['mode']==r['contracts']['mode'] and int(row['days'])==r['days'] and row['fixture']==fixture)
            self.assertEqual(digest(dict(report=r)),pin['summary_sha256']);self.assertEqual(r['ledger_sha256'],pin['ledger_sha256'])

    def test_partial_and_late_wages_have_actual_shopping_consequences(self):
        late=capture(days=1,fixture='cash_zero');audit(late)
        for data,meals in ((self.partial,1),(late,0)):
            r=data['report'];c=r['final']['binding_contracts']['obligations']['0001:bakery:finn']
            self.assertEqual(c['paid'],10);self.assertEqual(r['accounts']['finn']['meals'],meals)
            self.assertEqual(c['payments'][-1]['minute'],1140)
        c=self.partial['report']['final']['binding_contracts']['obligations']['0001:bakery:finn']
        self.assertEqual([p['amount'] for p in c['payments']],[6,4])
        self.assertEqual(self.partial['report']['contracts']['workers']['finn']['productive'],0)

    def test_early_receipts_clear_earned_wages_before_food_shopping(self):
        data=capture(days=1,fixture='mill_zero');audit(data)
        r=data['report'];claim=r['final']['binding_contracts']['obligations']['0001:mill:hale']
        self.assertEqual(claim['paid'],10);self.assertEqual(claim['payments'][0]['minute'],730)
        self.assertEqual(r['accounts']['hale']['meals'],1)
        self.assertEqual(r['contracts']['workers']['hale']['productive'],0)

    def test_arrears_survive_nonrenewal_and_are_expensed(self):
        r=self.insolvent['report'];firm=r['contracts']['businesses']['bakery']
        self.assertEqual((firm['cash_payroll'],firm['arrears'],firm['accrued_wages']),(0,90,90))
        self.assertEqual((firm['cash_margin'],firm['accrued_margin']),(0,-90))
        self.assertNotIn('finn',r['final']['affiliations'])
        self.assertEqual(r['final']['binding_contracts']['obligations']['0001:bakery:finn']['amount'],10)

    def test_no_show_is_not_paid_standby(self):
        data=capture(days=1,fixture='no_show');audit(data);state=data['report']['final']['binding_contracts']
        self.assertEqual(state['attendance']['0001:farm:dain']['status'],'absent')
        self.assertNotIn('0001:farm:dain',state['obligations'])
        self.assertEqual(data['report']['contracts']['workers']['dain']['cash_wages'],0)

    def test_lifecycle_witnesses_independently_replayed(self):
        for fixture in ('decline','renew','rehire','cancel','worker_release','employer_release','overlap','remote','oldest_after_expiry','declined_assignment'):
            with self.subTest(fixture=fixture):
                p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_binding_lifecycle.gd','--',fixture],capture_output=True,env=godot_environment(),timeout=60)
                self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'');data=json.loads(p.stdout);audit(data)
                if fixture=='oldest_after_expiry':
                    state=data['report']['final']['binding_contracts'];claim=state['obligations']['0001:bakery:finn']
                    self.assertEqual(claim['paid'],10);self.assertTrue(any(p['day']==4 for p in claim['payments']))
                if fixture=='declined_assignment':self.assertEqual(data['report']['contracts']['workers']['finn']['attended'],1)
                if fixture=='rehire':
                    self.assertGreater(data['report']['contracts']['counts']['rehired'],0)
                    self.assertEqual(data['report']['contracts']['counts']['renewed'],0)

    def test_rehashed_forgery_fails_independent_reconstruction(self):
        def first(d,action):return next(e for e in d['events'] if e['action']==action and e['success'])
        def amount(d):first(d,'guaranteed_wage_due')['details']['claim']['amount']=11
        def attendance(d):first(d,'contract_attended')['details']['kind']='standby'
        def payment(d):first(d,'transfer_money')['details']['amount']+=1
        def annotation(d):first(d,'wage_payment_applied')['details']['payment']['amount']+=1
        def timestamp(d):first(d,'guaranteed_wage_due')['minute']-=5
        def early(d):first(d,'employment_started')['details']['job']['start_day']=3
        def term(d):first(d,'binding_term_started')['details']['term']['end_day']+=1
        def entry(d):first(d,'binding_term_started')['details']['entry_kind']='rehire'
        def private(d):first(d,'labor_search_decision')['details']['observation']['other_cash']=120
        def forecast(d):first(d,'labor_vacancy_assessed')['details']['proposal']['baseline']['guaranteed_wages']=0
        def due_link(d):first(d,'guaranteed_wage_due')['details']['claim']['due_event_id']=1
        def erased(d):d['report']['final']['binding_contracts']['obligations']['0001:bakery:finn']['paid']=10
        def fake_profit(d):d['report']['contracts']['businesses']['bakery']['accrued_margin']=0
        def duplicate(d):
            c=d['report']['final']['binding_contracts']['obligations']['0001:bakery:finn'];c['payments'].append(copy.deepcopy(c['payments'][0]))
        def initial_price(d):
            for state in (d['report']['initial'],d['events'][0]['details']['state']):state['commodity_quotes']['bakery']['bread']['unit_price']=5
        def initial_cap(d):
            for state in (d['report']['initial'],d['events'][0]['details']['state']):state['brewery']['supply_cap']=22
        for source,corrupt in [(self.reference,f) for f in (amount,attendance,payment,annotation,timestamp,early,term,entry,private,forecast,due_link,initial_price,initial_cap)]+[(self.insolvent,erased),(self.insolvent,fake_profit),(self.partial,duplicate)]:
            with self.subTest(forgery=corrupt.__name__):
                data=copy.deepcopy(source);corrupt(data)
                data['report']['ledger_sha256']=hashlib.sha256(json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
                with self.assertRaises(AssertionError):audit(data)


if __name__=='__main__':unittest.main()
