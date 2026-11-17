#!/usr/bin/env python3
"""Publish compact M25 contracts/claims, daily employment, and accounting evidence."""
import argparse
import json
import shutil
from pathlib import Path
from profile_simulation import write_csv


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    for folder,source,target in [('experiments','runs','RUNS'),('experiments','performance','PERFORMANCE'),('experiments','latency','LATENCY'),('fixtures-final','runs','FIXTURES'),('lifecycle','results','LIFECYCLES')]:shutil.copy2(a.input/folder/(source+'.csv'),a.output/('M25_'+target+'.csv'))
    people=[];businesses=[];terms=[];claims=[];worker_days=[];days=[]
    for file in sorted((a.input/'experiments').glob('*.json')):
        data=json.loads(file.read_text())
        if 'report' not in data:continue
        r=data['report']
        if r['days']!=30:continue
        c=r['contracts'];state=r['final']['binding_contracts'];tag=dict(condition=r['condition'],mode=c['mode'],days=30)
        for shorter in (1,3):
            small=json.loads((a.input/'experiments'/file.name.replace('-30-','-'+str(shorter)+'-')).read_text())['report']
            assert small['day_results']==r['day_results'][:shorter] and small['contracts']['worker_days']==[d for d in c['worker_days'] if d['day']<=shorter]
        for w,contract in c['workers'].items():
            account=r['accounts'][w]
            people.append(dict(**tag,worker=w,**contract,meals=account['meals'],missed_meals=account['missed_meals'],bread_spending=account['bread_spending'],ale_spending=account['ale_spending'],ale_consumed=account['ale_consumed'],distributions=account['distributions'],cash=account['cash'],**account['inventory']))
        for b,book in c['businesses'].items():
            row=dict(**tag,business=b,**book);row.update(row.pop('inventory'));businesses.append(row)
        for term in state['terms'].values():terms.append(dict(**tag,closed_day=None,**term) if 'closed_day' not in term else dict(**tag,**term))
        for claim in state['obligations'].values():
            row=dict(**tag,**claim,remaining=10-claim['paid']);row['payments']=json.dumps(row['payments'],sort_keys=True,separators=(',',':'));claims.append(row)
        schedules={(d['day'],d['worker']):d for d in c['worker_days']}
        for day,d in zip(c['days'],r['day_results']):
            days.append(dict(**tag,day=d['day'],meals=d['resident_meals'],missed=d['unmet_meals'],productive=d['shifts'],scheduled=d['shifts_due'],unutilized=d['missed_shifts'],breaches=day['breaches'],arrears=sum(day['liabilities'].values()),circulation=d['circulation'],**d['production']))
            for w,h in d['households'].items():
                schedule=schedules.get((d['day'],w),{})
                worker_days.append(dict(**tag,day=d['day'],worker=w,term=day['terms'].get(w,''),scheduled=schedule.get('scheduled',0),attended=schedule.get('attended',0),productive=h['shifts'],standby=schedule.get('standby',0),accrued=schedule.get('accrued',0),cash_wages=h['wages'],claim_paid_by_close=schedule.get('claim_paid_by_close',0),claim_arrears_by_close=schedule.get('claim_arrears_by_close',0),total_arrears=day['receivables'].get(w,0),breach=schedule.get('breach',False),meals=h['meals'],missed_meals=h['missed_meals'],cash=h['cash'],attendance_event_id=schedule.get('attendance_event_id'),closure_event_id=schedule.get('closure_event_id')))
    for name,rows in [('RESIDENTS',people),('BUSINESSES',businesses),('CONTRACTS',terms),('WAGE_CLAIMS',claims),('WORKER_DAYS',worker_days),('DAYS',days)]:write_csv(a.output/('M25_'+name+'.csv'),rows)
    fixture_claims=[];fixture_terms=[]
    for folder in ('fixtures-final','lifecycle'):
        for file in sorted((a.input/folder).glob('*.json')):
            data=json.loads(file.read_text())
            if 'report' not in data:continue
            r=data['report'];tag=dict(witness=file.stem,configuration=folder,days=r['days'])
            for c in r['final']['binding_contracts']['obligations'].values():
                row=dict(**tag,**c,remaining=10-c['paid']);row['payments']=json.dumps(row['payments'],sort_keys=True,separators=(',',':'));fixture_claims.append(row)
            for t in r['final']['binding_contracts']['terms'].values():
                row=dict(**tag,closed_day=None);row.update(t);fixture_terms.append(row)
    write_csv(a.output/'M25_FIXTURE_CLAIMS.csv',fixture_claims);write_csv(a.output/'M25_FIXTURE_CONTRACTS.csv',fixture_terms)
    print('Published',len(terms),'terms,',len(claims),'earned claims,',len(worker_days),'person-days; short-run prefixes verified.')


if __name__=='__main__':main()
