# R26 — Economic architecture research and feasibility-diagnostic proposal

**Project:** Simulated Town RPG  
**Date:** 2026-11-17  
**Status:** Completed research review; no simulator code changes, Codex execution, branch creation, or new economic experiments.  
**Inspected implementation:** `anoy-maker/simulated-town-rpg`, `codex/m26-demand-observation`, including M23/M25/M26 documentation, `scripts/sim/brewery_config.gd`, `brewery_policy.gd`, `binding_policy.gd`, `binding_world.gd`, and the published M26 result/CSV files.  
**Decision recommended:** Preserve M26's optional treatments. Make the next milestone a **read-only, independently audited economic-feasibility and failure-attribution diagnostic**, not a generic firm optimizer or wage/price-policy intervention.

## 1. Executive synthesis

The town already maintains strong **accounting and event validity**: native validated transfers, conserved 9,192 coins, physical production recipes, enforceable three-day wage claims, and independent event reconstruction. These guarantees are necessary but do not establish that particular labor/input/retail configurations are sustainable, profitable to individual agents, or capable of satisfying residents' needs.

M26 improves a seller's information about genuine stockout-caused requests without changing prices, wage rates, input allocations, and binding contracts. Relative to the matched sales-only smoother, it increases resident meals in every constrained main case, but can also produce substantial standby, unprofitable brewing, and different distributional outcomes. Improving information about **demand** is not equivalent to improving information about **supply, cash timing, input competition, or other agents' purchasing power**.

**R26's main mathematical result** is that the tight/scarce harvest caps create a real distinction between *physical capacity* and *new-job profitability*. A third farm shift produces at most five wheat at cap 19, or two wheat at cap 16. At the two-coin wheat price and ten-coin wage, either shift is zero/negative contribution **when choosing to incur an additional wage obligation**. However, if the worker is already legally owed the wage, the current-day marginal wage for assigning productive work is zero: M26's initial contracts in fact allow day-one harvest of 19 (tight) and 16 (scarce). Contract **entry/renewal** and **already committed work assignment** must never be conflated.

A five-wheat incremental chain at current prices shows a second wedge: an extra farm shift yields margin 0, extra mill shift margin +5, extra bakery shift margin +7 if seven loaves sell. Thus independent profit incentives can leave a collectively positive (+12) production opportunity unrealized. At fixed flour price five and whole-coin wheat prices, the farm wants wheat price >2 while the mill wants wheat price <3; no integer wheat price satisfies both strictly positive marginal contributions for that pair of shifts. This is a conditional example, **not** a claim about every observed day, a universal welfare comparison, or proof that price changes alone solve the economy.

## 2. Evidence from M26 — what was actually observed

All numbers below are 30-day, seed-42, main endowment, **not** estimates of long-run reliability. M26 used two fresh-process repeats per case to establish deterministic replication, not independent statistical seeds. Total resident meal opportunities = 450.

| Scenario | Sales smoother: resident meals / bread / standby | Requests smoother: resident meals / bread / standby | Requests-minus-sales resident gain | Brewery accrued margin (S → R) |
|---|---|---|---:|---:|
| Reference 21 | 450 / 630 / 0 | 450 / 630 / 0 | 0 | 480 → 480 |
| Tight 19 | 362 / 448 / 10 | 395 / 497 / 44 | +33 | +210 → −108 |
| Scarce 16 | 341 / 420 / 8 | 378 / 448 / 56 | +37 | +252 → −60 |
| No brew request | 286 / 364 / 28 | 325 / 441 / 21 | +39 | −60 → −60 (initial committed wages without brewing) |

**Do not equate resident meals with production or total welfare.** In scarce, request-aware produces 28 more bread yet residents consume 37 more while visitors consume 9 fewer. The reference produces all installed bread and still records 266 valid unsatisfied ale requests across 30 days; available brewing labor/equipment constrains output. No payment arrears, aggregate coin loss, or contract breach appears in the main experiments. Brewery ending cash under request-awareness is 0 (tight) and 12 (scarce). Mara, the unpaid owner of that firm, misses 27/23 meals in those respective conditions; results should be assessed by person, not only town total.

Unfulfilled solvent purchase requests are lower bounds on demand; no-request missed meals cannot be treated as solvent stockouts. In M26, the diagnostic category of missed meals without a stockout request is associated with inability to finance food **at the actual shopping time** under the scenario's rules, and must not be retrospectively 'funded' with the resident's end-of-day cash. A retailer's private complete-demand truth is not established by a censored window. M26's report explicitly warns against interpreting lower-bound forecast scores as actual RMSE.

