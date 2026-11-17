"""Independent M24 labor/knowledge replay layered on the strict M23 goods/cash audit.

This consumes native events, never imports policy code or accepts report aggregates as
evidence. Mutable replay state is shared only with the existing economic auditor.
"""
import copy
from collections import Counter
from itertools import groupby
from brewery_audit import audit as economic_audit, planned
from brewery_feasibility import WORKERS, OWNERS, SITES, WINDOWS


class LaborAudit:
    ACTIONS = set('labor_vacancy_assessed job_posted labor_notice_opened labor_notices_observed labor_search_decision application_submitted labor_applicants_ranked job_offer_made labor_offers_observed labor_acceptance_decision offer_accepted resignation_requested labor_transfer_scheduled labor_boundary employment_ended employment_started labor_assignment labor_notice_closed'.split())

    def attach(self, report, events, entities, firms, jobs, people, quotes, cargo, books):
        self.r, self.events = report, events
        self.entities, self.firms, self.jobs, self.people = entities, firms, jobs, people
        self.quotes, self.cargo = quotes, cargo
        initial = report['initial']; self.state = copy.deepcopy(initial['labor_market'])
        self.mode, self.tie = self.state['mode'], self.state['tie']
        assert self.mode in ('matching', 'shift_selection') and self.tie in ('neutral_rotate', 'legacy_sorted')
        assert self.state['homogeneous'] is True
        self.affiliations = copy.deepcopy(initial['affiliations'])
        self.postings, self.apps, self.pending, self.resignations = {}, {}, {}, {}
        assert all(initial[k] == {} for k in ('job_postings', 'applications', 'pending_hires', 'resignations'))
        assert all(self.state[k] == {} for k in ('notices', 'known_jobs', 'known_offers', 'contingent', 'history', 'sales', 'input_terms'))
        inactive = [w for w in jobs if not jobs[w]['active']]
        fixture = self.state['fixture']
        assert inactive == ([] if fixture == 'none' else ['gale' if fixture == 'vacancy' else fixture.split(':')[1]])
        assert self.affiliations == {w: dict(business=j['business'], kind='employee') for w, j in jobs.items() if j['active']}
        self.day = self.minute = 0

    def staff(self, f):
        return sorted(w for w in self.firms[f]['employees'] if self.jobs[w]['active'] and self.jobs[w]['business'] == f and self.affiliations.get(w) == dict(business=f, kind='employee'))

    def active_workers(self):
        return sorted(w for w in self.affiliations if self.jobs[w]['active'])

    def ordered(self, rows, day):
        rows = sorted(copy.deepcopy(rows), key=lambda w: (not w['available'], w['wage'], w['id']))
        if self.tie == 'legacy_sorted': return rows
        result = []
        for _, group in groupby(rows, key=lambda w: (w['available'], w['wage'])):
            group = list(group); offset = day % len(group)
            result.extend(group[offset:] + group[:offset])
        return result

    def context(self, day, minute, worked, due, harvested):
        self.day, self.minute, self.worked, self.due, self.harvested = day, minute, worked, due, harvested

    def board(self, who):
        p = self.people[who]
        assert self.mode == 'matching' and self.minute == 955 and p['active'] and p['kind'] == 'resident'
        assert p['tile'] == SITES['bakery'] and p['activity'] == 'board' and p['until'] == 960

    def witnesses(self):
        return sorted(w for w, p in self.people.items() if p['active'] and p['tile'] == SITES['bakery'])

    def public(self, id):
        n = self.state['notices'][id]
        return dict(copy.deepcopy(self.postings[id]), posted_day=n['day'], latest_start=n['latest_start'], schedule=n['schedule'])

    def worker(self, who):
        known = self.state['known_jobs'].get(who, {})
        history = [rows[who] for day, rows in sorted(self.state['history'].items(), key=lambda x: int(x[0])) if int(day) >= self.day-2 and who in rows]
        return dict(worker=who, day=self.day, business=self.affiliations.get(who, {}).get('business', ''), history=copy.deepcopy(history), notices=copy.deepcopy(known.get('notices', [])), notice_event_id=known.get('event_id'))

    def income(self, o):
        paid = sum(h['paid'] for h in o['history']); due = sum(h['due'] for h in o['history'])
        return dict(paid=paid, due=due, numerator=10*(paid+1) if o['business'] else 0, denominator=due+2 if o['business'] else 1)

    def search(self, o):
        current = self.income(o); eligible = []
        if (not o['business'] or current['paid'] < current['due']) and 5*current['denominator'] > current['numerator']:
            eligible = [p for p in o['notices'] if p['active'] and p['business'] != o['business'] and p['filled']+p['reserved'] < p['vacancies']]
        best = min(eligible, key=lambda p: p['id']) if eligible else None
        return dict(action='apply' if best else 'stay', posting=best['id'] if best else '', current_income=current, offer_income=dict(numerator=5, denominator=1) if best else {}, reason='strictly_better_observed_income' if best else 'status_quo_or_no_better_observed_vacancy')

    def vacancy(self, f, observation=None):
        rule = dict(farm=('wheat', '', 0, 7, ''), mill=('flour', 'wheat', 5, 5, 'mill'), bakery=('bread', 'flour', 5, 7, 'bake'), brewery=('ale', 'wheat', 3, 6, 'brew'))[f]
        out, raw, take, make, recipe = rule
        quote = self.state['input_terms'].get(f, {}).get('quote', {})
        available = lambda w: w not in self.worked and self.people[w]['active'] and self.people[w]['activity'] == 'idle' and self.people[w]['tile'] == SITES[f]
        workers = self.ordered([dict(id=w, wage=10, available=available(w)) for w in self.staff(f)], self.day)
        production = dict(owner=OWNERS[f], business=f, day=self.day,
            rule=dict(output=out, input=raw, recipe=recipe, batches=int(f != 'farm'), target=len(WORKERS[f])*make, take=take, make=make),
            cash=self.entities[f]['money'], output_stock=self.entities[f]['inventory'][out], input_stock=self.entities[f]['inventory'][raw]+self.cargo[f]['inventory'][raw] if raw else 0,
            output_price=self.quotes[f][out]['unit_price'], input_price=quote.get('unit_price', 0), input_quote=copy.deepcopy(quote), allow_procurement=True,
            harvest_remaining=self.r['initial']['brewery']['supply_cap']-self.harvested if f == 'farm' else 0, workers=workers)
        previous = self.state['sales'].get(str(self.day-1), {}).get(f, production['rule']['target'] if self.day <= 1 else 0)
        reserved = sum(p['reserved'] for p in self.postings.values() if p['business'] == f and p['active'])
        o = dict(owner=OWNERS[f], business=f, day=self.day, production=production, previous_sales=previous, staff=self.staff(f), reserved=reserved, capacity=len(WORKERS[f]), farm_cap=self.r['initial']['brewery']['supply_cap'] if f == 'farm' else 0, disabled=self.r['condition']=='no_brew_request' and f=='brewery')
        if observation is not None: assert observation == o, ('vacancy observation', f, observation, o)
        projected = copy.deepcopy(production); projected['output_stock'] = max(0, production['output_stock']-previous)
        projected['harvest_remaining'] = o['farm_cap'] if not raw else 0
        projected['workers'] = [dict(id=f'slot:{i}', wage=10, available=True) for i in range(o['capacity'])]
        p = planned(projected)
        n = 0 if o['disabled'] else max(0, min(o['capacity']-len(o['staff'])-reserved, p['shifts']-len(o['staff'])-reserved))
        return dict(vacancies=n, projected_shifts=p['shifts'], forecast_carry=projected['output_stock'], expected_receipts=p['expected_receipts'], committed_cash=p['committed_cash'], contribution=p['expected_receipts']-p['committed_cash'], reason='positive_funded_unfilled_position' if n else 'control_no_brew_request' if o['disabled'] else 'no_profitable_unfilled_position')

    def apply(self, e):
        action, actor, target, d = (e[k] for k in ('action', 'actor', 'target', 'details'))
        s = self.state
        if action == 'labor_vacancy_assessed':
            self.board(actor); assert OWNERS[target] == actor and d['proposal'] == self.vacancy(target, d['observation'])
        elif action == 'job_posted':
            self.board(actor); p = d['posting']; f = p['business']; assert f == target and OWNERS[f] == actor
            assert p == dict(id=p['id'], employer=actor, business=f, role=self.firms[f]['industry'], wage=10, guaranteed_shifts=1, cycle_days=1, duration_days=30, required_skills=[], vacancies=p['vacancies'], reserved=0, filled=0, active=True)
            assert p['id'] not in self.postings and 0 < p['vacancies'] <= self.vacancy(f)['vacancies']
            assert not any(n['business']==f and n['day']==self.day for n in s['notices'].values())
            self.postings[p['id']] = copy.deepcopy(p)
        elif action == 'labor_notice_opened':
            n = d['notice']; p = self.postings[n['id']]; assert p['business'] == target and p['employer'] == actor
            assert n == dict(id=p['id'], business=target, day=self.day, latest_start=self.day+1, schedule=list(WINDOWS[target]), status='open')
            assert self.events[d['posting_event_id']-1]['details']['posting'] == p
            s['notices'][n['id']] = copy.deepcopy(n)
        elif action == 'labor_notices_observed':
            self.board(actor); expected = [self.public(id) for id, n in sorted(s['notices'].items()) if self.postings[id]['active'] and n['day']==self.day]
            assert d == dict(notices=expected, witnesses=self.witnesses())
            s['known_jobs'][actor] = dict(day=self.day, event_id=e['id'], notices=copy.deepcopy(expected))
        elif action == 'labor_search_decision':
            self.board(actor); assert actor not in OWNERS.values()
            assert d['observation'] == self.worker(actor) and d['proposal'] == self.search(self.worker(actor))
            assert target == d['proposal']['posting']
        elif action == 'application_submitted':
            self.board(actor); a = d['application']; p = self.postings[a['posting']]
            assert p['active'] and p['filled']+p['reserved'] < p['vacancies'] and a['worker']==actor and a['status']=='applied'
            assert actor not in OWNERS.values() and self.affiliations.get(actor, {}).get('business') != target and actor not in self.pending and actor not in self.resignations
            assert any(n['id']==p['id'] for n in s['known_jobs'][actor]['notices']) and a['id']==p['id']+':'+actor and a['id'] not in self.apps
            self.apps[a['id']] = copy.deepcopy(a)
        elif action == 'labor_applicants_ranked':
            self.board(actor); assert OWNERS[target]==actor
            rows = [dict(id=a['worker'], wage=10, available=True, application_id=a['id']) for a in self.apps.values() if self.postings[a['posting']]['business']==target and a['status']=='applied']
            for row in rows:self.board(row['id'])
            assert d == dict(candidates=self.ordered(rows,self.day), tie=self.tie, reason='equal_financial_contribution')
        elif action == 'job_offer_made':
            a = self.apps[d['application_id']]; p = self.postings[a['posting']]
            self.board(actor); self.board(a['worker']); assert actor==p['employer'] and target==p['business'] and a['status']=='applied'
            assert p['active'] and p['filled']+p['reserved']<p['vacancies'] and self.vacancy(target)['vacancies']>0
            assert d==dict(application_id=a['id'],worker=a['worker'],posting=p['id'])
            a['status']='offered';p['reserved']+=1
        elif action == 'labor_offers_observed':
            self.board(actor)
            offers=[dict(application_id=id,posting=self.public(a['posting'])) for id,a in sorted(self.apps.items()) if a['worker']==actor and a['status']=='offered' and self.postings[a['posting']]['active']]
            for offer in offers:self.board(offer['posting']['employer'])
            assert d==dict(offers=offers,witnesses=self.witnesses())
            s['known_offers'][actor]=dict(day=self.day,event_id=e['id'],offers=copy.deepcopy(offers))
        elif action == 'labor_acceptance_decision':
            o=self.worker(actor);current=self.income(o);offers=s['known_offers'][actor]
            better=5*current['denominator']>current['numerator']
            assert d==dict(observation=o,offers_event_id=offers['event_id'],accepts=better and bool(offers['offers']),reason='no_observed_offer' if not offers['offers'] else 'strict_income_improvement' if better else 'status_quo_wins')
        elif action == 'offer_accepted':
            a=self.apps[d['application_id']];p=self.postings[a['posting']]
            self.board(actor);self.board(p['employer']);assert a['worker']==actor and a['status']=='offered' and actor not in self.pending
            assert any(o['application_id']==a['id'] for o in s['known_offers'][actor]['offers'])
            assert p['active'] and p['reserved']>0 and self.vacancy(target)['projected_shifts']>=len(self.staff(target))+sum(q['reserved'] for q in self.postings.values() if q['business']==target and q['active'])
            expected=dict(posting=p['id'],application_id=a['id'],effective_day=self.day+1)
            assert d['pending']==expected;a['status']='accepted';self.pending[actor]=expected
        elif action == 'resignation_requested':
            assert actor in self.pending and self.affiliations[actor]['business']==target and actor not in self.resignations
            assert d==dict(business=target,effective_day=self.day+1);self.resignations[actor]=copy.deepcopy(d)
        elif action == 'labor_transfer_scheduled':
            pending=self.pending[actor]
            assert d==dict(application_id=pending['application_id'],posting=pending['posting'],old=self.affiliations.get(actor,{}),effective_day=self.day+1)
            s['contingent'][actor]=copy.deepcopy(d)
        elif action == 'labor_boundary':
            assert self.minute==1440 and d==dict(effective_day=self.day+1,pending=self.pending)
            for w,pending in self.pending.items():
                assert self.affiliations.get(w,{})==s['contingent'][w]['old'] and pending['effective_day']==self.day+1
                p=self.postings[pending['posting']];assert p['active'] and s['notices'][p['id']]['latest_start']==self.day+1
                assert self.vacancy(p['business'])['projected_shifts']>=len(self.staff(p['business']))+sum(q['reserved'] for q in self.postings.values() if q['business']==p['business'] and q['active'])
        elif action == 'employment_ended':
            assert self.minute==1440 and d['effective_day']==self.day+1 and self.affiliations[actor]==d['affiliation']
            expired=self.jobs[actor]['end_day']>0 and self.jobs[actor]['end_day']<=self.day+1
            assert d['reason']==('duration_complete' if expired else 'resigned') and (expired or actor in self.resignations)
            self.jobs[actor].update(active=False,end_day=self.day+1)
            assert self.jobs[actor]==d['job'];self.affiliations.pop(actor);self.resignations.pop(actor,None)
        elif action == 'employment_started':
            assert self.minute==1440 and actor not in self.affiliations
            pending=self.pending.pop(actor);p=self.postings[pending['posting']]
            assert pending['effective_day']==self.day+1==d['effective_day'] and d['posting']==p['id']
            job=dict(worker=actor,business=target,wage=10,active=True,start_day=self.day+1,end_day=self.day+31,contract=dict(cycle_days=1,shifts_per_cycle=1,cycle_compensation=10,phases=[1]))
            assert d['job']==job and target==p['business'] and d['affiliation']==dict(business=target,kind='employee')
            self.jobs[actor]=job;self.affiliations[actor]=copy.deepcopy(d['affiliation'])
            if actor not in self.firms[target]['employees']:self.firms[target]['employees'].append(actor)
            p['reserved']-=1;p['filled']+=1;p['active']=p['filled']<p['vacancies'];self.apps[pending['application_id']]['status']='started'
        elif action == 'labor_assignment':
            receipt=self.events[d['employment_event_id']-1];assert receipt['actor']==actor and receipt['action'] in ('employment_ended','employment_started')
            business=self.affiliations.get(actor,{}).get('business','');removed=[]
            for f in OWNERS:
                if f!=business and actor in self.firms[f]['employees']:self.firms[f]['employees'].remove(actor);removed.append(f)
            assert d['removed_from']==removed and target==business
            schedule=self.people[actor]['schedule'];schedule.update(business=business,first_destination=SITES[business] if business else self.people[actor]['home'],work_start=WINDOWS[business][0] if business else 0,work_end=WINDOWS[business][1] if business else 0,owner=False,courier={})
            assert d['schedule']==schedule
        elif action == 'labor_notice_closed':
            p=self.postings[d['posting']];canceled=[];applications=[]
            pending=[w for w,q in self.pending.items() if q['posting']==p['id']]
            reason=d['reason']
            if reason=='withdrawn':self.board(actor);assert actor==p['employer']
            else:assert self.minute==1440
            if reason=='expired_unaccepted':assert not pending
            elif reason=='filled':assert p['filled']==p['vacancies'] and not pending
            elif reason=='partially_filled':assert 0<p['filled']<p['vacancies'] and not pending
            elif reason=='changed_capacity_or_funding':
                reserved=sum(q['reserved'] for q in self.postings.values() if q['business']==p['business'] and q['active'])
                assert len(self.staff(p['business']))+reserved>len(WORKERS[p['business']]) or self.vacancy(p['business'])['projected_shifts']<len(self.staff(p['business']))+reserved
            elif reason=='changed_old_affiliation':assert any(self.affiliations.get(w,{})!=s['contingent'][w]['old'] for w in pending)
            else:assert reason in ('withdrawn','expired','changed_fixed_terms','expired_or_closed_notice')
            for a in self.apps.values():
                if a['posting']!=p['id'] or a['status']=='started':continue
                w=a['worker']
                if self.pending.get(w,{}).get('application_id')==a['id']:
                    self.pending.pop(w);self.resignations.pop(w,None);s['contingent'].pop(w);canceled.append(w)
                a['status']='closed';applications.append(copy.deepcopy(a))
            p.update(active=False,reserved=0);s['notices'][p['id']]['status']=d['reason']
            assert d['state']==p and d['canceled_pending']==canceled and d['applications']==applications

    def after(self,e):
        s=self.state;action=e['action'];day=str(e['day']);actor=e['actor']
        if action=='day_started':
            s['known_jobs'].clear();s['known_offers'].clear()
            for key in list(s['history']):
                if int(key)<self.day-2:del s['history'][key]
            for key in list(s['sales']):
                if int(key)<self.day-1:del s['sales'][key]
            for w in list(s['contingent']):
                if w not in self.pending:s['contingent'].pop(w)
        if e['success'] and action=='purchase':
            rows=s['sales'].setdefault(day,{});rows[e['target']]=rows.get(e['target'],0)+e['details']['quantity']
        if e['success'] and action=='spatial_encounter' and e['details']['kind']=='inspected':
            for f,owner in OWNERS.items():
                if owner!=actor or f=='farm':continue
                raw='flour' if f=='bakery' else 'wheat'
                for item,q in self.quotes[e['target']].items():
                    if item==raw:s['input_terms'][f]=dict(day=self.day,inspection_event_id=e['id'],quote=dict(q,available=min(q['limit'],self.entities[e['target']]['inventory'][item])))
        if action in ('contract_due','work_shift','contract_shift') and actor in self.entities and self.entities[actor]['kind']=='resident':
            h=s['history'].setdefault(day,{}).setdefault(actor,dict(day=e['day'],due=0,paid=0,due_event_id=None,wage_event_id=None,shift_event_id=None,closure_event_id=None))
            if e['success'] and action=='contract_due':h['due']+=1;h['due_event_id']=e['id']
            if e['success'] and action=='work_shift':h['paid']+=1;h['wage_event_id']=e['details']['payment_event_id'];h['shift_event_id']=e['id']
            if action=='contract_shift':h['closure_event_id']=e['id']
        if e['success'] and action=='business_plan':
            d=e['details'];candidates=[dict(id=w['id'],wage=w['wage'],available=w['available'],selected=w['id'] in d['proposal']['workers'],reason='not_available' if not w['available'] else 'equal_financial_return_'+self.tie if w['id'] in d['proposal']['workers'] else 'outside_profitable_funded_plan') for w in d['observation']['workers']]
            assert d['selection']==dict(tie=self.tie,objective='conditional_receipts_minus_missing_inputs_and_wages',candidates=candidates)

    def finish(self):
        final=self.r['final']
        assert self.state==final['labor_market'] and self.affiliations==final['affiliations'] and self.firms==final['businesses']
        for key,value in [('job_postings',self.postings),('applications',self.apps),('pending_hires',self.pending),('resignations',self.resignations)]:assert final[key]==value,key
        assert final['labor_used']=={w:1 for w in self.worked}
        assert final['business_labor']==dict(Counter(self.affiliations[w]['business'] for w in self.worked))
        counts=dict.fromkeys(('postings','applications','offers','accepted','employment_started','employment_ended','canceled_pending','rejections'),0);transitions=[];reasons=Counter()
        mapping=dict(job_posted='postings',application_submitted='applications',job_offer_made='offers',offer_accepted='accepted',employment_started='employment_started',employment_ended='employment_ended')
        for e in self.events:
            a=e['action']
            if not e['success']:
                counts['rejections']+=int(a in ('job_posted','application_submitted','job_offer_made','offer_accepted','resignation_requested'));continue
            if a in mapping:counts[mapping[a]]+=1
            if a in ('employment_started','employment_ended'):transitions.append({k:e[k] for k in ('day','minute','action','details')}|dict(worker=e['actor'],business=e['target']))
            if a=='labor_notice_closed':counts['canceled_pending']+=len(e['details']['canceled_pending'])
            if a=='labor_search_decision':reasons[e['details']['proposal']['reason']]+=1
        assert self.r['labor']==dict(mode=self.mode,tie=self.tie,fixture=self.state['fixture'],wage=10,counts=counts,search_reasons=dict(reasons),transitions=transitions,qualification='M24 homogeneous labor; historical skill arrays unchanged')


def audit(data):
    return economic_audit(data,labor=LaborAudit())
