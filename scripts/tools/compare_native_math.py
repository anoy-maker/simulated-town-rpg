#!/usr/bin/env python3
"""M20 fresh-process measurements and independent acceptance (separate phases)."""
import argparse,csv,hashlib,json,os,statistics,subprocess,tempfile,time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor
from profile_simulation import godot_environment,write_csv
from learning_audit import audit
ROOT=Path(__file__).resolve().parents[2]
BACKENDS=['gdscript','cpp','rust']
with (ROOT/'docs/M18_RUNS.csv').open() as stream:
    PINNED={(r['stage'],int(r['days'])):r for r in csv.DictReader(stream)}
NUMERIC={'ordinary','informed','evsi','unadapted_value','adaptive_value'}
def parity(reference,actual,path=''):
    """Only explicitly identified projected values may differ by absolute 1e-9."""
    if isinstance(reference,dict):
        assert reference.keys()==actual.keys(),path
        for k,v in reference.items():
            if k in NUMERIC and '.proposal.' in path:
                assert abs(v-actual[k])<=1e-9,(path,k,v,actual[k])
            else:parity(v,actual[k],path+'.'+k)
    elif isinstance(reference,list):
        assert len(reference)==len(actual),path
        for i,(a,b) in enumerate(zip(reference,actual)):parity(a,b,path+f'.{i}')
    else:assert reference==actual,(path,reference,actual)
def capture(stage,days,backend):
    cmd=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/benchmark_native.gd','--',stage,str(days),backend]
    begin=time.perf_counter()
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        child=subprocess.Popen(cmd,stdout=out,stderr=err,env=godot_environment());_,status,usage=os.wait4(child.pid,0);child.returncode=os.waitstatus_to_exitcode(status)
        elapsed=time.perf_counter()-begin;err.seek(0);error=err.read();assert child.returncode==0 and not error,(cmd,child.returncode,error.decode())
        out.seek(0);data,trailer=map(json.loads,out.readlines())
    m=data['measurement'];m.update(trailer,command_seconds=elapsed,command_peak_rss_kib=usage.ru_maxrss)
    return data

def check(data,reference=None):
    m=data['measurement'];pin=PINNED[m['stage'],m['days']]
    assert data['report']['profitable']['ledger_sha256']==pin['ledger_sha256']
    if m['backend']=='gdscript':assert m['canonical_sha256']==pin['summary_sha256']
    if reference is not None:
        assert data['events']==reference['events']
        parity(reference['report'],data['report'])

def audit_case(task):
    folder,s,d,b=task
    reference=json.loads((folder/f'{s}-{d}-gdscript.json').read_text())
    data=json.loads((folder/f'{s}-{d}-{b}.json').read_text());check(data,reference)
    start=time.perf_counter();audit(data)
    return dict(stage=s,days=d,backend=b,summary_sha256=data['measurement']['canonical_sha256'],ledger_sha256=data['report']['profitable']['ledger_sha256'],independent_audit_seconds=time.perf_counter()-start)

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--audit-jobs',type=int,default=2);p.add_argument('--phase',choices=['preflight','benchmark','audit'],required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    rows=[];metrics=[]
    if a.phase=='audit':
        tasks=[(a.output,s,d,b) for s,d in [(s,d) for s in 'CD' for d in (1,3,30)]+[('A',30)] for b in BACKENDS]
        assert 1<=a.audit_jobs<=2
        # Verification only, after all performance runs. Each case is independently rebuilt.
        with ProcessPoolExecutor(max_workers=a.audit_jobs) as pool:
            for row in pool.map(audit_case,tasks):
                rows.append(row);write_csv(a.output/'audits.csv',rows)
                print('audited',row['stage'],row['days'],row['backend'],flush=True)
        return
    cases=[(s,d) for d in (1,3) for s in 'CD'] if a.phase=='preflight' else [(s,d) for d in (1,3,30) for s in 'CD']+[('A',30)]
    # Code pages warm; each measured process still starts with cold model caches.
    if a.phase=='benchmark':
        for b in BACKENDS:
            for s in 'ACD':check(capture(s,1,b))
    maximum=1 if a.phase=='preflight' else 5
    for repeat in range(maximum):
        for s,d in cases:
            if repeat>=(5 if (s,d)==('D',30) else 3) and a.phase=='benchmark':continue
            order=BACKENDS[(repeat+cases.index((s,d)))%3:]+BACKENDS[:(repeat+cases.index((s,d)))%3]
            reference=None
            trio=[]
            for b in order:
                data=capture(s,d,b);m=data['measurement'];check(data);trio.append(data)
                path=a.output/f'{s}-{d}-{b}.json'
                if repeat==0:path.write_text(json.dumps(data,separators=(',',':')))
                # Check all repeated projection fields against first GDScript capture after each trio.
                metrics.append(m)
                row={k:m[k] for k in ['stage','days','backend','run_usec','init_usec','load_usec','engine_entry_usec','report_usec','canonical_json_usec','history_copy_usec','envelope_json_usec','command_seconds','command_peak_rss_kib','run_hwm_kib','canonical_sha256']};row['repeat']=repeat+1;rows.append(row)
                write_csv(a.output/'runs.csv',rows);(a.output/'measurements.json').write_text(json.dumps(metrics,separators=(',',':')))
                print(s,d,b,repeat+1,'run',m['run_usec']/1e6,'command',round(m['command_seconds'],4),flush=True)
            reference=json.loads((a.output/f'{s}-{d}-gdscript.json').read_text())
            for data in trio:check(data,reference)
    print('complete',len(rows),'runs',flush=True)
if __name__=='__main__':main()
