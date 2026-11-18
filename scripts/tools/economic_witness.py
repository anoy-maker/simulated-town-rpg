"""M27 tiny bounded physical search. No NPC integration or finance optimization."""
from itertools import product
from brewery_feasibility import OWNERS,SITES,WINDOWS
from spatial_audit import route
from run_brewery import digest

FIRMS=('farm','mill','bakery','brewery')


def staff(s,b):
    return sorted(w for w,j in s['employment'].items() if j['active'] and j['business']==b
                  and j['start_day']<=s['day']<j['end_day'] and s['affiliations'].get(w)==dict(business=b,kind='employee'))


def routes(s,evidence):
    trips=[];residents=sorted(w for w,e in s['entities'].items() if e['kind']=='resident')
    def add(w,destination,start):
        old=[t for t in trips if t['body']==w]
        origin=old[-1]['to'] if old else s['people'][w]['tile']
        path=route(origin,destination)
        if path:trips.append(dict(body=w,start=start,end=start+5*len(path),origin=list(origin),to=list(destination),path=path))
    for w in residents:
        b=next((b for b in FIRMS if w in staff(s,b)),None)
        destination=SITES['farm'] if w in ('bram','mara') else SITES['mill'] if w=='cora' else SITES['farm'] if w=='ada' else SITES[b] if b else s['people'][w]['home']
        add(w,destination,480)
    for w,b in [('bram','mill'),('mara','brewery')]:add(w,SITES[b],615)
    add('cora',SITES['bakery'],735)
    for w in residents:add(w,SITES['bakery'],930)
    for w in residents:add(w,SITES['brewery'],965)
    add('cora',SITES['bakery'],980)
    for event in evidence['visitors']:
        w=event['actor'];trips.append(dict(body=w,start=1020,end=1025,origin=[9,3],to=SITES['bakery'],path=[[8,3]]))
        add(w,SITES['brewery'],1030);add(w,[9,3],1045)
    for w in residents:add(w,s['people'][w]['home'],1050)
    return trips


def physical_candidates(bundle,tier):
    s,e=bundle['state'],bundle['evidence'];assert tier in ('fixed_orders','voluntary_orders')
    limits=[min(len(staff(s,b)),s['businesses'][b]['assets']['daily_slots']) for b in FIRMS]
    initial={b:s['entities'][b]['inventory'] for b in FIRMS}
    cargo={b:s['cargo'][b]['inventory'] for b in FIRMS}
    clearing=e['clearing'];assert clearing is not None
    fixed=(clearing['details']['eligible']['mill'],clearing['details']['eligible']['brewery'],e['plans']['bakery:procurement']['details']['proposal']['lots'])
    requests=[fixed] if tier=='fixed_orders' else product(range(limits[1]+1),range((0 if s['condition']=='no_brew_request' else limits[3])+1),range(limits[2]+1))
    requests=list(requests)
    for counts in product(*(range(n+1) for n in limits)):
        f,m,b,a=counts
        harvest=min(7*f,s['cap'])
        if f and harvest<=7*(f-1):continue
        for rm,ra,rf in requests:
            available=initial['farm']['wheat']+harvest
            q=s['quotes']['farm']['wheat'];available=min(q['limit'],available) if q['active'] else 0
            used,am,aa=max((5*mm+3*ba,mm,ba) for mm in range(rm+1) for ba in range(ra+1) if 5*mm+3*ba<=available)
            if 5*m>initial['mill']['wheat']+cargo['mill']['wheat']+5*am:continue
            q=s['quotes']['mill']['flour'];flour=initial['mill']['flour']+5*m
            purchased=min(rf,min(flour,q['limit'])//5) if q['active'] else 0
            if 5*b>initial['bakery']['flour']+cargo['bakery']['flour']+5*purchased:continue
            if 3*a>initial['brewery']['wheat']+cargo['brewery']['wheat']+3*aa:continue
            yield dict(counts=dict(zip(FIRMS,counts)),requests=dict(mill=rm,brewery=ra,flour=rf),
                       production=dict(wheat=harvest,flour=5*m,bread=7*b,ale=6*a),allocation=dict(mill=am,brewery=aa),
                       flour_lots=purchased,bread_at_shop=initial['bakery']['bread']+7*b)


def generate(bundle,tier):
    candidates=list(physical_candidates(bundle,tier));assert candidates
    def rank(c):
        n=tuple(c['counts'][b] for b in FIRMS);r=tuple(c['requests'][b] for b in ('mill','brewery','flour'))
        return c['bread_at_shop'],c['production']['ale'],-sum(n),tuple(-v for v in n+r)
    best=max(candidates,key=rank);s=bundle['state']
    return dict(schema=1,snapshot_sha256=bundle['snapshot_sha256'],evidence_sha256=digest(bundle['evidence']),
                tier=tier,day=s['day'],counts=best['counts'],requests=best['requests'],
                workers={b:staff(s,b)[:best['counts'][b]] for b in FIRMS},trips=routes(s,bundle['evidence']),
                claimed_physical=best,search_candidates=len(candidates),
                label='relaxed_potential',relaxations=['money','customer choices','own-profit/request policy gates'])
