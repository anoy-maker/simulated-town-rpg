# M12 — Employer-Driven Production and Labor Scheduling

## Fixed experiment before outcomes

This is a separately selected `settlement_employer_choice`, with M11 unchanged as the control. Copy its exact twelve residents, ownership/employment/skills/assets, six personal coins, 120 coins/business, zero commodities, 432 total coins, 2/4/4 prices, eight-coin shifts, four wheat/harvest, and existing two-batch milling/baking recipes. No withdrawals, subsidies, debt, free food, guarantees or revised parameters.

Architecture inspection found no major refactor is needed. A child of the existing reference world projects only an owner's own completed previous-day sales/purchases and previous forecast, from existing receipts. A new pure employer policy proposes a production/input/staffing plan. An execution adapter binds the owner/business and dispatches existing validated purchases, shift offers, worker acceptances and production; it records actual outcomes. A separate runner keeps the farm → mill → bakery → household food → consumption order. No historical world/policy/scheduler changes are required.

**Predeclared forecasting rule:** on day one only, expected sales are 8 wheat / 8 flour / 12 bread for the corresponding firm. On every later day, expected sales equal that firm's actual successful sales quantity of its output on the immediately preceding calendar day. Zero sales mean a zero forecast. There is no smoothing, recurring startup fallback, minimum output, market-wide household demand oracle, or forecast retuning.

The owner subtracts existing output stock from the forecast, rounds a positive shortfall up to the smallest whole number of productive shifts, and caps the plan by assets and eligible available workers. Each worker supplies one full shift. Farming makes four wheat/shift, milling four flour from four wheat, baking six bread from four flour. Extra whole-batch output remains real unsold stock and offsets later plans.

Select the owner first, then qualified active employees in stable ID order; never rotate. Evaluate prefixes of that roster, reducing the shift count until actual owned inputs plus public available stock suffice and current firm cash covers both required input purchases and all selected contractual wages. Only missing inputs for this plan are purchased, using the existing price/stock/ID offer selector. A scheduled available employee accepts a valid funded shift. Existing employment stays active without guaranteed hours. An owner gets no compensation merely for planning. No production is added to keep people employed.

Owner observations include own household/firm state, own workers' eligibility/availability/wages, productive assets, public output offers and own prior-day trade aggregates. Other households' balances, unrelated firms' internal funds/ingredients, full history, and future transactions are excluded. Report-only aggregates never enter decisions. Plans record forecast/source, stock offset, desired and feasible output/shifts, input/payroll costs, limiting reasons, selected workers and skipped candidates; authoritative annotations link real receipts and outcomes.

Experiments are fixed at **2, 30 and 365 days, seed 42**, alongside the original M11 control. Harvest opportunities are constant and neither policy draws randomness, so no second-seed matrix is needed. Verify deterministic replay including full in-memory ledgers, existing accounting/production/labor safeguards, and published historical hashes. Use compact summaries, ledger hashes and a short audited trace; do not export verbose annual histories.

Reporting definitions are fixed too: a food shortage begins at the first failed daily meal. Record separately the first day bakery stock before household buying is below twelve, and misses on days bread remains unsold. Economic activity means successful production/work or a purchase, excluding logging, planning, wages annotated twice, and consumption. Sustained village inactivity means at least **seven consecutive complete days** with no such activity; report the first day of that run and any trailing run. Individual long work gaps remain separately visible. Show only the first eight daily aggregates in compact reports; full decisions remain in memory for audit.

## Actual results

The unchanged M11 control feeds everyone. M12 does not: **1122 of 4380 annual meals are consumed, 3258 are missed, and only 563 paid shifts occur**. Three owners eat daily while nine employees receive just nine paid shifts combined, all by day four. Currency, goods and labor accounting remain valid. There is continuing owner-supported trade, rather than complete village inactivity. No policy or economic parameter was changed to improve these results.

### Matched comparison

All cases use seed 42 and identical initial resources, prices, recipes, wages, workforce and constant opportunities. Each was run twice in separate Godot processes with identical compact bytes and full-ledger fingerprints. M11 control summaries match their published hashes.

