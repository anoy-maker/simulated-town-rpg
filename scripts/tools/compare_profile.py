#!/usr/bin/env python3
"""Three alternating fresh-process comparisons of short scenarios and pure continuation."""
import argparse,csv,json,os,subprocess
from pathlib import Path
from profile_simulation import capture,write_csv,ROOT,godot_environment

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--reference',type=Path,required=True);p.add_argument('--candidate',type=Path,default=ROOT)
    p.add_argument('--fixture',type=Path,required=True,help='Canonical M18 D30 --report-json capture')
    p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    roots={'before':a.reference.resolve(),'after':a.candidate.resolve()};rows=[]
    with (ROOT/'docs/M18_RUNS.csv').open() as stream:
        pinned={(r['stage'],int(r['days'])):r['summary_sha256'] for r in csv.DictReader(stream)}
    for stage in 'AD':
        for label in roots:capture(roots[label],stage,1,'learning')
        for repeat in range(1,4):
            for label in (['before','after'] if repeat%2 else ['after','before']):
                m=capture(roots[label],stage,3,'learning')['measurement']
                assert m['canonical_sha256']==pinned[stage,3]
                rows.append(dict(label=label,stage=stage,days=3,repeat=repeat,run_usec=m['run_usec'],report_usec=m['report_usec'],command_seconds=m['command_seconds'],canonical_sha256=m['canonical_sha256']))
    write_csv(a.output/'paired-short.csv',rows)
    rows=[];expected=None;input_sha=None
    env=godot_environment()
    for repeat in range(1,4):
        for label in (['before','after'] if repeat%2 else ['after','before']):
            r=subprocess.run(['godot','--headless','--no-header','--path',str(roots[label]),'--script',str(a.candidate.resolve()/'scripts/tools/benchmark_continuation.gd'),'--',str(a.fixture.resolve())],capture_output=True,env=env,check=True,timeout=120)
            assert not r.stderr,r.stderr.decode()
            data=json.loads(r.stdout)
            if expected is None:expected=data['values'];input_sha=data['input_sha256']
            assert data['values']==expected and data['input_sha256']==input_sha
            rows.append(dict(label=label,repeat=repeat,tasks=data['tasks'],continuation_usec=data['continuation_usec'],input_sha256=input_sha))
    write_csv(a.output/'micro.csv',rows)
if __name__=='__main__':main()
