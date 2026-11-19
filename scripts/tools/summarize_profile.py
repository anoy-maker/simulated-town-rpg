#!/usr/bin/env python3
"""Export bounded M19 tables; keep raw timing/profiling traces in work/."""
import argparse,csv,json,statistics
from pathlib import Path

def write(path,rows):
    with path.open('w') as stream:
        w=csv.DictWriter(stream,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)

def read_csv(path):
    with path.open() as stream:return list(csv.DictReader(stream))

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    a.output.mkdir(parents=True,exist_ok=True)
    loaded={label:json.loads((a.input/label/'profiles.json').read_text()) for label in ('before','after')}
    raw=[]
    for label in ('before','after-initial','after'):
        if not (a.input/label/'runs.csv').exists():continue
        for row,detail in zip(read_csv(a.input/label/'runs.csv'),json.loads((a.input/label/'profiles.json').read_text())):
            row['label']=label
            row.update(load1=detail['load_average'][0],load5=detail['load_average'][1],load15=detail['load_average'][2])
            raw.append(row)
    write(a.output/'M19_BENCHMARKS.csv',raw)
    summary=[]
    keys=sorted({(x['scenario'],x['stage'],x['days']) for x in loaded['before']})
    for scenario,stage,days in keys:
        row=dict(scenario=scenario,stage=stage,days=days)
        for label in ('before','after'):
            group=[r for r in loaded[label] if not r['profiled'] and (r['scenario'],r['stage'],r['days'])==(scenario,stage,days)]
            values=[x['run_usec']/1e6 for x in group]
            row.update({label+'_n':len(group),label+'_median_seconds':statistics.median(values),label+'_min_seconds':min(values),label+'_max_seconds':max(values),
                        label+'_command_median_seconds':statistics.median(x['command_seconds'] for x in group),
                        label+'_run_hwm_median_kib':statistics.median(x['run_hwm_kib'] for x in group),
                        label+'_command_peak_median_kib':statistics.median(x['command_peak_rss_kib'] for x in group)})
        row['run_change_percent']=100*(row['after_median_seconds']/row['before_median_seconds']-1)
        summary.append(row)
    write(a.output/'M19_SUMMARY.csv',summary)
    phases=[];decisions=[];work=[]
    for label,data in loaded.items():
        for r in data:
            if not r['profiled']:continue
            for phase,timing in r['run_profile']['phases'].items():
                phases.append(dict(label=label,scenario=r['scenario'],stage=r['stage'],days=r['days'],phase=phase,**timing,exclusive_percent=100*timing['exclusive_usec']/r['run_usec']))
            if r['scenario']!='learning' or r['days']!=30 or r['stage'] not in 'ACD':continue
            counts=r['run_profile']['counts']
            work.append(dict(label=label,stage=r['stage'],events=r['event_count'],candidates=counts.get('candidates',0),branches=counts.get('observable_branches',0),continuation_calls=counts.get('continuation_calls',0),
                             forecast_prices=counts.get('forecast_prices',0),beta_table_misses=counts.get('beta_table_misses',0),traffic_component_misses=counts.get('traffic_component_misses',0),
                             full_mean_hits=counts.get('full_mean_hits',''),full_mean_misses=counts.get('full_mean_misses',''),stock_limited_means=counts.get('stock_limited_means','')))
            for d in r['run_profile']['decisions']:
                if d['day'] not in (1,3,4,15,16,30):continue
                c=d['counts'];ph=d['phases']
                decisions.append(dict(label=label,stage=r['stage'],day=d['day'],memory_days=d['memory_days'],elapsed_usec=d['elapsed_usec'],
                                      candidates=c.get('candidates',0),branches=c.get('observable_branches',0),continuations=c.get('continuation_calls',0),forecast_prices=c.get('forecast_prices',0),
                                      beta_misses=c.get('beta_table_misses',0),traffic_misses=c.get('traffic_component_misses',0),
                                      continuation_usec=ph.get('continuation',{}).get('exclusive_usec',0),forecast_mixture_usec=ph.get('forecast_mixture',{}).get('exclusive_usec',0)))
    for name,rows in [('M19_PHASES.csv',phases),('M19_DECISIONS.csv',decisions),('M19_WORK.csv',work)]:write(a.output/name,rows)
    if (a.input/'micro.csv').exists():write(a.output/'M19_CONTINUATION.csv',read_csv(a.input/'micro.csv'))
    if (a.input/'paired-short.csv').exists():write(a.output/'M19_PAIRED.csv',read_csv(a.input/'paired-short.csv'))
    for row in summary:
        if row['scenario']=='learning':print(row['stage'],row['days'],'before/after',row['before_median_seconds'],row['after_median_seconds'],'change',row['run_change_percent'])
if __name__=='__main__':main()