## 3. Implementation facts: the critical boundaries

- `brewery_config.gd`: farm +7 wheat/shift (up to scenario daily harvest cap); mill uses 5 wheat to make 5 flour; bakery uses 5 flour to make 7 bread; brewery uses 3 wheat to make 6 ale. Prices: wheat 2, flour 5, bread 6, ale 4. Three farm, three mill, three bakery, two brewery job/equipment slots; labor wage 10 per guaranteed attended day.
- `brewery_policy.gd::plan`: bounded inventory-target planner. It requires strictly positive projected incremental receipts minus current applicable procurement and worker cost, and has a zero/nonpositive tie that retains cash. It is not a stochastic input-supply model.
- `binding_policy.gd::within`: reserves committed payroll *once*, and assigns `worker.wage=0` for an already-funded/committed worker when choosing their present production assignment. An already-paid employee working is different from entering an additional three-day contract.
- `binding_policy.gd::forecast`: projects three days using forecast output demand, own stocks, the known quote, fixed wage commitments, and a pure production plan; resets the farm cap in successive days and assumes procurement can occur when the plan requires it. It does **not** model a probability distribution over future rival-funded wheat requests, future stock availability, or endogenous bankrupt supply partners. Its contribution estimate may therefore be too optimistic despite an excellent demand signal.
- `binding_policy.gd::renewal`: maximizes the three-day planned contribution subject to its feasibility gate, leaving capacity unused on equal/not-profitable terms. Existing obligations and cash constraints are real; forecasts are predictions, not spendable money or contracts for input supply.
- `M26_DEMAND_FEASIBILITY.md`: demand estimation uses only seller-local witnessed/entrusted receipts and completed eligible same-price days. All owner knowledge boundaries and scenario isolation must remain unchanged.
- `M23_FEASIBILITY.md` independently established a day-one **funded physical witness** at full cap21; the test deliberately did not establish stable decentralized equilibrium. This prior success should seed and validate the new offline feasibility diagnostics.

**Important correction:** Because M25 made wages binding, it would be incorrect to infer that cap19/16 automatically limits *actual* harvest to 14 every day. For example, M26's day-one tight/requests run harvested 19 and scarce/requests harvested 16 while all initially contracted workers were present. A 14-unit threshold is informative for **prospective additional labor profitability**, not an unconditional simulation upper bound.

## 4. What the established research contributes

| Research/model | Relevant mechanism | Useful for us | Inappropriate shortcut |
|---|---|---|---|
| **Input-output economics** (Leontief; QuantEcon lesson) | Gross intermediate output needed for final demand; labor-resource requirements; primal/dual production bounds | Industry dependency matrix, immediate screening for aggregate impossibility, interpretable bottleneck/shadow-price diagnostics | A continuous one-period equilibrium is *not* proof of feasible indivisible lots, travel, cash, personal consumption or time sequence |
| **Multi-level capacitated lot sizing / integer programming** | Integer batches, inventory balance, shared scarce capacity, sequential production | Correct offline physical upper bounds for small day-scale scenarios; compare optimized feasibility to actual decisions | Never feed the omniscient optimal allocation to NPCs; do not begin with a 30-day all-constraints MILP |
| **Stock-flow consistent ABM** (Caiani et al.; sfctools/JMAB) | Financial stocks, obligations, cash flow through sectors, initialization consistency | Cash timelines, firm and owner distribution statements, wage payables/receivables, intra-town vs visitor-money movements | Current town has **cash and wage claims, but no banks/loans**; don't install a full banking framework or pretend it exists |
| **BAM Engine** | Separate planning, labor, production, goods, revenues, bankruptcies; integer headcount thresholds; calibrated stress testing | Compare decision-stage contracts and sources of forecast error, identify labor quantization and funding questions | Its basic goods production uses labor productivity rather than our physical wheat/flour/bread chain; its randomized heuristics/credit may conflict with our controlled baseline |
| **Mark-0** (Gualdi et al.) | Nonlinear employment/consumption feedback and regime shifts | Design robustness checks for apparently abrupt collapse; don't suppress real endogenous crises | Its abstract or aggregate consumers do not reproduce our individual household purchasing constraints |
| **Censored-demand inventory research** | Stockouts provide incomplete sales signals; stockout timing and genuine requests add information | Confirms M26's evidence/provenance principle and motivates future industry-specific learning | No invented latent 'true demand' or global unseen visitors in NPC beliefs |
| **Supply-chain coordination contracts** | Individually rational wholesale trades may fail to maximize network gains | Explain zero-profit supplier vs positive total downstream surplus; future optional price/contract experiments | Do not force benevolence, share profits automatically, or modify supplier objectives in the baseline |
| **ABM validation methodology** | Separate implementation verification, structural tests, sensitivity, and empirical validity | Preregister controlled interventions and vary initial endowments/contract maturities/seeds | Two byte-identical repeat runs prove determinism, not real-world calibration or general economic viability |

