#!/usr/bin/env python3
"""Compact M26 evidence. Censored request totals are lower bounds, never truth."""
import argparse
import json
import shutil
from collections import defaultdict
from pathlib import Path
from demand_audit import PRODUCT
from profile_simulation import write_csv


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    for folder,prefix in [('experiments',''),('staggered','STAGGERED_')]:
        for name in ('runs','performance','latency','parity'):
            shutil.copy2(a.input/folder/(name+'.csv'),a.output/('M26_'+prefix+name.upper()+'.csv'))
    residents=[];firms=[];observations=[];forecasts=[];days=[];terms=[];orders=[];stalls=[]
    for folder in ('experiments','staggered'):
        for file in sorted((a.input/folder).glob('*.json')):
            r=json.loads(file.read_text()).get('report')
            if not r or r['days']!=30:continue
            tag=dict(condition=r['condition'],arm=r['demand']['arm'],fixture=r['initial']['labor_market']['fixture'],days=30)
            if folder=='experiments':
                for shorter in (1,3):
                    small=json.loads((file.parent/file.name.replace('-30-','-'+str(shorter)+'-')).read_text())['report']
                    assert small['day_results']==r['day_results'][:shorter]
                    assert small['demand']['forecasts']==[f for f in r['demand']['forecasts'] if f['day']<=shorter]
            for w,c in r['contracts']['workers'].items():
                account=r['accounts'][w]
                residents.append(dict(**tag,resident=w,**c,meals=account['meals'],missed=account['missed_meals'],bread_spending=account['bread_spending'],ale_spending=account['ale_spending'],ale_consumed=account['ale_consumed'],distributions=account['distributions'],cash=account['cash'],**account['inventory']))
            for b,c in r['contracts']['businesses'].items():
                row=dict(**tag,business=b,**c,**c['inventory']);del row['inventory'];firms.append(row)
            for term in r['final']['binding_contracts']['terms'].values():terms.append(dict(**tag,closed_day=term.get('closed_day'),**{k:v for k,v in term.items() if k!='closed_day'}))
            book=defaultdict(lambda:dict(requests=0,quantity=0,filled=0,unfilled=0,witnessed=0))
            for order in r['final']['demand_observations']['orders'].values():
                cohort='visitor' if order['buyer'].startswith('visitor:') else 'business' if order['kind']!='retail' else 'resident'
                counts=book[order['day'],order['seller'],order['kind'],cohort]
                counts['requests']+=1;counts['witnessed']+=bool(order['witness'])
                for k in ('quantity','filled','unfilled'):counts[k]+=order[k]
            for (day,b,kind,cohort),counts in sorted(book.items()):orders.append(dict(**tag,day=day,business=b,kind=kind,cohort=cohort,**counts))
            lookup={(f['day'],f['business']):f for f in r['demand']['forecasts']}
            for f in r['demand']['forecasts']:
                forecasts.append(dict(**tag,**{k:v for k,v in f.items() if k!='arm'},sample_censored=sum(x['censored'] for x in r['demand']['days'] if x['closed_event_id'] in f['sample_ids'])))
            for o in r['demand']['days']:
                previous=lookup.get((o['day']-1,o['business']));point=previous['forecast'] if previous else None
                lower=o['sales']+o['unfilled'];exact=o['complete'] and not o['censored']
                observations.append(dict(**tag,**o,request_lower_bound=lower,previous_meeting_forecast=point,demonstrated_underestimate=point is not None and point<lower,lower_bound_deficit=max(0,lower-point) if point is not None else None,exact_next_day_error=point-lower if point is not None and exact else None,evaluation='exact_observed_window' if exact else 'censored_lower_bound_only'))
            for d,contract_day in zip(r['day_results'],r['contracts']['days']):
                stockout=sum(o['unfilled'] for o in r['final']['demand_observations']['orders'].values() if o['day']==d['day'] and o['item']=='bread' and o['kind']=='retail' and not o['buyer'].startswith('visitor:'))
                assert 0<=stockout<=d['unmet_meals']
                days.append(dict(**tag,day=d['day'],meals=d['resident_meals'],missed=d['unmet_meals'],resident_stockout_misses=stockout,misses_without_stockout_request=d['unmet_meals']-stockout,visitor_meals=d['visitor_bread'],productive=d['shifts'],scheduled=d['shifts_due'],unutilized=d['missed_shifts'],arrears=sum(contract_day['liabilities'].values()),circulation=d['circulation'],**d['production']))
                for b,c in d['firms'].items():
                    c=dict(c);inventory=c.pop('inventory')
                    stalls.append(dict(**tag,day=d['day'],business=b,production=d['production'][PRODUCT[b]],zero_production=d['production'][PRODUCT[b]]==0,**c,**inventory))
    for name,rows in [('RESIDENTS',residents),('BUSINESSES',firms),('OBSERVATIONS',observations),('FORECASTS',forecasts),('DAYS',days),('TERMS',terms),('ORDERS',orders),('STALLS',stalls)]:
        # Arrays are explicit compact provenance, not a Python repr in a cell.
        rows=[{k:json.dumps(v,separators=(',',':')) if isinstance(v,(list,dict)) else v for k,v in row.items()} for row in rows]
        write_csv(a.output/('M26_'+name+'.csv'),rows)


if __name__=='__main__':main()
