#!/usr/bin/env python3
"""M29 compact audited cash/food/firm evidence and matched ownership contrasts."""
import argparse,csv,hashlib,json,shutil
from collections import defaultdict
from pathlib import Path
from brewery_feasibility import OWNERS
from cash_allocation_audit import initial_cash,ALLOCATIONS
from input_audit import ARMS
from run_economic_diagnostics import write_rows,write_json,flatten
from run_brewery import digest


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--traces',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    for name in ['runs','performance','parity']:shutil.copy2(a.input/(name+'.csv'),a.output/('M29_'+name.upper()+'.csv'))
    initial=[];residents=[];days=[];firms=[];firm_days=[];shopping=[];orders=[];forecasts=[];failures=[];constraints=[];terms=[];money=[];metrics={}
    for file in sorted((a.input/'analyses').glob('*-30-*.json')):
        x=json.loads(file.read_text());data=json.loads((a.traces/(file.stem+'-1.json')).read_text());r=data['report'];allocation=r['cash_allocation']['name'];arm=r['input_reliability']['arm'];tag=dict(condition=r['condition'],arm=arm,allocation=allocation,stratum='primary' if r['condition'] in ['scarce','no_brew_request'] else 'secondary',seed=42)
        assert x['source']['report_sha256']==digest(dict(report=r))
        for w,e in r['initial']['entities'].items():
            initial.append(dict(**tag,account=w,kind=e['kind'],owner=w in OWNERS.values(),initial_coins=e['money'],delta_vs_original=e['money']-initial_cash('original')[w],source_event_id=1,source_day=0,earned_income=0))
        for w,row in r['contracts']['workers'].items():
            h=r['accounts'][w];residents.append(flatten(dict(**tag,resident=w,owner=w in OWNERS.values(),initial_cash=r['initial']['entities'][w]['money'],**row,meals=h['meals'],missed=h['missed_meals'],ownership_income=h['distributions'],bread_spending=h['bread_spending'],ale_spending=h['ale_spending'],cash=h['cash'],inventory=h['inventory'])))
        for b,row in r['contracts']['businesses'].items():firms.append(flatten(dict(**tag,business=b,initial_cash=r['initial']['entities'][b]['money'],standby=sum(f['standby'] for f in x['firm_days'] if f['firm']==b),last_productive_day=max((f['day'] for f in x['firm_days'] if f['firm']==b and f['productive']),default=0),**row)))
        for f in x['firm_days']:firm_days.append(flatten(dict(**tag,**f)))
        for order in x['input']['orders']:orders.append(flatten(dict(**tag,**order)))
        lookup={(p['day'],p['business']):p for p in x['input']['projections']}
        demand={(p['day'],p['business']):p['forecast'] for p in r['demand']['forecasts']}
        late=defaultdict(list)
        for e in data['events']:
            if e['action']=='transfer_money' and e['success']:
                money.append(dict(**tag,day=e['day'],minute=e['minute'],event_id=e['id'],payer=e['actor'],recipient=e['target'],amount=e['details']['amount'],purpose=e['details']['purpose']))
                if e['minute']>960:late[e['day'],e['target']].append(e)
            if e['action']=='consumer_decision':
                o=e['details']['observation'];shopping.append(flatten(dict(**tag,day=e['day'],minute=e['minute'],buyer=e['actor'],cohort='visitor' if e['actor'].startswith('visitor:') else 'owner' if e['actor'] in OWNERS.values() else 'nonowner',item=e['details']['item'],event_id=e['id'],money=o['money'],need=o['need_'+e['details']['item']],stock=o['stock'].get(e['details']['item']),price=o['prices'].get(e['details']['item']),purchased=e['details']['purchased'],bread_ceiling=o['bread_ceiling'])))
            if e['action']=='input_forecast_projection':
                p=e['details'];point=p['estimate'];forecasts.append(flatten(dict(**tag,day=e['day'],business=e['target'],event_id=e['id'],N=point['numerator'],D=point['denominator'],status=point['status'],sample_ids=point['sample_order_ids'],demand_point=demand[e['day'],e['target']],headcount=p['headcount'],candidates=[c['summary'] for c in p['candidates']])))
        for f in x['failure_attributions']:
            incoming=late[f['day'],f['buyer']];h=r['day_results'][f['day']-1]['households'][f['buyer']]
            failures.append(flatten(dict(**tag,**f,owner=f['buyer'] in OWNERS.values(),closing_cash=h['cash'],late_income=sum(e['details']['amount'] for e in incoming),late_source_ids=[e['id'] for e in incoming])))
        grouped={}
        for f in x['constraints']:
            key=f['day'],f['subject'],f['flag'],f['evidence'];g=grouped.setdefault(key,dict(day=f['day'],subject=f['subject'],flag=f['flag'],evidence=f['evidence'],event_ids=[],related_ids=[],details=set()))
            g['event_ids'].append(f['event_id']);g['related_ids']+=f['additional_source_ids'];g['details'].add(f['detail'])
        for g in grouped.values():g['details']=sorted(g['details']);constraints.append(flatten(dict(**tag,**g)))
        for d in r['day_results']:
            bad=[f for f in x['failure_attributions'] if f['day']==d['day']];cash=sum(f['immediate_blocker']=='household_purchasing_power' for f in bad);stock=sum(f['immediate_blocker']=='stockout_of_solvent_request' for f in bad)
            assert cash+stock==d['unmet_meals']
            days.append(dict(**tag,day=d['day'],meals=d['resident_meals'],missed=d['unmet_meals'],owner_missed=sum(h['missed_meals'] for w,h in d['households'].items() if w in OWNERS.values()),nonowner_missed=sum(h['missed_meals'] for w,h in d['households'].items() if w not in OWNERS.values()),cash_blocked=cash,solvent_stockout=stock,visitor_bread=d['visitor_bread'],ale_consumed=d['ale_consumed'],wages=sum(f['wages'] for f in d['firms'].values()),productive=d['shifts'],standby=sum(f['standby'] for f in x['firm_days'] if f['day']==d['day']),circulation=d['circulation'],household_cash=sum(h['cash'] for h in d['households'].values()),firm_cash=sum(f['cash'] for f in d['firms'].values()),visitor_cash=d['external_cash'],**d['production']))
        for term in r['final']['binding_contracts']['terms'].values():terms.append(flatten(dict(**tag,**term)))
        ds=[d for d in days if all(d[k]==v for k,v in tag.items())];cash=r['final']['entities']
        assert len(ds)==30 and all(d['meals']+d['missed']==15 and d['household_cash']+d['firm_cash']+d['visitor_cash']==9192 for d in ds)
        value={k:sum(d[k] for d in ds) for k in ['meals','missed','owner_missed','nonowner_missed','cash_blocked','solvent_stockout','visitor_bread','wages','productive','standby','circulation','wheat','flour','bread','ale']}
        value.update({f'meals_days_{lo}_{lo+9}':sum(d['meals'] for d in ds if lo<=d['day']<=lo+9) for lo in [1,11,21]})
        value.update(owner_cash=sum(cash[w]['money'] for w in OWNERS.values()),nonowner_cash=sum(e['money'] for w,e in cash.items() if e['kind']=='resident' and w not in OWNERS.values()),firm_cash=sum(cash[b]['money'] for b in OWNERS),visitor_cash=cash['visitors']['money'],active_jobs=len(r['final']['affiliations']),arrears=sum(w['arrears'] for w in r['contracts']['workers'].values()))
        assert value['meals']==sum(h['meals'] for w,h in r['accounts'].items() if r['final']['entities'][w]['kind']=='resident') and value['wages']==sum(w['cash_wages'] for w in r['contracts']['workers'].values())
        assert value['productive']==sum(f['productive'] for f in x['firm_days']) and value['circulation']==r['money']['circulation']
        metrics[r['condition'],arm,allocation]=value
    comparisons=[]
    for c in ['scarce','no_brew_request','tight','reference']:
        for arm in ARMS:
            for before,after in [('original','households_330'),('original','firms_330'),('households_330','firms_330')]:
                left,right=metrics[c,arm,before],metrics[c,arm,after];comparisons.append(dict(condition=c,policy=arm,contrast=before+' -> '+after,**{'delta_'+k:right[k]-left[k] for k in left}))
        for allocation in ALLOCATIONS:
            left,right=metrics[c,ARMS[0],allocation],metrics[c,ARMS[1],allocation];comparisons.append(dict(condition=c,policy=allocation,contrast='B -> I',**{'delta_'+k:right[k]-left[k] for k in left}))
    for n,rows in [('INITIAL_ACCOUNTS',initial),('RESIDENTS',residents),('FIRMS',firms),('FIRM_DAYS',firm_days),('DAYS',days),('SHOPPING',shopping),('INPUT_ORDERS',orders),('FORECASTS',forecasts),('FAILURES',failures),('CONSTRAINTS',constraints),('TERMS',terms),('MONEY_TRANSFERS',money),('COMPARISONS',comparisons),('OUTCOMES',[dict(condition=c,arm=arm,allocation=allocation,**v) for (c,arm,allocation),v in metrics.items()])]:write_rows(a.output/('M29_'+n+'.csv'),rows)
    captures=[]
    for path in sorted(a.traces.glob('*.json')):
        if path.name.endswith('.meta.json'):continue
        payload=path.read_bytes();d=json.loads(payload);r=d['report']
        captures.append(dict(file=path.name,bytes=len(payload),trace_sha256=hashlib.sha256(payload).hexdigest(),summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
    assert len(captures)==96 and len(initial)==480 and len(residents)==360 and len(firms)==96 and len(firm_days)==2880 and len(days)==720 and len(comparisons)==36
    write_rows(a.output/'M29_CAPTURE_MANIFEST.csv',captures)
    write_json(a.output/'M29_ARTIFACT_CHECKS.json',dict(thirty_day_cases=len(metrics),initial_accounts=len(initial),resident_rows=len(residents),firm_rows=len(firms),firm_days=len(firm_days),day_rows=len(days),capture_payloads=len(captures),matched_contrasts=len(comparisons),checks='CSV totals agree with fully audited native reports; each day has fifteen resident meals/misses and9192 actual coins.'))
    shutil.copy2(a.input/'verification.json',a.output/'M29_EXPERIMENT_MANIFEST.json')
    print('Published24 audited30-day cases and36 matched contrasts; no welfare score',flush=True)


if __name__=='__main__':main()
