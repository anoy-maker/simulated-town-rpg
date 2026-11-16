#!/usr/bin/env python3
"""Independent-process M19 measurements. No verification workload runs in run()."""
import argparse,csv,hashlib,json,os,platform,statistics,subprocess,tempfile,time
from pathlib import Path
from learning_audit import audit as learning_audit
from spatial_audit import audit as spatial_audit
from enterprise_audit import audit as enterprise_audit
ROOT=Path(__file__).resolve().parents[2]

def capture(root,stage,days,scenario,profile=False):
    env=dict(os.environ,XDG_DATA_HOME='/workspace/work/godot-data',XDG_CONFIG_HOME='/workspace/work/godot-config',XDG_CACHE_HOME='/workspace/work/cache')
    command=['godot','--headless','--no-header','--path',str(root),'--script','res://scripts/tools/profile_simulation.gd','--',stage,str(days),scenario]+(['profile'] if profile else [])
    start=time.perf_counter()
    # wait4 returns this child's actual Linux peak RSS; not the maximum of prior children.
    with tempfile.TemporaryFile() as out,tempfile.TemporaryFile() as err:
        process=subprocess.Popen(command,stdout=out,stderr=err,env=env)
        _,status,usage=os.wait4(process.pid,0)
        process.returncode=os.waitstatus_to_exitcode(status)
        command_seconds=time.perf_counter()-start
        err.seek(0);error=err.read()
        assert process.returncode==0 and not error,(command,process.returncode,error.decode())
        out.seek(0);data,trailer=map(json.loads,out.readlines())
    m=data['measurement'];m.update(trailer)
    m['command_seconds']=command_seconds;m['command_peak_rss_kib']=usage.ru_maxrss
    m['python_audit_seconds']=0.0
    m['load_average']=list(os.getloadavg())
    return data

def write_csv(path,rows):
    with path.open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=ROOT);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--label',required=True);p.add_argument('--repeats',type=int,default=3)
    p.add_argument('--audit',action='store_true');p.add_argument('--profiles-only',action='store_true')
    a=p.parse_args();assert a.repeats>=3
    a.output.mkdir(parents=True,exist_ok=True)
    pinned={(r['stage'],int(r['days'])):r for r in csv.DictReader((ROOT/'docs/M18_RUNS.csv').open())}
    cases=[(s,d,'learning') for d in (1,3,30) for s in 'ACD']+[('B',30,'learning'),('A',30,'m16'),('A',30,'m17')]
    rows=[];detailed=[];audited=set()
    def run(stage,days,scenario,repeat,profile):
        data=capture(a.root,stage,days,scenario,profile);m=data['measurement']
        if scenario=='learning':assert m['canonical_sha256']==pinned[stage,days]['summary_sha256'],(stage,days,m['canonical_sha256'])
        if a.audit and (stage,days,scenario) not in audited:
            begin=time.perf_counter()
            (learning_audit if scenario=='learning' else spatial_audit if scenario=='m17' else enterprise_audit)(data)
            m['python_audit_seconds']=time.perf_counter()-begin;audited.add((stage,days,scenario))
        detailed.append(m)
        row=dict(label=a.label,scenario=scenario,stage=stage,days=days,repeat=repeat,profiled=profile,
                 **{k:m[k] for k in ['engine_entry_usec','init_usec','run_usec','report_usec','canonical_json_usec','history_copy_usec','envelope_json_usec','event_count','command_seconds','command_peak_rss_kib','run_hwm_kib','python_audit_seconds','canonical_sha256']})
        rows.append(row)
        write_csv(a.output/'runs.csv',rows)
        (a.output/'profiles.json').write_text(json.dumps(detailed,separators=(',',':')))
        print(a.label,scenario,stage,days,'profile' if profile else repeat,'run',round(m['run_usec']/1e6,5),'report',round(m['report_usec']/1e6,5),'audit',round(m['python_audit_seconds'],3),'RSS',m['command_peak_rss_kib'],flush=True)
    # Fresh-process one-day warm-ups prime OS/code pages, never share Bayesian caches.
    if not a.profiles_only:
        for stage in 'ACD':capture(a.root,stage,1,'learning')
        for repeat in range(a.repeats):
            ordered=cases[repeat:]+cases[:repeat]
            for stage,days,scenario in ordered:
                if (stage=='B' or scenario!='learning') and repeat>0:continue
                run(stage,days,scenario,repeat+1,False)
    for stage,days,scenario in cases:run(stage,days,scenario,0,True)
    (a.output/'host.json').write_text(json.dumps(dict(platform=platform.platform(),python=platform.python_version(),cpus=os.cpu_count(),godot=subprocess.check_output(['godot','--version'],text=True,env=dict(os.environ,XDG_DATA_HOME='/workspace/work/godot-data',XDG_CONFIG_HOME='/workspace/work/godot-config',XDG_CACHE_HOME='/workspace/work/cache')).strip(),protocol='Fresh process per case, one-day A/C/D process warm-ups, rotating order; unprofiled timings and separate profiled attribution. No concurrent verification.'),indent=2))
if __name__=='__main__':main()