**Conclusion:** We do not need to port sfctools, BAM, JMAB, or Mark-0. Borrow **diagnostic mathematics and verification discipline**, not an incompatible macroeconomic architecture.

## 5. Diagnostic design: three progressively tighter questions

### Tier A — Physical feasibility (offline, no coins)

For one chosen day with frozen starting inventories, equipment, workers, routes and real product recipes, enumerate or solve for **integer** shifts and product deliveries. A conceptually simple formulation:

- Each farm worker shift yields an integer amount `0..7` wheat, bounded by the **actual** cap and existing labor availability. In a literal-authority witness use exactly the source's harvest action/eligibility rules, not an arbitrarily flexible partial harvest choice.
- Each mill shift uses 5 wheat and yields 5 flour; bakery 5 flour → 7 bread; brewery 3 wheat → 6 ale.
- Respect real ordering: farm harvest before grain clearing, mill before flour purchase, bakery/brewery before resident and visitor shopping. Do not consume flour/wheat/bread before they exist; maintain separately held business/agent stocks and actual transfer opportunities.
- Each named worker has at most one exclusive valid assignment per time window, can work only within contractual/skill/equipment/physical limitations of the chosen tier. **Distinguish a relaxed physical potential** (labor could hypothetically be reassigned/recontracted) from **today's legal physical potential** (only real active contracts).
- A witness must contain actual feasible integer shifts, commodity conservation and shop-time available units; a solver objective value without a feasible schedule is insufficient.
- Objective alternatives must be disclosed: maximum aggregate bread, maximum number of residents fed, minimum missed residents, or maximum *minimum* per-resident meals. Different objectives can favor different distributions. Keep visitor meals separate.

For a quick, deliberately relaxed **recipe-only** one-day bound with all three employees in each food industry: `15 wheat → 15 flour → 21 bread` is feasible in principle in all 21/19/16 harvest-cap settings. This is **not** a proven financed/legal/witnessed outcome for a given day and does not assume the full economy voluntarily realizes it.

### Tier B — Cash/contract feasibility (offline, no invented money)

Build on the physical witness by enforcing event-time cash, real transfers, actual posted prices, guaranteed wages for **attended** contracted workers (even if standby), actual three-day terms, immediate purchasing power, and lawful distributions. Useful invariants include:

`firm cash after event = firm cash before event + actual receipts − actual payments >= 0`.

`cash wage payments + outstanding wage claims = total earned wage claims`, with debtor and creditor sides equal and preserved across employment changes.

`sum(cash of all resident, firm, and external accounts) = 9,192` at every money movement.

Do **not** mistake cash-conserving circulation for every business being solvent. A positive aggregate margin says nothing about whether a particular firm can pay wages before it receives retail revenues. Distinguish a pure physical bound, a financially *fundable* plan with explicit transfers, and feasible individual incentives. Introducing an omniscient planner is allowed **only outside the world** as a diagnostic.

### Tier C — Decentralized incentives and information (observed simulation)

Compare the actual decisions against the preceding bounds without declaring it an error when a local owner refuses an unprofitable shift or a solvent buyer cannot find stock. Attribute the difference to:

