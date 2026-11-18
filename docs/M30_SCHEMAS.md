# M30 evidence schemas

Read the [frozen institution](M30_DYNAMIC_WAGE_FEASIBILITY.md) and
[actual results](M30_RESULTS.md). These exports are offline research evidence;
competing asks, employer valuations, cross-household facts and final outcomes
never enter another NPC's observation. Historical schemas and files are retained.

`condition,arm,allocation,seed` identify a world. F=`fixed10_instrumented`,
W=`worker_bids`; `stratum` is core or household sensitivity. All cases use seed42.
The twelve long cases are four original-endowment conditions ×F/W plus two
household-cash conditions ×F/W. Twenty accounts contain9192 actual coins.
Owner wallets (Ada/Bram/Cora/Mara) stay distinct from firm treasuries.

Days/minutes/event IDs refer to that case's native trace. Never join event IDs
between worlds. Employment end days are exclusive: a day3 board successor
starts4 and ends7. An employment-start event at24:00 can authorize next-day work;
it is not an extra productive/paid day inside the reported horizon. Blank means
not applicable/unobserved, not zero. Nested CSV cells are JSON. Four larger
candidate/observation tables are **lossless gzip-compressed CSV**, with all rows
retained and deterministic compression metadata. Read them with Python
`gzip.open(path, 'rt')` and `csv.DictReader`; full verbose event traces are not
committed.

| Artifact (`M30_` prefix) | Meaning and grain |
| --- | --- |
| `RUNS.csv` | All28 cases/horizons; report/ledger hashes, food, work, actual wages, contracts, purchases, currency |
| `PERFORMANCE.csv` |56 distinct native processes; retained short-checkpoint timings explicitly marked reused; run/report/command/audit walls, process RSS KiB, worst headless appointment/tick |
| `PARITY.csv` |14 F comparisons retaining every original economic event/receipt and complete report after exact passive-event removal/ID remapping; raw instrumented and normalized ledger hashes differ honestly |
| `CONTROL_PINS.csv` | Frozen historical comparison provenance, including four short M28-derived controls that were not published as M29 cash-wrapper cells |
| `INITIAL_ACCOUNTS.csv` |240 rows: every actual account in twelve long cases, source initialization ID and initial coins |
| `RESIDENTS.csv` |180 resident/case rows: actual/accrued/unpaid wages, productive/standby attendance, food, ownership income, spending, final cash/goods |
| `FIRMS.csv` |48 firm/case rows: sales, inputs, paid/accrued wages, margins, distributions, guarantees, work/standby, last productive day and final inventories/capital |
| `RESIDENT_DAYS.csv` |5400 resident-days: opening/closing cash identity, earned salary/claim and final settlement, attendance, shopping-time cash/known bread quote/stock, affordability, actual consumption and later income provenance |
| `FIRM_DAYS.csv` |1440 independently reconstructed firm-days: cash minima, goods/cargo, active workers, due/payments/claims, future guarantees and production |
| `DAYS.csv` |360 day/cohort summaries: actual resident/visitor bread and ale, owner/nonowner missed meals, cash/stock blockers, money circulation, wealth and output |
| `SHOPPING.csv` |15120 actual on-site bread/ale decisions, own cash/need/price/shelf stock, time and purchase result; residents, owners and visitors labeled separately |
| `TRANSFERS.csv` |Successful authoritative wage/distribution payments, source/destination/amount/time and native event ID; initialization is not income |
| `MISSED_MEALS.csv` |1906 actual missed resident meals with audited immediate cash/stock blockers, overlapping context and later-income source IDs; late money is never backdated |
| `PARTICIPATION.csv` |3960 board worker-days, all eleven workers: actual presence/eligibility/current term, witnessed notices, own ask, research-only competing-applicant count/portfolio value/rank, offer/acceptance/next-day entry and reason |
| `WORKER_DECISIONS.csv.gz` |Full authorized own observation and no-income baseline at each board decision/passive F observation; own cash/quotes/history and selected ask, with source IDs; no employer-private data |
| `BUDGETS.csv.gz` |23780 wage/worker/meeting budgets, twenty per bidding decision; today's common shopping prelude plus three conditional future days, retained money and total utility. Source decision links the own observation and no-income baseline |
| `BELIEFS.csv.gz` |51560 personally visible notice/wage comparisons: own actual anchor, prior, completed comparable win/loss IDs, exact chance/score, gain and chosen flag |
| `FIRM_COMPARISONS.csv.gz` |7950 firm-stage portfolio rows: minimum-wage vacancy assessment, actual submitted selection and accepted midnight recheck; actual retained/proposed salaries, whole-input trajectories, contribution and current-cash front gate |
| `F_FIXED_ADMISSION.csv` |720 passive F firm-days; offline independent current-cash test of the **actual old ten-coin chosen headcount**, joined to native M28 projection and M30 observation IDs. This counterfactual guard diagnostic never vetoes an F hire |
| `NOTICES.csv` |All W actual public notices, legitimate quantity/terms/assessment and public closure count/status; actual applicant count is researcher-only |
| `BIDS.csv` |1189 actual W asks, original provenance, final status, actual hire and whether own outcome was observed before horizon. Submitted/unselected at an unfilled notice is unknown, not a witnessed auction loss |
| `TERMS.csv` |882 actual initial/successor terms; wage, employer, predecessor, exclusive interval, closure and status |
| `WAGE_STATS.csv` |36 denominator-explicit summaries: paid claim-worker-days' agreed nominal wages; positive cash-receipt worker-days; equally weighted paid individuals' mean nominal wages. Each includes count, distinct paid workers, mean/median/range |
| `WAGE_SPELLS.csv` |81 maximal consecutive calendar earning spells strictly below threshold6 or10. Unemployment/no earned claim is excluded. No below6 spells occur in automatic runs |
| `WORKER_CYCLES.csv` |132 named-worker/case histories: successor terms, same-firm uninterrupted renewal, return after gap, employer switch, actual filled-notice losses, hire dates and wage path |
| `CONCENTRATION.csv` |36 share/HHI rows over eleven workers' paid wages, four employers' paid wages and productive work. HHI uses sum of squared shares; it is descriptive, not a welfare index |
| `INPUT_ORDERS.csv` |842 genuine positive funded input orders with lots/receipt IDs and actual fills; no order means unknown supply |
| `OUTCOMES.csv`, `COMPARISONS.csv` |Twelve long-case totals and six matched W−F contrasts, including ten-day meal windows. Initial three full daily economic results match in every pair |
| `CAPTURE_MANIFEST.csv` |56 lossless compressed native payload filenames, compressed-byte/report/ledger hashes; timings excluded from canonical report/event equality |
| `AUTHORITY_FIXTURES.json` |Three separately labeled technical witnesses: lawful10/8/5 terms, real partial5 claim paid2/owed3 surviving expiry, genuine no-show with zero unearned salary |
| `ARTIFACT_CHECKS.json`, `EXPERIMENT_MANIFEST.json` |Row counts/cross-table identities and exact model/engine/base/capture counts |

