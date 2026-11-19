#!/usr/bin/env python3
"""Bounded M22 tables; raw latency distributions and actual sample sizes."""
import argparse,csv,json,statistics,shutil
from collections import defaultdict
from pathlib import Path
from planning_load_tools import quantiles
from profile_simulation import write_csv
p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
raw=list(csv.DictReader((a.input/'load/runs.csv').open()));details=json.loads((a.input/'load/details.json').read_text());groups=defaultdict(list);latencies=defaultdict(list);order=[]
for r,d in zip(raw,details):
    key=(d['kind'],d['count'],d['workers']);groups[key].append((r,d))
    latencies[key+('callback',)].extend(x/1000 for x in d['callbacks_usec'])
    latencies[key+('heartbeat_gap',)].extend(x/1000 for x in d['heartbeat_gaps_usec'])
    for j in d['records']:
        values={'admission':j['admission_usec'],'serialization':j['serialize_usec'],'queue_to_dispatch':j['dispatched_usec']-j['enqueued_usec'],'queue_to_start':j['started_usec']-j['enqueued_usec'],'execution':j['finished_usec']-j['started_usec'],'full_policy':j['compute_usec'],'post_complete_poll':j['polled_usec']-j['finished_usec'],'finish_to_eligible':j['released_usec']-j['finished_usec'],'total_to_eligible':j['released_usec']-j['enqueued_usec'],'release_work':j['release_work_usec'],'numerical':sum(x['compute_usec'] for x in j['batches']),'pack':sum(x['pack_usec'] for x in j['batches']),'unpack':sum(x['unpack_usec'] for x in j['batches'])}
        for kind,value in values.items():latencies[key+(kind,)].append(value/1000)
    if d['kind']=='ordering':order.append(dict(repeat=d['repeat'],finish_order=','.join(r['id'] for r in sorted(d['records'],key=lambda r:r['finished_usec'])),release_order=','.join(r['id'] for r in d['ledger']),release_digest=d['release_digest'],proposal_digest=d['proposal_digest']))
rows=[]
for (kind,n,w),samples in groups.items():
    times=[d['run_usec']/1e6 for _,d in samples];base=statistics.median(d['run_usec']/1e6 for _,d in groups[(kind,n,1)]) if (kind,n,1) in groups else None
    rows.append(dict(kind=kind,count=n,workers=w,n=len(samples),median_seconds=statistics.median(times),min_seconds=min(times),max_seconds=max(times),jobs_per_second=n/statistics.median(times),speedup=base/statistics.median(times) if base else '',efficiency=base/statistics.median(times)/w if base else '',median_command_seconds=statistics.median(d['command_seconds'] for _,d in samples),median_peak_rss_kib=statistics.median(d['peak_rss_kib'] for _,d in samples),median_resident_before_kib=statistics.median(d['memory_before']['VmRSS'] for _,d in samples),median_resident_warm_kib=statistics.median(d['memory_warm']['VmRSS'] for _,d in samples),median_resident_final_kib=statistics.median(d['memory_final']['VmRSS'] for _,d in samples),median_resident_after_cleanup_kib=statistics.median(d['memory_after_cleanup']['VmRSS'] for _,d in samples),max_inputs=max(d['maxima']['input_bytes'] for _,d in samples),max_outputs=max(d['maxima']['output_bytes'] for _,d in samples),max_outstanding=max(d['maxima']['outstanding'] for _,d in samples),max_waiting=max(d['maxima']['waiting'] for _,d in samples),max_completed=max(d['maxima']['completed'] for _,d in samples),total_full_rejections=sum(d['rejection_counts'].get('full',0) for _,d in samples),median_cleanup_usec=statistics.median(d['cleanup_usec'] for _,d in samples)))
write_csv(a.output/'M22_SUMMARY.csv',rows);write_csv(a.output/'M22_RUNS.csv',raw);write_csv(a.output/'M22_ORDER.csv',order)
rows=[]
for key,values in latencies.items():rows.append(dict(zip(('kind','count','workers','metric'),key),**quantiles(values)))
write_csv(a.output/'M22_LATENCY.csv',rows)
if (a.input/'controls/world-runs.csv').exists():
    values=list(csv.DictReader((a.input/'controls/world-runs.csv').open()));write_csv(a.output/'M22_WORLD_RUNS.csv',values)
    groups=defaultdict(list)
    for r in values:groups[r['stage'],r['days'],r['mode']].append(r)
    rows=[]
    for (stage,days,mode),values in groups.items():
        times=[float(x['run_usec'])/1e6 for x in values]
        rows.append(dict(stage=stage,days=days,mode=mode,n=len(times),median_seconds=statistics.median(times),min_seconds=min(times),max_seconds=max(times),median_command_seconds=statistics.median(float(x['command_seconds']) for x in values)))
    write_csv(a.output/'M22_WORLD_SUMMARY.csv',rows)
    measurements=json.loads((a.input/'controls/world-details.json').read_text());latencies=defaultdict(list)
    for d in measurements:
        if d['days']!=30:continue
        key=(d['stage'],d['mode'])
        for metric,values in [('callback',[r['usec'] for r in d['callbacks']]),('heartbeat_gap',d['heartbeat_gaps_usec']),('decision',[r['usec'] for r in d['decisions']] if d['mode']=='sync' else [r['compute_usec'] for r in d['jobs']]),('required_decision_latency',[r['usec'] for r in d['appointments'] if r['minute']==745] if d['mode']=='sync' else [r['usec'] for r in d['appointment_latencies']]),('appointment',[r['usec'] for r in d['appointments']])]:
            latencies[key+(metric,)].extend(value/1000 for value in values)
    write_csv(a.output/'M22_WORLD_LATENCY.csv',[dict(zip(('stage','mode','metric'),key),**quantiles(values)) for key,values in latencies.items()])
for name,target in [('controls/audits.csv','M22_AUDITS.csv'),('historical.csv','M22_REGRESSIONS.csv')]:
    if (a.input/name).exists():shutil.copy2(a.input/name,a.output/target)
print('exported',len(raw),'load runs and measured latency tables')
