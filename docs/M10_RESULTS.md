# M10 — Business Income and Capital Circulation

## Predeclared experiment, before finance outcomes

Use the unchanged M9 twelve residents, three sole-owned businesses, nine employment records, 432 initial coins, skills, inventories, prices (wheat/flour/bread 1/2/3), three-coin shifts, one shift/person/day, assets, targets, supplier selection, and seeded farm opportunities. M9 remains a historical scenario. No employment guarantee, subsidy, forced production, household pooling, or redistribution to employees is introduced.

Fix these **three** policies before simulations; no post-result tuning:

| Policy | Household goal | Maximum proposed payout |
| --- | --- | --- |
| `none` | Original M9 behavior | No withdrawal phase/events; exact M9 economic ledger control |
| `needs` | Own stock plus cash for two meals | Smaller of personal cash shortfall and all cash above the operating reserve |
| `half-surplus` | Same two-meal goal | Smaller of the same shortfall and half the cash above reserve, rounded down |

The personal cash shortfall is `max(0, max(0, 2 − own bread) × 3 − personal coins)`. One proposal per business/day follows all production and precedes food purchases; business order remains farm → mill → bakery. A funded shift's wage already received that day reduces the shortfall. An owner need not work to be eligible for a withdrawal. Policies use only their own household and authorized business observations. Both payout policies have identical information and capabilities. No price, wage, target, capacity, recipe, initial capital, or allocation changes.

The authoritative reserve is **two full-capacity operating days**, computed without valuing or deducting already-owned inputs. One day's budget is workplace slots × (highest authorized compensation per shift + recipe input cash per shift at fixed prices). Using the highest owner/active-employee wage is conservative for differing compensation; initial wages are all three. Four slots and the unchanged two-batch shifts give:

| Business | Daily payroll buffer | Daily input cash | Two-day reserve | Initial funds | Initial cash above reserve |
| --- | --- | --- | --- | --- | --- |
| farm | 12 | 0 | **24** | 120 | 96 |
| mill | 12 | 16 | **56** | 120 | 64 |
| bakery | 12 | 32 | **88** | 120 | 32 |

`distributable_cash = max(0, actual business coins − reserve)`. A withdrawal cannot leave less than that reserve. Ordinary wages/input purchases may spend the retained operating buffer; this is not escrow or a restriction on business operations. A finite buffer cannot ensure long-term solvency or sales. The authority enforces ownership, existing cash, integer amounts/capacity, and the reserve; household need/fraction are policy choices, not transaction eligibility rules. Funds remain separate until a validated transaction transfers them.

These are **cash withdrawals, not formal profit distributions**. Starting capital can be withdrawn above reserve; receipts are not all distributable and unsold inventory is not spendable cash. No inventory valuation, accrual profit, debt, capital injection, or automatic operating-fund refill is modeled. Initial operating capacity and physical food feasibility are exactly M9's; only ownership income may change realized behavior.

Run 30 and 365 days, seeds **7, 42, 99**, for all three policies, with independent-process replay and full ledger audit. Reuse hash-verified M9 captures for matched comparisons, verify the `none` control's complete events/report projection against M9, and require identical underlying opportunities across policies. Report individual food access and employee participation as well as aggregate meals and circulation. Reserves and policies remain fixed even if outcomes are poor.

## Actual results and assessment

**Ownership income restores sustained economic activity in all sampled runs, but does not create a viable twelve-person economy.** Both withdrawal policies keep real trade active through day 365, improve production/employment, and support 812–813 annual meals versus M9's 77–82. Only Cora eats all 365 meals. Most employees remain almost completely excluded; Ada and Bram still miss many meals. The village still misses over 81% of its 4380 annual meals. Technical correctness and increased circulation are not broad household viability.

[18 run summaries](M10_RUNS.csv), [216 resident records](M10_RESIDENTS.csv), and [54 business records](M10_BUSINESSES.csv) include all policies, horizons and seeds. The tables preserve full JSON hashes, matched-environment hashes, source M9 hashes, cash flows, separate wage/ownership income, inventories, work/production, meals and inactivity. Full JSON ledgers are workspace artifacts. No initial condition, reserve, goal, fraction, market, wage, recipe or production policy was tuned after outcomes.

