# M9 — Workplaces, Labor, and Employment

## Predeclared configuration (before settlement experiments)

This is a new `settlement_labor` scenario, not adoption of M8 or a modification of a historical economy. Twelve residents own personal accounts and one initial bread plus six coins each. Three separately accounted businesses are sole-owned by Ada, Bram, and Cora. Business stock and operating funds belong to the business; households cannot eat or spend them directly. There are no dividends, automatic capital transfers, loans, or rescue payments. Owners receive the same three-coin compensation as employees only when they actually work a funded shift.

| Business | Industry / owner | Employees (occupation; authorized skill) | Starting funds | Starting wheat / flour / bread | Output target | Assets / daily capacity |
| --- | --- | --- | --- | --- | --- | --- |
| farm | farming / Ada (farmer) | Dain (laborer; farmer), Edda (farmer; farmer), Gale (laborer; farmer) | 120 | 8 / 0 / 0 | 16 wheat | Four field slots; one 2–6 wheat harvest per worker shift |
| mill | milling / Bram (miller) | Hale (miller; miller), Jory (laborer; miller), Lyle (miller; miller) | 120 | 8 / 4 / 0 | 16 flour | Four mill slots; two existing recipe batches per shift (4 wheat → 4 flour) |
| bakery | baking / Cora (baker) | Finn (baker; baker), Iona (baker; baker), Kira (laborer; baker) | 120 | 0 / 8 / 6 | 18 bread | Four oven slots; two existing recipe batches per shift (4 flour → 6 bread) |

All residents have one full-shift/day labor capacity. Occupation, skills, ownership, and explicit employment are separate facts: laborers with the required skill can be employed in an industry; ownership alone does not confer skill or extra labor. Owners may work their own business under the same capacity, wage, and input constraints. Employee wage records are fixed at three coins/full shift. One employer per employee initially; no recruitment, dismissal, negotiation, or debt mechanics. Exactly 12 residents and three business accounts, **432 initial coins** (72 household + 360 business), 16 wheat, 12 flour, and 18 bread across all accounts.

Fixed prices remain wheat 1, flour 2, bread 3. This scenario deliberately uses the original prices, not M8's unadopted candidate. A paid shift buys one meal. A farming shift has mean gross value 4 against wage 3 (a low-yield shift can lose money); milling gross revenue 8 minus inputs 4 and wage 3 leaves 1; baking gross revenue 18 minus inputs 8 and wage 3 leaves 7. These are conditional unit margins, not guaranteed daily sales. Each firm's 120 coins covers four wages plus a full four-shift day's inputs (farm 12, mill 28, bakery 44 total) without relying on same-day revenue. Personal six-coin balances cover two purchased meals, in addition to each initial bread.

**Physical feasibility:** four farming shifts supply 8–24 wheat/day (mean 16); four milling shifts process 16 wheat/day into 16 flour; four baking shifts process 16 flour into 24 bread. At the minimum daily farm opportunity, 8 wheat can become 12 bread, matching 12 daily needs; at mean opportunity, capacity is 24 bread/day, a positive buffer of 12 before policy, payroll, markets, and timing. The initial wheat/flour provide additional real buffers. This is a potential bound with all labor supplied, not an agent outcome or a claim that 24 bread will find paying buyers. Output targets, skipped shifts, and cash distribution may prevent realization.

The deterministic schedule is farming → milling → baking; each owner is considered first, then that firm's employee IDs ascending. Before each candidate shift, the owner can buy at most the inputs for one two-batch shift, retaining three coins for its compensation. Owners propose offers only below the firm's output target with enough inputs and wage funds. An independently evaluated worker proposal accepts an eligible offered shift; world authority rechecks employment/ownership, skill, daily capacity, workplace capacity, wages, stock, and output bounds. A successful acceptance pays the worker and performs production together; failed acceptance changes neither resources, funds, nor labor. Offers reserve neither money nor stock and expire at the next day. No unpaid hired work is performed. A decision to skip a candidate is explicitly recorded with the limiting reason.

