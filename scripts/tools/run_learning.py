#!/usr/bin/env python3
"""Fixed M18 matrix; native trace audits, process replay, and run-only timings."""
import argparse,csv,hashlib,json,os,subprocess,time
from pathlib import Path
from learning_audit import audit

ROOT=Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,default=Path('/workspace/work/m18'))
    args=p.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    env=dict(os.environ,XDG_DATA_HOME='/workspace/work/godot-data',XDG_CONFIG_HOME='/workspace/work/godot-config',XDG_CACHE_HOME='/workspace/work/cache')
    base=['godot','--headless','--no-header','--path',str(ROOT),'--script']
    rows=[]
    for stage in 'ABCD':
        for days in (1,3,30):
            timed=base+['res://scripts/tools/benchmark_learning.gd','--',stage,str(days)]
            first=subprocess.run(timed,capture_output=True,env=env,check=True,timeout=3600)
            assert not first.stderr,first.stderr.decode()
            data=json.loads(first.stdout)
            # No verbose traces are persisted; authoritative trace is independently audited.
            audit(data)
            if stage=='A':
                pinned=next(row for row in csv.DictReader((ROOT/'docs/M17_RUNS.csv').open()) if row['case']=='control' and int(row['days'])==days)
                assert data['report']['profitable']['ledger_sha256']==pinned['ledger_sha256']
            cmd=base+['res://scripts/tools/run_simulation.gd','--','--scenario','settlement_spatial_learning','--stage',stage,str(days),'42','--report-json']
            replay=subprocess.run(cmd,capture_output=True,env=env,check=True,timeout=3600)
            assert not replay.stderr,replay.stderr.decode()
            assert data['report']==json.loads(replay.stdout)['report'],('replay',stage,days)
            if days==3:
                split=subprocess.run(timed+['split'],capture_output=True,env=env,check=True,timeout=3600)
                assert not split.stderr,split.stderr.decode()
                assert json.loads(split.stdout)['report']==data['report'],('split replay',stage)
            baseline=subprocess.run(timed+['nonspatial'],capture_output=True,env=env,check=True,timeout=180)
            assert not baseline.stderr,baseline.stderr.decode()
            non=json.loads(baseline.stdout)
            r=data['report'];op=r['open_economy'];book=r['profitable']['cash_results']['bakery']
            (args.output/f'{stage}-{days}-summary.json').write_bytes(replay.stdout)
            row=dict(stage=stage,days=days,seed=42,meals=op['resident_meals'],missed=sum(r['unmet_meals'].values()),visitors=op['visitor_bread'],paid_shifts=r['shifts']['paid'],breaches=r['profitable']['contracts']['breaches'],
                     bakery_sales=book['sales'],bakery_inputs=book['inputs'],bakery_payroll=book['payroll'],bakery_distributions=book['distributions'],bakery_cash=r['final']['entities']['bakery']['money'],bread_produced=r['totals']['production_outputs']['bread'],bread_stock=r['final']['entities']['bakery']['inventory']['bread'],
                     circulation=r['money']['circulation'],village_money=op['village_money'],external_money=op['external_money'],combined_money=r['money']['final'],prices='/'.join(str(d['proposal']['selected_price']) for d in r['learning']['decisions']),
                     simulation_seconds=data['simulation_seconds'],nonspatial_seconds=non['simulation_seconds'],summary_sha256=hashlib.sha256(replay.stdout).hexdigest(),ledger_sha256=r['profitable']['ledger_sha256'])
            rows.append(row)
            with (args.output/'runs.csv').open('w') as f:
                writer=csv.DictWriter(f,fieldnames=list(row),lineterminator="\n");writer.writeheader();writer.writerows(rows)
            print(stage,days,'audited/replayed',row,flush=True)
if __name__=='__main__':main()
