# M13 — Employment allocation versus production forecasting

## Predeclared experiment

This is a deterministic 2×2 diagnosis, not an economic repair. M11 (`settlement_equilibrium_reference`) and M12 (`settlement_employer_choice`) remain unchanged controls. New `settlement_fixed_owner_first` (M13-A) attempts the prescribed 8 wheat / 8 flour / 12 bread every day with M12's owner-first, stable-ID staffing. New `settlement_sales_rotating` (M13-B) uses M12's exact own-previous-calendar-day-sales forecasts and output-stock offsets with M11's exclusive odd/even worker pairs, in their existing order. No out-of-group substitute is allowed. Fewer needed shifts use only the eligible prefix of the designated group.

All four begin with the exact M11 twelve residents, ownership/employment/skills/assets, 6 coins per resident, 120 per firm, no commodities, 432 total coins, 2/4/4 prices, eight-coin productive shifts, four-wheat harvests and unchanged two-batch recipes (4 wheat → 4 flour; 4 flour → 6 bread). Each needs one bread/day and has at most one productive shift/day. Industry and household order, public offers, authority and employee acceptance stay unchanged. No withdrawals, transfers outside wages/purchases, debt, free food, guaranteed work or post-result tuning.

Architecture inspection permits a small extraction of M12's pure budgeting/whole-shift calculation, plus one runner policy hook. Default inputs/outputs remain identical. The original M11 pair selector supplies M13-B's group; the original owner-first sorter supplies M13-A. The existing world executes all real purchases, paid work and recipes. There is no new economic subsystem or policy access to private household finances. The reporter receives completed ledgers only.

**M13-A:** required new daily output is always 8/8/12, even if existing output exceeds that quantity. Output stock is recorded but never subtracted from the production target; weak sales never lower the target. The minimum whole shifts are two per firm, reduced only for qualified available workers/capacity, real input availability, or the joint cash cost of missing inputs plus wages. Actual owned *input* stock still reduces required input purchases. This is feasible attempted production, not permission to produce unpaid or on credit.

**M13-B:** day-one forecast is 8/8/12 once. Later forecasts are own realized output sales on the preceding day, including zero. Existing output stock offsets the forecast; only whole needed, funded shifts are chosen. No smoothing or output/employment floor. Candidate groups are farm Ada/Dain vs Edda/Gale; mill Bram/Hale vs Jory/Lyle; bakery Cora/Finn vs Iona/Kira. An ineligible/unavailable candidate is skipped without recruiting outside the group.

Predictions supplied in the task: owner-first staffing may exclude employees even under fixed output; accumulated stock may drain operating cash. Rotating income may let unchanged sales forecasts reproduce M11. These are hypotheses to compare with actual receipts, not acceptance criteria.

Run **all four at 2, 7, 30 and 365 days, seed 42**, twice per case. There is no new randomness; no additional seed matrix. Preserve all historical hashes, including M12. No verbose annual ledgers are exported. Full histories remain available in memory for audit; compact reports include their fingerprints.

Measurements are fixed before outcomes: all meals/misses, per-resident work/wages/cash, no-shift residents, owner/employee income, production/desired/feasible plans, sales/input/payroll spending, stocks/capital, actual circulation and cash concentration. First missed meal and first pre-food bakery stock below twelve are separate. Count missed meals on days with bread remaining unsold; this indicates coexistence, not that every miss could be served by the residual stock. Also record missed meals whose own food-turn observation has an available loaf but insufficient personal cash, and distinguish no public food at that turn.

For each firm's daily decision, compare its actual opening cash with the known full cost of desired shifts plus missing inputs at fixed prices, independently of public input availability. Report the first shortfall, whether it can fund even one desired shift, and input shortages separately. M11's prescribed decisions are projected by the observer; no new world events are inserted into that control. Sustained inactivity means seven consecutive complete days without successful production/work or purchase, matching M12. Show only the first eight daily aggregates and first eight firm plans in compact reports; retain aggregate reason/worker counts for the rest.

Household purchases remain one bread for that day's personal consumption. M11 historically submits direct purchases; M12 and the new treatments use the existing affordable-food policy, which waits instead of submitting an unaffordable/unavailable purchase. Failed purchases and waits change no economic state and have no fees. Comparisons of native economic movements and physical/account outcomes exclude such annotation/attempt differences; rejected-attempt counts must not be mistaken for different purchasing power.

## Actual results

### Findings and predictions versus observations

