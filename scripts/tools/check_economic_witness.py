"""M27 independent integer/time/cash certificate verifier, not the search program.

Inputs must be snapshots/evidence from independently audited native traces.
This module never imports the witness generator or the GDScript policies.
"""
import copy
from collections import Counter
from itertools import product
from run_brewery import digest

FIRMS=('farm','mill','bakery','brewery')
ITEMS=('wheat','flour','bread','ale')
OWNERS=dict(farm='ada',mill='bram',bakery='cora',brewery='mara')
SITES=dict(farm=[6,1],mill=[6,3],bakery=[8,3],brewery=[8,5])
WINDOWS=dict(farm=(540,600),mill=(660,720),bakery=(840,900),brewery=(780,840))
PRICES=dict(wheat=2,flour=5,bread=6,ale=4)
RULES=dict(farm=(None,0,'wheat',7),mill=('wheat',5,'flour',5),bakery=('flour',5,'bread',7),brewery=('wheat',3,'ale',6))


def integer(n):
    assert type(n) is int and n>=0,'whole nonnegative integer required'
    return n


def eligible(s,b):
    ids=[]
    for w in s['businesses'][b]['employees']:
        j=s['employment'].get(w,{})
        if j.get('active') and j['business']==b and j['start_day']<=s['day']<j['end_day']:
            assert s['affiliations'][w]==dict(business=b,kind='employee')
            assert s['entities'][w]['kind']=='resident' and w not in OWNERS.values() and j['wage']==10
            ids.append(w)
    return sorted(ids)


def capacity(s,b):
    requirements=('workshop',dict(farm='farm_tools',mill='millstone',bakery='oven',brewery='brew_vat')[b])
    assets=[a for a in s['assets'].values() if a['holder']==b]
    limits=[s['businesses'][b]['assets']['daily_slots'],len(eligible(s,b))]
    for kind in requirements:
        matching=[a for a in assets if a['kind']==kind and a['industry']==s['businesses'][b]['industry']]
        assert len(matching)==1;limits.append(integer(matching[0]['capacity']))
    return min(limits)


def clear(grain,rm,ra):
    # Independent sort, rather than the generator's max-comprehension.
    possibilities=[]
    for mill in range(rm+1):
        for brewer in range(ra+1):
            if 5*mill+3*brewer<=grain:possibilities.append((5*mill+3*brewer,mill,brewer))
    possibilities.sort(reverse=True)
    return dict(mill=possibilities[0][1],brewery=possibilities[0][2])


