# M14 — Profitable ownership and contractual employment reference

## Fixed specification and implementation path

This is the separately selected `settlement_profitable_reference`, a prescribed reference, not autonomous scheduling or profit optimization. M0–M13 remain historical controls. Initial holdings are exactly six coins per resident, 120 per business, no commodities and 432 coins total. Ownership, employees, skills and productive assets remain the original twelve-person structure. Wheat/flour/bread prices are 2/4/4. Existing paid recipes yield four wheat, four flour from four wheat, or six bread from four flour per shift.

Managers Ada/Bram/Cora retain their skills but cannot perform paid productive work in this world. Each employee has an ongoing six-coin contract for two shifts per three-day cycle. The prescribed pairs are farm Dain/Gale → Dain/Edda → Edda/Gale; mill Hale/Lyle → Hale/Jory → Jory/Lyle; bakery Finn/Kira → Finn/Iona → Iona/Kira. No substitution, catch-up work, debt, suspension or termination conceals a missed obligation. Output/sales forecasts and inventory targets do not change these scheduled attempts.

Architecture inspection found a small extension sufficient. M14 inherits the reference price/harvest and original labor/purchase/recipe authority. Two protected, default-preserving labor hooks permit zero owner compensation only in this world and forward authorized account transfers to the existing kernel. No inventory or balance reset, new industry or general employment framework is needed. New contract due/attempt/outcome records distinguish eligibility, scheduling, completed paid labor and breaches; they do not move money.

Daily order is determine contractual pairs → farm paid work → mill real input purchase/paid work → bakery real input purchase/paid work → twelve personal bread purchases → twelve consumption attempts → eligible owner profit distributions → contract/day accounting closure. Ordinary business operations may use initial capital below 120. Owner distributions occur after household consumption attempts, use existing coins, and must leave 120 untouched.

A receipt-derived cash book tracks actual sales, input spending, payroll and prior distributions. Eligible distribution is the smaller of positive cumulative realized operating cash after previous payouts and positive actual cash above 120; for the unfinanced canonical initialization these are equal. No unsold stock or commodity valuation counts as revenue. The entire eligible amount is paid to the actual owner; a zero budget creates no distribution event. This is a restricted cash-surplus measure, not accrual profit. Earlier operating deficits must be recovered before another eligible payout.

Expected daily results are 8 wheat, 8 flour, 12 bread, six paid employee shifts, 36 wages, twelve consumed meals, twelve owner-distribution coins and 120 closing cash per firm. Each firm realizes four coins of cash surplus after actual sales/input costs/payroll. Owners return to six coins daily. Employee financial states repeat after three days: scheduled employees 8 / unscheduled 2 on day one; Dain/Hale/Finn 10 and the other six employees 4 on day two; everyone 6 on day three. These predictions will be checked against receipts, never imposed by resetting state.

Run 1/2/3/30/365 days with seed 42, independent-process and split-run replay, every-event currency/goods/labor/cash-book audits, explicit daily/three-day recurrences and historical hashes. No annual verbose event exports. Synthetic fixtures will test real cash/input/eligibility/capacity failures, declined scheduling, duplicate closure, capital/loss/unsold-stock safeguards, authority and repeated settlement without altering the canonical initial conditions. No corrective policy or M15.

## Actual results

### Actual results versus predictions

**Every requested prediction holds at 1, 2, 3, 30 and 365 days.** Each case was run twice in independent Godot processes, with identical compact report bytes and full-ledger fingerprints. All reference and accounting flags pass. Productive owner shifts and owner wages are **zero** throughout.

| Days | Meals / missed | Paid employee shifts | Employee wages | Owner distributions | Contract breaches | Closing cash per firm | Currency |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 12 / 0 | 6 | 36 | 12 | 0 | 120 | 432 |
| 2 | 24 / 0 | 12 | 72 | 24 | 0 | 120 | 432 |
| 3 | 36 / 0 | 18 | 108 | 36 | 0 | 120 | 432 |
| 30 | 360 / 0 | 180 | 1080 | 360 | 0 | 120 | 432 |
| 365 | 4380 / 0 | 2190 | 13140 | 4380 | 0 | 120 | 432 |

At day 365 each business has completed **730 employee shifts**. Each owner has received **1460 coins** of actual distributions. Dain/Hale/Finn each completed **244 shifts** and hold ten coins; the other six employees each completed **243 shifts** and hold four. Owners hold six coins each. All household and business inventories are empty. No transaction fails, meal is missed, or contractual shift is breached in the canonical runs. There is no economic deviation to correct and no post-result change to wages, prices, schedule, endowments, productivity or recipes.

