#!/usr/bin/env python3
"""Reaudit pinned M28 raw controls on verified unchanged reachable source."""
import argparse,csv,hashlib,json,re,subprocess,time
from pathlib import Path
from input_audit import analyze
from profile_simulation import ROOT,godot_environment
from run_input import capture
from run_brewery import digest
from run_economic_diagnostics import write_json,write_rows
from cash_allocation_audit import BASE

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--old-traces',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    todo=['scripts/tools/run_input.gd'];seen={}
    while todo:
        name=todo.pop()
        if name in seen:continue
        content=(ROOT/name).read_bytes();assert content==subprocess.check_output(['git','show',BASE+':'+name],cwd=ROOT),name
        seen[name]=hashlib.sha256(content).hexdigest();todo+=re.findall(r'[\"\']res://([^\"\']+\.gd)[\"\']',content.decode())
    write_json(a.output/'dependencies.json',dict(base=BASE,unchanged_reachable_GDScript=seen,godot=subprocess.check_output(['godot','--version'],env=godot_environment(),text=True).strip()))
    rows=[];start=time.perf_counter()
    for table,fixture in [('M28_RUNS.csv','none'),('M28_STAGGERED_RUNS.csv','staggered')]:
        for pin in csv.DictReader((ROOT/'docs'/table).open()):
            name=f"{pin['condition']}-{pin['days']}-{pin['arm']}-{fixture}-1.json";cached=a.old_traces/name if a.old_traces else None
            if cached and cached.exists():
                meta=json.loads(cached.with_suffix('.meta.json').read_text());assert meta['godot']==subprocess.check_output(['godot','--version'],env=godot_environment(),text=True).strip()
                data=json.loads(cached.read_text());reused=True
            else:data=capture(pin['condition'],int(pin['days']),pin['arm'],fixture);reused=False
            stamp=time.perf_counter();analyze(data);r=data['report'];assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256']
            rows.append(dict(case=name,reused_raw_trace=reused,full_independent_audit=True,audit_seconds=time.perf_counter()-stamp,summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256'],trace_sha256=hashlib.sha256(cached.read_bytes()).hexdigest() if reused else digest(data)))
            write_rows(a.output/'controls.csv',rows);print(name,'pinned source and full replay PASS',flush=True)
    write_json(a.output/'verification.json',dict(cases=len(rows),command_seconds=time.perf_counter()-start))

if __name__=='__main__':main()
