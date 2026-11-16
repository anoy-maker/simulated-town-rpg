# M18 — Bayesian bakery memory and capital-aware price discovery

Implements [issue #21](https://github.com/anoy-maker/simulated-town-rpg/issues/21), from M17 `b8021818995c546bc3eb6d75b86fa2ab193dcc1f`. No historical scenario or artifact is replaced.

## Fixed choices before experiments

A/B/C/D reuse M17's exact control initialization, bodies, schedules, transport custody, nine six-coin shifts, recipes/assets, household needs, finite visitor account/requests/private six-coin ceiling, farm/mill prices, and realized-earnings distributions above 120. Only Cora's bakery bread price policy differs. A keeps four; B calls the unchanged M16 pure short-memory policy with a permitted-observation adapter; C uses the specified Bayesian model without adaptive continuation choice; D uses the same model with one-step EVSI. All stages collect the same permitted memory/passive bakery beliefs. No baseline staffing, capital retention, hours, movement or visitor behavior changes.

Price decisions occur at **12:25, immediately after Cora's existing physical flour deposit**. No new appointment or travel is inserted. This supplies actual, on-site public flour-price/availability information consulted at 12:10 and the bakery's actual current cash/flour, before 14:00 work and afternoon customers. Quote revision is administrative, not another physical shift. Today projects only remaining payroll/production/sales/distribution; already-paid flour is not charged twice. The next operating day projects complete procurement, actual whole shifts, sales and distributions. The first quotes still start at 2/4/4. B retains its original conditional eighteen-new-bread plan/66-cost comparison, without adding financial intelligence to that benchmark.

### Permitted memory

Each owner has append-only day records for their own accounts and personally witnessed on-site encounters. Fields separate posted prices, local/visitor physical arrivals, inspections, eligible inspections, purchases, visible declines, stock-limited/closed/unresolved cases, actual accounting sales/input/payroll/distributions, own inventories/cash and genuinely consulted public quotes. Raw records and derived beliefs are separate. Accounting sales remain legitimate even if an owner was absent; they never fill in an unwitnessed conversion. Permanent memory contains cohort aggregates and provenance IDs, not recognized customer histories or private balances/ceilings. A transient authority-side inspection/outcome join is discarded after each encounter/day.

A bakery traffic day is usable only when Cora covers the complete fixed retail observation window 15:00–17:15. Witnessed arrivals earlier that day, including her own arrival, remain part of that day's observed count. Absent/incomplete observation skips the traffic update; an observed zero-arrival day updates bin zero. Closed hours do not erase actual observable arrivals. Conversion uses only witnessed open/active/in-stock inspections with witnessed outcomes; any stock-limited, closed or unresolved observation in a cohort-day conservatively excludes that cohort's conversion likelihood. n=0 excludes conversion. Actual sales are retained as a lower bound, never converted into invented failures.

Traffic is the required Dirichlet model for 0..12+ counts, alpha=1/4 each, with 12+ forecast as 12. Response has twelve threshold patterns (q=0.9 below/equal K, else 0.1), plus the required gradual q=clamp(0.8−0.075(p−4),0.1,0.9), with priors 0.8/12 and 0.2. One cohort-day beta-binomial update uses a=2q,b=2(1−q), normalized in fixed order after max scaling. Each new day first mixes weights with the original prior using hazard 0.02. No raw records are forgotten.

Cora observes three local employees already at the bakery before her own arrival. This known, on-site carry-in is separate from witnessed arrivals. Forecast local opportunities are min(12, predicted witnessed arrivals + currently observed carry-in), and each opportunity can buy at most one bread. Today's arrival model is conditioned on arrivals already witnessed by decision time; future days use the unconditional learned traffic model and the same known carry-in approximation. Visitors have a separate subjective 0..12+ traffic distribution, with no access to the actual six requests. Locals are served first, and finite stock limits visitor opportunities. No private household budgets, visitor ceiling or future arrivals are supplied to the forecast.

### Bounded financial and information objective

Planning prices are 1..12; actual quote authority retains its existing numerical limit. Candidates are current, adjacent down, prior actually posted lower prices (including censored/no-traffic days), and at most current+1. Ties prefer current then lower; numerical roundoff tolerance is 1e-9 coins, not a risk penalty. Historical posted prices are a search history, not a claim that censored feedback identified their conversion rates.

The objective is discounted business distributions plus residual business cash at the end of fourteen days, discount 0.99/day. Every payout is deducted from both cash and remaining realized earnings, avoiding double counting and preserving the 120 payout floor. Remaining inventory has **zero horizon salvage in this restricted approximation**, without deleting native goods. Household utility/food expenditure and asset valuation are not added to the stated business financial objective.

The read-only own-business projector pays for up to three four-flour purchase requests before whole productive shifts, using current funds and the latest genuinely inspected public flour price/availability (capped at the existing twelve-input plan). It then pays/produces only feasible whole shifts, sells available bread and distributes eligible realized earnings. Public supplier availability is a fallible persistence assumption, never knowledge of future private supplier cash/production. First and next operating day use integer conditional state transitions for considered outcomes. Remaining twelve days use deterministic mean-state continuation at the selected continuation price, applying the same payment order/whole-shift feasibility and hazard but no further hypothetical learning. Fractional expected cash/stock are projection moments, not native balances. At projection-only whole-input/shift boundaries, 1e-9 absorbs floating-point roundoff; it never supplies native coins or changes native validation. This projects actual interruption consequences rather than assigning a fixed bankruptcy penalty.

For every candidate, forecast traffic and beta-binomial conversions produce full sales/revenue distributions. Stock-limited outcomes use the beta-binomial first-success hitting-time distribution to distinguish eligible inspections from later unstocked ones. For bounded EVSI integration, each cohort's joint observable outcomes are sorted by (sales, arrivals, eligible inspections, censor flag), partitioned into **three equal-probability quantile bins**, and represented by the weighted median state of each bin. Visitor bins are conditional on the local representative's remaining stock. This gives at most nine plausible observable branches/candidate; no sampled future truth or RNG is used.

For each branch y, let a0(y) be the best continuation price under frozen pre-observation beliefs and the branch's actual financial state. Evaluate its continuation value under the hypothetically updated beliefs. C integrates that unadapted continuation value; D integrates the maximum under the same updated beliefs. Their difference is nonnegative one-step EVSI from adapting the continuation action. C does not select a continuation based on the new information; using posterior predictions to integrate the value of its unadapted action preserves the correlation between evidence and market conditions. D evaluates this for **every candidate, including staying**. No known-price information value is set to zero by fiat. Beyond tomorrow the continuation price is held fixed, so this is not a general dynamic-programming optimizer.

Cost bound: at most twelve candidates × nine observable branches × two searches of at most twelve continuation prices. Each continuation integrates at most 25 next-day sales totals and twelve mean-state tail days. Fixed response tables, traffic-pattern components and hazard mixtures are cached; there is no movement-ledger rescan at a price decision. Reports retain inputs, candidate values/EVSI, demand distributions, selected-branch liquidity/shift projections and audit fingerprints, rather than all internal planning paths.

### Declared fixtures and experiments

Run A–D for 1/3/30 days, seed 42, twice independently; preserve M17 and compare A's complete native ledger/state/accounting exactly. Measure command simulation execution times separately from Codex wall time, also running the corresponding M16 nonspatial A–D controls. No priors/hazard/price range/horizon/forecast parameters are tuned after inspecting results.

Separate toy fixtures use the issue's exact two-hypothesis probabilities, no production thirteen-pattern assumptions. Expected tolerant posteriors: all=8/11, none=1/25, three/no visitors=1/4. The unrounded teaching trial value is **590.8125**, versus 588 never experimenting; immediate price-seven surplus 31.65 versus 42 at six. A second abstract fixture verifies that staying can itself be informative.

The 70/120/300 conditional cash calculations use before-procurement states and exact conserved 9192-coin balance sheets. The 300 example assumes **180 of prior retained realized earnings**, yielding a 114 payout after a zero-sales 66-cost day. If the same cash is contributed capital, no such payout is eligible; test both. These are hypothetical reconciled finance calculations, not new village endowments or injected native money. Additional artificial-evidence/capital comparisons use predeclared cash 4/54/120/234/300, current price seven, posted history 4/5/6/7 and the same valid artificial evidence (six complete days of 12/12 local and 6/6 visitor purchases at price six, followed by 12/12 local and 0/6 visitor purchases at seven; hazard before every day), recording whichever choices emerge without prescribing a winner.

## Actual results and verification

Godot **4.6.3.stable**, Python **3.12.14**. All twelve predefined stage/horizon cases completed, each with two independent simulation processes, identical complete reports/decision values, authoritative ledger reconstruction and independent mathematical checks. All monetary balances remain nonnegative and combined currency remains **9192** after every economic event. No parameter was adjusted to improve outcomes.

The complete native suite passes **3066 checks, zero failures** (3005 historical + 61 M18). The complete Python suite passes **63 tests** (51 historical + 12 M18). The separate pure-native mathematical invocation passes **37 checks**; the focused native M18 invocation passes all **61**. All **157 historical payload/hash comparisons** pass: 156 published M0–M17 payloads plus the full M16 competition trace against its detached historical commit. M0's 30-day seed-42 JSON remains `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`. M17's five existing compact hashes remain unchanged. A additionally matches M17's full native ledger hash, initial/final state, accounts, production, consumption, money, purchases and shifts at **1, 3 and 30 days**. Native unit split-run tests cover A/C/D; additional three-day 1+2 versus uninterrupted comparisons pass for **all four stages**, including B's exact prior-day adapter memory.

### Economic outcomes

Bakery-only financial amounts below; meals are resident meals, visitors are purchased loaves, shifts/breaches cover the entire settlement. Full exact hashes and prices are in [M18_RUNS.csv](M18_RUNS.csv).


| Stage | Days | Meals / missed | Visitors | Paid shifts / breaches | Bakery sales | Inputs | Payroll | Distributions | End cash / bread |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A | 1 | 12 / 0 | 6 | 9 / 0 | 72 | 48 | 18 | 6 | 120 / 0 |
| A | 3 | 36 / 0 | 18 | 27 / 0 | 216 | 144 | 54 | 18 | 120 / 0 |
| A | 30 | 360 / 0 | 180 | 270 / 0 | 2160 | 1440 | 540 | 180 | 120 / 0 |
| B | 1 | 12 / 0 | 6 | 9 / 0 | 90 | 48 | 18 | 24 | 120 / 0 |
| B | 3 | 36 / 0 | 12 | 27 / 0 | 282 | 144 | 54 | 84 | 120 / 6 |
| B | 30 | 257 / 103 | 12 | 268 / 2 | 2350 | 1440 | 528 | 382 | 120 / 259 |
| C | 1 | 12 / 0 | 6 | 9 / 0 | 90 | 48 | 18 | 24 | 120 / 0 |
| C | 3 | 36 / 0 | 12 | 27 / 0 | 282 | 144 | 54 | 84 | 120 / 6 |
| C | 30 | 360 / 0 | 174 | 270 / 0 | 3198 | 1440 | 540 | 1218 | 120 / 6 |
| D | 1 | 12 / 0 | 6 | 9 / 0 | 90 | 48 | 18 | 24 | 120 / 0 |
| D | 3 | 36 / 0 | 12 | 27 / 0 | 282 | 144 | 54 | 84 | 120 / 6 |
| D | 30 | 358 / 2 | 168 | 270 / 0 | 3160 | 1440 | 540 | 1180 | 120 / 14 |

A keeps bread at four, reproducing M17. Every resident ends day 30 with 66 coins. All 540 bread are consumed (360 locally, 180 by visitors).

B repeats M16 B's **economic totals**, although its native ledger is spatial: prices climb 5/6/7/8/9/10 and then range 9–11. It never learns the visitor refusal boundary. All six visitors still visibly arrive daily; purchases cease above six, rather than visitors disappearing. B has **103 missed resident meals**, **168 unfilled visitor requests**, **259 unsold bread and eight flour**. Bakery cash before payroll falls to 16 on day 7 and 17 on day 10; the final sorted baker employee Kira misses one shift on each. Lowest end-of-day bakery cash is 64. The 120 distribution floor never acts as a protected operating reserve. B eventually returns to 120 cash, which does not erase the intervening shortfalls or missed meals.

C chooses **5, 6, 7, then 6 on days 4–30**. It holds the uncertain six-coin price for 27 consecutive days after the first rollback; this duration is an outcome, not a mandatory experiment period. It serves all 360 resident meals, sells 174 visitor loaves, completes all 270 paid shifts, and ends with six unsold bread. Bakery operating cash surplus is 3198−1440−540=**1218**, all distributed above the unchanged capital floor. Cora ends with **1044 personal coins**; each other resident holds six. More owner income does not imply broader household savings.

D chooses the same sequence through day 14, **probes seven on day 15**, then returns to six on day 16 and holds it through day 30. Its second probe loses six visitor sales and two local sales. **Ada and Bram each miss their day-15 meal**: each has six personal coins at shopping time, receives no employee wage, and receives the day's ownership distribution only after meals. The bakery cannot turn its funds into their purchasing power before that appointment. The policy never receives those private balances. D's day-15 sales are 70 versus C's 108, giving 38 less realized surplus. No shift is missed, but final bread stock rises to fourteen. D ends with Ada/Bram at twelve coins, Cora at **1005**, and all nine employees at five. Their higher/lower cash reflects purchases missed or paid, not equal welfare.

Farm and mill each produce **360 units** over thirty days in every stage. Each pays 540 wages, distributes 180 and ends at 120 cash with no commodities. All stages buy 360 flour for the bakery. A/C/D convert it all into 540 bread; B converts 352 flour into 528 bread and retains eight flour. No output or input is removed to repair a result. All owners remain nonproductive managers; all wages go to existing employees.

| Stage (30 days) | Successful / rejected atomic purchases | Visible local / visitor declines | Cash circulation | Village / external cash | Bakery distributions + final cash − initial cash | Foregone cash vs best of these four tested policies |
|---|---:|---:|---:|---:|---:|---:|
| A | 720 / 0 | 0 / 0 | 6480 | 1152 / 8040 | 180 | 1038 |
| B | 449 / 0 | 103 / 168 | 6860 | 498 / 8694 | 382 | 836 |
| C | 714 / 0 | 0 / 6 | 8556 | 1470 / 7722 | 1218 | 0 |
| D | 706 / 0 | 2 / 12 | 8480 | 1434 / 7758 | 1180 | 38 |

Buyer policies usually decline without issuing an atomic purchase when no affordable offer exists. **Zero rejected atomic purchases does not mean zero failed shopping attempts.** The last column is an undiscounted, zero-inventory-salvage comparison of only these tested thirty-day policies, not regret against an omniscient or optimized policy. We did not run or infer a constant-six counterfactual. C has higher bakery financial returns than A and B here, but A serves six more visitor meals. D does not improve actual returns or food access over C.

### Information value, predictions and confidence

D explicitly values staying. On day 1 its current-price-four candidate has ordinary value **20.98875**, EVSI **0.83560**, total **21.82435**. The price-five candidate has ordinary value **42.62245**, EVSI **0.32073**, total **42.94318** and wins. Staying was informative, but that information was insufficient to outweigh the alternative's financial value.

The C/D native states and beliefs are identical entering day 15. At six, both have ordinary continuation value **416.62746**, with D's additional adaptation value zero under this approximation. At seven, ordinary value is **401.75497**, but D estimates EVSI **43.37675**, for total **445.13173**. C therefore stays and D probes. Those are subjective projected values, not guaranteed receipts; the actual probe yields four coins of daily operating surplus rather than the 42 earned by C. The hazard allows uncertainty to return, and the bounded forecast overvalues this particular second experiment. No risk penalty, subsidy, reserve change or forced reversal is added afterward.

All actual main-run cohort-days have positive observed traffic, open shops and complete eligible outcomes: **30 eligible local and 30 eligible visitor days per stage**, zero censored or no-traffic days. Crafted tests separately cover zero traffic, absence, closure, stock limitation and unresolved observations. No-travel/closure cases are not pooled into the calibration scores below. Six visitor outcomes are evaluated through one correlated beta-binomial likelihood per day.

| Stage | Mean local / visitor negative log predictive score | Mean local / visitor squared conversion-rate error | Final largest local / visitor pattern posterior |
|---|---:|---:|---:|
| A | 0.4723 / 0.3534 | 0.0135 / 0.0137 | 0.1104 / 0.1101 |
| B | 2.5200 / 0.4261 | 0.1799 / 0.0359 | 0.8132 / 0.7244 |
| C | 0.4887 / 0.4277 | 0.0178 / 0.0361 | 0.1609 / 0.7584 |
| D | 0.5644 / 0.4329 | 0.0175 / 0.0374 | 0.1630 / 0.8822 |

Scores condition on actual eligible inspection count and the pre-evidence weights; squared error is (predicted conversion rate − actual rate)^2. Lower is better on those observations, but stages encounter different prices/outcomes, so these are not matched off-policy scoring contests. A/B collect **passive** Bayesian diagnostics; those beliefs do not guide their prices. At day 30, C/D's largest visitor pattern is threshold K=6, but substantial model uncertainty remains. Local thresholds above posted prices remain poorly identified. No posterior is asserted to identify structural willingness to pay or private wealth.

C's full Bayesian forecast averages **15.10 sales/day** versus 17.80 realized; D's averages **14.96** versus 17.53. At day 1, both forecast 9.58 sales at five and actually sell eighteen. At day 30 they forecast 15.83 at six and sell eighteen. Their q=0.9 “tolerant” patterns, traffic pseudocounts and hazard still underpredict this deterministic market. D's second probe predicts 11.40 sales and sells ten. The selected-action three-bin quadrature differs from the full forecast mean by **−0.509 to +0.428 loaves** across C/D days. This is an observed approximation error, not a corrected calibration parameter. C's zero EVSI fields mean **adaptive search not evaluated**, as marked by `information_evaluated=false`, rather than proof that its price choices contain no information.

[M18_CALIBRATION.csv](M18_CALIBRATION.csv) includes eligible/no-traffic/censored categories, log scores, rate errors, entropy and q quantiles. [M18_DAYS.csv](M18_DAYS.csv) contains day-level finance, production payroll, sales, full forecast means, quadrature bias, meals and breaches. [M18_CANDIDATES.csv](M18_CANDIDATES.csv) records every actual decision's candidate scores. [M18_RESIDENTS.csv](M18_RESIDENTS.csv) gives all twelve residents' money, wages, distributions, consumption expenditure, meals and missed meals in all four thirty-day treatments. Canonical CLI reports additionally contain complete raw memories, distributions and auditable branch liquidity states; verbose traces are audited transiently, not committed.

### Artificial evidence and finance results

Both independent implementations reproduce the toy posteriors **8/11, 1/25, 1/4, 1/4**, the immediate surpluses **31.65 / 42**, and the exact fourteen-day trial value **590.8125** versus **588**. The separate informative-stay fixture returns value six for learning by staying versus four for an equally profitable uninformative trial; it does not special-case current-price information value to zero.

All ten fixed capital/evidence projections are independently audited, with exact reconciled 9192-coin hypothetical balance sheets. At cash **4**, C and D retain seven because every candidate's projected financial value is zero: existing flour cannot pay a shift, and no bread exists to sell. At cash **54, 120, 234 and 300**, both select six under the same supplied evidence. No strategy receives better observations or extra resources. The positive-cash cases do not produce different C/D prices; that is the result, not a failed assertion. The search test explicitly admits non-adjacent historical lower prices while permitting only a one-coin upward probe. Actual world rollbacks here are adjacent 7→6; no non-adjacent world rollback is claimed. Detailed candidate values are in [M18_CAPITAL.csv](M18_CAPITAL.csv).

The 70/120/300 zero-sales calculations yield **4/54/234 before payout**, **4/54/120 after payout**, with a **114** payout in the prior-earned-surplus case and none for contributed capital. A two-day closed-shop native fixture verifies the precise next-day liquidity consequence: after cash 54, actual procurement spends 48 first, permitting only one six-coin shift; bakery ends with cash zero, eight unused flour and 24 real bread. The projector does not invent replacement inputs, free wages or forced sales. An absent-owner fixture records seventeen legitimate accounting sales but zero witnessed inspections and no false traffic/conversion update.

### Execution times

Measured with `Time.get_ticks_usec()` **around `runner.run()` only**, excluding initialization, startup, report generation, auditing and serialization. These are actual simulation execution times, **not Codex wall time**. Timings are stored outside canonical JSON. Runs shared the execution environment with verification jobs; these single observations are not controlled microbenchmarks, and D's shorter measured thirty-day time must not be interpreted as inherently cheaper than C.

| Stage | Days | Spatial M18 seconds | Existing nonspatial M16 seconds |
|---|---:|---:|---:|
| A | 1 | 0.026260 | 0.033166 |
| A | 3 | 0.149062 | 0.050457 |
| A | 30 | 7.288842 | 0.381007 |
| B | 1 | 0.079057 | 0.045966 |
| B | 3 | 0.274923 | 0.097391 |
| B | 30 | 4.160417 | 0.142080 |
| C | 1 | 0.775817 | 0.008552 |
| C | 3 | 10.103890 | 0.037731 |
| C | 30 | 57.103361 | 0.151085 |
| D | 1 | 0.693485 | 0.003938 |
| D | 3 | 2.359943 | 0.011869 |
| D | 30 | 39.738402 | 0.092925 |

M16 A/B are useful economic controls: M18 A retains their fixed-control accounting, and M18 B reproduces M16 B's economic results. M16 C/D additionally activate mill/farm price policies, whereas M18 C/D change only bakery learning. Their labels therefore do **not** identify matched economic treatments; the nonspatial numbers above provide execution-cost context. Spatial travel, custody and observation generate more work/events, and Bayesian continuation adds price-evaluation cost.

### Verification commands and implementation limits

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
godot --headless --path . --script res://tests/run_learning_tests.gd -- --math
python3 -B scripts/tools/run_learning.py --output /workspace/work/m18
godot --headless --path . --script res://scripts/tools/learning_fixtures.gd > /workspace/work/m18-fixtures.json
python3 -B scripts/tools/summarize_learning.py --input /workspace/work/m18 --output /workspace/work/m18-tables --fixtures /workspace/work/m18-fixtures.json
```

One initial C-stage audit **failed** before verification: native and log-gamma reference arithmetic differed by tiny floating-point error at whole-production boundaries, which produced materially different continuation actions. The projection-only 1e-9 boundary tolerance fixes that numerical error; independent values and all final runs pass. An early development invocation also reported a GDScript inherited-constant name collision; it was corrected before experiments. No economic result was repaired by parameter tuning. A distribution-convolution optimization replaces repeated pairwise sums with the identical total-sales PMF; the independent implementation retains the pairwise reference and verifies the values.

The thirteen-pattern model assumes provisional cohort stationarity with a fixed hazard, not structural demand truth. It omits unobserved customer financial trajectories and cannot attribute a refusal to a private budget versus a private ceiling. Its fixed observation-coverage rule is conservative; incomplete days preserve raw lower bounds but skip traffic fitting. The 12+ arrival bucket is truncated to twelve, current carry-in and public supplier availability are approximated as persistent, EVSI uses only nine representative observable branches, and the twelve-day tail uses mean states and a fixed continuation price. These approximations can miss rare financial interruptions or overvalue learning. No full-horizon optimality or economically viable autonomous equilibrium is established.

Money still flows from a **finite** external account. C/D concentrate most acquired household cash in Cora, while A distributes household purchasing power more evenly. Thirty days do not establish resilience to visitor depletion, input shocks or longer-term liquidity changes. We do not extrapolate the result into an unrun year, adopt six as a default, or change capital retention/staffing to make it succeed. Native snapshot reload/persistence remains outside scope; split runs continue the same deterministic in-memory runner.

Changed implementation areas: minimal protected hooks in the existing spatial world/runner and opt-in auditor allowance; isolated learning world/runner, pure beliefs/finance/policy; independent audit, matrix/fixture/timing/diagnostic tools; focused native/Python tests and CLI selection; README, architecture, roadmap and the M18 result tables. Existing economic authority, M16 pure policy and historical configurations/artifacts are unchanged.

**Stop after M18 for review. No M19 implemented.**
