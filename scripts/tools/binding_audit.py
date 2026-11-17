"""M25 independent attendance, earned-liability, term and financial decision replay."""
import copy
from collections import Counter
from brewery_audit import audit as replay, planned
from labor_market_audit import LaborAudit
from brewery_feasibility import OWNERS, WORKERS, WINDOWS, SITES


class BindingAudit(LaborAudit):
    SCENARIO='settlement_binding_contracts'
    BINDING=True
    ACTIONS=LaborAudit.ACTIONS|set('binding_attendance_started contract_attended guaranteed_wage_due wage_payment_applied binding_breach binding_day_closed binding_term_closed binding_term_started binding_term_disposition binding_boundary_closed binding_offer_declined binding_release_requested'.split())

    def attach(self,report,*args):
        self.bound=copy.deepcopy(report['initial']['binding_contracts'])
        self.contract_mode=self.bound['mode'];assert self.contract_mode in ('matching','obligations_only')
        self.wage_receipts=set();self.productive_receipts=set();self.pending_payment={};self.due_receipts={};self.work_records={};self.closures=[];self.binding_days=[]
        super().attach(report,*args)
        assert self.bound['processed_boundary']==-1
        assert all(self.bound[k]=={} for k in ('obligations','attendance','releases'))
        for w,j in self.jobs.items():
            id=f'term:{j["start_day"]:04}:{j["business"]}:{w}'
            assert self.bound['active_terms'][w]==id
            assert self.bound['terms'][id]==dict(id=id,worker=w,business=j['business'],start_day=1,end_day=j['end_day'],wage=10,status='active',predecessor='',source='initial')

    def validate_initial_jobs(self,initial,jobs):
        fixture=initial['labor_market']['fixture'];assert fixture in ('none','cash_short','cash_zero','mill_zero','insolvent','no_show','staggered')
        assert initial['brewery']['case']==self.r['condition'] and initial['brewery']['supply_cap']==dict(reference=21,tight=19,scarce=16,no_brew_request=21)[self.r['condition']]
        assert initial['commodity_quotes']=={b:{item:dict(seller=b,item=item,unit_price=price,active=True,limit=10**9,version=1,effective_day=0,revised_day=-1)} for b,item,price in [('farm','wheat',2),('mill','flour',5),('bakery','bread',6),('brewery','ale',4)]}
        for i,w in enumerate(sorted(jobs)):
            assert jobs[w]['active'] and jobs[w]['start_day']==1 and jobs[w]['end_day']==(2+i%3 if fixture=='staggered' else 4)
        for id,e in initial['entities'].items():
            expected=8622 if id=='visitors' else 120 if id in OWNERS else 6
            if fixture in ('cash_short','cash_zero','insolvent'):
                cash=6 if fixture=='cash_short' else 0
                if id=='bakery':expected=cash
                if id=='finn':expected=0
                if id=='visitors':expected+=126-cash
            if fixture=='mill_zero':
                if id in ('mill','hale'):expected=0
                if id=='visitors':expected+=126
            assert e['money']==expected
            assert e['inventory']=={item:21 if fixture in ('cash_short','cash_zero') and id=='bakery' and item=='bread' else 15 if fixture=='mill_zero' and id=='mill' and item=='flour' else 0 for item in ('wheat','flour','bread','ale')}

    def cid(self,w,b,day=None):return f'{self.day if day is None else day:04}:{b}:{w}'
    def queue(self,b):return sorted(id for id,c in self.bound['obligations'].items() if c['business']==b and c['paid']<10)
    def arrears(self,b):return sum(10-self.bound['obligations'][id]['paid'] for id in self.queue(b))
    def committed(self,b):return self.arrears(b)+10*sum(self.cid(w,b) not in self.bound['attendance'] for w in self.staff(b))
    def funded(self,b):
        cash=self.entities[b]['money']-self.arrears(b);result=[]
        for w in self.staff(b):
            c=self.bound['obligations'].get(self.cid(w,b),{})
            if c:
                if c['paid']==10:result.append(w)
            elif cash>=10:result.append(w);cash-=10
        return result

    def within(self,o):
        p=copy.deepcopy(o);p['cash']=max(0,o['cash']-o['committed_payroll'])
        for w in p['workers']:w['wage']=0;w['available']=w['available'] and w['id'] in o['funded_workers']
        return dict(planned(p),cost_basis='incremental_inputs_only_committed_wages_reserved_once',committed_payroll=o['committed_payroll'])

    def forecast(self,o,count):
        p=copy.deepcopy(o['production']);stock=max(0,p['output_stock']-o['remaining_sales']);cash=p['cash']+o['remaining_sales']*p['output_price']-o['arrears'];raw=p['input_stock']
        receipts=inputs=0;feasible=cash>=0
        for _ in range(3):
            p.update(cash=max(0,cash-10*count),output_stock=stock,input_stock=raw,harvest_remaining=o['farm_cap'],workers=[dict(id=f'slot:{i}',wage=0,available=cash>=10*count) for i in range(count)])
            decision=planned(p);cost=decision['lots']*p['rule']['take']*p['input_price'];inputs+=cost;cash-=cost+10*count;feasible=feasible and cash>=0
            stock+=decision['expected_receipts']//p['output_price'];raw+=(decision['lots']-decision['shifts'])*p['rule']['take']
            sold=min(stock,o['demand']);stock-=sold;cash+=sold*p['output_price'];receipts+=sold*p['output_price']
        return dict(headcount=count,receipts=receipts,inputs=inputs,guaranteed_wages=30*count,contribution=receipts-inputs-30*count,feasible=feasible,cash=cash)

    def renewal(self,o):
        base=self.forecast(o,o['retained']);best=base;candidates=[base]
        maximum=min(o['capacity'],o['retained']+len(o['expiring'])) if self.contract_mode=='obligations_only' else o['capacity']
        if o['disabled']:maximum=o['retained']
        for n in range(o['retained']+1,maximum+1):
            p=self.forecast(o,n);candidates.append(p)
            if p['feasible'] and p['contribution']>best['contribution']:best=p
        return dict(vacancies=max(0,best['headcount']-o['retained']-o['reserved']),headcount=best['headcount'],baseline=base,candidates=candidates,reason='positive_full_term_contribution' if best['headcount']>o['retained'] else 'no_profitable_new_commitment')

    def vacancy(self,b,observation=None):
        # Reuse the independent M24 observation reconstruction, intercepting its
        # comparison to obtain the permitted production and own-sales fields.
        old_super=self._capture_vacancy(b)
        production=old_super['production'];production.update(committed_payroll=self.committed(b),funded_workers=self.funded(b))
        expiring=[w for w in self.staff(b) if self.jobs[w]['end_day']<=self.day+1]
        closing=dict(farm=660,mill=780,bakery=1050,brewery=1050)[b]
        remaining=min(production['output_stock'],max(0,old_super['previous_sales']-self.state['sales'].get(str(self.day),{}).get(b,0))) if self.minute<closing else 0
        o=dict(owner=OWNERS[b],business=b,day=self.day,production=production,demand=old_super['previous_sales'],remaining_sales=remaining,retained=len(self.staff(b))-len(expiring),expiring=expiring,reserved=old_super['reserved'],capacity=len(WORKERS[b]),farm_cap=old_super['farm_cap'],disabled=old_super['disabled'],arrears=self.arrears(b),mode=self.contract_mode)
        if observation is not None:assert observation==o,('renewal observation',b,observation,o)
        return self.renewal(o)

    def _capture_vacancy(self,b):
        # Obtain the common independent reconstruction without importing a world
        # implementation; the parent exposes no callback, so build its small view.
        out,raw,take,make,recipe=dict(farm=('wheat','',0,7,''),mill=('flour','wheat',5,5,'mill'),bakery=('bread','flour',5,7,'bake'),brewery=('ale','wheat',3,6,'brew'))[b]
        quote=self.state['input_terms'].get(b,{}).get('quote',{})
        workers=[dict(id=w,wage=10,available=w not in self.worked and self.people[w]['active'] and self.people[w]['activity']=='idle' and self.people[w]['tile']==SITES[b]) for w in self.staff(b)]
        p=dict(owner=OWNERS[b],business=b,day=self.day,rule=dict(output=out,input=raw,recipe=recipe,batches=int(b!='farm'),target=len(WORKERS[b])*make,take=take,make=make),cash=self.entities[b]['money'],output_stock=self.entities[b]['inventory'][out],input_stock=self.entities[b]['inventory'][raw]+self.cargo[b]['inventory'][raw] if raw else 0,output_price=self.quotes[b][out]['unit_price'],input_price=quote.get('unit_price',0),input_quote=copy.deepcopy(quote),allow_procurement=True,harvest_remaining=self.r['initial']['brewery']['supply_cap']-self.harvested if b=='farm' else 0,workers=self.ordered(workers,self.day))
        return dict(production=p,previous_sales=self.state['sales'].get(str(self.day-1),{}).get(b,p['rule']['target'] if self.day<=1 else 0),reserved=sum(q['reserved'] for q in self.postings.values() if q['active'] and q['business']==b),farm_cap=self.r['initial']['brewery']['supply_cap'] if b=='farm' else 0,disabled=self.r['condition']=='no_brew_request' and b=='brewery')

    def worker(self,w):
        history=[]
        for day in range(max(1,self.day-2),self.day+1):
            for b in OWNERS:
                id=self.cid(w,b,day)
                if id in self.bound['attendance']:
                    a=self.bound['attendance'][id];c=self.bound['obligations'].get(id,{})
                    history.append(dict(day=day,business=b,due_event_id=a['due_event_id'],attendance_event_id=a['attendance_event_id'],paid=c.get('paid',0),payments=copy.deepcopy(c.get('payments',[]))))
        j=self.jobs.get(w,{});known=self.state['known_jobs'].get(w,{})
        return dict(worker=w,day=self.day,business=self.affiliations.get(w,{}).get('business',''),end_day=j.get('end_day',0),eligible=not j.get('active',False) or j['end_day']==self.day+1,history=history,notices=copy.deepcopy(known.get('notices',[])),notice_event_id=known.get('event_id'),mode=self.contract_mode)

    def search(self,o):
        candidates=[]
        if o['eligible']:
            for p in o['notices']:
                if not p['active'] or p['reserved']+p['filled']>=p['vacancies'] or (self.contract_mode=='obligations_only' and p['business']!=o['business']):continue
                history=[h for h in o['history'] if h['business']==p['business']]
                candidates.append((p,dict(numerator=sum(h['paid'] for h in history)+10,denominator=len(history)+2)))
        best=None;value={}
        for p,v in sorted(candidates,key=lambda x:(x[0]['business']!=o['business'],x[0]['id'])):
            if best is None or v['numerator']*value['denominator']>value['numerator']*v['denominator']:best=p;value=v
        return dict(action='apply' if best else 'stay',posting=best['id'] if best else '',income=value,reason='best_observed_post_expiry_income' if best else 'binding_term_or_no_eligible_offer')

    def validate_payment(self,e):
        b,w,d=e['actor'],e['target'],e['details'];assert self.queue(b)
        id=self.queue(b)[0];c=self.bound['obligations'][id]
        assert c['worker']==w and d['amount']==min(10-c['paid'],self.entities[b]['money'],10**9-self.entities[w]['money'])>0
        assert ((self.minute<960 and (c['day']<self.day or self.minute>=WINDOWS[b][1])) or self.minute==1140) and e['physical_actor']==OWNERS[b]
        self.pending_payment[e['id']]=id

    def validate_productive(self,e):
        c=self.bound['obligations'][self.cid(e['actor'],e['target'])];p=e['details']['payment_event_id']
        assert c['paid']==10 and len(c['payments'])==1 and c['payments'][0]==dict(payment_event_id=p,amount=10,day=self.day,minute=self.minute)
        assert p in self.wage_receipts and p not in self.productive_receipts
        self.productive_receipts.add(p)

    def validate_closure(self,e):
        w,b,d=e['actor'],e['target'],e['details'];id=self.cid(w,b);a=self.bound['attendance'][id];c=self.bound['obligations'].get(id,{})
        shift=self.work_records.get(id);breach=a['status']=='absent' or c.get('breach_event_id') is not None
        expected=dict(contract_id=f'{self.day}:{b}:{w}',employer=OWNERS[b],expected_compensation=10,actual_compensation=c.get('paid',0),completed=shift is not None,reason='productive_work' if shift else 'worker_nonattendance' if a['status']=='absent' else 'attended_standby',shift_event_id=shift,attendance_event_id=a['attendance_event_id'],guaranteed_wage_due=c.get('amount',0),arrears=c.get('amount',0)-c.get('paid',0),breach=breach)
        assert d==expected and e['success']==bool(shift) and not any(r['day']==self.day and r['worker']==w for r in self.closures)
        self.closures.append(dict(day=self.day,worker=w,business=b,event_id=e['id'],success=e['success'],details=copy.deepcopy(d)))

    def breach_count(self):
        return sum(a['status']=='absent' or self.bound['obligations'].get(id,{}).get('breach_event_id') is not None for id,a in self.bound['attendance'].items() if a['day']==self.day)

    def eligible(self,w,p):
        assert w not in OWNERS.values() and w not in self.pending and w not in self.resignations
        assert not self.jobs[w]['active'] or self.jobs[w]['end_day']<=self.day+1
        if self.contract_mode=='obligations_only':assert self.affiliations.get(w,{}).get('business')==p['business'] and self.jobs[w]['end_day']==self.day+1

    def apply(self,e):
        a,w,b,d=(e[k] for k in ('action','actor','target','details'));s=self.bound
        if a=='binding_attendance_started':
            session=d['session'];id=self.cid(w,b);p=self.people[w];self.assert_term(w,b)
            assert self.minute==WINDOWS[b][0] and w in self.staff(b) and p['tile']==SITES[b] and p['activity'] in ('work','standby') and p['until']==self.minute+60 and id not in s['attendance']
            assert self.events[session['start_event_id']-1]['action']=='spatial_activity_started' and self.events[session['start_event_id']-1]['actor']==w
            assert session==dict(id=id,worker=w,business=b,term=s['active_terms'][w],day=self.day,start_event_id=session['start_event_id'],due_event_id=self.due_receipts[id],kind=p['activity'],status='started',attendance_event_id=None,breach_event_id=None)
            s['attendance'][id]=copy.deepcopy(session)
        elif a=='contract_attended':
            id=self.cid(w,b);session=s['attendance'][id];p=self.people[w];self.assert_term(w,b)
            assert self.minute==WINDOWS[b][1] and p['tile']==SITES[b] and p['activity']==session['kind'] and p['business']==b and p['until']==self.minute and session['status']=='started'
            assert d==dict(term=s['active_terms'][w],session=id,start_event_id=session['start_event_id'],clock_event_id=d['clock_event_id'],due_event_id=self.due_receipts[id],kind=session['kind'])
            self.assert_clock(d['clock_event_id']);session.update(status='attended',attendance_event_id=e['id'])
        elif a=='guaranteed_wage_due':
            id=self.cid(w,b);session=s['attendance'][id];c=d['claim'];assert session['status']=='attended' and id not in s['obligations']
            assert c==dict(id=id,worker=w,business=b,term=s['active_terms'][w],day=self.day,minute=self.minute,amount=10,paid=0,due_event_id=self.due_receipts[id],attendance_event_id=session['attendance_event_id'],payments=[],breach_event_id=None)
            s['obligations'][id]=copy.deepcopy(c)
        elif a=='wage_payment_applied':
            id=d['claim'];c=s['obligations'][id];p=d['payment'];receipt=p['payment_event_id']
            assert self.pending_payment.pop(receipt)==id and receipt not in self.wage_receipts
            pay=self.events[receipt-1];amount=pay['details']['amount']
            assert p==dict(payment_event_id=receipt,amount=amount,day=self.day,minute=self.minute) and w==c['worker'] and b==c['business']
            c['paid']+=amount;c['payments'].append(copy.deepcopy(p));assert d['paid']==c['paid']<=10 and d['arrears']==10-c['paid'];self.wage_receipts.add(receipt)
        elif a=='binding_breach':
            self.assert_clock(d['clock_event_id']);assert self.minute==WINDOWS[b][1] and d['term']==s['active_terms'][w]
            id=self.cid(w,b)
            if d['kind']=='worker_nonattendance':
                old=s['attendance'].get(id,{});p=self.people[w]
                assert not old or old['status']=='started'
                assert not old or p['tile']!=SITES[b] or p['activity']!=old['kind'] or p['business']!=b or p['until']!=self.minute
                assert d==dict(kind='worker_nonattendance',term=s['active_terms'][w],session=id,clock_event_id=d['clock_event_id'],presence=p,due_event_id=self.due_receipts[id])
                s['attendance'][id]=dict(id=id,worker=w,business=b,term=s['active_terms'][w],day=self.day,start_event_id=old.get('start_event_id'),due_event_id=self.due_receipts[id],kind=old.get('kind','absent'),status='absent',attendance_event_id=None,breach_event_id=e['id'])
            else:
                c=s['obligations'][id];assert c['paid']<10 and self.entities[b]['money']==0
                assert d==dict(kind='employer_unpaid',term=c['term'],claim=id,amount_paid=c['paid'],arrears=10-c['paid'],clock_event_id=d['clock_event_id'])
                c['breach_event_id']=e['id']
        elif a=='binding_day_closed':
            liabilities={f:self.arrears(f) for f in OWNERS};receivables=Counter()
            for c in s['obligations'].values():receivables[c['worker']]+=10-c['paid']
            assert self.minute==1140 and d==dict(liabilities=liabilities,receivables=dict(receivables),terms=s['active_terms'],breaches=self.breach_count())
            self.binding_days.append(dict(day=self.day,minute=self.minute,event_id=e['id'],**copy.deepcopy(d)))
        elif a=='binding_term_closed':
            old=s['active_terms'].pop(w);term=s['terms'][old];receipt=self.events[d['employment_event_id']-1]
            assert receipt['action']=='employment_ended' and receipt['actor']==w
            term.update(status='released' if w in s['releases'] else 'expired',closed_day=self.day+1)
            assert d==dict(term=term,employment_event_id=receipt['id'],release=s['releases'].get(w,{}))
        elif a=='binding_term_started':
            receipt=self.events[d['employment_event_id']-1];assert receipt['action']=='employment_started' and receipt['actor']==w
            previous=[t for t in s['terms'].values() if t['worker']==w];prev=max(previous,key=lambda t:t['start_day'])['id'] if previous else ''
            id=f'term:{self.day+1:04}:{b}:{w}';term=dict(id=id,worker=w,business=b,start_day=self.day+1,end_day=self.day+4,wage=10,status='active',predecessor=prev,source='accepted')
            same=bool(prev) and s['terms'][prev]['business']==b;continuous=same and s['terms'][prev]['closed_day']==self.day+1
            assert w not in s['active_terms'] and d==dict(term=term,employment_event_id=receipt['id'],renewed=continuous,entry_kind='renewal' if continuous else 'rehire' if same else 'new_employer')
            s['terms'][id]=term;s['active_terms'][w]=id
        elif a=='binding_term_disposition':
            term=s['terms'][d['term']];successor=s['terms'].get(s['active_terms'].get(w,''),{})
            disposition='released' if term['status']=='released' else 'nonrenewed' if not successor else 'renewed' if successor['business']==b else 'changed_employer'
            assert d==dict(term=term['id'],disposition=disposition,successor=successor.get('id','')) and term['closed_day']==self.day+1
        elif a=='binding_boundary_closed':
            assert self.minute==1440 and s['processed_boundary']<self.day and d==dict(effective_day=self.day+1,processed_day=self.day)
            s['releases'].clear();s['processed_boundary']=self.day
            for person in list(self.state['contingent']):
                if person not in self.pending:self.state['contingent'].pop(person)
        elif a=='binding_offer_declined':
            self.board(w);app=self.apps[d['application_id']];assert app['worker']==w and app['status']=='offered' and any(o['application_id']==app['id'] for o in self.state['known_offers'][w]['offers'])
            app['status']='declined';self.postings[app['posting']]['reserved']-=1
        elif a=='binding_release_requested':
            actor=w;person=b;self.board(actor);term=s['terms'][s['active_terms'][person]];receipt=self.events[d['breach_event_id']-1]
            assert receipt['action']=='binding_breach' and receipt['actor']==person and receipt['details']['term']==term['id'] and person not in self.pending and person not in s['releases']
            if receipt['details']['kind']=='employer_unpaid':assert actor==person and s['obligations'][receipt['details']['claim']]['paid']<10
            else:assert actor==OWNERS[term['business']]
            assert d==dict(worker=person,business=term['business'],actor=actor,breach_event_id=receipt['id'],effective_day=self.day+1)
            s['releases'][person]=copy.deepcopy(d);self.resignations[person]=dict(business=term['business'],effective_day=self.day+1)
        elif a=='labor_vacancy_assessed':
            self.board(w);assert OWNERS[b]==w and d['proposal']==self.vacancy(b,d['observation'])
        elif a=='job_posted':
            self.board(w);p=d['posting'];assert OWNERS[b]==w and p==dict(id=p['id'],employer=w,business=b,role=self.firms[b]['industry'],wage=10,guaranteed_shifts=1,cycle_days=1,duration_days=3,required_skills=[],vacancies=p['vacancies'],reserved=0,filled=0,active=True)
            assert p['id'] not in self.postings and 0<p['vacancies']<=self.vacancy(b)['vacancies'];self.postings[p['id']]=copy.deepcopy(p)
        elif a=='labor_search_decision':
            self.board(w);assert w not in OWNERS.values() and d==dict(observation=self.worker(w),proposal=self.search(self.worker(w))) and b==d['proposal']['posting']
        elif a=='application_submitted':
            self.board(w);app=d['application'];p=self.postings[app['posting']];self.eligible(w,p)
            assert p['active'] and p['filled']+p['reserved']<p['vacancies'] and any(n['id']==p['id'] for n in self.state['known_jobs'][w]['notices'])
            assert app==dict(id=p['id']+':'+w,worker=w,posting=p['id'],status='applied') and app['id'] not in self.apps;self.apps[app['id']]=copy.deepcopy(app)
        elif a=='labor_applicants_ranked':
            self.board(w);assert OWNERS[b]==w
            rows=[dict(id=app['worker'],wage=10,available=True,application_id=app['id'],incumbent=self.affiliations.get(app['worker'],{}).get('business')==b) for app in self.apps.values() if self.postings[app['posting']]['business']==b and app['status']=='applied']
            for row in rows:self.board(row['id'])
            ranked=self.ordered([r for r in rows if r['incumbent']],self.day)+self.ordered([r for r in rows if not r['incumbent']],self.day)
            assert d==dict(candidates=ranked,tie='incumbent_then_neutral_rotate',reason='equal_full_term_financial_contribution')
        elif a=='labor_acceptance_decision':
            o=self.worker(w);offers=self.state['known_offers'][w]
            assert d==dict(observation=o,offers_event_id=offers['event_id'],accepts=o['eligible'] and bool(offers['offers']),reason='positive_post_expiry_income' if o['eligible'] and offers['offers'] else 'binding_term_or_no_observed_offer')
        elif a=='offer_accepted':
            app=self.apps[d['application_id']];p=self.postings[app['posting']];self.board(w);self.board(p['employer']);self.eligible(w,p)
            assert app['worker']==w and app['status']=='offered' and any(o['application_id']==app['id'] for o in self.state['known_offers'][w]['offers'])
            assert p['active'] and p['reserved']>0;assert self.vacancy(b)['headcount']>=self.retained(b)+self.reserved(b)
            expected=dict(posting=p['id'],application_id=app['id'],effective_day=self.day+1);assert d['pending']==expected
            app['status']='accepted';self.pending[w]=expected
        elif a=='resignation_requested':raise AssertionError('M25 ordinary resignation cannot end a binding term')
        elif a=='labor_boundary':
            assert self.minute==1440 and d==dict(effective_day=self.day+1,pending=self.pending)
            for person,pending in self.pending.items():
                assert self.affiliations.get(person,{})==self.state['contingent'][person]['old'] and (not self.jobs[person]['active'] or self.jobs[person]['end_day']<=self.day+1)
                p=self.postings[pending['posting']];assert self.vacancy(p['business'])['headcount']>=self.retained(p['business'])+self.reserved(p['business'])
        elif a=='employment_started':
            assert self.minute==1440 and w not in self.affiliations
            pending=self.pending.pop(w);p=self.postings[pending['posting']];job=dict(worker=w,business=b,wage=10,active=True,start_day=self.day+1,end_day=self.day+4,contract=dict(cycle_days=1,shifts_per_cycle=1,cycle_compensation=10,phases=[1]))
            assert d==dict(posting=p['id'],job=job,affiliation=dict(business=b,kind='employee'),effective_day=self.day+1)
            self.jobs[w]=job;self.affiliations[w]=dict(business=b,kind='employee')
            if w not in self.firms[b]['employees']:self.firms[b]['employees'].append(w)
            p['reserved']-=1;p['filled']+=1;p['active']=p['filled']<p['vacancies'];self.apps[pending['application_id']]['status']='started'
        elif a=='labor_notice_closed':
            p=self.postings[d['posting']];reason=d['reason']
            if reason=='withdrawn':self.board(w);assert p['employer']==w
            else:assert self.minute==1440
            if reason=='changed_capacity_or_funding':assert self.vacancy(b)['headcount']<self.retained(b)+self.reserved(b)
            elif reason=='expired_unaccepted':assert not any(q['posting']==p['id'] for q in self.pending.values())
            elif reason=='filled':assert p['filled']==p['vacancies']
            else:assert reason in ('withdrawn','partially_filled','expired','changed_fixed_terms','expired_or_closed_notice','changed_old_affiliation')
            canceled=[];applications=[]
            for app in self.apps.values():
                if app['posting']!=p['id'] or app['status']=='started':continue
                person=app['worker']
                if self.pending.get(person,{}).get('application_id')==app['id']:self.pending.pop(person);self.resignations.pop(person,None);self.state['contingent'].pop(person);canceled.append(person)
                app['status']='closed';applications.append(copy.deepcopy(app))
            p.update(active=False,reserved=0);self.state['notices'][p['id']]['status']=reason
            assert d['state']==p and d['canceled_pending']==canceled and d['applications']==applications
        else:super().apply(e)

    def reserved(self,b):return sum(p['reserved'] for p in self.postings.values() if p['active'] and p['business']==b)
    def retained(self,b):return sum(self.jobs[w]['end_day']>self.day+1 for w in self.staff(b))
    def assert_term(self,w,b):
        t=self.bound['terms'][self.bound['active_terms'][w]]
        assert t['business']==b and t['status']=='active' and t['start_day']<=self.day<t['end_day'] and self.affiliations[w]==dict(business=b,kind='employee')
    def assert_clock(self,id):
        e=self.events[id-1];assert e['action']=='spatial_clock' and e['success'] and e['day']==self.day and e['minute']==self.minute and e['details']['to']==self.minute

    def after(self,e):
        if e['success'] and e['action']=='business_plan':
            # Parent selection check has the M24 objective; all candidate fields
            # are identical and remain independently verified there.
            selection=e['details']['selection'];assert selection['objective']=='incremental_receipts_minus_inputs_committed_wage_excluded'
            shadow=copy.deepcopy(e);shadow['details']['selection']['objective']='conditional_receipts_minus_missing_inputs_and_wages';super().after(shadow)
        else:super().after(e)
        if e['action']=='day_started' and self.day==1:self.bound['processed_boundary']=0
        if e['success'] and e['action']=='contract_due':
            self.assert_term(e['actor'],e['target']);self.due_receipts[self.cid(e['actor'],e['target'])]=e['id']
        if e['success'] and e['action']=='work_shift':self.work_records[self.cid(e['actor'],e['target'])]=e['id']

    def finish(self):
        super().finish()
        assert self.r['failures']==dict(Counter(e['action']+':'+e['details'].get('reason','unspecified') for e in self.events if not e['success']))
        assert self.bound==self.r['final']['binding_contracts'] and not self.pending_payment
        assert sum(self.arrears(b) for b in OWNERS)==sum(10-c['paid'] for c in self.bound['obligations'].values())
        workers={w:dict(scheduled=0,attended=0,productive=0,standby=0,breaches=0,accrued=0,cash_wages=self.r['accounts'][w]['wages'],arrears=0,future_guaranteed_days=0,initial_employer=self.r['initial']['affiliations'].get(w,{}).get('business',''),final_employer=self.affiliations.get(w,{}).get('business','')) for w,e in self.entities.items() if e['kind']=='resident'}
        businesses={}
        for b in OWNERS:
            book=self.r['final']['cash_results'][b];businesses[b]=dict(sales=book['sales'],inputs=book['inputs'],cash_payroll=book['payroll'],distributions=book['distributions'],accrued_wages=0,arrears=0,future_guaranteed_wages=0,cash_margin=book['sales']-book['inputs']-book['payroll'],cash=self.entities[b]['money'],inventory=self.entities[b]['inventory'],productive=self.r['accounts'][b]['shifts'])
        rows=[]
        for c in self.closures:
            w=workers[c['worker']];d=c['details'];attended=d['guaranteed_wage_due']==10
            for k,n in dict(scheduled=1,attended=int(attended),productive=int(c['success']),standby=int(attended and not c['success']),breaches=int(d['breach'])).items():w[k]+=n
            household=self.r['day_results'][c['day']-1]['households'][c['worker']]
            rows.append(dict(day=c['day'],worker=c['worker'],business=c['business'],scheduled=1,attended=int(attended),productive=int(c['success']),standby=int(attended and not c['success']),accrued=d['guaranteed_wage_due'],claim_paid_by_close=d['actual_compensation'],claim_arrears_by_close=d['arrears'],breach=d['breach'],attendance_event_id=d['attendance_event_id'],shift_event_id=d['shift_event_id'],closure_event_id=c['event_id'],cash_wages_on_day=household['wages'],meals=household['meals'],missed_meals=household['missed_meals']))
        for c in self.bound['obligations'].values():
            workers[c['worker']]['accrued']+=10;workers[c['worker']]['arrears']+=10-c['paid'];businesses[c['business']]['accrued_wages']+=10;businesses[c['business']]['arrears']+=10-c['paid']
        for b,row in businesses.items():row['accrued_margin']=row['cash_margin']-row['arrears'];assert row['cash_payroll']+row['arrears']==row['accrued_wages']
        for w,id in self.bound['active_terms'].items():
            term=self.bound['terms'][id];remaining=max(0,term['end_day']-max(term['start_day'],self.day+1))
            workers[w]['future_guaranteed_days']=remaining;businesses[term['business']]['future_guaranteed_wages']+=10*remaining
        counts=dict.fromkeys(('expired','released','renewed','nonrenewed','hired','rehired','changed_employer'),0)
        for e in self.events:
            if e['action']=='binding_term_closed':counts[e['details']['term']['status']]+=1
            if e['action']=='binding_term_disposition' and e['details']['disposition'] in ('renewed','nonrenewed','changed_employer'):counts[e['details']['disposition']]+=1
            if e['action']=='binding_term_started' and not e['details']['renewed']:counts['hired']+=1
            if e['action']=='binding_term_started' and e['details']['entry_kind']=='rehire':counts['rehired']+=1
        assert counts['renewed']+counts['hired']==self.r['labor']['counts']['employment_started']
        assert len(self.r['initial']['affiliations'])+self.r['labor']['counts']['employment_started']-self.r['labor']['counts']['employment_ended']==len(self.affiliations)
        assert self.r['contracts']==dict(mode=self.contract_mode,term_days=3,wage=10,workers=workers,businesses=businesses,worker_days=rows,days=self.binding_days,counts=counts,utilization_note='Legacy missed_shifts counts nonproductive due opportunities; only explicit binding breaches measure contract violation. Accrued margin expenses inputs without inventory valuation.')


def audit(data):
    fixture=data['report']['initial']['labor_market']['fixture']
    return replay(data,fixture=fixture not in ('none','no_show','staggered'),labor=BindingAudit())
