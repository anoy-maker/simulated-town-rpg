"""M30 independent integer affordability and small portfolio verifier; no NPC import."""
import copy,itertools
from brewery_audit import basket,planned

ARMS=('fixed10_instrumented','worker_bids')

def budget(o,wage):
 cash=o['money'];goods=copy.deepcopy(o['inventory']);rows=[];benefit=0
 prices={k:v['quote']['unit_price'] for k,v in o['quotes'].items()};stock=dict.fromkeys(prices,1)
 for day in range(4):
  if day:cash+=wage
  bread=int(day>0 or not o['bread_eaten']);ale=int(day>0 or not o['ale_drunk']);held_bread=min(bread,goods.get('bread',0));held_ale=min(ale,goods.get('ale',0))
  choice=basket(dict(money=cash,need_bread=bread-held_bread,need_ale=ale-held_ale,prices=prices,stock=stock,bread_ceiling=10**9))
  goods['bread']=goods.get('bread',0)-held_bread;goods['ale']=goods.get('ale',0)-held_ale;cash=choice['remaining']
  row=dict(offset=day,wage_before_shopping=wage if day else 0,basket=choice,held_bread=held_bread,held_ale=held_ale,closing_cash=cash,availability='assumed_for_affordability_only')
  if day:rows.append(row);benefit+=100*(held_bread+choice['bread'])+5*(held_ale+choice['ale'])
  else:prelude=row
 return dict(wage=wage,prelude=prelude,days=rows,utility=benefit+cash,terminal_cash=cash)

def worker(o):
 reason='binding_term_active' if not o['eligible'] else 'unknown_bread_quote' if 'bread' not in o['quotes'] else 'no_observed_positive_vacancy'
 out=dict(action='abstain',notice='',wage=0,reason=reason,baseline={},budgets=[],candidates=[],score=dict(numerator=0,denominator=1))
 if not o['eligible'] or 'bread' not in o['quotes'] or not o['notices']:return out
 out['baseline']=budget(o,0);out['budgets']=[budget(o,w) for w in range(1,21)]
 for n in o['notices']:
  if not n['active'] or n['vacancies']<1:continue
  for w in range(1,21):
   alpha,beta=(2,1) if w<=o['anchor']['wage'] else (1,4)
   history=[h for h in o['history'] if h['business']==n['business'] and h['context']==n['context'] and h['wage']==w]
   wins=sum(h['outcome']=='hired' for h in history);losses=sum(h['outcome']=='lost_filled' for h in history);gain=out['budgets'][w-1]['utility']-out['baseline']['utility']
   score=dict(numerator=(alpha+wins)*gain,denominator=alpha+beta+wins+losses)
   out['candidates'].append(dict(notice=n['id'],business=n['business'],wage=w,alpha=alpha,beta=beta,wins=wins,losses=losses,source_ids=[h['observation_event_id'] for h in history],p_num=alpha+wins,p_den=score['denominator'],gain=gain,score=score,budget_index=w-1))
   comparison=score['numerator']*out['score']['denominator']-out['score']['numerator']*score['denominator']
   if score['numerator']>0 and (comparison>0 or comparison==0 and (w>out['wage'] or w==out['wage'] and n['id']<out['notice'])):
    out.update(action='bid',notice=n['id'],wage=w,score=score,reason='best_positive_belief_weighted_private_utility')
 return out

