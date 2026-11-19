#!/usr/bin/env python3
"""M28 frozen matched matrix. Fresh native processes, strict replay and source pins."""
import argparse
import copy
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from profile_simulation import ROOT,godot_environment
from run_brewery import digest
from run_demand import capture as capture_demand
from demand_audit import audit as audit_demand
from input_audit import BASE,ARMS,analyze
from run_economic_diagnostics import write_json,write_rows,flatten


def capture(condition='reference',days=3,arm='R_baseline_instrumented',fixture='none'):
    command=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_input.gd','--','--condition',condition,'--arm',arm,'--fixture',fixture,str(days),'42','--measure']
    start=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(command,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-start;err.seek(0);error=err.read();assert child.returncode==0 and not error,(command,child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data['measurement'].update(command_seconds=elapsed,peak_rss_kib=usage.ru_maxrss)
    return data


def economic_parity(new,old):
    """Remove ONLY M28 bookkeeping and remap original receipt links. Keep every
    M26 request, decision, failure, claim, forecast and full economic report.
    """
    events=new['events'];kept=[e for e in events if not e['action'].startswith('input_')];ids={e['id']:i for i,e in enumerate(kept,1)}
    vectors={'sample_ids','order_ids','sale_ids','source_ids','receipt_ids','witness_clock_ids','empty_inspection_ids','purchase_event_ids'}
    def walk(value,key=''):
        if isinstance(value,dict):return {k:walk(v,k) for k,v in value.items() if k!='input_reliability'}
        if isinstance(value,list):return [ids[v] if key in vectors and type(v) is int else walk(v,key[:-1] if key.endswith('_ids') else key) for v in value]
        if type(value) is int and (key=='id' or key.endswith('event_id') or key.endswith('receipt_id')):return ids[value] if value else value
        return value
    normalized_events=walk(kept);assert normalized_events==old['events'],'native economic event/receipt drift'
    report=walk(new['report']);report['scenario']='settlement_demand_observation';report['event_count']=len(kept)
    report['ledger_sha256']=hashlib.sha256(json.dumps(normalized_events,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
    if report!=old['report']:
        mismatches=[k for k in report if report[k]!=old['report'].get(k)]
        raise AssertionError(('full normalized report drift',mismatches))
    return dict(all_native_events=True,full_normalized_report=True,initial_final_obligations=True,normalized_ledger_sha256=report['ledger_sha256'],raw_new_ledger_sha256=new['report']['ledger_sha256'],raw_old_ledger_sha256=old['report']['ledger_sha256'])


def identity():
    paths=list((ROOT/'scripts/sim').glob('*.gd'))+[ROOT/'scripts/tools/run_input.gd']
    source=digest({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)})
    return dict(base=BASE,native_source_sha256=source,godot=subprocess.check_output(['godot','--version'],env=godot_environment(),text=True).strip())


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--traces',type=Path,required=True)
    p.add_argument('--checkpoint',action='store_true');p.add_argument('--staggered',action='store_true');p.add_argument('--reuse-checkpoint',action='store_true');p.add_argument('--old-traces',type=Path)
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);a.traces.mkdir(parents=True,exist_ok=True);stamp=time.perf_counter();model=identity()
    cases=[(c,d,arm,'none') for d in ((1,3) if a.checkpoint else (1,3,30)) for c in ('reference','tight','scarce','no_brew_request') for arm in ARMS]
    if a.staggered:cases=[(c,30,arm,'staggered') for c in ('tight','scarce') for arm in ARMS]
    pins={(r['condition'],int(r['days'])):r for r in csv.DictReader((ROOT/'docs/M26_RUNS.csv').open()) if r['arm']=='requests_smoothed'}
    staggered={r['condition']:r for r in csv.DictReader((ROOT/'docs/M26_STAGGERED_RUNS.csv').open()) if r['arm']=='requests_smoothed'}
    runs=[];performance=[];parity=[]
    for c,d,arm,f in cases:
        tag=dict(condition=c,days=d,arm=arm,fixture=f,seed=42);name=f'{c}-{d}-{arm}-{f}';first=None
        for repeat in (1,2):
            path=a.traces/(name+f'-{repeat}.json');meta=path.with_suffix('.meta.json')
            reused=a.reuse_checkpoint and d in (1,3) and path.exists() and meta.exists()
            if reused:assert json.loads(meta.read_text())==model,'native checkpoint source/engine changed';data=json.loads(path.read_text())
            else:data=capture(c,d,arm,f);write_json(path,data);write_json(meta,model)
            start=time.perf_counter();diagnostic=analyze(data);audit_seconds=time.perf_counter()-start;m=data['measurement']
            performance.append(dict(**tag,repeat=repeat,reused_checkpoint=reused,run_seconds=m['run_usec']/1e6,report_seconds=m['report_usec']/1e6,command_seconds=m['command_seconds'],peak_rss_kib=m['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(x['usec'] for x in m['appointments'])/1000,worst_tick_ms=max(x['usec'] for x in m['ticks'])/1000))
            if first is None:first=data;write_json(a.output/'analyses'/(name+'.json'),diagnostic)
            else:assert first['report']==data['report'] and first['events']==data['events'],'fresh-process replay drift'
        r=first['report'];ds=r['day_results'];workers=r['contracts']['workers']
        if arm=='R_baseline_instrumented':
            cached=a.old_traces/f'{c}-{d}-requests_smoothed.json' if a.old_traces and f=='none' else None
            old=json.loads(cached.read_text()) if cached and cached.exists() else capture_demand(c,d,'requests_smoothed',f)
            audit_demand(old);pin=pins[c,d] if f=='none' else staggered[c]
            assert digest(dict(report=old['report']))==pin['summary_sha256'] and old['report']['ledger_sha256']==pin['ledger_sha256']
            parity.append(dict(**tag,**economic_parity(first,old),original_pins_unchanged=True,reused_original_trace=bool(cached and cached.exists())))
            write_rows(a.output/'parity.csv',parity)
        runs.append(dict(**tag,meals=sum(x['resident_meals'] for x in ds),missed=sum(x['unmet_meals'] for x in ds),visitor_meals=sum(x['visitor_bread'] for x in ds),productive=sum(x['shifts'] for x in ds),standby=sum(x['standby'] for x in workers.values()),cash_wages=sum(x['cash_wages'] for x in workers.values()),arrears=sum(x['arrears'] for x in workers.values()),**r['totals']['produced'],successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],circulation=r['money']['circulation'],currency=r['money']['final'],active_jobs=len(r['final']['affiliations']),zero_production_days=sum(not any(x['production'].values()) for x in ds),last_productive_day=max((x['day'] for x in ds if x['shifts']),default=0),**r['contracts']['counts'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
        for filename,rows in [('runs',runs),('performance',performance)]:write_rows(a.output/(filename+'.csv'),rows)
        write_json(a.output/'reports'/(name+'.json'),dict(report=r))
        print(name,'fresh replay, independent audit and baseline parity PASS',flush=True)
    write_json(a.output/'verification.json',dict(identity=model,cases=len(cases),fresh_process_repeats=2,parity_cases=len(parity),command_seconds=time.perf_counter()-stamp,scope='staggered initial legal endowment' if a.staggered else 'main'))


if __name__=='__main__':main()
