# M8 — Candidate Viable Economic Baseline

## Fixed experiment, before new outcomes

This study compares the M7 original baseline (bread 3, harvest opportunities 2–6), affordable bread (`lower_food_price`: bread 2, opportunities 2–6), higher productivity (bread 3, opportunities 4–8), and the **combined candidate** (bread 2, opportunities 4–8). Only the combined configuration is new. Verified M7 captures supply the other three comparisons, checked against committed SHA-256 hashes and re-audited before reuse.

All other conditions are fixed: Ada farmer; Bram/Edda millers; Cora/Finn bakers; Dain laborer; 115 initial coins distributed 30/20/20/20/20/5 in that order; one initial bread each; wheat/flour prices 1/2; daily Ada → Dain payment 2 attempted before sales; farmer target 4; flour target 4; bread target 6; food target 1; max two recipe batches/turn; commitment-first; unchanged role/ID schedule, public observations, agreement rules, and authoritative commands. No default is changed or adopted. No post-result tuning is permitted.

The new combined case runs **30 and 365 days for seeds 7, 42, and 99**, twice independently. The four-way comparison shares each seed/horizon's underlying daily draws; only productive cases add two. The six original M7 presets and their matrix remain intact. A small preset addition and study option reuse the existing calibration runner, CLI, ledger auditor, and CSV projections. No new policy or runner is needed.

Feasibility improves on two dimensions: a paid two-coin wage can buy two-coin bread, while mean potential six wheat can supply nine bread/day against six needs (three surplus, before policy/finance/timing). Millers can process eight wheat/day and bakers eight flour/day under their unchanged action limits. This does not imply all opportunities are harvested, that surplus goods can be sold to six one-meal/day customers, that wages are actually paid, or that individuals retain food until eating. Gross processing margins remain those of the affordable-bread case, not the original three-coin bread economy.

Assessment will consider physical utilization, household meal access, individual business continuity, wage/payment performance, circulation, distribution, and consistency across the three seeds. An aggregate meal increase alone is insufficient to establish a viable default. Resilience beyond the specified seeds/horizons is untested.

The new observation-only diagnostic reconstructs bread holdings before the food proposal's command, tracks later same-day successful bread sales, and links any subsequent failed consumption. It records actor/day and event IDs for inspection. It never reserves goods, changes a proposal, or modifies a ledger. It is computed for reused M7 captures and new cases alike.

## Actual results and assessment

**The combination is a strong 30-day result, but is not supported as a viable year-long provisional baseline.** All six NPCs eat every day and Ada pays every wage in the first 30 days, across all three seeds. By day 365 the candidate misses 873/882/855 meals (seeds 7/42/99), Edda and Finn have stopped producing, and Dain has lost most wage payments. Its annual aggregate meals exceed original baseline and productivity alone, but are below affordable bread alone in every seed. No defaults were adopted and no settings/policies were tuned after these outcomes.

[All 24 run summaries](M8_RUNS.csv) include physical bounds, trades, agreements, wages, circulation, wealth, incident counts, environment/output hashes, and source provenance. [All 144 NPC records](M8_NPCS.csv) include inventories, meals, cumulative money earned/spent, trade/production, supplier choices, commitments, and inactivity. [All 135 observed food-loss chains](M8_FOOD_LOSSES.csv) contain case/day/actor and receipt IDs. The three M7 configurations are reused data, not new implementations; their full JSON bytes and source hashes are preserved.

## Matched meals: all four configurations

Each case needs 180 meals at 30 days or 2190 at 365. Cells show **eaten / missed**; the two delta columns compare the combined case with each isolated intervention. A higher number of meals does not imply every NPC or business fares better.

