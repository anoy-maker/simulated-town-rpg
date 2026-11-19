"""Independent M23 native-event replay. No GDScript report/decision implementation import."""
import copy
import hashlib
import json
from collections import Counter
from brewery_feasibility import WORKERS, OWNERS, RULES, SITES, WINDOWS, certificate
from spatial_audit import route

ITEMS=('wheat','flour','bread','ale')
TRADE=dict(farm=(600,660),mill=(720,780),bakery=(900,1050),brewery=(900,1050))


def planned(o):
    """Integer forward budget, independently reconstructed from permitted observations."""
    cash=o['cash'];stock=o['output_stock'];raw=o['input_stock'];harvest=0;workers=[];lots=0
    rule=o['rule'];reason='output_target_met' if stock>=rule['target'] else 'no_eligible_worker'
    for w in o['workers']:
        if stock>=rule['target']:break
        if not w['available']:continue
        output=min(rule['make'],o['harvest_remaining']-harvest) if not rule['input'] else rule['make']
        missing=int(bool(rule['input']) and raw<rule['take'])
        cost=w['wage']+missing*rule['take']*o['input_price']
        if output<=0:reason='harvest_capacity';break
        if output*o['output_price']<=cost:reason='nonpositive_expected_contribution';break
        if cash<cost:reason='working_capital';break
        if missing and not o['allow_procurement']:reason='missing_deposited_inputs';break
        cash-=cost;raw+=missing*rule['take']-rule['take'];stock+=output
        harvest+=output if not rule['input'] else 0;workers.append(w['id']);lots+=missing;reason='positive_expected_contribution'
    return dict(workers=workers,shifts=len(workers),lots=lots,expected_receipts=(stock-o['output_stock'])*o['output_price'],committed_cash=o['cash']-cash,reason=reason)


def basket(o):
    candidates=[]
    for b in (0,1):
        for a in (0,1):
            if b>o['need_bread'] or a>o['need_ale']:continue
            if b and (o['stock'].get('bread',0)<1 or o['prices'].get('bread',10**9+1)>o['bread_ceiling']):continue
            if a and o['stock'].get('ale',0)<1:continue
            cost=b*o['prices'].get('bread',0)+a*o['prices'].get('ale',0)
            if cost<=o['money']:candidates.append((100*b+5*a+o['money']-cost,o['money']-cost,-a,-b,b,a,cost))
    value,remaining,_,_,b,a,cost=max(candidates)
    reason='positive_marginal_utility' if cost else 'allowance_used' if o['need_bread']+o['need_ale']==0 else 'no_stock' if not any(o['stock'].values()) else 'retain_cash_or_unaffordable'
    return dict(bread=b,ale=a,utility=value,remaining=remaining,cost=cost,reason=reason)


