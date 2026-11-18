#!/usr/bin/env python3
"""Fresh M26 pins and unchanged M27 offline proofs on the M28 branch.

The M27 experiment CLI deliberately guards its exact old source tree. Reuse its
unchanged observer/generator/checker here against freshly captured historical
scenarios, and require the old diagnostic/proof digests rather than weaken it.
"""
import argparse
import csv
import json
import time
from pathlib import Path
from profile_simulation import ROOT
from run_demand import capture,economic_parity
from run_binding import capture as old_capture
from binding_audit import audit as old_audit
from economic_diagnostics import analyze
from economic_witness import generate
from check_economic_witness import verify
from run_brewery import digest
from run_economic_diagnostics import write_rows,write_json


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    cases={(r['condition'],r['arm'],r['days']):r for r in csv.DictReader((ROOT/'docs/M27_CASES.csv').open())}
    physical={(r['condition'],r['arm'],r['day'],r['tier']):r for r in csv.DictReader((ROOT/'docs/M27_PHYSICAL_WITNESSES.csv').open())}
    rows=[];proofs=[];parity=[];start=time.perf_counter()
    for pin in csv.DictReader((ROOT/'docs/M26_RUNS.csv').open()):
        c,days,arm=pin['condition'],int(pin['days']),pin['arm'];data=capture(c,days,arm);stamp=time.perf_counter();diagnostic=analyze(data);seconds=time.perf_counter()-stamp;r=data['report']
        assert digest(dict(report=r))==pin['summary_sha256'] and r['ledger_sha256']==pin['ledger_sha256']
        expected=cases[c,arm,str(days)];assert digest(diagnostic)==expected['diagnostic_sha256'],'M27 reader drift'
        if days==30:
            for day,bundle in diagnostic['snapshots'].items():
                for tier in ('fixed_orders','voluntary_orders'):
                    plan=generate(bundle,tier);proof=verify(bundle,plan);old=physical[c,arm,day,tier]
                    assert digest(proof)==old['proof_sha256'] and bundle['snapshot_sha256']==old['snapshot_sha256']
                    if arm=='legacy_instrumented':
                        path=ROOT/'docs/M27_CERTIFICATES'/old['certificate'];cert=json.loads(path.read_text())
                        assert cert['source']==diagnostic['source'];verify(bundle,cert['plan'],cert['proof'])
                    proofs.append(dict(condition=c,arm=arm,day=int(day),tier=tier,proof_sha256=digest(proof),historical_proof_unchanged=True))
        if arm=='legacy_instrumented':
            old=old_capture(c,days);old_audit(old);parity.append(dict(condition=c,days=days,**economic_parity(data,old)))
        rows.append(dict(condition=c,days=days,arm=arm,summary_sha256=pin['summary_sha256'],ledger_sha256=pin['ledger_sha256'],M27_diagnostic_sha256=digest(diagnostic),native_fresh=True,independent_audit=True,audit_seconds=seconds))
        for n,values in [('controls',rows),('proofs',proofs),('legacy-parity',parity)]:
            if values:write_rows(a.output/(n+'.csv'),values)
        print(c,days,arm,'fresh M26 pins and M27 digest/proofs PASS',flush=True)
    assert len(rows)==36 and len(proofs)==48 and len(parity)==12
    write_json(a.output/'verification.json',dict(fresh_M26_cases=36,unchanged_M27_diagnostics=36,unchanged_M27_proofs=48,complete_committed_certificates=16,M25_legacy_parity_cases=12,command_seconds=time.perf_counter()-start))


if __name__=='__main__':main()
