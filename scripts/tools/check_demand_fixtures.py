#!/usr/bin/env python3
"""Publish labeled M26 physical seller witnesses, twice with independent audits."""
import argparse
import json
from pathlib import Path
import subprocess
from demand_audit import audit
from profile_simulation import ROOT,godot_environment,write_csv
from run_brewery import digest


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);rows=[]
    for label in ('poor_visitors','cashless_buyers','remote_farm','duplicate'):
        first=None
        for repeat in (1,2):
            p=subprocess.run(['godot','--headless','--no-header','--path',str(ROOT),'--script','res://tests/run_demand_fixture.gd','--',label],capture_output=True,env=godot_environment(),timeout=60)
            assert p.returncode==0 and not p.stderr,p.stderr.decode();data=json.loads(p.stdout);audit(data)
            if first is None:first=data
            else:assert first==data
        r=first['report'];rows.append(dict(fixture=label,currency=r['money']['final'],resident_meals=sum(d['resident_meals'] for d in r['day_results']),visitor_meals=r['accounts']['visitors']['meals'],unfilled=r['demand']['unfilled'],audits=2,complete_replay=True,summary_sha256=digest(dict(report=r)),ledger_sha256=r['ledger_sha256']))
        (a.output/(label+'.json')).write_text(json.dumps(dict(report=r),separators=(',',':'))+'\n')
        print(label,'full native economic/evidence audit and process replay PASS',flush=True)
    write_csv(a.output/'results.csv',rows)


if __name__=='__main__':main()
