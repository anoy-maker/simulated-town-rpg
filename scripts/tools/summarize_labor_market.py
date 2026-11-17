#!/usr/bin/env python3
"""Publish compact M24 evidence, leaving full-year/native traces out of version control."""
import argparse
import csv
import json
import shutil
from pathlib import Path
from profile_simulation import write_csv


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    for folder,source,target in [('experiments','runs','RUNS'),('experiments','performance','PERFORMANCE'),('experiments','latency','LATENCY'),('fixtures','runs','VACANCIES'),('fixtures','transitions','EMPLOYMENT_EVENTS'),('legacy-brewery','controls','LEGACY_CONTROLS')]:
        shutil.copy2(a.input/folder/(source+'.csv'),a.output/('M24_'+target+'.csv'))
    residents=[];firms=[];days=[];fixture_people=[]
    for file in sorted((a.input/'experiments').glob('*.json')):
        data=json.loads(file.read_text())
        if 'report' not in data:continue
        r=data['report']
        if r['days']!=30:continue
        labor=r['labor'];tag=dict(condition=r['condition'],mode=labor['mode'],days=30)
        for shorter in (1,3):
            small=json.loads((a.input/'experiments'/file.name.replace('-30-','-'+str(shorter)+'-')).read_text())['report']
            assert small['day_results']==r['day_results'][:shorter]
        for id,row in r['accounts'].items():
            if r['final']['entities'][id]['kind']=='resident':residents.append(dict(**tag,id=id,**{k:v for k,v in row.items() if not isinstance(v,dict)},**row['inventory']))
        for f,book in r['final']['cash_results'].items():
            firms.append(dict(**tag,business=f,**book,operating_surplus=book['sales']-book['inputs']-book['payroll'],cash=r['accounts'][f]['cash'],shifts=r['accounts'][f]['shifts'],**r['accounts'][f]['inventory']))
        for d in r['day_results']:
            days.append(dict(**tag,day=d['day'],meals=d['resident_meals'],missed=d['unmet_meals'],shifts=d['shifts'],missed_shifts=d['missed_shifts'],bread_stock=d['firms']['bakery']['inventory']['bread'],circulation=d['circulation'],wheat=d['production']['wheat'],flour=d['production']['flour'],bread=d['production']['bread'],ale=d['production']['ale']))
    for file in sorted((a.input/'fixtures').glob('*.json')):
        data=json.loads(file.read_text())
        if 'report' not in data:continue
        r=data['report']
        for id,row in r['accounts'].items():
            if r['final']['entities'][id]['kind']=='resident':fixture_people.append(dict(fixture=r['labor']['fixture'],id=id,**{k:v for k,v in row.items() if not isinstance(v,dict)},**row['inventory']))
    for name,rows in [('RESIDENTS',residents),('BUSINESSES',firms),('DAYS',days),('FIXTURE_RESIDENTS',fixture_people)]:write_csv(a.output/('M24_'+name+'.csv'),rows)
    print('Published',len(residents),'30-day resident accounts;',len(fixture_people),'fixture accounts. Shorter-run prefixes verified.')


if __name__=='__main__':main()
