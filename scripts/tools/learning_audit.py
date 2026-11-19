"""Independent math/permission audit. Only post-run tooling sees the full ledger."""
import copy,math
from functools import lru_cache
from spatial_audit import audit as physical_audit
PRIOR=(.8/12,)*12+(.2,)
COHORTS=('local','visitor')
def fresh():return {c:dict(alpha=[.25]*13,weights=list(PRIOR)) for c in COHORTS}
def hazard(b):return {c:dict(alpha=x['alpha'][:],weights=[.98*w+.02*p for w,p in zip(x['weights'],PRIOR)]) for c,x in b.items()}
def q(h,p):return (.9 if p<=h+1 else .1) if h<12 else max(.1,min(.9,.8-.075*(p-4)))
@lru_cache(None)
def bb(h,p,n):
    a=2*q(h,p);b=2-a
    logbeta=lambda x,y:math.lgamma(x)+math.lgamma(y)-math.lgamma(x+y)
    return tuple(math.exp(math.lgamma(n+1)-math.lgamma(s+1)-math.lgamma(n-s+1)+logbeta(s+a,n-s+b)-logbeta(a,b)) for s in range(n+1))
def update(b,obs,p,complete):
    b=copy.deepcopy(b)
    for c in COHORTS:
        o=obs[c]
        if complete:b[c]['alpha'][min(12,o['arrivals'])]+=1
        if not o['eligible'] or o['censored'] or o.get('unresolved',0):continue
        weights=[w*bb(h,p,o['eligible'])[o['sales']] for h,w in enumerate(b[c]['weights'])]
        b[c]['weights']=[w/sum(weights) for w in weights]
    return b

def near(a,b,tol=1e-8):
    if isinstance(a,dict):
        assert set(a)==set(b),(set(a),set(b))
        for k in a:near(a[k],b[k],tol)
    elif isinstance(a,(list,tuple)):
        assert len(a)==len(b)
        for x,y in zip(a,b):near(x,y,tol)
    elif isinstance(a,(int,float)) and not isinstance(a,bool):assert abs(a-b)<=tol*max(1,abs(a),abs(b)),(a,b)
    else:assert a==b,(a,b)

@lru_cache(None)
def components(alpha,p,carry,minimum):
    total=sum(alpha[minimum:]);out=[]
    for h in range(13):
        row=[0.]*13
        for n in range(minimum,13):
            for s,prob in enumerate(bb(h,p,min(12,n+carry))):row[s]+=alpha[n]/total*prob
        out.append(row)
    return out

def demand(b,p,carry=3,minimum=(0,0)):
    out=[]
    for ci,c in enumerate(COHORTS):
        parts=components(tuple(b[c]['alpha']),p,carry if ci==0 else 0,minimum[ci])
        out.append([sum(w*parts[h][s] for h,w in enumerate(b[c]['weights'])) for s in range(13)])
    return out

def sales(pmf,stock):
    out=[0.]*(min(24,stock)+1)
    for l,lp in enumerate(pmf[0]):
        for v,vp in enumerate(pmf[1]):out[min(stock,l+v)]+=lp*vp
    return out

def operate(state,procure,supply=12):
    cash,flour,bread,retained=state
    inputs=min(12,supply,int((cash+1e-9)/4)) if procure else 0
    cash-=inputs*4;flour+=inputs;retained-=inputs*4
    shifts=min(3,int((cash+1e-9)/6),int((flour+1e-9)/4))
    return dict(state=[cash-6*shifts,flour-4*shifts,bread+6*shifts,retained-6*shifts],inputs=inputs,shifts=shifts)
def close(state,p,sold):
    cash,flour,bread,retained=state;sold=min(bread,sold)
    cash+=p*sold;bread-=sold;retained+=p*sold
    payout=max(0,min(retained,cash-120))
    return dict(state=[cash-payout,flour,bread,retained-payout],payout=payout)
def forecasts(b,prices,carry):
    result={p:[] for p in prices}
    for t in range(13):
        b=hazard(b)
        for p in prices:result[p].append(demand(b,p,carry))
    return result

def continuation(state,p,pmfs,supply):
    first=operate(state,True,supply)['state'];value=0
    for sold,prob in enumerate(sales(pmfs[0],int(first[2]))):
        if prob<1e-12:continue
        result=close(first,p,sold);branch=result['payout'];s=result['state']
        for t in range(1,13):
            s=operate(s,True,supply)['state']
            expected=sum(min(s[2],l+v)*lp*vp for l,lp in enumerate(pmfs[t][0]) for v,vp in enumerate(pmfs[t][1]))
            result=close(s,p,expected);s=result['state'];branch+=.99**t*result['payout']
        value+=prob*(branch+.99**12*s[0])
    return value

