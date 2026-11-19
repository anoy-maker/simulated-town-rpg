#!/usr/bin/env python3
"""M25 frozen controls, native process replay, independent audits and compact evidence."""
import argparse
import csv
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from binding_audit import audit
from run_brewery import digest
from profile_simulation import ROOT,godot_environment,write_csv
from planning_load_tools import quantiles


def capture(condition='reference',days=3,mode='matching',fixture='none'):
    command=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_binding.gd','--','--condition',condition,'--mode',mode,'--fixture',fixture,str(days),'42','--measure']
    stamp=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(command,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-stamp;err.seek(0);error=err.read();assert child.returncode==0 and not error,(child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data['measurement'].update(command_seconds=elapsed,peak_rss_kib=usage.ru_maxrss)
    return data


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=Path('work/m25/experiments'));p.add_argument('--checkpoint',action='store_true');p.add_argument('--fixtures',action='store_true');p.add_argument('--verify-pins',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    cases=[(c,d,m,'none') for d in ((1,3) if a.checkpoint else (1,3,30)) for c in ('reference','tight','scarce','no_brew_request') for m in ('matching','obligations_only')]
    if a.fixtures:cases=[('reference',d,'matching',f) for f,d in [('cash_short',1),('cash_zero',1),('mill_zero',1),('insolvent',4),('no_show',3),('staggered',4)]]
    pins={}
    if a.verify_pins:
        for row in csv.DictReader(a.verify_pins.open()):pins[row['condition'],int(row['days']),row['mode'],row['fixture']]=row
    runs=[];performance=[];latencies=[]
    for c,d,m,f in cases:
        results=[];tag=dict(condition=c,days=d,mode=m,fixture=f,seed=42)
        for repeat in (1,2):
            data=capture(c,d,m,f);stamp=time.perf_counter();audit(data);audit_seconds=time.perf_counter()-stamp;results.append(data)
            measurement=data['measurement'];appointments=[row['usec']/1000 for row in measurement['appointments']];ticks=[row['usec']/1000 for row in measurement['ticks']]
            performance.append(dict(**tag,repeat=repeat,run_seconds=measurement['run_usec']/1e6,command_seconds=measurement['command_seconds'],report_seconds=measurement['report_usec']/1e6,peak_rss_kib=measurement['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(appointments),worst_tick_ms=max(ticks)))
            for metric,values in [('appointment',appointments),('tick',ticks)]:latencies.append(dict(**tag,repeat=repeat,metric=metric,**quantiles(values)))
        first,second=results;assert first['report']==second['report'] and first['events']==second['events'],tag
        r=first['report'];contract=r['contracts'];workers=contract['workers'];ds=r['day_results']
        row=dict(**tag,meals=sum(x['resident_meals'] for x in ds),missed=sum(x['unmet_meals'] for x in ds),productive=sum(x['shifts'] for x in ds),scheduled=sum(w['scheduled'] for w in workers.values()),attended=sum(w['attended'] for w in workers.values()),standby=sum(w['standby'] for w in workers.values()),breaches=sum(w['breaches'] for w in workers.values()),accrued=sum(w['accrued'] for w in workers.values()),cash_wages=sum(w['cash_wages'] for w in workers.values()),arrears=sum(w['arrears'] for w in workers.values()),**r['totals']['produced'],successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],circulation=r['money']['circulation'],currency=r['money']['final'],**contract['counts'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256'])
        if pins:assert all(row[k]==pins[c,d,m,f][k] for k in ('summary_sha256','ledger_sha256'))
        runs.append(row)
        (a.output/f'{c}-{d}-{m}-{f}.json').write_text(json.dumps(dict(report=r,measurements=[x['measurement'] for x in results]),separators=(',',':'))+'\n')
        for name,rows in [('runs',runs),('performance',performance),('latency',latencies)]:write_csv(a.output/(name+'.csv'),rows)
        print(tag,'meals/missed',row['meals'],row['missed'],'productive/standby',row['productive'],row['standby'],'wages/arrears',row['cash_wages'],row['arrears'],'audited/replayed',flush=True)
    (a.output/'verification.json').write_text(json.dumps(dict(cases=len(cases),process_runs=len(cases)*2,independent_audits=len(cases)*2,complete_process_replay=True),indent=2)+'\n')


if __name__=='__main__':main()
