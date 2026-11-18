"""Independent M28 receipt/knowledge/renewal replay over unchanged M27 accounting.

No native policy import. Input-limited production is bounded analytically rather
than rerunning the GDScript's capped production planner.
"""
import copy
from economic_diagnostics import EconomicAudit,analyze as economic_analyze
from brewery_audit import planned
from brewery_feasibility import OWNERS

BASE='e735df8cf3dd46fe32f2bee5b22f2b366cc70d73'
ARMS=('R_baseline_instrumented','R_input_aware')
INPUTS=dict(mill=('farm','wheat',5,3),bakery=('mill','flour',5,3),brewery=('farm','wheat',3,2))


def estimate(history,b,day,terms):
    supplier,item,size,k=INPUTS.get(b,('','',0,0));q=terms.get('quote',{})
    known=bool(k and terms.get('day')==day and q.get('active') and q.get('seller')==supplier and q.get('item')==item)
    samples=[];ids=set();receipts=set();days=set()
    if known:
        for r in sorted(history,key=lambda x:(x['day'],x['order_event_id'])):
            if (r['business'],r['supplier'],r['item'],r['price'])!=(b,supplier,item,q['unit_price']) or r['day']>=day:continue
            if not r['eligible'] or type(r['requested']) is not int or type(r['filled']) is not int or not 0<r['requested']<=k or not 0<=r['filled']<=r['requested']:continue
            if r['order_event_id'] in ids or r['day'] in days or receipts.intersection(r['receipt_ids']):continue
            samples.append(r);ids.add(r['order_event_id']);days.add(r['day']);receipts.update(r['receipt_ids'])
    samples=samples[-3:]
    return dict(day=day,business=b,supplier=supplier,item=item,K=k,numerator=k+sum(r['filled'] for r in samples),denominator=k+sum(r['requested'] for r in samples),
        price=q.get('unit_price',0) if known else 0,quote=copy.deepcopy(q) if known else {},inspection_event_id=terms.get('inspection_event_id') if known else None,
        sample_order_ids=[r['order_event_id'] for r in samples],sample_days=[r['day'] for r in samples],status='inapplicable' if not k else 'unknown_quote' if not known else 'prior_only' if not samples else 'observed_fill_heuristic')


