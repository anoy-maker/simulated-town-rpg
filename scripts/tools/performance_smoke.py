#!/usr/bin/env python3
"""Opt-in quick C/D1 + ten-job guardrail. Timing changes warn; correctness fails."""
import argparse,csv,json,statistics,time
from pathlib import Path
from compare_native_math import capture as world_capture,PINNED
from planning_load_tools import capture,host,quantiles

def regression_warnings(current,reference):
    warnings=[]
    comparable=(current['host'].get('cpu_max') not in (None, 'unavailable')
                and all(current['host'].get(k)==reference['host'].get(k)
                        for k in ('godot','machine','cpu_max','rust_sha256')))
    if not comparable:warnings.append('Reference host/engine/kernel differs; timing ratios are informational only.')
    for case,new in current['cases'].items():
        old=reference.get('cases',{}).get(case)
        if not old: warnings.append(f'{case}: no reference');continue
        if new['run_seconds']>old['run_seconds']*1.5:warnings.append(f'{case}: run time increased >50%')
        if new['peak_rss_kib']>old['peak_rss_kib']*1.25 and new['peak_rss_kib']-old['peak_rss_kib']>32768:warnings.append(f'{case}: peak RSS increased >25% and >32 MiB')
        if 'callback_ms' in new and 'callback_ms' in old:
            tail=lambda q:q.get('p99') or q.get('p95') or q.get('worst') or 0
            a,b=tail(new['callback_ms']),tail(old['callback_ms'])
            if a>b*1.5 and a-b>5:warnings.append(f'{case}: callback tail increased >50% and >5 ms')
    return comparable,warnings

def collect():
    start=time.perf_counter();cases={}
    for stage in 'CD':
        data=world_capture(stage,1,'rust');m=data['measurement']
        assert m['canonical_sha256']==PINNED[stage,1]['summary_sha256']
        cases[stage+'1']=dict(run_seconds=m['run_usec']/1e6,command_seconds=m['command_seconds'],report_seconds=m['report_usec']/1e6,peak_rss_kib=m['command_peak_rss_kib'],event_count=len(data['events']),canonical_sha256=m['canonical_sha256'],decision_work_ms=quantiles([r['usec']/1000 for r in m['decisions']]),worst_appointment_ms=max(r['usec'] for r in m['appointments'])/1000,worst_tick_ms=max(r['usec'] for r in m['ticks'])/1000)
    data=capture(10,1)
    cases['queue10']=dict(run_seconds=data['run_usec']/1e6,command_seconds=data['command_seconds'],peak_rss_kib=data['peak_rss_kib'],event_count=0,callback_ms=quantiles([x/1000 for x in data['callbacks_usec']]),queue_wait_ms=quantiles([(r['started_usec']-r['enqueued_usec'])/1000 for r in data['records']]),decision_work_ms=quantiles([r['compute_usec']/1000 for r in data['records']]),maxima=data['maxima'],proposal_digest=data['proposal_digest'],release_digest=data['release_digest'])
    return dict(version=1,host=host(),cases=cases,command_wall_seconds=time.perf_counter()-start,verification_phases=[],warnings=[])

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--reference',type=Path,default=Path(__file__).resolve().parents[2]/'docs/M22_SMOKE_REFERENCE.json');p.add_argument('--verification-times',type=Path);a=p.parse_args()
    result=collect()
    if a.reference and a.reference.exists():
        result['comparable'],result['warnings']=regression_warnings(result,json.loads(a.reference.read_text()))
    if a.verification_times:
        with a.verification_times.open() as f:result['verification_phases']=list(csv.DictReader(f))
    a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))
if __name__=='__main__':main()