| Seed | Days | Original | Affordable bread | Productivity | Combined | Combined − affordable | Combined − productivity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 144 / 36 | 150 / 30 | 153 / 27 | 180 / 0 | +30 | +27 |
| 7 | 365 | 1243 / 947 | 1665 / 525 | 1130 / 1060 | 1317 / 873 | -348 | +187 |
| 42 | 30 | 149 / 31 | 164 / 16 | 151 / 29 | 180 / 0 | +16 | +29 |
| 42 | 365 | 1107 / 1083 | 1404 / 786 | 1085 / 1105 | 1308 / 882 | -96 | +223 |
| 99 | 30 | 137 / 43 | 141 / 39 | 153 / 27 | 180 / 0 | +39 | +27 |
| 99 | 365 | 1089 / 1101 | 1839 / 351 | 1130 / 1060 | 1335 / 855 | -504 | +205 |

At 30 days, combined adds 30/16/39 meals over affordable bread and 27/29/27 over productivity. All NPCs get 30 meals; this is not an aggregate gain obtained by withholding some first-month meals from another actor. But that improvement does not persist: annual combined is **348/96/504 meals worse than affordable bread alone**, while 187/223/205 better than productivity alone. The initial result therefore cannot establish resilience. All whole-village business-inactive-day counts remain zero, even as individual access collapses.

## Potential versus actual production

The higher-productivity and combined cases share identical physical bounds and underlying draws; affordable bread and original baseline share the lower bounds. Physical bounds ignore finance, choices, and distribution, and assume the unchanged two-batch/processor-turn limits. Six initial bread are included only in timely-meal bounds, not new-bread bounds. The full four-way production comparison is:

| Seed | Days | Configuration | Harvested / opportunity wheat | Flour made | Bread made / physical upper bound |
| --- | --- | --- | --- | --- | --- |
| 7 | 30 | baseline | 99 / 102 | 96 | 144 / 153 |
| 7 | 30 | lower_food_price | 99 / 102 | 96 | 144 / 153 |
| 7 | 30 | higher_productivity | 109 / 162 | 108 | 159 / 243 |
| 7 | 30 | combined_candidate | 124 / 162 | 120 | 180 / 243 |
| 7 | 365 | baseline | 832 / 1456 | 830 | 1242 / 2184 |
| 7 | 365 | lower_food_price | 1110 / 1456 | 1108 | 1659 / 2184 |
| 7 | 365 | higher_productivity | 759 / 2186 | 754 | 1128 / 3279 |
| 7 | 365 | combined_candidate | 887 / 2186 | 882 | 1314 / 3279 |
| 42 | 30 | baseline | 102 / 122 | 98 | 147 / 183 |
| 42 | 30 | lower_food_price | 110 / 122 | 106 | 159 / 183 |
| 42 | 30 | higher_productivity | 110 / 182 | 106 | 156 / 273 |
| 42 | 30 | combined_candidate | 127 / 182 | 124 | 180 / 273 |
| 42 | 365 | baseline | 743 / 1470 | 738 | 1104 / 2205 |
| 42 | 365 | lower_food_price | 940 / 1470 | 938 | 1401 / 2205 |
| 42 | 365 | higher_productivity | 726 / 2200 | 724 | 1083 / 3300 |
| 42 | 365 | combined_candidate | 881 / 2200 | 876 | 1305 / 3300 |
| 99 | 30 | baseline | 93 / 119 | 92 | 138 / 177 |
| 99 | 30 | lower_food_price | 91 / 119 | 90 | 135 / 177 |
| 99 | 30 | higher_productivity | 110 / 179 | 108 | 159 / 267 |
| 99 | 30 | combined_candidate | 121 / 179 | 120 | 180 / 267 |
| 99 | 365 | baseline | 731 / 1482 | 726 | 1086 / 2223 |
| 99 | 365 | lower_food_price | 1229 / 1482 | 1224 | 1833 / 2223 |
| 99 | 365 | higher_productivity | 759 / 2212 | 754 | 1128 / 3318 |
| 99 | 365 | combined_candidate | 899 / 2212 | 894 | 1332 / 3318 |

The combined annual physical bread bounds are 3279/3300/3318 and the time-respecting pooled-meal bound is 2190 for every seed. Actual bread is only 1314/1305/1332, about 40% of that production bound. The extra theoretical grain is not created when Ada waits, and more potential bread does not become actual stock or sales automatically.

