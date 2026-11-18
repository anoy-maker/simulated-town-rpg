#!/usr/bin/env python3
"""Publish compact M27 tables and representative, replayable L certificates.

All L/S/R certificates are checked; complete committed examples use L by a fixed
selection rule. Other certificates remain reproducible transient artifacts.
"""
import argparse
import csv
import json
import shutil
from collections import defaultdict
from pathlib import Path
from economic_witness import generate
from check_economic_witness import verify
from run_economic_diagnostics import write_rows,write_json,flatten
from run_brewery import digest


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--traces',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--parity-input',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    for name in ('cases','performance','cash_timelines','cohort_days'):
        shutil.copy2(a.input/(name+'.csv'),a.output/('M27_'+name.upper().replace('-','_')+'.csv'))
    parity=a.parity_input or a.input
    shutil.copy2(parity/'legacy-parity.csv',a.output/'M27_LEGACY_PARITY.csv')
    shutil.copy2(a.input/'conditional-wedges.json',a.output/'M27_CONDITIONAL_WEDGES.json')
    write_json(a.output/'M27_CASE_MANIFEST.json',dict(final_reader=json.loads((a.input/'verification.json').read_text()),original_capture_and_parity=json.loads((parity/'verification.json').read_text())))
    physical=[];failures=[];firms=[];constraints=[];proof_index=[];orders=[];bound_count=0
    for file in sorted((a.input/'analyses').glob('*-30-*.json')):
        diagnostic=json.loads(file.read_text());name=file.stem
        data=json.loads((a.traces/(name+'.json')).read_text());r=data['report']
        assert diagnostic['source']['report_sha256']==digest(dict(report=r)) and diagnostic['source']['ledger_sha256']==r['ledger_sha256']
        tag=dict(condition=r['condition'],arm=r['demand']['arm'],seed=42)
        # Recheck every stored certificate with the final independent checker.
        for day,bundle in diagnostic['snapshots'].items():
            for tier in ('fixed_orders','voluntary_orders'):
                path=a.input/'certificates'/f'{name}-day{day}-{tier}.json';cert=json.loads(path.read_text())
                verify(bundle,cert['plan'],cert['proof']);bound_count+=1
                if tag['arm']=='legacy_instrumented':
                    target=a.output/'M27_CERTIFICATES'/path.name;target.parent.mkdir(exist_ok=True);shutil.copy2(path,target)
                    proof_index.append(dict(**tag,day=int(day),tier=tier,certificate=str(target.relative_to(a.output)),certificate_sha256=digest(cert)))
        for row in csv.DictReader((a.input/'physical_witnesses.csv').open()):
            if row['condition']==tag['condition'] and row['arm']==tag['arm']:
                row.update(optimality_scope='declared one-day physical space; funding and buyer choices relaxed',
                    finance_label='witnessed_feasible' if row['finance_witnessed']=='True' else 'unproven',
                    financial_optimality='unproven',finance_horizon_days=1,future_term_funding='unproven')
                physical.append(row)
        transfers=defaultdict(list)
        for event in data['events']:
            if event['action']=='transfer_money' and event['success'] and event['minute']>960:
                transfers[event['day'],event['target']].append(event)
        for row in diagnostic['failure_attributions']:
            end=r['day_results'][row['day']-1]['households'][row['buyer']]
            late=transfers[row['day'],row['buyer']]
            failures.append(flatten(dict(**tag,**row,closing_cash=end['cash'],late_income_coins=sum(e['details']['amount'] for e in late),late_income_source_ids=[e['id'] for e in late])))
        for row in diagnostic['firm_days']:
            actual=r['day_results'][row['day']-1]['firms'][row['firm']]
            firms.append(flatten(dict(**tag,**row,scheduled_shifts=actual['shifts_due'],installed_slots=r['initial']['businesses'][row['firm']]['assets']['daily_slots'],
                cash_operating_flow=row['sales']-row['input_spending']-row['paid_wages'],accrued_input_expensed_margin=row['sales']-row['input_spending']-row['accrued_wages'])))
        grouped={}
        for row in diagnostic['constraints']:
            event=data['events'][row['event_id']-1];d=event['details'];subject=row['subject']
            if row['flag']=='legal_contract_restriction':subject=d.get('observation',{}).get('business',subject)
            item=d.get('item','')
            if event['action']=='consumer_decision':item=d['item']
            key=row['day'],subject,row['flag'],row['evidence'],item
            g=grouped.setdefault(key,dict(day=row['day'],subject=subject,flag=row['flag'],evidence=row['evidence'],item=item,details=set(),actors=set(),event_ids=set(),related_source_ids=set(),minutes=set()))
            g['details'].add(row['detail']);g['actors'].add(row['subject']);g['event_ids'].add(row['event_id']);g['related_source_ids'].update(row['additional_source_ids']);g['minutes'].add(row['minute'])
        for g in grouped.values():
            row={k:sorted(v) if isinstance(v,set) else v for k,v in g.items()};row.update(first_minute=min(row['minutes']),last_minute=max(row['minutes']));del row['minutes']
            constraints.append(flatten(dict(**tag,**row)))
        order_groups={}
        for event in data['events']:
            if event['action']!='demand_order_observed' or not event['success']:continue
            d=event['details'];buyer=d['buyer'] if d['kind']!='retail' else 'visitors' if d['buyer'].startswith('visitor:') else 'residents'
            q=d['quote'];key=event['day'],event['minute'],d['seller'],buyer,d['item'],d['kind'],q['unit_price'],q['version']
            g=order_groups.setdefault(key,dict(day=event['day'],minute=event['minute'],seller=d['seller'],buyer_or_cohort=buyer,item=d['item'],kind=d['kind'],unit_price=q['unit_price'],quote_version=q['version'],requests=0,requested=0,filled=0,unfilled=0,paid_coins=0,event_ids=[],request_source_ids=[]))
            g['requests']+=1;g['requested']+=d['quantity'];g['filled']+=d['filled'];g['unfilled']+=d['unfilled'];g['paid_coins']+=d['filled']*q['unit_price']
            g['event_ids'].append(event['id']);g['request_source_ids'].extend(d['source_ids'])
        orders.extend(flatten(dict(**tag,**g)) for g in order_groups.values())
    for name,rows in [('PHYSICAL_WITNESSES',physical),('FIRM_DAYS',firms),('FAILURE_ATTRIBUTIONS',failures),('CONSTRAINTS',constraints),('CERTIFICATE_INDEX',proof_index),('ORDERS',orders)]:
        write_rows(a.output/('M27_'+name+'.csv'),rows)
    write_json(a.output/'M27_CERTIFICATE_CHECKS.json',dict(all_arm_certificates_rechecked=bound_count,complete_committed_examples=len(proof_index),selection='all L cases, days1/3, both tiers; never selected by outcome',
        example_encoding='Proof financial steps omit exact-zero inventory/cargo cells; declared holders/items define zeros.',
        incentive_compatible='unproven; current policy quantity agreement is a different claim'))
    print('Rechecked',bound_count,'certificates; published',len(proof_index),'representative complete L examples',flush=True)


if __name__=='__main__':main()
