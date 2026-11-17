"""Independent integer M23 witness; no simulation outcome or kernel import."""
import argparse
from pathlib import Path
from spatial_audit import route

PRICES = dict(wheat=2, flour=5, bread=6, ale=4)
WORKERS = dict(farm=['dain', 'edda', 'gale'], mill=['hale', 'jory', 'lyle'],
               bakery=['finn', 'iona', 'kira'], brewery=['nell', 'oren'])
OWNERS = dict(farm='ada', mill='bram', bakery='cora', brewery='mara')
SITES = dict(farm=[6, 1], mill=[6, 3], bakery=[8, 3], brewery=[8, 5])
WINDOWS = dict(farm=(540, 600), mill=(660, 720), bakery=(840, 900), brewery=(780, 840))
RULES = dict(farm=({}, dict(wheat=7)), mill=(dict(wheat=5), dict(flour=5)),
             bakery=(dict(flour=5), dict(bread=7)), brewery=(dict(wheat=3), dict(ale=6)))


def certificate():
    assert sum(map(len, WORKERS.values())) == 11
    assert len(set(sum(WORKERS.values(), []) + list(OWNERS.values()))) == 15
    inputs, outputs, books = {}, {}, {}
    for firm, (take, make) in RULES.items():
        count = len(WORKERS[firm]); cost = sum(PRICES[i]*q*count for i, q in take.items())
        sales = sum(PRICES[i]*q*count for i, q in make.items()); wages = count*10
        books[firm] = dict(sales=sales, inputs=cost, wages=wages, surplus=sales-cost-wages,
                           pre_sales_cash=120-cost-wages)
        for i, q in take.items(): inputs[i] = inputs.get(i, 0) + count*q
        for i, q in make.items(): outputs[i] = outputs.get(i, 0) + count*q
    assert outputs == dict(wheat=21, flour=15, bread=21, ale=12)
    assert inputs == dict(wheat=21, flour=15)
    assert [books[x]['surplus'] for x in RULES] == [12, 15, 21, 16]
    assert min(b['pre_sales_cash'] for b in books.values()) == 15
    # One executable cash witness: wages before receipts; inputs before processing wages.
    cash = {x:120 for x in RULES}; cash.update({x:6 for x in sum(WORKERS.values(), [])+list(OWNERS.values())}); cash['visitors']=8622
    def pay(a,b,n):
        assert 0 < n <= cash[a];cash[a]-=n;cash[b]+=n
        assert sum(cash.values()) == 9192 and min(cash.values()) >= 0
    for firm in ('farm','mill','brewery','bakery'):
        if firm!='farm': pay(firm, 'farm' if firm!='bakery' else 'mill', books[firm]['inputs'])
        for worker in WORKERS[firm]: pay(firm, worker, 10)
    for person in sorted(sum(WORKERS.values(), [])+list(OWNERS.values())): pay(person,'bakery',6)
    for worker in sum(WORKERS.values(), []): pay(worker,'brewery',4)
    for slot in range(6):
        spend=6+(4 if slot==0 else 0);assert spend<=10
        pay('visitors','bakery',6)
        if slot==0:pay('visitors','brewery',4)
    assert {f:cash[f]-120 for f in RULES} == {f:b['surplus'] for f,b in books.items()}
    for firm in RULES:pay(firm,OWNERS[firm],books[firm]['surplus'])
    assert cash['visitors']==8582
    # Route/appointment witness: all couriers are actual distinct managing owners.
    trips=[('bram','farm','mill',615,625,660),('mara','farm','brewery',615,645,780),('cora','mill','bakery',735,745,840)]
    for who,a,b,depart,arrive,start in trips:
        assert OWNERS[b]==who and depart+5*len(route(SITES[a],SITES[b]))==arrive
        assert arrive+5<=start
    assert 965+5*len(route(SITES['bakery'],SITES['brewery']))==975
    assert 1030+5*len(route(SITES['bakery'],SITES['brewery']))==1040
    assert 1045+5*len(route(SITES['brewery'],[9,3]))==1060
    original=sorted(['ada','bram','cora']+sum([WORKERS[f] for f in ('farm','mill','bakery')],[]))
    homes={p:[1,1+2*(i//4)] for i,p in enumerate(original)}
    homes.update(mara=[2,0],nell=[2,2],oren=[2,4])
    for p,home in homes.items():
        assert 0<=home[0]<10 and 0<=home[1]<7 and home not in SITES.values()
        firm=next(f for f in RULES if p==OWNERS[f] or p in WORKERS[f])
        first='farm' if p in ('bram','mara') else 'mill' if p=='cora' else firm
        assert 480+5*len(route(home,SITES[first]))<=WINDOWS[firm][0]
        assert 1050+5*len(route(SITES['bakery'] if p=='cora' else SITES['brewery'],home))<=1110
    # Exhaust the finite integer allocation rather than relying on iteration priority.
    clear=lambda grain:max(((5*m+3*b,m,b) for m in range(4) for b in range(3) if 5*m+3*b<=grain))
    assert [clear(g) for g in (21,19,16)]==[(21,3,2),(18,3,1),(16,2,2)]
    assert (32+3)//4 == 8 and 12*4-32==16 and 6*4-3*2-10==8
    # Employee feasible basket, owner day-one constraint, and utility tie at ale5.
    def basket(cash,ale):
        return max((100*b+5*a+cash-6*b-ale*a,cash-6*b-ale*a,-a,-b,b,a)
                   for b in (0,1) for a in (0,1) if 6*b+ale*a<=cash)[-2:]
    assert basket(10,4)==(1,1) and basket(6,4)==(1,0) and basket(11,5)==(1,0)
    return dict(inputs=inputs,outputs=outputs,books=books,cash_after=cash,homes=homes,paid_shifts=11,money=9192)


def document():
    c=certificate()
    rows='\n'.join(f"| {f} | {len(WORKERS[f])} | {b['sales']} | {b['inputs']} | {b['wages']} | {b['surplus']} | {b['pre_sales_cash']} |" for f,b in c['books'].items())
    return '''# M23 preflight feasibility certificate

Predeclared before simulation outcomes. Regenerate with `python3 -B scripts/tools/brewery_feasibility.py --write docs/M23_FEASIBILITY.md`.
This independent integer witness proves a possible funded, physical day, not autonomous discovery or long-term equilibrium.

15 residents retain the original twelve IDs/jobs and add Mara (brewery manager), Nell and Oren (qualified brewery employees). Four managers do no paid production. All residents start with six coins and zero goods. Each firm has 120 coins, zero goods, its own workshop and equipment. Existing assets are explicitly endowed for M23's different techniques; no investment decision or free work is hidden. Brewery has two equipment/workplace slots, others three. Daily wage10; eleven unique paid shifts.

Recipes per completed shift: farm +7 wheat; mill −5 wheat/+5 flour; bakery −5 flour/+7 bread; brewery −3 wheat/+6 ale. Three farm/mill/bakery and two brewery shifts give wheat21, flour15, bread21, ale12. Wheat21 is consumed exactly as mill15+brewery6; flour15 feeds bakery15; bread21 serves fifteen locals and six visitors. Bakery 7/5 is deliberately a *lower* flour conversion yield than historical 6/4, not an efficiency claim.

Prices wheat2/flour5/bread6/ale4. Possible full-sales daily books:

| Firm | Shifts | Sales | Inputs | Wages | Operating surplus | 120−inputs−wages |
|---|---:|---:|---:|---:|---:|---:|
'''+rows+'''

The pre-sales column conservatively ignores upstream receipts. Farm payroll leaves90; mill procurement then payroll leaves60; brewery leaves88; bakery leaves15. Every payment uses existing funds, never future sales. After legitimate settlement, realized surpluses above120 may be paid to actual owners. Cash operating surplus is not accrual profit or valuation of unsold inventory.

Brewery full-day break-even ceil((6×2+2×10)/4)=8 ales; nine through twelve are positive. One full-sale batch contributes 6×4−3×2−10=8. At wheat3 the mill batch margin is zero; at wheat4 it is −5. At wheat4/ale4 the brewer batch margin is2. Production capacity is not assumed revenue.

Money identity: 15×6+4×120+8622=9192. The 138 reduction from old visitors8760 exactly funds three new households18 plus brewery120. Six visitor bodies share the finite8622 account, each with a private ten-coin *total* daily cap, not separate bread/ale wallets. Employee cash before shopping is16 and can afford bread6+ale4. Managers start at6, afford bread, and may lack ale money until settlement. Utility 100×bread+5×ale+remaining cash, tie retains cash: ale4 adds1 utility; ale5 adds0 and is declined. A possible day-one allocation sells ale to all eleven employees and one visitor, bread to everyone; other visitors may find no ale. External spending40 leaves8582, firm cash480 and household cash130 after total distributions64; total remains9192.

Physical witness on unchanged 10×7 grid: farm[6,1], mill[6,3], bakery[8,3], brewery[8,5], gate[9,3]. Routes move x then y, one orthogonal tile per five minutes. Original homes retain their three shared M17 rows; new nonoverlapping housing Mara[2,0], Nell[2,2], Oren[2,4]. All morning home→first-site routes departing08:00 arrive before relevant shifts. At09:00–10:00 farm employees work; Bram/Mara are already at farm for common10:10 clearing. Five-minute procurement then10:15 departure takes Bram two tiles to mill10:25, Mara six to brewery10:45; five-minute deposit precedes11:00 mill/13:00 brewery work. Cora buys flour at mill12:10, departs12:15, arrives bakery12:25, deposits by12:30, before14:00–15:00 bakery work. Mill work ends12:00, brewery14:00. Managers perform only management/courier tasks.

All residents leave workplaces15:30 for bakery16:00 bread; after five-minute shopping, bakery→brewery two tiles reaches16:15 ale; consume ale16:20. Cora returns to bakery16:20→16:30 to witness later bread encounters. Visitors enter gate17:00→bakery17:05, shop five minutes, eat17:10, travel to brewery17:20, shop five minutes, consume17:25, travel three tiles to gate17:40 and exit. Residents leave for home17:30 (not17:45: that would make distant homes late); every route arrives by18:30 meals. Settlement19:00 follows household attempts; clock finishes24:00. No teleport, overlapping body appointments or unpaid productive manager.

Enumerated common-price clearing maximizes actual grain revenue over submitted/affordable whole lots: at stock21 accept mill3/brewery2 (21); at19 mill3/brewery1 (18); at16 mill2/brewery2 (16). Stable lexicographic tie rule favors larger mill-lot count only after equal revenue; within 0..3/0..2 positive-price lots there is no distinct equal-use pair. No private downstream consumers enter this objective. Held-stock fixtures are not mandated actual harvests.

## Fixed experimental policies (before longitudinal runs)

Reference/tight/scarce daily harvest caps21/19/16; same techniques, prices, wages, population and initial funds. Matched `no_brew_request` control uses cap21 and disables only brewery grain requests, with all fifteen residents and four firms retained. Run all four for1/3/30 days, seed42, twice independently. Price fixtures wheat2/3/4 and ale3/4/5 are isolated, not retuning longitudinal runs.

Common deterministic owner rule: refill fixed output targets wheat21/flour15/bread21/ale12 using bounded whole shifts/lots, current owned stock/cash, actual qualified available employees, own output quote and genuinely inspected input quote. Expected continuation assumes sale of replenishment output at that quote within a future selling day; it is a declared fallible inventory-target assumption, not knowledge of consumer funds or compelled demand. Missing input *whole lots* and payroll must fit current cash; require strictly positive incremental projected cash contribution, retain cash on zero/negative ties. Production also requires deposited real input. Farm partial capacity is valued at its actual capped output: five wheat×2 equals wage10 and is declined; two wheat is worse. Thus caps19/16 need not be realized. No subsidized third shift or stock deletion enforces the preset. Existing output stock at/above target suppresses replenishment. Managers do not get paid shifts. Worker choice uses sorted eligible IDs, not a fairness correction.

Consumers maximize the stated myopic basket utility over currently inspected, available goods and actual funds/remaining daily allowance. Bread opportunity comes first, ale later; no remote offer is assumed seen and future stock is not reserved. One bread need and at most one ale purchase/day; actual ale consumption is an owned, physically witnessed sink with discretionary benefit5, no health/intoxication effect. Fixed quotes, no Bayesian/EVSI recalibration, new planner or post-result tuning. This certificate does not promise universal access or stable business operation.
'''


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--write',type=Path);a=p.parse_args();text=document()
    if a.write:a.write.write_text(text)
    else:print(text)
