"""M27 source audit, independent witness rejection, and truthful tier labels."""
import copy
import hashlib
import json
import sys
import subprocess
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from run_demand import capture
from run_brewery import digest
from economic_diagnostics import analyze
from economic_witness import generate
from check_economic_witness import verify,verify_physical,finance
from economic_wedge import wedge,five_wheat_chain
from profile_simulation import ROOT,godot_environment


class EconomicDiagnosticsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.traces={c:capture(c,3,'requests_smoothed') for c in ('reference','tight','scarce','no_brew_request')}
        cls.analyses={c:analyze(d) for c,d in cls.traces.items()}

    def test_reader_is_read_only_and_replay_deterministic(self):
        d=self.traces['scarce'];before=digest(d);first=self.analyses['scarce']
        self.assertEqual(first,analyze(d));self.assertEqual(digest(d),before)
        self.assertEqual(first['audit']['money'],9192)
        self.assertEqual(set(first['snapshots']),{'1','3'})
        for f in first['firm_days']:
            self.assertEqual(f['opening_arrears']+f['accrued_wages']-f['paid_wages'],f['arrears'])
            for item in ('wheat','flour','bread','ale'):
                self.assertEqual(f['opening_inventory'][item]+f['opening_cargo'][item]+f['produced_goods'][item]+f['purchased_inputs'][item]-f['consumed_inputs'][item]-f['sold_goods'][item],f['closing_inventory'][item]+f['closing_cargo'][item])

    def test_final_cash_is_not_a_substitute_for_native_events(self):
        with self.assertRaisesRegex(ValueError,'full native events'):analyze(dict(report=self.traces['reference']['report']))

    def test_reference_witness_reproduces_m23_books_with_binding_payroll(self):
        b=self.analyses['reference']['snapshots']['1'];v=verify(b,generate(b,'fixed_orders'))
        self.assertTrue(v['physical']['physically_feasible']);self.assertEqual(v['physical']['optimality'],'certified_optimum')
        self.assertEqual(v['physical']['production'],dict(wheat=21,flour=15,bread=21,ale=12))
        self.assertTrue(v['finance']['finance_witnessed']);self.assertEqual(v['finance']['resident_meals'],15)
        self.assertEqual(v['finance']['visitor_meals'],6);self.assertEqual(v['finance']['currency'],9192)
        for firm in ('farm','mill','bakery','brewery'):self.assertEqual(v['finance']['cash'][firm],120)
        self.assertEqual(v['finance']['incentive_compatible'],'unproven')

    def test_resource_cap_and_new_job_profitability_are_distinct(self):
        for condition,cap in [('tight',19),('scarce',16)]:
            a=self.analyses[condition];f=next(r for r in a['firm_days'] if r['day']==1 and r['firm']=='farm')
            self.assertEqual(f['produced'],cap)
            self.assertEqual(wedge(cap)['new_farm_margin'],0 if cap==19 else -6)
            self.assertGreater(wedge(cap)['current_assignment_margin_if_sold'],0)
        self.assertEqual(five_wheat_chain()['integrated'],12)
        self.assertEqual([five_wheat_chain()[k] for k in ('farm','mill','bakery')],[0,5,7])
        self.assertFalse(five_wheat_chain()['incentive_compatible'])

    def test_scarce_recorded_orders_vs_voluntary_alternative(self):
        b=self.analyses['scarce']['snapshots']['1']
        fixed=verify(b,generate(b,'fixed_orders'));alternative=verify(b,generate(b,'voluntary_orders'))
        self.assertEqual(fixed['physical']['bread_at_shop'],14)
        self.assertEqual(alternative['physical']['bread_at_shop'],21)
        self.assertEqual(alternative['physical']['optimality'],'certified_optimum')
        self.assertTrue(alternative['finance']['finance_witnessed'])
        self.assertEqual(alternative['finance']['resident_meals'],15)
        self.assertFalse(alternative['finance']['current_policy_quantity_agreement'])
        self.assertEqual(alternative['finance']['incentive_compatible'],'unproven')

    def test_day_three_uses_actual_owned_stock_terms_and_household_money(self):
        for condition,a in self.analyses.items():
            b=a['snapshots']['3'];p=generate(b,'voluntary_orders');v=verify(b,p)
            self.assertEqual(b['state']['day'],3)
            self.assertTrue(all(j['end_day']==4 for j in b['state']['employment'].values()))
            if v['finance']['finance_witnessed']:
                self.assertLessEqual(v['finance']['resident_meals'],15)
                self.assertEqual(v['finance']['steps'][-1]['future_guarantees'],0)
            for row in a['firm_days']:
                if row['day']==3:self.assertEqual(row['future_guarantees'],self.traces[condition]['report']['contracts']['businesses'][row['firm']]['future_guaranteed_wages'])

    def test_shopping_cash_and_stockout_causes_have_actual_provenance(self):
        a=self.analyses['tight'];r=self.traces['tight']['report']
        self.assertEqual(len(a['failure_attributions']),sum(x['unmet_meals'] for x in r['day_results']))
        self.assertTrue(any(f['immediate_blocker']=='household_purchasing_power' for f in a['failure_attributions']))
        for f in a['failure_attributions']:
            self.assertTrue(f['source_ids']);self.assertEqual(f['latent_demand'],'unknown')
            if f['immediate_blocker']=='household_purchasing_power':self.assertLess(f['shopping_cash'],6)
        for row in a['claim_totals']:self.assertEqual(row['payable'],row['receivable'])
        self.assertTrue(any(f['shopping_cash']<6 and r['day_results'][f['day']-1]['households'][f['buyer']]['cash']>=6 for f in a['failure_attributions']))

    def test_rehashed_native_evidence_corruption_still_fails_original_audit(self):
        for action in ('demand_day_closed','guaranteed_wage_due','transfer_money'):
            data=copy.deepcopy(self.traces['scarce']);event=next(e for e in data['events'] if e['action']==action and e['success'])
            if action=='demand_day_closed':event['details']['censored']=not event['details']['censored']
            elif action=='guaranteed_wage_due':event['details']['claim']['amount']-=1
            else:event['details']['amount']+=1
            data['report']['ledger_sha256']=hashlib.sha256(json.dumps(data['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
            with self.assertRaises(AssertionError):analyze(data)

    def test_poor_visitors_and_cashless_b2b_do_not_become_invented_demand(self):
        for fixture in ('poor_visitors','cashless_buyers'):
            process=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_demand_fixture.gd','--',fixture],capture_output=True,env=godot_environment(),timeout=60)
            self.assertEqual(process.returncode,0,process.stderr.decode());self.assertEqual(process.stderr,b'')
            a=analyze(json.loads(process.stdout))
            if fixture=='poor_visitors':
                visitors=[c for c in a['cohorts'] if c['cohort']=='visitor']
                self.assertTrue(all(c['requested']==0 and c['stockout_unfilled']==0 for c in visitors))
                self.assertTrue(all(c['unaffordable_visits']==6 for c in visitors))
            else:
                farm=next(f for f in a['firm_days'] if f['firm']=='farm')
                self.assertEqual((farm['requested'],farm['unfilled'],farm['coverage']),(0,0,True))
                bundle=a['snapshots']['1'];proof=verify(bundle,generate(bundle,'voluntary_orders'))
                self.assertTrue(proof['physical']['physically_feasible']);self.assertFalse(proof['finance']['finance_witnessed'])
                self.assertEqual(proof['finance']['label'],'unproven')

    def test_late_visitors_and_sales_do_not_finance_early_wages(self):
        b=self.analyses['reference']['snapshots']['1'];p=generate(b,'fixed_orders')
        s=copy.deepcopy(b['state']);s['entities']['visitors']['money']+=s['entities']['farm']['money'];s['entities']['farm']['money']=0
        altered=copy.deepcopy(b);altered['state']=s;altered['snapshot_sha256']=digest(s);p['snapshot_sha256']=digest(s)
        physical=verify_physical(altered,p);v=finance(altered,p,physical)
        self.assertFalse(v['finance_witnessed']);self.assertIn('cash at600',v['reason'])
        self.assertGreater(sum(c['amount']-c['paid'] for c in v['remaining_claims'].values()),0)

    def test_due_wages_precede_owner_capital_floor_and_claims_survive(self):
        b=copy.deepcopy(self.analyses['reference']['snapshots']['1'])
        b['state']['binding']['obligations']['0000:farm:dain']=dict(id='0000:farm:dain',day=0,worker='dain',business='farm',amount=10,paid=0)
        b['snapshot_sha256']=digest(b['state']);p=generate(b,'fixed_orders');v=verify(b,p)
        early=v['finance']['steps'][0]
        self.assertEqual((early['minute'],early['purpose'],early['cash']['farm']),(480,'wage',110))
        self.assertEqual(v['finance']['remaining_claims']['0000:farm:dain']['paid'],10)

    def test_invalid_physical_and_financial_certificates_reject(self):
        b=self.analyses['reference']['snapshots']['1'];plan=generate(b,'fixed_orders');proof=verify(b,plan)
        def fractional(p):p['counts']['farm']=2.5
        def duplicate(p):p['workers']['mill'][0]=p['workers']['farm'][0]
        def double(p):p['workers']['farm'][1]=p['workers']['farm'][0]
        def site(p):p['trips'][0]['to']=[0,0]
        def late(p):p['trips'][0]['end']+=5
        def negative(p):p['requests']['mill']=-1
        def illegal(p):p['workers']['farm'][0]='ada'
        def false_production(p):p['claimed_physical']['production']['bread']+=1
        def false_truth(p):p['latent_demand']='exact'
        for mutate in (fractional,duplicate,double,site,late,negative,illegal,false_production,false_truth):
            with self.subTest(mutate=mutate.__name__):
                p=copy.deepcopy(plan);mutate(p)
                with self.assertRaises((AssertionError,KeyError)):verify(b,p)
        for bad in ('negative_initial_stock','expired_term'):
            altered=copy.deepcopy(b);p=copy.deepcopy(plan)
            if bad=='negative_initial_stock':altered['state']['entities']['farm']['inventory']['wheat']=-1
            else:altered['state']['employment']['dain']['end_day']=1
            altered['snapshot_sha256']=digest(altered['state']);p['snapshot_sha256']=altered['snapshot_sha256']
            with self.assertRaises(AssertionError):verify(altered,p)
        for mutate in ('free_cash','negative_stock','future_sale','erase_claim','duplicate_transfer','fake_fulfillment','censored_truth'):
            with self.subTest(forgery=mutate):
                claimed=copy.deepcopy(proof)
                if mutate=='free_cash':claimed['finance']['steps'][0]['cash']['farm']+=1
                if mutate=='negative_stock':claimed['physical']['steps'][0]['held']['farm']['wheat']=-1
                if mutate=='future_sale':claimed['finance']['steps'].insert(0,dict(minute=500,action='purchase',coins=126))
                if mutate=='erase_claim':claimed['finance']['remaining_claims'].clear()
                if mutate=='duplicate_transfer':claimed['finance']['steps'].append(claimed['finance']['steps'][0])
                if mutate=='fake_fulfillment':claimed['finance']['resident_meals']=16
                if mutate=='censored_truth':claimed['physical']['latent_demand']='exact'
                with self.assertRaises(AssertionError):verify(b,plan,claimed)


if __name__=='__main__':unittest.main()
