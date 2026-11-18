#!/usr/bin/env python3
"""M29 frozen 48-case cash allocation matrix and native M28 original parity."""
import argparse,copy,csv,json,os,subprocess,tempfile,time
from pathlib import Path
from profile_simulation import ROOT,godot_environment
from run_input import identity as input_identity,capture as input_capture
from input_audit import ARMS,analyze as old_analyze
from cash_allocation_audit import BASE,ALLOCATIONS,analyze
from run_brewery import digest
from run_economic_diagnostics import write_json,write_rows


def capture(condition='scarce',days=3,arm='R_baseline_instrumented',allocation='original'):
    cmd=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_cash_allocation.gd','--','--condition',condition,'--arm',arm,'--allocation',allocation,str(days),'42','--measure'];start=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(cmd,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        wall=time.perf_counter()-start;err.seek(0);error=err.read();assert child.returncode==0 and not error,(cmd,child.returncode,error.decode())
        out.seek(0);data=json.loads(out.read())
    data['measurement'].update(command_seconds=wall,peak_rss_kib=usage.ru_maxrss);return data


def parity(new,old):
    assert new['events']==old['events'],'native events/receipt links changed'
    r=copy.deepcopy(new['report']);assert r.pop('cash_allocation')['name']=='original';r['scenario']='settlement_input_reliability'
    assert r==old['report'],'full report/state/terms changed'
    return dict(native_events_identical=True,ledger_identical=True,full_report_except_scenario_metadata=True,old_report_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256'])


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--traces',type=Path,required=True);p.add_argument('--checkpoint',action='store_true');p.add_argument('--reuse-checkpoint',action='store_true');p.add_argument('--old-traces',type=Path);a=p.parse_args()
    a.output.mkdir(parents=True,exist_ok=True);a.traces.mkdir(parents=True,exist_ok=True);model=input_identity();model.update(base=BASE,cash_cli=digest((ROOT/'scripts/tools/run_cash_allocation.gd').read_text()));start=time.perf_counter()
    cases=[(c,d,arm,allocation) for d in ([1,3] if a.checkpoint else [1,3,30]) for c in ['scarce','no_brew_request'] for arm in ARMS for allocation in ALLOCATIONS]
    if not a.checkpoint:cases +=[(c,30,arm,allocation) for c in ['tight','reference'] for arm in ARMS for allocation in ALLOCATIONS]
    pins={(r['condition'],r['days'],r['arm']):r for r in csv.DictReader((ROOT/'docs/M28_RUNS.csv').open())}
    runs=[];perf=[];comparisons=[]
    for c,days,arm,allocation in cases:
        tag=dict(condition=c,days=days,arm=arm,allocation=allocation,seed=42,stratum='primary' if c in ['scarce','no_brew_request'] else 'secondary');name=f'{c}-{days}-{arm}-{allocation}';first=None
        for repeat in [1,2]:
            path=a.traces/(name+f'-{repeat}.json');meta=path.with_suffix('.meta.json');reused=a.reuse_checkpoint and days in [1,3] and path.exists()
            if reused:assert json.loads(meta.read_text())==model;data=json.loads(path.read_text())
            else:data=capture(c,days,arm,allocation);write_json(path,data);write_json(meta,model)
            stamp=time.perf_counter();diagnostic=analyze(data);audit_seconds=time.perf_counter()-stamp;m=data['measurement']
            perf.append(dict(**tag,repeat=repeat,reused_checkpoint=reused,run_seconds=m['run_usec']/1e6,command_seconds=m['command_seconds'],report_seconds=m['report_usec']/1e6,peak_rss_kib=m['peak_rss_kib'],events=len(data['events']),audit_seconds=audit_seconds,worst_appointment_ms=max(x['usec'] for x in m['appointments'])/1000,worst_tick_ms=max(x['usec'] for x in m['ticks'])/1000))
            if first is None:first=data;write_json(a.output/'analyses'/(name+'.json'),diagnostic)
            else:assert first['report']==data['report'] and first['events']==data['events']
        r=first['report'];ds=r['day_results'];workers=r['contracts']['workers']
        if allocation=='original':
            cached=a.old_traces/f'{c}-{days}-{arm}-none-1.json' if a.old_traces else None
            old=json.loads(cached.read_text()) if cached and cached.exists() else input_capture(c,days,arm)
            old_analyze(old);pin=pins[c,str(days),arm];assert digest(dict(report=old['report']))==pin['summary_sha256'] and old['report']['ledger_sha256']==pin['ledger_sha256']
            comparisons.append(dict(**tag,**parity(first,old)));write_rows(a.output/'parity.csv',comparisons)
        runs.append(dict(**tag,meals=sum(x['resident_meals'] for x in ds),missed=sum(x['unmet_meals'] for x in ds),visitor_meals=sum(x['visitor_bread'] for x in ds),productive=sum(x['shifts'] for x in ds),standby=sum(x['standby'] for x in workers.values()),wages=sum(x['cash_wages'] for x in workers.values()),arrears=sum(x['arrears'] for x in workers.values()),**r['totals']['produced'],circulation=r['money']['circulation'],currency=r['money']['final'],active_jobs=len(r['final']['affiliations']),successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],last_productive_day=max((d['day'] for d in ds if d['shifts']),default=0),**r['contracts']['counts'],summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
        for n,rows in [('runs',runs),('performance',perf)]:write_rows(a.output/(n+'.csv'),rows)
        write_json(a.output/'reports'/(name+'.json'),dict(report=r));print(name,'native replay, full audit and original parity PASS',flush=True)
    write_json(a.output/'verification.json',dict(cases=len(cases),captures=len(cases)*2,original_parity_cases=len(comparisons),model=model,command_seconds=time.perf_counter()-start))


if __name__=='__main__':main()
