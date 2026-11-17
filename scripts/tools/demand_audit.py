"""Independent M26 seller evidence replay layered on unchanged M25 authority audit.

Private household state is consulted here solely to audit that a public request
was genuine. Only whitelisted public book records reach the reconstructed planner.
"""
import copy
from collections import Counter
from binding_audit import BindingAudit
from brewery_audit import audit as replay, basket, TRADE
from brewery_feasibility import OWNERS, SITES

ARMS=('legacy_instrumented','sales_smoothed','requests_smoothed')
PRODUCT=dict(farm='wheat',mill='flour',bakery='bread',brewery='ale')
TARGET=dict(farm=21,mill=15,bakery=21,brewery=12)


class DemandAudit(BindingAudit):
    SCENARIO='settlement_demand_observation'
    ACTIONS=BindingAudit.ACTIONS|{'demand_customer_intent','demand_order_observed','demand_day_closed','demand_forecast'}

    def validate_initial_jobs(self,initial,jobs):
        label=initial.get('demand_fixture')
        if label is None:return super().validate_initial_jobs(initial,jobs)
        assert label in ('poor_visitors','cashless_buyers','remote_farm','duplicate')
        normalized=copy.deepcopy(initial)
        for who,e in initial['entities'].items():
            cash=8622 if who=='visitors' else 120 if who in OWNERS else 6
            stock=dict.fromkeys(PRODUCT.values(),0)
            if label=='poor_visitors':
                if who=='visitors':cash=0
                if who=='ada':cash+=8622
            if label=='cashless_buyers':
                if who in ('mill','brewery'):cash=0
                if who=='visitors':cash+=240
                if who=='farm':stock['wheat']=21
            assert e['money']==cash and e['inventory']==stock
            normalized['entities'][who]['money']=8622 if who=='visitors' else 120 if who in OWNERS else 6
            normalized['entities'][who]['inventory']=dict.fromkeys(PRODUCT.values(),0)
        super().validate_initial_jobs(normalized,jobs)

    def attach(self,*args):
        super().attach(*args)
        initial=self.r['initial']['demand_observations'];self.arm=initial['arm'];assert self.arm in ARMS
        assert initial==dict(arm=self.arm,live={},days=[],orders={},points={},forecasts=[])
        self.live={};self.days=[];self.orders={};self.points={};self.forecasts=[]
        self.inspections={};self.intents={};self.failed_requests=set();self.ordered_receipts=set()
        self.retail_bought=Counter();self.eaten=set();self.drank=set();self.grain={}

    def witness(self,b):
        w=OWNERS[b];p=self.people[w]
        return w if p['active'] and p['tile']==SITES[b] and p['activity']!='walking' else ''

    def _capture_vacancy(self,b):
        o=super()._capture_vacancy(b)
        # Remote-courier fixture has no inspected input quote at all. Unknown
        # input terms cannot authorize the inherited procurement projection.
        p=o['production'];p['allow_procurement']=not p['rule']['input'] or bool(p['input_quote'])
        if self.arm!='legacy_instrumented':
            assert self.minute in (955,1440) and b in self.points
            o['previous_sales']=self.points[b]
        return o

    def quote(self,b):
        q=self.quotes[b][PRODUCT[b]]
        return dict(q,available=min(q['limit'],self.entities[b]['inventory'][PRODUCT[b]]))

    def intent_quantity(self,who,b,q):
        p=self.people[who];visitor=p['kind']=='visitor';money=self.entities[p['account']]['money']
        item=PRODUCT[b];key=f'{self.day:04}:{who}:{b}:{item}:{q["version"]}'
        if key in self.orders or not q['active']:return 0
        o=dict(money=min(10-p['spent'],money) if visitor else money,
               need_bread=int(p['bought']['bread']==0 and p['loaf']==0) if visitor else int(who not in self.eaten and self.entities[who]['inventory']['bread']==0 and self.retail_bought[who,'bread']==0),
               need_ale=int(p['bought']['ale']==0) if visitor else int(who not in self.drank and self.retail_bought[who,'ale']==0 and self.entities[who]['inventory']['ale']==0),
               bread_ceiling=6 if visitor else 10**9,prices={item:q['unit_price']},stock={item:max(1,q['available'])})
        return basket(o)[item]

    def apply(self,e):
        a,w,b,d=(e[k] for k in ('action','actor','target','details'))
        if not a.startswith('demand_'):return super().apply(e)
        assert e['success'] and b in OWNERS
        if a=='demand_customer_intent':
            assert b in ('bakery','brewery') and set(d)=={'item','quantity','quote','inspection_event_id','witness'}
            p=self.people[w];q=d['quote'];inspection=self.events[d['inspection_event_id']-1]
            assert inspection['action']=='spatial_encounter' and inspection['actor']==w and inspection['target']==b and inspection['details']['kind']=='inspected' and inspection['minute']==self.minute and inspection['day']==self.day
            assert self.inspections[w,b]==d['inspection_event_id']<e['id']
            assert q==self.quote(b) and d['item']==PRODUCT[b] and p['active'] and p['tile']==SITES[b]
            assert TRADE[b][0]<=self.minute<TRADE[b][1] and p['activity']=='shop' and p['until']==self.minute+5
            assert type(d['quantity']) is int and d['quantity']==self.intent_quantity(w,b,q) and d['witness']==self.witness(b)
            self.intents[e['id']]=copy.deepcopy(e)
        elif a=='demand_order_observed':
            assert set(d)=={'key','buyer','seller','item','quote','quantity','filled','unfilled','reason','kind','source_ids','receipt_ids','witness','day','minute'}
            q=d['quote'];key=f'{self.day:04}:{w}:{b}:{PRODUCT[b]}:{q["version"]}'
            assert key==d['key'] and key not in self.orders and d['buyer']==w and d['seller']==b and d['item']==PRODUCT[b]
            assert (d['day'],d['minute'])==(self.day,self.minute) and d['witness']==self.witness(b)
            assert q['active'] and all(q[k]==v for k,v in self.quotes[b][PRODUCT[b]].items())
            assert type(d['quantity']) is int and type(d['filled']) is int and 0<=d['filled']<=d['quantity'] and d['quantity']>0
            assert d['unfilled']==d['quantity']-d['filled'] and d['reason']==('stockout' if d['unfilled'] else 'fulfilled')
            assert all(type(i) is int and 0<i<e['id'] for i in d['source_ids']+d['receipt_ids'])
            assert all((self.events[i-1]['day'],self.events[i-1]['minute'])==(self.day,self.minute) for i in d['source_ids']+d['receipt_ids'])
            assert len(set(d['receipt_ids']))==len(d['receipt_ids']) and not self.ordered_receipts.intersection(d['receipt_ids'])
            receipts=[self.events[i-1] for i in d['receipt_ids']]
            if d['kind']=='retail':
                assert len(d['source_ids'])==len(receipts)==1
                intent=self.intents[d['source_ids'][0]];assert intent['actor']==w and intent['target']==b and intent['details']['quantity']==1 and intent['details']['quote']==q
                purchase=receipts[0];assert purchase['action']=='purchase' and purchase['physical_actor']==w and purchase['target']==b
                assert purchase['details']['item']==PRODUCT[b] and purchase['details']['quantity']==1 and purchase['details']['quote']==q
                assert d['quantity']==1 and d['filled']==int(purchase['success'])
                if not purchase['success']:assert purchase['id'] in self.failed_requests
            elif d['kind']=='grain':
                assert b=='farm' and self.minute==610 and len(d['source_ids'])==2
                request,clearing=(self.events[i-1] for i in d['source_ids']);buyer=request['target']
                assert request['action']=='grain_request' and request['success'] and request['actor']==w and request['details']['quote']==q
                assert clearing['action']=='grain_cleared' and clearing['success'] and clearing['id'] in self.grain
                assert d['quantity']==clearing['details']['eligible'][buyer]*request['details']['lot_size']
                assert d['filled']==clearing['details']['allocation'][buyer]*request['details']['lot_size']
                assert d['receipt_ids']==[i for i in clearing['details']['purchase_event_ids'] if self.events[i-1]['actor']==buyer]
            else:
                assert d['kind']=='flour' and b=='mill' and w=='cora' and self.minute==730 and len(d['source_ids'])==1
                plan=self.events[d['source_ids'][0]-1];assert plan['action']=='business_plan' and plan['target']=='bakery' and plan['details']['phase']=='procurement'
                assert plan['details']['observation']['input_quote']==q and d['quantity']==5*plan['details']['proposal']['lots']
                assert d['receipt_ids']==[x['id'] for x in self.events[plan['id']:e['id']-1] if x['action']=='purchase']
                assert receipts and all(x['actor']=='bakery' and x['target']=='mill' and (x['success'] or x['details']['reason']=='insufficient_stock') for x in receipts)
                assert d['filled']==sum(x['details']['quantity'] for x in receipts if x['success'])
            self.ordered_receipts.update(d['receipt_ids']);self.orders[key]=copy.deepcopy(d)
            self.live[b]['order_ids'].append(e['id']);self.live[b]['unfilled']+=d['unfilled']
        elif a=='demand_day_closed':
            assert self.minute==TRADE[b][1] and w==OWNERS[b] and not any(r['day']==self.day and r['business']==b for r in self.days)
            r=copy.deepcopy(self.live[b]);complete=r['quote_consistent'] and r['coverage_ticks']>0 and r['coverage_ticks']==r['witness_ticks']
            r.update(complete=complete,censored=not complete or bool(r['empty_inspection_ids']) or r['unfilled']>0,eligible=r['quote_consistent'] and (complete or r['sales']>0 or bool(r['order_ids'])),closed_event_id=e['id'])
            assert d==r,('seller day',d,r);self.days.append(r)
        elif a=='demand_forecast':
            assert self.minute==955 and w==OWNERS[b] and b not in self.points
            price=self.quotes[b][PRODUCT[b]]['unit_price'];rows=[r for r in self.days if r['business']==b and r['day']<self.day and r['price']==price and r['eligible']][-3:]
            numerator=TARGET[b]+sum(r['sales']+(r['unfilled'] if self.arm=='requests_smoothed' else 0) for r in rows)
            point=min(30,max(0,(numerator+len(rows))//(1+len(rows))))
            if self.arm=='legacy_instrumented':point=self.state['sales'].get(str(self.day-1),{}).get(b,TARGET[b] if self.day<=1 else 0)
            expected=dict(arm=self.arm,business=b,day=self.day,price=price,target=TARGET[b],sample_ids=[r['closed_event_id'] for r in rows],sample_days=[r['day'] for r in rows],numerator=numerator,denominator=1+len(rows),forecast=point,uses_unfilled=self.arm=='requests_smoothed')
            assert d==expected,('forecast',d,expected);self.forecasts.append(copy.deepcopy(d));self.points[b]=point

    def after(self,e):
        super().after(e)
        a,b,d=e['action'],e['target'],e['details']
        if a=='day_started':
            self.live={f:dict(day=self.day,business=f,item=PRODUCT[f],price=self.quotes[f][PRODUCT[f]]['unit_price'],version=self.quotes[f][PRODUCT[f]]['version'],quote_consistent=self.quotes[f][PRODUCT[f]]['active'],coverage_ticks=0,witness_ticks=0,witness_clock_ids=[],empty_inspection_ids=[],sale_ids=[],order_ids=[],sales=0,unfilled=0) for f in OWNERS}
            self.points.clear();self.retail_bought.clear();self.eaten.clear();self.drank.clear();self.inspections.clear()
        if a=='spatial_clock' and e['success']:
            for f,r in self.live.items():
                if TRADE[f][0]<=d['from'] and d['to']<=TRADE[f][1]:
                    r['coverage_ticks']+=1;q=self.quotes[f][PRODUCT[f]]
                    r['quote_consistent']=r['quote_consistent'] and q['active'] and q['version']==r['version'] and q['unit_price']==r['price']
                    if self.witness(f):r['witness_ticks']+=1;r['witness_clock_ids'].append(e['id'])
        if a=='spatial_encounter' and e['success'] and d['kind']=='inspected':
            self.inspections[e['actor'],b]=e['id']
            if b in self.live and self.witness(b) and self.entities[b]['inventory'][PRODUCT[b]]==0:self.live[b]['empty_inspection_ids'].append(e['id'])
        if a=='purchase' and e['success']:
            r=self.live[b];r['sales']+=d['quantity'];r['sale_ids'].append(e['id'])
            if e['actor'] not in OWNERS:self.retail_bought[e['actor'],d['item']]+=d['quantity']
        if a=='purchase' and not e['success'] and e['physical_actor'] in self.people and self.people[e['physical_actor']]['kind'] in ('resident','visitor') and b in ('bakery','brewery'):
            assert self.entities[b]['inventory'][PRODUCT[b]]==0 and d['reason']=='insufficient_stock' and d['quantity']==1
            assert e['id']>1 and self.events[e['id']-2]['action']=='demand_customer_intent'
            intent=self.intents[e['id']-1];assert intent['actor']==e['physical_actor'] and intent['details']['quantity']==1 and intent['details']['quote']==d['quote']
            self.failed_requests.add(e['id'])
        if a=='consume' and e['success'] and e['actor']!='visitors' and d['item']=='bread':self.eaten.add(e['actor'])
        if a=='discretionary_benefit' and e['success']:self.drank.add(e['actor'])
        if a=='grain_cleared' and e['success']:self.grain[e['id']]=copy.deepcopy(e)
        if a=='grain_request' and e['success']:
            plans=[x for x in self.events[:e['id']-1] if x['action']=='business_plan' and x['day']==self.day and x['minute']==610 and x['target']==b and x['details']['phase']=='procurement']
            assert plans and d['maximum']<=plans[-1]['details']['proposal']['lots']

    def finish(self):
        super().finish()
        assert self.failed_requests<=self.ordered_receipts
        assert all(any(row['source_ids']==[id] for row in self.orders.values()) for id,e in self.intents.items() if e['details']['quantity']>0)
        assert self.r['final']['demand_observations']==dict(arm=self.arm,live=self.live,days=self.days,orders=self.orders,points=self.points,forecasts=self.forecasts)
        assert self.r['demand']==dict(arm=self.arm,days=self.days,forecasts=self.forecasts,order_count=len(self.orders),unfilled=sum(r['unfilled'] for r in self.orders.values()),note='Censored records are seller-local lower bounds, never latent demand truth.')


def audit(data):
    return replay(data,fixture='demand_fixture' in data['report']['initial'],labor=DemandAudit())
