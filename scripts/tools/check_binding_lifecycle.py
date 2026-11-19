#!/usr/bin/env python3
"""Fresh, independently audited M25 authority witnesses; no economic policy tuning."""
import argparse
import json
from pathlib import Path
import subprocess
import time
from binding_audit import audit
from profile_simulation import ROOT,godot_environment,write_csv
from run_brewery import digest


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);rows=[]
    for fixture in ('decline','renew','rehire','cancel','worker_release','employer_release','overlap','remote','oldest_after_expiry','declined_assignment'):
        stamp=time.perf_counter();result=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_binding_lifecycle.gd','--',fixture],capture_output=True,env=godot_environment(),timeout=90)
        command_seconds=time.perf_counter()-stamp;assert result.returncode==0 and not result.stderr,(fixture,result.returncode,result.stderr.decode())
        data=json.loads(result.stdout);stamp=time.perf_counter();audit(data);audit_seconds=time.perf_counter()-stamp
        r=data['report'];c=r['contracts'];workers=c['workers'];rows.append(dict(fixture=fixture,days=r['days'],currency=r['money']['final'],meals=sum(x['resident_meals'] for x in r['day_results']),missed=sum(x['unmet_meals'] for x in r['day_results']),productive=sum(w['productive'] for w in workers.values()),attended=sum(w['attended'] for w in workers.values()),cash_wages=sum(w['cash_wages'] for w in workers.values()),arrears=sum(w['arrears'] for w in workers.values()),**c['counts'],canceled_pending=r['labor']['counts']['canceled_pending'],command_seconds=command_seconds,audit_seconds=audit_seconds,summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
        write_csv(a.output/'results.csv',rows);(a.output/(fixture+'.json')).write_text(json.dumps(dict(report=r),separators=(',',':'))+'\n')
        print(fixture,'audited',flush=True)


if __name__=='__main__':main()
