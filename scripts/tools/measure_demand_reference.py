#!/usr/bin/env python3
"""Isolated final-source reference30 timing; verify frozen outcomes each time."""
import argparse
import csv
import time
from pathlib import Path
from demand_audit import audit,ARMS
from run_demand import capture
from run_brewery import digest
from profile_simulation import ROOT,write_csv


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();rows=[]
    pins={r['arm']:r for r in csv.DictReader((ROOT/'docs/M26_RUNS.csv').open()) if r['condition']=='reference' and r['days']=='30'}
    for arm in ARMS:
        for repeat in (1,2):
            d=capture('reference',30,arm);stamp=time.perf_counter();audit(d);elapsed=time.perf_counter()-stamp
            assert digest(dict(report=d['report']))==pins[arm]['summary_sha256'] and d['report']['ledger_sha256']==pins[arm]['ledger_sha256']
            m=d['measurement'];rows.append(dict(arm=arm,condition='reference',days=30,repeat=repeat,run_seconds=m['run_usec']/1e6,report_seconds=m['report_usec']/1e6,command_seconds=m['command_seconds'],peak_rss_kib=m['peak_rss_kib'],events=len(d['events']),audit_seconds=elapsed,worst_appointment_ms=max(x['usec'] for x in m['appointments'])/1000,worst_tick_ms=max(x['usec'] for x in m['ticks'])/1000))
            write_csv(a.output,rows);print(arm,repeat,'final-source pin and audit PASS',flush=True)


if __name__=='__main__':main()
