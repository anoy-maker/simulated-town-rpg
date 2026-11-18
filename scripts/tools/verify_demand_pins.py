#!/usr/bin/env python3
"""Final focused30-day audit recaptures against frozen M26 experimental pins.

Useful after tightening evidence validation; timings are verification costs,
never substituted into the isolated benchmark samples.
"""
import argparse
import csv
import time
from pathlib import Path
from demand_audit import audit
from run_demand import capture
from run_brewery import digest
from profile_simulation import ROOT,write_csv


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();rows=[]
    for source in ('M26_RUNS.csv','M26_STAGGERED_RUNS.csv'):
        for pin in csv.DictReader((ROOT/'docs'/source).open()):
            if pin['days']!='30':continue
            stamp=time.perf_counter();data=capture(pin['condition'],30,pin['arm'],pin['fixture']);audit(data)
            assert digest(dict(report=data['report']))==pin['summary_sha256'] and data['report']['ledger_sha256']==pin['ledger_sha256']
            rows.append(dict(condition=pin['condition'],days=30,arm=pin['arm'],fixture=pin['fixture'],summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256'],seconds=time.perf_counter()-stamp,independent_audit=True))
            write_csv(a.output,rows);print(rows[-1],flush=True)


if __name__=='__main__':main()
