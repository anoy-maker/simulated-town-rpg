"""M29 exact initial ownership and unchanged native transaction/knowledge rules."""
import copy,json,hashlib,subprocess,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from cash_allocation_audit import analyze,initial_cash,ALLOCATIONS,NONOWNERS
from run_cash_allocation import capture,parity
from profile_simulation import ROOT,godot_environment

class CashTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases={(arm,a):capture('scarce',1,arm,a) for arm in ['R_baseline_instrumented','R_input_aware'] for a in ALLOCATIONS}

    def test_native_creation_and_utility_guards(self):
        r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_cash_allocation_tests.gd'],capture_output=True,env=godot_environment(),timeout=60)
        self.assertEqual((r.returncode,r.stderr),(0,b''));self.assertIn(b'failures: 0',r.stdout)
        r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_cash_allocation.gd','--','--allocation','invalid'],capture_output=True,env=godot_environment(),timeout=30)
        self.assertEqual(r.returncode,2)

    def test_exact_initial_accounts_native_replay_and_no_operating_income(self):
        for (arm,a),data in self.cases.items():
            result=analyze(data);self.assertEqual(result['audit']['money'],9192)
            self.assertEqual({w:e['money'] for w,e in data['report']['initial']['entities'].items()},initial_cash(a))
            self.assertEqual(len(data['report']['initial']['employment']),11)
            self.assertFalse(any(e['action']=='transfer_money' and e['day']==0 for e in data['events']))
        original=self.cases['R_input_aware','original']['report']['initial']
        for a in ALLOCATIONS:
            s=copy.deepcopy(self.cases['R_input_aware',a]['report']['initial'])
            for w in s['entities']:s['entities'][w]['money']=original['entities'][w]['money']
            self.assertEqual(s,original)

    def test_original_exact_native_ledger_full_report_and_terms(self):
        from run_input import capture as old_capture
        for arm in ['R_baseline_instrumented','R_input_aware']:
            self.assertTrue(parity(self.cases[arm,'original'],old_capture('scarce',1,arm))['native_events_identical'])

    def test_read_only_deterministic_fresh_process(self):
        first=self.cases['R_input_aware','households_330'];before=copy.deepcopy(first);r=analyze(first)
        self.assertEqual(first,before);self.assertEqual(r,analyze(first));again=capture('scarce',1,'R_input_aware','households_330')
        self.assertEqual(first['report'],again['report']);self.assertEqual(first['events'],again['events'])

    def test_extra_cash_never_becomes_free_food_or_excess_allowance(self):
        d=self.cases['R_input_aware','households_330'];a=analyze(d)
        self.assertEqual(sum(r['consumed'] for r in a['cohorts'] if r['item']=='bread' and r['cohort']=='resident'),14)
        self.assertEqual(len(a['failure_attributions']),1);self.assertEqual(a['failure_attributions'][0]['immediate_blocker'],'stockout_of_solvent_request')
        for data in self.cases.values():
            residents=data['report']['accounts'];self.assertTrue(all(row['meals']<=1 for w,row in residents.items() if w in NONOWNERS))
            for v in data['report']['day_results'][0]['visitors'].values():self.assertLessEqual(v['bread_spending']+v['ale_spending'],10)

    def test_firm_treasury_retains_realized_income_distribution_rules(self):
        d=capture('reference',1,'R_input_aware','firms_330');analyze(d)
        for b,row in d['report']['contracts']['businesses'].items():
            self.assertEqual(row['cash'],initial_cash('firms_330')[b]);self.assertEqual(row['distributions'],row['sales']-row['inputs']-row['accrued_wages'])
        d=capture('no_brew_request',1,'R_input_aware','firms_330');a=analyze(d)
        self.assertFalse(any(r['business']=='brewery' for r in a['input']['orders']));self.assertEqual(d['report']['contracts']['businesses']['brewery']['accrued_wages'],20)

    def test_rehashed_initial_and_runtime_forgeries_reject(self):
        def recipient(d):d['report']['initial']['entities']['ada']['money']+=30;d['report']['initial']['entities']['dain']['money']-=30
        def creation(d):d['report']['initial']['entities']['visitors']['money']+=330
        def goods(d):d['report']['initial']['entities']['farm']['inventory']['wheat']=1
        def profit(d):d['report']['initial']['cash_results']['farm']['sales']=83
        def terms(d):d['report']['initial']['employment']['dain']['end_day']+=1
        def private(d):next(e for e in d['events'] if e['action']=='labor_vacancy_assessed')['details']['observation']['allocation']='households_330'
        def late(d):next(e for e in d['events'] if e['action']=='consumer_decision')['details']['observation']['money']+=30
        def wage(d):next(e for e in d['events'] if e['action']=='guaranteed_wage_due')['details']['claim']['amount']=40
        for change in [recipient,creation,goods,profit,terms,private,late,wage]:
            with self.subTest(change=change.__name__):
                d=copy.deepcopy(self.cases['R_input_aware','households_330']);change(d)
                d['events'][0]['details']['state']=copy.deepcopy(d['report']['initial'])
                d['report']['cash_allocation']['initial_accounts']={w:e['money'] for w,e in d['report']['initial']['entities'].items()}
                d['report']['ledger_sha256']=hashlib.sha256(json.dumps(d['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
                with self.assertRaises((AssertionError,KeyError,ValueError)):analyze(d)

if __name__=='__main__':unittest.main()
