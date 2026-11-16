"""Independent M17 physical/custody/encounter replay, alongside native receipt finance."""
import copy
from enterprise_audit import audit as financial_audit
SITES = {'farm':[6,1], 'mill':[6,3], 'bakery':[8,3]}
WINDOWS = {'farm':(540,600), 'mill':(660,720), 'bakery':(840,900)}
TRADE = {'farm':(600,660), 'mill':(720,780), 'bakery':(900,1035)}


def route(start, destination):
    tile = list(start)
    result = []
    for axis in (0,1):
        while tile[axis] != destination[axis]:
            tile[axis] += 1 if tile[axis] < destination[axis] else -1
            result.append(list(tile))
    return result


def audit(data):
    financial_audit(data)
    r, history = data['report'], data['events']
    space = copy.deepcopy(r['initial']['spatial'])
    people = space['presences']
    firms = r['initial']['businesses']
    seen, quantities = {}, {}
    external_bread = 0
    day = 0
    for e in history:
        action, actor, target, d = (e[k] for k in ('action','actor','target','details'))
        if action == 'day_started':
            day += 1
            space['minute'] = 0
        if e['success'] and action == 'spatial_clock':
            assert d['from'] == space['minute'] and d['to'] == d['from'] + 5 <= 1440
            space['minute'] = d['to']
        minute = space['minute']
        absolute = max(0, day-1)*1440 + minute
        assert e['day'] == day and e['minute'] == minute and minute % 5 == 0 and e['absolute_minute'] == absolute
        if not e['success']:
            continue
        if action == 'spatial_departed':
            p = people[actor]
            expected = route(p['tile'], d['destination'])
            assert p['active'] and p['activity'] == 'idle' and expected == d['route'] and expected
            assert minute + len(expected)*5 <= d['arrive_by'] <= 1440
            p.update(destination=list(d['destination']),route=expected,activity='walking',until=0,last_step=absolute)
        elif action == 'spatial_moved':
            p = people[actor]
            assert p['active'] and p['activity'] == 'walking' and p['tile'] == d['from'] and p['route'][0] == d['to']
            assert sum(abs(a-b) for a,b in zip(d['to'],d['from'])) == 1 and absolute-p['last_step'] >= 5
            p['tile'] = list(d['to'])
            p['route'].pop(0)
            p['last_step'] = absolute
        elif action == 'spatial_arrived':
            p = people[actor]
            assert p['activity'] == 'walking' and not p['route'] and p['tile'] == p['destination'] == d['tile']
            p['activity'] = 'idle'
        elif action == 'spatial_stayed':
            assert people[actor]['tile'] == d['tile'] and people[actor]['activity'] == 'idle'
        elif action == 'spatial_activity_started':
            p = people[actor]
            assert p['active'] and p['activity'] == 'idle' and d['until'] == minute+d['duration'] <= 1440
            if d['kind'] in ('work','manage'):
                assert p['tile'] == SITES[target] and minute == WINDOWS[target][0] and d['duration'] == 60
                if d['kind'] == 'manage': assert firms[target]['owner'] == actor
            elif d['kind'] in ('shop','procure','deposit'):
                assert d['duration'] == 5
            else:
                assert d['kind'] == 'rest' and p['tile'] == p['home'] and minute >= 1110 and d['until'] == 1440
            p.update(activity=d['kind'],until=d['until'],business=target)
        elif action == 'spatial_activity_ended':
            p = people[actor]
            assert p['activity'] == d['kind'] and p['until'] == minute
            if d['kind'] == 'work':
                work = history[d['result_event_id']-1]
                assert work['action'] == 'work_shift' and work['actor'] == actor and work['minute'] == minute
            p.update(activity='idle',until=0,business='')
        elif action == 'spatial_visitor_entered':
            p = d['presence']
            assert actor not in people and actor == f"visitor:{day:04}:{d['slot']}" and 1 <= d['slot'] <= 6
            assert minute == 1020 and p['tile'] == p['home'] == [9,3] and p['account'] == 'visitors' and not p['loaf'] and 'money' not in p
            people[actor] = copy.deepcopy(p)
        elif action == 'spatial_visitor_exited':
            p = people[actor]
            assert p['active'] and p['activity'] == 'idle' and p['tile'] == [9,3] and not p['loaf']
            p['active'] = False
        elif action == 'purchase':
            presence = e['physical_actor']
            p = people[presence]
            closes = space['retail_close'] if target == 'bakery' else TRADE[target][1]
            assert p['active'] and p['tile'] == SITES[target] and TRADE[target][0] <= minute < closes
            assert p['activity'] in ('shop','procure') and p['until'] > minute
            quantities[presence] = quantities.get(presence,0)+d['quantity']
            if actor in firms:
                assert d['custody'] == dict(business=actor,holder=presence) and firms[actor]['owner'] == presence
            elif actor == 'visitors':
                assert p['kind'] == 'visitor' and not p['purchased'] and not p['loaf'] and d['quantity'] == 1
                p.update(purchased=True,loaf=1)
                external_bread += 1
            else:
                assert actor == presence and d['quantity'] == 1
        elif action == 'spatial_deposited':
            p = people[actor]
            assert p['tile'] == SITES[target] and p['activity'] == 'deposit' and p['until'] == minute+5
            assert firms[target]['owner'] == actor and r['initial']['cargo'][target]['holder'] == actor
        elif action in ('work_shift','harvest','produce'):
            p = people[e['physical_actor']]
            business = target if action == 'work_shift' else actor
            assert p['tile'] == SITES[business] and p['activity'] == 'work' and p['business'] == business and p['until'] == minute
        elif action == 'transfer_money' and d['purpose'] == 'wage':
            p = people[target]
            assert e['physical_actor'] == target and p['tile'] == SITES[actor] and p['activity'] == 'work' and p['until'] == minute
        elif action == 'consume':
            if actor == 'visitors':
                p = people[e['physical_actor']]
                assert p['active'] and p['tile'] == [8,3] and p['activity'] == 'idle' and p['loaf'] == d['amount'] == 1
                p['loaf'] = 0
                external_bread -= 1
            else:
                p = people[actor]
                assert p['tile'] == p['home'] and p['activity'] == 'idle' and 1110 <= minute < 1140
        elif action == 'spatial_encounter':
            assert set(d) == {'kind','item','quantity','tile','witnesses'}
            assert people[actor]['tile'] == d['tile'] == SITES[target]
            assert d['witnesses'] == sorted(id for id,p in people.items() if p['active'] and p['tile'] == d['tile'])
            if d['kind'] == 'inspected':
                closes = space['retail_close'] if target == 'bakery' else TRADE[target][1]
                assert TRADE[target][0] <= minute < closes and people[actor]['activity'] == 'idle'
                seen[actor] = (day,minute)
                quantities[actor] = 0
            elif d['kind'] in ('purchased','declined'):
                assert seen[actor] == (day,minute) and d['quantity'] == quantities.get(actor,0)
                assert (d['quantity'] > 0) == (d['kind'] == 'purchased')
        assert all(0 <= p['tile'][0] < 10 and 0 <= p['tile'][1] < 7 for p in people.values())
        assert sum(p['loaf'] for p in people.values() if p['kind'] == 'visitor') == external_bread
    assert space == r['final']['spatial']