## Matched control and aggregate comparison

The `none` control has exactly the original M9 events, including initialization, opportunities and every decision; its inherited report equals M9 after removing only the new finance projection and scenario label. All six source M9 captures were checked against committed SHA-256 hashes, audited and reused. Both payout policies use exactly the same full daily opportunities as that control, including opportunities skipped by production policies.

| Seed | Days | None meals eaten / missed | Needs meals eaten / missed | Half-surplus meals eaten / missed | Paid shifts none / needs / half | Circulation none / needs / half |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 82 / 278 | 135 / 225 | 135 / 225 | 46 / 69 / 69 | 496 / 919 / 919 |
| 7 | 365 | 82 / 4298 | 813 / 3567 | 812 / 3568 | 46 / 413 / 412 | 496 / 6347 / 6341 |
| 42 | 30 | 77 / 283 | 133 / 227 | 133 / 227 | 41 / 66 / 66 | 454 / 903 / 903 |
| 42 | 365 | 77 / 4303 | 813 / 3567 | 812 / 3568 | 41 / 405 / 408 | 454 / 6347 / 6331 |
| 99 | 30 | 77 / 283 | 133 / 227 | 133 / 227 | 41 / 68 / 68 | 454 / 907 / 907 |
| 99 | 365 | 77 / 4303 | 813 / 3567 | 812 / 3568 | 41 / 407 / 399 | 454 / 6346 / 6341 |

At 30 days both withdrawal policies reach 135/133/133 meals (seeds 7/42/99), leaving **225/227/227 of 360 needs unmet**. At 365 days `needs` reaches 813 in all seeds (**3567 unmet**); `half-surplus` reaches 812 (**3568 unmet**). Relative to control, the annual gains are 731/736/736 meals for `needs` and 730/735/735 for `half-surplus`. The slight aggregate difference between the fractions is not evidence of a universally superior policy; it changes some individual access and labor timing.

Circulation includes each actual purchase, payroll payment and owner withdrawal once. An ownership withdrawal followed by a purchase is two real cash movements, not two counts of one receipt. Even excluding the new withdrawal leg, annual `needs` circulation is 5250/5226/5232 versus control 496/454/454. The observed gain therefore includes additional ordinary purchases and wages. The money supply remains exactly **432** in every case and at every reconstructed event; repeated payout totals above 432 are reuse of existing coins.

## Actual production and accepted withdrawals

Physical capacity remains M9's: four potential shifts/industry/day, 16 flour/day mill capacity, 24 bread/day bake capacity, and initial 16 wheat / 12 flour / 18 bread. Annual farm opportunities are 5774/5846/5951 wheat. Finance creates no goods or labor. Production below is real harvest/recipe output, and every productive receipt links to exactly one funded shift.

| Seed | Days | Policy | Harvest / opportunity wheat | Flour produced | Bread produced | Wages paid | Payout transactions / coins |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | none | 61 / 451 | 60 | 84 | 138 | 0 / 0 |
| 7 | 30 | needs | 88 / 451 | 92 | 132 | 207 | 33 / 99 |
| 7 | 30 | half-surplus | 88 / 451 | 92 | 132 | 207 | 33 / 99 |
| 7 | 365 | none | 61 / 5774 | 60 | 84 | 138 | 0 / 0 |
| 7 | 365 | needs | 546 / 5774 | 544 | 816 | 1239 | 454 / 1097 |
| 7 | 365 | half-surplus | 544 / 5774 | 544 | 816 | 1236 | 466 / 1097 |
| 42 | 30 | none | 57 / 475 | 56 | 78 | 123 | 0 / 0 |
| 42 | 30 | needs | 91 / 475 | 88 | 132 | 198 | 34 / 102 |
| 42 | 30 | half-surplus | 91 / 475 | 88 | 132 | 198 | 34 / 102 |
| 42 | 365 | none | 57 / 5846 | 56 | 78 | 123 | 0 / 0 |
| 42 | 365 | needs | 548 / 5846 | 544 | 816 | 1215 | 462 / 1121 |
| 42 | 365 | half-surplus | 548 / 5846 | 544 | 810 | 1224 | 460 / 1107 |
| 99 | 30 | none | 59 / 479 | 56 | 78 | 123 | 0 / 0 |
| 99 | 30 | needs | 92 / 479 | 92 | 132 | 204 | 32 / 96 |
| 99 | 30 | half-surplus | 92 / 479 | 92 | 132 | 204 | 32 / 96 |
| 99 | 365 | none | 59 / 5951 | 56 | 78 | 123 | 0 / 0 |
| 99 | 365 | needs | 545 / 5951 | 544 | 816 | 1221 | 458 / 1114 |
| 99 | 365 | half-surplus | 545 / 5951 | 544 | 816 | 1197 | 485 / 1136 |

