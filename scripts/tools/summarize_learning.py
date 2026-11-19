#!/usr/bin/env python3
"""Post-run diagnostics only; never selects prices or changes simulator state."""
import argparse,csv,json,math
from pathlib import Path
from learning_audit import bb,demand,sales,operate,update


def write(path,rows):
    with path.open('w') as stream:
        w=csv.DictWriter(stream,fieldnames=list(rows[0]),lineterminator="\n");w.writeheader();w.writerows(rows)

def quantile(weights,values,level):
    mass=0
    for value,w in sorted(zip(values,weights)):
        mass+=w
        if mass>=level:return value
    return max(values)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--fixtures',type=Path)
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    daily=[];calibration=[];participants=[];candidates=[]
    for stage in 'ABCD':
        r=json.loads((a.input/f'{stage}-30-summary.json').read_text())['report'];learning=r['learning']
        for day,decision,physical in zip(learning['memory']['cora'],learning['decisions'],r['spatial']['days']):
            o=decision['observation'];proposal=decision['proposal'];price=proposal['selected_price'];b=decision['beliefs']
            stock=int(operate(o['state'],False)['state'][2]);pmf=sales(demand(b,price,o['carry'],o['minimum']),stock)
            expected=sum(i*p for i,p in enumerate(pmf))
            selected=next((x for x in proposal['candidates'] if x['price']==price),{})
            quadrature=sum(x['probability']*(x['local']['sales']+x['visitor']['sales']) for x in selected.get('branches',[])) if stage in 'CD' else None
            daily.append(dict(stage=stage,day=day['day'],price=price,cash_before_payroll=o['state'][0],planned_shifts=operate(o['state'],False)['shifts'],
                revenue=day['accounting']['revenue'],inputs=day['accounting']['inputs'],payroll=day['accounting']['payroll'],distributions=day['accounting']['distributions'],
                financial_surplus=day['accounting']['revenue']-day['accounting']['inputs']-day['accounting']['payroll'],cash_end=day['cash'],bread_end=day['inventory']['bread'],
                sales=day['accounting']['sold'],passive_bayesian_expected_sales=expected,quadrature_expected_sales=quadrature,quadrature_sales_bias=quadrature-expected if quadrature is not None else None,
                meals=physical['resident_meals'],missed_meals=physical['unmet_meals'],visitor_loaves=physical['visitor_loaves'],paid_shifts=physical['paid_shifts'],breaches=physical['breaches']))
            posterior=update(b,day,price,day['complete'])
            for c in ('local','visitor'):
                obs=day[c];n=obs['eligible'];s=obs['sales'];weights=b[c]['weights'];after=posterior[c]['weights']
                eligible=n>0 and not obs['censored'] and not obs['unresolved']
                predictive=sum(w*bb(h,price,n)[s] for h,w in enumerate(weights)) if eligible else None
                qs=[(.9 if price<=h+1 else .1) if h<12 else max(.1,min(.9,.8-.075*(price-4))) for h in range(13)]
                expected_rate=sum(w*q for w,q in zip(weights,qs))
                calibration.append(dict(stage=stage,day=day['day'],cohort=c,price=price,arrivals=obs['arrivals'],eligible_inspections=n,sales=s,declines=obs['declines'],
                    closed=obs['closed'],stock_limited=obs['stock_limited'],censored=obs['censored'],complete_traffic=day['complete'],conversion_updated=eligible,
                    no_traffic=obs['arrivals']==0,expected_conversion=expected_rate,actual_conversion=s/n if n else None,
                    negative_log_predictive=-math.log(predictive) if eligible else None,squared_rate_error=(expected_rate-s/n)**2 if eligible else None,
                    entropy_before=-sum(w*math.log(w) for w in weights if w),entropy_after=-sum(w*math.log(w) for w in after if w),max_posterior=max(after),
                    q10=quantile(weights,qs,.1),q90=quantile(weights,qs,.9)))
            for row in proposal['candidates']:
                candidates.append(dict(stage=stage,day=day['day'],current_price=o['current_price'],price=row['price'],selected=price==row['price'],
                    ordinary=row.get('ordinary'),informed=row.get('informed'),evsi=row.get('evsi'),information_evaluated=stage=='D',
                    short_memory_operating_cash=row.get('operating_cash')))
        for actor,e in sorted(r['final']['entities'].items()):
            if e['kind']!='resident':continue
            account=r['accounts'][actor]
            participants.append(dict(stage=stage,actor=actor,money=e['money'],bread=e['inventory']['bread'],wages=account['wages_received'],distributions=account['profit_distributions_received'],food_spending=account['purchases'],meals=account['consumed'],missed=r['unmet_meals'][actor]))
    for name,rows in [('M18_DAYS.csv',daily),('M18_CALIBRATION.csv',calibration),('M18_RESIDENTS.csv',participants),('M18_CANDIDATES.csv',candidates)]:write(a.output/name,rows)
    if a.fixtures:
        rows=[]
        for case in json.loads(a.fixtures.read_text())['capital_cases']:
            for c in case['proposal']['candidates']:
                rows.append(dict(cash=case['cash'],external_cash=case['external_cash'],other_accounts=case['other_accounts'],combined=case['combined'],stage=case['stage'],price=c['price'],selected=c['price']==case['proposal']['selected_price'],ordinary=c['ordinary'],informed=c['informed'],evsi=c['evsi']))
        write(a.output/'M18_CAPITAL.csv',rows)
if __name__=='__main__':main()
