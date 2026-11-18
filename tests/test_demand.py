"""M26 factual request/coverage boundaries, matched forecasts and corrupt evidence."""
import copy
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from demand_audit import audit
from run_demand import capture,economic_parity
from run_binding import capture as old_capture
from profile_simulation import ROOT,godot_environment


class DemandTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases={a:capture('scarce',3,a) for a in ('legacy_instrumented','sales_smoothed','requests_smoothed')}
        cls.reference=capture('reference',1,'requests_smoothed')

    def test_native_focused_witnesses(self):
        p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_demand_tests.gd'],capture_output=True,env=godot_environment(),timeout=90)
        self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'');self.assertEqual(json.loads(p.stdout)['failures'],0)

    def test_three_arm_independent_cash_goods_contract_and_forecast_replay(self):
        for data in self.cases.values():self.assertEqual(audit(data)['money'],9192)
        self.assertEqual(audit(self.reference)['money'],9192)

    def test_legacy_native_events_states_and_accounting_parity(self):
        self.assertTrue(economic_parity(self.cases['legacy_instrumented'],old_capture('scarce',3))['all_native_events'])

    def test_complete_native_process_replay(self):
        again=capture('scarce',3,'requests_smoothed');audit(again)
        for key in ('events','report'):self.assertEqual(again[key],self.cases['requests_smoothed'][key])

    def test_identical_initial_resources_and_solver_with_different_information(self):
        first=None
        for arm,data in self.cases.items():
            initial=copy.deepcopy(data['report']['initial']);initial.pop('demand_observations')
            if first is None:first=initial
            else:self.assertEqual(first,initial)
        sales=self.cases['sales_smoothed']['report']['demand']['forecasts'];requests=self.cases['requests_smoothed']['report']['demand']['forecasts']
        self.assertTrue(any(a['forecast']!=b['forecast'] for a,b in zip(sales,requests)))
        self.assertEqual([x['sample_days'] for x in sales],[x['sample_days'] for x in requests])

    def test_real_stockout_requests_and_budget_are_not_soldout_inspections(self):
        d=self.reference;orders=list(d['report']['final']['demand_observations']['orders'].values())
        unmet=[o for o in orders if o['unfilled']]
        self.assertEqual(len(unmet),5)
        self.assertTrue(all(o['item']=='ale' and o['quantity']==1 and o['buyer'].startswith('visitor:') for o in unmet))
        intents=[e for e in d['events'] if e['action']=='demand_customer_intent']
        self.assertTrue(any(e['details']['quantity']==0 for e in intents))
        self.assertTrue(all(set(e['details'])=={'item','quantity','quote','inspection_event_id','witness'} for e in intents))
        self.assertTrue(all(p['spent']<=10 and all(n<=1 for n in p['bought'].values()) for p in d['report']['final']['spatial']['presences'].values() if p['kind']=='visitor'))

    def test_partial_owner_coverage_and_late_information_embargo(self):
        r=self.reference['report'];days={x['business']:x for x in r['demand']['days']}
        self.assertFalse(days['bakery']['complete']);self.assertTrue(days['bakery']['censored'])
        self.assertTrue(days['farm']['complete']);self.assertFalse(days['farm']['censored'])
        self.assertTrue(all(x['sample_ids']==[] for x in r['demand']['forecasts']))
        self.assertTrue(any(o['minute']>955 and o['buyer'].startswith('visitor:') for o in r['final']['demand_observations']['orders'].values()))

    def test_labeled_native_observation_fixtures_independently_audited(self):
        for label in ('poor_visitors','cashless_buyers','remote_farm','duplicate'):
            with self.subTest(label=label):
                p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_demand_fixture.gd','--',label],capture_output=True,env=godot_environment(),timeout=60)
                self.assertEqual(p.returncode,0,p.stderr.decode());self.assertEqual(p.stderr,b'');data=json.loads(p.stdout);audit(data)
                r=data['report'];orders=list(r['final']['demand_observations']['orders'].values())
                if label=='poor_visitors':self.assertFalse(any(o['buyer'].startswith('visitor:') for o in orders))
                if label=='cashless_buyers':
                    farm=next(x for x in r['demand']['days'] if x['business']=='farm')
                    self.assertEqual((farm['complete'],farm['eligible'],farm['sales'],farm['unfilled']),(True,True,0,0))
                    self.assertFalse(any(o['seller']=='farm' for o in orders))
                if label=='remote_farm':self.assertFalse(any(o['buyer']=='bram' and o['seller']=='farm' for o in orders))
                if label=='duplicate':self.assertEqual(sum(o['buyer']=='ada' and o['seller']=='bakery' for o in orders),1)

    def test_rehashed_forged_interest_knowledge_forecast_terms_and_censoring_reject(self):
        def first(d,action):return next(e for e in d['events'] if e['action']==action and e['success'])
        def interest(d):first(d,'demand_customer_intent')['details']['quantity']=0
        def witness(d):first(d,'demand_customer_intent')['details']['witness']='mara'
        def private(d):first(d,'demand_customer_intent')['details']['money']=6
        def future(d):first(d,'demand_forecast')['details']['sample_days']=[1]
        def double(d):first(d,'demand_order_observed')['details']['quantity']*=2
        def fake(d):first(d,'demand_day_closed')['details']['unfilled']+=1
        def estimate(d):first(d,'demand_forecast')['details']['forecast']+=1
        def contract(d):first(d,'binding_term_started')['details']['term']['end_day']+=1
        def payroll(d):first(d,'guaranteed_wage_due')['details']['claim']['amount']=9
        def censor(d):first(d,'demand_day_closed')['details']['censored']=not first(d,'demand_day_closed')['details']['censored']
        def quote(d):first(d,'demand_customer_intent')['details']['quote']['version']+=1
        def receipt(d):first(d,'demand_order_observed')['details']['receipt_ids']*=2
        def future_view(d):first(d,'labor_vacancy_assessed')['details']['observation']['future_arrivals']=6
        def failed_lot(d):next(e for e in d['events'] if e['action']=='purchase' and not e['success'] and e['target']=='mill')['details']['quantity']=99
        def failed_price(d):next(e for e in d['events'] if e['action']=='purchase' and not e['success'] and e['target']=='brewery')['details']['unit_price']=5
        for mutate in (interest,witness,private,future,double,fake,estimate,contract,payroll,censor,quote,receipt,future_view,failed_lot,failed_price):
            with self.subTest(forgery=mutate.__name__):
                data=copy.deepcopy(self.cases['requests_smoothed']);mutate(data)
                data['report']['ledger_sha256']=hashlib.sha256(json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
                with self.assertRaises((AssertionError,KeyError,ValueError)):audit(data)


if __name__=='__main__':unittest.main()