def outcomes(b,c,p,stock,carry,minimum):
    merged={};total=sum(b[c]['alpha'][minimum:])
    def add(n,e,s,censored,prob):
        key=(s,n,e,censored)
        merged[key]=merged.get(key,0)+prob
    for n in range(minimum,13):
        m=min(12,n+carry)
        for h,w in enumerate(b[c]['weights']):
            weight=b[c]['alpha'][n]/total*w
            for sold in range(min(stock,m)+1):
                if sold==stock and stock<m:continue
                add(n,m,sold,False,weight*bb(h,p,m)[sold])
            if stock<m:
                if stock==0:add(n,0,0,m>0,weight)
                else:
                    for k in range(stock,m+1):add(n,k,stock,k<m,weight*bb(h,p,k)[stock]*stock/k)
    return [dict(arrivals=n,eligible=e,sales=s,censored=c,probability=prob) for (s,n,e,c),prob in sorted(merged.items())]

def quadrature(out):
    result=[]
    for target in (1/6,1/2,5/6):
        cumulative=0
        for o in out:
            cumulative+=o['probability']
            if cumulative>=target-1e-14:
                result.append(dict(o,probability=1/3));break
    return result

def candidate_prices(current,posted):return sorted(set([current,max(1,current-1),min(12,current+1)]+[p for p in posted if p<current]))
def best(values,current):
    chosen=current;value=-math.inf
    for p,v in values.items():
        if v>value+1e-9 or (abs(v-value)<=1e-9 and (p==current or (chosen!=current and p<chosen))):chosen=p;value=v
    return chosen