All 18 cases have **zero rejected withdrawals, zero rejected purchases, zero rejected work acceptances, and zero unfunded shifts**. Failed/unauthorized/stale withdrawals are covered by focused tests, not artificially injected into these fresh-observation runs. Every skipped candidate shift in the experiments is recorded as `output_target_met`; production is never forced just to provide wages. Actual bread remains below a tenth of the annual baking-capacity bound despite hunger and positive buffers.

Every accepted payout in these experiments occurs on a day the recipient supplies **no shift**. Finance follows all work, so the `without_shift` counter is unambiguous here. For seed 42, the first payout is **day 10, event 958**: Bram withdraws three coins from the mill, leaving 121 above its 56 reserve. It is a distinct ownership receipt; it neither creates a work shift nor counts as wages. Cora later receives 693/696 coins of annual ownership income independently of work compensation, depending on the case.

## Businesses: cash flow, capital, and real activity

The annual table includes all three matched policies. Inventories are wheat/flour/bread. New output is the business's own commodity; shifts include its owner and employees. Monthly values and each firm's last production/business days are in the full CSVs. `capital = 120 + sales − input purchases − wages − withdrawals`; this is cash reconciliation, not inventory-valued profit.

| Seed | Policy | Firm | Sales | Input cash | Wages | Withdrawals | Final capital | W / F / B | New output | Shifts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | none | farm | 52 | 0 | 51 | 0 | 121 | 17 / 0 / 0 | 61 | 17 |
| 7 | none | mill | 96 | 52 | 45 | 0 | 119 | 0 / 16 / 0 | 60 | 15 |
| 7 | none | bakery | 210 | 96 | 42 | 0 | 192 | 0 / 0 / 20 | 84 | 14 |
| 7 | needs | farm | 536 | 0 | 423 | 212 | 21 | 18 / 0 / 0 | 546 | 141 |
| 7 | needs | mill | 1072 | 536 | 408 | 192 | 56 | 0 / 12 / 0 | 544 | 136 |
| 7 | needs | bakery | 2403 | 1072 | 408 | 693 | 350 | 0 / 0 / 21 | 816 | 136 |
| 7 | half-surplus | farm | 536 | 0 | 420 | 214 | 22 | 16 / 0 / 0 | 544 | 140 |
| 7 | half-surplus | mill | 1072 | 536 | 408 | 190 | 58 | 0 / 12 / 0 | 544 | 136 |
| 7 | half-surplus | bakery | 2400 | 1072 | 408 | 693 | 347 | 0 / 0 / 22 | 816 | 136 |
| 42 | none | farm | 48 | 0 | 42 | 0 | 126 | 17 / 0 / 0 | 57 | 14 |
| 42 | none | mill | 88 | 48 | 42 | 0 | 118 | 0 / 16 / 0 | 56 | 14 |
| 42 | none | bakery | 195 | 88 | 39 | 0 | 188 | 0 / 0 / 19 | 78 | 13 |
| 42 | needs | farm | 536 | 0 | 399 | 236 | 21 | 20 / 0 / 0 | 548 | 133 |
| 42 | needs | mill | 1072 | 536 | 408 | 192 | 56 | 0 / 12 / 0 | 544 | 136 |
| 42 | needs | bakery | 2403 | 1072 | 408 | 693 | 350 | 0 / 0 / 21 | 816 | 136 |
| 42 | half-surplus | farm | 536 | 0 | 411 | 222 | 23 | 20 / 0 / 0 | 548 | 137 |
| 42 | half-surplus | mill | 1064 | 536 | 408 | 189 | 51 | 0 / 16 / 0 | 544 | 136 |
| 42 | half-surplus | bakery | 2400 | 1064 | 405 | 696 | 355 | 0 / 0 / 16 | 810 | 135 |
| 99 | none | farm | 48 | 0 | 42 | 0 | 126 | 19 / 0 / 0 | 59 | 14 |
| 99 | none | mill | 88 | 48 | 42 | 0 | 118 | 0 / 16 / 0 | 56 | 14 |
| 99 | none | bakery | 195 | 88 | 39 | 0 | 188 | 0 / 0 / 19 | 78 | 13 |
| 99 | needs | farm | 536 | 0 | 405 | 229 | 22 | 17 / 0 / 0 | 545 | 135 |
| 99 | needs | mill | 1072 | 536 | 408 | 192 | 56 | 0 / 12 / 0 | 544 | 136 |
| 99 | needs | bakery | 2403 | 1072 | 408 | 693 | 350 | 0 / 0 / 21 | 816 | 136 |
| 99 | half-surplus | farm | 536 | 0 | 381 | 253 | 22 | 17 / 0 / 0 | 545 | 127 |
| 99 | half-surplus | mill | 1072 | 536 | 408 | 190 | 58 | 0 / 12 / 0 | 544 | 136 |
| 99 | half-surplus | bakery | 2400 | 1072 | 408 | 693 | 347 | 0 / 0 / 22 | 816 | 136 |

