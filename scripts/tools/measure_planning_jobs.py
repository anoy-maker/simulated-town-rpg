#!/usr/bin/env python3
"""M21 isolated frame-pump controls, fixtures and acceptance. No benchmark concurrency."""
import argparse,csv,json,os,subprocess,tempfile,time,statistics,math
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor
from profile_simulation import ROOT,godot_environment,write_csv
from learning_audit import audit
with (ROOT/'docs/M18_RUNS.csv').open() as f:PINS={(r['stage'],int(r['days'])):r for r in csv.DictReader(f)}
def capture(stage,days,mode,delay=0,fixture='none'):
    cmd=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_planning_jobs.gd','--',stage,str(days),mode,str(delay),fixture]
    begin=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(cmd,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-begin;err.seek(0);error=err.read();assert child.returncode==0 and not error,(cmd,child.returncode,error.decode())
        out.seek(0);data,trailer=map(json.loads,out.readlines())
    data['measurement'].update(trailer,command_seconds=elapsed,peak_rss_kib=usage.ru_maxrss)
    return data

def validate(data):
    m=data['measurement'];r=data['report'];stage=m['stage'];days=m['days']
    if m['fixture']=='none':
        assert m['canonical_sha256']==PINS[stage,days]['summary_sha256']
        assert r['profitable']['ledger_sha256']==PINS[stage,days]['ledger_sha256']
        assert all(j['status']=='committed' and j['minute']==745 for j in m['jobs'])
        assert len(m['jobs'])==(days if m['mode']=='scheduled' else 0)
    assert r['money']['final']==9192
    for job in m['jobs']:
        if 'worker_thread_id' in job:assert job['worker_thread_id']!=m['main_thread_id']
    if m['fixture']!='none':
        assert len(m['jobs'])==2 and m['jobs'][0]['status']==('canceled' if m['fixture']=='cancel' else 'stale')
        assert m['jobs'][1]['status']=='committed' and m['jobs'][1]['id']>m['jobs'][0]['id']
        assert m['fixture_evidence']['minute']==745 and m['fixture_evidence']['decisions_before']==0
        if m['fixture'] in ('cancel','inventory'):assert m['canonical_sha256']==PINS[stage,days]['summary_sha256']
    return True

def audit_case(task):
    file=task;data=json.loads(file.read_text());validate(data);start=time.perf_counter();audit(data)
    return dict(case=file.stem,audit_seconds=time.perf_counter()-start,summary_sha256=data['measurement']['canonical_sha256'],ledger_sha256=data['report']['profitable']['ledger_sha256'])

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--phase',choices=['preflight','benchmark','audit','direct'],required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    if a.phase=='direct':
        from compare_native_math import capture as direct_capture
        rows=[]
        for stage in 'CD':direct_capture(stage,1,'rust')
        for repeat in range(3):
            for stage in ('CD' if repeat%2==0 else 'DC'):
                data=direct_capture(stage,30,'rust');m=data['measurement'];assert m['canonical_sha256']==PINS[stage,30]['summary_sha256']
                rows.append(dict(stage=stage,repeat=repeat+1,**{k:m[k] for k in ('run_usec','report_usec','command_seconds','command_peak_rss_kib','canonical_sha256')}))
                write_csv(a.output/'direct.csv',rows);print('direct',stage,repeat+1,m['run_usec']/1e6,flush=True)
        return
    if a.phase=='audit':
        files=[a.output/f'{s}-{d}-{mode}-none.json' for s in 'CD' for d in (1,3,30) for mode in ('sync','scheduled')]
        rows=[]
        with ProcessPoolExecutor(max_workers=2) as pool:
            for row in pool.map(audit_case,files):
                rows.append(row);write_csv(a.output/'audits.csv',rows);print('audited',row['case'],flush=True)
        return
    cases=[(s,d,mode,0,'none') for s in 'CD' for d in ((1,3) if a.phase=='preflight' else (1,3,30)) for mode in ('sync','scheduled')]
    cases+= [('D',1,'scheduled',500,'none')]+[('D',1,'scheduled',100,f) for f in ('funds','inventory','quote','supplier','beliefs','presence','cancel')]
    rows=[];details=[];repeats=1 if a.phase=='preflight' else 5
    if a.phase=='benchmark':
        for s in 'CD':
            for mode in ('sync','scheduled'):validate(capture(s,1,mode))
    for repeat in range(repeats):
        ordered=cases if repeat%2==0 else [cases[i^1] for i in range(12)]+cases[12:]
        for s,d,mode,delay,fixture in ordered:
            if repeat>=3 and not (s=="D" and d==30 and delay==0 and fixture=="none"):continue
            data=capture(s,d,mode,delay,fixture);validate(data);m=data['measurement'];m['repeat']=repeat+1
            name=f'{s}-{d}-{mode}-{fixture}'+('-delay' if delay==500 else '')
            if repeat==0:(a.output/(name+'.json')).write_text(json.dumps(data,separators=(',',':')))
            details.append(m);row={k:m[k] for k in ('stage','days','mode','fixture','repeat','run_usec','report_usec','shutdown_usec','load_usec','serialize_usec','command_seconds','peak_rss_kib','canonical_sha256','barrier_heartbeats')};row['delay_ms']=delay;rows.append(row)
            write_csv(a.output/'runs.csv',rows);(a.output/'measurements.json').write_text(json.dumps(details,separators=(',',':')))
            print(name,repeat+1,'run',round(m['run_usec']/1e6,4),'callbacks',len(m['callbacks']),'barrier frames',m['barrier_heartbeats'],flush=True)
    print('complete',len(rows),'runs',flush=True)
if __name__=='__main__':main()