**Staffing alone creates food insecurity in this setup. Forecasting alone does not.** M13-B reproduces M11's complete successful economic movements at every tested horizon, with 4380 annual meals and zero misses. M13-A consumes 1182 meals, missing 3198; M12 consumes 1122, missing 3258. The owner-first hypothesis is supported, including accumulated inventory and capital constraints. The rotating/forecasting hypothesis is supported under the exact deterministic reference conditions; it does not establish general autonomous stability.

### Four-condition comparison

| Days | Condition | Meals / missed | Shifts | Owner / employee wages | Circulation | Coins: firms / owners / employees |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | M11 fixed/rotating | 24 / 0 | 12 | 24 / 72 | 288 | 360 / 18 / 54 |
| 2 | A fixed/owner-first | 18 / 6 | 12 | 48 / 48 | 264 | 336 / 42 / 54 |
| 2 | B sales/rotating | 24 / 0 | 12 | 24 / 72 | 288 | 360 / 18 / 54 |
| 2 | M12 sales/owner-first | 18 / 6 | 12 | 48 / 48 | 264 | 336 / 42 / 54 |
| 7 | M11 fixed/rotating | 84 / 0 | 42 | 96 / 240 | 1008 | 360 / 30 / 42 |
| 7 | A fixed/owner-first | 48 / 36 | 40 | 168 / 152 | 816 | 232 / 102 / 98 |
| 7 | B sales/rotating | 84 / 0 | 42 | 96 / 240 | 1008 | 360 / 30 / 42 |
| 7 | M12 sales/owner-first | 46 / 38 | 24 | 120 / 72 | 568 | 352 / 54 / 26 |
| 30 | M11 fixed/rotating | 360 / 0 | 180 | 360 / 1080 | 4320 | 360 / 18 / 54 |
| 30 | A fixed/owner-first | 160 / 200 | 119 | 640 / 312 | 2384 | 48 / 298 / 86 |
| 30 | B sales/rotating | 360 / 0 | 180 | 360 / 1080 | 4320 | 360 / 18 / 54 |
| 30 | M12 sales/owner-first | 117 / 243 | 61 | 416 / 72 | 1436 | 340 / 74 / 18 |
| 365 | M11 fixed/rotating | 4380 / 0 | 2190 | 4392 / 13128 | 52560 | 360 / 30 / 42 |
| 365 | A fixed/owner-first | 1182 / 3198 | 631 | 4736 / 312 | 14656 | 40 / 374 / 18 |
| 365 | B sales/rotating | 4380 / 0 | 2190 | 4392 / 13128 | 52560 | 360 / 30 / 42 |
| 365 | M12 sales/owner-first | 1122 / 3258 | 563 | 4432 / 72 | 13488 | 344 / 70 / 18 |

Each row has exactly 432 coins. Circulation counts actual payroll and input/food payments once, not new money, aggregate wealth or accounting profit. Desired new production, rounded feasible output and actual output, cash constraints, workers selected/skipped and reasons are in the business CSV and compact study reports. Individual wages, spending, shifts, meals, inventories and cash at **every horizon** are in the resident CSV.

All employment records remain active. Six residents receive zero shifts in A and M12 at every tested horizon; none do in M11/B. There are zero rejected purchases, rejected/unfunded work attempts or rejected employer plans in all sixteen cases: the policy reduces its proposal before an unaffordable transaction. Missing meals remain recorded consumption failures. The inherited `shifts.unavailable=0` is the original per-worker scheduling-wait counter, not an unemployment measure; use actual shifts and skipped candidates.

### Exact initial divergence

All four have identical successful native money/goods movements on day one. On **day two**, the first economic difference is the farm's eight-coin payroll: M11/B pay **Edda**, while A/M12 again pay **Ada**. This repeats the first six earners rather than reaching the other six residents. Those excluded residents hold two coins and cannot buy four-coin bread. A and M12 still produce twelve bread, miss six meals, and leave six bread unsold. Their entire successful economic traces remain identical through day two.

On **day three**, the first economic difference between A and M12 is the bakery's input purchase. A buys eight flour for 32 coins and makes twelve new bread, regardless of six existing loaves or six previous sales. M12 forecasts six sales, offsets six unsold bread, buys no flour and offers no bakery shifts. Its next successful economic event instead begins household food purchases. M11/B continue their matched twelve-meal daily path through day 365, with identical ordered native movement fingerprints, not merely equal totals.

