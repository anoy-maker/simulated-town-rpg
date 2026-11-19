#!/usr/bin/env python3
"""Replay published M0–M18 payload pins, without relying on local old captures."""
import argparse,csv,hashlib,json,os,re,subprocess
from pathlib import Path
from profile_simulation import godot_environment
ROOT=Path(__file__).resolve().parents[2]

def cases():
    result=[]
    def add(milestone,name,args,sha):result.append((milestone,name,list(map(str,args)),sha))
    text=(ROOT/'docs/M6B_RESULTS.md').read_text()
    levels={'m0':0,'trading':2,'agents':3,'coordination':4,'planning':5}
    for name,sha in re.findall(r'^\| ([a-z0-9-]+) \| ([0-9a-f]{64}) \|$',text,re.M):
        if name.startswith('market-'):continue
        scenario,rest=name.split('-',1);priority,days=rest.rsplit('-',1)
        add(levels[scenario],name,['--scenario',scenario]+(['--priority',priority] if priority else [])+[days,42,'--json'],sha)
    for seed,days,sha in re.findall(r'^\| (7|42|99) \| (30|365) \| \d+ \| ([0-9a-f]{64}) \|$',text,re.M):
        add(6,f'market_downstream-{seed}-{days}',['--scenario','market_downstream',days,seed,'--json'],sha)
    for name,sha in re.findall(r'^\| (market-[0-9]+-[0-9]+) \| ([0-9a-f]{64}) \|$',text,re.M):
        _,seed,days=name.split('-');add(6,name,['--scenario','market',days,seed,'--json'],sha)
    def rows(m):
        with (ROOT/f'docs/M{m}_RUNS.csv').open() as stream:return list(csv.DictReader(stream))
    for m in (7,8):
        for r in rows(m):
            if m==8 and r['experiment']!='combined_candidate':continue
            add(m,f"{r['experiment']}-{r['seed']}-{r['days']}",['--scenario','calibration','--experiment',r['experiment'],r['days'],r['seed'],'--json'],r['sha256'])
    for m,scenario in [(9,'settlement_labor'),(10,'settlement_finance')]:
        for r in rows(m):
            extra=['--distribution',r['distribution']] if m==10 else []
            add(m,f"{scenario}-{'/'.join(extra)}-{r['seed']}-{r['days']}",['--scenario',scenario]+extra+[r['days'],r['seed'],'--json'],r['sha256'])
    for r in rows(11):add(11,'reference-'+r['days'],['--scenario','settlement_equilibrium_reference',r['days'],r['seed'],'--report-json'],r['summary_sha256'])
    for r in rows(12):
        if r['scenario']=='settlement_employer_choice':add(12,'employer-'+r['days'],['--scenario',r['scenario'],r['days'],42,'--report-json'],r['summary_sha256'])
    for r in rows(13):
        for flag,field in [('--study-json','study_sha256'),('--report-json','summary_sha256')]:add(13,f"{r['scenario']}-{r['days']}-{flag}",['--scenario',r['scenario'],r['days'],42,flag],r[field])
    for r in rows(14):add(14,'reference-'+r['days'],['--scenario','settlement_profitable_reference',r['days'],42,'--report-json'],r['summary_sha256'])
    for r in rows(15):add(15,f"{r['scenario']}-{r['days']}",['--scenario',r['scenario'],r['days'],42,'--report-json'],r['summary_sha256'])
    for r in rows(16):add(16,r['stage']+'-'+r['days'],['--scenario','settlement_pricing','--stage',r['stage'],r['days'],42,'--report-json'],r['summary_sha256'])
    add(16,'competition-full-trace',['--scenario','pricing_competition_fixture',1,42,'--json'],'343e25cb82af654d027c30306e1cef966391020c87c56845e9072208dfec17eb')
    for r in rows(17):add(17,r['case']+'-'+r['days'],['--scenario','settlement_spatial','--spatial-case',r['case'],r['days'],42,'--report-json'],r['summary_sha256'])
    for r in rows(18):add(18,r['stage']+'-'+r['days'],['--scenario','settlement_spatial_learning','--stage',r['stage'],r['days'],42,'--report-json'],r['summary_sha256'])
    assert len(result)==169,len(result)
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--through',type=int,default=18,choices=range(19));p.add_argument('--list',action='store_true')
    p.add_argument('--output',type=Path,default=Path('work/m19/historical.csv'));a=p.parse_args()
    selected=[r for r in cases() if r[0]<=a.through]
    if a.list:
        print(json.dumps(selected));return
    a.output.parent.mkdir(parents=True,exist_ok=True)
    env=godot_environment()
    cli=['godot','--headless','--no-header','--path',str(ROOT),'--script','res://scripts/tools/run_simulation.gd','--']
    with a.output.open('w') as f:
        w=csv.DictWriter(f,fieldnames=['milestone','case','arguments','expected_sha256','actual_sha256'],lineterminator='\n');w.writeheader()
        for i,(m,name,args,expected) in enumerate(selected,1):
            r=subprocess.run(cli+args,capture_output=True,env=env,check=True,timeout=180)
            assert not r.stderr,r.stderr.decode()
            actual=hashlib.sha256(r.stdout).hexdigest();assert actual==expected,(m,name,actual,expected)
            w.writerow(dict(milestone=m,case=name,arguments=json.dumps(args,separators=(',',':')),expected_sha256=expected,actual_sha256=actual));f.flush()
            print('UNCHANGED',i,'/',len(selected),'M'+str(m),name,actual,flush=True)
if __name__=='__main__':main()