All twelve residents then choose food using only personal stock, personal money, and public business offers, followed by one meal attempt each. Food order is resident ID ascending; no owner has free access to business bread. Supplier selection is fixed price ascending, stock descending, business ID ascending. All trade uses the existing atomic purchase command. Each day draws four independent 2–6 farm opportunities in worker-ID order, even if shifts are skipped; policies do not see a favorable draw in advance. The owner and worker policies use no other household's private finances.

Experiments are fixed at 30 and 365 days, seeds 7, 42, and 99, with independent process replay and ledger reconstruction. No parameter/policy tuning after settlement outcomes. Report potential capacity separately from actual labor, production, payroll, business cash flow, and individual food access. No commercial supply-request policy is added to the labor experiment; prior agreement scenarios remain intact.

## Actual results

**Paid labor, production, ownership, and payroll accounting work, but this economy reaches complete economic inactivity in every seed by day 13–15.** No population member remains fed throughout even the first month. The year adds no meals, work, or trade after the initial short-run activity. All 432 coins end in business accounts, with 19–20 bread still in the bakery. No parameters or policies were changed to remedy this outcome.

[Six run summaries](M9_RUNS.csv), [72 resident records](M9_RESIDENTS.csv), and [18 business records](M9_BUSINESSES.csv) are committed, including full JSON hashes, cash flows, wages, individual meals/purchases, work participation, production, skipped-shift reasons, and final holdings. Full event histories remain workspace artifacts. The configuration file stayed at SHA-256 `1f8da8bea990f864f9386ab8493050f4c98a46741bd7081636384eb9346acc4e` throughout the experiments.

## Potential, labor supplied, and realized food

The horizon bread bound includes initial grain/flour/bread, limits milling to 16 flour/day and baking to 24 bread/day, and pools stock over the horizon. It is not a time-respecting household-access calculation. Each day offers twelve potential full shifts and twelve meal needs; realized paid shifts are actual labor, not offered employment positions.

| Seed | Days | Worked / available shifts | Harvest / opportunity wheat | Flour made | Bread made | Pooled bread bound incl. initial | Meals eaten / missed | Total compensation | Gross circulation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 46 / 360 | 61 / 451 | 60 | 84 | 735 | 82 / 278 | 138 | 496 |
| 7 | 365 | 46 / 4380 | 61 / 5774 | 60 | 84 | 8721 | 82 / 4298 | 138 | 496 |
| 42 | 30 | 41 / 360 | 57 / 475 | 56 | 78 | 738 | 77 / 283 | 123 | 454 |
| 42 | 365 | 41 / 4380 | 57 / 5846 | 56 | 78 | 8778 | 77 / 4303 | 123 | 454 |
| 99 | 30 | 41 / 360 | 59 / 479 | 56 | 78 | 738 | 77 / 283 | 123 | 454 |
| 99 | 365 | 41 / 4380 | 59 / 5951 | 56 | 78 | 8778 | 77 / 4303 | 123 | 454 |

All six runs have **zero rejected purchases, zero rejected shift acceptances, and zero unfunded scheduled shifts**. Owner schedule waits total 314/319/319 at 30 days and 4334/4339/4339 at 365 (seeds 7/42/99); every reason is `output_target_met`. These are explicit unavailable work opportunities, not accepted unpaid work or rejected purchases. Owners checked output targets before considering payroll. The absence of unfunded shifts does not imply workers received daily wages.

Seed 7 has 46 paid shifts: farm 17, mill 15, bakery 14. Seeds 42/99 have 41: farm 14, mill 14, bakery 13. Each mill shift produces exactly four flour and each bakery shift exactly six bread, with native recipe inputs. The four daily farm draws still occur for all 365 days even after harvesting stops. Added opportunity alone does not produce wheat or restart work.