| Days | Scenario | Meals eaten / missed | Paid shifts | Owner / employee wages | Wheat / flour / bread produced | Gross cash circulation |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | M11 control | 24 / 0 | 12 | 24 / 72 | 16 / 16 / 24 | 288 |
| 2 | M12 employers | 18 / 6 | 12 | 48 / 48 | 16 / 16 / 24 | 264 |
| 30 | M11 control | 360 / 0 | 180 | 360 / 1080 | 240 / 240 / 360 | 4320 |
| 30 | M12 employers | 117 / 243 | 61 | 416 / 72 | 84 / 80 / 120 | 1436 |
| 365 | M11 control | 4380 / 0 | 2190 | 4392 / 13128 | 2920 / 2920 / 4380 | 52560 |
| 365 | M12 employers | 1122 / 3258 | 563 | 4432 / 72 | 752 / 752 / 1122 | 13488 |

Circulation sums actual input purchases, household food purchases and payroll once each; it is turnover, not new currency or income net of costs. Total money is always **432**. Successful purchase counts are M11 **28 / 420 / 5110**, M12 **22 / 152 / 1492** at 2/30/365 days. Both have zero rejected purchases, rejected work shifts, unfunded shifts and rejected employer plans in these experiments. Food policies wait when unaffordable instead of submitting rejected purchases; missed meals still count every failed daily consumption.

Physical capacity has not changed: four available farming shifts could harvest 16 wheat/day and the chain's independent full-capacity bread bound is 24/day; M11 needs only two shifts/firm/day for 12 meals. M12 realizes 752 of 5840 potential wheat and 1122 of 8760 bounded annual bread, versus needs of 4380 bread. These bounds describe available labor/recipes/opportunities, not a prediction of realized demand or a mandated production target.

### First divergence: food exists, but half the residents cannot buy it

| Day | Bread made | Bread before food purchases | Bread sold/eaten | Bread left | Missed meals | Paid shifts |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 12 | 12 | 12 | 0 | 0 | 6 |
| 2 | 12 | 12 | 6 | 6 | 6 | 6 |
| 3 | 0 | 6 | 6 | 0 | 6 | 4 |
| 4 | 6 | 6 | 6 | 0 | 6 | 3 |
| 5 | 6 | 6 | 6 | 0 | 6 | 1 |
| 6 | 6 | 6 | 5 | 1 | 7 | 2 |
| 7 | 6 | 7 | 5 | 2 | 7 | 2 |
| 8 | 6 | 8 | 4 | 4 | 8 | 3 |

Day one matches M11's physical output and working group. On day two forecasts still equal 8/8/12, so M12 again produces enough for everyone. Owner-first/stable-ID staffing pays **the same six residents again**. The other six have only two coins after their first meal and cannot afford four-coin bread. Six bread remain unsold while six meals are missed. This first divergence is financial access, not missing production or inadequate capital.

On day three Cora sees six realized sales and six unsold bread. The inventory offset eliminates her productive shifts; she buys no flour that day. Later upstream sales observations and staffing shrink too. Declining paid demand and unsold-stock offsets reduce output, which eventually becomes physically insufficient to feed twelve. They do not signal that household needs disappeared. The first failed meals occur on **day 2**; the first bakery stock below twelve before household purchasing is **day 3**. Misses on days with bread remaining unsold total **6 / 127 / 1630** at 2/30/365 days. Those figures show simultaneous exclusion and stock, not an assertion that every missed meal could be served by the remaining stock.

M11 and M12 change both forecasting and staffing. The day-two trace isolates the initial staffing difference before output changes; later effects combine staffing, observed paid demand, whole batches and retained stock. There is no separate forecasting/staffing ablation and no claim that their long-run effects are independently measured.

### Employment and individual food access

All nine employment records remain active and unchanged. Owners have no management income or withdrawals; every coin of compensation below belongs to an actual productive shift. The annual comparison is:

| Resident | Firm / status | M11 paid shifts | M12 paid shifts | M12 wages | M12 food spending | M12 meals / missed | M12 final coins | Last M12 work day |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Ada | Farm owner | 183 | 184 | 1472 | 1460 | 365 / 0 | 18 | 364 |
| Bram | Mill owner | 183 | 185 | 1480 | 1460 | 365 / 0 | 26 | 365 |
| Cora | Bakery owner | 183 | 185 | 1480 | 1460 | 365 / 0 | 26 | 364 |
| Dain | Farm employee | 183 | 4 | 32 | 36 | 9 / 356 | 2 | 4 |
| Edda | Farm employee | 182 | 0 | 0 | 4 | 1 / 364 | 2 | Never |
| Gale | Farm employee | 182 | 0 | 0 | 4 | 1 / 364 | 2 | Never |
| Hale | Mill employee | 183 | 3 | 24 | 28 | 7 / 358 | 2 | 3 |
| Jory | Mill employee | 182 | 0 | 0 | 4 | 1 / 364 | 2 | Never |
| Lyle | Mill employee | 182 | 0 | 0 | 4 | 1 / 364 | 2 | Never |
| Finn | Bakery employee | 183 | 2 | 16 | 20 | 5 / 360 | 2 | 2 |
| Iona | Bakery employee | 182 | 0 | 0 | 4 | 1 / 364 | 2 | Never |
| Kira | Bakery employee | 182 | 0 | 0 | 4 | 1 / 364 | 2 | Never |

M11 gives every resident 365 meals. M12 owners also eat all 1095 of their combined meals; employees eat **27 of 3285**, missing **3258**. Six employees never work; the other three receive no work after day four. Owner-first staffing assigns every later one-shift plan to its owner. Employment contracts confer eligibility, not hours, wages or purchasing power. Across all residents M12 leaves 3817 of 4380 possible resident-days without paid work, versus 2190 in M11.

M12 owners receive 4432 wages for 554 shifts, versus M11's 4392 for 549. Employees fall from 13128 wages/1641 shifts to 72/nine. This is productive compensation concentration, not ownership distributions. All personal inventories are empty at the end of each reported horizon.

The inherited `shifts.unavailable` CSV field counts explicit per-worker scheduling waits in the original labor policy. M11 and M12 do not emit those waits, so its zero is **not** a count of unemployment. Actual shifts, last work days, and each employer plan's skipped-worker records measure participation here. The inherited empty business `schedule_reasons` maps likewise do not replace the new `employers.by_business` reasons and skips.

### Business activity, stock and money

Annual receipts and final holdings:

| Scenario / business | Sales revenue | Input spending | Payroll | Total spending | Completed shifts | Output | Final coins | Final commodity stock |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M11 farm | 5840 | 0 | 5840 | 5840 | 730 | 2920 wheat | 120 | None |
| M11 mill | 11680 | 5840 | 5840 | 11680 | 730 | 2920 flour | 120 | None |
| M11 bakery | 17520 | 11680 | 5840 | 17520 | 730 | 4380 bread | 120 | None |
| M12 farm | 1504 | 0 | 1504 | 1504 | 188 | 752 wheat | 120 | None |
| M12 mill | 2992 | 1504 | 1504 | 3008 | 188 | 752 flour | 104 | 4 flour |
| M12 bakery | 4488 | 2992 | 1496 | 4488 | 187 | 1122 bread | 120 | None |

M12 mills all 752 harvested wheat, bakes 748 flour, leaves four flour, produces 1122 bread and consumes all 1122. No unaccounted sources/sinks occur. At day two the businesses hold 120/120/96 coins and six unsold bread at the bakery. At day thirty farm/mill/bakery hold 112/120/108 coins, four wheat at the farm and three bread at the bakery. The remaining stocks explain cash differences without a balance reset, subsidy or refund.

At day 365 businesses hold **344 coins (79.63%)**, owners **70 (16.20%)**, employees **18 (4.17%)**. In M11 the corresponding totals are 360/30/42; each firm's balance repeats daily, and households alternate the verified two-day states. M12 does not retain those equilibrium invariants; they are control properties, not requirements imposed on employer choices.

No actual M12 plan is limited by missing inputs or operating funds. Each business can still fund a productive shift at the final snapshot. Annual plan counts distinguish the realized demand mechanism:

| Firm | Plans meeting expected sales | Zero-sales waits | Stock-covered waits | Declining-sales annotations | Stock-offset annotations | Actual owner / employee shifts |
| --- | --- | --- | --- | --- | --- | --- |
| Farm | 184 | 180 | 1 | 179 | 1 | 184 / 4 |
| Mill | 185 | 179 | 1 | 179 | 1 | 185 / 3 |
| Bakery | 185 | 0 | 180 | 4 | 182 | 185 / 2 |