### Three-day reference cycle and repeatability

Actual end-of-day household balances match the specified phases:

| Residents | Initialization | Day 1 | Day 2 | Day 3 |
| --- | --- | --- | --- | --- |
| Ada, Bram, Cora | 6 each | 6 each | 6 each | 6 each |
| Dain, Hale, Finn | 6 each | 8 each | 10 each | 6 each |
| Gale, Lyle, Kira | 6 each | 8 each | 4 each | 6 each |
| Edda, Jory, Iona | 6 each | 2 each | 4 each | 6 each |

All three firms return to **120 coins and no inventory every day**. A managing owner spends four coins before receiving four at settlement: `6 − 4 + 4 = 6`. Each employee receives twelve coins and consumes twelve coins of bread per complete three-day cycle: `6 + 2×6 − 3×4 = 6`. Every employee works exactly twice per complete cycle; no one works more than once on a day.

Daily company cash equations, using real receipts, are farm `120 − 12 + 16 − 4 = 120`, mill `120 − 16 − 12 + 32 − 4 = 120`, bakery `120 − 32 − 12 + 48 − 4 = 120`. Ordinary operating cash falls below 120 before sales, as permitted; only distributions retain the floor. Required inputs are purchased per due employee shift, then that shift is attempted, before moving to the next industry. This preserves a feasible first shift when a synthetic firm can afford only part of its day. Normal input purchases are four wheat twice and four flour twice; all twelve households buy one bread each. There are **16 successful purchases/day**, rather than M11's larger combined ingredient orders. This changes no prices, amounts or economic totals in this isolated reference.

The return to the same personal cash/inventory state after day three, the same business state every day, an unchanged three-day rotation and a zero retained realized cash result after settlement establish repeatability by induction under the specified assumptions. The next cycle has the same inputs, available workers, costs and purchasing power. Raw day numbers, event IDs and cumulative receipts naturally grow; they are not reset to fake a repeated full snapshot. This is mathematical feasibility under prescribed actions, not a promise that the engine can store an infinite history.

### Individual employment and income

Annual observed outcomes:

| Resident | Role | Due / completed shifts | Wages | Distributions | Food expenditure | Meals / missed | Final coins |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ada | Managing owner | 0 / 0 | 0 | 1460 | 1460 | 365 / 0 | 6 |
| Bram | Managing owner | 0 / 0 | 0 | 1460 | 1460 | 365 / 0 | 6 |
| Cora | Managing owner | 0 / 0 | 0 | 1460 | 1460 | 365 / 0 | 6 |
| Dain | Farm employee | 244 / 244 | 1464 | 0 | 1460 | 365 / 0 | 10 |
| Edda | Farm employee | 243 / 243 | 1458 | 0 | 1460 | 365 / 0 | 4 |
| Finn | Bakery employee | 244 / 244 | 1464 | 0 | 1460 | 365 / 0 | 10 |
| Gale | Farm employee | 243 / 243 | 1458 | 0 | 1460 | 365 / 0 | 4 |
| Hale | Mill employee | 244 / 244 | 1464 | 0 | 1460 | 365 / 0 | 10 |
| Iona | Bakery employee | 243 / 243 | 1458 | 0 | 1460 | 365 / 0 | 4 |
| Jory | Mill employee | 243 / 243 | 1458 | 0 | 1460 | 365 / 0 | 4 |
| Kira | Bakery employee | 243 / 243 | 1458 | 0 | 1460 | 365 / 0 | 4 |
| Lyle | Mill employee | 243 / 243 | 1458 | 0 | 1460 | 365 / 0 | 4 |

All nine employee records stay active, and all scheduled obligations are attempted and fulfilled in the normal reference. Expected and paid contractual compensation both total **13140**; owners have no employment contract due and collect no wages. Every resident spends **1460** on food and eats **365** meals. Owner distributions are ownership income, separately reported from payroll, with no productive owner labor. They are neither management wages nor M10-style discretionary capital withdrawals.

### Business results and monetary/commodity reconciliation

Annual cash results:

| Business | Sales receipts | Input purchases | Paid payroll | Realized operating cash surplus before distributions | Distributions | Retained result | Final cash |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Farm | 5840 | 0 | 4380 | 1460 | 1460 | 0 | 120 |
| Mill | 11680 | 5840 | 4380 | 1460 | 1460 | 0 | 120 |
| Bakery | 17520 | 11680 | 4380 | 1460 | 1460 | 0 | 120 |

Each firm's daily surplus is four because all output really sells. The operation does not simply award the expected four. Its actual budget is:

`max(0, min(cumulative_sales − cumulative_inputs − cumulative_payroll − prior_distributions, actual_cash − 120))`.

With 120 starting capital and no financing/injections, the two terms inside `min` are equal. The cumulative check additionally rejects a synthetic firm's preexisting capital above 120 as income. Operating losses must be recovered before any eligible payment; inventory creation/valuation cannot create cash. Zero eligible cash emits no distribution. A successful payment uses the existing atomic account transfer, then one `profit_distribution` annotation links that exact receipt. Repetition finds no remaining surplus and cannot pay it twice.

Native transfer receipts count once in monetary circulation. The report reclassifies business-to-owner transfers from the inherited generic wage projection into `profit_distributions_received/paid`, retaining correct total earnings/spending. Distributions reduce retained cash but are shown separately from operating input/payroll costs, not treated as formal operating expenses. The receipt-derived cash book is independently reconstructed and reconciled against authority.

Aggregate annual payroll **13140** plus distributions **4380** supplies exactly household food expenditure **17520**. Intermediate wheat/flour spending is **5840 + 11680 = 17520**. Gross circulation is therefore **52560**, or 144/day; this is turnover of the same **432 coins**, not currency creation. At the end of day 365 firms hold **360**, owners **18**, employees **54**, totaling 432. Cash remains nonnegative after every recorded event.

Goods reconcile without inventory resets: **2920 wheat harvested and 2920 milled**; **2920 flour made and 2920 baked**; **4380 bread made and 4380 consumed**. No commodity balance remains. Harvest is the existing authorized production source; recipes and household meals are explicit transformations/sinks. No free food, invisible sale, liquidation, inventory valuation, spoilage, fees or invented replacement input is used.

### Contracts and verified synthetic failures

Existing employee records carry fixed six-coin, two-of-three contract terms. `contract_due` identifies each daily obligation. `contract_attempt` links the actual authorized scheduling command and captures cash, inventory, wage, qualification, employment status, labor used and capacity before that scheduling attempt. If work later fails, its native failure also records the actual work-time constraints, which the breach record uses. `contract_shift` records expected/actual compensation, attempted/completed status, employer, worker, native shift link and reason. Unfulfilled outcomes remain in the event history. `contract_day_closed` aggregates fulfillment and closing money/goods/cash results. Closing twice emits no duplicate outcomes; advancing an unclosed day finalizes it before creating the next day's obligations.

An attempted contract means an authorized employer scheduling attempt for that due worker; an unauthorized actor cannot turn a declined obligation into an authorized attempt. Productive work still requires the existing worker's valid funded native shift. Breaches are nonfinancial records: no wage debt, arrears, free labor, substitute worker, catch-up slot, suspension or termination is introduced.

Focused fixtures, separate from the canonical initial state, verify:

- **Zero employer cash:** the native shift rejects `unfunded_payroll`; the attempted obligation records expected six coins, paid zero, no completed work and the zero-cash constraint. No wage or wheat appears.
- **No scheduling attempt:** records `employer_did_not_schedule`, distinct from the blocked cash attempt. The employment remains active and the next prescribed pair is unchanged; there is no automatic catch-up.
- **Missing inputs:** a cash-funded miller with no wheat records `insufficient_inputs` and no wage or flour. Missing skill similarly records ineligibility.
- **Stale offers:** when two valid mill shift offers share four wheat, the first completed shift consumes it and gets paid; the second is breached with actual zero wheat at work time and no wage. Offers reserve no stock, and a later failure does not reverse earlier paid production.
- **Capacity:** one available workplace slot permits the first real paid shift and four wheat, then records the second obligation's `workplace_capacity` breach. Completed work is retained, not refunded or duplicated; the constrained day's accounting still passes.
- **Owner/out-of-group authority:** managers and a qualified employee outside today's pair cannot perform a paid shift. Original owner skills remain intact.
- **Capital and unsold stock:** a synthetic firm starting with 124 coins but no operating receipts cannot distribute four; two unsold farming shifts leave eight real wheat, twelve paid wage coins and no owner income. A bakery starting with 1000 bread still completes contractual production and retains those 1000 unsold units; no target suppression or inventory deletion occurs.
- **Loss recovery:** twelve real payroll coins followed by sales of eight, four, then two coins produce cash results **−4 → 0 → +2**. Only the final **two** actual surplus coins can be paid. No fixed four-coin award is made.
- **Settlement boundaries:** premature settlement, a foreign owner and recipient numeric overflow reject without changing balances or cash books; zero/repeated settlement changes neither balances nor history. Snapshot edits cannot create realized income.
- **Independent audit:** forged surplus/amount metadata, reused payment receipts, invented contractual compensation and a fictional breach cause are detected even when simple total-currency conservation alone would pass.

