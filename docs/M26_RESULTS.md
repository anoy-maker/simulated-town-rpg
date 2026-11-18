# M26 — Seller-local demand and binding contract renewal

Implements [issue #37](https://github.com/anoy-maker/simulated-town-rpg/issues/37)
from M25 `6b344dd5faec2edce80dd703d748c7ba6be9b799` on
`codex/m26-demand-observation`. Historical scenarios and defaults are preserved.

**Economic finding:** correcting some stockout censorship changes employment
and food allocation, but does not establish viability. In the main experiment,
request-aware forecasting raises resident meals relative to the matched sales
smoother in all three constrained conditions. It also increases standby costs,
can exhaust brewery capital, and performs worse in one staggered comparison.
This is not a wage/price experiment or a viable-baseline adoption.

## Frozen experiment and implementation

The [feasibility protocol](M26_DEMAND_FEASIBILITY.md) was committed as `e4af88d`
before outcome runs. The implementation and midnight-validation clarification
were committed before longitudinal experiments; no economic parameters or policy
were retuned after results. Fifteen residents, four firms, 9192 coins, fixed prices
wheat 2/flour 5/bread 6/ale 4, targets 21/15/21/12, physical schedules, utility, ten-coin
wages, three-day exclusive terms and M25 matching all remain unchanged.

Three arms share identical instrumentation:

- **L / legacy_instrumented:** exact M25 yesterday-sales forecast and initial target.
- **S / sales_smoothed:** one output-target pseudo-day and last three eligible
  completed same-price seller days, using fulfilled sales only.
- **R / requests_smoothed:** exactly S, adding credible stockout-unfilled quantity.

S/R use `ceil((target + sum(signal))/(1+n))`, clamped 0..30. Partial days with real
order/register evidence enter as expressly censored lower bounds. An unwitnessed
empty window is unknown; a fully witnessed zero-interest open window is zero.
Eligibility is common to both arms, including the fact that a real interaction
occurred; only R uses its unfilled quantity. The authority filters each firm's
own records before calling the pure estimator. L's reported sample window is
diagnostic; its selected point remains yesterday's sales, not that smoother.

All points freeze at 15:55 from prior completed days. The unchanged
`binding_policy.forecast()` and renewal solver value the same prospective wage
and input obligations. Midnight entry validation rechecks actual resources with
the same frozen point; it does not fit 17:00 visitor outcomes. Legitimate own
today-so-far receipts retain M25's remaining-today expression.

New retail intent is a genuine buyer action at an inspected active quote. A
private stock-independent intent calculation retains actual money, allowance,
need, price ceiling and marginal utility. It discloses only item/quantity/quote,
buyer/seller and provenance, never private finances/preferences. Empty stock
causes a real native `insufficient_stock` rejection. Stocked buying is unchanged.
Grain orders use funded profitable physical lot requests and actual clearing;
flour orders use the funded 12:10 plan and native attempts. No request creates
goods, coins, an enforceable supply promise or an unpaid wage claim.

Own cash-register sales, entrusted direct order books and owner-on-site witnesses
are distinct. Five-minute coverage and quote consistency determine complete versus
partial windows. Retail owners miss part of the window; their records remain
censored even when actual requests are valid. Farm/mill learn only direct inbound
grain/flour orders, never hidden downstream bread demand. No M18 response tables,
Bayesian posterior, Rust kernel or generalized optimizer was added. World and
contract authority remain GDScript.

## Main 30-day economic results, seed 42

Each arm/condition/horizon 1/3/30 ran twice in fresh processes: **36 cases,
72 audited captures**, with exact complete event/report replay. Initial terms
all cover days 1–3. Resident need is 450 meals; visitor meals are separate.

| Condition | Arm | Resident meals / missed | Visitor meals | Wheat / flour / bread / ale | Productive / standby shifts | Cash wages |
|---|---|---:|---:|---|---:|---:|
| Reference 21 | L/S/R |450 /0|180|630 /450 /630 /360|330 /0|3300|
| Tight 19 | L |260 /190|62|267 /230 /322 /72|143 /28|1710|
| Tight 19 | S |362 /88|86|414 /320 /448 /180|218 /10|2280|
| Tight 19 | R |395 /55|102|414 /360 /497 /84|217 /44|2610|
| Scarce 16 | L |359 /91|61|426 /300 /420 /252|225 /22|2470|
| Scarce 16 | S |341 /109|79|405 /300 /420 /204|214 /8|2220|
| Scarce 16 | R |378 /72|70|384 /320 /448 /120|205 /56|2610|
| No brew request | L |174 /276|50|161 /160 /224 /0|87 /21|1080|
| No brew request | S |286 /164|78|273 /260 /364 /0|143 /28|1710|
| No brew request | R |325 /125|116|315 /315 /441 /0|171 /21|1920|

All main earned guarantees are paid: **zero arrears and zero contract breaches**.
Attendance equals productive plus standby; fixed pay remains ten per attended day.
No-brew's original employees still receive their initial 60 despite zero brewing.

L→S isolates the declared smoothing/prior change, not correction of stockouts.
It improves tight/no-brew food access but **reduces scarce meals 359→341**, while
visitor meals increase 61→79 and bread output stays 420. That particular aggregate
resident loss is distribution, not less bread output.

S→R isolates the unfilled-request signal and its endogenous consequences. Tight
has 49 additional bread,33 additional resident meals and 16 additional visitor meals.
No-brew has 77 additional bread,39 additional resident meals and 38 visitor meals.
Scarce has 28 additional bread but 37 additional resident meals: **nine meals of
that resident gain displace visitors**. These are not 37 extra bread or an established
social-welfare improvement. Scarce R also harvests 21 less wheat and makes 84 less
ale than S. Food access, sector production and cash circulation do not all improve.

Reference stays economically identical in every arm without a special-case
survival rule. It already fills all food demand at installed food capacity.
Its brewery records 266 legitimate unsatisfied ale requests over 30 days; higher
forecast demand cannot exceed its two installed positions or change target 12.

## Employment, stalls and capital

Counts distinguish continuous renewals, other entries (including rehiring after a
gap), and lawful nonrenewals. Final jobs include next-day terms at the closing boundary.

| Condition / arm | Expired | Renewed | Other entries (rehire subset) | Nonrenewed | Final jobs | Zero-production days / last productive day |
|---|---:|---:|---:|---:|---:|---:|
| Reference, each |110|110|0 (0)|0|11|0 /30|
| Tight L |57|34|12 (8)|23|0|6 /25|
| Tight S |75|68|3 (1)|7|7|0 /30|
| Tight R |85|73|6 (2)|11|5|0 /30|
| Scarce L |81|76|2 (1)|5|8|0 /30|
| Scarce S |74|67|3 (2)|7|7|0 /30|
| Scarce R |85|75|5 (2)|10|6|0 /30|
| No brew L |36|19|6 (4)|17|0|12 /19|
| No brew S |56|40|7 (2)|16|2|0 /30|
| No brew R |63|49|8 (2)|14|5|0 /30|

There is one immediate employer switch in tight R; other employer changes after
unemployment are distinct from this boundary statistic. All original term dates,
exclusivity, attendance, payments and entry classifications remain audited.

R keeps some food-chain work through day 30 in constrained main cases, but not all
businesses. Tight R's last brewery production is day 17 and brewery ends with
**zero cash**, after 360 wages,84 inputs,336 sales and 12 earlier distributions.
Scarce R's brewery last produces on day 20 and ends with 12 cash after 420 wages,
120 inputs,480 sales and 48 earlier distributions. Their accrued margins are
−108/−60. All earned wages are nevertheless paid. No court, waiver or subsidy
erases the losses. Higher demand evidence does not repair M25's fallible future
input/production assumptions; additional commitments can become paid standby.

Mara misses 27/23 meals in tight/scarce R. No-brew R still leaves Mara with 29 missed
meals and Kira/Lyle with 19 each. Its food-chain activity is not universal food
access. See all fifteen individuals in [residents](M26_RESIDENTS.csv), daily
[stalls and firm stocks](M26_STALLS.csv), and [term histories](M26_TERMS.csv).

## Money, goods and shortage distinctions

Every row retains 9192 actual coins, without negative accounts. Household/firm/
external sums below show redistribution, not currency creation. Full per-firm
sales, purchases, cash/accrued wages, distributions and inventory are in
[business accounts](M26_BUSINESSES.csv).

| Condition / arm | Household / business / visitor coins | Circulation | Successful / rejected native purchases |
|---|---|---:|---:|
| Reference, each |1174 /480 /7538|13950|1230 /266|
| Tight L |550 /392 /8250|6210|498 /638|
| Tight S |606 /480 /8106|9236|786 /430|
| Tight R |822 /360 /8010|9335|738 /577|
| Scarce L |516 /480 /8196|9408|834 /388|
| Scarce S |572 /480 /8140|8976|778 /420|
| Scarce R |658 /336 /8198|8840|716 /592|
| No brew L |502 /368 /8322|3920|288 /756|
| No brew S |626 /412 /8154|6256|468 /642|
| No brew R |846 /420 /7926|7557|567 /592|

New rejected counts include genuine empty-shelf retail attempts, which M25 did
not issue. They must not be compared as an increase in accounting faults. L's
original purchases/timing/state are exactly preserved after excluding only these
extra failed attempts and observational events; no fake equal ledger hash is claimed.

R's witnessed unfilled grain/flour quantities are tight 105/55, scarce 121/110,
no-brew 15/25. These are funded direct input requests, not financially impossible
wish lists. Failed cash/authorization/stale/remote attempts do not enter those
quantities. Native recipes, cargo and final stocks reconcile independently.
For example tight R retains 12 farm wheat and 5 mill flour; scarce R retains 4
farm wheat. No-brew R ends with zero commodities. Unprocessed stock is not deleted.

| Condition / arm | Missed resident meals with credible stockout request | Missed without stockout request |
|---|---:|---:|
| Tight L/S/R |68 /0 /0|122 /88 /55|
| Scarce L/S/R |1 /1 /15|90 /108 /57|
| No brew L/S/R |138 /34 /12|138 /130 /113|

These are independent outcome diagnostics, **not NPC inputs**. With these unchanged
daily visits, no initial bread, positive bread utility and one-unit allowance,
the second category reflects lack of purchasing capacity at the actual food turn;
it is not counted as unsatisfied solvent demand. Final cash cannot retrospectively
fund a missed meal. Public refusals themselves disclose no private reason.
Input rationing, household affordability, operational capital depletion and
cautious projected nonrenewal remain different mechanisms. An owner declining a
nonpositive or unfundable three-day commitment is not an accounting breach.

## Forecast evidence, not hidden demand truth

Each main case has 116 next-day seller comparisons (four sellers, days 2–30).
A forecast below a native witnessed request lower bound is demonstrably low.
Censored retail windows cannot support latent-demand RMSE. No such RMSE is computed.

| Condition | L below lower bound / total deficit | S below lower bound / total deficit | R below lower bound / total deficit |
|---|---:|---:|---:|
| Reference |29 /261|29 /261|29 /72|
| Tight |70 /637|57 /297|37 /68|
| Scarce |74 /421|57 /283|40 /74|
| No brew |59 /713|57 /431|20 /46|

Even R persistently underestimates reference ale interest: its finite window and
one target 12 pseudo-day pull three observed 21-unit lower bounds to 19. This is
the preregistered heuristic's bias, not an invented estimate of unseen customers.

Exact next-day absolute errors are reported **only** for complete uncensored
observed windows. Reference has 58 such comparisons and zero error in every arm.
Tight L/S/R have 34/49/31 comparisons with total absolute error 46/96/98; scarce
38/52/18 with 33/107/68; no-brew 39/42/50 with 51/143/167. These subsets change
endogenously with behavior and censoring, so their totals are not a matched
forecast-accuracy ranking. Lower-bound improvement does not establish universal
point-forecast accuracy. See [daily evidence](M26_OBSERVATIONS.csv),
[frozen estimates](M26_FORECASTS.csv), and [direct orders by cohort](M26_ORDERS.csv).

## Staggered maturities sensitivity

This separately labeled legal endowment reuses M25's initial 1/2/3-day maturities;
new terms still last three days. Four 30-day cases ran twice and were independently
audited. Their original resources, prices and physical opportunities match, but
initial legal obligations differ from the main experiment.

| Condition / arm | Resident / visitor meals | Bread | Productive / standby | Circulation | Final jobs |
|---|---:|---:|---:|---:|---:|
| Tight L |230 /36|266|125 /25|5342|4|
| Tight R |363 /92|455|224 /37|9519|8|
| Scarce L |355 /65|420|221 /23|9304|8|
| Scarce R |354 /80|434|222 /31|9378|8|

All have zero arrears and production through day 30. Scarce R makes 14 more bread,
but residents eat one fewer and visitors 15 more. It is a direct counterexample to
an unconditional food-access benefit. Differences between staggered and main
cases cannot be attributed exclusively to demand forecasting.

## Verification and measured cost

Final acceptance passes, with no unresolved failure or unavailable required check:

- **3272 Godot checks**, zero failures: all 3244 historical checks plus 28 M26.
- **111 Python tests**, zero failures/skips: all 102 historical tests plus 9 M26.
- **169/169 historical payload fingerprints** unchanged, including M0's30-day
  seed 42 byte hash `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`.
- All **88 published M23/M24/M25 report/ledger controls** unchanged: M23's12,
  M24's24 main and 12 vacancy cases, M25's24 main,6 cash/maturity fixtures and 10
  lifecycle witnesses. Their original independent audits also pass.
- All **12 fresh C/D synchronous/scheduled 1/3/30-day original independent
  financial/spatial/observation/numerical audits** pass.
- All 72 main and 8 staggered M26 captures replay/audit exactly; four additional
  labeled seller fixtures pass twice. L matches every original native economic
  event, receipt link after renumbering, state, accounts and daily outcomes in
  all 12 main comparisons, plus both staggered comparisons.
- **16 final 30-day recaptures** retain the original experimental report/ledger
  hashes under tightened failed-order quantity/price/provenance checks. Six final
  isolated reference timing captures do likewise. No experimental outcome changes.
- **15 rehashed forgery categories reject**: false interest, witness, private
  data, future samples/view, doubled/fake order, estimate, term, payroll, censoring,
  quote, receipt duplication, failed lot quantity and failed retail price.
- The public `run_simulation.gd --scenario settlement_demand_observation` entry
  reproduces the three-day scarce R canonical report/ledger. Editor import and
  whitespace checks pass. The **M22 smoke passes with zero performance warnings**;
  ten-job callback p95 is 1.863ms from 44 samples, worst 3.119ms, no supported p99.

Fixtures remain separate test endowments/protocols. `poor_visitors` transfers the
initial 8622 visitor coins to Ada:15 resident meals, zero visitor orders/meals.
`cashless_buyers` moves mill/brewery's240 initial coins to visitors and starts with
21 explicitly accounted farm wheat: no credible wheat order, a truly witnessed
zero-interest farm window, and 57 real downstream unfilled units. `remote_farm`
routes Bram away before procurement, creating no imaginary mill wheat request.
`duplicate` adds a second Ada visit; only one order is recorded. Every fixture
retains 9192 coins and reconciled initial/produced/consumed goods. Main-case native
witnesses additionally cover bread/ale stockouts, voluntary refusals, partial
coverage, stale/invalid quotes, funded grain 21/19/16, flour shortage, combined
visitor allowance and later-than-meeting arrivals.

Development checks initially caught parse/rule-lookup errors, an overly narrow
15:55-only guard on midnight authority validation, and a remote-quote assumption
in the opt-in audit adapter. One initial test incorrectly expected tight 19's
first-day lot allocation to have scarce 16's five-unit shortage; the actual tight
shortage is three. These were corrected without changing allocation or parameters.
Later audit tightening prompted the 16 pinned recaptures, not economic tuning.
All final native/Python logs are clean.

See [check manifest](M26_CHECKS.json), [test log](M26_TEST_LOG.txt),
[historical payloads](M26_REGRESSIONS.csv), [published control pairs](M26_HISTORICAL_CONTROLS.csv),
[original audits](M26_ORIGINAL_AUDITS.csv), [fixtures](M26_FIXTURES.csv),
[final pinned audits](M26_FINAL_AUDITS.csv), and [smoke](M26_SMOKE.json).

Godot 4.6.3, Python 3.12.14, Linux 6.18.57 x86-64, glibc 2.41, three visible CPUs,
two-CPU quota,8GiB limit. The initial matrix ran sequentially before full
verification, two fresh processes per case. A final isolated reference repeat
followed the completed suites and audit refinements; its rows below measure the
final source. Constrained rows retain the initial matrix samples. All economic
outputs remain pinned, and timings never enter canonical state. No frame/input
latency is established. Thirty-day medians, worst latency across both processes:

| Condition / arm | Run s | Command s | Report s | Peak KiB | Events | Worst appointment / tick ms |
|---|---:|---:|---:|---:|---:|---:|
| Reference L |3.803|9.672|2.619|754782|48363|61.180 /6.834|
| Reference S |4.086|10.345|2.672|754826|48363|141.237 /91.209|
| Reference R |3.715|9.176|2.349|754708|48363|90.858 /50.185|
| Tight L |3.357|7.797|2.247|655900|43350|37.802 /12.557|
| Tight S |3.760|8.574|2.502|700060|45268|49.338 /9.130|
| Tight R |4.315|9.011|2.501|711886|45587|54.651 /15.109|
| Scarce L |4.268|9.394|2.575|706098|45700|120.287 /24.995|
| Scarce S |3.808|9.068|2.717|699254|45257|66.026 /8.084|
| Scarce R |3.609|8.464|2.413|715214|45615|99.328 /11.764|
| No brew L |2.957|7.218|2.164|620298|41620|32.352 /17.423|
| No brew S |3.502|8.458|2.484|654782|43157|52.958 /21.401|
| No brew R |4.578|9.637|2.160|668520|43829|76.606 /30.693|

Reference adds 3112 events over M25's45251. Peak command memory is about 737MiB,
versus M25's published 646MiB: retained books/snapshots/report copies have a real
cost. These published-context figures are not a fresh controlled speed ratio.
No performance optimization or native port was attempted. Some real appointments
still exceed 50ms, including the final S reference 141.237ms appointment and 91.209ms
tick, and the initial legacy scarce 120.287ms appointment. Their root causes were
not separately profiled; elapsed tails can include host scheduling. These negative
observations are retained. Two repeats do not establish robust tails or interactive
responsiveness.

Main experiment command wall 456.686s; sensitivity 135.802s. These are measured
driver intervals including captures, replay comparisons and independent audits,
not simulation-only times or total Codex elapsed time. See per-process
[performance](M26_PERFORMANCE.csv), [latency](M26_LATENCY.csv), and separate
[staggered performance](M26_STAGGERED_PERFORMANCE.csv). The
[final reference samples](M26_REFERENCE_FINAL_PERFORMANCE.csv) took 91.447s including
six complete captures and independent audits; they are not substituted into the
original matrix CSV.

| Verification phase | Actual command wall seconds | Exit |
|---|---:|---:|
| Full Godot suite |633.174|0|
| Full Python suite |204.560|0|
|169 historical payloads |1000.785|0|
| Fresh original C/D capture |125.522|0|
| Original C/D independent audits |431.933|0|
| M23 controls |75.882|0|
| M24 main / vacancy cases |373.814 /38.289|0|
| M25 main / fixtures / lifecycle |320.113 /52.062 /37.945|0|
| M26 seller fixtures |22.699|0|
| Final 16 M26 pinned audits |373.090|0|
| Public CLI parity |1.421|0|
| M22 smoke |2.639|0|

Several verification lanes overlap; **do not sum their walls as elapsed time**.
Full Python began after the native-extension-dependent Godot work completed;
remaining M26 captures used GDScript only. Final reference timings and smoke were
isolated after all correctness lanes. [Phase records](M26_VERIFICATION.csv) retain
the measured command intervals, not an invented total Codex time.

## Reproduction, limitations and review boundary

```sh
python 3 -B scripts/tools/run_demand.py --checkpoint --output work/m26/checkpoint
python 3 -B scripts/tools/run_demand.py --output work/m26/experiments
python 3 -B scripts/tools/run_demand.py --staggered --output work/m26/staggered
python 3 -B scripts/tools/check_demand_fixtures.py --output work/m26/fixtures
python 3 -B scripts/tools/summarize_demand.py --input work/m26 --output docs
godot --headless --no-header --path . --script res://tests/run_tests.gd
python 3 -B -m unittest discover -s tests -p 'test_*.py'
```

The [runs/pins](M26_RUNS.csv) and [legacy economic parity](M26_PARITY.csv) retain
all horizons; [daily outcomes](M26_DAYS.csv) include shortage distinctions.
Historical verification commands follow [PERFORMANCE.md](PERFORMANCE.md) and M25's
published control commands. Full native traces remain transient audit inputs,
not committed event dumps.

The smoother is deliberately low-biased, bounded and supply-sensitive. Coverage
does not reveal customers who never arrive; solvent requests do not measure the
needs of people without cash. Fixed targets, whole lots, presumed future input
availability, finite external money and synchronized terms still shape outcomes.
Only seed 42 and 1/3/30 days were preregistered here; no annual resilience or general
autonomous equilibrium is claimed. Duplicate positive buyer/day/offer attempts
are rejected within this one-visit schedule, not implemented as a retry/backorder
system. Native wages remain binding even when projected production fails.

A possible separately reviewed next step is a generalized **per-firm Bayesian
demand model** with industry-appropriate observations/censoring and a permitted
snapshot interface. It need not copy bakery price-elasticity tables into B2B
industries. If profiling justifies it, multi-firm numerical optimization could
use a narrow Rust calculation boundary while keeping information filtering and
world authority explicit. Separately controlled wage competition should wait
until contract valuation is better understood. None of those changes is part of
M26; no default economic baseline is adopted. **Stop for review. No M27.**
