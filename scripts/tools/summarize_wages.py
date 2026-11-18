#!/usr/bin/env python3
"""M30 compact audited wage formation, named household days and exclusion evidence."""
import argparse,csv,json,hashlib,statistics,shutil
from collections import defaultdict,Counter
from pathlib import Path
from brewery_feasibility import OWNERS
from run_wages import load_trace
from run_brewery import digest
from run_economic_diagnostics import write_rows,write_json,flatten
from wage_calculation import evaluate


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--traces',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
 for label in ['runs','performance','parity']:shutil.copy2(a.input/(label+'.csv'),a.output/('M30_'+label.upper()+'.csv'))
 tables=defaultdict(list);outcomes={};stats=[];matched={}
 for file in sorted((a.input/'analyses').glob('*-30-*.json')):
  x=json.loads(file.read_text());data=load_trace(a.traces/(file.stem+'-1.json.gz'));r=data['report'];arm=r['wage_market']['arm'];allocation=r['cash_allocation']['name'];events=data['events'];tag=dict(condition=r['condition'],arm=arm,allocation=allocation,stratum='core' if allocation=='original' else 'household_sensitivity',seed=42)
  assert x['source']['report_sha256']==digest(dict(report=r));matched[r['condition'],allocation,arm]=r
  board={(z['day'],z['worker']):z for z in x['board_days']};by=defaultdict(list)
  for e in events:by[e['day'],e['action']].append(e)
  decisions={};native_apps={};offers={};accepted={};started={};closures={};claim_rows={};shops={};late=defaultdict(list);portfolios={};F_projections={};F_fixed={};low=defaultdict(list);spells=defaultdict(list);employee_paid=[];actual_paid=[];worker_nominal=defaultdict(list)
  for e in events:
   d=e['details'];day=e['day'];w=e['actor'];act=e['action']
   if act=='input_forecast_projection':F_projections[day,e['target']]=e
   if act=='wage_fixed_admission_observed':F_fixed[day,e['target']]=e
   if act in ('wage_worker_decision','wage_fixed_worker_observed'):decisions[day,w]=e
   if act=='consumer_decision':
    shops[day,w,d['item']]=e
    tables['SHOPPING'].append(flatten(dict(**tag,day=day,minute=e['minute'],buyer=w,cohort='visitor' if w.startswith('visitor:') else 'owner' if w in OWNERS.values() else 'nonowner',item=d['item'],money=d['observation']['money'],need=d['observation']['need_'+d['item']],stock=d['observation']['stock'].get(d['item']),price=d['observation']['prices'].get(d['item']),purchased=d['purchased'],event_id=e['id'])))
   if act=='transfer_money' and e['success']:
    tables['TRANSFERS'].append(dict(**tag,day=day,minute=e['minute'],payer=w,recipient=e['target'],amount=d['amount'],purpose=d['purpose'],event_id=e['id']))
    if e['minute']>960:late[day,e['target']].append(e)
   if act=='application_submitted' and e['success']:native_apps[day,w]=e
   if act=='job_offer_made' and e['success']:offers[day,d['worker']]=e
   if act=='offer_accepted' and e['success']:accepted[day,w]=e
   if act=='employment_started' and e['success']:started[day,w]=e
   if act=='contract_shift':closures[day,w]=e
   if act=='guaranteed_wage_due':claim_rows[day,w]=r['final']['binding_contracts']['obligations'][d['claim']['id']]
   if act=='wage_worker_decision':
    o=d['observation'];proposal=d['proposal']
    for budget in proposal['budgets']:tables['BUDGETS'].append(flatten(dict(**tag,day=day,worker=w,source_event_id=e['id'],baseline_utility=proposal['baseline']['utility'],**budget)))
    for candidate in proposal['candidates']:tables['BELIEFS'].append(flatten(dict(**tag,day=day,worker=w,source_event_id=e['id'],anchor=o['anchor'],chosen=candidate['notice']==proposal['notice'] and candidate['wage']==proposal['wage'],**candidate)))
   if act in ('wage_portfolio_selected','wage_vacancy_assessed','wage_boundary_assessed'):
    packet=d['packet'] if act=='wage_boundary_assessed' else d if act=='wage_portfolio_selected' else dict(observation=d['observation'],retained=d['retained'],proposal=d['proposal'])
    if act=='wage_portfolio_selected':portfolios[day,e['target']]=e
    for c in packet['proposal']['candidates']:
     tables['FIRM_COMPARISONS'].append(flatten(dict(**tag,day=day,business=e['target'],stage=act,event_id=e['id'],selected=c['ids']==packet['proposal']['selected'],current_cash=packet['observation']['production']['cash'],current_arrears=packet['observation']['arrears'],retained=packet['retained'],**c)))
  for (day,b),e in F_fixed.items():
   original=F_projections[day,b];d=e['details'];n=original['details']['headcount'];o=d['observation'];asks=[dict(id=f'slot:{i}',wage=10,incumbent=False) for i in range(n-o['retained'])]
   c=evaluate(o,d['retained'],asks)
   tables['F_FIXED_ADMISSION'].append(flatten(dict(**tag,day=day,business=b,event_id=e['id'],native_projection_event_id=original['id'],new_commitments=n-o['retained'],current_cash=o['production']['cash'],current_arrears=o['arrears'],**c)))
  for id,e in r['initial']['entities'].items():tables['INITIAL_ACCOUNTS'].append(dict(**tag,account=id,kind=e['kind'],coins=e['money'],source_event_id=1))
  for f in x['firm_days']:tables['FIRM_DAYS'].append(flatten(dict(**tag,**f)))
  for q in x['input']['orders']:tables['INPUT_ORDERS'].append(flatten(dict(**tag,**q)))
  for term in r['final']['binding_contracts']['terms'].values():tables['TERMS'].append(flatten(dict(**tag,**term)))
  for bid in r['final']['wage_market']['bids'].values():
   close=r['final']['wage_market']['settlements'].get(bid['notice'],{});row=dict(**tag,**bid);row['actual_hired']=bid['status']=='hired';row['other_slot_filled']=close.get('filled',0)>0;row['outcome_observed_by_horizon']='observation_event_id' in bid;tables['BIDS'].append(flatten(row))
  for f in x['failure_attributions']:
   row=dict(**tag,**f,late_income=sum(e['details']['amount'] for e in late[f['day'],f['buyer']]),late_event_ids=[e['id'] for e in late[f['day'],f['buyer']]])
   tables['MISSED_MEALS'].append(flatten(row))
  for d in r['day_results']:
   day=d['day'];rows=[]
   for w,h in d['households'].items():
    previous=r['initial']['entities'][w]['money'] if day==1 else r['day_results'][day-2]['households'][w]['cash']
    assert previous+h['wages']+h['distributions']-h['bread_spending']-h['ale_spending']==h['cash']
    shop=shops.get((day,w,'bread'));ob=shop['details']['observation'] if shop else {};q=ob.get('prices',{}).get('bread');stock=ob.get('stock',{}).get('bread');money=ob.get('money');c=claim_rows.get((day,w),{});close=closures.get((day,w));b=board.get((day,w),{})
    row=dict(**tag,day=day,resident=w,owner=w in OWNERS.values(),opening_cash=previous,closing_cash=h['cash'],wages=h['wages'],distributions=h['distributions'],bread_spending=h['bread_spending'],ale_spending=h['ale_spending'],ale_consumed=h['ale_consumed'],meals=h['meals'],missed=h['missed_meals'],inventory=h['inventory'],employer=b.get('employer',''),contract_salary=close['details']['expected_compensation'] if close else None,earned_wage=c.get('amount',0),claim_paid_by_horizon=c.get('paid',0),claim_unpaid=c.get('amount',0)-c.get('paid',0),standby=bool(close and close['details']['guaranteed_wage_due']>0 and not close['success']),fully_paid_standby=bool(close and not close['success'] and c and c['paid']==c['amount']),claim=c.get('id'),claim_event_id=next((z['id'] for z in by[day,'guaranteed_wage_due'] if z['actor']==w),None),shopping_event_id=shop['id'] if shop else None,shopping_cash=money,known_bread_price=q,shopping_stock=stock,can_afford_bread=money>=q if q is not None and money is not None else None,cash_blocked_with_stock=ob.get('need_bread',0)>0 and money<q and stock>0 if q is not None and money is not None and stock is not None else None,earned_below6=0<c.get('amount',0)<6,earned_below10=0<c.get('amount',0)<10,late_income=sum(e['details']['amount'] for e in late[day,w]),late_event_ids=[e['id'] for e in late[day,w]])
    tables['RESIDENT_DAYS'].append(flatten(row));rows.append(row)
    if row['earned_below6']:low[w].append(day)
    for threshold in (6,10):
     if 0<row['earned_wage']<threshold:spells[w,threshold].append(day)
    if c and c['paid']>0:employee_paid.append(c['amount']);worker_nominal[w].append(c['amount'])
    if h['wages']>0:actual_paid.append(h['wages'])
   cash_block=sum(f['day']==day and f['immediate_blocker']=='household_purchasing_power' for f in x['failure_attributions']);stock_fail=sum(f['day']==day and f['immediate_blocker']=='stockout_of_solvent_request' for f in x['failure_attributions'])
   assert d['unmet_meals']==cash_block+stock_fail
   tables['DAYS'].append(dict(**tag,day=day,meals=d['resident_meals'],missed=d['unmet_meals'],visitor_bread=d['visitor_bread'],resident_ale=sum(h['ale_consumed'] for h in d['households'].values()),visitor_ale=sum(v['ale_consumed'] for v in d['visitors'].values()),cash_blocked=cash_block,solvent_stockout=stock_fail,owner_missed=sum(h['missed_meals'] for w,h in d['households'].items() if w in OWNERS.values()),nonowner_missed=sum(h['missed_meals'] for w,h in d['households'].items() if w not in OWNERS.values()),cash_wages=sum(h['wages'] for h in d['households'].values()),distributions=sum(h['distributions'] for h in d['households'].values()),household_cash=sum(h['cash'] for h in d['households'].values()),firm_cash=sum(f['cash'] for f in d['firms'].values()),visitor_cash=d['external_cash'],circulation=d['circulation'],productive=d['shifts'],**d['production']))
  for (day,w),b in board.items():
   own=decisions.get((day,w));o=own['details']['observation'] if own else {};application=native_apps.get((day,w));firm=application['target'] if application else '';bid=next((z for z in r['final']['wage_market']['bids'].values() if z['day']==day and z['worker']==w),None)
   firm=bid['business'] if bid else firm
   observed=o.get('notices',[]);employer_apps=len([z for z in r['final']['wage_market']['bids'].values() if z['day']==day and z['business']==firm]) if bid else len([z for (d0,p0),z in native_apps.items() if d0==day and z['target']==firm]) if application else None
   selected=portfolios.get((day,bid['business'])) if bid else None;best_with=None;chosen_value=None;front=None;feasible=[];admissible=[];best_admissible=None;financial_rank=None;comparison_ids=[]
   if selected:
    candidates=[c for c in selected['details']['proposal']['candidates'] if w in c['ids']];feasible=[c for c in candidates if c['front_funded'] and c['projection']['summary']['feasible']]
    best_with=max((c['projection']['summary']['contribution'] for c in feasible),default=None);chosen_value=selected['details']['proposal']['best']['projection']['summary']['contribution'];front=any(c['front_funded'] for c in candidates)
    allc=selected['details']['proposal']['candidates'];lookup={tuple(c['ids']):c['projection']['summary']['contribution'] for c in allc};base=lookup[()]
    admissible=[c for c in feasible if c['projection']['summary']['contribution']>base and all(c['projection']['summary']['contribution']>lookup[tuple(z for z in c['ids'] if z!=id)] for id in c['ids'])]
    best_admissible=max((c['projection']['summary']['contribution'] for c in admissible),default=None)
    financial_rank=1+len({c['projection']['summary']['contribution'] for c in allc if c['front_funded'] and c['projection']['summary']['feasible'] and best_admissible is not None and c['projection']['summary']['contribution']>best_admissible}) if best_admissible is not None else None
    comparison_ids=[selected['id']]
   if not b['board_present']:reason='not_at_board'
   elif not b['eligible']:reason='locked_valid_contract'
   elif not observed:reason='no_observed_positive_vacancy'
   elif not bid and not application:reason='abstained_or_no_legal_application'
   elif (day,w) in started:reason='renewed' if started[day,w]['target']==b['employer'] else 'hired_after_unemployment_or_transfer'
   elif bid and bid['status']=='cancelled':reason='boundary_or_notice_cancelled'
   elif bid and bid['status']=='declined':reason='voluntary_offer_declined'
   elif bid and bid['status']=='unaccepted':reason='offer_not_accepted'
   elif bid and not front:reason='front_funding_rejection'
   elif bid and not feasible:reason='projected_financing_failure'
   elif bid and not admissible:reason='no_strict_marginal_gain_at_requested_wage'
   elif bid and best_admissible==chosen_value:reason='financial_tie_incumbent_or_stable_id'
   elif bid:reason='outbid_by_higher_value_portfolio'
   else:reason='fixed10_competition_or_financial_tie'
   update=by[day,'wage_outcome_observed'];tables['PARTICIPATION'].append(flatten(dict(**tag,**b,observed_notices=[n['id'] for n in observed],observed_notice_count=len(observed),bid=bid['id'] if bid else '',application_event_id=application['id'] if application else None,requested_wage=bid['wage'] if bid else 10 if application else None,request_kind='sealed_ask' if bid else 'fixed_post_application' if application else 'none',employer_applicants=employer_apps,offered=(day,w) in offers,accepted=(day,w) in accepted,started=(day,w) in started,new_employer=started[day,w]['target'] if (day,w) in started else '',start_event_id=started[day,w]['id'] if (day,w) in started else None,reason=reason,best_feasible_value_including_worker=best_with,chosen_value=chosen_value,best_admissible_value_including_worker=best_admissible,financial_value_rank=financial_rank,comparison_event_ids=comparison_ids,any_front_funded_portfolio=front,own_past_win_observations=sum(z['actor']==w and z['details']['outcome']=='hired' for z in update),own_past_loss_observations=sum(z['actor']==w and z['details']['outcome']=='lost_filled' for z in update),own_past_unknown_observations=sum(z['actor']==w and z['details']['outcome']=='unknown' for z in update))))
  for w,row in r['contracts']['workers'].items():
   h=r['accounts'][w];tables['RESIDENTS'].append(flatten(dict(**tag,resident=w,owner=w in OWNERS.values(),initial_cash=r['initial']['entities'][w]['money'],**row,meals=h['meals'],missed=h['missed_meals'],distributions=h['distributions'],bread_spending=h['bread_spending'],ale_spending=h['ale_spending'],cash=h['cash'],inventory=h['inventory'])))
  for b,row in r['contracts']['businesses'].items():tables['FIRMS'].append(flatten(dict(**tag,business=b,initial_cash=r['initial']['entities'][b]['money'],standby=sum(f['standby'] for f in x['firm_days'] if f['firm']==b),last_productive_day=max((f['day'] for f in x['firm_days'] if f['firm']==b and f['productive']),default=0),**row)))
  for w,days in low.items():
   start=previous=days[0]
   for day in days[1:]+[10**9]:
    if day!=previous+1:
     tables['LOW_WAGE_SPELLS'].append(dict(**tag,worker=w,start_day=start,end_day=previous,days=previous-start+1));start=day
    previous=day
  for (w,threshold),days in spells.items():
   start=previous=days[0]
   for day in days[1:]+[10**9]:
    if day!=previous+1:
     tables['WAGE_SPELLS'].append(dict(**tag,worker=w,threshold=threshold,start_day=start,end_day=previous,days=previous-start+1));start=day
    previous=day
  employees=[z for z in tables['RESIDENTS'] if all(z[k]==v for k,v in tag.items()) and not z['owner']]
  firms=[z for z in tables['FIRMS'] if all(z[k]==v for k,v in tag.items())]
  for measure,groups,field in [('employee_cash_wage_share',employees,'cash_wages'),('employer_paid_wage_share',firms,'cash_payroll'),('employer_productive_share',firms,'productive')]:
   total=sum(z[field] for z in groups)
   tables['CONCENTRATION'].append(dict(**tag,measure=measure,total=total,positive_groups=sum(z[field]>0 for z in groups),groups=len(groups),hhi=sum((z[field]/total)**2 for z in groups) if total else None,largest_share=max((z[field]/total for z in groups),default=None) if total else None,shares={z.get('resident',z.get('business')):z[field]/total if total else None for z in groups}))
  for w in sorted(r['final']['wage_market']['anchors']):
   terms=sorted((t for t in r['final']['binding_contracts']['terms'].values() if t['worker']==w),key=lambda t:t['start_day']);hires=[t for t in terms if t['source']=='accepted'];ownparts=[z for (d0,p0),z in board.items() if p0==w]
   victories=[b for b in r['final']['wage_market']['bids'].values() if b['worker']==w and b['status']=='hired'];losses=[b for b in r['final']['wage_market']['bids'].values() if b['worker']==w and b['status']=='submitted' and r['final']['wage_market']['settlements'].get(b['notice'],{}).get('filled',0)>0]
   continuations=0;returns=0;switches=0
   for t in hires:
    prior=next((p for p in terms if p['id']==t['predecessor']),None)
    if prior and prior['business']==t['business'] and prior['closed_day']==t['start_day']:continuations+=1
    elif prior and prior['business']==t['business']:returns+=1
    elif prior:switches+=1
   tables['WORKER_CYCLES'].append(flatten(dict(**tag,worker=w,successor_terms=len(hires),continuous_same_firm=continuations,same_firm_return_after_gap=returns,changed_employer=switches,actual_hired_bids=len(victories),unselected_live_bids_at_filled_notice=len(losses),eligible_board_days=sum(b['eligible'] for b in ownparts),unemployed_board_days=sum(not b['employer'] for b in ownparts),wage_path=[dict(start=t['start_day'],end=t['end_day'],closed=t.get('closed_day'),business=t['business'],wage=t['wage']) for t in terms],bid_days=[b['day'] for b in losses],hire_days=[t['start_day'] for t in hires])))
  for metric,values in [('paid_claim_worker_days_nominal_wage',employee_paid),('positive_cash_receipt_worker_days',actual_paid),('paid_individual_mean_nominal_wage',[statistics.mean(v) for v in worker_nominal.values()])]:stats.append(dict(**tag,metric=metric,count=len(values),distinct_paid_workers=len(worker_nominal),mean=statistics.mean(values) if values else None,median=statistics.median(values) if values else None,minimum=min(values) if values else None,maximum=max(values) if values else None))
  ds=[d for d in tables['DAYS'] if all(d[k]==v for k,v in tag.items())];people=[d for d in tables['RESIDENT_DAYS'] if all(d[k]==v for k,v in tag.items())];parts=[d for d in tables['PARTICIPATION'] if all(d[k]==v for k,v in tag.items())];cash=r['final']['entities']
  value={k:sum(d[k] for d in ds) for k in ['meals','missed','visitor_bread','resident_ale','visitor_ale','cash_blocked','solvent_stockout','owner_missed','nonowner_missed','cash_wages','distributions','circulation','productive','wheat','flour','bread','ale']}
  value.update(standby=sum(z['standby'] for z in people),fully_paid_standby=sum(z['fully_paid_standby'] for z in people),earned_below6=sum(z['earned_below6'] for z in people),earned_below10=sum(z['earned_below10'] for z in people),cash_blocked_with_stock=sum(z['cash_blocked_with_stock'] is True for z in people),paid_employee_days=len(employee_paid),mean_paid_nominal_wage=statistics.mean(employee_paid) if employee_paid else None,median_paid_nominal_wage=statistics.median(employee_paid) if employee_paid else None,bids=len(r['final']['wage_market']['bids']),new_terms=sum(e['action']=='binding_term_started' for e in events),active_jobs=len(r['final']['affiliations']),arrears=sum(z['arrears'] for z in r['contracts']['workers'].values()),household_cash=sum(e['money'] for e in cash.values() if e['kind']=='resident'),firm_cash=sum(cash[b]['money'] for b in OWNERS),visitor_cash=cash['visitors']['money'],locked_board_days=sum(z['reason']=='locked_valid_contract' for z in parts),no_notice_eligible_board_days=sum(z['reason']=='no_observed_positive_vacancy' for z in parts),submitted_unselected_board_days=sum(bool(z['bid']) and not z['started'] for z in parts))
  value.update({f'meals_days_{lo}_{lo+9}':sum(d['meals'] for d in ds if lo<=d['day']<=lo+9) for lo in [1,11,21]});outcomes[r['condition'],allocation,arm]=value
  assert len(ds)==30 and len(people)==450 and len(parts)==330 and value['household_cash']+value['firm_cash']+value['visitor_cash']==9192
 comparisons=[]
 for (c,allocation,arm),left in outcomes.items():
  if arm!='fixed10_instrumented':continue
  right=outcomes[c,allocation,'worker_bids'];comparisons.append(dict(condition=c,allocation=allocation,contrast='F -> W',**{'delta_'+k:right[k]-left[k] for k in left if left[k] is not None and right[k] is not None}))
  F=matched[c,allocation,arm];W=matched[c,allocation,'worker_bids'];assert F['day_results'][:3]==W['day_results'][:3],'wage experiment altered initial three ten-coin days'
 tables['WAGE_STATS']=stats;tables['COMPARISONS']=comparisons;tables['OUTCOMES']=[dict(condition=c,allocation=al,arm=arm,**v) for (c,al,arm),v in outcomes.items()]
 for label,rows in tables.items():
  if rows:write_rows(a.output/('M30_'+label+'.csv'),[flatten(r) for r in rows])
 captures=[]
 for path in sorted(a.traces.glob('*.json.gz')):
  raw=path.read_bytes();d=load_trace(path);captures.append(dict(file=path.name,bytes=len(raw),compressed_payload_sha256=hashlib.sha256(raw).hexdigest(),summary_sha256=digest(dict(report=d['report'])),ledger_sha256=d['report']['ledger_sha256']))
 assert len(captures)==56 and len(outcomes)==12 and len(comparisons)==6
 write_rows(a.output/'M30_CAPTURE_MANIFEST.csv',captures);shutil.copy2(a.input/'verification.json',a.output/'M30_EXPERIMENT_MANIFEST.json')
 write_json(a.output/'M30_ARTIFACT_CHECKS.json',dict(cases=12,captures=56,matched_comparisons=6,initial_three_day_economic_parity_pairs=6,rows={k:len(v) for k,v in tables.items()},checks='All exports derive from complete independently audited traces; household/day budgets and9192 actual coins reconcile.'))
 print('Published12 thirty-day cases, all named households and six matched F/W contrasts.',flush=True)

if __name__=='__main__':main()
