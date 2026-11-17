#!/usr/bin/env python3
"""Predeclared M23 matrix: fresh process replay, independent audits, compact evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from brewery_audit import audit
from brewery_feasibility import certificate
from planning_load_tools import quantiles
from profile_simulation import ROOT, godot_environment, write_csv


def capture(condition,days):
    command=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_brewery.gd','--','--condition',condition,str(days),'42','--measure']
    start=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(command,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-start;err.seek(0);error=err.read();assert child.returncode==0 and not error,(child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data['measurement'].update(command_seconds=elapsed,peak_rss_kib=usage.ru_maxrss)
    return data


def digest(data):return hashlib.sha256((json.dumps(data,sort_keys=True,separators=(',',':'),ensure_ascii=False)+'\n').encode()).hexdigest()


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=Path('work/m23'));p.add_argument('--checkpoint',action='store_true');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    certificate();runs=[];daily=[];accounts=[];businesses=[];performance=[];latencies=[]
    cases=[(c,d) for d in ((1,3) if a.checkpoint else (1,3,30)) for c in ('reference','tight','scarce','no_brew_request')]
    # Two excluded one-day warmups; no timing overlaps auditing or other verification.
    for condition in ('reference','no_brew_request'):capture(condition,1)
    for condition,days in cases:
        results=[]
        for repeat in (1,2):
            data=capture(condition,days);start=time.perf_counter();verified=audit(data);audit_seconds=time.perf_counter()-start
            r=data['report'];m=data['measurement'];results.append(data)
            samples=[x['usec']/1000 for x in m['appointments']];ticks=[x['usec']/1000 for x in m['ticks']]
            warning='appointment p99 exceeds provisional 50-ms diagnostic goal' if quantiles(samples)['p99'] and quantiles(samples)['p99']>50 else ''
            performance.append(dict(condition=condition,days=days,repeat=repeat,run_seconds=m['run_usec']/1e6,command_seconds=m['command_seconds'],report_seconds=m['report_usec']/1e6,peak_rss_kib=m['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(samples),worst_tick_ms=max(ticks),warning=warning))
            for metric,values in [('appointment',samples),('tick',ticks)]:latencies.append(dict(condition=condition,days=days,repeat=repeat,metric=metric,**quantiles(values)))
        first,second=results
        assert first['report']==second['report'] and first['events']==second['events'],(condition,days,'complete process replay mismatch')
        r=first['report'];ds=r['day_results']
        runs.append(dict(condition=condition,days=days,seed=42,meals=sum(d['resident_meals'] for d in ds),missed=sum(d['unmet_meals'] for d in ds),visitor_bread=sum(d['visitor_bread'] for d in ds),visitor_bread_declined=sum(d['visitor_bread_declined'] for d in ds),ale_sold=sum(d['ale_sold'] for d in ds),ale_consumed=r['totals']['consumed']['ale'],wheat=r['totals']['produced']['wheat'],flour=r['totals']['produced']['flour'],bread=r['totals']['produced']['bread'],ale=r['totals']['produced']['ale'],shifts=sum(d['shifts'] for d in ds),missed_shifts=sum(d['missed_shifts'] for d in ds),successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],circulation=r['money']['circulation'],combined_currency=r['money']['final'],visitor_cash=r['final']['entities']['visitors']['money'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
        (a.output/f'{condition}-{days}.json').write_text(json.dumps(dict(report=r,measurements=[x['measurement'] for x in results]),separators=(',',':'))+'\n')
        for d in ds:
            row=dict(condition=condition,horizon=days,**d)
            for key,value in row.items():
                if isinstance(value,dict):row[key]=json.dumps(value,sort_keys=True,separators=(',',':'))
            daily.append(row)
        for id,account in r['accounts'].items():
            row=dict(condition=condition,days=days,id=id,**account)
            for key,value in row.items():
                if isinstance(value,dict):row[key]=json.dumps(value,sort_keys=True,separators=(',',':'))
            accounts.append(row)
        for f in r['final']['businesses']:
            book=r['final']['cash_results'][f]
            businesses.append(dict(condition=condition,days=days,business=f,**book,operating_surplus=book['sales']-book['inputs']-book['payroll'],cash=r['final']['entities'][f]['money'],inventory=json.dumps(r['final']['entities'][f]['inventory'],sort_keys=True,separators=(',',':')),shifts=r['accounts'][f]['shifts']))
        for name,rows in [('runs',runs),('days',daily),('accounts',accounts),('businesses',businesses),('performance',performance),('latency',latencies)]:write_csv(a.output/f'{name}.csv',rows)
        print(condition,days,'meals/missed',runs[-1]['meals'],runs[-1]['missed'],'ale',runs[-1]['ale_sold'],'wheat',runs[-1]['wheat'],'shifts',runs[-1]['shifts'],'audited/replayed',flush=True)
    (a.output/'verification.json').write_text(json.dumps(dict(cases=len(cases),process_runs=len(cases)*2,full_reports_and_events_replayed=True,independent_audits=len(cases)*2,feasibility=True),indent=2)+'\n')


if __name__=='__main__':main()