For example, `needs`, seed 7: farm `120 + 536 − 423 − 212 = 21`; mill `120 + 1072 − 536 − 408 − 192 = 56`; bakery `120 + 2403 − 1072 − 408 − 693 = 350`. The mill withdraws 192 against operating net cash receipts of 128, using 64 of starting capital. This is allowed above reserve and demonstrates why the command must not be described as paying only accounting profit. Inventory and initial buffers are not valued as profit or minted into cash.

The no-withdrawal control's last village activity is day 15/13/14. In every active finance case there is real production or trade on **all 339 days after day 26**, including day 365. This prevents the historical village-wide stall; the intervention starts before that stall in its own trajectory, rather than waiting for a central rescue. Individual inactivity remains severe. The original production/trade inactivity metric deliberately does not count a cash withdrawal itself as renewed business output.

At seed 42 day 26, real farm work includes Ada and Dain (work receipts **2327**, **2334**, harvesting 3 and 5 wheat). Cora buys four flour (**2354**) and bakes six bread (**2359**); Bram withdraws three ownership coins without a shift (**2372**). Ada, Bram, Cora and Dain then each purchase bread (**2375/2377/2379/2381**). This is extra labor, inputs, production and consumption, not only a transfer among account labels.

## Operating-capital safeguards

Every accepted withdrawal retains its recomputed reserve. Below, the first vector is minimum cash immediately after any accepted payout, in farm/mill/bakery order. The second is minimum cash over **all** operations (initial cash, payroll, inputs, sales and payouts), independently reconstructed from receipts.

| Seed | Policy | Min immediately after payout (floor 24 / 56 / 88) | Min over all business operations | Final capital |
| --- | --- | --- | --- | --- |
| 7 | needs | 24 / 56 / 182 | 17 / 49 / 114 | 21 / 56 / 350 |
| 7 | half-surplus | 25 / 58 / 182 | 17 / 51 / 114 | 22 / 58 / 347 |
| 42 | needs | 24 / 56 / 178 | 16 / 49 / 114 | 21 / 56 / 350 |
| 42 | half-surplus | 25 / 58 / 178 | 18 / 51 / 114 | 23 / 51 / 355 |
| 99 | needs | 24 / 56 / 178 | 18 / 49 / 114 | 22 / 56 / 350 |
| 99 | half-surplus | 25 / 58 / 178 | 19 / 51 / 114 | 22 / 58 / 347 |