# Raw-memory reconstruction uses only personally witnessed public events and own receipts.
def rebuild(data):
    r,events=data['report'],data['events'];firms=r['initial']['businesses']
    state=copy.deepcopy(r['initial']);records={f['owner']:[] for f in firms.values()};current={};pending={}
    def blank():return dict(arrivals=0,inspections=0,eligible=0,sales=0,purchases=0,declines=0,stock_limited=0,closed=0,unresolved=0,censored=False,events=[])
    for e in events:
        a,t,d=e['actor'],e['target'],e['details'];action=e['action'];people=state['spatial']['presences'];minute=e['minute']
        if action=='day_started':
            current={owner:dict(day=e['day'],business=b,price=state['commodity_quotes'][b][next(iter(state['commodity_quotes'][b]))]['unit_price'],local=blank(),visitor=blank(),coverage=0,accounting=dict(sold=0,revenue=0,inputs=0,payroll=0,distributions=0,stockout_requests=0),receipts=[],public_quotes=[]) for b,f in firms.items() for owner in [f['owner']]};pending={}
        if action=='spatial_clock' and 900<=minute<1035:
            sites={'farm':[6,1],'mill':[6,3],'bakery':[8,3]}
            for owner,record in current.items():
                if people[owner]['active'] and people[owner]['tile']==sites[record['business']]:record['coverage']+=1
        if e['success'] and action=='spatial_moved':people[a]['tile']=d['to'][:]
        if e['success'] and action=='spatial_visitor_entered':people[a]=copy.deepcopy(d['presence'])
        if e['success'] and action=='spatial_visitor_exited':people[a]['active']=False
        if e['success'] and action=='quote_revised':
            assert a=='cora' and t=='bakery' and d['quote']['item']=='bread' and minute==745
            assert d['quote']['unit_price']==r['learning']['decisions'][e['day']-1]['proposal']['selected_price']
            state['commodity_quotes'][t]['bread']=copy.deepcopy(d['quote']);current['cora']['price']=d['quote']['unit_price']
        if e['success'] and action in ('purchase','transfer_money'):
            for owner,record in current.items():
                b=record['business'];acc=record['accounting'];accounted=False
                if action=='purchase':
                    if t==b:acc['sold']+=d['quantity'];acc['revenue']+=d['total_price'];accounted=True
                    if a==b:acc['inputs']+=d['total_price'];accounted=True
                elif a==b and d['purpose'] in ('wage','distribution'):acc['payroll' if d['purpose']=='wage' else 'distributions']+=d['amount'];accounted=True
                if accounted:record['receipts'].append(e['id'])
        if not e['success'] and action=='purchase' and d.get('reason')=='insufficient_stock':
            for record in current.values():
                if t==record['business']:record['accounting']['stockout_requests']+=d['quantity']
        if e['success'] and action in ('purchase','transfer_money'):
            amount=d['total_price'] if action=='purchase' else d['amount']
            state['entities'][a]['money']-=amount;state['entities'][t]['money']+=amount
            if action=='purchase':
                if a in firms:state['cash_results'][a]['inputs']+=amount
                if t in firms:state['cash_results'][t]['sales']+=amount
            elif a in firms:state['cash_results'][a]['payroll' if d['purpose']=='wage' else 'distributions']+=amount
        if e['success'] and action=='purchase':
            inv=state['cargo'][a]['inventory'] if a in firms else state['entities'][a]['inventory']
            state['entities'][t]['inventory'][d['item']]-=d['quantity'];inv[d['item']]+=d['quantity']
        if e['success'] and action=='produce':
            for item,amount in d['inputs'].items():state['entities'][a]['inventory'][item]-=amount
            for item,amount in d['outputs'].items():state['entities'][a]['inventory'][item]+=amount
        if e['success'] and action=='harvest':state['entities'][a]['inventory'][d['item']]+=d['amount']
        if e['success'] and action=='spatial_deposited':
            for item,amount in d['goods'].items():state['entities'][t]['inventory'][item]+=amount;state['cargo'][t]['inventory'][item]-=amount
        if e['success'] and action=='consume':state['entities'][a]['inventory'][d['item']]-=d['amount']
        if e['success'] and action=='spatial_deposited' and a=='cora' and minute==745:
            decision=r['learning']['decisions'][e['day']-1];o=decision['observation'];f=state['entities']['bakery'];book=state['cash_results']['bakery']
            near(o['state'],[f['money'],f['inventory']['flour'],f['inventory']['bread'],book['sales']-book['inputs']-book['payroll']-book['distributions']])
            consultations=[x for x in current['cora']['public_quotes'] if x['seller']=='mill']
            quote=consultations[-1]['offers'] if consultations else []
            assert o['supply']==min(12,quote[0]['available']) if quote else o['supply']==0
            assert o['minimum']==[current['cora']['local']['arrivals'],current['cora']['visitor']['arrivals']]
            onsite=sum(p['active'] and p['tile']==[8,3] for id,p in people.items() if not id.startswith('visitor:'))
            assert o['carry']==max(0,onsite-current['cora']['local']['arrivals'])
        if action=='spatial_encounter':
            for owner,record in current.items():
                if owner not in d['witnesses']:continue
                if owner==a and d['kind']=='inspected':
                    offers=[]
                    for quote in state['commodity_quotes'][t].values():
                        quote=copy.deepcopy(quote);quote['available']=min(quote['limit'],state['entities'][t]['inventory'][quote['item']]);offers.append(quote)
                    record['public_quotes'].append(dict(event=e['id'],seller=t,offers=offers))
                if t!=record['business']:continue
                c='visitor' if a.startswith('visitor:') else 'local';obs=record[c];obs['events'].append(e['id']);key=(owner,a)
                if d['kind']=='arrived':obs['arrivals']+=1
                if d['kind']=='closed_attempt':obs['closed']+=1;obs['censored']=True
                if d['kind']=='inspected':
                    obs['inspections']+=1;quote=next(iter(state['commodity_quotes'][t].values()));eligible=quote['active'] and min(quote['limit'],state['entities'][t]['inventory'][quote['item']])>0
                    pending[key]=(c,eligible)
                    if eligible:obs['eligible']+=1
                    else:obs['stock_limited']+=1;obs['censored']=True
                if d['kind'] in ('purchased','declined'):
                    obs['purchases' if d['kind']=='purchased' else 'declines']+=1
                    if key in pending:
                        if pending[key][1]:obs['sales']+=d['quantity']
                        del pending[key]
        if action=='spatial_clock' and minute==1440:
            for (owner,_),(c,eligible) in pending.items():
                if eligible:current[owner][c]['unresolved']+=1
            for owner,record in current.items():
                record['complete']=record['coverage']==27 if owner=='cora' else False
                business=record['business']
                record['cash']=state['entities'][business]['money']
                record['inventory']=copy.deepcopy(state['entities'][business]['inventory'])
                record['book']=copy.deepcopy(state['cash_results'][business])
                records[owner].append(copy.deepcopy(record))
    return records