For a concrete accepted shift, seed 42 day 1: Ada's offer to Dain is event **12**. Native payment **14** moves three actual coins from farm to Dain; harvest **15** adds five wheat to the farm's account; work event **16** links both receipts and consumes Dain's one daily labor unit. Dain retains occupation `laborer` while using his authorized farmer skill. Neither the owner policy nor the worker policy directly changes these holdings.

## Employment, personal earnings, and meals

Nine residents are employed by business records and three are working owners. Actual participants are nine of twelve (six of nine employees) in seed 7 and eight of twelve (five of nine employees) in seeds 42/99. Iona, Kira, and Lyle never receive a shift in any seed; Gale additionally receives none in 42/99. Employment remains active despite no work; there is no dismissal or guaranteed-hours mechanism.

The following annual values use seed order **7 / 42 / 99**. Every resident ends with zero coins and zero inventory. Their 30-day work, wages, purchases, and eaten meals are already the same as these annual values; only missed meals increase with time. Purchases are money spent on personal bread. Owners receive no extra distribution of firm cash.

| Resident | Position | Shifts | Wages | Food purchases (coins) | Meals eaten | Meals missed (365d) |
| --- | --- | --- | --- | --- | --- | --- |
| Ada | owner | 9 / 9 / 9 | 27 / 27 / 27 | 33 / 33 / 33 | 12 / 12 / 12 | 353 / 353 / 353 |
| Bram | owner | 10 / 9 / 9 | 30 / 27 / 27 | 36 / 33 / 33 | 13 / 12 / 12 | 352 / 353 / 353 |
| Cora | owner | 10 / 9 / 9 | 30 / 27 / 27 | 36 / 33 / 33 | 13 / 12 / 12 | 352 / 353 / 353 |
| Dain | employee | 6 / 4 / 4 | 18 / 12 / 12 | 24 / 18 / 18 | 9 / 7 / 7 | 356 / 358 / 358 |
| Edda | employee | 1 / 1 / 1 | 3 / 3 / 3 | 9 / 9 / 9 | 4 / 4 / 4 | 361 / 361 / 361 |
| Finn | employee | 4 / 4 / 4 | 12 / 12 / 12 | 18 / 18 / 18 | 7 / 7 / 7 | 358 / 358 / 358 |
| Gale | employee | 1 / 0 / 0 | 3 / 0 / 0 | 9 / 6 / 6 | 4 / 3 / 3 | 361 / 362 / 362 |
| Hale | employee | 4 / 4 / 4 | 12 / 12 / 12 | 18 / 18 / 18 | 7 / 7 / 7 | 358 / 358 / 358 |
| Iona | employee | 0 / 0 / 0 | 0 / 0 / 0 | 6 / 6 / 6 | 3 / 3 / 3 | 362 / 362 / 362 |
| Jory | employee | 1 / 1 / 1 | 3 / 3 / 3 | 9 / 9 / 9 | 4 / 4 / 4 | 361 / 361 / 361 |
| Kira | employee | 0 / 0 / 0 | 0 / 0 / 0 | 6 / 6 / 6 | 3 / 3 / 3 | 362 / 362 / 362 |
| Lyle | employee | 0 / 0 / 0 | 0 / 0 / 0 | 6 / 6 / 6 | 3 / 3 / 3 | 362 / 362 / 362 |

Owners get 29/27/27 of the 46/41/41 shifts: 87/81/81 coins of compensation, and 38/36/36 meals across three people. The nine employees share 17/14/14 shifts, 51/42/42 wage coins, and 44/41/41 meals. Owners therefore have better early personal access under the declared owner-first ordering, but every owner also becomes hungry. Ownership of a cash-rich business is separate from spendable personal cash. These are effects under this initial allocation/order; no rotation, owner-last, dividend, or alternative-wage counterfactual was tested.

There is an exact household reconciliation: each person eats their one initial bread plus two meals funded by their six initial coins plus one meal for every three-coin paid shift. Thus total meals are `12 × 3 + paid_shifts` = 82/77/77. All personal spending is through purchases; business food is never taken for free. The bakery still has actual bread after all households lose purchasing power.