In combined years, Ada harvests on 147/147/150 of 365 days. She waits on the ordinary four-wheat target on 204/209/197 days, and on already-owned commitment stock on 14/9/18. The unchanged policy responds to inventory depletion, not projected six-person demand, and allows a larger harvest to overshoot its target. This limits opportunity utilization, but does not show that forcing additional harvests would find funded buyers. No such alternative policy was tested.

## Per-NPC access, currency, and flows

At day 30 every combined NPC has eaten 30 and missed zero. Final money in Ada/Bram/Edda/Cora/Finn/Dain order is **36/28/12/16/16/7** (seed 7), **36/32/8/16/16/7** (42), and **36/36/4/16/16/7** (99), always summing to 115. Both bakers hold three bread; neither additional producer has yet stopped business. Detailed first-month production/inventories/flows are in the NPC table.

The combined annual per-character results show why the initial success is insufficient. Inventory columns are wheat/flour/bread. Earned/spent include spot trades, prepayments and wages exactly once; each row reconciles `final = initial + earned − spent`. Delivery does not charge again.

| Seed | NPC | Eaten / missed | Coins | W / F / B | Earned / spent | Food-cash-affordable days | Trailing business-idle days |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | Ada | 365 / 0 | 0 | 5 / 0 / 0 | 882 / 912 | 365 | 0 |
| 7 | Bram | 365 / 0 | 82 | 0 / 3 / 0 | 1586 / 1524 | 365 | 0 |
| 7 | Edda | 52 / 313 | 0 | 0 / 2 / 0 | 168 / 188 | 52 | 306 |
| 7 | Cora | 365 / 0 | 32 | 0 / 0 / 3 | 1504 / 1492 | 365 | 0 |
| 7 | Finn | 75 / 290 | 0 | 0 / 1 / 0 | 242 / 262 | 70 | 294 |
| 7 | Dain | 95 / 270 | 1 | 0 / 0 / 0 | 184 / 188 | 95 | 269 |
| 42 | Ada | 365 / 0 | 0 | 5 / 0 / 0 | 876 / 906 | 365 | 0 |
| 42 | Bram | 365 / 0 | 82 | 0 / 3 / 0 | 1586 / 1524 | 365 | 0 |
| 42 | Edda | 49 / 316 | 0 | 0 / 2 / 0 | 156 / 176 | 49 | 312 |
| 42 | Cora | 365 / 0 | 32 | 0 / 0 / 3 | 1504 / 1492 | 365 | 0 |
| 42 | Finn | 72 / 293 | 0 | 0 / 1 / 0 | 230 / 250 | 67 | 297 |
| 42 | Dain | 92 / 273 | 1 | 0 / 0 / 0 | 178 / 182 | 92 | 272 |
| 99 | Ada | 365 / 0 | 0 | 5 / 0 / 0 | 894 / 924 | 365 | 0 |
| 99 | Bram | 365 / 0 | 82 | 0 / 3 / 0 | 1586 / 1524 | 365 | 0 |
| 99 | Edda | 58 / 307 | 0 | 0 / 2 / 0 | 192 / 212 | 58 | 300 |
| 99 | Cora | 365 / 0 | 32 | 0 / 0 / 3 | 1504 / 1492 | 365 | 0 |
| 99 | Finn | 81 / 284 | 0 | 0 / 1 / 0 | 266 / 286 | 76 | 288 |
| 99 | Dain | 101 / 264 | 1 | 0 / 0 / 0 | 196 / 200 | 101 | 263 |

Ada, Bram, and Cora each eat all 365 meals in every combined seed. Edda eats only 52/49/58, Finn 75/72/81, and Dain 95/92/101. Thus three well-fed participants coexist with three severely underserved participants. No health/death state removes their unmet needs.

Annual currency distribution and gross circulation for every comparison follow. Circulation counts real repeated uses of the same 115 coins, including prepayments once. Shares are truncated integer basis points displayed as percent.