| Day | A bread made / meals / shifts | A bread left | M12 bread made / meals / shifts | M12 bread left |
| --- | --- | --- | --- | --- |
| 1 | 12 / 12 / 6 | 0 | 12 / 12 / 6 | 0 |
| 2 | 12 / 6 / 6 | 6 | 12 / 6 / 6 | 6 |
| 3 | 12 / 6 / 6 | 12 | 0 / 6 / 4 | 0 |
| 4 | 12 / 6 / 6 | 18 | 6 / 6 / 3 | 0 |
| 5 | 12 / 6 / 6 | 24 | 6 / 6 / 1 | 0 |
| 6 | 6 / 6 / 5 | 24 | 6 / 5 / 2 | 1 |
| 7 | 6 / 6 / 5 | 24 | 6 / 5 / 2 | 2 |
| 8 | 6 / 6 / 5 | 24 | 6 / 4 / 3 | 4 |

M11/B make twelve bread, eat twelve meals and pay six shifts every day, with no unsold stock. In A, the bakery's opening cash on days 1–6 is **120, 120, 96, 72, 48, 24**. Full daily production costs **48** (32 inputs + 16 wages). On day six only one 24-coin shift/input bundle is affordable, so the target remains twelve but actual output falls to six. This is financial constraint, not a forecasting response or output-stock offset.

### Household access and employment

Annual participation and distribution:

| Resident | M11 = B shifts | A shifts | A meals / missed | A coins | M12 shifts | M12 meals / missed | M12 coins |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ada | 183 | 199 | 365 / 0 | 138 | 184 | 365 / 0 | 18 |
| Bram | 183 | 197 | 365 / 0 | 122 | 185 | 365 / 0 | 26 |
| Cora | 183 | 196 | 365 / 0 | 114 | 185 | 365 / 0 | 26 |
| Dain | 183 | 23 | 47 / 318 | 2 | 4 | 9 / 356 | 2 |
| Edda | 182 | 0 | 1 / 364 | 2 | 0 | 1 / 364 | 2 |
| Gale | 182 | 0 | 1 / 364 | 2 | 0 | 1 / 364 | 2 |
| Hale | 183 | 11 | 23 / 342 | 2 | 3 | 7 / 358 | 2 |
| Jory | 182 | 0 | 1 / 364 | 2 | 0 | 1 / 364 | 2 |
| Lyle | 182 | 0 | 1 / 364 | 2 | 0 | 1 / 364 | 2 |
| Finn | 183 | 5 | 11 / 354 | 2 | 2 | 5 / 360 | 2 |
| Iona | 182 | 0 | 1 / 364 | 2 | 0 | 1 / 364 | 2 |
| Kira | 182 | 0 | 1 / 364 | 2 | 0 | 1 / 364 | 2 |

Every M11/B resident eats 365 meals; their final coins are ten for the six odd-day workers and two for the six even-day workers. Every shift in every condition pays eight coins, so the shift counts also determine individual wages exactly; complete explicit wage and expenditure columns are in the CSV. All personal commodity inventories finish empty.

A pays **592 owner shifts / 39 employee shifts**, versus M12's **554 / 9**, and M11/B's **549 / 1641**. A's employees earn 312 coins and eat 87 meals, versus M12's 72 coins and 27 meals. Three selected employees work last on days **23 (Dain), 11 (Hale), 5 (Finn)** in A, versus 4/3/2 in M12. Edda, Gale, Jory, Lyle, Iona and Kira never work under either owner-first rule. All three owners eat daily in all conditions. These are eligibility records without guaranteed hours, not unemployment caused by employee absences, firing or lost skills.

The first missed meal is day two under both owner-first rules; neither rotating condition misses any. In A, **all 3198 annual missed meals occur when the household has an available public loaf but less than its price**, and bread remains unsold every such day. No household food turn finds zero bread. Bakery stock before household buying never falls below twelve, even though realized annual output is far below total annual needs. The observed failure is access to existing stock; do not infer that the recorded low output could support universal consumption without changing the ensuing trajectory.

M12 has **1636** unaffordable food turns with stock and **1622** food turns without public bread, summing to its 3258 misses. Of those misses, **1630** occur on days with bread left after all buying; the two diagnostics measure different moments. The first pre-food stock below twelve is day three. Thus forecasting changes the manifestation from accumulated available stock toward a mixture of financial exclusion and actual supply shortages. It does not initiate the day-two loss of purchasing power.

### Production, business finances and retained resources

