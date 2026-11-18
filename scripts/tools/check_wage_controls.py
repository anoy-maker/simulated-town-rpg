#!/usr/bin/env python3
"""Fresh historical M28/M29 execution after default-ten authority accessors."""
import argparse,copy,csv,json,time
from pathlib import Path
from profile_simulation import ROOT
from run_input import capture as capture_input,economic_parity
from run_cash_allocation import capture as capture_cash,parity as cash_parity
from run_demand import capture as capture_demand
from input_audit import analyze as audit_input
from cash_allocation_audit import analyze as audit_cash
from demand_audit import audit as audit_demand
from run_wages import save_trace,load_trace,identity
from run_brewery import digest
from run_economic_diagnostics import write_json,write_rows


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--R-comparison-traces',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
 controls=[];parities=[];cash=[];start=time.perf_counter();model=identity();seen={}
 pins={(r['condition'],r['days']):r for r in csv.DictReader((ROOT/'docs/M26_RUNS.csv').open()) if r['arm']=='requests_smoothed'}
 staggered={r['condition']:r for r in csv.DictReader((ROOT/'docs/M26_STAGGERED_RUNS.csv').open()) if r['arm']=='requests_smoothed'}
 for table,fixture,group in [('M28_RUNS.csv','none','M28'),('M28_STAGGERED_RUNS.csv','staggered','M28'),('M29_RUNS.csv','none','M29')]:
  for pin in csv.DictReader((ROOT/'docs'/table).open()):
   c,days,arm=pin['condition'],int(pin['days']),pin['arm'];allocation=pin.get('allocation','original');name=f'{group}-{c}-{days}-{arm}-{allocation}-{fixture}'
   data=capture_input(c,days,arm,fixture) if group=='M28' else capture_cash(c,days,arm,allocation)
   stamp=time.perf_counter();(audit_input if group=='M28' else audit_cash)(data);audit_seconds=time.perf_counter()-stamp;r=data['report']
   assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256'],name
   save_trace(a.output/'native'/(name+'.json.gz'),data)
   controls.append(dict(group=group,condition=c,days=days,arm=arm,allocation=allocation,fixture=fixture,source_table=table,fresh_native=True,full_independent_audit=True,command_seconds=data['measurement']['command_seconds'],audit_seconds=audit_seconds,peak_rss_kib=data['measurement']['peak_rss_kib'],summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256']))
   if group=='M28' and (arm=='R_baseline_instrumented' or c=='reference'):
    key=c,days,fixture
    if key not in seen:
     path=a.R_comparison_traces/f'{c}-{days}-requests_smoothed.json' if a.R_comparison_traces and fixture=='none' else None
     old=json.loads(path.read_text()) if path and path.exists() else capture_demand(c,days,'requests_smoothed',fixture)
     audit_demand(old);pinned=pins[c,str(days)] if fixture=='none' else staggered[c]
     assert digest(dict(report=old['report']))==pinned['summary_sha256'] and old['report']['ledger_sha256']==pinned['ledger_sha256'];seen[key]=old
    parities.append(dict(condition=c,days=days,arm=arm,fixture=fixture,comparison_is_pinned_historical_R=True,**economic_parity(data,seen[key])))
   if group=='M29' and allocation=='original':
    original=load_trace(a.output/'native'/f'M28-{c}-{days}-{arm}-original-none.json.gz');cash.append(dict(condition=c,days=days,arm=arm,**cash_parity(data,original)))
   for label,rows in [('controls',controls),('M28-R-parity',parities),('M29-M28-parity',cash)]:
    if rows:write_rows(a.output/(label+'.csv'),rows)
   print(name,'fresh native published report/ledger and full audit PASS',flush=True)
 assert len(controls)==76 and len(parities)==17 and len(cash)==16
 write_json(a.output/'verification.json',dict(fresh_M28_cases=28,fresh_M29_cases=48,M28_R_economic_parities=17,M29_M28_original_native_parities=16,model=model,command_seconds=time.perf_counter()-start,R_note='Pinned historical R payloads are comparison inputs, not substituted fresh M26 controls; all36 M26 controls execute afresh in separate acceptance.'))

if __name__=='__main__':main()