| Seed | Configuration | Coins Ada / Bram / Edda / Cora / Finn / Dain | Largest holder ID | Largest share | Gross circulation |
| --- | --- | --- | --- | --- | --- |
| 7 | baseline | 2 / 1 / 0 / 110 / 0 / 2 | baker | 95.65% | 4606 |
| 7 | lower_food_price | 0 / 2 / 0 / 112 / 0 / 1 | baker | 97.39% | 6062 |
| 7 | higher_productivity | 2 / 4 / 0 / 107 / 1 / 1 | baker | 93.04% | 4252 |
| 7 | combined_candidate | 0 / 82 / 0 / 32 / 0 / 1 | miller | 71.30% | 4566 |
| 42 | baseline | 0 / 3 / 0 / 109 / 1 / 2 | baker | 94.78% | 4172 |
| 42 | lower_food_price | 0 / 26 / 0 / 88 / 0 / 1 | baker | 76.52% | 4990 |
| 42 | higher_productivity | 2 / 4 / 0 / 107 / 1 / 1 | baker | 93.04% | 4102 |
| 42 | combined_candidate | 0 / 82 / 0 / 32 / 0 / 1 | miller | 71.30% | 4530 |
| 99 | baseline | 0 / 3 / 0 / 110 / 0 / 2 | baker | 95.65% | 4112 |
| 99 | lower_food_price | 0 / 2 / 0 / 112 / 0 / 1 | baker | 97.39% | 6750 |
| 99 | higher_productivity | 2 / 4 / 0 / 107 / 1 / 1 | baker | 93.04% | 4252 |
| 99 | combined_candidate | 0 / 82 / 0 / 32 / 0 / 1 | miller | 71.30% | 4638 |

The candidate ends with exactly **0/82/0/32/0/1** coins in every seed. Bram holds 71.30% and Bram+Cora hold 114/115 coins (99.13%). A lower single-holder share than M7's baker concentration is not sufficient evidence of broad access. Circulation is 4566/4530/4638, compared with affordable bread's 6062/4990/6750. Those annual results have less circulation and fewer meals than the affordable-only match despite more potential agricultural output.

## Wages, agreements, and business continuity

Nominal wage coverage is two-thirds of bread at price 3, or one bread at price 2. Affordability depends on actually receiving the wage and finding stock. The combined case completes all 30 first-month payments, transferring 60 coins, then performs poorly over the year. Table entries below show successful / failed wage attempts, Dain's meals, agreement accepted / fulfilled / outstanding, and each second producer's last production day.

| Seed | Configuration | Wages paid / failed | Dain meals | Agreements accepted / fulfilled / outstanding | Edda last production | Finn last production |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | baseline | 195 / 170 | 132 | 414 / 414 / 0 | 304 | 303 |
| 7 | lower_food_price | 223 / 142 | 226 | 656 / 655 / 1 | 290 | 288 |
| 7 | higher_productivity | 205 / 160 | 139 | 307 / 306 / 1 | 232 | 231 |
| 7 | combined_candidate | 92 / 273 | 95 | 53 / 53 / 0 | 58 | 69 |
| 42 | baseline | 204 / 161 | 138 | 373 / 372 / 1 | 225 | 224 |
| 42 | lower_food_price | 132 / 233 | 135 | 324 / 324 / 0 | 165 | 165 |
| 42 | higher_productivity | 205 / 160 | 139 | 290 / 289 / 1 | 207 | 206 |
| 42 | combined_candidate | 89 / 276 | 92 | 42 / 42 / 0 | 52 | 66 |
| 99 | baseline | 204 / 161 | 138 | 365 / 364 / 1 | 221 | 221 |
| 99 | lower_food_price | 277 / 88 | 280 | 710 / 709 / 1 | 346 | 344 |
| 99 | higher_productivity | 205 / 160 | 139 | 312 / 311 / 1 | 232 | 231 |
| 99 | combined_candidate | 98 / 267 | 101 | 61 / 61 / 0 | 64 | 75 |

