#!/usr/bin/env python3
"""M26 frozen factorial, full native replay/audits and M25 economic parity."""
import argparse
import copy
import csv
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from demand_audit import audit, ARMS
from run_binding import capture as binding_capture
from binding_audit import audit as binding_audit
from run_brewery import digest
from profile_simulation import ROOT,godot_environment,write_csv
from planning_load_tools import quantiles


def capture(condition='reference',days=3,arm='legacy_instrumented',fixture='none'):
    command=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_demand.gd','--','--condition',condition,'--arm',arm,'--fixture',fixture,str(days),'42','--measure']
    stamp=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(command,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-stamp;err.seek(0);error=err.read();assert child.returncode==0 and not error,(child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data['measurement'].update(command_seconds=elapsed,peak_rss_kib=usage.ru_maxrss)
    return data


def economic_parity(new,old):
    """Compare EVERY original event/state after removing only added observations
    and empty-stock retail failures, renumbering their native receipt links.
    This is stronger than comparing production/meals alone.
    """
    def normalize(data):
        events=data['events'];removed={e['id'] for e in events if e['action'].startswith('demand_') or (e['action']=='purchase' and not e['success'] and e['id']>1 and events[e['id']-2]['action']=='demand_customer_intent')}
        kept=[e for e in events if e['id'] not in removed];ids={e['id']:i for i,e in enumerate(kept,1)}
        def walk(value,key=''):
            if isinstance(value,dict):return {k:walk(v,k) for k,v in value.items() if k!='demand_observations'}
            if isinstance(value,list):return [walk(v,key[:-1] if key.endswith('_ids') else key) for v in value]
            if type(value) is int and (key=='id' or key.endswith('event_id') or key.endswith('receipt_id')):return ids[value] if value else value
            return value
        return walk(kept),walk(data['report']['initial']),walk(data['report']['final'])
    a,b=normalize(new),normalize(old)
    for label,x,y in zip(('all native events','initial','final'),a,b):
        if x!=y:
            if isinstance(x,list):
                mismatch=next(((i,p,q) for i,(p,q) in enumerate(zip(x,y)) if p!=q),('length',len(x),len(y)))
            else:mismatch=(x,y)
            raise AssertionError((label,mismatch))
    for k in ('accounts','totals','money','day_results'):
        assert new['report'][k]==old['report'][k],k
    return dict(all_native_events=True,initial_final=True,accounts_goods_money_days=True)


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=Path('work/m26/experiments'));p.add_argument('--checkpoint',action='store_true');p.add_argument('--staggered',action='store_true');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    cases=[(c,d,arm,'none') for d in ((1,3) if a.checkpoint else (1,3,30)) for c in ('reference','tight','scarce','no_brew_request') for arm in ARMS]
    if a.staggered:cases=[(c,30,arm,'staggered') for c in ('tight','scarce') for arm in ('legacy_instrumented','requests_smoothed')]
    pins={(r['condition'],int(r['days'])):r for r in csv.DictReader((ROOT/'docs/M25_RUNS.csv').open()) if r['mode']=='matching' and r['fixture']=='none'}
    runs=[];performance=[];latencies=[];parity=[]
    for c,d,arm,f in cases:
        tag=dict(condition=c,days=d,arm=arm,fixture=f,seed=42);first=None
        for repeat in (1,2):
            data=capture(c,d,arm,f);stamp=time.perf_counter();audit(data);audit_seconds=time.perf_counter()-stamp
            m=data['measurement'];appointments=[row['usec']/1000 for row in m['appointments']];ticks=[row['usec']/1000 for row in m['ticks']]
            performance.append(dict(**tag,repeat=repeat,run_seconds=m['run_usec']/1e6,command_seconds=m['command_seconds'],report_seconds=m['report_usec']/1e6,peak_rss_kib=m['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(appointments),worst_tick_ms=max(ticks)))
            for metric,values in [('appointment',appointments),('tick',ticks)]:latencies.append(dict(**tag,repeat=repeat,metric=metric,**quantiles(values)))
            if first is None:first=data
            else:assert first['report']==data['report'] and first['events']==data['events'],tag
        r=first['report'];ds=r['day_results'];workers=r['contracts']['workers']
        if arm=='legacy_instrumented':
            old=binding_capture(c,d,'matching',f);binding_audit(old)
            if f=='none':assert digest(dict(report=old['report']))==pins[c,d]['summary_sha256'] and old['report']['ledger_sha256']==pins[c,d]['ledger_sha256']
            parity.append(dict(**tag,**economic_parity(first,old),old_summary_sha256=digest(dict(report=old['report'])),old_ledger_sha256=old['report']['ledger_sha256']))
        row=dict(**tag,meals=sum(x['resident_meals'] for x in ds),missed=sum(x['unmet_meals'] for x in ds),visitor_meals=sum(x['visitor_bread'] for x in ds),productive=sum(x['shifts'] for x in ds),attended=sum(x['attended'] for x in workers.values()),standby=sum(x['standby'] for x in workers.values()),cash_wages=sum(x['cash_wages'] for x in workers.values()),arrears=sum(x['arrears'] for x in workers.values()),**r['totals']['produced'],successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],circulation=r['money']['circulation'],currency=r['money']['final'],unfilled=r['demand']['unfilled'],zero_production_days=sum(not any(x['production'].values()) for x in ds),last_productive_day=max((x['day'] for x in ds if x['shifts']),default=0),active_jobs=len(r['final']['affiliations']),**r['contracts']['counts'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256'])
        runs.append(row)
        (a.output/f'{c}-{d}-{arm}-{f}.json').write_text(json.dumps(dict(report=r),separators=(',',':'))+'\n')
        for name,rows in [('runs',runs),('performance',performance),('latency',latencies),('parity',parity)]:
            if rows:write_csv(a.output/(name+'.csv'),rows)
        print(tag,'meals/missed',row['meals'],row['missed'],'output',r['totals']['produced'],'audited/replayed',flush=True)
    (a.output/'verification.json').write_text(json.dumps(dict(cases=len(cases),process_runs=len(cases)*2,independent_audits=len(cases)*2,complete_process_replay=True,legacy_parity_cases=len(parity)),indent=2)+'\n')


if __name__=='__main__':main()