def physical_bound(s,e,tier):
    """Independent analytical bound: maximize flour/bread monotonically AFTER
    enumerating farm output and indivisible clearing, which is nonmonotone.
    """
    cf,cm,cb,ca=(capacity(s,b) for b in FIRMS)
    ceilings=(e['clearing']['details']['eligible']['mill'],e['clearing']['details']['eligible']['brewery'],e['plans']['bakery:procurement']['details']['proposal']['lots'])
    request_space=[ceilings] if tier=='fixed_orders' else list(product(range(cm+1),range((0 if s['condition']=='no_brew_request' else ca)+1),range(cb+1)))
    best=s['entities']['bakery']['inventory']['bread']
    for f in range(cf+1):
        for rm,ra,rf in request_space:
            wheat=s['entities']['farm']['inventory']['wheat']+min(7*f,s['cap']);q=s['quotes']['farm']['wheat']
            allocation=clear(min(wheat,q['limit']) if q['active'] else 0,rm,ra)
            m=min(cm,(s['entities']['mill']['inventory']['wheat']+s['cargo']['mill']['inventory']['wheat']+5*allocation['mill'])//5)
            flour=s['entities']['mill']['inventory']['flour']+5*m;q=s['quotes']['mill']['flour']
            lots=min(rf,min(flour,q['limit'])//5) if q['active'] else 0
            b=min(cb,(s['entities']['bakery']['inventory']['flour']+s['cargo']['bakery']['inventory']['flour']+5*lots)//5)
            best=max(best,s['entities']['bakery']['inventory']['bread']+7*b)
    return best


def geometry(s,e,plan,allocation,flour_lots):
    residents=sorted(w for w,p in s['entities'].items() if p['kind']=='resident')
    visitors=[v['actor'] for v in e['visitors']]
    trips=plan['trips'];assert set(t['body'] for t in trips)==set(residents+visitors)
    expected={}
    for w in residents:
        first=SITES['farm'] if w in ('ada','bram','mara') else SITES['mill'] if w=='cora' else SITES[s['employment'][w]['business']] if s['employment'].get(w,{}).get('active') else s['people'][w]['home']
        expected[w]=[(480,first)]
        if w in ('bram','mara'):expected[w].append((615,SITES['mill' if w=='bram' else 'brewery']))
        if w=='cora':expected[w].append((735,SITES['bakery']))
        expected[w]+=[(930,SITES['bakery']),(965,SITES['brewery'])]
        if w=='cora':expected[w].append((980,SITES['bakery']))
        expected[w].append((1050,s['people'][w]['home']))
    for w in visitors:expected[w]=[(1020,SITES['bakery']),(1030,SITES['brewery']),(1045,[9,3])]
    schedules={}
    for w in residents+visitors:
        pos=list(s['people'][w]['tile']) if w in residents else [9,3];end=0;checked=[];own=[t for t in trips if t['body']==w]
        wanted=[]
        for start,to in expected[w]:
            if pos!=to:wanted.append((start,to));pos=list(to)
        assert [(t['start'],t['to']) for t in own]==wanted,'missing/extra/reordered trip'
        pos=list(s['people'][w]['tile']) if w in residents else [9,3]
        for t in own:
            assert t['origin']==pos and type(t['start']) is int and t['start']>=end
            path=[];at=list(pos)
            for axis in (0,1):
                while at[axis]!=t['to'][axis]:
                    at[axis]+=1 if at[axis]<t['to'][axis] else -1;path.append(list(at))
            assert t['path']==path and t['end']==t['start']+5*len(path) and t['end']<=1440
            assert all(0<=p[0]<10 and 0<=p[1]<7 for p in path)
            checked.append(t);pos=list(t['to']);end=t['end']
        schedules[w]=checked
    def at(w,minute):
        pos=list(s['people'][w]['tile']) if w in residents else [9,3]
        for trip in schedules[w]:
            if minute<trip['start']:return pos
            if trip['start']<minute<trip['end']:return None
            if minute>=trip['end']:pos=trip['to']
        return pos
    activities={w:[] for w in residents+visitors}
    def activity(w,start,end,b,kind):
        assert at(w,start)==SITES[b] and at(w,end)==SITES[b],(w,kind,'wrong site/time')
        assert all(max(start,t['start'])>=min(end,t['end']) for t in schedules[w]),'body travels during activity'
        assert all(max(start,a[0])>=min(end,a[1]) for a in activities[w]),'overlapping activities'
        activities[w].append((start,end,kind))
    for b in FIRMS:
        for w in eligible(s,b):activity(w,*WINDOWS[b],b,'work' if w in plan['workers'][b] else 'standby')
        activity(OWNERS[b],*WINDOWS[b],b,'manage')
    for w in ('bram','mara'):activity(w,610,615,'farm','procure')
    activity('cora',730,735,'mill','procure')
    for b,start in [('mill',625),('brewery',645),('bakery',745)]:
        activity(OWNERS[b],start,start+5,b,'deposit')
    for w in residents:
        activity(w,955,960,'bakery','board');activity(w,960,965,'bakery','shop');activity(w,975,980,'brewery','shop')
        assert at(w,1110)==s['people'][w]['home'],'late household meal'
    for w in visitors:activity(w,1025,1030,'bakery','shop');activity(w,1040,1045,'brewery','shop')
    return dict(trips=len(trips),activities=sum(map(len,activities.values())),resident_bodies=len(residents),visitor_bodies=len(visitors))


def verify_physical(bundle,plan):
    s,e=bundle['state'],bundle['evidence']
    assert set(plan)=={'schema','snapshot_sha256','evidence_sha256','tier','day','counts','requests','workers','trips','claimed_physical','search_candidates','label','relaxations'},'unknown witness claims'
    assert 0<integer(plan['search_candidates'])<=9216
    for holder in list(s['entities'].values())+list(s['cargo'].values()):
        assert set(holder['inventory'])==set(ITEMS)
        for qty in holder['inventory'].values():assert integer(qty)<=10**9
    assert sum(integer(v['money']) for v in s['entities'].values())==9192
    assert plan['schema']==1 and plan['snapshot_sha256']==bundle['snapshot_sha256']==digest(s)
    assert plan['evidence_sha256']==digest(e) and plan['day']==s['day']
    assert plan['tier'] in ('fixed_orders','voluntary_orders') and plan['label']=='relaxed_potential'
    assert plan['relaxations']==['money','customer choices','own-profit/request policy gates']
    n=plan['counts'];requests=plan['requests'];seen=set()
    assert set(n)==set(FIRMS) and set(plan['workers'])==set(FIRMS) and set(requests)=={'mill','brewery','flour'}
    for b in FIRMS:
        assert integer(n[b])<=capacity(s,b) and len(plan['workers'][b])==n[b]
        assert len(set(plan['workers'][b]))==n[b] and set(plan['workers'][b])<=set(eligible(s,b))
        assert not seen.intersection(plan['workers'][b]);seen.update(plan['workers'][b])
    for b,firm in [('mill','mill'),('brewery','brewery'),('flour','bakery')]:assert integer(requests[b])<=capacity(s,firm)
    if s['condition']=='no_brew_request':assert requests['brewery']==0
    if plan['tier']=='fixed_orders':
        assert requests==dict(mill=e['clearing']['details']['eligible']['mill'],brewery=e['clearing']['details']['eligible']['brewery'],flour=e['plans']['bakery:procurement']['details']['proposal']['lots'])
    held={b:copy.deepcopy(s['entities'][b]['inventory']) for b in FIRMS};steps=[];production=dict.fromkeys(ITEMS,0)
    cargo={b:copy.deepcopy(s['cargo'][b]['inventory']) for b in FIRMS}
    expected_goods={i:sum(g[i] for g in list(held.values())+list(cargo.values())) for i in ITEMS}
    def step(minute,action,b,**detail):
        assert all(type(q) is int and q>=0 for g in list(held.values())+list(cargo.values()) for q in g.values())
        assert expected_goods=={i:sum(g[i] for g in list(held.values())+list(cargo.values())) for i in ITEMS}
        steps.append(dict(minute=minute,action=action,firm=b,**detail,held=copy.deepcopy(held),cargo=copy.deepcopy(cargo)))
    for i,w in enumerate(plan['workers']['farm']):
        amount=min(7,s['cap']-production['wheat']);assert amount>0
        held['farm']['wheat']+=amount;production['wheat']+=amount;expected_goods['wheat']+=amount;step(600,'harvest','farm',worker=w,quantity=amount)
    q=s['quotes']['farm']['wheat'];allocation=clear(min(held['farm']['wheat'],q['limit']) if q['active'] else 0,requests['mill'],requests['brewery'])
    for b,size in [('brewery',3),('mill',5)]:
        qty=allocation[b]*size;held['farm']['wheat']-=qty;cargo[b]['wheat']+=qty
        step(610,'cargo_purchase',b,item='wheat',quantity=qty)
    for b,minute in [('mill',625),('brewery',645)]:
        qty=cargo[b]['wheat'];held[b]['wheat']+=qty;cargo[b]['wheat']=0;step(minute,'deposit' if qty else 'wait',b,item='wheat',quantity=qty)
    for w in plan['workers']['mill']:
        assert held['mill']['wheat']>=5;held['mill']['wheat']-=5;held['mill']['flour']+=5;production['flour']+=5
        expected_goods['wheat']-=5;expected_goods['flour']+=5;step(720,'mill','mill',worker=w)
    q=s['quotes']['mill']['flour'];lots=min(requests['flour'],min(q['limit'],held['mill']['flour'])//5) if q['active'] else 0
    held['mill']['flour']-=5*lots;cargo['bakery']['flour']+=5*lots;step(730,'cargo_purchase','bakery',item='flour',quantity=5*lots)
    qty=cargo['bakery']['flour'];held['bakery']['flour']+=qty;cargo['bakery']['flour']=0;step(745,'deposit' if qty else 'wait','bakery',item='flour',quantity=qty)
    for b,minute in [('brewery',840),('bakery',900)]:
        raw,take,out,make=RULES[b]
        for w in plan['workers'][b]:
            assert held[b][raw]>=take;held[b][raw]-=take;held[b][out]+=make;production[out]+=make
            expected_goods[raw]-=take;expected_goods[out]+=make;step(minute,'produce',b,worker=w)
    assert [r['minute'] for r in steps]==sorted(r['minute'] for r in steps)
    expected=dict(counts=n,requests=requests,production=production,allocation=allocation,flour_lots=lots,bread_at_shop=held['bakery']['bread'])
    assert plan['claimed_physical']==expected,'generator physical claim mismatch'
    geometry_proof=geometry(s,e,plan,allocation,lots)
    bound=physical_bound(s,e,plan['tier']);assert held['bakery']['bread']<=bound
    return dict(label='relaxed_potential',physically_feasible=True,bread_at_shop=held['bakery']['bread'],
                physical_resident_delivery_ceiling=min(15,held['bakery']['bread']+sum(v['inventory']['bread'] for v in s['entities'].values() if v['kind']=='resident')),
                physical_upper_bound=bound,optimality='certified_optimum' if held['bakery']['bread']==bound else 'unproven',
                production=production,allocation=allocation,flour_lots=lots,held_at_shop=held,steps=steps,geometry=geometry_proof)


class FinanceUnproven(Exception):
    pass


def finance(bundle,plan,physical):
    """Conservative constructive overlay; no optimization or invented customers.
    Fully pays each due window; unsupported partial/late-cure alternatives stay
    unproven. Starting claims survive even when this certificate cannot fund them.
    """
    s,e=bundle['state'],bundle['evidence'];day=s['day']
    cash={w:integer(v['money']) for w,v in s['entities'].items()};assert sum(cash.values())==9192
    inventory={w:copy.deepcopy(v['inventory']) for w,v in s['entities'].items()};cargo={b:copy.deepcopy(s['cargo'][b]['inventory']) for b in FIRMS}
    claims=copy.deepcopy(s['binding']['obligations']);books=copy.deepcopy(s['books']);steps=[];produced=dict.fromkeys(ITEMS,0);consumed=dict.fromkeys(ITEMS,0)
    for claim in claims.values():
        assert claim['amount']==10 and integer(claim['paid'])<=claim['amount'] and claim['business'] in FIRMS
        assert s['entities'][claim['worker']]['kind']=='resident'
    visitors=[v['actor'] for v in e['visitors']]
    assert not any(inventory['visitors'].values()),'unproven external inventory custody at start'
    for w in visitors:inventory[w]=dict.fromkeys(ITEMS,0)
    residents=sorted(w for w,v in s['entities'].items() if v['kind']=='resident')
    initial_goods={i:sum(g[i] for g in inventory.values())+sum(g[i] for g in cargo.values()) for i in ITEMS}
    inputs=dict.fromkeys(ITEMS,0);spent={w:0 for w in visitors};bought=set();paid_receipt_counts=Counter()
    def total_debt():return sum(c['amount']-c['paid'] for c in claims.values())
    def record(minute,action,actor,target='',**detail):
        assert sum(cash.values())==9192 and min(cash.values())>=0
        actual_goods={i:sum(g[i] for g in inventory.values())+sum(g[i] for g in cargo.values()) for i in ITEMS}
        assert actual_goods=={i:initial_goods[i]+produced[i]-inputs[i]-consumed[i] for i in ITEMS}
        assert all(type(q) is int and 0<=q<=10**9 for g in list(inventory.values())+list(cargo.values()) for q in g.values())
        payable=total_debt();receivable=sum(sum(c['amount']-c['paid'] for c in claims.values() if c['worker']==w) for w in residents)
        assert payable==receivable
        sparse=lambda stock:{w:{i:q for i,q in goods.items() if q} for w,goods in stock.items() if any(goods.values())}
        steps.append(dict(minute=minute,action=action,actor=actor,target=target,**detail,
                          cash=dict(cash),inventory=sparse(inventory),cargo=sparse(cargo),
                          payable=payable,receivable=receivable,claim_state_sha256=digest(claims)))
    def transfer(minute,a,b,amount,purpose):
        assert type(amount) is int and amount>0
        if cash[a]<amount:raise FinanceUnproven(f'cash at{minute}: {a} has{cash[a]}, needs{amount} for {purpose}')
        assert cash[b]+amount<=10**9
        cash[a]-=amount;cash[b]+=amount
        if purpose=='wage':books[a]['payroll']+=amount
        if purpose=='distribution':books[a]['distributions']+=amount
        record(minute,'transfer',a,b,coins=amount,purpose=purpose)
    def pay(minute,b):
        queue=sorted((id,c) for id,c in claims.items() if c['business']==b and c['paid']<c['amount'])
        for id,c in queue:
            amount=c['amount']-c['paid']
            transfer(minute,b,c['worker'],amount,'wage');c['paid']+=amount;paid_receipt_counts[id]+=1
            c.setdefault('alternative_payments',[]).append(dict(step=len(steps),minute=minute,coins=amount))
            record(minute,'wage_claim_application',b,c['worker'],claim_id=id,paid=amount)
    def purchase(minute,account,seller,item,qty,body,receipt_id=None):
        integer(qty);assert qty>0 and body==OWNERS.get(account,body)
        q=s['quotes'][seller][item]
        assert q['active'] and q['unit_price']==PRICES[item] and qty<=q['limit']
        assert inventory[seller][item]>=qty
        cost=qty*q['unit_price']
        if cash[account]<cost:raise FinanceUnproven(f'input cash at{minute}: {account}')
        cash[account]-=cost;cash[seller]+=cost;books[seller]['sales']+=cost
        inventory[seller][item]-=qty
        if account in FIRMS:cargo[account][item]+=qty;books[account]['inputs']+=cost
        else:inventory[body][item]+=qty
        record(minute,'purchase',body,seller,account=account,item=item,quantity=qty,coins=cost,source_event_id=receipt_id)
    def industry(b):
        start,end=WINDOWS[b]
        # Presence/continuous attendance was independently proved by geometry.
        for w in eligible(s,b):
            id=f'{day:04}:{b}:{w}';assert id not in claims
            claims[id]=dict(id=id,worker=w,business=b,day=day,amount=10,paid=0)
            record(end,'wage_claim_accrued',b,w,claim_id=id,kind='productive' if w in plan['workers'][b] else 'standby',amount=10)
        pay(end,b)
        raw,take,out,make=RULES[b]
        for w in plan['workers'][b]:
            id=f'{day:04}:{b}:{w}';assert claims[id]['paid']==10 and paid_receipt_counts[id]==1
            if b=='farm':
                qty=min(7,s['cap']-produced['wheat']);assert qty>0
            else:
                assert inventory[b][raw]>=take;inventory[b][raw]-=take;inputs[raw]+=take;qty=make
            inventory[b][out]+=qty;produced[out]+=qty
            record(end,'production',w,b,item=out,quantity=qty)
    def deposit(minute,b):
        for item in ITEMS:inventory[b][item]+=cargo[b][item];cargo[b][item]=0
        record(minute,'deposit',OWNERS[b],b)
    def retail(minute,b):
        item='bread' if b=='bakery' else 'ale'
        intents=[x for x in e['intents'] if x['minute']==minute and x['target']==b]
        for event in intents:
            w=event['actor'];d=event['details']
            assert event['day']==day and d['item']==item and type(d['quantity']) is int and d['quantity'] in (0,1)
            q=d['quote'];assert all(q[k]==v for k,v in s['quotes'][b][item].items())
            if not d['quantity']:continue # Refusal never becomes hypothetical demand.
            assert (w,item) not in bought
            account='visitors' if w in visitors else w;price=PRICES[item]
            if cash[account]<price or (w in visitors and spent[w]+price>10):
                record(minute,'actual_request_not_fundable_in_alternative',w,b,source_event_id=event['id']);continue
            if inventory[b][item]==0:
                record(minute,'unfilled_actual_request',w,b,item=item,source_event_id=event['id']);continue
            purchase(minute,account,b,item,1,w,event['id']);bought.add((w,item))
            if w in visitors:spent[w]+=price
    def consume(minute,people,item):
        for w in people:
            if inventory[w][item]>0:
                inventory[w][item]-=1;consumed[item]+=1;record(minute,'consume',w,item=item,quantity=1)
            elif item=='bread' and w in residents:record(minute,'missed_meal',w,item=item)
    try:
        for b in FIRMS:pay(480,b)
        industry('farm')
        # Native request gates depend on actual own pre-procurement budgets and
        # stocks; those are unchanged before today's first incoming retail sale.
        for b in ('mill','brewery'):
            actual=e['plans'][b+':procurement']['details']
            if plan['requests'][b]>actual['proposal']['lots']:raise FinanceUnproven('unsupported funded production request: '+b)
            if cash[b]!=actual['observation']['cash']:raise FinanceUnproven('pre-request cash differs; actual request gate cannot certify alternative')
        for b,size in [('brewery',3),('mill',5)]:
            for _ in range(physical['allocation'][b]):purchase(610,b,'farm','wheat',size,OWNERS[b])
        deposit(625,'mill');deposit(645,'brewery');industry('mill')
        actual=e['plans']['bakery:procurement']['details']
        if plan['requests']['flour']>actual['proposal']['lots']:raise FinanceUnproven('unsupported funded flour order')
        if cash['bakery']!=actual['observation']['cash']:raise FinanceUnproven('pre-flour cash differs; no certified request gate')
        for _ in range(physical['flour_lots']):purchase(730,'bakery','mill','flour',5,'cora')
        deposit(745,'bakery');industry('brewery');industry('bakery')
        assert produced==physical['production'] and inventory['bakery']['bread']==physical['bread_at_shop']
        retail(960,'bakery');retail(975,'brewery');consume(980,residents,'ale')
        retail(1025,'bakery');consume(1030,visitors,'bread');retail(1040,'brewery');consume(1045,visitors,'ale')
        consume(1110,residents,'bread')
        for b in FIRMS:pay(1140,b)
        for b in FIRMS:
            book=books[b];owed=sum(c['amount']-c['paid'] for c in claims.values() if c['business']==b)
            realized=book['sales']-book['inputs']-book['payroll']-book['distributions']
            amount=0 if owed else min(max(0,realized),max(0,cash[b]-120))
            if amount:transfer(1140,b,OWNERS[b],amount,'distribution')
        record(1440,'boundary','world',future_guarantees=sum(10*max(0,j['end_day']-day-1) for j in s['employment'].values() if j['active']),
               naturally_expiring_terms=[id for id in s['binding']['active_terms'].values() if s['binding']['terms'][id]['end_day']<=day+1],new_terms=[])
    except FinanceUnproven as error:
        return dict(finance_witnessed=False,label='unproven',reason=str(error),steps=steps,
                    remaining_claims=copy.deepcopy(claims),incentive_compatible='unproven')
    assert [r['minute'] for r in steps]==sorted(r['minute'] for r in steps)
    deviations=[]
    for b in ('mill','brewery'):
        actual=e['plans'][b+':procurement']['details']['proposal']['lots']
        if plan['requests'][b]!=actual:deviations.append(dict(firm=b,action='grain_request',actual=actual,alternative=plan['requests'][b]))
    if plan['requests']['flour']!=e['plans']['bakery:procurement']['details']['proposal']['lots']:
        deviations.append(dict(firm='bakery',action='flour_request',actual=e['plans']['bakery:procurement']['details']['proposal']['lots'],alternative=plan['requests']['flour']))
    for b in FIRMS:
        actual=e['plans'][b+':production']['details']['proposal']['workers']
        if len(plan['workers'][b])!=len(actual):deviations.append(dict(firm=b,action='production_headcount',actual=len(actual),alternative=len(plan['workers'][b])))
    return dict(finance_witnessed=True,label='witnessed_feasible',steps=steps,currency=9192,remaining_claims=claims,
                resident_meals=sum(r['action']=='consume' and r['actor'] in residents and r.get('item')=='bread' for r in steps),
                visitor_meals=sum(r['action']=='consume' and r['actor'] in visitors and r.get('item')=='bread' for r in steps),
                inventory=inventory,cash=cash,incentive_compatible='unproven',current_policy_quantity_agreement=not deviations,
                finance_horizon_days=1,future_guarantees_status='retained, not certified funded for future days',
                step_encoding='Missing inventory/cargo cells are exact zero over the declared holders/items; cash is dense.',
                incentive_scope='Policy disagreement is evidence of non-reproduction, not proof that a counterfactual choice is irrational.',
                policy_deviations=deviations)


def verify(bundle,plan,claimed=None):
    physical=verify_physical(bundle,plan);financial=finance(bundle,plan,physical)
    result=dict(physical=physical,finance=financial)
    if claimed is not None:assert result==claimed,'forged witness outcome/steps/cash/claims'
    return result


def main():
    import argparse,csv,json
    from pathlib import Path
    from economic_diagnostics import analyze
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--trace',type=Path,required=True);p.add_argument('--certificate',type=Path,required=True);a=p.parse_args()
    source=json.loads(a.trace.read_text());cert=json.loads(a.certificate.read_text());data=analyze(source)
    report=source['report'];pins=Path(__file__).resolve().parents[2]/'docs/M26_RUNS.csv'
    pin=next(r for r in csv.DictReader(pins.open()) if r['condition']==report['condition'] and r['arm']==report['demand']['arm'] and int(r['days'])==report['days'])
    assert digest(dict(report=report))==pin['summary_sha256'] and report['ledger_sha256']==pin['ledger_sha256'],'unpinned source'
    assert cert['source']==data['source'];bundle=data['snapshots'][str(cert['plan']['day'])]
    verify(bundle,cert['plan'],cert['proof']);print('Independent physical/time/cash certificate PASS')


if __name__=='__main__':main()
