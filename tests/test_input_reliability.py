"""M28 local input provenance, pure forecast accounting and causal isolation."""
import copy
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from input_audit import analyze,estimate,projection,INPUTS
from binding_audit import BindingAudit
from run_input import capture,economic_parity
from run_demand import capture as original
from profile_simulation import ROOT,godot_environment


class InputTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases={arm:capture('scarce',3,arm) for arm in ('R_baseline_instrumented','R_input_aware')}
        cls.reference=capture('reference',3,'R_input_aware')
        cls.fixtures={}
        for label in ('no_harvest','cashless_inputs','remote_buyer','invalid_attempts'):
            r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_input_fixture.gd','--',label],capture_output=True,env=godot_environment(),timeout=60)
            assert r.returncode==0 and not r.stderr,(label,r.returncode,r.stderr.decode())
            cls.fixtures[label]=json.loads(r.stdout)

    def test_native_focused_integer_and_policy_fixtures(self):
        r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_input_tests.gd'],capture_output=True,env=godot_environment(),timeout=60)
        self.assertEqual((r.returncode,r.stderr),(0,b''));self.assertIn(b'failures: 0',r.stdout)

    def test_complete_native_replay_and_no_hidden_state_mutation(self):
        data=self.cases['R_input_aware'];before=copy.deepcopy(data);first=analyze(data)
        self.assertEqual(data,before);self.assertEqual(first,analyze(data));again=capture('scarce',3,'R_input_aware')
        self.assertEqual(data['events'],again['events']);self.assertEqual(data['report'],again['report']);self.assertEqual(first['audit']['money'],9192)

    def test_passive_baseline_full_report_events_receipt_and_obligation_parity(self):
        self.assertTrue(economic_parity(self.cases['R_baseline_instrumented'],original('scarce',3,'requests_smoothed'))['full_normalized_report'])

    def test_same_initial_endowment_and_current_term_economic_behavior(self):
        starts=[]
        for data in self.cases.values():
            s=copy.deepcopy(data['report']['initial']);s.pop('input_reliability');starts.append(s)
        self.assertEqual(*starts)
        self.assertEqual(self.cases['R_baseline_instrumented']['report']['day_results'],self.cases['R_input_aware']['report']['day_results'])
        # Terms at the closing boundary may legitimately differ; no current
        # contract is terminated to make the treatment's forecast come true.
        for data in self.cases.values():self.assertEqual(analyze(data)['audit']['money'],9192)

    def test_every_no_history_and_full_fill_candidate_matches_original(self):
        for data in [self.reference,self.cases['R_input_aware']]:
            for e in data['events']:
                if e['action']!='labor_vacancy_assessed' or not e['success']:continue
                o=e['details']['observation'];ratio=o.get('input_reliability',{})
                if ratio.get('numerator')!=ratio.get('denominator'):continue
                for c in e['details']['proposal']['candidates']:
                    self.assertEqual(c,BindingAudit.forecast(None,o,c['headcount']))
                    self.assertEqual(c['guaranteed_wages'],30*c['headcount'])

    def test_native_filled_rationed_and_unknown_orders_have_distinct_provenance(self):
        for data in self.fixtures.values():self.assertEqual(analyze(data)['audit']['money'],9192)
        a=analyze(self.fixtures['no_harvest']);orders=a['input']['orders']
        self.assertEqual(set(r['business'] for r in orders),set(INPUTS))
        self.assertTrue(all(r['filled']==0 and r['requested']>0 for r in orders))
        self.assertGreater(sum(x['arrears'] for x in a['firm_days']),0)
        a=analyze(self.fixtures['cashless_inputs']);self.assertFalse(any(r['business'] in ('mill','brewery') for r in a['input']['orders']))
        a=analyze(self.fixtures['remote_buyer']);self.assertFalse(any(r['business']=='mill' for r in a['input']['orders']))
        a=analyze(self.fixtures['invalid_attempts']);self.assertEqual(len(a['input']['orders']),3)
        self.assertTrue(all(p['sample_days']==[] for p in a['input']['forecasts']))
        a=analyze(self.cases['R_input_aware']);self.assertTrue(any(r['filled']<r['requested'] for r in a['input']['orders']))

    def test_exact_estimator_context_last_three_dedup_and_half_up(self):
        for b,(supplier,item,size,k) in INPUTS.items():
            terms=dict(day=5,inspection_event_id=2,quote=dict(seller=supplier,item=item,unit_price=2,active=True))
            rows=[dict(business=b,supplier=supplier,item=item,price=2,day=day,requested=k,filled=k if day==1 else 1 if day==2 else 0,eligible=True,order_event_id=10+day,receipt_ids=[20+day] if day<3 else []) for day in range(1,5)]
            p=estimate(rows,b,5,terms);self.assertEqual((p['sample_days'],p['numerator'],p['denominator']),([2,3,4],k+1,4*k))
            self.assertEqual(p,estimate(rows+[rows[-1]],b,5,terms))
            for field in ['supplier','item','price','eligible','requested']:
                changed=copy.deepcopy(rows);changed[-1][field]=False if field=='eligible' else 0 if field=='requested' else 99 if field=='price' else 'unknown'
                self.assertEqual(estimate(changed,b,5,terms)['sample_days'],[1,2,3])

    def test_owned_inputs_survive_bad_history_and_standby_wages_remain(self):
        event=next(e for e in self.reference['events'] if e['action']=='labor_vacancy_assessed' and e['target']=='bakery')
        o=copy.deepcopy(event['details']['observation']);o['input_reliability']=dict(numerator=1,denominator=12);o['production']['output_stock']=0;o['production']['cash']=120;o['remaining_sales']=0
        o['production']['input_stock']=10
        result=projection(o,2,True);self.assertEqual(result['days'][0]['output'],14);self.assertEqual(result['days'][0]['desired_lots'],0)
        o['production']['input_stock']=0;result=projection(o,2,True)
        self.assertTrue(all(d['output']==0 and d['guaranteed_wages']==20 for d in result['days']));self.assertEqual(result['summary']['contribution'],-60)
        o['production']['cash']=0;result=projection(o,2,True);self.assertFalse(result['summary']['feasible']);self.assertEqual(result['summary']['guaranteed_wages'],60)

    def test_morning_receipt_is_embargoed_and_farm_is_unaffected(self):
        for data in [self.reference,*self.cases.values()]:
            a=analyze(data)
            for p in a['input']['forecasts']:
                self.assertTrue(all(day<p['day'] for day in p['sample_days']))
                if p['day']==1:self.assertEqual(p['sample_days'],[])
                if p['business']=='farm':self.assertEqual(p['status'],'inapplicable')
            self.assertTrue(all(e['minute']==955 for e in data['events'] if e['action'].startswith('input_')))

    def test_rehashed_forged_knowledge_cost_quantity_and_debt_reject(self):
        def find(d,action):return next(e for e in d['events'] if e['action']==action and e['target']=='brewery' and e['day']==3)
        def ratio(d):find(d,'input_reliability_frozen')['details']['numerator']+=1
        def future(d):find(d,'input_reliability_frozen')['details']['sample_days']=[3]
        def competitor(d):find(d,'input_reliability_frozen')['details']['sample_order_ids']=[1]
        def private(d):find(d,'input_reliability_frozen')['details']['supplier_cash']=999
        def quote(d):find(d,'input_reliability_frozen')['details']['quote']['unit_price']=3
        def unpaid(d):find(d,'input_forecast_projection')['details']['candidates'][-1]['summary']['guaranteed_wages']=0
        def goods(d):find(d,'input_forecast_projection')['details']['candidates'][-1]['days'][0]['output']+=6
        def rounding(d):find(d,'input_forecast_projection')['details']['candidates'][-1]['days'][0]['predicted_lots']+=1
        def cash(d):find(d,'input_forecast_projection')['details']['candidates'][-1]['days'][0]['cash_before_sales']+=100
        def duplicate(d):next(e for e in d['events'] if e['action']=='demand_order_observed' and e['details']['kind']=='grain')['details']['receipt_ids']*=2
        def erased(d):d['report']['final']['binding_contracts']['obligations'].clear()
        for mutate in (ratio,future,competitor,private,quote,unpaid,goods,rounding,cash,duplicate,erased):
            with self.subTest(forgery=mutate.__name__):
                d=copy.deepcopy(self.cases['R_input_aware']);mutate(d)
                d['report']['ledger_sha256']=hashlib.sha256(json.dumps(d['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
                with self.assertRaises((AssertionError,KeyError,ValueError)):analyze(d)


if __name__=='__main__':unittest.main()