def projection(o,count,limited):
    p=copy.deepcopy(o['production']);stock=max(0,p['output_stock']-o['remaining_sales']);cash=p['cash']+o['remaining_sales']*p['output_price']-o['arrears'];raw=p['input_stock']
    receipts=inputs=0;feasible=cash>=0;days=[];ratio=o.get('input_reliability',{});n=ratio.get('numerator',1);d=ratio.get('denominator',1)
    if p['rule']['input']:assert 0<n<=d<=12
    for day in range(1,4):
        p.update(cash=max(0,cash-10*count),output_stock=stock,input_stock=raw,harvest_remaining=o['farm_cap'],workers=[dict(id=f'slot:{i}',wage=0,available=cash>=10*count) for i in range(count)])
        full=planned(p);k=full['lots'];predicted=k
        if limited and p['rule']['input']:
            # Independent quotient/remainder half-up, not floating-point ratios.
            whole,remainder=divmod(k*n,d);predicted=min(k,whole+int(2*remainder>=d))
        shifts=full['shifts']
        if p['rule']['input']:shifts=min(shifts,(raw+predicted*p['rule']['take'])//p['rule']['take'])
        output=min(shifts*7,o['farm_cap']) if not p['rule']['input'] else shifts*p['rule']['make']
        cost=predicted*p['rule']['take']*p['input_price'];opening=cash;cash-=cost+10*count;inputs+=cost;feasible=feasible and cash>=0
        owned=raw;raw+=(predicted-shifts)*p['rule']['take'];stock+=output
        sold=min(stock,o['demand']);stock-=sold;cash+=sold*p['output_price'];receipts+=sold*p['output_price']
        assert raw>=0 and predicted<=k and shifts<=count
        days.append(dict(projected_day=day,owned_input_before=owned,desired_lots=k,predicted_lots=predicted,input_cost=cost,shifts=shifts,output=output,owned_input_after=raw,output_stock_after=stock,sold=sold,opening_cash=opening,cash_before_sales=opening-cost-10*count,closing_cash=cash,guaranteed_wages=10*count))
    return dict(summary=dict(headcount=count,receipts=receipts,inputs=inputs,guaranteed_wages=30*count,contribution=receipts-inputs-30*count,feasible=feasible,cash=cash),days=days)


class InputAudit(EconomicAudit):
    SCENARIO='settlement_input_reliability'
    ACTIONS=EconomicAudit.ACTIONS|{'input_reliability_frozen','input_forecast_projection'}

    def validate_initial_jobs(self,initial,jobs):
        label=initial.get('input_fixture')
        if label is None:return super().validate_initial_jobs(initial,jobs)
        assert label in ('no_harvest','cashless_inputs','remote_buyer','invalid_attempts')
        normalized=copy.deepcopy(initial)
        for who,e in initial['entities'].items():
            cash=8622 if who=='visitors' else 120 if who in OWNERS else 6
            if label=='no_harvest':cash=0 if who=='farm' else cash+120 if who=='visitors' else cash
            if label=='cashless_inputs':cash=0 if who in ('mill','brewery') else cash+240 if who=='visitors' else cash
            assert e['money']==cash and not any(e['inventory'].values())
            normalized['entities'][who]['money']=8622 if who=='visitors' else 120 if who in OWNERS else 6
        super().validate_initial_jobs(normalized,jobs)

    def attach(self,*args):
        super().attach(*args);initial=self.r['initial']['input_reliability'];self.input_arm=initial['arm'];assert self.input_arm in ARMS
        assert initial==dict(arm=self.input_arm,orders=[],points={},forecasts=[],projections=[])
        self.input_orders=[];self.input_points={};self.input_forecasts=[];self.input_projections=[];self.projection_observations={}

    def forecast(self,o,count):
        if self.input_arm=='R_baseline_instrumented' or o['business']=='farm':return super().forecast(o,count)
        p=copy.deepcopy(o);p['input_reliability']=self.input_points[o['business']]
        return projection(p,count,True)['summary']

    def vacancy(self,b,observation=None):
        if observation is not None and self.input_arm=='R_input_aware' and b!='farm':
            observation=copy.deepcopy(observation);assert observation.pop('input_reliability')==self.input_points[b]
        return super().vacancy(b,observation)

    def renewal(self,o):
        self.projection_observations[o['business']]=copy.deepcopy(o)
        return super().renewal(o)

    def apply(self,e):
        a,w,b,d=(e[k] for k in ('action','actor','target','details'))
        if a not in ('input_reliability_frozen','input_forecast_projection'):return super().apply(e)
        assert e['success'] and self.minute==955 and w==OWNERS[b]
        if a=='input_reliability_frozen':
            assert b not in self.input_points
            own=[r for r in self.input_orders if r['business']==b]
            expected=estimate(own,b,self.day,self.state['input_terms'].get(b,{}))
            assert d==expected,('own-input estimate',d,expected)
            assert all(self.events[id-1]['day']<self.day for id in d['sample_order_ids'])
            self.input_points[b]=copy.deepcopy(d);self.input_forecasts.append(copy.deepcopy(d))
        else:
            selected=self.vacancy(b);o=self.projection_observations[b];o['input_reliability']=self.input_points[b]
            expected=dict(day=self.day,business=b,arm=self.input_arm,estimate=self.input_points[b],candidates=[projection(o,c['headcount'],self.input_arm=='R_input_aware') for c in selected['candidates']],headcount=selected['headcount'])
            assert d==expected,('three-day input projection',d,expected)
            self.input_projections.append(copy.deepcopy(d))

    def after(self,e):
        super().after(e)
        if e['action']=='day_started':self.input_points.clear()
        if not e['success'] or e['action']!='demand_order_observed' or e['details']['kind']=='retail':return
        d=e['details'];b='bakery' if d['kind']=='flour' else 'mill' if e['actor']=='bram' else 'brewery'
        supplier,item,size,k=INPUTS[b];terms=self.state['input_terms'][b]
        assert e['actor']==OWNERS[b] and d['seller']==supplier and d['item']==item and terms['quote']==d['quote'] and terms['day']==self.day
        assert d['quantity']%size==d['filled']%size==0 and 0<d['quantity']//size<=k
        assert not any(r['business']==b and r['day']==self.day for r in self.input_orders)
        assert not set(d['receipt_ids']).intersection(id for r in self.input_orders for id in r['receipt_ids'])
        row=dict(business=b,owner=e['actor'],supplier=supplier,item=item,price=d['quote']['unit_price'],quote=copy.deepcopy(d['quote']),day=self.day,minute=self.minute,lot_size=size,requested=d['quantity']//size,filled=d['filled']//size,rationed=(d['quantity']-d['filled'])//size,eligible=True,order_event_id=e['id'],inspection_event_id=terms['inspection_event_id'],source_ids=copy.deepcopy(d['source_ids']),receipt_ids=copy.deepcopy(d['receipt_ids']))
        self.input_orders.append(row)

    def finish(self):
        super().finish()
        assert self.r['final']['input_reliability']==dict(arm=self.input_arm,orders=self.input_orders,points=self.input_points,forecasts=self.input_forecasts,projections=self.input_projections)
        assert self.r['input_reliability']==dict(arm=self.input_arm,orders=self.input_orders,forecasts=self.input_forecasts,projections=self.input_projections,note='Local endogenous fill heuristic, not a future supply guarantee.')
        assert len(self.input_forecasts)==4*self.r['days']
        assert len(self.input_projections)==(0 if getattr(self,'VARIABLE_WAGES',False) else 4*self.r['days'])


def analyze(data):
    observer=InputAudit();result=economic_analyze(data,observer,fixture='input_fixture' in data['report']['initial'])
    result['source']['base']=BASE
    result['input']=dict(orders=observer.input_orders,forecasts=observer.input_forecasts,projections=observer.input_projections)
    return result


def audit(data):return analyze(data)['audit']
