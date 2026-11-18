"""M30 exact private beliefs, fixed-control parity and native variable wage rights."""
import copy,hashlib,json,subprocess,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/tools'))
from run_wages import capture,parity
from wage_audit import analyze
from cash_allocation_audit import analyze as audit_old
from run_cash_allocation import capture as old_capture
from profile_simulation import ROOT,godot_environment


def rehash(d):d['report']['ledger_sha256']=hashlib.sha256(json.dumps(d['events'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()

class WageTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.cases={arm:capture('scarce',3,arm) for arm in ['fixed10_instrumented','worker_bids']}
  cls.fixtures={f:capture('reference',days,'worker_bids',script='res://tests/run_wage_fixture.gd',fixture=f) for f,days in [('manual_mixed',4),('manual_partial',6),('manual_no_show',4)]}
 def test_native_math_and_authority(self):
  r=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_wage_tests.gd'],capture_output=True,env=godot_environment(),timeout=60)
  self.assertEqual((r.returncode,r.stderr),(0,b''));self.assertIn(b'failures: 0',r.stdout)
 def test_complete_event_reconstruction_and_read_only(self):
  for x in [*self.cases.values(),*self.fixtures.values()]:
   before=copy.deepcopy(x);a=analyze(x);self.assertEqual(a['audit']['money'],9192);self.assertEqual(x,before)
 def test_F_full_economic_receipts_reports_and_obligations_match_M29(self):
  old=old_capture('scarce',3,'R_input_aware','original');audit_old(old)
  self.assertTrue(parity(self.cases['fixed10_instrumented'],old)['full_normalized_report'])
  self.assertNotEqual(self.cases['fixed10_instrumented']['report']['ledger_sha256'],old['report']['ledger_sha256'])
  self.assertTrue(any(e['action']=='wage_payment_applied' for e in old['events']))
 def test_initial_terms_unchanged_then_real_mixed_salary_claims(self):
  x=self.fixtures['manual_mixed'];analyze(x)
  claims=[e for e in x['events'] if e['action']=='guaranteed_wage_due']
  self.assertTrue(all(e['details']['claim']['amount']==10 for e in claims if e['day']<=3))
  self.assertEqual({e['actor']:e['details']['claim']['amount'] for e in claims if e['day']==4},dict(dain=10,finn=8,kira=5))
  for w,wage in [('dain',10),('finn',8),('kira',5)]:
   job=x['report']['final']['employment'][w];self.assertEqual((job['start_day'],job['end_day'],job['wage'],job['contract']['cycle_compensation']),(4,7,wage,wage))
   work=[e for e in x['events'] if e['day']==4 and e['action']=='work_shift' and e['actor']==w];self.assertEqual(len(work),1);self.assertEqual(work[0]['details']['wage'],wage)
 def test_variable_partial_payment_survives_expiration_without_new_money(self):
  x=self.fixtures['manual_partial'];analyze(x);s=x['report']['final'];c=s['binding_contracts']['obligations']['0006:farm:kira']
  self.assertEqual((c['amount'],c['paid'],x['report']['contracts']['workers']['kira']['arrears']),(5,2,3))
  self.assertEqual(s['binding_contracts']['terms'][c['term']]['status'],'expired');self.assertNotIn('kira',s['affiliations'])
  self.assertEqual(sum(v['money'] for v in s['entities'].values()),9192);self.assertEqual(x['report']['contracts']['businesses']['farm']['arrears'],3)
  self.assertTrue(any(e['day']==6 and e['action']=='binding_breach' and e['actor']=='kira' and e['details'].get('arrears')==3 for e in x['events']))
 def test_real_no_show_never_accrues_variable_salary(self):
  x=self.fixtures['manual_no_show'];analyze(x);s=x['report']['final']
  self.assertNotIn('0004:farm:kira',s['binding_contracts']['obligations']);self.assertEqual(s['employment']['kira']['wage'],5)
  self.assertTrue(any(e['day']==4 and e['actor']=='kira' and e['action']=='binding_breach' and e['details']['kind']=='worker_nonattendance' for e in x['events']))
 def test_fresh_process_deterministic_replay(self):
  old=self.cases['worker_bids'];new=capture('scarce',3,'worker_bids');self.assertEqual(old['events'],new['events']);self.assertEqual(old['report'],new['report'])
 def test_rehashed_knowledge_bids_claims_projection_and_conservation_forgeries_reject(self):
  def initial(d):d['report']['initial']['employment']['dain']['end_day']=3;d['events'][0]['details']['state']=copy.deepcopy(d['report']['initial'])
  def private(d):next(e for e in d['events'] if e['action']=='wage_worker_decision')['details']['observation']['firm_cash']=120
  def future(d):next(e for e in d['events'] if e['action']=='wage_worker_decision' and e['details']['observation']['quotes'])['details']['observation']['quotes']['bread']['inspection_event_id']=len(d['events'])+1
  def bid(d):next(e for e in d['events'] if e['action']=='wage_bid_submitted' and e['success'])['details']['bid']['wage']=8.5
  def source(d):next(e for e in d['events'] if e['action']=='wage_bid_submitted' and e['success'])['details']['bid']['source_event_id']=1
  def post(d):next(e for e in d['events'] if e['action']=='job_posted')['details']['posting']['wage']+=1
  def salary(d):next(e for e in d['events'] if e['action']=='guaranteed_wage_due' and e['day']==4)['details']['claim']['amount']+=1
  def shift(d):next(e for e in d['events'] if e['action']=='work_shift' and e['day']==4)['details']['wage']+=1
  def lost_claim(d):d['report']['final']['binding_contracts']['obligations'].pop('0006:farm:kira');d['report']['contracts']['workers']['kira']['arrears']=0
  def prediction(d):next(e for e in d['events'] if e['action']=='wage_vacancy_assessed')['details']['proposal']['baseline']['projection']['days'][0]['predicted_lots']+=1
  def utility(d):next(e for e in d['events'] if e['action']=='wage_worker_decision' and e['details']['proposal']['candidates'])['details']['proposal']['candidates'][0]['p_num']+=1
  def payment(d):next(e for e in d['events'] if e['action']=='transfer_money' and e['details']['purpose']=='wage')['details']['amount']+=1
  def commodity(d):next(e for e in d['events'] if e['action']=='harvest')['details']['amount']+=1
  def capacity(d):next(e for e in d['events'] if e['action']=='wage_notice_posted')['details']['notice']['vacancies']=9
  for change in [initial,private,future,bid,source,post,salary,shift,lost_claim,prediction,utility,payment,commodity,capacity]:
   with self.subTest(change=change.__name__):
    origin=self.cases['worker_bids'] if change in [private,future,utility] else self.fixtures['manual_partial']
    d=copy.deepcopy(origin);change(d);rehash(d)
    with self.assertRaises((AssertionError,KeyError,ValueError)):analyze(d)
 def test_historical_fixed10_audit_does_not_accept_a_forged_eight_coin_claim(self):
  old=old_capture('scarce',1,'R_input_aware','original');e=next(e for e in old['events'] if e['action']=='guaranteed_wage_due');e['details']['claim']['amount']=8;rehash(old)
  with self.assertRaises(AssertionError):audit_old(old)

if __name__=='__main__':unittest.main()