1. **Raw resource bound** (field cap/stock insufficient).
2. **Discrete technique/labor constraint** (whole batches, slots, current terms, schedule).
3. **Input-market rationing** (funded requests accepted/rejected by actual clearing).
4. **Working-capital/timing constraint** (not enough own cash at the time of purchase or payroll).
5. **Forecast information/censoring** (known direct demand/inputs vs estimated future demand).
6. **Contract irreversibility and standby** (locked prospective wages vs usable shifts).
7. **Incentive misalignment** (firm's rational margin differs from integrated supply-chain margin).
8. **Purchasing-power/distribution** (specific household cash before food visit, who receives wages/distributions, visitors' purchases).

Multiple causes can overlap. Record an **evidence-backed primary blocking constraint** and optional secondary contributors; do not turn every missed meal into one falsely exclusive causal story.

## 6. Worked conditional production-chain wedge

At wheat quote 2, flour quote 5, bread quote 6, wage 10 and **new** full-shift payroll obligations:

| Added shift | Sale value | Purchased input | Wage | Margin |
|---|---:|---:|---:|---:|
| Farm, third shift yields 5 wheat | `5 × 2 = 10` | 0 | 10 | 0 |
| Mill, converts 5 wheat → 5 flour | `5 × 5 = 25` | `5 × 2 = 10` | 10 | +5 |
| Bakery, converts 5 flour → 7 bread | `7 × 6 = 42` | `5 × 5 = 25` | 10 | +7 |
| Combined chain, assuming output sells | 42 final retail | internal wheat/flour transfers cancel | 30 | +12 |

For a wheat price `p` in whole coins, farm marginal margin is `5p−10`, mill marginal margin is `25−5p−10 = 15−5p`. Both strictly positive requires `2 < p < 3`; **there is no whole-coin wheat price in that interval** given fixed flour price 5. This is a *conditional indivisibility/price-grid result*, not a prediction that all pricing reforms fail. Existing already-paid wages have zero additional cost when choosing **today's assignment**, changing the optimal shift execution decision.

One intuition: **A farm laborer can be worth employing to the production network without being worth employing to the farm at prevailing prices.** That is allowed emergent behavior; diagnose first and only later evaluate mechanisms such as more granular prices, supply commitments, alternative ownership or negotiated contracts as controlled interventions.

## 7. Recommended next implementation: M27 diagnostic-only

**Hypothesis:** The simulator's current outcomes can be more meaningfully explained by adding independent physical, finance-timing, and incentive diagnostics, without changing a single NPC policy or authoritative transaction.

**Proposed scope (minimal first phase)**

1. **Preflight evidence protocol:** Freeze classification definitions, the baseline source/branch/hash, one-day benchmark assumptions and proof witnesses **before observing new comparisons**. Reuse M23 feasibility witnesses and M26 reports as reference cases.
2. **Passive diagnostic ledger:** Reconstruct product flows per firm, inventory, cash event times, wage claims, B2B order fill rates, retail affordability at the actual shopping time and owner distributions using audited native events. The output is a read-only CSV/JSON attribution table, entirely outside NPC memory.
3. **One-day integer physical feasibility:** Independent Python verifier or tiny enumeration. Start with full 21-cap reference; then cap 19 and 16. Verify a witness with real batch sizes, assets, named workers, time windows and stock transfers; optionally produce a second relaxed potential bound with formally listed relaxed assumptions. Do **not** report a bound as a world-feasible outcome until a schedule/ownership witness exists.
4. **Financing overlay:** Validate pre-sale working capital, guaranteed wages and same-day purchase-time affordability, retaining every coin. Separate profitable-in-principle, actually financeable, and locally incentive-compatible.
5. **Compare against M26:** At minimum reference, tight and scarce (plus no-brew for negative control), sales/request policies, day 1 and day 3 checkpoints, with 30-day aggregation from existing auditable traces. Label when some native traces must be regenerated for the independent verifier. Inspect sensitivity to initial contract maturities as an external dimension; no retrospective attribution of all effects to demand forecasting.
6. **Acceptance gate:** No change to any M0–M26 canonical world/economic/event outputs; independently reconciled goods and money; exact integer arithmetic; no knowledge leakage into firm policy; fixtures for zero-stock/unfunded order/committed standby/no owner distribution; clear classification of 'provable', 'bounded', 'unobserved', and 'model-dependent'. No full multi-sector planner, AI personality, dynamic prices or wages, banks, debt, welfare intervention, settlement expansion or Rust port.

**Preferred deliverables:** `docs/M27_ECONOMIC_DIAGNOSTICS_FEASIBILITY.md` (frozen before outcome review), `docs/M27_RESULTS.md`, small `physical_witnesses.csv`, `cash_timelines.csv`, `constraints.csv` and `failure_attributions.csv`, with independent witness/audit scripts, negative-case tests and benchmark-versus-real outcomes. Conform to `docs/PERFORMANCE.md`: focused checks during edits, milestone-wide historical acceptance only at the final checkpoint. Keep the long M26 world run out of the edit/test loop unless source changes invalidate its traces.

### What *not* to implement in M27

Do **not** replace the three-day renewal solver with a global optimizer. Do not make firms altruistically maximize network profit. Do not introduce dynamic wages/prices or debt to rescue the brewery, do not force full employment/food access, and do not supply NPCs with an omniscient benchmark. A later M28 candidate could test **seller-local input availability beliefs / competing funded order history** against the unchanged three-day financial solver, but that should be selected only after diagnostics show which projected assumptions are failing.

## 8. Preregister a robustness program after diagnostics

M26 showed deterministic repeatability (same case, same seed), not statistical reliability. For later controlled work:

- Sweep independent scenario seeds **only when they actually alter stochastic schedule/visits/selection**; if all inputs are deterministic, different seeds may not constitute independent economic observations.
- Vary exogenous harvest caps across the interesting integer thresholds (including 14/15/16/18/19/20/21), *and* record where individual third-shift contribution crosses zero. Freeze values before viewing results; do not engineer favorable benchmarks.
- Test simultaneously and staggered three-day initial maturities as distinct legal starting endowments, not a post hoc 'improvement' caused by a policy.
- Vary starting working-capital allocation and visitor purchasing power as separately disclosed endowments while preserving total coins, rather than changing market policies and money simultaneously.
- Separate robustness of **survival, employment, bread output, resident meals, visitor meals, individual misses, firm margins, arrears, and final cash**; no single scalar success score should silently collapse these outcomes.

## 9. Research limitations and confidence

**Directly inspected/project-grounded:** M26 experimental summary and CSVs, M23 feasibility arithmetic and real source functions identified above. **Derived exact conditional arithmetic:** 5-wheat third labor shift, margins, price interval, one-day recipe-only supply chain. **Research-grounded analogies:** BAM's market/firm phases and quantized labor, Leontief IO, ABM-SFC sector accounting, Mark-0 tipping points, supply-chain contract coordination, inventory censoring. **Proposals only:** new mathematical benchmarks, causal attribution scheme, integer schedules, future input-probability learning. No new 30-day economy simulation, solver feasibility proof, economic calibration, or benchmark implementation was executed during R26.

### Primary sources and documentation

**Our town (inspected M26 branch):**

- [M26 findings](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/docs/M26_RESULTS.md) — outcomes, parity, checks and limitations.
- [M26 preregistration](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/docs/M26_DEMAND_FEASIBILITY.md) — seller evidence, censored requests and information boundaries.
- [M23 feasibility certificate](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/docs/M23_FEASIBILITY.md) — recipes, time windows, wholesale batches, day-one witness and funding.
- [Source: brewery policy](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/scripts/sim/brewery_policy.gd) and [binding policy](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/scripts/sim/binding_policy.gd) — authoritative pure calculation inputs.
- [Firm accounts](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/docs/M26_BUSINESSES.csv) and [individual outcomes](https://github.com/anoy-maker/simulated-town-rpg/blob/codex/m26-demand-observation/docs/M26_RESIDENTS.csv).

**External research:**

1. Sargent & Stachurski, [*Input-Output Models*](https://intro.quantecon.org/input_output.html). Equation, Leontief inverse, labor frontier, primal/dual LP.
2. [*Multi-level capacitated lot sizing under time-varying environments*](https://www.mdpi.com/1099-4300/21/4/377). Integer batch planning under capacities and inventory carryover.
3. Caiani et al. (2016), [*Agent based–stock flow consistent macroeconomics: Towards a benchmark model*](https://ideas.repec.org/a/eee/dyncon/v69y2016icp375-408.html). Micro/meso/macro balance-sheet and flow consistency.
4. Baldauf (2023), [*sfctools*](https://sfctools-framework.readthedocs.io/en/latest/). Reusable stock-flow-consistent ABM accounting structures.
5. [*BAM Engine: The BAM Model*](https://bam-engine.readthedocs.io/en/latest/user_guide/bam_model.html). Planning/labor/credit/production/goods flows and integer labor quantization.
6. Gualdi et al. (2015), [*Tipping points in macroeconomic agent-based models*](https://www.cfm.com/tipping-points-in-macroeconomic-agent-based-models/). Endogenous collapse and hiring/firing asymmetry.
7. [*Demand forecasting under lost sales stock policies*](https://ideas.repec.org/a/eee/intfor/v40y2024i3p1055-1068.html) (2024). Sales censoring and limitations of lost-sales estimation.
8. Cachon (2003), [*Supply Chain Coordination with Contracts*](https://econspace.net/teaching/MGT-528/Cachon-SC-Coordination-w-Contracts.pdf). Independent supplier-retailer incentives and coordination mechanisms.
9. Fagiolo et al., [*Validation of Agent-Based Models*](https://lem.sssup.it/WPLem/files/2017-23.pdf). Model verification, robustness and calibration.
10. [*Studying economic complexity with agent-based models: advances, challenges and future perspectives*](https://link.springer.com/article/10.1007/s11403-024-00428-w). Focus on real sector structure, feedbacks and methodological cautions.

**Sign-off:** R26 recommends **M27 diagnostics before changing business behavior**. No M27 implementation or GitHub issue was created as part of this research pass.