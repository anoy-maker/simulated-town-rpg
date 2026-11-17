#!/usr/bin/env python3
"""Publish compact M23 evidence; no full native traces or repeated short-run day tables."""
import argparse
import csv
import json
import shutil
from pathlib import Path
from profile_simulation import write_csv

p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
for source,target in [('runs','RUNS'),('businesses','BUSINESSES'),('performance','PERFORMANCE'),('latency','LATENCY')]:shutil.copy2(a.input/f'{source}.csv',a.output/f'M23_{target}.csv')
days=[];residents=[];visitors=[];firms=[];totals=[]
for condition in ('reference','tight','scarce','no_brew_request'):
    report=json.loads((a.input/f'{condition}-30.json').read_text())['report']
    for shorter in (1,3):
        small=json.loads((a.input/f'{condition}-{shorter}.json').read_text())['report']
        assert small['day_results']==report['day_results'][:shorter]
    for d in report['day_results']:
        row={k:v for k,v in d.items() if not isinstance(v,dict)};row['condition']=condition
        row.update({f'produced_{i}':q for i,q in d['production'].items()})
        row.update({f'input_{i}':q for i,q in d['production_inputs'].items()})
        row.update({f'grain_to_{b}':q for b,q in d['grain_allocation'].items()})
        row['declines']=json.dumps(d['declines'],sort_keys=True,separators=(',',':'));days.append(row)
        for id,p in d['households'].items():
            row=dict(condition=condition,day=d['day'],id=id,**p)
            row.update({i:q for i,q in row.pop('inventory').items()});row['declines']=json.dumps(row['declines'],sort_keys=True,separators=(',',':'));residents.append(row)
        for id,p in d['visitors'].items():
            row=dict(condition=condition,day=d['day'],id=id,**p);row['spent']=p['bread_spending']+p['ale_spending'];row['declines']=json.dumps(row['declines'],sort_keys=True,separators=(',',':'));visitors.append(row)
        for id,p in d['firms'].items():
            row=dict(condition=condition,day=d['day'],business=id,**p);row.update({i:q for i,q in row.pop('inventory').items()});firms.append(row)
    for horizon in (1,3,30):
        r=json.loads((a.input/f'{condition}-{horizon}.json').read_text())['report']
        for id,p in r['accounts'].items():
            if id in r['final']['businesses'] or id=='visitors':continue
            row={k:v for k,v in p.items() if not isinstance(v,dict)};row.update(condition=condition,days=horizon,id=id,**p['inventory']);totals.append(row)
for name,rows in [('DAYS',days),('RESIDENT_DAYS',residents),('VISITOR_DAYS',visitors),('FIRM_DAYS',firms),('RESIDENTS',totals)]:write_csv(a.output/f'M23_{name}.csv',rows)
print('exported',len(days),'complete days,',len(residents),'resident days,',len(visitors),'visitor days; shorter prefixes verified')
