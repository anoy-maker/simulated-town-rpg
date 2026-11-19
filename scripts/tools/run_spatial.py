#!/usr/bin/env python3
"""Run M17's predeclared controls/disruptions with independent replay and audits."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
from spatial_audit import audit


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',default='godot')
    parser.add_argument('--output',type=Path,default=Path('work/m17'))
    args=parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    root=Path(__file__).resolve().parents[2]
    env=dict(os.environ,XDG_DATA_HOME=str(args.output.resolve()/'data'),XDG_CONFIG_HOME=str(args.output.resolve()/'config'),XDG_CACHE_HOME=str(args.output.resolve()/'cache'))
    cli=[args.godot,'--headless','--no-header','--path',str(root),'--script','res://scripts/tools/run_simulation.gd','--']
    published15={int(row['days']):row['summary_sha256'] for row in csv.DictReader((root/'docs/M15_RUNS.csv').open()) if row['experiment']=='A'}
    published16={int(row['days']):row['summary_sha256'] for row in csv.DictReader((root/'docs/M16_RUNS.csv').open()) if row['stage']=='A'}
    runs,days_table,residents,businesses=[],[],[],[]
    for case,horizon in [('control',1),('control',3),('control',30),('late_worker',1),('early_close',1)]:
        command=cli+['--scenario','settlement_spatial','--spatial-case',case,str(horizon),'42']
        first=subprocess.run(command+['--report-json'],env=env,capture_output=True,check=True,timeout=180)
        replay=subprocess.run(command+['--report-json'],env=env,capture_output=True,check=True,timeout=180)
        assert not first.stderr and not replay.stderr,(first.stderr,replay.stderr)
        assert first.stdout==replay.stdout,(case,horizon,'process replay mismatch')
        data=json.loads(first.stdout)
        assert 'events' not in data and len(first.stdout)<256000
        r=data['report']
        v=r['profitable']['verification']
        assert all(all(v[group].values()) for group in ('accounting','spatial')),v
        assert v['days_checked']==horizon and r['money']['final']==9192
        traced=subprocess.run(command+['--json'],env=env,capture_output=True,check=True,timeout=180)
        assert not traced.stderr,traced.stderr
        trace=json.loads(traced.stdout)
        audit(trace)  # All five full traces are audited in memory, never saved.
        assert trace['report']==r
        if case=='control':
            for scenario,extra,pinned in [('settlement_external_trade_reference',[],published15),('settlement_pricing',['--stage','A'],published16)]:
                baseline=subprocess.run(cli+['--scenario',scenario]+extra+[str(horizon),'42','--report-json'],env=env,capture_output=True,check=True,timeout=180)
                assert not baseline.stderr,baseline.stderr
                assert hashlib.sha256(baseline.stdout).hexdigest()==pinned[horizon]
                control=json.loads(baseline.stdout)['report']
                for key in ('accounts','totals','money','shifts','purchases','unmet_meals','business_activity'):
                    assert r[key]==control[key],(horizon,scenario,key)
                for key in ('contracts','cash_results','distributions'):
                    assert r['profitable'][key]==control['profitable'][key],(horizon,scenario,key)
            assert r['open_economy']['resident_meals']==12*horizon and r['open_economy']['visitor_bread']==6*horizon
        digest=hashlib.sha256(first.stdout).hexdigest()
        (args.output/f'{case}-{horizon}-summary.json').write_bytes(first.stdout)
        op=r['open_economy']
        runs.append(dict(case=case,days=horizon,seed=42,resident_meals=op['resident_meals'],missed_meals=sum(r['unmet_meals'].values()),visitor_loaves=op['visitor_bread'],
                         paid_shifts=r['shifts']['paid'],wages=r['shifts']['wages'],distributions=r['profitable']['distributions']['amount'],breaches=r['profitable']['contracts']['breaches'],
                         wheat=r['totals']['harvested']['wheat'],flour=r['totals']['production_outputs']['flour'],bread=r['totals']['production_outputs']['bread'],
                         village_money=op['village_money'],external_money=op['external_money'],combined_money=r['money']['final'],
                         steps=sum(d['steps'] for d in r['spatial']['days']),visitor_entries=sum(d['visitor_entries'] for d in r['spatial']['days']),visitor_exits=sum(d['visitor_exits'] for d in r['spatial']['days']),
                         cargo_purchased=sum(d['cargo_purchased'] for d in r['spatial']['days']),cargo_deposited=sum(d['cargo_deposited'] for d in r['spatial']['days']),
                         successful_purchases=r['purchases']['successful'],rejected_purchases=r['purchases']['rejected'],circulation=r['money']['circulation'],events=r['event_count'],
                         summary_sha256=digest,ledger_sha256=r['profitable']['ledger_sha256']))
        if case!='control' or horizon==30:
            for d in r['spatial']['days']:
                row=dict(case=case,**d)
                for key in ('household_cash','business_cash','external_cash'): row[key]=json.dumps(row[key],sort_keys=True,separators=(',',':'))
                days_table.append(row)
            for actor,p in sorted(r['spatial']['residents'].items()):
                a=r['accounts'][actor]
                row=dict(case=case,days=horizon,**p)
                row.update(coins=r['final']['entities'][actor]['money'],wages=a['wages_received'],ownership_income=a['profit_distributions_received'],food_spending=a['purchases'],missed_meals=r['unmet_meals'][actor])
                for key in ('home','tile'): row[key]=json.dumps(row[key],separators=(',',':'))
                residents.append(row)
            for business in ('farm','mill','bakery'):
                e=r['final']['entities'][business]
                book=r['profitable']['cash_results'][business]
                businesses.append(dict(case=case,days=horizon,business=business,coins=e['money'],**e['inventory'],**book,paid_shifts=r['accounts'][business]['shifts']))
        print(case,horizon,'meals/missed',op['resident_meals'],sum(r['unmet_meals'].values()),'visitors',op['visitor_bread'],'shifts',r['shifts']['paid'],
              'breaches',r['profitable']['contracts']['breaches'],'audited/replayed',flush=True)
    for name,rows in [('runs',runs),('days',days_table),('residents',residents),('businesses',businesses)]:
        with (args.output/(name+'.csv')).open('w',newline='') as handle:
            writer=csv.DictWriter(handle,fieldnames=list(rows[0]),lineterminator='\n')
            writer.writeheader()
            writer.writerows(rows)


if __name__=='__main__': main()