Annual firm receipts (M11 and B are economically identical):

| Condition / firm | Sales revenue | Input spending | Payroll | Shifts | Output | Final coins | Final stock |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M11 = B / farm | 5840 | 0 | 5840 | 730 | 2920 wheat | 120 | None |
| M11 = B / mill | 11680 | 5840 | 5840 | 730 | 2920 flour | 120 | None |
| M11 = B / bakery | 17520 | 11680 | 5840 | 730 | 4380 bread | 120 | None |
| A / farm | 1664 | 0 | 1776 | 222 | 888 wheat | 8 | 56 wheat |
| A / mill | 3216 | 1664 | 1664 | 208 | 832 flour | 8 | 28 flour |
| A / bakery | 4728 | 3216 | 1608 | 201 | 1206 bread | 24 | 24 bread |
| M12 / farm | 1504 | 0 | 1504 | 188 | 752 wheat | 120 | None |
| M12 / mill | 2992 | 1504 | 1504 | 188 | 752 flour | 104 | 4 flour |
| M12 / bakery | 4488 | 2992 | 1496 | 187 | 1122 bread | 120 | None |

For A, desired new output remains **2920 wheat / 2920 flour / 4380 bread**; rounded feasible and actual output are **888 / 832 / 1206**. Each firm desires 730 shifts for the year, but completes only 222/208/201. Targets are never reduced because of weak sales or owned output. First cash constraints and annual plan counts are:

| A firm | Full desired plans financed | Financially constrained plans | First cannot fund full target | First cannot fund even one shift/input bundle | Public input-shortage plans |
| --- | --- | --- | --- | --- | --- |
| Farm | 23 | 342 | 24 | 27 | 0 |
| Mill | 11 | 354 | 12 | 14 | 0 |
| Bakery | 5 | 360 | 6 | 13 | 0 |

In M11/B all 365 daily full plans per firm are funded. In M12 no actual desired plan has a cash/input constraint; desired work shrinks with sales/stock instead. Its annual new-output deficits are 752 wheat, 752 flour and **584 bread**; minimum whole six-bread shifts round the last figure to 1122 actual bread. Feasible/actual quantities must be distinguished from unrounded deficits. M12's 181/180/180 zero-new-output plans for farm/mill/bakery are endogenous waits, not rejected transactions or unfunded work. All of these reporting fields use a firm's **own desired output** as denominator, not a universal twelve-person target.

A's retained resources reconcile exactly: **888 wheat − 832 milled = 56 wheat**; **832 flour − 804 baked = 28 flour**; **1206 bread − 1182 consumed = 24 bread**. M12 ends with four flour; M11/B end with no commodities. No food is discarded, gifted or created outside authorized production. Inventory has no decay in this experiment.

A's firms hold **40 coins (9.26%)**, owners **374 (86.57%)**, employees **18 (4.17%)** at year end. M12's corresponding amounts are **344 / 70 / 18**, versus M11/B's **360 / 30 / 42**. Fixed attempted output transfers initial operating cash into wages and unsold goods, then becomes funding-limited; no money disappears. Owners' personal cash is not automatically available as business capital. Financial distress here means inability to fund the stated target/bundle, not negative balances, debt or cessation of all trade.

No condition has a seven-day village-wide inactivity run or trailing inactivity run at the tested horizons. In A and M12 all three firms still trade on day 365; farm/bakery last produce on day 364 and mill on 365. Owner-supported activity continues alongside persistent employee exclusion. Do not describe this as complete economic collapse or universal viability.

### Matched contrasts and interaction

With meals consumed as outcome, compare owner-first minus rotating staffing under each production rule, and sales minus fixed production under each staffing rule:

| Days | Staffing effect under fixed (A − M11) | Staffing effect under sales (M12 − B) | Forecasting effect under rotating (B − M11) | Forecasting effect under owner-first (M12 − A) | Interaction |
| --- | --- | --- | --- | --- | --- |
| 2 | −6 | −6 | 0 | 0 | 0 |
| 7 | −36 | −38 | 0 | −2 | −2 |
| 30 | −200 | −243 | 0 | −43 | −43 |
| 365 | −3198 | −3258 | 0 | −60 | −60 |

Interaction is `(M12 − B) − (A − M11)` in meals consumed; negative values mean forecasting increases the food-access loss of owner-first staffing relative to the fixed-production comparison. Effects are not independently additive.