Ordinary operations intentionally spend the retained buffer: the farm can finish with 21–23 coins, and the mill can finish at 51, below their payout thresholds. These are not withdrawal breaches. There are no observed payroll/input-funding failures, and all firms remain able to pay a three-coin shift. The safeguards prevent payouts from consuming the predefined buffer; they do not promise it stays untouched or prove two days is sufficient under other horizons, shocks, or initial conditions. The farm/mill floor also limits their owners' food-income proposals. The baker retains much larger surplus because its owner's household goal, not all available company cash, limits withdrawals.

## Residents, employees, and concentration

| Seed | Policy | Meals: 3 owners | Meals: 9 employees | Owner shifts | Employee shifts | Employee wages |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | none | 38 | 44 | 29 | 17 | 51 |
| 7 | needs | 751 | 62 | 378 | 35 | 105 |
| 7 | half-surplus | 750 | 62 | 377 | 35 | 105 |
| 42 | none | 36 | 41 | 27 | 14 | 42 |
| 42 | needs | 756 | 57 | 375 | 30 | 90 |
| 42 | half-surplus | 750 | 62 | 373 | 35 | 105 |
| 99 | none | 36 | 41 | 27 | 14 | 42 |
| 99 | needs | 756 | 57 | 377 | 30 | 90 |
| 99 | half-surplus | 760 | 52 | 374 | 25 | 75 |

Under `needs`, employee meals improve by only **18/16/16** over M9 while owners gain **713/720/720**. Only Dain improves: 27/23/23 meals versus 9/7/7 in control; `half-surplus` gives him 27/28/18. Every other employee's annual meals stay at the matched M9 value. Iona, Kira and Lyle never work; Gale also never works in seeds 42/99. Other employees' last work remains day 1–6, except Dain. Common owner-first scheduling and output targets leave few residual employee shifts. No free food, wage guarantee or ownership income is given to employees.

The following full individual example is **seed 42, 365 days, `needs`**. All personal inventories finish at zero wheat/flour/bread. Consumption expenditure is actual bread purchases. Complete records for every policy/seed/horizon are in the 216-row resident CSV.

| Resident | Wages | Ownership cash | Food spending | Eaten | Missed | Final coins |
| --- | --- | --- | --- | --- | --- | --- |
| Ada | 336 | 236 | 576 | 193 | 172 | 2 |
| Bram | 393 | 192 | 591 | 198 | 167 | 0 |
| Cora | 396 | 693 | 1092 | 365 | 0 | 3 |
| Dain | 60 | 0 | 66 | 23 | 342 | 0 |
| Edda | 3 | 0 | 9 | 4 | 361 | 0 |
| Finn | 12 | 0 | 18 | 7 | 358 | 0 |
| Gale | 0 | 0 | 6 | 3 | 362 | 0 |
| Hale | 12 | 0 | 18 | 7 | 358 | 0 |
| Iona | 0 | 0 | 6 | 3 | 362 | 0 |
| Jory | 3 | 0 | 9 | 4 | 361 | 0 |
| Kira | 0 | 0 | 6 | 3 | 362 | 0 |
| Lyle | 0 | 0 | 6 | 3 | 362 | 0 |

Cora eats all 365 meals in every payout case. Ada eats 188/193/193 (`needs`) or 188/188/198 (`half-surplus`); Bram eats 198/198/198 or 197/197/197. Thus even two owners remain intermittently unable to afford food. In all payout cases the other eight employees eat only 3–7 meals all year. Without deaths/health mechanics they remain present with explicit unmet needs.

At the annual horizon the three firms hold 427/427/428 coins under `needs`, or 427/429/427 under `half-surplus`; the remaining 3–5 coins are personal owner cash. All employee cash is zero. The bakery holds 350 coins under `needs` and 347/355/347 under `half-surplus`, about 80–82% of the entire currency supply. Cash concentration in that firm increases despite improved owner access and circulation. No inventory-valued net-worth/equity comparison is claimed.

