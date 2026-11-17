#!/usr/bin/env python3
"""M22 predefined isolated planning-load matrix; raw samples retained."""
import argparse,json
from pathlib import Path
from planning_load_tools import capture,host
from profile_simulation import write_csv
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);p.add_argument('--preflight',action='store_true');p.add_argument('--controls',action='store_true');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
if a.controls:
    from measure_planning_jobs import capture as world_capture,validate as world_validate
    rows=[];details=[]
    for s in 'CD':
        for mode in ('sync','scheduled'):world_validate(world_capture(s,1,mode))
    cases=[(s,d,mode) for d in (1,3,30) for s in 'CD' for mode in ('sync','scheduled')]
    for repeat in range(3):
        ordered=cases if repeat%2==0 else list(reversed(cases))
        for s,d,mode in ordered:
            if d<30 and repeat>0:continue
            data=world_capture(s,d,mode);world_validate(data);m=data['measurement'];m['repeat']=repeat+1
            if repeat==0:(a.output/f'{s}-{d}-{mode}-none.json').write_text(json.dumps(data,separators=(',',':')))
            details.append(m)
            rows.append(dict(stage=s,days=d,mode=mode,repeat=repeat+1,**{k:m[k] for k in ('run_usec','report_usec','command_seconds','peak_rss_kib','canonical_sha256')}))
            write_csv(a.output/'world-runs.csv',rows);(a.output/'world-details.json').write_text(json.dumps(details,separators=(',',':')))
            print('world',s,d,mode,repeat+1,round(m['run_usec']/1e6,5),flush=True)
    raise SystemExit(0)
cases=[(n,w,'homogeneous') for n in (1,10,100) for w in (1,2,4)]+[(100,w,'mixed') for w in (1,2,4)]+[(10,2,'ordering')]
if a.preflight:cases=[(1,4,'homogeneous'),(10,4,'mixed'),(10,2,'ordering')]
rows=[];details=[]
for repeat in range(1 if a.preflight else 5):
    ordered=cases[repeat%len(cases):]+cases[:repeat%len(cases)]
    for n,w,kind in ordered:
        if repeat>=3 and (n,w,kind)!=(100,4,'homogeneous'):continue
        data=capture(n,w,kind);data['repeat']=repeat+1;details.append(data)
        row={k:data[k] for k in ('count','workers','kind','repeat','run_usec','cleanup_usec','fixture_copy_usec','validation_usec','command_seconds','peak_rss_kib','proposal_digest','release_digest')}
        row.update({f'max_{k}':v for k,v in data['maxima'].items()});rows.append(row)
        (a.output/'details.json').write_text(json.dumps(details,separators=(',',':')));write_csv(a.output/'runs.csv',rows)
        print(kind,n,w,repeat+1,'run',round(data['run_usec']/1e6,5),'RSS',data['peak_rss_kib'],'depth',data['maxima']['outstanding'],flush=True)
(a.output/'host.json').write_text(json.dumps(host(),indent=2)+'\n')
# Both release keys and complete proposal digests must be independent of worker count/order.
for n in (1,10,100):
    for kind in ('homogeneous','mixed','ordering'):
        samples=[r for r in rows if r['count']==n and r['kind']==kind]
        if samples:
            assert len({r['proposal_digest'] for r in samples})==1
            assert len({r['release_digest'] for r in samples})==1
print('complete',len(rows),'runs',flush=True)