Staffing alone is sufficient to cause the initial insecurity: changing production alone under rotation produces **no** economic divergence over the tested year. Under concentrated staffing, forecasts/stock offsets preserve business capital and avoid cash-constrained plans, but reduce paid work sooner. Relative to fixed output, they eliminate **30 employee shifts / 240 employee wage coins / 60 employee meals**, plus 38 owner shifts, through day 365. All sixty lost meals belong to employees; owner consumption is unchanged. Continued fixed production is therefore not a cure: it buys modestly more employee participation through operating-capital drawdown, keeps six employees completely excluded, accumulates stock and leaves firms unable to finance their original targets.

These conclusions concern this deterministic own-last-sales/whole-shift/owner-first versus exact-rotation experiment. They do not establish general results about employers, markets, forecasting, distribution policies or all possible staffing rules.

### Technical verification and reproducibility

- Godot **4.6.3** full suite: **2754 checks, zero failures**, preserving all 2703 existing checks and adding 51 focused treatment/accounting/replay checks.
- Python standard-library discovery: **28 tests passed**, preserving all 22 existing tests and adding six M13 tests. The independent auditor checks prescribed targets versus stock-offset forecasts, exclusive group membership, prices/receipts, funded unique work and final state; corrupted treatment annotations are detected.
- All sixteen cases run twice in independent processes with byte-identical compact study output, complete canonical-ledger fingerprints and valid every-event 432-coin/nonnegative accounting. Full annual native ledgers are also checked in memory for real recipe/payroll sources, unique receipt claims and split-run replay in both treatments.
- All **96 historical pinned outputs** remain unchanged: 59 through M7, six M8, six M9, eighteen M10, four M11, and three additional M12 summaries (the M11 rows duplicated in M12's table are counted once). The new seven-day M11/M12 compact **and full-ledger** captures also equal a fresh run of parent commit `b666479` exactly. Historical result files and the M0 default remain unchanged.
- Native successful economic movement fingerprints for M13-B equal M11 at all four horizons. These exclude administrative events, rejected/no-op attempts and receipt IDs, but retain day, action, participants and every economic receipt detail. Full ledgers remain independently deterministic, and all payroll/production links are audited before this comparison.

Run from the repository root with the README's writable XDG setup:

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/run_causality.py --output work/m13
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_fixed_owner_first 365 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_sales_rotating 365 42 --study-json
```

`--study-json` adds reporting-only reconstructed diagnostics and original-summary/full-ledger fingerprints for these four scenarios. `--report-json` retains original control bytes; default human output is concise. Study artifacts are approximately **31–41 KB/year case** and contain no events. Full ledgers exist internally for verification; the short `--json` diagnostic remains available. [16 run rows](M13_RUNS.csv), [192 resident rows](M13_RESIDENTS.csv) and [48 firm rows](M13_BUSINESSES.csv) report every condition/horizon, hashes, circulation, cash/stock, shifts, food access and plan constraints. Firm `purchases` means coins spent on inputs; `purchases_successful` counts transactions. Null/blank dates mean no observed occurrence.

Changed implementation: small shared planning extraction and runner hook in the employer files, plus `causality_policy.gd`, `causality_runner.gd`, `causality_report.gd`, experiment driver, CLI selection and focused tests/auditor extensions. World balance/inventory mutation, M11 scheduling and legacy recipes/eligibility remain unchanged. New decision reasons accurately label prescribed inputs or rotating selection. A plan still consists of individually atomic existing commands, with real partial execution preserved if a later command fails; no new atomic aggregate or rollback is introduced.

### Remaining uncertainties and limits

The rules and five policy/runner/dispatch implementation files were fixed before the first treatment run and remained unchanged after outcomes. Later changes concern diagnostic checks, tests, tables and documentation only. No result-driven tuning or new economic behavior occurred. There are no final test failures or unverified required simulations.

Rotation is intentionally prescribed; B demonstrates that **this exact rotation** supports the unchanged deterministic forecast from this initialization, not that autonomous employment discovers it. Forecasts observe paid sales rather than needs. Day-one reference expectations, exact parameters, fixed ordering, one-day memory, whole shifts, passive acceptance, no food spoilage and no hunger effects on labor capacity remain material assumptions. No perturbation, alternative initial state, pricing, forecast window, random weather or labor-market response is tested. Personal versus business cash remains separate; owners cannot silently recapitalize firms or transfer meals to employees. No rescue, fair staffing policy, new economic subsystem or M14 is implemented. Stop after M13 for review.