def project(o,salaries):
 assert len(salaries)<=3 and all(type(w) is int and 1<=w<=20 for w in salaries)
 p=copy.deepcopy(o['production']);payroll=sum(salaries);stock=max(0,p['output_stock']-o['remaining_sales']);cash=p['cash']+o['remaining_sales']*p['output_price']-o['arrears'];raw=p['input_stock']
 receipts=inputs=0;feasible=cash>=0;days=[];ratio=o.get('input_reliability',{});n=ratio.get('numerator',1);d=ratio.get('denominator',1)
 if p['rule']['input']:assert 0<n<=d<=12
 for day in range(1,4):
  p.update(cash=max(0,cash-payroll),output_stock=stock,input_stock=raw,harvest_remaining=o['farm_cap'],workers=[dict(id=f'slot:{i}',wage=0,available=cash>=payroll) for i in range(len(salaries))])
  full=planned(p);k=full['lots'];predicted=k
  if p['rule']['input']:
   whole,remainder=divmod(k*n,d);predicted=min(k,whole+int(2*remainder>=d))
  shifts=full['shifts']
  if p['rule']['input']:shifts=min(shifts,(raw+predicted*p['rule']['take'])//p['rule']['take'])
  output=min(shifts*7,o['farm_cap']) if not p['rule']['input'] else shifts*p['rule']['make']
  cost=predicted*p['rule']['take']*p['input_price'];opening=cash;cash-=cost+payroll;inputs+=cost;feasible=feasible and cash>=0
  owned=raw;raw+=(predicted-shifts)*p['rule']['take'];stock+=output;sold=min(stock,o['demand']);stock-=sold;cash+=sold*p['output_price'];receipts+=sold*p['output_price']
  days.append(dict(projected_day=day,owned_input_before=owned,desired_lots=k,predicted_lots=predicted,input_cost=cost,shifts=shifts,output=output,owned_input_after=raw,output_stock_after=stock,sold=sold,opening_cash=opening,cash_before_sales=opening-cost-payroll,closing_cash=cash,guaranteed_wages=payroll))
 return dict(summary=dict(headcount=len(salaries),receipts=receipts,inputs=inputs,guaranteed_wages=3*payroll,contribution=receipts-inputs-3*payroll,feasible=feasible,cash=cash),days=days)

def evaluate(o,retained,asks):
 salaries=[w['wage'] for w in retained+list(asks)];p=project(o,salaries);front=o['arrears']+p['days'][0]['input_cost']+sum(salaries)
 return dict(ids=[w['id'] for w in asks],salaries=salaries,projection=p,front_cost=front,front_funded=o['production']['cash']>=front,incumbents=sum(w['incumbent'] for w in asks))

def select(o,retained,bidders):
 assert len(retained)<=o['capacity'] and len(bidders)<=11
 rows=sorted(bidders,key=lambda r:r['id']);maximum=0 if o['disabled'] else o['capacity']-len(retained)
 groups=sorted((tuple(g) for k in range(maximum+1) for g in itertools.combinations(rows,k)),key=lambda g:tuple(w['id'] for w in g))
 candidates=[evaluate(o,retained,g) for g in groups];lookup={tuple(c['ids']):c for c in candidates};base=lookup[()];best=base
 for c in candidates:
  value=c['projection']['summary'];ids=c['ids']
  if not ids or not c['front_funded'] or not value['feasible'] or value['contribution']<=base['projection']['summary']['contribution']:continue
  if any(value['contribution']<=lookup[tuple(x for x in ids if x!=w)]['projection']['summary']['contribution'] for w in ids):continue
  prior=best['projection']['summary']['contribution']
  if value['contribution']>prior or value['contribution']==prior and (c['incumbents']>best['incumbents'] or c['incumbents']==best['incumbents'] and c['ids']<best['ids']):best=c
 return dict(selected=best['ids'],baseline=base,best=best,candidates=candidates,reason='strict_positive_funded_portfolio' if best['ids'] else 'no_profitable_funded_submitted_portfolio')


def acceptance(o,offer,request):
 reason='binding_term_active' if not o['eligible'] else 'request_terms_mismatch' if offer['bid']!=request['id'] or offer['terms']['wage']!=request['wage'] else 'unknown_bread_quote' if 'bread' not in o['quotes'] else 'positive_actual_offer_utility'
 gain=budget(o,request['wage'])['utility']-budget(o,0)['utility'] if reason=='positive_actual_offer_utility' else 0
 return dict(accepts=gain>0,gain=gain,reason=reason if gain>0 or reason!='positive_actual_offer_utility' else 'nonpositive_actual_offer_utility')