## Business cash flow, production, and remaining assets

The table applies to both horizons; money and inventory are already unchanged by day 30. Stocks are wheat/flour/bread. Net cash change is revenue minus actual input purchases and payroll, not an inventory-valued profit measure. Working owners are included in payroll.

| Seed | Business | Revenue | Input costs | Payroll | Net cash Δ | Final capital | W / F / B | Last production day | Last business day |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | farm | 52 | 0 | 51 | 1 | 121 | 17 / 0 / 0 | 13 | 15 |
| 7 | mill | 96 | 52 | 45 | -1 | 119 | 0 / 16 / 0 | 15 | 15 |
| 7 | bakery | 210 | 96 | 42 | 72 | 192 | 0 / 0 / 20 | 14 | 15 |
| 42 | farm | 48 | 0 | 42 | 6 | 126 | 17 / 0 / 0 | 12 | 13 |
| 42 | mill | 88 | 48 | 42 | -2 | 118 | 0 / 16 / 0 | 13 | 13 |
| 42 | bakery | 195 | 88 | 39 | 68 | 188 | 0 / 0 / 19 | 12 | 13 |
| 99 | farm | 48 | 0 | 42 | 6 | 126 | 19 / 0 / 0 | 14 | 14 |
| 99 | mill | 88 | 48 | 42 | -2 | 118 | 0 / 16 / 0 | 13 | 13 |
| 99 | bakery | 195 | 88 | 39 | 68 | 188 | 0 / 0 / 19 | 12 | 14 |

Final business balances are farm/mill/bakery **121/119/192** (seed 7), **126/118/188** (42 and 99). These sum to all 432 initial coins. Every firm can still fund a three-coin shift. The mill and bakery have spent their input buffers but hold output at/above target, so their policies do not purchase more inputs. No firm is formally bankrupt, closed, or in debt; the failure is prolonged inactivity and household exclusion. Plenty of initial working capital did not guarantee turnover.

Final resources reconcile independently: seed 7 wheat `16 + 61 − 60 = 17`, flour `12 + 60 − 56 = 16`, bread `18 + 84 − 82 = 20`. Seed 42: wheat 17, flour 16, bread 19; seed 99: wheat 19, flour 16, bread 19. No currency is minted, no inputs disappear off-ledger, and no promised/future labor is treated as production. Gross circulation 496/454/454 counts actual purchases and payroll receipts once; repeated movement is not additional money supply.

## Why economic activity stops

1. Common policies hire to fill output targets, considering the owner first. A single bakery shift creates six bread but pays one worker enough for one bread. Early initial cash funds broader demand; additional staff are skipped once stock reaches target. Factories need fewer labor-days than the population needs wage-funded meals.
2. There is no retained-profit distribution in the predeclared experiment. Household payments return money to the bakery, while business-to-business input sales move funds among firms. Wage income alone does not keep all twelve households funded. This is an important assumption of this model, not a universal conclusion about employment economies.
3. As households exhaust cash, bakery sales fall. Its output stays at/above 18, so all baking shifts stop and payroll ceases despite sufficient firm money. Reduced flour/wheat demand leaves the upstream targets full too.
4. By the common late state every household has zero cash and bread. Firms have cash and target stocks. Owner policies decline all input/shift actions; food policies wait for unaffordable food; meal commands record actual insufficient stock. Future farm draws cannot affect an output-target wait. Within these rules this is a self-maintaining economic deadlock, with no rescue or arbitrary resumed work.

For seed 42 on **day 26**, farm holds 17 wheat and 126 coins, mill holds 16 flour and 118 coins, bakery holds 19 bread and 188 coins. All twelve schedule decisions wait with `output_target_met`; all twelve food decisions wait with `unaffordable_food`; all twelve meal attempts fail. No payroll is attempted or silently granted. The 30- and 365-day account/resource states match in every seed. Last village business day is 15/13/14 and annual trailing inactivity is 350/352/351 days. There is no renewed activity after day 26.