Annotations can overlap; a stock offset may reduce positive production as well as eliminate it. Minimum whole shifts sometimes produce more than the forecast, leaving stock for a later day. The bakery has 185 productive days but 187 shifts due to its initial two-shift days. These are calculated choices, not recurring two-shift quotas.

There is **no seven-day village-wide economic inactivity run** and no trailing one at any tested horizon. Every firm still trades on day 365; last productive days are farm 364, mill 365, bakery 364. Continued activity serves the three owners. It does not establish broad viability or contradict the nine employees' persistent lack of paid work.

### Implementation, verification and limits

New implementation consists of `employer_policy.gd` (pure plan), `employer_world.gd` (authorized own-history projection and existing-command dispatch), `employer_runner.gd` (daily decisions/reporting), and `run_employer.py` (six compact comparisons). CLI selection and the existing independent labor auditor are extended; historical simulation implementations remain unchanged. Focused GDScript/Python tests, README/architecture/roadmap updates and the results tables complete the change.

A plan is a sequence of individually authoritative transactions, not a new atomic financial transaction. The executor recomputes payroll and fixed-price input cost from authority before spending. A stale or invalid purchase/shift still fails through the original command. If earlier valid work succeeded before a later command fails, it remains real, paid and auditable; the plan reports partial execution and receipt links. No whole-plan rollback, fabricated production or automatic refund is added. A focused synthetic changed-skill case verifies that boundary; it does not change experimental endowments or eligibility.

Verification used **Godot 4.6.3**:

- Full native suite: **2703 checks, zero failures**, including all 2673 prior checks and 30 M12 checks.
- Standard-library Python discovery: **22 tests passed**, including four new M12 auditor/replay tests and the original 18.
- Full in-memory ledgers at 2/30/365 days reconstruct all cash and goods, check 432 coins/nonnegative bounds after every event, validate four-wheat harvests/two-batch recipes, and link every payroll/production receipt to exactly one paid shift and employer decision. Split-run full-state/event/report replay passes.
- Independent Python short-trace reconstruction passes; forged sales forecasts and reused work receipts are detected. Annual independent-process compact replay includes the complete ledger hash without exporting events. Annual audit of native receipts occurs in the Godot tests.
- All **93 historical pinned outputs** remain byte-identical: 59 through M7, six M8, six M9, eighteen M10, and four M11 report-only outputs. The original M0 default and all historical simulation code remain unchanged.
- The six fixed comparison cases replay byte-identically; M11's summaries match published hashes. A focused two-day seed-99 trace equals seed 42 because M12 uses constant opportunities and no random decisions. No second-seed matrix is necessary for this deterministic, nonrandom policy.

Commands (use the README's writable XDG setup for direct Godot commands):

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/run_employer.py --output work/m12
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_employer_choice 365 42
```

[Six run summaries](M12_RUNS.csv), [72 resident rows](M12_RESIDENTS.csv), and [18 business rows](M12_BUSINESSES.csv) contain both scenarios at all three horizons, actual counts/cash flows/holdings, and summary/ledger SHA-256 values. Blank control-only diagnostic columns mean M11 has no M12 diagnostic projection; its zero missed meals are verified independently. Summary JSON stays in the work directory; no annual verbose event dumps are added.

The forecasting rule and all three simulation implementation files were fixed before the matrix and remained unchanged afterward. Only audit/test handling of partial execution, documentation and output tables were completed afterward. No result-driven policy or economic tuning occurred. There were no final test failures or unverified requested runs; this experiment does not establish behavior under shocks, alternative forecasts, rotation, different ordering or alternative policy designs.

Last-day sales are a deliberately limited signal of **effective paid demand**, not unmet need; zero upstream sales can pause work on the next day. Owners prefer themselves, employees are passive accepters, and stable IDs repeatedly select the same additional workers. Whole shifts and recipes cause stock carryover. Farm → mill → bakery sequencing, household ID order, exact prices/wages and constant harvest capacity remain controlled assumptions. No policy is repaired to prevent unemployment or starvation.

M11 remains evidence of feasibility under prescribed decisions. M12 shows that these specific decentralized employer choices do **not** reproduce universal food access, despite adequate underlying productive capacity and solvent businesses. Stop after M12 for review; no M13 or economic rescue is implemented.
