#!/usr/bin/env python3
"""M28 compact measured outcomes and conditional next-day input evaluation.

No latent hypothetical supply scores. Unknown/unsent orders remain unscored.
This tool consumes independently audited researcher outputs, never NPC inputs.
"""
import argparse
import json
import shutil
from pathlib import Path
from input_audit import INPUTS
from brewery_feasibility import OWNERS
from run_economic_diagnostics import write_rows,write_json,flatten
from run_brewery import digest


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--traces',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    firms=[];residents=[];food=[];days=[];beliefs=[];candidates=[];orders=[];evaluations=[];failures=[];businesses=[];terms=[];balances=[]
    manifests={}
    for folder,prefix in [('experiments',''),('staggered','STAGGERED_')]:
        path=a.input/folder
        for name in ['runs','performance','parity']:shutil.copy2(path/(name+'.csv'),a.output/('M28_'+prefix+name.upper()+'.csv'))
        manifests[folder]=json.loads((path/'verification.json').read_text())
        for file in sorted((path/'analyses').glob('*-30-*.json')):
            diagnostic=json.loads(file.read_text());data=json.loads((a.traces/(file.stem+'-1.json')).read_text());r=data['report'];tag=dict(condition=r['condition'],arm=r['input_reliability']['arm'],fixture=r['initial']['labor_market']['fixture'],seed=42)
            assert diagnostic['source']['report_sha256']==digest(dict(report=r)) and diagnostic['source']['ledger_sha256']==r['ledger_sha256']
            points={(f['day'],f['business']):f for f in diagnostic['input']['forecasts']};receipts={(o['day'],o['business']):o for o in diagnostic['input']['orders']}
            projections={(f['day'],f['business']):f for f in diagnostic['input']['projections']}
            freezes={(e['day'],e['target']):e['id'] for e in data['events'] if e['action']=='input_reliability_frozen'}
            projection_ids={(e['day'],e['target']):e['id'] for e in data['events'] if e['action']=='input_forecast_projection'}
            shops={(e['day'],e['actor']):e for e in data['events'] if e['action']=='consumer_decision' and e['target']=='bakery' and not e['actor'].startswith('visitor:')}
            missed={(f['day'],f['buyer']):f for f in diagnostic['failure_attributions']}
            for row in diagnostic['firm_days']:
                point=points[row['day'],row['firm']];receipt=receipts.get((row['day'],row['firm']))
                f=dict(**row,input_observation='valid_positive_order' if receipt else 'unknown_no_eligible_order' if row['firm']!='farm' else 'inapplicable',input_requested_lots=receipt['requested'] if receipt else None,input_filled_lots=receipt['filled'] if receipt else None,input_rationed_lots=receipt['rationed'] if receipt else None,input_order_id=receipt['order_event_id'] if receipt else None,input_N=point['numerator'],input_D=point['denominator'],input_status=point['status'],chosen_headcount=projections[row['day'],row['firm']]['headcount'],input_estimate_event_id=freezes[row['day'],row['firm']],accrued_input_expensed_margin=row['sales']-row['input_spending']-row['accrued_wages'])
                if receipt:
                    item=INPUTS[row['firm']][1];size=INPUTS[row['firm']][2]
                    assert row['purchased_inputs'][item]==receipt['filled']*size
                firms.append(flatten(dict(**tag,**f)))
            for point in diagnostic['input']['forecasts']:beliefs.append(flatten(dict(**tag,**point,event_id=freezes[point['day'],point['business']])))
            for receipt in diagnostic['input']['orders']:orders.append(flatten(dict(**tag,**receipt)))
            for projection in diagnostic['input']['projections']:
                for candidate in projection['candidates']:
                    summary=dict(candidate['summary']);summary['term_guaranteed_wages']=summary.pop('guaranteed_wages')
                    for day in candidate['days']:
                        candidates.append(flatten(dict(**tag,day=projection['day'],business=projection['business'],event_id=projection_ids[projection['day'],projection['business']],chosen=candidate['summary']['headcount']==projection['headcount'],N=projection['estimate']['numerator'],D=projection['estimate']['denominator'],**summary,**day)))
                if projection['business'] not in INPUTS or projection['day']>=30:continue
                b=projection['business'];point=projection['estimate'];chosen=next(c for c in projection['candidates'] if c['summary']['headcount']==projection['headcount']);first=chosen['days'][0]
                actual=receipts.get((projection['day']+1,b));reason='unknown_no_eligible_order' if actual is None else 'unknown_quote' if point['status']=='unknown_quote' else 'changed_quote_context' if (actual['supplier'],actual['item'],actual['price'])!=(point['supplier'],point['item'],point['price']) else 'different_desired_quantity' if actual['requested']!=first['desired_lots'] else 'selected_comparable_order'
                comparable=reason=='selected_comparable_order';error=first['predicted_lots']-actual['filled'] if comparable else None
                evaluations.append(dict(**tag,business=b,forecast_day=projection['day'],order_day=projection['day']+1,N=point['numerator'],D=point['denominator'],forecast_desired_lots=first['desired_lots'],forecast_predicted_lots=first['predicted_lots'],actual_requested=actual['requested'] if actual else None,actual_filled=actual['filled'] if actual else None,actual_order_id=actual['order_event_id'] if actual else None,comparable=comparable,status=reason,signed_lot_error=error,absolute_lot_error=abs(error) if comparable else None))
            for d in r['day_results']:
                count=sum(f['day']==d['day'] and f['immediate_blocker']=='household_purchasing_power' for f in diagnostic['failure_attributions']);stockout=sum(f['day']==d['day'] and f['immediate_blocker']=='stockout_of_solvent_request' for f in diagnostic['failure_attributions'])
                assert count+stockout==d['unmet_meals']
                days.append(dict(**tag,day=d['day'],resident_meals=d['resident_meals'],missed=d['unmet_meals'],cash_blocked=count,solvent_stockout=stockout,visitor_bread=d['visitor_bread'],ale_consumed=d['ale_consumed'],productive=d['shifts'],wages=sum(f['wages'] for f in d['firms'].values()),standby=sum(f['day']==d['day'] and f['standby'] for f in diagnostic['firm_days']),circulation=d['circulation'],currency=d['currency'],**d['production']))
                for w,h in d['households'].items():
                    event=shops[d['day'],w];o=event['details']['observation'];failure=missed.get((d['day'],w))
                    food.append(flatten(dict(**tag,day=d['day'],resident=w,shopping_event_id=event['id'],shopping_cash=o['money'],bread_quote=o['prices'].get('bread'),bread_stock=o['stock'].get('bread'),purchased=event['details']['purchased'],need=o['need_bread'],meals=h['meals'],missed=h['missed_meals'],wages=h['wages'],distributions=h['distributions'],closing_cash=h['cash'],immediate_blocker=failure['immediate_blocker'] if failure else '',blocker_source_ids=failure['source_ids'] if failure else [])))
            failures.extend(flatten(dict(**tag,**f)) for f in diagnostic['failure_attributions'])
            for w,row in r['contracts']['workers'].items():
                account=r['accounts'][w];residents.append(flatten(dict(**tag,resident=w,owner=w in OWNERS.values(),**row,meals=account['meals'],missed=account['missed_meals'],bread_spending=account['bread_spending'],ale_spending=account['ale_spending'],ownership_income=account['distributions'],cash=account['cash'],inventory=account['inventory'])))
            for b,row in r['contracts']['businesses'].items():businesses.append(flatten(dict(**tag,business=b,standby=sum(f['standby'] for f in diagnostic['firm_days'] if f['firm']==b),last_productive_day=max((f['day'] for f in diagnostic['firm_days'] if f['firm']==b and f['productive']),default=0),**row)))
            terms.extend(flatten(dict(**tag,**t)) for t in r['final']['binding_contracts']['terms'].values())
            accounts=r['final']['entities'];hh=sum(e['money'] for e in accounts.values() if e['kind']=='resident');bb=sum(accounts[b]['money'] for b in OWNERS);external=accounts['visitors']['money'];assert hh+bb+external==9192
            balances.append(dict(**tag,household_cash=hh,business_cash=bb,external_cash=external,owner_cash=sum(accounts[w]['money'] for w in OWNERS.values()),employee_cash=sum(e['money'] for w,e in accounts.items() if e['kind']=='resident' and w not in OWNERS.values()),richest_resident_cash=max(e['money'] for e in accounts.values() if e['kind']=='resident'),currency=9192))
    for name,rows in [('FIRM_DAYS',firms),('RESIDENTS',residents),('FOOD_DAYS',food),('DAYS',days),('BELIEFS',beliefs),('CANDIDATES',candidates),('INPUT_ORDERS',orders),('INPUT_EVALUATION',evaluations),('FAILURE_ATTRIBUTIONS',failures),('BUSINESSES',businesses),('TERMS',terms),('BALANCES',balances)]:write_rows(a.output/('M28_'+name+'.csv'),rows)
    write_json(a.output/'M28_EXPERIMENT_MANIFEST.json',manifests)
    print('Published audited main/staggered outcomes; comparable input errors exclude unknown or different-size requests',flush=True)


if __name__=='__main__':main()
