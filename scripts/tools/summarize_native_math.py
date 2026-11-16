#!/usr/bin/env python3
"""Export bounded M20 tables; retain actual n and nearest-rank latency quantiles."""
import argparse,csv,json,math,statistics
from collections import defaultdict
from pathlib import Path
from profile_simulation import write_csv
p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
raw=list(csv.DictReader((a.input/'bench/runs.csv').open()));groups=defaultdict(list)
for r in raw:groups[r['stage'],int(r['days']),r['backend']].append(r)
summary=[]
for (stage,days,backend),rows in groups.items():
    runs=[float(r['run_usec'])/1e6 for r in rows];base=statistics.median(float(r['run_usec'])/1e6 for r in groups[stage,days,'gdscript'])
    row=dict(stage=stage,days=days,backend=backend,n=len(rows),median_seconds=statistics.median(runs),min_seconds=min(runs),max_seconds=max(runs),speedup=base/statistics.median(runs))
    for k in ('command_seconds','report_usec','load_usec','init_usec','engine_entry_usec','canonical_json_usec','history_copy_usec','envelope_json_usec','command_peak_rss_kib','run_hwm_kib'):row['median_'+k]=statistics.median(float(r[k]) for r in rows)
    summary.append(row)
write_csv(a.output/'M20_SUMMARY.csv',summary);write_csv(a.output/'M20_RUNS.csv',raw)
metrics=json.loads((a.input/'bench/measurements.json').read_text());latencies=defaultdict(list);boundaries=defaultdict(list)
for m in metrics:
    for kind in ('decisions','appointments','ticks'):
        for event in m[kind]:latencies[m['stage'],m['days'],m['backend'],kind].append(event)
    for batch in m['batches']:boundaries[m['stage'],m['days'],m['backend']].append(batch)
rows=[]
for (s,d,b,kind),events in latencies.items():
    times=sorted(e['usec']/1000 for e in events);n=len(times);worst=max(events,key=lambda e:e['usec'])
    rows.append(dict(stage=s,days=d,backend=b,kind=kind,n=n,median_ms=statistics.median(times),p95_ms=times[math.ceil(.95*n)-1] if n>=20 else '',p99_ms=times[math.ceil(.99*n)-1] if n>=100 else '',worst_ms=max(times),worst_day=worst['day'],worst_minute=worst['minute']))
write_csv(a.output/'M20_LATENCY.csv',rows)
rows=[]
for (s,d,b),batches in boundaries.items():
    rows.append(dict(stage=s,days=d,backend=b,batches=len(batches),**{'mean_'+k:statistics.mean(x[k] for x in batches) for k in ('pack_usec','compute_usec','bridge_usec','call_usec','unpack_usec','total_usec')}))
write_csv(a.output/'M20_BOUNDARY.csv',rows)
raw=list(csv.DictReader((a.input/'kernels/kernel-runs.csv').open()));write_csv(a.output/'M20_KERNEL_RUNS.csv',raw);groups=defaultdict(list)
for r in raw:groups[r['kind'],r['case'],int(r['copies']),r['backend']].append(r)
rows=[]
for (kind,case,copies,backend),values in groups.items():
    def mid(key):return statistics.median(float(r[key]) for r in values)
    base=statistics.median(float(r['compute_usec']) for r in groups['godot_batch',case,copies,'gdscript'])
    rows.append(dict(kind=kind,case=case,copies=copies,backend=backend,n=len(values),median_total_usec=mid('total_usec'),min_total_usec=min(float(r['total_usec']) for r in values),max_total_usec=max(float(r['total_usec']) for r in values),median_compute_usec=mid('compute_usec'),kernel_speedup=base/mid('compute_usec'),jobs_per_second=copies*1e6/mid('total_usec'),**{'median_'+k:mid(k) for k in ('pack_usec','call_usec','unpack_usec')}))
write_csv(a.output/'M20_KERNEL_SUMMARY.csv',rows)
# Digests are validation products, never used to replace calculations.
for case in {r['case'] for r in raw}:
    for copies in {r['copies'] for r in raw if r['case']==case}:
        digests={r['digest'] for r in raw if r['case']==case and r['copies']==copies and r['kind']=='godot_batch'}
        assert len(digests)==1,(case,copies,digests)
print('tables exported',len(summary),'whole-run groups')