At day 30 the combined agreements are 27/26/1 (seed 7), 17/17/0 (42), and 27/26/1 (99). The year ends with every combined agreement fulfilled and no open/outstanding/closed/waived record. Most are wheat advances to Ada; each seed also has one two-flour delivery to Finn from Bram. All agreements settling is compatible with prolonged business exclusion and does not prove viability. No failed purchase or lifecycle operation occurs in these default comparison runs; failed wages and missed meals are still explicit failures. Audits apply each underlying payment/delivery receipt once.

Edda's combined last production is day 58/52/64; Finn's is 69/66/75. Their trailing business inactivity reaches 306/312/300 and 294/297/288 days. These are earlier stalls than either single-intervention match, not brief end-of-horizon pauses. Edda holds two unsold flour and no cash; Finn holds one flour and no cash, insufficient for a two-flour batch. They have no active requests at the year horizon. The inherited minimum-batch underfunding flag misses Edda because she still owns theoretically sellable output; it is not a complete stall classifier. The last-day/idle data must be considered too.

The trace on day 300 illustrates the unchanged mechanisms in all three combined seeds. Cora chooses Bram's flour offer (five stock) over Edda's (two stock), at the same price. Edda's input decision waits with `unaffordable_with_priorities` and zero own cash. Cora buys two flour from Bram for four coins; Bram buys two wheat from Ada for two; Ada and Bram each buy one bread from Cora for two. Cora's batch produces three bread, feeding those three active NPCs. Available wheat and Edda's unsold flour do not imply a funded production opportunity for the excluded producers, and actors cannot inspect hidden finances or force another buyer to choose them.

Ada's attempted wage occurs before those sales and fails. Her later two-coin wheat receipt funds her own two-coin bread, without making an earlier unpaid wage happen retroactively. The last successful combined wage is day 96/93/102; Dain's last food purchase is on that same day. There are no partial payments, arrears, or rescue transfers. This supports a scheduling/working-capital explanation for observed payment failures, not a claim that the nominal wage is below the bread price. No payment-timing or supplier-selection change was implemented to test a remedy.

## Food owned at planning, then sold before the meal

The observer takes actual bread holdings **before** the food proposal's command. It requires at least one owned bread, a later successful same-day bread sale, and then a failed same-day consumption for insufficient stock. Food bought by the proposal was not owned at the planning snapshot. Cases with another post-planning bread transfer are excluded to avoid attributing a mixed cause to sales. This is a conservative diagnostic over the standard one-food-turn/one-meal schedule, not a policy rule or a reservation. Sales that leave enough food, failed sales, and later-day meals do not count.

Counts below show incidents, not distinct NPCs. Annual counts include their first 30 days, so the two horizons should not be added as disjoint episodes.

| Seed | Days | Original | Affordable bread | Productivity | Combined |
| --- | --- | --- | --- | --- | --- |
| 7 | 30 | 0 | 2 | 0 | 0 |
| 7 | 365 | 0 | 47 | 0 | 0 |
| 42 | 30 | 2 | 1 | 0 | 0 |
| 42 | 365 | 2 | 29 | 0 | 0 |
| 99 | 30 | 3 | 0 | 0 | 0 |
| 99 | 365 | 3 | 46 | 0 | 0 |

All 135 exported chains involve Cora or Finn. For example, affordable-only seed 7, day 53 links Cora's planning event **3394**, Dain's subsequent bread purchase **3396**, and Cora's failed consumption **3404**. The observer identifies 38 Cora and nine Finn incidents in that annual run. The mixed-cause exclusion does not remove any incident implied by the actual owned-food/meal counts in these cases; an independent comparison against those counts agrees.

There are **zero combined incidents** at both horizons for all seeds. Cora always owns and eats her food, and Finn's later missed meals follow having no bread at the food turn. Thus the candidate's annual hunger does not stem from this particular late-sale failure. Conversely, eliminating the observed incident count is not enough to establish equitable food access. No food reservation or behavioral fix was added.

## Provisional-baseline assessment

