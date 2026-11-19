"""M29 opt-in endowment validator, retaining original structural/economic audits."""
import copy
from input_audit import InputAudit
from economic_diagnostics import analyze as replay
from brewery_feasibility import OWNERS

BASE='29aae2f3852965968a9cefcf06f508c2ff469890'
ALLOCATIONS=('original','households_330','firms_330')
NONOWNERS=('dain','edda','finn','gale','hale','iona','jory','kira','lyle','nell','oren')
EXTRA=dict(farm=83,mill=83,bakery=82,brewery=82)


def initial_cash(allocation):
    assert allocation in ALLOCATIONS
    values={w:6 for w in (*OWNERS.values(),*NONOWNERS)};values.update(dict.fromkeys(OWNERS,120));values['visitors']=8622
    if allocation!='original':values['visitors']-=330
    if allocation=='households_330':
        for w in NONOWNERS:values[w]+=30
    if allocation=='firms_330':
        for b,n in EXTRA.items():values[b]+=n
    assert len(values)==20 and sum(values.values())==9192
    return values


class CashAudit(InputAudit):
    SCENARIO='settlement_cash_allocation'

    def validate_initial_jobs(self,initial,jobs):
        allocation=self.r['cash_allocation']['name'];expected=initial_cash(allocation)
        assert set(initial['entities'])==set(expected)
        normalized=copy.deepcopy(initial)
        for who,e in initial['entities'].items():
            assert type(e['money']) is int and e['money']==expected[who] and not any(e['inventory'].values())
            normalized['entities'][who]['money']=initial_cash('original')[who]
        assert initial['labor_market']['fixture']=='none' and 'input_fixture' not in initial and 'demand_fixture' not in initial
        assert all(all(v==0 for v in book.values()) for book in initial['cash_results'].values())
        assert self.r['cash_allocation']==dict(name=allocation,initial_accounts=expected,source_event_id=1,kind='initial_ownership_not_income')
        super().validate_initial_jobs(normalized,jobs)


def analyze(data):
    observer=CashAudit();result=replay(data,observer,fixture=True)
    result['source']['base']=BASE
    result['input']=dict(orders=observer.input_orders,forecasts=observer.input_forecasts,projections=observer.input_projections)
    return result