The positive physical buffer, nominal wage/food affordability, and sufficient operating funds therefore coexist with severe realized hunger. This milestone establishes meaningful paid productive work and its consequences, not an economically viable baseline. Different wealth/population/endowments/ownership rules from M8 preclude a controlled aggregate improvement comparison. No parameter, wage, price, target, scheduling, profit-distribution, or policy change was made after these observations.

## Verification and limitations

Base: M8 commit `f064a2a`. Runtime: **Godot 4.6.3**. Pre-change suite: **2513 checks, zero failures**. Complete final suite: **2572 checks, zero failures**, preserving all 2513 and adding 59 focused M9 checks. All **10 Python tests** pass (six M8 observers and four independent labor-audit tests). The latter verify full reconstruction/nonmutation and rejection of changed wages, unlinked payroll/production, and unsupported reported income.

All **65 historical JSON captures are byte-identical**: 23 through M6B, 36 M7 configurations, and six M8 combined captures. Historical worlds/policies/configurations and result tables are unchanged. All six M9 cases match independent-process replay byte-for-byte, pass independent reconstruction of complete day/entities/businesses/employment/offers/labor/opportunities/meals, and conserve 432 coins at every event. Every payroll/production receipt is claimed by one eligible, bounded, paid shift, and each report reconciles per-account money, commodity sources/sinks, meals, decisions, and business activity. The native tests also cover stale offers after money/input spending, cross-workplace double shifts, capacity/eligibility failures, fixed-price purchase authority, personal/account spoofing, privacy, and split-run replay.

An early indentation parse error was corrected before experiments. An initial full-suite attempt hit a 120-second command timeout while running historical groups; unrestricted complete reruns succeeded. Review also corrected the new scenario's inherited failure summary to exclude duplicate decision annotations; every authoritative M9 event history remained unchanged, and the six experiments were replayed/re-audited with the corrected projection. No assertion, simulation, accounting, or replay failure remains. Headless editor import and readable 30/365-day seed-42 CLI runs pass, as does `git diff --check`. Documentation CSVs are excluded from Godot asset import using `docs/.gdignore`; they are not translation assets.

Actual commands, using the README writable XDG setup:

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py' -v
python3 -B scripts/tools/run_labor.py --output /workspace/work/m9
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_labor 365 42
godot --headless --editor --path . --import
git diff --check
```

Full captures are `/workspace/work/m9/settlement_labor-{seed}-{days}.json`; compact tables are copied unchanged to the three committed CSVs. Annual histories contain 27,263–27,290 events and about 9.15–9.16 MB of formatted JSON each, despite early economic inactivity. Daily environment/decision/unmet-meal logging continues. Histories remain in memory, event/snapshot retrieval deep-copies data, and the experiment tool keeps both replay payloads; broader population/time scales will need separate consideration. No historical-storage framework was built.

Limitations: trusted developer initialization with fixed assignments; one full-shift unit/day; no partial shifts, labor negotiations, recruitment or dismissal, guaranteed employment, debt, profit withdrawals, autonomous capital movement, food reservations, health/death, or changing demand/prices. Workplace capacity is an abstract field/mill/oven slot, not a spatial asset. Policies receive copied permitted observations, not a security sandbox against arbitrary GDScript access. Cross-version replay, additional seeds, shocks, longer horizons, and alternative policies/initial conditions remain unverified. Cash affordability of a full next recipe is distinct from the report's simple `can_fund_one_shift` payroll flag. Skipped reasons use the first applicable policy condition; they do not measure every possible underlying constraint.

Files added: four cohesive `labor_*` simulation/configuration/policy scripts and their Godot UID files; one labor experiment/audit tool; focused Godot/Python tests; this report and three small CSVs; `docs/.gdignore`. The CLI and test entry point select/include M9, and README/architecture/roadmap document its boundaries. The original accounting kernel and all prior scenario implementations are unchanged.

Stop after M9 for review. No M10 has begun.
