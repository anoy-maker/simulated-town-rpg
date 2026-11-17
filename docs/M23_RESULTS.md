# M23 — Brewery economy, physical grain competition and discretionary demand

Implements [issue #31](https://github.com/anoy-maker/simulated-town-rpg/issues/31)
from `codex/m22-planning-scale` at `10f299f6743ce69fd6ab5c3500b1a984ef0e0cf1`.
No M24 work or historical economic parameter changes.

## Predeclared design

The [feasibility certificate](M23_FEASIBILITY.md), with independent executable
integer checks, was committed in `88fb311` **before** adaptive outcome runs.
It enumerates the exact recipes, 11 qualified paid shifts, physical routes,
upfront capital, consumer baskets, cash flows, brewery break-even and 9192-coin
identity. Four cash surpluses 12/15/21/16 are possible at full sales; they are not
assigned revenue. The bakery's 5→7 conversion is deliberately different from
historical 4→6, with a lower output/input ratio. Explicit M23 equipment endowment
changes productive technique, not free production or an investment policy.

Each of fifteen residents starts at6, each of four firms at120, visitors at8622;
zero commodity stock. The 138-coin reallocation from historical visitors8760
funds the three new households18 plus brewery120. Ada/Bram/Cora and all nine
original employees keep their identities and relationships; new managing owner
Mara employs qualified Nell/Oren. Eleven daily employee contracts pay10 for real
completed one-hour shifts; managers do not perform paid production.

Fixed prices wheat2/flour5/bread6/ale4. Whole recipes/shift: +7 wheat; 5 wheat→5
flour; 5 flour→7 bread; 3 wheat→6 ale. Output targets21/15/21/12. Whole input lots
and wages must fit actual cash, with strictly positive projected contribution;
zero ties retain cash. Full-sale continuation at the posted output quote is a
declared fallible target-replenishment assumption, not private customer knowledge.
Existing output stock suppresses work; actual deposited input is required.

Grain caps reference21/tight19/scarce16, plus matched cap21 `no_brew_request`
control with **zero brewery requested lots**, same 15 residents, firms, initial
money, prices, travel and household rules. No economic tuning follows results.
All four conditions run1/3/30 days, seed42, two independent processes each.
Small held-stock/price/cash/attendance fixtures are separate from actual harvests.

M23 uses the existing 10×7 map with brewery[8,5] and three distinct new homes.
Couriers Bram/Mara inspect and submit at farm10:10 simultaneously; seller chooses
whole lots maximizing actual receipts at its common quote, then ordinary atomic
purchase transfers cash and real cargo. Revalidate changing quote, funds and
attendance. No reservation, subsidy, bid inflation or bread-altruism priority.
Clearance21→mill15/brewer6,19→15/3,16→10/6 is a held-stock feasibility matrix,
not a mandated farm output. Routes and all appointments are in the certificate.

Bread shopping16:00 precedes physical bakery→brewery travel and ale shopping16:15.
Visitors buy bread17:05, consume/travel, consider ale17:20, consume/travel and exit
gate17:40. Residents leave homeward17:30; every route finishes before18:30 meals.
Settlement19:00 follows all fifteen bread attempts, counts only realized earnings
and retains the120 floor. That floor is not an escrowed operating reserve.

Consumers maximize100×bread+5×ale+remaining cash over currently inspected,
affordable stock; cash wins utility ties. Bread6 gives positive essential utility;
ale4 adds one net unit, ale5 is declined on tie. One bread need and one ale
purchase/day; visitor spend10 is combined across both stops against the real
finite account. No future ale stock reservation or hidden remote offer is supplied.
Actual ale consumption gives a linked benefit5 receipt, with no intoxication,
health, fatigue or social effect. No M18 twelve-person Bayesian policy is reused.

## Actual economic results

All twelve cases completed twice with **identical complete reports and native
events**, and all24 traces passed independent Python reconstruction. Currency is
9192 after every successful economic movement, with no negative accounts or
unaccounted commodity changes. Tight/scarce have identical economic paths, but
different condition/cap metadata and therefore different canonical hashes.

| Condition | Days | Resident meals / missed | Visitor bread / refused | Ale produced/sold/consumed | Shifts / missed | Wheat / flour / bread produced |
|---|---:|---:|---:|---:|---:|---:|
| Reference | 1 | 15 / 0 | 6 / 0 | 12 / 12 / 12 | 11 / 0 | 21 / 15 / 21 |
| Reference | 3 | 45 / 0 | 18 / 0 | 36 / 36 / 36 | 33 / 0 | 63 / 45 / 63 |
| Reference | 30 | 450 / 0 | 180 / 0 | 360 / 360 / 360 | 330 / 0 | 630 / 450 / 630 |
| Tight | 1 | 14 / 1 | 0 / 6 | 6 / 6 / 6 | 7 / 4 | 14 / 10 / 14 |
| Tight | 3 | 38 / 7 | 11 / 7 | 12 / 12 / 12 | 22 / 11 | 42 / 35 / 49 |
| Tight | 30 | 368 / 82 | 155 / 25 | 90 / 90 / 90 | 225 / 105 | 420 / 375 / 525 |
| Scarce | 1 | 14 / 1 | 0 / 6 | 6 / 6 / 6 | 7 / 4 | 14 / 10 / 14 |
| Scarce | 3 | 38 / 7 | 11 / 7 | 12 / 12 / 12 | 22 / 11 | 42 / 35 / 49 |
| Scarce | 30 | 368 / 82 | 155 / 25 | 90 / 90 / 90 | 225 / 105 | 420 / 375 / 525 |
| No brew request | 1 | 15 / 0 | 6 / 0 | 0 / 0 / 0 | 9 / 2 | 21 / 15 / 21 |
| No brew request | 3 | 37 / 8 | 18 / 0 | 0 / 0 / 0 | 26 / 7 | 56 / 45 / 63 |
| No brew request | 30 | 322 / 128 | 180 / 0 | 0 / 0 / 0 | 201 / 129 | 378 / 370 / 511 |

### Reference: feasible and operating steadily for thirty days

Every day produces and sells21 wheat,15 flour,21 bread and12 ale, completes all
eleven shifts, and feeds all fifteen residents/six visitors. Every firm closes
at120 coins with no goods/cargo. Daily realized cash surpluses are precisely the
12/15/21/16 witness; thirty-day total1920 is legitimately distributed. Actual
wages total3300. Successful purchases1230, rejected0, circulation13950. Circulation
counts all native exchanges/wages/distributions, potentially reusing the same
coin; it is not money creation or a GDP estimate.

Full-sales affordability does **not** imply every consumer receives ale.
On day1 all eleven employees buy ale and one visitor buys the last unit; the
four managers cannot afford it after bread. From day2 the three early managers
also have funds, and sorted customer order exhausts twelve ales before Mara,
Nell and Oren. They are physically present, inspect stock and decline; the
brewery's own producers are not given preferential treatment. No food reservation
or personalized taste creates that result. Visitors spend1080 on bread and4 on
ale over thirty days, within each body's ten-coin allowance.

The actual startup ordering also finances inputs before customer receipts:
farm payroll at10:00 leaves90, common grain sales at10:10 bring it to132;
mill procurement leaves90 then12:00 payroll60, followed by flour receipts75;
brewery procurement leaves108 then14:00 payroll88; bakery flour purchase leaves45
then15:00 payroll15. No wage is paid from a projected later bread/ale receipt.

Reference final personal money (all zero commodity stocks,30 meals each):

| Resident(s) | Final coins | Wages | Ownership income | Bread / ale expenditure |
|---|---:|---:|---:|---:|
| Ada | 70 | 0 | 360 | 180 / 116 |
| Bram | 160 | 0 | 450 | 180 / 116 |
| Cora | 340 | 0 | 630 | 180 / 116 |
| Dain, Edda, Finn, Gale, Hale, Iona, Jory, Kira, Lyle (each) | 6 | 300 | 0 | 180 / 120 |
| Mara | 306 | 0 | 480 | 180 / 0 |
| Nell, Oren (each) | 122 | 300 | 0 | 180 / 4 |

Households hold1174, firms480, external account7538: total9192. Business state
and physical throughput repeat daily, while household money accumulates from
finite visitors. This is an observed thirty-day operating pattern under fixed
prices/preferences/endowments and simple policies, **not a closed monetary
equilibrium**, permanent default, robustness proof or unlimited external demand.

### Scarcity: profitable firms coexist with persistent deprivation

At either cap19 or16, the first two farm shifts each earn an expected14 at wage10.
The remaining capacity is respectively five wheat (receipts10, zero contribution)
or two (receipts4, loss6). The **predeclared strict-positive tie rule** declines
the third shift. Actual harvest is14 every day in both conditions, not19 or16.
This is a financial decision, not a scripted loss of available grain or a forced
unprofitable shift to reach a preset.

On odd days14 grain is available; clearing chooses mill2/brewer1, uses13 and
leaves1. On even days that residual plus14 makes15; mill3/brewer0 uses all15.
Thus actual allocation alternates **10/3** and **15/0**, not the held-stock16
fixture's10/6. Brewery genuinely competes for the same grain, produces6 ale on
odd days and none on even days; no missing second shift is fabricated.

Cora's replenishment request targets whole batches using price and own capital;
it is not automatically truncated to the supplier's advisory stock. On fifteen
short-flour days the third five-flour purchase rejects for actual insufficient
stock. These **15 failed purchases** leave money/custody unchanged, while778
purchases succeed. Deposited stock allows only real bakery shifts. This bounded,
optimistic replenishment policy is a limitation, not perfect procurement foresight.

Thirty-day actual firm cash books (tight and scarce):

| Firm | Sales | Input purchases | Wages | Operating surplus / payouts | Shifts | End cash / stock |
|---|---:|---:|---:|---:|---:|---|
| Farm | 840 | 0 | 600 | 240 / 240 | 60 | 120 / none |
| Mill | 1875 | 750 | 750 | 375 / 375 | 75 | 120 / none |
| Bakery | 3138 | 1875 | 750 | 513 / 513 | 75 | 120 / 2 bread |
| Brewery | 360 | 90 | 150 | 120 / 120 | 15 | 120 / none |

Actual surplus uses realized purchased inputs/payroll, never nominal capacity.
There are82 missed resident meals: Gale29, Oren29, Mara10, Kira5, Lyle5, Nell4;
everyone else misses0. Sorted staffing repeatedly excludes Gale and Oren, who
receive **zero** wages; Kira/Lyle/Nell each get15 shifts. A contract breach records
the loss, without debt, guaranteed work, substitution or free food. Fifty-three
misses occur on19 days ending with unsold bread: household purchasing power and
timing matter alongside physical output. Farm/mill/bakery operate through day30,
brewery through day29; thirty productive shifts still occur in days27–30. This
is partial recurring activity and individual employment/food deadlock, not total
village cessation. All firms closing solvent at120 does not establish welfare.

Final households1020, firms480, visitors7692. Resident-by-resident balances,
spending, wages, distributions, work and missed meals are in the tables below.
All produced ale is sold and consumed; no ale stock disappears. Two bread remain
from525 produced versus523 consumed (368 local,155 visitor).

### Matched zero-brew-request control

This keeps the same fifteen people and capital; it does not delete brewery
households or replace their missing wages. Thirty-day meals322/missed128, with
all180 visitor loaves sold. Bakery produces511 bread and retains9;128 missed
meals occur on29 days with end-of-day bread stock. Mara, Nell and Oren each eat
once, then miss29 meals. Gale misses24, Kira8, Lyle7, Ada2; others miss0.

Without brewery grain demand the farm carries stock and its fixed target cuts
work:54 shifts/378 wheat, Gale only3 shifts. Mill has74 shifts/370 flour and
holds5 flour; bakery73 shifts/511 bread. Initial income loss suppresses household
spending, stock offsets suppress more jobs, and no policy rescues the excluded.
Firm closing cash is farm120/mill110/bakery120/brewery120. The mill paid355 in
earlier distributions but cumulative operating surplus is345 by day30, leaving
−10 retained cash earnings and five flour. Each earlier payout respected actual
funds/realized earnings and120 at payment time; **120 is a payout floor, not a
protected operating balance**. Low closing cash reaches110/110/111 for farm/
mill/bakery at different days, without negative accounts or invented liquidity.

Households1180, firms470, visitors7542 conserve9192. Successful purchases649,
rejected0, circulation8599. Final grain8, flour5 and bread9 reconcile production
minus transformation/consumption exactly. Activity continues after day26, with24
paid shifts in days27–30; the brewery never produces in this explicit control.

The reference's better food access relative to this **matched** control is an
outcome of enabling brewery demand, including its endogenous work/income and
inventory feedbacks. It does not isolate only grain allocation, prove ale improves
nutrition, or causally compare this population/endowment with M22's twelve-person
historical economy. Tight/scarce versus the control also changes the supply cap.

## Verification and performance

Final acceptance passes with **zero failures**:

| Command phase | Actual result | Wall seconds |
|---|---|---:|
| Full Godot suite | 3168 checks (all3122 historical +46 M23) | 371.028 |
| Full Python discovery | 82 tests (previous77 +5 M23), no skips | 170.362 |
| Historical canonical sweep | All169 pins byte-identical | 594.483 |
| Fresh M21 C/D1/3/30 sync/scheduled capture | All12 complete report/ledger pins unchanged | 96.743 |
| Original financial/spatial/observation/numerical audits | All12 fresh historical traces pass | 224.239 |
| Headless editor import | Exit0, no script errors | 12.210 |

The24 M23 independent audits are additionally recorded per case in
[M23_AUDITS.csv](M23_AUDITS.csv); complete replay/case counts in
[M23_CHECKS.json](M23_CHECKS.json). [All historical pins](M23_REGRESSIONS.csv),
[fresh legacy audits](M23_LEGACY_AUDITS.csv) and
[command costs](M23_VERIFICATION.csv) preserve exact evidence. The Godot→Python
lane ran alongside historical→fresh capture→audit after isolated timings, so
overlapping phase costs are not summed as task duration. Significant core source
did not change afterward. M0's original30-day seed42 full JSON remains
`6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`.

The final standard CLI's one-day M23 trace independently audits and matches its
matrix report pin. The original [M22 smoke](M23_LEGACY_SMOKE.json), against its
unchanged reference, completes in3.291 s with comparable host metadata and **no
warnings**, with current phase costs attached. No requested experiment/check was
skipped. Actual FPS/input latency, other seeds, annual operation and broader NPC
autonomy were not tested or claimed.

Focused tests cover the exact21/19/16 clearing matrix in both submission orders;
zero demand, cashless/underfunded buyer, stale quote, changed attendance/stock,
whole-lot rejection, duplicate clearing, no input, cash-short bakery, unavailable
ale, private-observation noninterference, real visitor combined budget, physical
account authorization, daily allowances, split replay and fixed historical goods.
Held grain is explicit fixture initialization, not a mandated harvest. One test
deliberately mutates private held stock after inspection as a fault fixture; it
does not masquerade as an audited simulated removal. Price fixtures verify mill
margin at wheat2/3/4, brewer contribution2 per batch at wheat4/ale4, loss/decline
at wheat4/ale3, and consumer behavior at ale3/4/5. No case retunes the matrix.

The independent Python auditor reconstructs native money/goods, real employee
receipts, quote/version/price, cargo/deposit ownership, routes/arrival/work times,
daily visit budgets, consumption provenance, policy observations and report
fields. Unknown successful actions fail. Ten rehashed corruption fixtures
(money, recipe, wage, quote, movement, visitor budget, private information,
consumer need, report and benefit linkage) fail independent reconstruction rather
than merely the final hash. Existing auditors and pins are not weakened.

An early one-day development check rejected ale sales because dot insertion
created a StringName business key, while historical quote validation requires a
String seller. Explicit String-key initialization fixed the implementation;
no economic parameter or decision policy was changed to repair that outcome.

### Measured cost (same host, two fresh processes per case)

Godot4.6.3/Python3.12.14 on the M22 Linux x86_64 host: three visible CPUs, two-CPU
quota,8 GiB ([exact host/build metadata](M23_HOST.json)). No Rust or expensive Bayesian model is required by M23. Two excluded
one-day warmups; each captured process completes before its audit, with no other
verification running during timings. Run-only wraps `runner.run()`; command wall
also includes engine load, initialization, report, full transient event JSON and
exit. Reporting/serialization and post-run audit are distinct costs. The measured
child command total is54.883 s;24 independent audit calls total30.458 s, excluding
warmups and Python orchestration. These are not elapsed agent/task duration.

| Condition | Days | Run median (s) | Full command median (s) | Report median (s) | Peak RSS median (KiB) | Events | Worst appointment / tick across repeats (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|
| Reference | 1 | .036 | .688 | .039 | 85,606 | 1,336 | 4.678 / .878 |
| Reference | 3 | .130 | 1.010 | .179 | 107,340 | 4,006 | 9.100 / 2.078 |
| Reference | 30 | 2.815 | 5.795 | 1.307 | 527,464 | 40,051 | 21.520 / 14.084 |
| No brew request | 1 | .039 | .566 | .031 | 85,308 | 1,277 | 5.820 / 1.339 |
| No brew request | 3 | .122 | .804 | .095 | 104,982 | 3,812 | 9.549 / 3.750 |
| No brew request | 30 | 2.430 | 5.245 | 1.025 | 498,676 | 37,617 | 21.027 / 5.520 |
| Tight | 30 | 2.384 | 5.163 | 1.243 | 499,808 | 38,239 | 23.371 / 7.472 |
| Scarce | 30 | 2.415 | 5.504 | 1.257 | 499,804 | 38,239 | 31.039 / 19.959 |

Thirty-day appointment n=810/process supports p99: reference18.003/16.891 ms,
control14.927/15.782 ms; every measured case remains below the provisional50-ms
diagnostic p99 goal (no budget warning). Tick n=8640/process; one-day appointments
n=27 have no p99 estimate. Exact samples/ranges and all1/3/30 conditions are in
the performance/latency CSVs. Appointments include intervening clock/movement work;
tick costs are nested, not extra. This synchronous headless runner does not test
rendered FPS, player input or nonblocking world progression.

Reference30 uses about15.8% more run-only time and5.8% more peak RSS than the
matched no-request30 control, with more actual employment/trade/events. These
two-sample ratios are diagnostic, not precise causal estimates of brewery policy
CPU cost. **About515 MiB peak RSS for a thirty-day trace** is a practical limit:
native retained ledgers, copies and JSON/report output contribute; no memory
optimization or unrun annual/100-citizen scalability claim follows. Current CLI
bounds M23 to0..30 days; keep quick1/3-day checks during editing, complete
historical/independent acceptance at final milestone as in [PERFORMANCE.md](PERFORMANCE.md).

## Evidence, reproduction and limits

[Runs/hashes](M23_RUNS.csv), [daily aggregates](M23_DAYS.csv),
[firm totals](M23_BUSINESSES.csv), [firm days](M23_FIRM_DAYS.csv),
[resident totals](M23_RESIDENTS.csv), [resident days](M23_RESIDENT_DAYS.csv),
[individual visitor days](M23_VISITOR_DAYS.csv), [performance samples](M23_PERFORMANCE.csv)
and [latencies](M23_LATENCY.csv) are compact published evidence. Day tables cover
all120 thirty-day condition-days;1/3-day report prefixes are independently checked
equal, not repeated in those tables. No full native traces are committed.

```sh
python3 -B scripts/tools/brewery_feasibility.py
godot --headless --no-header --path . --script res://tests/run_brewery_tests.gd
python3 -B -m unittest discover -s tests -p test_brewery.py
python3 -B scripts/tools/run_brewery.py --output work/m23/experiments
python3 -B scripts/tools/summarize_brewery.py --input work/m23/experiments --output docs
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_brewery --condition scarce 30 42 --report-json
# Final full acceptance, after isolated measurement:
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m23/historical.csv
```

Fresh legacy capture/audit reproduction, using the unchanged M21 tools:

```sh
python3 -B - <<'PY'
import json, sys
from pathlib import Path
sys.path.insert(0, 'scripts/tools')
from measure_planning_jobs import capture, validate
out = Path('work/m23/legacy-controls'); out.mkdir(parents=True, exist_ok=True)
for stage in 'CD':
    for days in (1, 3, 30):
        for mode in ('sync', 'scheduled'):
            data = capture(stage, days, mode); validate(data)
            (out / f'{stage}-{days}-{mode}-none.json').write_text(json.dumps(data))
PY
python3 -B scripts/tools/measure_planning_jobs.py --phase audit --output work/m23/legacy-controls
```

`--json` emits a diagnostic native trace; `--measure` additionally emits timing
sidecars, excluded from canonical reports/events. `run_brewery.py --checkpoint`
uses the1/3-day cases only. M23 needs no native toolchain. Historical M21/M22
native tests still use their optional pinned build. Seed42 is recorded; this
reference has fixed productive capacity and no stochastic consumer preferences.
We did not claim additional-seed, annual, adaptive pricing or fault-resilient
planning results.

Technical correctness and a feasible reference do not establish robust autonomous
economic stability. Local policies remain optimistic whole-batch inventory
replenishment with conditional full-sale values, no household future budget model,
fixed sorted staffing/retail order, no fairness or price feedback, and finite
visitor purchasing power. Capacity/demand/stock/earnings interact and excluded
people can remain hungry beside stocked, solvent businesses. Results are reported
without economic calibration, free food, debt, compensating payroll or recovery
scripts. Historical M18 learning remains calibrated to its own unchanged world.

The next reviewed industry could reuse explicit input/output vectors, eligible
paid labor, actual custody, public on-site offers and bounded consumer cash/utility.
A tavern would need a real ale purchase and separately authorized service; equipment
investment would need actual assets and retained capital rather than an invisible
productivity upgrade; clothing would need its own declared sources/recipes/budgets.
None is implemented here, and this is not a generic multi-commodity planner.

Changed files: small protected default hooks in kernel/labor/profitable/enterprise/
pricing/spatial authority; isolated M23 config/policy/world/timetable/report and CLI
delegation; independent feasibility/audit/matrix/table tools; focused native/Python
tests; README/architecture/roadmap and this evidence. Shared static commodity,
recipe and industry constants, old policies/runners, Rust kernels and old auditors
are unchanged. **Stop after M23 for review. Do not begin M24.**
