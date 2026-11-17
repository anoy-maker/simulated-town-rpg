#!/usr/bin/env python3
"""Frozen M24 matrix; fresh-process replay, independent replay, compact evidence."""
import argparse
import csv
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from labor_market_audit import audit
from brewery_feasibility import WORKERS
from run_brewery import digest
from planning_load_tools import quantiles
from profile_simulation import ROOT, godot_environment, write_csv


def capture(condition='reference', days=3, mode='matching', tie='neutral_rotate', fixture='none'):
    command=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_labor_market.gd','--','--condition',condition,'--mode',mode,'--tie',tie,'--fixture',fixture,str(days),'42','--measure']
    start=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(command,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-start;err.seek(0);error=err.read();assert child.returncode==0 and not error,(child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data['measurement'].update(command_seconds=elapsed,peak_rss_kib=usage.ru_maxrss)
    return data


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=Path('work/m24'));p.add_argument('--checkpoint',action='store_true');p.add_argument('--fixtures',action='store_true');p.add_argument('--legacy-controls',action='store_true');p.add_argument('--verify-pins',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    if a.legacy_controls:
        from run_brewery import capture as legacy_capture
        from brewery_audit import audit as legacy_audit
        pins=list(csv.DictReader((ROOT/'docs/M23_RUNS.csv').open()));rows=[]
        for pin in pins:
            data=legacy_capture(pin['condition'],int(pin['days']));stamp=time.perf_counter();legacy_audit(data)
            r=data['report'];assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256']
            rows.append(dict(condition=pin['condition'],days=pin['days'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256'],audit_seconds=time.perf_counter()-stamp,**{k:v for k,v in data['measurement'].items() if k not in ('ticks','appointments')}))
            (a.output/f"{pin['condition']}-{pin['days']}.json").write_text(json.dumps(dict(report=r,measurement=data['measurement']),separators=(',',':'))+'\n')
            write_csv(a.output/'controls.csv',rows)
            print('M23 historical report/ledger and independent audit',pin['condition'],pin['days'],'PASS',flush=True)
        return
    pins={}
    if a.verify_pins:
        for row in csv.DictReader(a.verify_pins.open()):pins[row['condition'],int(row['days']),row['mode'],row['tie'],row['fixture']]=row
    if a.fixtures:
        cases=[('reference',3,'matching','neutral_rotate','vacancy')]+[('reference',3,'matching','neutral_rotate','vacancy:'+w) for w in sorted(w for rows in WORKERS.values() for w in rows)]
    else:
        cases=[(c,d,m,'neutral_rotate','none') for d in ((1,3) if a.checkpoint else (1,3,30)) for c in ('reference','tight','scarce','no_brew_request') for m in ('shift_selection','matching')]
    runs=[];accounts=[];daily=[];performance=[];latencies=[];transitions=[]
    for c,d,m,t,f in cases:
        results=[]
        for repeat in (1,2):
            data=capture(c,d,m,t,f);start=time.perf_counter();audit(data);audit_seconds=time.perf_counter()-start;results.append(data)
            measurement=data['measurement'];tag=dict(condition=c,days=d,mode=m,tie=t,fixture=f)
            appointments=[x['usec']/1000 for x in measurement['appointments']];ticks=[x['usec']/1000 for x in measurement['ticks']]
            performance.append(dict(**tag,repeat=repeat,run_seconds=measurement['run_usec']/1e6,command_seconds=measurement['command_seconds'],report_seconds=measurement['report_usec']/1e6,peak_rss_kib=measurement['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(appointments),worst_tick_ms=max(ticks)))
            for metric,values in [('appointment',appointments),('tick',ticks)]:latencies.append(dict(**tag,repeat=repeat,metric=metric,**quantiles(values)))
        first,second=results;assert first['report']==second['report'] and first['events']==second['events'],tag
        r=first['report'];ds=r['day_results']
        if pins:
            pin=pins[c,d,m,t,f];assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256']
        runs.append(dict(**tag,seed=42,meals=sum(x['resident_meals'] for x in ds),missed=sum(x['unmet_meals'] for x in ds),visitor_bread=sum(x['visitor_bread'] for x in ds),ale_sold=sum(x['ale_sold'] for x in ds),shifts=sum(x['shifts'] for x in ds),missed_shifts=sum(x['missed_shifts'] for x in ds),**r['totals']['produced'],successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],circulation=r['money']['circulation'],combined_currency=r['money']['final'],**r['labor']['counts'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
        name=f'{c}-{d}-{m}-{t}-{f.replace(":","-")}'
        (a.output/(name+'.json')).write_text(json.dumps(dict(report=r,measurements=[x['measurement'] for x in results]),separators=(',',':'))+'\n')
        def flatten(row):return {k:json.dumps(v,sort_keys=True,separators=(',',':')) if isinstance(v,(dict,list)) else v for k,v in row.items()}
        accounts.extend(flatten(dict(**tag,id=id,**account)) for id,account in r['accounts'].items())
        daily.extend(flatten(dict(**tag,**row)) for row in ds)
        transitions.extend(flatten(dict(**tag,**row)) for row in r['labor']['transitions'])
        for name,rows in [('runs',runs),('accounts',accounts),('days',daily),('performance',performance),('latency',latencies),('transitions',transitions)]:
            if rows:write_csv(a.output/(name+'.csv'),rows)
        print(tag,'meals/missed',runs[-1]['meals'],runs[-1]['missed'],'shifts',runs[-1]['shifts'],'starts/ends',r['labor']['counts']['employment_started'],r['labor']['counts']['employment_ended'],'audited/replayed',flush=True)
    (a.output/'verification.json').write_text(json.dumps(dict(cases=len(cases),process_runs=len(cases)*2,independent_audits=len(cases)*2,full_reports_and_events_replayed=True),indent=2)+'\n')


if __name__=='__main__':main()
