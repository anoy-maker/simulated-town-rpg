#!/usr/bin/env python3
"""M21 bounded tables. Quantiles are nearest-rank, p95 n>=20/p99 n>=100."""
import argparse,csv,json,math,statistics,shutil
from collections import defaultdict
from pathlib import Path
from profile_simulation import write_csv
p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
raw=list(csv.DictReader((a.input/'runs.csv').open()));metrics=json.loads((a.input/'measurements.json').read_text());assert len(raw)==len(metrics)
groups=defaultdict(list);latencies=defaultdict(list);fixtures=[];prep=[]
for row,m in zip(raw,metrics):
    key=(m['stage'],m['days'],m['mode'],m['fixture'],int(row['delay_ms']));groups[key].append(row)
    for kind,events in [('callback',m['callbacks']),('barrier_callback',[x for x in m['callbacks'] if x['barrier']]),('heartbeat_gap',[{'usec':x,'day':'','minute':''} for x in m['heartbeat_gaps_usec']])]:
        latencies[key+(kind,)].extend(events)
    day_jobs=defaultdict(list)
    for j in m['jobs']:
        day_jobs[j['day']].append(j)
        for kind,field in [('compute','compute_usec'),('worker_wall','worker_wall_usec'),('queue','queue_usec'),('poll_delay','poll_delay_usec'),('barrier','barrier_usec'),('commit_work','commit_work_usec'),('quote_commit_latency','commit_latency_usec')]:
            if field in j:latencies[key+(kind,)].append(dict(usec=j[field],day=j['day'],minute=j['minute']))
    if m['mode']=='sync':
        latencies[key+('compute',)].extend(m['decisions'])
        latencies[key+('appointment',)].extend(x for x in m['appointments'] if x['minute']==745)
    else:
        for appointment in [x for x in m['appointments'] if x['minute']==745]:
            jobs=day_jobs[appointment['day']];first,last=jobs[0],jobs[-1]
            # Reconstruct elapsed appointment with a few microseconds of callback bookkeeping.
            elapsed=last['submitted_usec']+last['commit_latency_usec']-first['submitted_usec']+appointment['usec']-first['submit_usec']
            latencies[key+('appointment',)].append(dict(usec=elapsed,day=appointment['day'],minute=745))
    if m['fixture']!='none':
        fixtures.append(dict(fixture=m['fixture'],repeat=m['repeat'],statuses=';'.join(j['status'] for j in m['jobs']),ids=';'.join(str(j['id']) for j in m['jobs']),day=m['fixture_evidence']['day'],minute=m['fixture_evidence']['minute'],decisions_before=m['fixture_evidence']['decisions_before'],quote_success=json.loads((a.input/f"D-1-scheduled-{m['fixture']}.json").read_text())['report']['learning']['decisions'][0]['success'],barrier_heartbeats=m['barrier_heartbeats']))
    if m['fixture']=='none' and int(row['delay_ms'])==0 and m['mode']=='scheduled':
        for e in m['preparations']:
            prep.append(dict(stage=m['stage'],days=m['days'],repeat=m['repeat'],day=e['day'],minute=e['minute'],same_beliefs=e['same_beliefs_at_commit'],earlier_cash=e['own_state'][0],later_cash=e['at_commit_own_state'][0],earlier_flour=e['own_state'][1],later_flour=e['at_commit_own_state'][1],carry_known_early=e['carry_known_here'],observed_carry_at_commit=e['carry_at_commit'],proposal_prepared=e['full_proposal_prepared']))
rows=[]
for key,values in groups.items():
    times=[float(r['run_usec'])/1e6 for r in values]
    rows.append(dict(zip(('stage','days','mode','fixture','delay_ms'),key),n=len(values),median_run_seconds=statistics.median(times),min_run_seconds=min(times),max_run_seconds=max(times),**{'median_'+k:statistics.median(float(r[k]) for r in values) for k in ('command_seconds','report_usec','load_usec','shutdown_usec','serialize_usec','peak_rss_kib','barrier_heartbeats')}))
write_csv(a.output/'M21_SUMMARY.csv',rows);write_csv(a.output/'M21_RUNS.csv',raw)
rows=[]
for key,events in latencies.items():
    if not events:continue
    times=sorted(e['usec']/1000 for e in events);n=len(times);worst=max(events,key=lambda e:e['usec'])
    rows.append(dict(zip(('stage','days','mode','fixture','delay_ms','kind'),key),n=n,min_ms=min(times),median_ms=statistics.median(times),p95_ms=times[math.ceil(.95*n)-1] if n>=20 else '',p99_ms=times[math.ceil(.99*n)-1] if n>=100 else '',worst_ms=max(times),worst_day=worst['day'],worst_minute=worst['minute']))
write_csv(a.output/'M21_LATENCY.csv',rows);write_csv(a.output/'M21_FIXTURES.csv',fixtures)
# Aggregate preparation coverage instead of publishing redundant daily rows.
keys=sorted({(r['stage'],r['days']) for r in prep});rows=[]
for s,d in keys:
    values=[x for x in prep if (x['stage'],x['days'])==(s,d)]
    rows.append(dict(stage=s,days=d,samples=len(values),same_beliefs=sum(x['same_beliefs'] for x in values),changed_flour=sum(x['earlier_flour']!=x['later_flour'] for x in values),carry_known_early=sum(x['carry_known_early'] for x in values),carry_at_commit=','.join(str(v) for v in sorted({x['observed_carry_at_commit'] for x in values})),early_proposals=sum(x['proposal_prepared'] for x in values)))
write_csv(a.output/'M21_PREPARATION.csv',rows)
for name,target in [('direct.csv','M21_DIRECT.csv'),('audits.csv','M21_AUDITS.csv')]:
    if (a.input/name).exists():shutil.copy2(a.input/name,a.output/target)
print('exported',len(raw),'runs',len(latencies),'latency groups')
