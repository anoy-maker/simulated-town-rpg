"""M18 independent mathematical reference and forged-memory rejection."""
import copy,json,math,os,subprocess,sys,tempfile,unittest
from fractions import Fraction as Q
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts/tools'))
from learning_audit import fresh,update,hazard,bb,demand,sales,operate,close,audit

class LearningTests(unittest.TestCase):
    @staticmethod
    def capture(stage):
        with tempfile.TemporaryDirectory() as directory:
            env=dict(os.environ,XDG_DATA_HOME=directory,XDG_CONFIG_HOME=directory,XDG_CACHE_HOME=directory)
            r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_simulation.gd','--','--scenario','settlement_spatial_learning','--stage',stage,'1','42','--json'],env=env,capture_output=True,check=True,timeout=180)
            assert not r.stderr,r.stderr
            return json.loads(r.stdout)
    @classmethod
    def setUpClass(cls):cls.control=cls.capture("A")
    def test_exact_teaching_posteriors_and_trial(self):
        prior=Q(1,4)
        posterior=lambda t,s:prior*t/(prior*t+(1-prior)*s)
        self.assertEqual(posterior(Q(8,10),Q(1,10)),Q(8,11))
        self.assertEqual(posterior(Q(1,10),Q(8,10)),Q(1,25))
        self.assertEqual(posterior(Q(1,10),Q(1,10)),prior)
        self.assertEqual(posterior(1,1),prior)  # No visitors: likelihood one.
        profit=lambda w:Q(243,10)+Q(294,10)*w
        immediate=profit(prior)
        continuation=Q(11,40)*max(Q(42),profit(Q(8,11)))+Q(29,40)*42
        self.assertEqual(immediate,Q(633,20))
        self.assertEqual(immediate+13*continuation,Q(9453,16))
        self.assertGreater(immediate+13*continuation,14*42)
    def test_informative_staying_has_information_value(self):
        # Both immediate expectations 2. Staying reveals state; trial does not.
        actions={'stay':(0,4),'trial':(4,0)}
        prior=(Q(1,2),Q(1,2))
        immediate={a:sum(p*v for p,v in zip(prior,pay)) for a,pay in actions.items()}
        informed=sum(prior[s]*max(pay[s] for pay in actions.values()) for s in range(2))
        frozen=max(immediate.values())
        values={'stay':immediate['stay']+informed,'trial':immediate['trial']+frozen}
        self.assertEqual(values,{'stay':6,'trial':4})
        self.assertEqual(max(values,key=values.get),'stay')
    def test_thirteen_pattern_likelihood_normalization_and_uncertainty(self):
        for p in (1,4,7,12):
            for h in range(13):self.assertAlmostEqual(sum(bb(h,p,6)),1,places=12)
        b=fresh();obs={c:dict(arrivals=6,eligible=6,sales=6,censored=False) for c in b}
        posterior=update(b,obs,7,True)
        self.assertTrue(all(w>0 for w in posterior['visitor']['weights']))
        self.assertGreater(posterior['visitor']['weights'][6],posterior['visitor']['weights'][0])
        # Correlated cohort-day likelihood is not six independent Bernoulli successes.
        self.assertNotAlmostEqual(bb(6,7,6)[6],.9**6)
        self.assertAlmostEqual(sum(sales(demand(posterior,7),18)),1)
    def test_censor_absence_closed_and_no_traffic_are_distinct(self):
        b=fresh();blank=dict(arrivals=0,eligible=0,sales=0,censored=False)
        self.assertEqual(update(b,dict(local=blank,visitor=blank),7,False),b)
        zero=update(b,dict(local=blank,visitor=blank),7,True)
        self.assertEqual(zero['visitor']['alpha'][0],1.25)
        self.assertEqual(zero['visitor']['weights'],b['visitor']['weights'])
        limited=dict(arrivals=6,eligible=3,sales=3,censored=True)
        after=update(b,dict(local=blank,visitor=limited),7,True)
        self.assertEqual(after['visitor']['weights'],b['visitor']['weights'])
        self.assertEqual(after['visitor']['alpha'][6],1.25)
    def test_finance_fixtures_and_capital_not_profit(self):
        for cash,expected in [(70,4),(120,54),(300,120)]:
            state=[cash,0,0,180 if cash==300 else 0]
            before=operate(state,True);after=close(before['state'],7,0)
            self.assertEqual(before['state'][0],cash-66)
            self.assertEqual(after['state'][0],expected)
            # Costs transferred into other accounts, payout into owner account.
            self.assertEqual((8880-cash)+312+after['state'][0]+66+after['payout'],9192)
        self.assertEqual(close(operate([300,0,0,0],True)['state'],7,0)['payout'],0)
    def test_control_full_independent_audit(self):audit(self.control)
    def test_forged_conversion_memory_rejected(self):
        data=copy.deepcopy(self.control);data['report']['learning']['memory']['cora'][0]['visitor']['sales']-=1
        with self.assertRaises(AssertionError):audit(data)
    def test_forged_cash_or_private_observation_rejected(self):
        for target in ('cash','state'):
            data=copy.deepcopy(self.control)
            if target=='cash':data['report']['learning']['memory']['cora'][0]['cash']+=1
            else:data['report']['learning']['decisions'][0]['observation']['state'][0]+=1
            with self.assertRaises(AssertionError):audit(data)
    def test_forged_posterior_rejected(self):
        data=copy.deepcopy(self.control);data['report']['learning']['beliefs']['visitor']['weights'][0]+=.01
        with self.assertRaises(AssertionError):audit(data)
    def test_native_evsi_forecasts_and_forgery_are_independently_checked(self):
        data=self.capture('D')
        audit(data)
        data['report']['learning']['decisions'][0]['proposal']['candidates'][0]['evsi']+=1
        with self.assertRaises(AssertionError):audit(data,check_values=False)
    def test_invalid_stage_and_scenario_fail(self):
        base=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_simulation.gd','--']
        for args in (['--scenario','settlement_spatial_learning','--stage','E'],['--scenario','settlement_unknown']):
            result=subprocess.run(base+args,capture_output=True,timeout=30)
            self.assertNotEqual(result.returncode,0)
    def test_no_private_ceilings_balances_or_customer_history_in_inputs(self):
        d=self.control['report']['learning']['decisions'][0]
        self.assertEqual(set(d['observation']),{'day','current_price','posted','state','supply','input_price','carry','minimum'})
        self.assertEqual(set(d['beliefs']),{'local','visitor'})
        self.assertNotIn('visitors',d['observation'])
        for record in self.control['report']['learning']['memory']['cora']:
            for c in ('local','visitor'):self.assertNotIn('customers',record[c])
if __name__=='__main__':unittest.main()