Successful work, fulfilled promises and actual payouts therefore remain distinct concepts. A breach is not a financial transaction or a liability. If a noncanonical firm legitimately has distributable realized cash despite an unpaid/unworked contract, no fictional wage debt is deducted; the breach remains recorded separately.

### Architecture and verification

New scripts are `profitable_config.gd` (fixed terms/rotation), `profitable_world.gd` (M14 authority/bookkeeping/contract audit records), `profitable_runner.gd` (prescribed sequence/report), and `profitable_audit.gd` (independent event reconstruction and reference invariants). The only shared economic-code changes are two protected labor hooks: the minimum owner-compensation value remains one in historical worlds and becomes zero here; account payments forward to the original kernel transfer. All new inventory and balance movements still use the existing commands. Ordinary public cash/goods transfers and unpaid direct production remain forbidden.

Bookkeeping updates only from successful native financial receipts, including the original wage/distribution transfer. Contract and distribution annotations never apply the same money twice. Report and audit data are observations, not decision inputs. Zero manager compensation and exclusive contract days are authoritative guards, not just scheduling conventions. M10's owner-withdrawal mechanism is not inherited or used.

Verification on **Godot 4.6.3**:

- Full native suite: **2803 checks, zero failures**, retaining all 2754 historical checks and adding 49 focused M14 checks.
- Full Python discovery: **33 tests passed**, preserving the original 28 and adding five M14 independent-audit/replay checks.
- The five fixed cases run twice in independent processes; original summary bytes and complete canonical-ledger hashes match exactly. Full annual ledgers are verified internally, not written as verbose artifacts.
- In-memory checks reconstruct every coin and commodity, validate recipes/unique funded shifts, manager/employee authority, due/attempt/fulfillment/breach links, actual cash budgets/payout receipts, final books/holdings, each daily business state and all phases of the recurring three-day household state. Split-run ledgers, snapshots and reports match across all requested horizons. A focused seed-7/99 trace matches because this world uses no randomness.
- Historical verification passes: all **96 pre-M13 pinned outputs**, all **16 M13 study outputs** and their **16 original-summary/ledger comparisons** match their published hashes (six summary cases repeat earlier controls). Historical economic configurations and result files are unchanged.

The first three-day preflight exposed an audit allowlist omission for successful `contract_shift` annotations. It was corrected before the fixed matrix; no economic result, parameter or policy needed adjustment. There are no deviations from the requested reference totals. All final tests pass and every required simulation is verified. The late failed-work diagnostic refinement leaves all five canonical compact reports and ledger fingerprints byte-identical to the original fixed matrix.

Run from the repository root using the README's writable XDG setup when needed:

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/run_profitable.py --output work/m14
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 365 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 365 42 --report-json
```

Run the CLI at 1/2/3/30/365 for each prescribed horizon. Default human output is eight lines. `--report-json` includes the full-ledger fingerprint, contract and income projections, first three daily financial states and all verification flags, but no events. A complete annual report is **20349 bytes** in this run. [Five run rows](M14_RUNS.csv), [60 resident rows](M14_RESIDENTS.csv) and [15 business rows](M14_BUSINESSES.csv) contain every horizon's actual wages/distributions/work/meals/cash/stock and summary/ledger hashes. The full histories remain available internally; short `--json` traces support independent auditing.

### Limits and interpretation

This verifies the requested **prescribed economic reference** and its mathematical financial/commodity recurrence. It does not prove autonomous hiring, market stability, profit optimization or resilience to a shock. Availability, labor schedules, harvest productivity, recipes, wages, prices, account separation and absence of decay are fixed assumptions. There are no social responses, borrowing, investment, automatic capital replenishment or economic rescue.

The cash book is not accrual accounting: it does not value inventory, depreciation, liabilities, income taxes or general investment/capital flows. Contract breaches are historical unmet obligations, without enforcement or wage debt. Contract status/terms are trusted fixed initialization rather than a mutable hiring/renegotiation system. Inventory persists without an economic storage cap or cost; the inherited one-billion-unit numeric safety bound still applies. It is never approached by this zero-closing-stock cycle. Potential-capacity figures describe the specified three-employee/industry reference, not an unrelated workforce configuration.

The deterministic recurrence supports indefinite repetition mathematically under unchanged assumptions, while finite integer counters, copied in-memory history and runtime memory prevent a claim of literally unbounded software execution. Persistence/reload, shocks and autonomous discovery are not tested or added. No default economics or historical results are overwritten. Stop after M14 for review; no M15 or corrective policies.