def verify_planning(o,b,proposal,stage,check_values=True):
    current=o['current_price'];posted=o['posted'];selected=proposal['selected_price']
    assert proposal['information_evaluated']==(stage=='D')
    prices=candidate_prices(current,posted);assert [row['price'] for row in proposal['candidates']]==prices
    operated=operate(o['state'],False);near(operated,proposal['today'])
    for row in proposal['candidates']:
        p=row['price'];near(sales(demand(b,p,o['carry'],o['minimum']),int(operated['state'][2])),row['sales_pmf'])
        ordinary=informed=0;next_prices=candidate_prices(p,posted+[p]);frozen=forecasts(b,next_prices,o['carry'])
        expected=[]
        for l in quadrature(outcomes(b,'local',p,int(operated['state'][2]),o['carry'],o['minimum'][0])):
            for v in quadrature(outcomes(b,'visitor',p,int(operated['state'][2])-l['sales'],0,o['minimum'][1])):expected.append((l,v))
        assert len(expected)==len(row['branches'])
        for branch,(el,ev) in zip(row['branches'],expected):
            l,v=branch['local'],branch['visitor'];near(l,el);near(v,ev);near(branch['probability'],1/9)
            closing=close(operated['state'],p,l['sales']+v['sales']);near(closing['state'],branch['state']);near(closing['payout'],branch['payout'])
            assert l['sales']+v['sales']<=operated['state'][2]
            if check_values:
                old={a:continuation(closing['state'],a,frozen[a],o['supply']) for a in next_prices};assert best(old,p)==branch['frozen_price']
                posterior=update(b,{'local':l,'visitor':v},p,True);updated=forecasts(posterior,next_prices,o['carry'])
                unadapted=continuation(closing['state'],branch['frozen_price'],updated[branch['frozen_price']],o['supply']);near(unadapted,branch['unadapted_value'])
                if stage=='D':
                    values={a:continuation(closing['state'],a,updated[a],o['supply']) for a in next_prices};assert best(values,p)==branch['adaptive_price'];near(max(values.values()),branch['adaptive_value'])
            if stage=='C':
                assert branch['adaptive_price']==branch['frozen_price']
                near(branch['adaptive_value'],branch['unadapted_value'])
            assert branch['adaptive_value']>=branch['unadapted_value']-1e-7
            ordinary+=branch['probability']*(closing['payout']+.99*branch['unadapted_value'])
            informed+=branch['probability']*(closing['payout']+.99*branch['adaptive_value'])
        near(ordinary,row['ordinary']);near(informed,row['informed']);near(max(0,informed-ordinary),row['evsi'])
    values={row['price']:row['informed' if stage=='D' else 'ordinary'] for row in proposal['candidates']};assert selected==best(values,current)

def audit(data,check_values=True):
    physical_audit(data)
    r=data['report'];learning=r['learning'];memory=learning['memory']
    assert learning['stage'] in ('A','B','C','D')
    if r['final']['day']==0:
        assert not memory and not learning['decisions']
        near(learning['beliefs'],fresh())
        return True
    assert len(learning['decisions'])==r['final']['day']==len(memory['cora'])
    assert all(len(records)==r['final']['day'] for records in memory.values())
    near(rebuild(data),memory)
    for group in ('accounting','spatial'):assert all(r['profitable']['verification'][group].values())
    assert r['money']['final']==9192
    b=fresh();posted=[4];current=4
    for i,decision in enumerate(learning['decisions']):
        b=hazard(b);near(b,decision['beliefs'])
        o=decision['observation'];proposal=decision['proposal'];assert decision['success']
        assert decision['day']==o['day']==i+1
        assert o['posted']==posted and o['current_price']==current and o['input_price']==4
        assert set(o)=={'day','current_price','posted','state','supply','input_price','carry','minimum'}
        selected=proposal['selected_price']
        if learning['stage']=='A':assert selected==4
        if learning['stage']=='B':
            recent=memory['cora'][i-1]['accounting'] if i else dict(sold=18,stockout_requests=0)
            candidates=[]
            for p in sorted(set((max(1,current-1),current,min(1000000000,current+1)))):
                demand_est=max(0,min(int(o['state'][2])+18,recent['sold']+recent['stockout_requests']+current-p))
                candidates.append(dict(price=p,demand=demand_est,revenue=p*demand_est,operating_cash=p*demand_est-66))
            near(candidates,proposal['candidates'])
            assert selected==best({row['price']:row['operating_cash'] for row in candidates},current)
        if learning['stage'] in 'CD':verify_planning(o,b,proposal,learning['stage'],check_values)
        if selected not in posted:posted.append(selected)
        current=selected
        day=memory['cora'][i];assert day['price']==selected
        b=update(b,day,selected,day['complete'])
    near(b,learning['beliefs'])
    for c in COHORTS:
        assert all(0<=w<=1 for w in learning['beliefs'][c]['weights'])
        near(sum(learning['beliefs'][c]['weights']),1)
    return True
