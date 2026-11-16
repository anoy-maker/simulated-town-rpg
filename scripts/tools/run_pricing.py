#!/usr/bin/env python3
"""M16's fixed, predeclared staged runs; no annual verbose event files."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
from enterprise_audit import audit


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--output', type=Path, default=Path('work/m16'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    root = Path(__file__).resolve().parents[2]
    env = dict(os.environ, XDG_DATA_HOME=str(args.output.resolve()/'data'), XDG_CONFIG_HOME=str(args.output.resolve()/'config'), XDG_CACHE_HOME=str(args.output.resolve()/'cache'))
    cli = [args.godot, '--headless', '--no-header', '--path', str(root), '--script', 'res://scripts/tools/run_simulation.gd', '--']
    runs, firms, daily, accounts = [], [], [], []
    for stage in 'ABCD':
        for days in (1, 3, 30):
            command = cli + ['--scenario', 'settlement_pricing', '--stage', stage, str(days), '42']
            first = subprocess.run(command+['--report-json'], env=env, capture_output=True, check=True, timeout=90)
            replay = subprocess.run(command+['--report-json'], env=env, capture_output=True, check=True, timeout=90)
            assert not first.stderr and not replay.stderr, (first.stderr, replay.stderr)
            assert first.stdout == replay.stdout, (stage, days, 'process replay mismatch')
            r = json.loads(first.stdout)['report']
            flags = r['profitable']['verification']
            assert all(all(flags[k].values()) for k in ('accounting', 'pricing')), flags
            assert flags['days_checked'] == days and r['pricing']['report_reconciles']
            traced = subprocess.run(command+['--json'], env=env, capture_output=True, check=True, timeout=90)
            assert not traced.stderr, traced.stderr
            trace = json.loads(traced.stdout)
            audit(trace)
            assert trace['report'] == r  # Trace is audited in memory, never exported.
            if stage == 'A':
                control = subprocess.run(cli+['--scenario','settlement_external_trade_reference',str(days),'42','--report-json'],env=env,capture_output=True,check=True,timeout=90)
                assert not control.stderr, control.stderr
                historical = json.loads(control.stdout)['report']
                for key in ('accounts','money','shifts','totals','unmet_meals','purchases'):
                    assert r[key] == historical[key], (days,key)
                assert r['profitable']['cash_results'] == historical['profitable']['cash_results']
            digest = hashlib.sha256(first.stdout).hexdigest()
            (args.output/f'{stage}-{days}-summary.json').write_bytes(first.stdout)
            p, c = r['open_economy'], r['profitable']['contracts']
            runs.append(dict(stage=stage, days=days, seed=42, resident_meals=p['resident_meals'], missed_meals=sum(r['unmet_meals'].values()),
                             visitor_bread=p['visitor_bread'], visitor_unfilled_requests=sum(d['visitor_unfilled_requests'] for d in r['pricing']['days']),
                             village_money=p['village_money'], external_money=p['external_money'], combined_money=r['money']['final'],
                             wheat=r['totals']['harvested']['wheat'], flour=r['totals']['production_outputs']['flour'], bread=r['totals']['production_outputs']['bread'],
                             paid_shifts=r['shifts']['paid'], wages=r['shifts']['wages'], distributions=r['profitable']['distributions']['amount'],
                             successful_purchases=r['purchases']['successful'], rejected_purchases=r['purchases']['rejected'], contract_breaches=c['breaches'],
                             circulation=r['money']['circulation'], price_revisions=sum(r['pricing']['price_changes'].values()), policy_audit_failures=sum(not passed for passed in flags['pricing'].values()),
                             summary_sha256=digest, ledger_sha256=r['profitable']['ledger_sha256']))
            if days == 30:
                for row in r['pricing']['business_days']:
                    row = dict(stage=stage, **row)
                    for key in ('candidates','inventory'):
                        row[key] = json.dumps(row[key],sort_keys=True,separators=(',',':'))
                    firms.append(row)
                for row in r['pricing']['days']:
                    row = dict(stage=stage, **row)
                    row['resident_cash'] = json.dumps(row['resident_cash'],sort_keys=True,separators=(',',':'))
                    daily.append(row)
                for actor, entity in sorted(r['final']['entities'].items()):
                    account = r['accounts'][actor]
                    row = dict(stage=stage, actor=actor, kind=entity['kind'], coins=entity['money'], **entity['inventory'],
                               **{k:v for k,v in account.items() if not isinstance(v,dict)}, missed_meals=r['unmet_meals'].get(actor,0))
                    accounts.append(row)
            print(stage, days, 'meals/missed', p['resident_meals'],sum(r['unmet_meals'].values()), 'visitors',p['visitor_bread'],
                  'shifts',r['shifts']['paid'],'breaches',c['breaches'],'audited/replayed',flush=True)
    for name, rows in (('runs',runs),('business_days',firms),('days',daily),('accounts',accounts)):
        with (args.output/(name+'.csv')).open('w',newline='') as handle:
            writer=csv.DictWriter(handle,fieldnames=list(rows[0]),lineterminator='\n')
            writer.writeheader()
            writer.writerows(rows)


if __name__ == '__main__':
    main()
