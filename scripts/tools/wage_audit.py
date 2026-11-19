"""M30 independent wage bids/knowledge/portfolios over strict physical/coin replay."""
import copy
from cash_allocation_audit import CashAudit
from economic_diagnostics import analyze as replay
from brewery_feasibility import OWNERS,WINDOWS,SITES
from wage_calculation import ARMS,worker,select,acceptance

BASE='9f7268e130d5e1efa341c858e9b14c4d42ab5e80'
NOTE='Direct sealed asks; conditional affordability and own application priors are fallible, never guaranteed hiring or food.'
NEW=set('wage_fixed_admission_observed wage_fixed_worker_observed wage_vacancy_assessed wage_notice_posted wage_board_observed wage_outcome_observed wage_worker_decision wage_portfolio_selected wage_bid_submitted wage_offer_observed wage_acceptance_decision wage_offer_declined wage_contract_started wage_boundary_assessed wage_pending_cancelled wage_notice_cancelled wage_offer_expired wage_notice_settled wage_offer_rejected'.split())

class WageAudit(CashAudit):
 SCENARIO='settlement_dynamic_wages'
 ACTIONS=CashAudit.ACTIONS|NEW
 def attach(self,r,*args):
  self.wage_arm=r['wage_market']['arm'];assert self.wage_arm in ARMS
  self.VARIABLE_WAGES=self.wage_arm=='worker_bids'
  assert r['wage_market']==dict(arm=self.wage_arm,note=NOTE)
  self.technical=r.get('wage_fixture','');assert self.technical in ('','manual_mixed','manual_partial','manual_no_show')
  super().attach(r,*args)
  assert self.input_arm=='R_input_aware' and r['cash_allocation']['name'] in (('technical_partial',) if self.technical=='manual_partial' else ('original','households_330'))
  if self.technical:assert self.VARIABLE_WAGES and r['condition']=='reference'
  self.wages=copy.deepcopy(r['initial']['wage_market']);s=self.wages
  assert s==dict(arm=self.wage_arm,notices={},bids={},known={},offers={},memory={},anchors={w:dict(wage=10,term=f'term:0001:{j["business"]}:{w}',source_event_id=1) for w,j in self.jobs.items()},quotes={},shopping={},settlements={})
  self.assessments={};self.selections={};self.decisions={};self.revalidations={};self.board_days={}
 def validate_initial_jobs(self,initial,jobs):
  if self.technical!='manual_partial':return super().validate_initial_jobs(initial,jobs)
  from cash_allocation_audit import initial_cash
  from binding_audit import BindingAudit
  expected=initial_cash('original');expected['farm']-=90;expected['visitors']+=90
  assert set(initial['entities'])==set(expected) and initial['labor_market']['fixture']=='none'
  normalized=copy.deepcopy(initial)
  for who,e in initial['entities'].items():
   assert type(e['money']) is int and e['money']==expected[who] and not any(e['inventory'].values());normalized['entities'][who]['money']=initial_cash('original')[who]
  assert all(all(v==0 for v in book.values()) for book in initial['cash_results'].values())
  assert self.r['cash_allocation']==dict(name='technical_partial',initial_accounts=expected,source_event_id=1,kind='initial_ownership_not_income')
  BindingAudit.validate_initial_jobs(self,normalized,jobs)
 def salary(self,w,b):
  if not self.VARIABLE_WAGES:return 10
  j=self.jobs[w];assert j['business']==b and type(j['wage']) is int and 1<=j['wage']<=20
  if w in self.bound['active_terms']:assert self.bound['terms'][self.bound['active_terms'][w]]['wage']==j['wage']
  return j['wage']
 def entry_salary(self,w,b,p):
  if not self.VARIABLE_WAGES:return 10
  origin=self.wages['offers'][p['id']];bid=self.wages['bids'][origin['bid']]
  assert bid['worker']==w and bid['business']==b and bid['wage']==p['wage'] and bid['status']=='accepted'
  return p['wage']
 def wage_label(self):return 'by_term' if self.VARIABLE_WAGES else 10
 def retained_salaries(self,b):
  return [dict(id=w,wage=self.jobs[w]['wage'],term=self.bound['active_terms'][w],end_day=self.jobs[w]['end_day']) for w in self.staff(b) if self.jobs[w]['end_day']>self.day+1]
 def firm_observation(self,b):
  old=self._capture_vacancy(b);p=old['production'];p.update(committed_payroll=self.committed(b),funded_workers=self.funded(b))
  expiring=[w for w in self.staff(b) if self.jobs[w]['end_day']<=self.day+1]
  remain=min(p['output_stock'],max(0,old['previous_sales']-self.state['sales'].get(str(self.day),{}).get(b,0))) if self.minute<dict(farm=660,mill=780,bakery=1050,brewery=1050)[b] else 0
  o=dict(owner=OWNERS[b],business=b,day=self.day,production=p,demand=old['previous_sales'],remaining_sales=remain,retained=len(self.staff(b))-len(expiring),expiring=expiring,reserved=old['reserved'],capacity=self.firms[b]['assets']['daily_slots'],farm_cap=old['farm_cap'],disabled=old['disabled'],arrears=self.arrears(b),mode=self.contract_mode)
  if b!='farm':o['input_reliability']=copy.deepcopy(self.input_points[b])
  return o
 def rows(self,b,statuses=('submitted',)):
  return [dict(id=r['worker'],wage=r['wage'],incumbent=self.affiliations.get(r['worker'],{}).get('business')==b,bid=r['id']) for r in self.wages['bids'].values() if r['day']==self.day and r['business']==b and r['status'] in statuses]
 def portfolio(self,b,rows):
  o=self.firm_observation(b);id=f'wage_notice:{self.day:04}:{b}'
  if id in self.wages['notices']:o['capacity']=min(o['capacity'],o['retained']+self.wages['notices'][id]['vacancies'])
  retained=self.retained_salaries(b)
  return dict(observation=o,retained=retained,proposal=select(o,retained,rows))
 def context_terms(self,b):return dict(business=b,role=self.firms[b]['industry'],schedule=list(WINDOWS[b]),term_days=3,guaranteed_days=1,minimum_wage=1,maximum_wage=20)
 def own(self,w):
  j=self.jobs.get(w,{});s=self.wages
  return dict(worker=w,day=self.day,minute=self.minute,money=self.entities[w]['money'],inventory=copy.deepcopy(self.entities[w]['inventory']),bread_eaten=w in self.eaten,ale_drunk=w in self.drank,business=self.affiliations.get(w,{}).get('business',''),end_day=j.get('end_day',0),eligible=not j.get('active',False) or j['end_day']==self.day+1,anchor=copy.deepcopy(s['anchors'][w]),quotes=copy.deepcopy(s['quotes'].get(w,{})),history=copy.deepcopy(s['memory'].get(w,[])),wage_history=self.worker(w)['history'],owed_wages=sum(c['amount']-c['paid'] for c in self.bound['obligations'].values() if c['worker']==w),current_term=copy.deepcopy(self.bound['terms'].get(self.bound['active_terms'].get(w,''),{})),shopping_history=copy.deepcopy(s['shopping'].get(w,[])),notices=copy.deepcopy(s['known'].get(w,{}).get('notices',[])),notice_event_id=s['known'].get(w,{}).get('event_id'),unobservables=['other_bids','firm_cash','future_sales','true_hiring_chance','guaranteed_food_stock'])
 def valid_entry(self,w,p):
  s=self.wages;origin=s['offers'].get(p['id'],{});bid=s['bids'].get(origin.get('bid'),{})
  if not bid or bid['worker']!=w or bid['business']!=p['business'] or bid['wage']!=p['wage']:return 'signed_bid_terms_changed'
  if type(p['wage']) is not int or not 1<=p['wage']<=20 or p['cycle_days']!=1 or p['guaranteed_shifts']!=1 or p['duration_days']!=3 or p['required_skills']:return 'invalid_wage_terms'
  if bid['day']!=self.day or not s['notices'][bid['notice']]['active'] or not p['active'] or p['reserved']<1:return 'expired_or_closed_notice'
  if self.jobs[w]['active'] and self.jobs[w]['end_day']>self.day+1:return 'binding_term_active'
  rows=self.rows(p['business'],('offered','accepted'))
  if not any(r['id']==w for r in rows):rows.append(dict(id=w,wage=bid['wage'],incumbent=self.affiliations.get(w,{}).get('business')==p['business'],bid=bid['id']))
  chosen=self.portfolio(p['business'],rows)['proposal']['selected']
  return 'changed_capacity_or_funding' if not all(r['id'] in chosen for r in rows) else ''
 def apply(self,e):
  a,w,b,d=(e[k] for k in ('action','actor','target','details'));s=self.wages
  if a=='wage_fixed_admission_observed':
   assert not self.VARIABLE_WAGES;self.board(w);assert OWNERS[b]==w;o=self.firm_observation(b);retained=self.retained_salaries(b)
   virtual=[dict(id=f'slot:{i}',wage=1,incumbent=False) for i in range(o['capacity']-o['retained'])]
   assert d==dict(observation=o,retained=retained,minimum_wage=select(o,retained,virtual))
  elif a=='wage_fixed_worker_observed':
   assert not self.VARIABLE_WAGES;self.board(w);o=self.own(w);known=self.state['known_jobs'][w];o.update(notices=known['notices'],notice_event_id=known['event_id'])
   assert d==dict(observation=o,native_observation_event_id=known['event_id'])
  elif a=='wage_vacancy_assessed':
   assert self.VARIABLE_WAGES;self.board(w);assert OWNERS[b]==w;o=self.firm_observation(b);retained=self.retained_salaries(b)
   virtual=[dict(id=f'slot:{i}',wage=1,incumbent=False) for i in range(o['capacity']-o['retained'])]
   assert d==dict(observation=o,retained=retained,proposal=select(o,retained,virtual));self.assessments[b]=e['id']
  elif a=='wage_notice_posted':
   self.board(w);n=d['notice'];source=self.events[self.assessments[b]-1];assert source['day']==self.day and source['target']==b and source['actor']==w
   count=len(source['details']['proposal']['selected']);id=f'wage_notice:{self.day:04}:{b}'
   assert count>0 and id not in s['notices'] and n==dict(id=id,business=b,employer=OWNERS[b],day=self.day,start_day=self.day+1,end_day=self.day+4,vacancies=count,context=self.context_terms(b),active=True,assessment_event_id=source['id'])
   s['notices'][id]=copy.deepcopy(n)
  elif a=='wage_board_observed':
   self.board(w);assert w in s['anchors'];expected=[copy.deepcopy(n) for id,n in sorted(s['notices'].items()) if n['day']==self.day and n['active']]
   assert d==dict(notices=expected,witnesses=self.witnesses());s['known'][w]=dict(day=self.day,event_id=e['id'],notices=expected)
  elif a=='wage_outcome_observed':
   self.board(w);bid=s['bids'][d['bid']];assert bid['worker']==w and bid['day']<self.day and 'observation_event_id' not in bid;close=s['settlements'][bid['notice']]
   outcome='hired' if bid['status']=='hired' else 'lost_filled' if bid['status']=='submitted' and close['filled']>0 else 'unknown'
   row=dict(bid=bid['id'],business=bid['business'],context=bid['context'],wage=bid['wage'],outcome=outcome,bid_event_id=bid['bid_event_id'],closure_event_id=close['event_id'],day=self.day)
   assert d==row;bid['observation_event_id']=e['id'];row=copy.deepcopy(row);row['observation_event_id']=e['id']
   if outcome!='unknown':s['memory'][w]=(s['memory'].get(w,[])+[row])[-6:]
  elif a=='wage_worker_decision':
   self.board(w);o=self.own(w);expected=worker(o);assert d==dict(observation=o,proposal=expected) and b==expected['notice'];self.decisions[w]=e['id']
  elif a=='wage_bid_submitted':
   self.board(w);bid=d['bid'];n=s['notices'][bid['notice']];assert n['active'] and n['day']==self.day and n in s['known'][w]['notices'];self.eligible(w,dict(business=n['business']))
   assert type(bid['wage']) is int and 1<=bid['wage']<=20 and not any(r['worker']==w and r['day']==self.day for r in s['bids'].values())
   decision=self.decisions.get(w);decision=decision if decision and self.events[decision-1]['day']==self.day else None
   if decision:
    p=self.events[decision-1]['details']['proposal'];assert p['action']=='bid' and p['notice']==n['id'] and p['wage']==bid['wage']
   else:assert self.technical in ('manual_mixed','manual_partial','manual_no_show')
   expected=dict(id=f'wage_bid:{self.day:04}:{w}',worker=w,business=n['business'],notice=n['id'],context=n['context'],day=self.day,wage=bid['wage'],source_event_id=s['known'][w]['event_id'],decision_event_id=decision,status='submitted')
   assert bid==expected and b==n['business'];s['bids'][bid['id']]=copy.deepcopy(bid);s['bids'][bid['id']]['bid_event_id']=e['id']
  elif a=='wage_portfolio_selected':
   self.board(w);assert OWNERS[b]==w and (b not in self.selections or self.events[self.selections[b]-1]['day']<self.day);expected=self.portfolio(b,self.rows(b));assert d==expected;self.selections[b]=e['id']
  elif self.VARIABLE_WAGES and a=='job_posted':
   self.board(w);p=d['posting'];person=p['id'].split(':')[-1];bid=s['bids'][f'wage_bid:{self.day:04}:{person}'];selection=self.selections[b]
   assert bid['business']==b and bid['status']=='submitted' and OWNERS[b]==w and person in self.events[selection-1]['details']['proposal']['selected'] and person in self.portfolio(b,self.rows(b,('submitted','offered','accepted')))['proposal']['selected']
   assert p==dict(id=f'wage_contract:{self.day:04}:{b}:{person}',employer=w,business=b,role=self.firms[b]['industry'],wage=bid['wage'],guaranteed_shifts=1,cycle_days=1,duration_days=3,required_skills=[],vacancies=1,reserved=0,filled=0,active=True) and p['id'] not in self.postings
   self.postings[p['id']]=copy.deepcopy(p);s['offers'][p['id']]=dict(bid=bid['id'],selection_event_id=selection,application_id=p['id']+':'+person)
  elif self.VARIABLE_WAGES and a=='application_submitted':
   self.board(w);app=d['application'];p=self.postings[app['posting']];self.eligible(w,p);origin=s['offers'][p['id']];bid=s['bids'][origin['bid']]
   assert bid['worker']==w and bid['status']=='submitted' and app==dict(id=origin['application_id'],worker=w,posting=p['id'],status='applied') and app['id'] not in self.apps
   self.apps[app['id']]=copy.deepcopy(app)
  elif self.VARIABLE_WAGES and a=='job_offer_made':
   self.board(w);app=self.apps[d['application_id']];self.board(app['worker']);p=self.postings[app['posting']];bid=s['bids'][s['offers'][p['id']]['bid']]
   assert app['status']=='applied' and bid['status']=='submitted' and p['active'] and p['reserved']==0 and p['employer']==w and self.own(app['worker'])['eligible']
   assert d==dict(application_id=app['id'],worker=app['worker'],posting=p['id']);app['status']='offered';p['reserved']=1;bid.update(status='offered',application_id=app['id'])
  elif a=='wage_offer_observed':
   self.board(w);offers=[]
   for id,origin in s['offers'].items():
    app=self.apps[origin['application_id']]
    if app['worker']==w and app['status']=='offered' and self.postings[id]['active']:offers.append(dict(application_id=app['id'],terms=copy.deepcopy(self.postings[id]),bid=origin['bid']))
   assert d==dict(offers=offers)
   if offers:s['known'][w]['offer_event_id']=e['id']
  elif a=='wage_acceptance_decision':
   self.board(w);observed=self.events[d['offer_event_id']-1];assert observed['action']=='wage_offer_observed' and observed['actor']==w and observed['id']==s['known'][w]['offer_event_id']
   offer=observed['details']['offers'][0];bid=s['bids'][offer['bid']];o=self.own(w)
   assert b==bid['business'] and d==dict(observation=o,offer_event_id=observed['id'],proposal=acceptance(o,offer,bid))
  elif a=='wage_offer_declined':
   self.board(w);app=self.apps[d['application_id']];p=self.postings[app['posting']];source=self.events[d['source_event_id']-1]
   assert source['action']=='wage_offer_observed' and source['actor']==w and source['id']==s['known'][w]['offer_event_id'] and any(o['application_id']==app['id'] for o in source['details']['offers'])
   assert app['worker']==w and app['status']=='offered' and p['active'] and p['reserved']==1
   app['status']='declined';p.update(active=False,reserved=0);s['bids'][s['offers'][p['id']]['bid']]['status']='declined'
  elif self.VARIABLE_WAGES and a=='offer_accepted':
   self.board(w);app=self.apps[d['application_id']];p=self.postings[app['posting']];self.board(p['employer']);self.eligible(w,p);known=s['known'][w]
   assert app['worker']==w and app['status']=='offered' and p['active'] and p['reserved']==1 and not self.valid_entry(w,p)
   observed=self.events[known['offer_event_id']-1];assert observed['action']=='wage_offer_observed' and observed['actor']==w and any(v['application_id']==app['id'] for v in observed['details']['offers'])
   expected=dict(posting=p['id'],application_id=app['id'],effective_day=self.day+1);assert d==dict(application_id=app['id'],pending=expected)
   self.pending[w]=expected;app['status']='accepted';s['bids'][s['offers'][p['id']]['bid']]['status']='accepted'
  elif a=='wage_boundary_assessed':
   assert self.minute==1440 and OWNERS[b]==w;packet=self.portfolio(b,self.rows(b,('offered','accepted')));reason=''
   for row in self.rows(b,('accepted',)):
    reason=self.valid_entry(row['id'],self.postings[self.pending[row['id']]['posting']])
    if reason:break
   assert d==dict(packet=packet,reason=reason);self.revalidations[e['id']]=dict(business=b,pending=copy.deepcopy({who:p for who,p in self.pending.items() if self.postings[p['posting']]['business']==b}),reason=reason)
  elif a=='wage_notice_cancelled':
   self.board(w);n=s['notices'][d['notice']];assert n['employer']==w and n['id']==b and n['active'] and n['day']==self.day;n['active']=False
  elif a=='wage_pending_cancelled':
   source=self.events[d['validation_event_id']-1];assert source['id']<e['id'] and source['day']==self.day
   if d['reason']=='withdrawn':assert source['action']=='wage_notice_cancelled' and not s['notices'][source['details']['notice']]['active']
   else:assert self.revalidations[source['id']]['reason']==d['reason'] and self.revalidations[source['id']]['pending'][w]==d['pending']
   pending=self.pending.pop(w);assert d['pending']==pending and self.postings[pending['posting']]['business']==b
   self.state['contingent'].pop(w);self.resignations.pop(w,None);app=self.apps[pending['application_id']];app['status']='closed';p=self.postings[pending['posting']];p.update(active=False,reserved=0);s['bids'][s['offers'][p['id']]['bid']]['status']='cancelled'
  elif self.VARIABLE_WAGES and a=='labor_boundary':
   assert self.minute==1440 and d==dict(effective_day=self.day+1,pending=self.pending)
   for person,pending in self.pending.items():
    assert self.affiliations.get(person,{})==self.state['contingent'][person]['old'] and not self.valid_entry(person,self.postings[pending['posting']])
  elif a=='wage_contract_started':
   bid=s['bids'][d['bid']];receipt=self.events[d['employment_event_id']-1];assert receipt['action']=='employment_started' and receipt['actor']==w and receipt['target']==b and bid['status']=='accepted'
   assert d==dict(bid=bid['id'],term=self.bound['active_terms'][w],employment_event_id=receipt['id'],wage=bid['wage']) and self.jobs[w]['wage']==bid['wage']
   bid.update(status='hired',term=d['term'],employment_event_id=receipt['id'])
  elif a=='wage_offer_expired':
   assert self.minute==1440;bid=s['bids'][d['bid']];assert bid['worker']==w and bid['business']==b and bid['status']=='offered' and bid['application_id']==d['application_id']
   bid['status']='unaccepted';app=self.apps[d['application_id']];app['status']='closed';self.postings[app['posting']].update(active=False,reserved=0)
  elif a=='wage_notice_settled':
   assert self.minute==1440;n=s['notices'][d['notice']];assert n['day']==self.day and n['employer']==w and n['business']==b and n['id'] not in s['settlements']
   hires=[r for r in s['bids'].values() if r['notice']==n['id'] and r['status']=='hired'];expected=dict(notice=n['id'],filled=len(hires),status='filled' if len(hires)==n['vacancies'] else 'partially_filled' if hires else 'closed_without_hire',day=self.day,source_ids=[r['employment_event_id'] for r in hires]);assert d==expected
   n['active']=False;s['settlements'][n['id']]=dict(expected,event_id=e['id'])
  else:super().apply(e)
 def after(self,e):
  super().after(e);s=self.wages;a,w,b,d=(e[k] for k in ('action','actor','target','details'))
  if a=='consumer_decision' and w in s['anchors']:
   row=dict(day=self.day,minute=self.minute,source_event_id=e['id'],item=d['item'],purchased=d['purchased'],price=d['observation']['prices'].get(d['item']),money_before=d['observation']['money'],reason=d['proposal']['reason'],success=e['success'])
   s['shopping'][w]=(s['shopping'].get(w,[])+[row])[-6:]
  if e['success'] and a in ('wage_vacancy_assessed','wage_fixed_admission_observed'):
   for who in sorted(s['anchors']):
    key=self.day,who
    if key in self.board_days:continue
    p=self.people[who];j=self.jobs[who];active=j['active'] and who in self.affiliations;term=self.bound['terms'].get(self.bound['active_terms'].get(who,''),{})
    self.board_days[key]=dict(day=self.day,worker=who,source_event_id=e['id'],board_present=p['active'] and p['tile']==SITES['bakery'] and p['activity']=='board' and p['until']==960,activity=p['activity'],tile=copy.deepcopy(p['tile']),eligible=not j['active'] or j['end_day']==self.day+1,employer=self.affiliations.get(who,{}).get('business',''),contract_wage=j['wage'] if active else None,term=term.get('id',''),end_day=j['end_day'],money=self.entities[who]['money'],owed_wages=sum(c['amount']-c['paid'] for c in self.bound['obligations'].values() if c['worker']==who))
  if not e['success']:return
  if a=='spatial_encounter' and d['kind']=='inspected' and w in s['anchors']:
   for item,q in self.quotes[b].items():
    if item in ('bread','ale') and q['active']:s['quotes'].setdefault(w,{})[item]=dict(quote=dict(q,available=min(q['limit'],self.entities[b]['inventory'][item])),inspection_event_id=e['id'],day=self.day,minute=self.minute)
  if a=='employment_started':s['anchors'][w]=dict(wage=d['job']['wage'],term=self.bound['active_terms'].get(w,f'term:{self.day+1:04}:{b}:{w}'),source_event_id=e['id'])
 def finish(self):
  super().finish();assert self.wages==self.r['final']['wage_market'],'wage knowledge/terms state drift'


def analyze(data):
 observer=WageAudit();result=replay(data,observer,fixture=True);result['source']['base']=BASE
 result['input']=dict(orders=observer.input_orders,forecasts=observer.input_forecasts,projections=observer.input_projections)
 result['board_days']=list(observer.board_days.values())
 return result
