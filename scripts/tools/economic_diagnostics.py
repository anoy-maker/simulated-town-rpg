"""M27 researcher-only passive diagnostics over the unchanged independent M26 audit.

No simulation import/authority and no writes to source traces or NPC observations.
All factual rows are emitted only if the complete inherited native audit succeeds.
"""
import copy
import hashlib
import json
from collections import Counter,defaultdict
from demand_audit import DemandAudit,PRODUCT
from brewery_audit import audit as replay
from brewery_feasibility import OWNERS
from run_brewery import digest

BASE='2bc13ef8ca92809a77eaf78a47168d97fd8bf939'
FLAGS=('natural_resource_cap','batch_asset_worker_limit','legal_contract_restriction',
       'input_clearing_rationing','timing_working_capital','stockout_forecast_lower_bound',
       'standby_obligation','firm_profitability_incentive','household_purchasing_power')


class EconomicAudit(DemandAudit):
    """Observer of independently reconstructed facts; existing checks stay intact."""
    def attach(self,*args):
        super().attach(*args)
        self.books=args[-1]
        self.snapshots={};self.evidence=defaultdict(lambda:dict(plans={},intents=[],visitors=[],orders=[],clearing=None))
        self.cash=[];self.flows=[];self.constraints=[];self.failures=[];self.shops={}
        self.firm_days={};self.cohorts={};self.last_cash={k:v['money'] for k,v in self.entities.items()}
        self.forecast_sources={};self.intent_sources={};self.claim_totals=[]

    def flag(self,e,flag,subject,detail,status='direct',additional=None):
        assert flag in FLAGS and status in ('direct','inferred','ambiguous','unknown')
        self.constraints.append(dict(day=e['day'],minute=e['minute'],event_id=e['id'],subject=subject,
                                     flag=flag,evidence=status,detail=detail,additional_source_ids=additional or []))

    def timeline(self,e,kind,actor,target,amount=0,before=None,after=None,**extra):
        if e['day'] not in (1,3):return
        self.cash.append(dict(day=e['day'],minute=e['minute'],event_id=e['id'],kind=kind,actor=actor,target=target,
                              coins=amount,balance_before=before,balance_after=after,**extra))

    def after(self,e):
        super().after(e)
        a,w,b,d=(e[k] for k in ('action','actor','target','details'));day=e['day']
        if a=='day_started':
            if day in (1,3):
                self.snapshots[day]=copy.deepcopy(dict(day=day,condition=self.r['condition'],source_event_id=e['id'],
                    entities=self.entities,businesses=self.firms,employment=self.jobs,affiliations=self.affiliations,
                    people=self.people,cargo=self.cargo,quotes=self.quotes,books=self.books,binding=self.bound,
                    assets=self.r['initial']['productive_assets'],cap=self.r['initial']['brewery']['supply_cap']))
            for firm in OWNERS:
                self.firm_days[day,firm]=dict(day=day,firm=firm,opening_cash=self.entities[firm]['money'],
                    opening_inventory=copy.deepcopy(self.entities[firm]['inventory']),produced=0,productive=0,standby=0,
                    opening_cargo=copy.deepcopy(self.cargo[firm]['inventory']),opening_arrears=self.arrears(firm),
                    active_workers=self.staff(firm),produced_goods=dict.fromkeys(PRODUCT.values(),0),
                    consumed_inputs=dict.fromkeys(PRODUCT.values(),0),purchased_inputs=dict.fromkeys(PRODUCT.values(),0),sold_goods=dict.fromkeys(PRODUCT.values(),0),
                    accrued_wages=0,paid_wages=0,distributions=0,sales=0,input_spending=0,
                    requested=0,fulfilled=0,unfilled=0,minimum_cash=self.entities[firm]['money'],source_ids=[])
            for cohort in ('resident','visitor'):
                for item in ('bread','ale'):
                    self.cohorts[day,cohort,item]=dict(day=day,cohort=cohort,item=item,visits=0,positive_requests=0,
                        requested=0,filled=0,stockout_unfilled=0,unaffordable_visits=0,consumed=0,source_ids=[])
        if not e['success']:
            reason=d.get('reason','')
            if reason in ('unfunded_payroll','insufficient_funds','guarantee_not_fully_paid'):
                self.flag(e,'timing_working_capital',b,reason)
            if reason in ('binding_term_active','binding_term_cannot_be_cancelled','not_employed'):
                self.flag(e,'legal_contract_restriction',w,reason)
            if a=='consume' and d.get('item')=='bread' and self.entities.get(w,{}).get('kind')=='resident':
                visit=self.shops.get((day,w,'bakery'));source=self.intent_sources.get((day,w,'bakery'))
                cause='unresolved';status='unknown';flags=[];ids=[];cash=None;stock=None
                if visit:
                    o=visit['details']['observation'];cash=o['money'];stock=o['stock'].get('bread');ids.append(visit['id'])
                    if o['need_bread']>0 and 'bread' in o['prices'] and cash<o['prices']['bread']:
                        cause='household_purchasing_power';status='direct';flags.append(cause)
                    elif source and source['details']['quantity']>0 and stock==0:
                        cause='stockout_of_solvent_request';status='direct';flags.append('stockout_forecast_lower_bound')
                    if stock==0:flags.append('empty_shelf_observed')
                if source:ids.append(source['id'])
                self.failures.append(dict(day=day,minute=e['minute'],event_id=e['id'],buyer=w,cohort='resident',
                    actual='missed_meal',immediate_blocker=cause,evidence=status,shopping_cash=cash,
                    shopping_bread_stock=stock,flags=flags,source_ids=ids,latent_demand='unknown'))
            return
        if a in ('purchase','transfer_money'):
            amount=d['total_price'] if a=='purchase' else d['amount']
            now={k:v['money'] for k,v in self.entities.items()}
            assert now[w]==self.last_cash[w]-amount and now[b]==self.last_cash[b]+amount
            assert sum(now.values())==9192 and min(now.values())>=0
            purpose=d['item'] if a=='purchase' else d['purpose']
            self.timeline(e,'money_transfer',w,b,amount,self.last_cash[w],now[w],purpose=purpose,
                          recipient_before=self.last_cash[b],recipient_after=now[b],currency=9192)
            if w in OWNERS:
                f=self.firm_days[day,w]
                f['input_spending' if a=='purchase' else 'paid_wages' if purpose=='wage' else 'distributions']+=amount
                f['minimum_cash']=min(f['minimum_cash'],now[w]);f['source_ids'].append(e['id'])
                if a=='purchase':f['purchased_inputs'][d['item']]+=d['quantity']
            if b in OWNERS:
                self.firm_days[day,b]['sales']+=amount;self.firm_days[day,b]['source_ids'].append(e['id'])
                if a=='purchase':self.firm_days[day,b]['sold_goods'][d['item']]+=d['quantity']
            self.last_cash=now
        if a in ('harvest','produce','spatial_deposited','purchase'):
            self.flows.append(dict(day=day,minute=e['minute'],event_id=e['id'],action=a,actor=w,target=b,
                item=d.get('item',''),quantity=d.get('quantity',d.get('amount',0)),inputs=copy.deepcopy(d.get('inputs',{})),
                outputs=copy.deepcopy(d.get('outputs',{'wheat':d['amount']} if a=='harvest' else d.get('goods',{})))))
        if a in ('harvest','produce'):
            qty=d['amount'] if a=='harvest' else d['outputs'][PRODUCT[w]]
            self.firm_days[day,w]['produced']+=qty
            f=self.firm_days[day,w];f['produced_goods'][PRODUCT[w]]+=qty;f['source_ids'].append(e['id'])
            for item,quantity in d.get('inputs',{}).items():f['consumed_inputs'][item]+=quantity
        if a=='spatial_deposited':self.firm_days[day,b]['source_ids'].append(e['id'])
        if a=='work_shift':self.firm_days[day,b]['productive']+=1
        if a=='contract_attended' and d['kind']=='standby':
            self.firm_days[day,b]['standby']+=1;self.flag(e,'standby_obligation',b,'verified hour earns wage without output')
        if a=='guaranteed_wage_due':
            claim=d['claim'];self.firm_days[day,b]['accrued_wages']+=claim['amount']
            self.timeline(e,'earned_wage_claim',b,w,0,claim_id=claim['id'],liability=claim['amount'])
        if a=='wage_payment_applied':
            self.timeline(e,'wage_claim_application',b,w,0,claim_id=d['claim'],liability_remaining=d['arrears'])
        if a=='business_plan':
            if day in (1,3):self.evidence[day]['plans'][b+':'+d['phase']]=copy.deepcopy(e)
            o,p=d['observation'],d['proposal'];reason=p['reason']
            self.timeline(e,'firm_planning_cash',w,b,0,o['cash'],o['cash'],phase=d['phase'],committed_payroll=o['committed_payroll'])
            if reason in ('working_capital','no_eligible_worker') and len(o['funded_workers'])<len(o['workers']):
                self.flag(e,'timing_working_capital',b,'current guaranteed payroll reduces funded worker set')
            if reason=='missing_deposited_inputs':self.flag(e,'input_clearing_rationing',b,reason)
            if reason in ('nonpositive_expected_contribution','output_target_met'):
                self.flag(e,'firm_profitability_incentive',b,reason)
            if reason in ('no_eligible_worker','harvest_capacity'):
                self.flag(e,'batch_asset_worker_limit',b,reason)
        if a=='grain_cleared':
            if day in (1,3):self.evidence[day]['clearing']=copy.deepcopy(e)
            for firm,lot in [('mill',5),('brewery',3)]:
                if d['allocation'][firm]<d['eligible'][firm]:
                    self.flag(e,'input_clearing_rationing',firm,'whole grain lots rationed at shared clearing')
        if a=='demand_order_observed':
            f=self.firm_days[day,b]
            for dst,src in [('requested','quantity'),('fulfilled','filled'),('unfilled','unfilled')]:f[dst]+=d[src]
            if day in (1,3):self.evidence[day]['orders'].append(copy.deepcopy(e))
            if d['kind']=='retail':
                cohort='visitor' if w.startswith('visitor:') else 'resident';row=self.cohorts[day,cohort,d['item']]
                row['requested']+=d['quantity'];row['filled']+=d['filled'];row['stockout_unfilled']+=d['unfilled']
            if d['unfilled']:
                self.flag(e,'stockout_forecast_lower_bound' if d['kind']=='retail' else 'input_clearing_rationing',b,
                          f'credible direct {d["item"]} request unfilled={d["unfilled"]}')
        if a=='demand_customer_intent':
            self.intent_sources[day,w,b]=copy.deepcopy(e)
            cohort='visitor' if w.startswith('visitor:') else 'resident';row=self.cohorts[day,cohort,d['item']]
            row['positive_requests']+=int(d['quantity']>0);row['source_ids'].append(e['id'])
            if day in (1,3):self.evidence[day]['intents'].append(copy.deepcopy(e))
        if a=='consumer_decision':
            self.shops[day,w,b]=copy.deepcopy(e);o=d['observation'];cohort='visitor' if w.startswith('visitor:') else 'resident'
            row=self.cohorts[day,cohort,d['item']];row['visits']+=1
            price=o['prices'].get(d['item']);unfunded=price is not None and o['need_'+d['item']]>0 and o['money']<price
            row['unaffordable_visits']+=int(unfunded)
            self.timeline(e,'shopping_time_cash',w,b,0,o['money'],o['money']-d['purchased']*(price or 0),
                          item=d['item'],purchased=d['purchased'],stock=o['stock'].get(d['item']),unaffordable=unfunded)
            if unfunded:self.flag(e,'household_purchasing_power',w,'insufficient funds at actual shopping quote')
        if a=='consume' and d['item'] in ('bread','ale'):
            cohort='visitor' if w=='visitors' else 'resident';self.cohorts[day,cohort,d['item']]['consumed']+=d['amount']
        if a=='spatial_visitor_entered' and day in (1,3):self.evidence[day]['visitors'].append(copy.deepcopy(e))
        if a=='labor_search_decision' and not d['observation']['eligible']:
            self.flag(e,'legal_contract_restriction',w,'existing exclusive term cannot be abandoned for today')
        if a=='labor_vacancy_assessed' and d['proposal']['reason']=='no_profitable_new_commitment':
            self.flag(e,'firm_profitability_incentive',b,'no additional profitable term in observed own forecast')
        if a=='demand_forecast':self.forecast_sources[day,b]=copy.deepcopy(e)
        if a=='demand_day_closed':
            f=self.firm_days[day,b];f.update(coverage=d['complete'],censored=d['censored'],demand_status='lower_bound' if d['censored'] else 'observed_window')
            if b in ('bakery','brewery'):
                for cohort in ('resident','visitor'):
                    self.cohorts[day,cohort,PRODUCT[b]].update(seller_censored=d['censored'],traffic_status='lower_bound' if d['censored'] else 'observed_window',latent_demand='unknown')
            prior=self.forecast_sources.get((day-1,b));lower=d['sales']+d['unfilled']
            if prior and prior['details']['forecast']<lower:
                self.flag(e,'stockout_forecast_lower_bound',b,'previous meeting point below today\'s observed lower bound',
                          'inferred',[prior['id']])
        if a=='binding_day_closed':
            liabilities=sum(d['liabilities'].values());receivables=sum(d['receivables'].values())
            assert liabilities==receivables==sum(c['amount']-c['paid'] for c in self.bound['obligations'].values())
            self.claim_totals.append(dict(day=day,event_id=e['id'],payable=liabilities,receivable=receivables))
            for firm in OWNERS:
                f=self.firm_days[day,firm];f.update(closing_cash=self.entities[firm]['money'],closing_inventory=copy.deepcopy(self.entities[firm]['inventory']),closing_cargo=copy.deepcopy(self.cargo[firm]['inventory']),
                    arrears=d['liabilities'][firm],future_guarantees=sum(t['wage']*max(0,t['end_day']-max(day+1,t['start_day'])) for t in self.bound['terms'].values() if t['status']=='active' and t['business']==firm))
                assert f['closing_cash']==f['opening_cash']+f['sales']-f['input_spending']-f['paid_wages']-f['distributions']
                assert f['opening_arrears']+f['accrued_wages']-f['paid_wages']==f['arrears']
                for item in PRODUCT.values():
                    assert f['opening_inventory'][item]+f['opening_cargo'][item]+f['produced_goods'][item]+f['purchased_inputs'][item]-f['consumed_inputs'][item]-f['sold_goods'][item]==f['closing_inventory'][item]+f['closing_cargo'][item]
                if firm=='farm' and f['produced']==self.r['initial']['brewery']['supply_cap']:
                    self.flag(e,'natural_resource_cap',firm,'actual harvest reaches daily cap; not a new-job profitability statement')
                if f['productive']==self.firms[firm]['assets']['daily_slots']:
                    self.flag(e,'batch_asset_worker_limit',firm,'installed productive slots fully used')
        if a=='binding_boundary_closed':
            for firm in OWNERS:
                f=self.firm_days[day,firm]
                f['future_guarantees']=sum(t['wage']*max(0,t['end_day']-max(day+1,t['start_day'])) for t in self.bound['terms'].values() if t['status']=='active' and t['business']==firm)
                f['future_guarantees_event_id']=e['id'];f['future_guarantees_minute']=e['minute']
                self.timeline(e,'future_term_guarantees',firm,'employees',0,guaranteed_coins=f['future_guarantees'],note='conditional future compensation, not current coins or earned debt')