Participation reasons distinguish locked terms, absent/unobserved vacancies,
unaffordable projected commitments, no strictly positive marginal gain at the
requested wage, higher-value competing portfolios and exact financial ties.
`financial_value_rank` ranks the best admissible portfolio containing that worker
against distinct feasible financial values; it is **not** a revealed worker
ranking or a worker observation. Full candidate rows remain the authoritative
financial comparison. F keeps its old matching/rotation institution, so its
unselected application reason is conservatively combined, not relabeled as a W
wage auction. The eleven board workers exclude management-only owners.

A paid claim-worker-day is counted if its **real earned claim received any money**
by the horizon; its nominal wage is the full promised amount. Actual cash receipt
days can include earlier arrears, so their mean is a cash-flow statistic rather
than a wage rate. All matrix claims are fully paid; the partial technical witness
is separate. An earned wage below6 does not itself prove a missed meal: compare
actual savings, shelf stock, shopping cash, price, and consumption.

Conditional household budgets assume goods availability for affordability only;
no stocks/reservations are created. Three-day firm valuation conservatively
continues retained salaries, while legal future guarantees cover only the actual
remaining term. Inventory-purchase-expensed margins are not formal profit with
inventory valuation. Circulation counts coins changing hands and can exceed9192.
Final jobs can start on day31 and do not prove activity beyond day30.

The acceptance manifest, commands/phases, complete suite logs, pinned historical
controls, C/D dependency proof and independently rerun original audits document
verification separately from isolated comparative run costs. Raw immutable
historical C/D evidence may be reused only with exact dependency/engine/build and
published payload hashes; cached audit conclusions are never reused.

The six-entry belief memory retains informative completed own outcomes only;
unknown cancellations/unfilled notices remain in the underlying bid/closure
records but add no Beta evidence. This is a bounded evidence window, not a
rolling six-day market-rate estimate.

Raw capture-byte hashes identify the archived measured payloads; timings and
compression headers need not reproduce. Deterministic replay compares full
canonical economic events/reports and their ledger/report hashes.
