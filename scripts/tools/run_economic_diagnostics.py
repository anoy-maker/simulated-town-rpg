#!/usr/bin/env python3
"""M27 pinned trace capture/reuse, passive diagnostics and independent certificates."""
import argparse
import csv
import json
import os
from pathlib import Path
import subprocess
import time
from profile_simulation import ROOT,write_csv,godot_environment
from run_demand import capture,economic_parity
from run_binding import capture as capture_binding
from binding_audit import audit as audit_binding
from run_brewery import digest
from demand_audit import ARMS
from economic_diagnostics import BASE,analyze
from economic_witness import generate
from check_economic_witness import verify
from economic_wedge import wedge,five_wheat_chain


def write_json(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,sort_keys=True,separators=(',',':'))+'\n')


def flatten(row):return {k:json.dumps(v,sort_keys=True,separators=(',',':')) if isinstance(v,(dict,list)) else v for k,v in row.items()}


def write_rows(path,rows):
    keys=list(dict.fromkeys(k for row in rows for k in row))
    write_csv(path,[{k:row.get(k) for k in keys} for row in rows])


def version():
    assert subprocess.run(['git','diff','--quiet',BASE,'--','scripts/sim'],cwd=ROOT).returncode==0,'Godot source drift'
    paths=['brewery_audit.py','binding_audit.py','labor_market_audit.py','demand_audit.py','run_demand.py']
    assert subprocess.run(['git','diff','--quiet',BASE,'--',*['scripts/tools/'+p for p in paths]],cwd=ROOT).returncode==0,'original auditor/capture drift'
    return dict(base=BASE,sim_tree=subprocess.check_output(['git','rev-parse',BASE+':scripts/sim'],cwd=ROOT,text=True).strip(),
                godot=subprocess.check_output(['godot','--version'],cwd=ROOT,env=godot_environment(),text=True).strip(),
                python=subprocess.check_output(['python3','--version'],text=True).strip())


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=Path('work/m27/experiments'))
    p.add_argument('--traces',type=Path,default=Path('work/m27/traces'));p.add_argument('--checkpoint',action='store_true');p.add_argument('--legacy-parity',action='store_true')
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);a.traces.mkdir(parents=True,exist_ok=True);identity=version()
    pins={(r['condition'],int(r['days']),r['arm']):r for r in csv.DictReader((ROOT/'docs/M26_RUNS.csv').open())}
    oldpins={(r['condition'],int(r['days'])):r for r in csv.DictReader((ROOT/'docs/M25_RUNS.csv').open()) if r['mode']=='matching'}
    manifests=[];performance=[];physical=[];cash=[];firms=[];cohorts=[];constraints=[];failures=[];parity=[]
    phase=time.perf_counter()
    for days in ((1,3) if a.checkpoint else (1,3,30)):
        for condition in ('reference','tight','scarce','no_brew_request'):
            for arm in ARMS:
                tag=dict(condition=condition,arm=arm,seed=42,days=days);name=f'{condition}-{days}-{arm}'
                path=a.traces/(name+'.json');meta=a.traces/(name+'.meta.json');start=time.perf_counter();cached=path.exists() and meta.exists()
                if cached:
                    assert json.loads(meta.read_text())==identity,'cache source/engine mismatch'
                    data=json.loads(path.read_text());capture_seconds=0
                else:
                    data=capture(condition,days,arm);capture_seconds=time.perf_counter()-start
                    write_json(path,data);write_json(meta,identity)
                r=data['report'];pin=pins[condition,days,arm]
                assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256']
                stamp=time.perf_counter();diagnostic=analyze(data);analysis_seconds=time.perf_counter()-stamp
                stamp=time.perf_counter();again=analyze(data);assert diagnostic==again;replay_seconds=time.perf_counter()-stamp;del again
                if days==30:
                    for shorter in (1,3):
                        short=json.loads((a.traces/f'{condition}-{shorter}-{arm}.json').read_text())
                        assert data['events'][:short['report']['event_count']]==short['events']
                        assert r['day_results'][:shorter]==short['report']['day_results']
                    cash.extend(flatten(dict(**tag,**row)) for row in diagnostic['cash'])
                    firms.extend(flatten(dict(**tag,**row)) for row in diagnostic['firm_days'])
                    cohorts.extend(flatten(dict(**tag,**row)) for row in diagnostic['cohorts'])
                    constraints.extend(flatten(dict(**tag,**row)) for row in diagnostic['constraints'])
                    failures.extend(flatten(dict(**tag,**row)) for row in diagnostic['failure_attributions'])
                stamp=time.perf_counter()
                for day,bundle in diagnostic['snapshots'].items():
                    for tier in ('fixed_orders','voluntary_orders'):
                        plan=generate(bundle,tier);proof=verify(bundle,plan)
                        certificate=dict(source=diagnostic['source'],plan=plan,proof=proof)
                        write_json(a.output/'certificates'/f'{name}-day{day}-{tier}.json',certificate)
                        if days==30:
                            actual=r['day_results'][int(day)-1];f=proof['finance'];v=proof['physical']
                            physical.append(dict(**tag,day=int(day),tier=tier,actual_bread=actual['production']['bread'],actual_resident_meals=actual['resident_meals'],
                                label=v['label'],physically_feasible=v['physically_feasible'],bread_at_shop=v['bread_at_shop'],physical_upper_bound=v['physical_upper_bound'],
                                optimality=v['optimality'],physical_resident_delivery_ceiling=v['physical_resident_delivery_ceiling'],**v['production'],
                                finance_witnessed=f['finance_witnessed'],finance_reason=f.get('reason',''),resident_meals_witness=f.get('resident_meals'),
                                visitor_meals_witness=f.get('visitor_meals'),incentive_compatible=f['incentive_compatible'],
                                current_policy_quantity_agreement=f.get('current_policy_quantity_agreement'),snapshot_sha256=bundle['snapshot_sha256'],
                                source_report_sha256=pin['summary_sha256'],source_ledger_sha256=pin['ledger_sha256'],proof_sha256=digest(proof),
                                certificate=f'{name}-day{day}-{tier}.json'))
                witness_seconds=time.perf_counter()-stamp
                if a.legacy_parity and arm=='legacy_instrumented':
                    original=capture_binding(condition,days);audit_binding(original);oldpin=oldpins[condition,days]
                    assert digest(dict(report=original['report']))==oldpin['summary_sha256'] and original['report']['ledger_sha256']==oldpin['ledger_sha256']
                    parity.append(dict(**tag,**economic_parity(data,original)))
                    write_rows(a.output/'legacy-parity.csv',parity)
                manifest=dict(**tag,cached=cached,events=len(data['events']),summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256'],
                              diagnostic_sha256=digest(diagnostic),independent_audit=True,read_only=True,diagnostic_replay=True,source_base=BASE)
                manifests.append(manifest);m=data['measurement']
                performance.append(dict(**tag,cached=cached,capture_seconds=capture_seconds,analysis_seconds=analysis_seconds,replay_seconds=replay_seconds,
                    witnesses_seconds=witness_seconds,native_run_seconds=m['run_usec']/1e6,native_report_seconds=m['report_usec']/1e6,
                    native_peak_rss_kib=m['peak_rss_kib'],researcher_peak_rss_kib=__import__('resource').getrusage(__import__('resource').RUSAGE_SELF).ru_maxrss))
                write_json(a.output/'analyses'/(name+'.json'),diagnostic)
                for filename,rows in [('cases',manifests),('performance',performance),('physical_witnesses',physical),('cash_timelines',cash),('firm_days',firms),('cohort_days',cohorts),('constraints',constraints),('failure_attributions',failures)]:
                    if rows:write_rows(a.output/(filename+'.csv'),rows)
                print(name,'pins, full audit, read-only analysis, replay and witnesses PASS',flush=True)
    write_json(a.output/'conditional-wedges.json',dict(cases=[wedge(c) for c in (21,19,16)],chain=five_wheat_chain()))
    write_json(a.output/'verification.json',dict(identity=identity,cases=len(manifests),legacy_parity_cases=len(parity),command_seconds=time.perf_counter()-phase,
        diagnostic='offline only; no change to any simulation/agent inputs',physical_horizons=[1,3],observational_horizon=30,
        claims='optimality is restricted to declared physical spaces; no financed/30-day optimum or certified incentives'))


if __name__=='__main__':main()