def audit(data, fixture=False, labor=None):
    binding = labor is not None and labor.BINDING
    r,events=data['report'],data['events'];initial=r['initial']
    assert events[0]['action']=='initialize' and events[0]['details']['state']==initial
    entities=copy.deepcopy(initial['entities']);firms=copy.deepcopy(initial['businesses']);jobs=copy.deepcopy(initial['employment'])
    cargo=copy.deepcopy(initial['cargo']);space=copy.deepcopy(initial['spatial']);people=space['presences']
    books=copy.deepcopy(initial['cash_results']);quotes=copy.deepcopy(initial['commodity_quotes'])
    assert set(firms)==set(OWNERS) and len(entities)==20
    assert {f:firms[f]['owner'] for f in firms}==OWNERS
    assert {f:sorted(firms[f]['employees']) for f in firms}==WORKERS
    assert sum(x['money'] for x in entities.values())==9192
    assert len([x for x in entities.values() if x['kind']=='resident'])==15
    assert {id:p['home'] for id,p in people.items()}==certificate()['homes']
    assert space['width']==10 and space['height']==7 and space['retail_close']==1050
    if not fixture:
        assert all(x['money']==(8622 if id=='visitors' else 120 if id in firms else 6) and not any(x['inventory'].values()) for id,x in entities.items())
    for f,workers in WORKERS.items():
        assert firms[f]['assets']['daily_slots']==len(workers) and firms[f]['owner_compensation']==0
        for w in workers:
            assert jobs[w]['business']==f and jobs[w]['wage']==10 and jobs[w]['contract']==dict(cycle_days=1,shifts_per_cycle=1,cycle_compensation=10,phases=[1])
            assert entities[w]['skills']==[dict(farm='farmer',mill='miller',bakery='baker',brewery='brewer')[f]] and entities[w]['labor_capacity']==1
        assets=[x for x in initial['productive_assets'].values() if x['holder']==f]
        assert {x['kind'] for x in assets}=={'workshop',dict(farm='farm_tools',mill='millstone',bakery='oven',brewery='brew_vat')[f]}
        assert all(x['capacity']==len(workers) for x in assets)
    day=0;worked=set();offered={};started={};seen={};requested={};bought=Counter();drunk=set();meals=set();attempted=set()
    due=set();closed=set();claims=set();receipts=set();pay_before={};production_claims=set();benefits=set()
    production=Counter();inputs=Counter();consumed=Counter();goods=Counter({i:sum(x['inventory'][i] for x in entities.values()) for i in ITEMS})
    accounts={id:dict(wages=0,distributions=0,sales=0,inputs=0,bread_spending=0,ale_spending=0,meals=0,missed_meals=0,ale_consumed=0,shifts=0,shifts_due=0,missed_shifts=0,produced=Counter(),purchased=Counter(),sold=Counter()) for id in entities}
    clearing_before=None;clearing_buys=[];harvested=0;circulation=0;successful=0;rejected=0;current=None;dayrows=[]
    def owned(id):return people[id]['active'] and people[id]['activity']=='idle'
    def at(id,site):return people[id]['active'] and people[id]['tile']==SITES[site]
    def staff(f):return WORKERS[f] if labor is None else labor.staff(f)
    def salary(w,f):return labor.salary(w,f) if binding and getattr(labor,'VARIABLE_WAGES',False) else 10
    def worker_available(w,f):return jobs[w]['active'] and w not in worked and owned(w) and at(w,f)
    def offered_quotes(seller):return [dict(q,available=min(q['limit'],entities[seller]['inventory'][item])) for item,q in sorted(quotes[seller].items())]
    def eligible(f):
        if f not in requested:return 0
        req=requested[f];who=req['owner'];q=req['quote'];now=quotes['farm']['wheat'];p=people[who]
        if any(q.get(k)!=v for k,v in now.items()) or not now['active'] or not at(who,'farm') or p['activity']!='procure' or p['until']!=615:return 0
        if binding:return min(req['maximum'],sum(worker_available(w,f) and w in labor.funded(f) for w in staff(f)),max(0,entities[f]['money']-labor.committed(f))//(req['lot_size']*q['unit_price']))
        return min(req['maximum'],sum(worker_available(w,f) for w in staff(f)),entities[f]['money']//(req['lot_size']*q['unit_price']+10))
    def begin_clearing():
        return (min(quotes['farm']['wheat']['limit'],entities['farm']['inventory']['wheat']) if quotes['farm']['wheat']['active'] else 0,eligible('mill'),eligible('brewery'))
    if labor is not None:
        assert r['scenario']==labor.SCENARIO
        labor.attach(r,events,entities,firms,jobs,people,quotes,cargo,books)
    for index,e in enumerate(events,1):
        assert e['id']==index
        action,actor,target,d=(e[k] for k in ('action','actor','target','details'))
        if action=='day_started':
            assert day==0 or (space['minute']==1440 and len(closed)==(11 if labor is None else len(due)))
            day+=1;space['minute']=0;worked.clear();offered.clear();started.clear();seen.clear();requested.clear();bought.clear();drunk.clear();meals.clear();attempted.clear();due.clear();closed.clear();harvested=0;clearing_before=None;clearing_buys=[]
            current=dict(day=day,production=Counter(),production_inputs=Counter(),resident_meals=0,unmet_meals=0,visitor_bread=0,visitor_bread_declined=0,ale_sold=0,ale_consumed=0,shifts_due=0,shifts=0,missed_shifts=0,circulation=0,observed_quotes=0,declines=Counter())
            current['firms']={f:dict(sales=0,inputs=0,wages=0,distributions=0,shifts=0,shifts_due=0,missed_shifts=0) for f in firms}
            current['households']={id:dict(wages=0,distributions=0,bread_spending=0,ale_spending=0,meals=0,missed_meals=0,ale_consumed=0,shifts=0,shifts_due=0,missed_shifts=0,declines={}) for id in people if people[id]['kind']=='resident'}
            current['visitors']={}
        if e['success'] and action=='spatial_clock':
            assert d['from']==space['minute'] and d['to']==d['from']+5<=1440;space['minute']=d['to']
        minute=space['minute'];absolute=max(0,day-1)*1440+minute
        assert (e['day'],e['minute'],e['absolute_minute'])==(day,minute,absolute)
        if action=='purchase':successful+=int(e['success']);rejected+=int(not e['success'])
        if action=='consume' and d.get('item')=='bread' and actor in entities and entities[actor]['kind']=='resident':
            attempted.add(actor)
            if not e['success']:
                assert d.get('reason')=='insufficient_stock' and entities[actor]['inventory']['bread']==0
                accounts[actor]['missed_meals']+=1;current['unmet_meals']+=1;current['households'][actor]['missed_meals']+=1
        if labor is not None:labor.context(day,minute,worked,due,harvested)
        if not e['success']:
            if action=='contract_shift':
                assert actor in due and actor not in worked
                if binding:labor.validate_closure(e)
                else:assert d['actual_compensation']==0
                accounts[actor]['missed_shifts']+=1;accounts[target]['missed_shifts']+=1;current['households'][actor]['missed_shifts']+=1;current['firms'][target]['missed_shifts']+=1
            if labor is not None:labor.after(e)
            continue
        if action=='spatial_departed':
            p=people[actor];expected=route(p['tile'],d['destination'])
            assert owned(actor) and expected and expected==d['route'] and minute+5*len(expected)<=d['arrive_by']<=1440
            p.update(destination=list(d['destination']),route=expected,activity='walking',until=0,last_step=absolute)
        elif action=='spatial_moved':
            p=people[actor];assert p['active'] and p['activity']=='walking' and p['tile']==d['from'] and p['route'][0]==d['to'] and absolute-p['last_step']>=5
            assert sum(abs(a-b) for a,b in zip(d['from'],d['to']))==1
            p['tile']=list(d['to']);p['route'].pop(0);p['last_step']=absolute
        elif action=='spatial_arrived':
            p=people[actor];assert p['activity']=='walking' and not p['route'] and p['tile']==p['destination']==d['tile'];p['activity']='idle'
        elif action=='spatial_stayed':assert owned(actor) and people[actor]['tile']==d['tile']
        elif action=='spatial_activity_started':
            p=people[actor];kind=d['kind'];assert owned(actor) and d['until']==minute+d['duration']<=1440
            if kind in ('work','manage'):
                assert at(actor,target) and minute==WINDOWS[target][0] and d['duration']==60
                if kind=='manage':assert OWNERS[target]==actor
                else:assert actor in staff(target) and actor not in started and actor in offered;started[actor]=target
            elif kind in ('shop','procure','deposit'):assert d['duration']==5
            elif kind=='board' and labor is not None:assert labor.mode=='matching' and minute==955 and at(actor,'bakery') and d['duration']==5
            elif kind=='standby' and binding:assert actor in staff(target) and at(actor,target) and minute==WINDOWS[target][0] and d['duration']==60
            else:assert kind=='rest' and p['tile']==p['home'] and minute>=1110 and d['until']==1440
            p.update(activity=kind,until=d['until'],business=target)
        elif action=='spatial_activity_ended':
            p=people[actor];assert p['activity']==d['kind'] and p['until']==minute
            if d['kind']=='work':assert events[d['result_event_id']-1]['action']=='work_shift' and events[d['result_event_id']-1]['actor']==actor
            p.update(activity='idle',until=0,business='')
        elif action=='spatial_visitor_entered':
            p=d['presence'];assert actor not in people and actor==f'visitor:{day:04}:{d["slot"]}' and 1<=d['slot']<=6 and minute==1020
            assert p['account']=='visitors' and p['tile']==p['home']==[9,3] and p['spent']==p['ale']==p['loaf']==0 and p['bought']==dict(bread=0,ale=0)
            people[actor]=copy.deepcopy(p);current['visitors'][actor]=dict(bread_spending=0,ale_spending=0,meals=0,ale_consumed=0,declines={})
        elif action=='spatial_visitor_exited':
            p=people[actor];assert owned(actor) and p['kind']=='visitor' and p['tile']==[9,3] and p['loaf']==p['ale']==0;p['active']=False
        elif action=='spatial_encounter':
            assert set(d)=={'kind','item','quantity','tile','witnesses'} and people[actor]['tile']==d['tile']==SITES[target]
            assert d['witnesses']==sorted(id for id,p in people.items() if p['active'] and p['tile']==d['tile'])
            if d['kind']=='inspected':
                assert owned(actor) and TRADE[target][0]<=minute<TRADE[target][1]
                seen[actor,target]=dict(day=day,minute=minute,offers=copy.deepcopy(offered_quotes(target)))
                current['observed_quotes']+=1
        elif action=='quote_revised':
            assert fixture and not binding and OWNERS[target]==actor
            q=d['quote'];assert q['version']==quotes[target][q['item']]['version']+1 and q['unit_price']>0
            quotes[target][q['item']]=copy.deepcopy(q)
        elif action=='grain_request':
            assert actor==OWNERS[target] and target in ('mill','brewery') and target not in requested and minute==610 and at(actor,'farm')
            assert 0<=d['maximum']<=len(WORKERS[target]) and type(d['maximum']) is int and d['lot_size']==(5 if target=='mill' else 3)
            assert d['quote'] in seen[actor,'farm']['offers'];requested[target]=copy.deepcopy(d)
        elif action=='purchase':
            item,qty,price=d['item'],d['quantity'],d['unit_price'];who=e['physical_actor'];p=people[who];q=quotes[target][item]
            assert type(qty) is int and qty>0 and type(price) is int and price>0 and d['total_price']==qty*price
            assert at(who,target) and TRADE[target][0]<=minute<TRADE[target][1] and p['activity'] in ('shop','procure') and p['until']>minute
            assert all(d['quote'][k]==v for k,v in q.items()) and q['active'] and price==q['unit_price'] and qty<=min(q['limit'],entities[target]['inventory'][item])
            assert d['quote']['available']==min(q['limit'],entities[target]['inventory'][item])
            observation=seen[who,target];assert observation['day']==day and observation['minute']==minute
            assert any(all(old[k]==v for k,v in q.items()) for old in observation['offers'])
            if actor in firms:
                assert OWNERS[actor]==who and d['custody']==dict(business=actor,holder=who)
                assert (actor,item,qty) in [('mill','wheat',5),('brewery','wheat',3),('bakery','flour',5)]
                if item=='wheat':
                    if clearing_before is None:clearing_before=begin_clearing()
                    clearing_buys.append(index)
                cargo[actor]['inventory'][item]+=qty;books[actor]['inputs']+=qty*price;accounts[actor]['inputs']+=qty*price;current['firms'][actor]['inputs']+=qty*price
            else:
                assert item in ('bread','ale') and qty==1
                if actor=='visitors':
                    assert p['kind']=='visitor' and p['active'] and p['bought'][item]==0 and p['spent']+price<=10 and (item!='bread' or price<=6)
                    p['bought'][item]+=1;p['spent']+=price
                    if item=='bread':p['purchased']=True;p['loaf']+=1;current['visitor_bread']+=1
                    else:p['ale']+=1
                    person=current['visitors'][who]
                else:
                    assert actor==who and bought[actor,item]==0 and (item!='bread' or (actor not in meals and entities[actor]['inventory']['bread']==0))
                    bought[actor,item]+=1;person=current['households'][actor]
                entities[actor]['inventory'][item]+=qty;accounts[actor][item+'_spending']+=price;person[item+'_spending']+=price
            entities[actor]['money']-=qty*price;entities[target]['money']+=qty*price;entities[target]['inventory'][item]-=qty
            books[target]['sales']+=qty*price;accounts[target]['sales']+=qty*price;current['firms'][target]['sales']+=qty*price
            accounts[actor]['purchased'][item]+=qty;accounts[target]['sold'][item]+=qty;circulation+=qty*price;current['circulation']+=qty*price
            if item=='ale':current['ale_sold']+=qty
        elif action=='grain_cleared':
            assert actor=='ada' and target=='farm' and at(actor,'farm') and owned(actor) and minute==610
            grain,m,b=clearing_before or begin_clearing()
            assert d['available']==grain and d['eligible']==dict(mill=m,brewery=b)
            used,mm,bb=max((5*i+3*j,i,j) for i in range(m+1) for j in range(b+1) if 5*i+3*j<=grain)
            assert d['allocation']==dict(mill=mm,brewery=bb,grain=used,revenue=used*quotes['farm']['wheat']['unit_price'])
            assert d['purchase_event_ids']==clearing_buys and all(events[x-1]['success'] for x in clearing_buys)
            assert Counter(events[x-1]['actor'] for x in clearing_buys)==Counter({k:v for k,v in [('mill',mm),('brewery',bb)] if v})
            current.update(grain_available=grain,grain_allocation=dict(mill=5*mm,brewery=3*bb),grain_residual=grain-used)
        elif action=='spatial_deposited':
            assert actor==OWNERS[target] and at(actor,target) and people[actor]['activity']=='deposit' and people[actor]['until']==minute+5
            assert d['goods']==cargo[target]['inventory']
            for item in ITEMS:entities[target]['inventory'][item]+=d['goods'][item];cargo[target]['inventory'][item]=0
        elif action=='shift_offered':
            w=d['offer']['worker'];assert OWNERS[target]==actor and w in staff(target) and owned(w) and at(w,target) and w not in worked
            assert d['offer']['wage']==salary(w,target) and d['offer']['day']==day and d['offer']['status']=='offered';offered[w]=copy.deepcopy(d['offer'])
        elif action=='transfer_money':
            assert type(d['amount']) is int and d['amount']>0 and d['purpose'] in ('wage','distribution') and actor in firms
            pay_before[index]=(entities[actor]['money'],copy.deepcopy(books[actor]))
            if d['purpose']=='wage':
                if binding:labor.validate_payment(e)
                else:
                    p=people[target];assert e['physical_actor']==target and target in staff(actor) and target not in worked and p['activity']=='work' and p['until']==minute==WINDOWS[actor][1] and at(target,actor) and d['amount']==10
                field='wages';books[actor]['payroll']+=d['amount']
            else:
                assert OWNERS[actor]==target and minute==1140 and len(attempted)==15
                if binding:assert labor.arrears(actor)==0
                field='distributions';books[actor]['distributions']+=d['amount']
            entities[actor]['money']-=d['amount'];entities[target]['money']+=d['amount'];accounts[target][field]+=d['amount'];current['firms'][actor][field]+=d['amount'];current['households'][target][field]+=d['amount'];receipts.add(index)
            circulation+=d['amount'];current['circulation']+=d['amount']
        elif action in ('harvest','produce'):
            who=e['physical_actor'];p=people[who];assert who in staff(actor) and started[who]==actor and p['activity']=='work' and p['until']==minute==WINDOWS[actor][1] and at(who,actor)
            take,make=copy.deepcopy(RULES[actor])
            if action=='harvest':
                assert actor=='farm';amount=min(7,initial['brewery']['supply_cap']-harvested);assert d['amount']==amount>0;make={'wheat':amount};harvested+=amount
            else:
                assert d['inputs']==take and d['outputs']==make and d['batches']==1 and d['recipe']==dict(mill='mill',bakery='bake',brewery='brew')[actor]
            for item,n in take.items():entities[actor]['inventory'][item]-=n;goods[item]-=n;inputs[item]+=n;current['production_inputs'][item]+=n
            for item,n in make.items():entities[actor]['inventory'][item]+=n;goods[item]+=n;production[item]+=n;current['production'][item]+=n;accounts[actor]['produced'][item]+=n
            receipts.add(index)
        elif action=='work_shift':
            assert actor in started and started[actor]==target and actor not in worked and d['wage']==salary(actor,target) and d['labor']==1
            pay,out=d['payment_event_id'],d['production_event_id'];assert out==index-1 and out not in claims
            if binding:labor.validate_productive(e)
            else:assert pay==index-2 and pay not in claims
            assert events[pay-1]['action']=='transfer_money' and events[pay-1]['actor']==target and events[pay-1]['target']==actor and events[pay-1]['details']['purpose']=='wage'
            assert events[out-1]['actor']==target and events[out-1]['action'] in ('harvest','produce')
            claims.update([pay,out]);worked.add(actor);production_claims.add(out);offered[actor]['status']='accepted'
            accounts[actor]['shifts']+=1;accounts[target]['shifts']+=1;current['shifts']+=1;current['firms'][target]['shifts']+=1;current['households'][actor]['shifts']+=1
        elif action=='consume':
            item=d['item'];assert item in ('bread','ale') and d['amount']==1
            who=e['physical_actor'];p=people[who]
            if actor=='visitors':
                assert p['kind']=='visitor' and owned(who) and at(who,'bakery' if item=='bread' else 'brewery')
                key='loaf' if item=='bread' else 'ale';assert p[key]==1;p[key]-=1;person=current['visitors'][who]
            else:
                assert who==actor and owned(actor)
                if item=='bread':assert p['tile']==p['home'] and 1110<=minute<1140 and actor not in meals;meals.add(actor);current['resident_meals']+=1
                else:assert at(actor,'brewery') and actor not in drunk
                person=current['households'][actor]
            entities[actor]['inventory'][item]-=1;goods[item]-=1;consumed[item]+=1
            field='meals' if item=='bread' else 'ale_consumed';accounts[actor][field]+=1;person[field]+=1
            if item=='ale':current['ale_consumed']+=1;benefits.add(index)
        elif action=='discretionary_benefit':
            receipt=d['consumption_event_id'];assert actor not in drunk and d['benefit']==5 and receipt==index-1 and receipt in benefits and receipt not in claims
            assert events[receipt-1]['action']=='consume' and events[receipt-1]['details']['item']=='ale' and events[receipt-1]['physical_actor']==actor;claims.add(receipt);drunk.add(actor)
        elif action=='profit_distribution':
            pay=d['payment_event_id'];assert pay==index-1 and pay not in claims and events[pay-1]['actor']==target and events[pay-1]['target']==actor and OWNERS[target]==actor
            cash,book=pay_before[pay];retained=book['sales']-book['inputs']-book['payroll']-book['distributions']
            assert d['amount']==min(max(0,retained),max(0,cash-120))>0 and d['policy']==dict(mode='full',reserve=120) and d['cumulative_before']==book
            claims.add(pay)
        elif action=='contract_due':
            assert actor in staff(target) and actor not in due and d['expected_compensation']==salary(actor,target) and d['phase']==1;due.add(actor);current['shifts_due']+=1
            accounts[actor]['shifts_due']+=1;accounts[target]['shifts_due']+=1;current['households'][actor]['shifts_due']+=1;current['firms'][target]['shifts_due']+=1
        elif action=='contract_attempt':
            command=events[d['command_event_id']-1];assert OWNERS[target]==actor and d['worker'] in staff(target) and command['action']=='shift_offered'
        elif action=='contract_shift':
            assert actor in due and actor not in closed and actor in worked and d['completed'] and d['actual_compensation']==salary(actor,target)
            if binding:labor.validate_closure(e)
            assert events[d['shift_event_id']-1]['action']=='work_shift' and events[d['shift_event_id']-1]['actor']==actor;closed.add(actor)
        elif action=='contract_day_closed':
            # Breaches are failed annotation events, counted below from completed native work.
            expected_due=11 if labor is None else len(labor.active_workers())
            assert d['due']==len(due)==expected_due and d['completed']==len(worked) and d['breaches']==(labor.breach_count() if binding else expected_due-len(worked))
            if binding:assert d['unutilized']==expected_due-len(worked)
            current['missed_shifts']=d.get('unutilized',d['breaches']);closed=set(due)
            assert d['cash_results']==books and d['business_cash']=={f:entities[f]['money'] for f in firms}
            assert d['household_cash']=={id:e['money'] for id,e in entities.items() if e['kind']=='resident'} and d['external_cash']=={'visitors':entities['visitors']['money']}
            assert d['goods']=={i:sum(x['inventory'][i] for x in entities.values())+sum(x['inventory'][i] for x in cargo.values()) for i in ITEMS}
            current['external_cash']=entities['visitors']['money'];current['currency']=9192
            for f,row in current['firms'].items():row.update(cash=entities[f]['money'],inventory=copy.deepcopy(entities[f]['inventory']),operating_surplus=row['sales']-row['inputs']-row['wages'])
            for id,row in current['households'].items():row.update(cash=entities[id]['money'],inventory=copy.deepcopy(entities[id]['inventory']))
            for key in ('production','production_inputs'):current[key]={i:current[key][i] for i in ITEMS}
            assert current==r['day_results'][day-1],(day,'day report mismatch')
            dayrows.append(copy.deepcopy(current))
        elif action=='business_plan':
            o=d['observation'];f=target;rule=o['rule'];assert o['owner']==actor==OWNERS[f] and o['cash']==entities[f]['money'] and o['day']==day
            assert set(o)=={'owner','business','day','rule','cash','output_stock','input_stock','output_price','input_price','input_quote','allow_procurement','harvest_remaining','workers'}|({'committed_payroll','funded_workers'} if binding else set())
            if binding:assert o['committed_payroll']==labor.committed(f) and o['funded_workers']==labor.funded(f)
            assert o['output_stock']==entities[f]['inventory'][rule['output']] and o['output_price']==quotes[f][rule['output']]['unit_price']
            assert o['harvest_remaining']==(initial['brewery']['supply_cap']-harvested if f=='farm' else 0)
            take,make=RULES[f];raw_item=next(iter(take),'');out_item=next(iter(make))
            assert rule==dict(output=out_item,input=raw_item,recipe=dict(farm='',mill='mill',bakery='bake',brewery='brew')[f],batches=int(f!='farm'),target=len(WORKERS[f])*make[out_item],take=take.get(raw_item,0),make=make[out_item])
            raw=rule['input'];assert o['input_stock']==(entities[f]['inventory'][raw]+(cargo[f]['inventory'][raw] if d['phase']=='procurement' else 0) if raw else 0)
            candidates=[dict(id=w,wage=salary(w,f),available=worker_available(w,f)) for w in staff(f)]
            assert o['workers']==(candidates if labor is None else labor.ordered(candidates,day))
            if raw:
                old=seen.get((actor,'farm' if raw=='wheat' else 'mill'),{}).get('offers',[])
                assert o['input_quote']==(old[0] if old else {}) and o['input_price']==(old[0]['unit_price'] if old else 0)
            expected=labor.within(o) if binding else planned(o)
            if r['condition']=='no_brew_request' and f=='brewery' and d['phase']=='procurement':expected.update(lots=0,reason='control_no_brew_request')
            assert expected==d['proposal']
        elif action=='consumer_decision':
            o=d['observation'];p=people[actor];visitor=p['kind']=='visitor';account=p['account'];old=seen[actor,target]
            # Observation is taken before this decision's optional native purchase.
            cost=events[d['command_event_id']-1]['details']['total_price'] if d['command_event_id'] else 0
            assert o['buyer']==actor and o['day']==day and o['minute']==minute and o['offers']==old['offers']
            before_money=entities[account]['money']+cost
            assert o['money']==(min(10-(p['spent']-cost),before_money) if visitor else before_money)
            assert set(o)=={'buyer','day','minute','money','need_bread','need_ale','bread_ceiling','prices','stock','offers'}
            qty=d['purchased'];bread_qty=qty if d['item']=='bread' else 0;ale_qty=qty if d['item']=='ale' else 0
            if visitor:
                assert o['need_bread']==int(p['bought']['bread']-bread_qty==0 and p['loaf']-bread_qty==0)
                assert o['need_ale']==int(p['bought']['ale']-ale_qty==0)
            else:
                assert o['need_bread']==int(actor not in meals and entities[actor]['inventory']['bread']-bread_qty==0 and bought[actor,'bread']-bread_qty==0)
                assert o['need_ale']==int(actor not in drunk and entities[actor]['inventory']['ale']-ale_qty==0 and bought[actor,'ale']-ale_qty==0)
            assert o['bread_ceiling']==(6 if visitor else 10**9)
            assert o['prices']=={q['item']:q['unit_price'] for q in old['offers'] if q['active']} and o['stock']=={q['item']:q['available'] for q in old['offers'] if q['active']}
            assert d['proposal']==basket(o) and d['purchased']==d['proposal'][d['item']]
            if d['command_event_id']:
                cmd=events[d['command_event_id']-1];assert cmd['success'] and cmd['action']=='purchase' and cmd['physical_actor']==actor and cmd['details']['item']==d['item']
            if d['purchased']==0:
                current['declines'][d['item']+':'+d['proposal']['reason']]+=1
                if visitor:
                    current['visitors'][actor]['declines'][d['item']]=d['proposal']['reason']
                    if d['item']=='bread':current['visitor_bread_declined']+=1
                else:current['households'][actor]['declines'][d['item']]=d['proposal']['reason']
        elif labor is not None and action in labor.ACTIONS:labor.apply(e)
        else:assert action in ('initialize','day_started','spatial_clock','spatial_shop_closed','labor_environment'),('unrecognized successful event',action)
        if labor is not None:labor.after(e)
        assert sum(x['money'] for x in entities.values())==9192
        assert all(type(x['money']) is int and 0<=x['money']<=10**9 and set(x['inventory'])==set(ITEMS) and all(type(n) is int and 0<=n<=10**9 for n in x['inventory'].values()) for x in entities.values())
        for item in ITEMS:assert goods[item]==sum(x['inventory'][item] for x in entities.values())+sum(x['inventory'][item] for x in cargo.values())
        assert all(0<=p['tile'][0]<10 and 0<=p['tile'][1]<7 for p in people.values())
        assert all(0<=p['spent']<=10 and 0<=p['bought']['bread']<=1 and 0<=p['bought']['ale']<=1 for p in people.values() if p['kind']=='visitor')
        for item,key in [('bread','loaf'),('ale','ale')]:assert entities['visitors']['inventory'][item]==sum(p[key] for p in people.values() if p['kind']=='visitor')
    if binding:claims.update(labor.wage_receipts)
    assert receipts|benefits==claims and entities==r['final']['entities'] and books==r['final']['cash_results'] and cargo==r['final']['cargo'] and space==r['final']['spatial']
    assert initial['productive_assets']==r['final']['productive_assets'] and quotes==r['final']['commodity_quotes'] and jobs==r['final']['employment']
    assert r['totals']==dict(produced={i:production[i] for i in ITEMS},inputs={i:inputs[i] for i in ITEMS},consumed={i:consumed[i] for i in ITEMS})
    for id,a in accounts.items():
        a.update(cash=entities[id]['money'],inventory=entities[id]['inventory'])
        for key in ('produced','purchased','sold'):a[key]={i:a[key][i] for i in ITEMS}
        if labor is not None and entities[id]['kind']=='resident':a['employer']=labor.affiliations.get(id,{}).get('business','')
        assert a==r['accounts'][id],(id,'account report mismatch')
    assert r['money']==dict(initial=9192,final=9192,circulation=circulation) and r['purchases']==dict(successful=successful,rejected=rejected)
    assert hashlib.sha256(json.dumps(events,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()==r['ledger_sha256']
    if labor is not None:labor.finish()
    return dict(events=len(events),days=day,money=9192,financial_spatial_goods_and_decisions=True)