def analyze(data,observer=None,fixture=False):
    """Fully audit before returning any researcher outputs; never modify data."""
    if 'events' not in data:raise ValueError('unobserved: full native events required; final cash cannot replace shopping-time funds')
    before=digest(data);observer=EconomicAudit() if observer is None else observer
    result=replay(data,fixture=fixture or 'demand_fixture' in data['report']['initial'],labor=observer)
    assert digest(data)==before,'diagnostic mutated its source trace'
    source=dict(base=BASE,report_sha256=digest(dict(report=data['report'])),ledger_sha256=data['report']['ledger_sha256'])
    snapshots={str(day):dict(state=s,snapshot_sha256=digest(s),source=source,evidence=observer.evidence[day]) for day,s in observer.snapshots.items()}
    return dict(source=source,audit=result,snapshots=snapshots,cash=observer.cash,firm_days=list(observer.firm_days.values()),
                cohorts=list(observer.cohorts.values()),constraints=observer.constraints,failure_attributions=observer.failures,
                claim_totals=observer.claim_totals,definitions=dict(currency='whole coins',quantities='whole commodity units',
                resident_meals='one daily need per resident',visitor_visits='opportunities, not a guaranteed consumption need',
                cause='immediate evidence-supported blocker; overlapping contributors allowed',latent_demand='unknown when censored'))
