# M29 evidence schemas

These are offline research outputs, never policy observations. The native event
schema and old M0–M28 artifacts are unchanged. Read the frozen
[protocol](M29_CASH_ALLOCATION_FEASIBILITY.md) and [results](M29_RESULTS.md) first.

`condition,arm,allocation,seed` identify a case; `stratum` distinguishes primary
scarce/no-brew from secondary tight/reference controls. B/I mean
`R_baseline_instrumented`/`R_input_aware`. Days are simulation days; minutes are
simulation minutes. Event IDs address that case's full native trace, starting
with `initialize` ID1 at day0/minute0. Do not join IDs across cases. JSON arrays
and nested maps inside CSV cells are serialized JSON. Coins/items are integers;
empty/missing observations are not measured zero demand or supply.
`owner` labels the four owner-resident wallets (Ada/farm, Bram/mill,
Cora/bakery, Mara/brewery); business accounts remain separate rows of their own
kind, never merged into an owner's personal cash.

| File | Grain and meaning |
| --- | --- |
| `M29_RUNS.csv` | 48 cases, including short primary horizons; report/ledger SHA, meals, output, actual wages, shifts, purchases, terms and final currency |
| `M29_PERFORMANCE.csv` | 96 actual fresh-process captures; short checkpoint captures retain their original timings and are marked reused in the final matrix; native run/report walls, whole command wall, process peak RSS KiB, audit wall and worst headless appointment/tick |
| `M29_PARITY.csv` | 16 original-allocation cells: literal M28 event/receipt/ledger equality and complete report equality after changing only scenario and removing new research metadata |
| `M29_INITIAL_ACCOUNTS.csv` | All 20 actual accounts per 30-day case; exact initial coins and delta versus original, owner label, initialization provenance and zero earned income |
| `M29_RESIDENTS.csv` | All 15 residents per 30-day case; initial/final cash, owner label, meals/misses, actual wages, accrued/owed wages, productive/standby attendance, ownership income, food/ale spending and final goods |
| `M29_FIRMS.csv` | Four businesses per case; initial/closing cash, sales, paid inputs, actual/accrued/unpaid wages, distributions, input-expensed accrued margin, labor, inventories and last productive day |
| `M29_FIRM_DAYS.csv` | Each business/day; event-reconstructed cash/goods/cargo, cash minimum, accrued wage expense, claims, conditional future guarantees, headcount and production. Future guarantees are not accrued debt. Closing cash versus future guarantees describes coverage, not a forecast incorporating future revenue/inputs |
| `M29_DAYS.csv` | Day/cohort totals: resident meals/misses, owner/non-owner misses, immediate cash/stock blockers, visitor bread, actual wages, work/standby, circulation, output and household/firm/visitor cash |
| `M29_SHOPPING.csv` | Actual on-site bread/ale decision, own cash, need, shelf stock, price, bread price ceiling, purchased quantity, time and event ID; need limits bread to one/day and visitor spending remains ten coins across both items |
| `M29_MONEY_TRANSFERS.csv` | Successful native wage/distribution transfers with actual source, destination, purpose, amount, day/time and event ID; excludes creation-time cash ownership |
| `M29_FAILURES.csv` | Missed resident meal and immediate shopping-time blocker plus overlapping contextual flags; closing cash and income arriving after16:00 are separate evidence, never retroactive purchasing power |
| `M29_CONSTRAINTS.csv` | Grouped native/audit constraint flags by day/subject/evidence, original event IDs and related IDs; flags can overlap and are not exclusive macro causes |
| `M29_INPUT_ORDERS.csv` | Genuine funded own grain/flour whole-lot orders and linked receipts, requested/filled lots, quote/time and source IDs; an absent order is unknown supply |
| `M29_FORECASTS.csv` | Owner-local N/D/status/sample IDs, unchanged local demand forecast, selected headcount and compact candidate summaries at the frozen forecast event |
| `M29_TERMS.csv` | Actual three-day employment term histories, participants, timing, status and financial obligations |
| `M29_CAPTURE_MANIFEST.csv` | 96 verbose native payload filenames, byte sizes and raw/report/ledger SHA256; two distinct process captures per case |
| `M29_ARTIFACT_CHECKS.json` | Compact row-count and cross-table consistency checks against audited native reports |
| `M29_OUTCOMES.csv` | 24 thirty-day cases; aggregate food, labor, cash and output, owner/non-owner wealth, jobs/arrears and three ten-day meal windows |
| `M29_COMPARISONS.csv` | 36 matched contrasts, all values after minus before: three allocation contrasts per policy/condition plus B→I within each allocation. These are deterministic comparisons, not independent statistical samples or welfare scores |

Cash circulation counts existing coins changing hands and can exceed the currency
supply. Initial capital is not sales, wages or realized distributable income.
Margins expense purchases and accrued wages without inventory valuation; they
are not formal accounting profits. An active job at the terminal boundary may
start next day; it does not imply productive work that day. Visitor bread is
separate from the 450 resident meals needed per 30-day case. No 365-day outcome
is inferred.

`M29_EXPERIMENT_MANIFEST.json` pins the model/engine, exact reviewed base and
capture counts. The acceptance manifest, phase/test log, historical/control pins,
raw C/D source manifest and unchanged dependency maps record separate verification
costs and cache provenance. Cached immutable historical raw traces are audited
again; cached audit conclusions are never substituted for replay. See results
for commands and actual timings. Raw verbose traces remain outside git.
