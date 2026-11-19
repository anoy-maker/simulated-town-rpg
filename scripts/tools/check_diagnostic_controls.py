#!/usr/bin/env python3
"""M27 unchanged-model C/D trace reuse and additional historical M26 controls."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
from profile_simulation import ROOT,write_csv,godot_environment
from measure_planning_jobs import capture as capture_cd,validate
from run_demand import capture,economic_parity
from demand_audit import audit
from run_binding import capture as capture_old
from binding_audit import audit as audit_old
from run_brewery import digest
from economic_diagnostics import BASE


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--reuse-cd',type=Path);p.add_argument('--cd',action='store_true');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);rows=[]
    if a.cd:
        # Cached traces are native evidence, not cached audit results. The original
        # numerical/financial/spatial auditors must run again on every copied file.
        assert subprocess.run(['git','diff','--quiet','896d090',BASE,'--','scripts','tests'],cwd=ROOT).returncode==0
        for stage in 'CD':
            for days in (1,3,30):
                for mode in ('sync','scheduled'):
                    name=f'{stage}-{days}-{mode}-none.json';source=a.reuse_cd/name if a.reuse_cd else None
                    if source and source.exists():
                        data=json.loads(source.read_text());validate(data);shutil.copy2(source,a.output/name);reused=True
                    else:
                        data=capture_cd(stage,days,mode);validate(data);(a.output/name).write_text(json.dumps(data,separators=(',',':')));reused=False
                    rows.append(dict(case=name,reused_native_trace=reused,model_source_unchanged=True,
                        canonical_sha256=data['measurement']['canonical_sha256'],ledger_sha256=data['report']['profitable']['ledger_sha256'],
                        trace_sha256=hashlib.sha256((a.output/name).read_bytes()).hexdigest(),audit_required='original independent audit; not replaced by cache'))
                    write_csv(a.output/'source-manifest.csv',rows)
        return
    pins=list(csv.DictReader((ROOT/'docs/M26_STAGGERED_RUNS.csv').open()))
    for pin in pins:
        data=capture(pin['condition'],30,pin['arm'],'staggered');audit(data);r=data['report']
        assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256']
        if pin['arm']=='legacy_instrumented':
            old=capture_old(pin['condition'],30,fixture='staggered');audit_old(old);economic_parity(data,old)
        rows.append(dict(case=pin['condition']+'-'+pin['arm'],configuration='staggered',summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256'],independent_audit=True))
        write_csv(a.output/'controls.csv',rows);print(rows[-1]['case'],'historical pins/audit PASS',flush=True)
    fixture_pins={p['fixture']:p for p in csv.DictReader((ROOT/'docs/M26_FIXTURES.csv').open())}
    for label,pin in fixture_pins.items():
        child=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_demand_fixture.gd','--',label],capture_output=True,env=godot_environment(),timeout=90)
        assert child.returncode==0 and not child.stderr,child.stderr.decode();data=json.loads(child.stdout);audit(data)
        assert digest(dict(report=data['report']))==pin['summary_sha256'] and data['report']['ledger_sha256']==pin['ledger_sha256']
        rows.append(dict(case=label,configuration='observation_fixture',summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256'],independent_audit=True))
        write_csv(a.output/'controls.csv',rows);print(label,'historical pins/audit PASS',flush=True)


if __name__=='__main__':main()