The fractions differ by only one aggregate annual meal per seed, but not by identical individual outcomes. For seed 42 half-surplus gives Dain five more meals than `needs` while Ada gets five fewer and Bram one fewer. For seed 99 the employee gain is smaller under half-surplus. These are deterministic consequences of different payout timing/rounding and the same environmental opportunities, not adjusted resources or better information. A handful of matched seeds is not a robust welfare ranking.

## Technical verification, scope, and remaining limits

Base: M9 commit `58268d0`; runtime **Godot 4.6.3**. Pre-change suite: **2572 checks, zero failures**. Final full suite: **2615 checks, zero failures**, preserving all existing coverage and adding 43 focused checks. All **16 Python tests** pass (ten existing plus six finance audit/control/tampering tests). The new checks cover ownership/actor binding, unknown accounts, zero/negative/noninteger/NaN/infinite/overflow amounts, available funds, reserve/recipient limits, exact-limit transfers, stale budgets, retained capital spent on real work, privacy/pure proposals, distinct wage classification, control equivalence and deterministic split replay.

All **71 historical JSON outputs** are byte-identical: 23 through M6B, 36 M7, six M8 and six M9. The shared table projection also regenerates the three original M9 CSVs byte-for-byte from verified captures. All 18 M10 cases match independent-process replays byte-for-byte and pass full state/receipt reconstruction. For each matched seed/horizon all policies have the same environmental history and initial state; all six controls match the entire M9 ledger and normalized report. Every business/household reconciles money, sources/sinks, production, wages, ownership cash, purchases and meals. Every post-withdrawal reserve check uses independently recomputed amounts, not trusted event claims. There is no receipt reuse or fabricated labor.

Finance configuration SHA-256: `7386215826e51b2bb6195af25531bdb263e7754d5b3f989c5e89ccc572f1b658`; policy SHA-256: `021dcf1ff6ba706de96857e90b560839b46a5aae9ffd054f64e4b1ebaf7ccf48`. Both remain unchanged from before the fixed matrix, as do M9 configuration/policy hashes. Headless editor import, readable 30/365-day seed-42 finance commands, and `git diff --check` pass. Corrupt cached M9 bytes are rejected before simulation; invalid/cross-scenario distribution flags exit 2. These expected negative checks are not unexpected failures. No unexpected test, simulation, audit, replay or import failure occurred.

Actual commands use the same writable XDG setup as README:

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py' -v
python3 -B scripts/tools/run_labor.py --study m10 --baseline /workspace/work/m9 --output /workspace/work/m10
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_finance --distribution needs 365 42
godot --headless --editor --path . --import
git diff --check
```

Full captures: `/workspace/work/m10/settlement_finance-{policy}-{seed}-{days}.json`, with the six verified M9 source captures copied under an `m9-` prefix. The original M9 capture directory is not overwritten. Run/resident/business CSVs are copied unchanged to the committed tables. The fresh-M9 fallback matrix without `--baseline` was not separately run; historical M9 commands were independently reproduced for all six hashes. Cross-version RNG replay, more seeds, shocks, longer horizons, alternative reserves/household goals, changed schedules, and formal accounting profit remain unverified. No default economy is adopted as viable.

Annual histories contain 27,263–31,288 events and 9.15–10.42 MB of formatted JSON. In-memory history, deep-copy reports and two replay payloads remain scaling limitations; no large historical data system is added.

Changes are limited to four small finance config/policy/world/runner scripts and their UIDs; a default-empty pre-food hook in M9's runner; scenario/option selection in the CLI; conditional finance audit/study/CSV extensions in the existing labor tool; focused Godot/Python tests; README/architecture/roadmap and these result tables. The original kernel, M9 world/occupation policies/endowments, and all historical result documents/tables are unchanged. Authority permits any safe owner withdrawal above reserve; the conservative fraction and household cap remain voluntary decision rules. There is no bank, credit, debt, new industry, employment promise, household pooling, forced output, player, graphics or LLM integration.

M10 demonstrates technically valid ownership income and sustained but highly unequal economic circulation. It does not establish settlement-wide economic viability. Stop after M10 for review; no M11 has begun.