- **Physical capacity:** favorable on paper, with a positive buffer and potential for every timely meal in the sampled environments. Realized harvest/bread use remains far below that capacity.
- **Household affordability:** a paid wage buys food and the first month funds everyone, but actual wages collapse and half the population misses most annual meals. Nominal affordability is not reliable access.
- **Business continuity:** fails for Edda and Finn in every annual run, while the village retains a smaller active chain. All agreements being fulfilled and zero whole-village idle days are insufficient criteria.
- **Distribution:** early currency and food access look reasonable; the year converges to 114 coins held by two NPCs and severe access inequality. The annual improvement over original/productivity aggregates does not justify ignoring individual harm. Compared with affordable-only, the candidate loses annual aggregate meals in all seeds.
- **Resilience:** the same failure pattern appears in all three predefined seeds without needing an external shock. Three seeds and a one-year horizon are not broad resilience testing, and the strong 30-day result is contradicted by the longer runs.

**Retain this as an experimental candidate, not an adopted viable default.** It is useful evidence that removing two feasibility obstacles does not overcome unchanged allocation, working-capital, output-target, and scheduling limitations. The milestone succeeds as a reproducible experiment with an unfavorable longer-horizon assessment. No parameter search or corrective policy experiment was performed; any future change requires separate review.

## Verification, changes, and limitations

Base: M7 commit `98c4ef8`. Runtime: **Godot 4.6.3**. Pre-change full suite: **2504 checks, zero failures**. Final full suite: **2513 checks, zero failures**, adding only nine focused combined-configuration/replay/accounting checks. All **six focused Python observer tests** pass. They exercise purity and linked incidents, sufficient remaining food, failed sales, food acquired by a proposal, mixed/non-sale outflows, and day boundaries. No test matrix or economic implementation was duplicated for the new millers/bakers.

All **59 historical JSON outputs** were reproduced byte-for-byte after the change: 23 through M6B plus all 36 M7 calibration captures. The 18 M7 captures used by this comparison were separately checked against committed `M7_RUNS.csv` hashes, re-audited, and reused for analysis. Historical regression checks are verification, not additional tuned interventions. All six newly simulated combined captures matched independent-process replays; all 24 comparison ledgers passed the existing accounting/receipt/report audits and matched their underlying environmental hashes. Every comparison conserves exactly 115 coins.

An independent check validated every incident's actor/day, planning/sale/consumption order and event type, failed-meal reason, quantities, and same-day receipt links, and reconciled counts with authoritative owned-food/meal diagnostics. Both readable combined CLI commands (30/365, seed 42) show all six NPCs. A deliberately corrupted reuse file was rejected before simulation. Headless editor import and `git diff --check` passed; final test/import logs contain no script errors. No unexpected test, simulation, audit, or import failure occurred. No economic behavior was changed in response to results.

Actual commands used the same writable XDG setup documented in README:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_calibration_observations.py'
python3 -B scripts/tools/run_calibration.py --study m8 --reuse /workspace/work/m7 --output /workspace/work/m8
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario calibration --experiment combined_candidate 365 42
godot --headless --editor --path . --import
git diff --check
```

Workspace captures are `/workspace/work/m8/{experiment}-{seed}-{days}.json`, with the three reused configurations copied byte-for-byte from M7 after hash validation. Independent repeat bytes for the combined case were compared in memory. Output `runs.csv`, `npcs.csv`, and `food_losses.csv` supply the three committed M8 tables, including full-output and environment hashes. The batch tool can run all four configurations without `--reuse` on a fresh workspace; that redundant full fresh matrix was not separately executed here. Cross-version replay, longer horizons, other seeds, other scheduling/initial conditions, and shocks remain unverified. No future recovery is assumed from this finite observation.

Files changed: the optional preset and available-name API in `calibration_config.gd`; CLI name validation in `run_simulation.gd`; M8 reuse/study/observer support in the existing `run_calibration.py`; nine focused checks in `calibration_tests.gd` and six Python tests; README/architecture/roadmap; this report and three compact CSV tables. The calibration runner/world/report, all NPC policies, accounting kernel, recipes, scheduling, wages, original targets, prior presets/defaults, and historical result files are unchanged. Observation results never enter NPC decisions.

Stop after M8 for review. The combined configuration is not adopted. M9 has not started.
