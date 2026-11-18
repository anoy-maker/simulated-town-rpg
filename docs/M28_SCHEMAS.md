# M28 evidence, units and evaluation boundaries

See the [frozen protocol](M28_INPUT_FEASIBILITY.md) and [results](M28_RESULTS.md).
All files are researcher outputs. Global reports, private shopping money and
M27's diagnostic state are never supplied to an NPC.

## Source and denominators

Base: `e735df8cf3dd46fe32f2bee5b22f2b366cc70d73`. The main matrix has24 cases:
four conditions × two arms × horizons1/3/30, with two fresh native processes per
case. The32 short captures were first made at checkpoint and reused in the final
driver after source/engine fingerprints and both full replays were checked.
The16 main30-day captures and8 staggered sensitivity captures were fresh.

Primary30-day outputs have8 cases,240 village-days and3,600 resident meal needs.
The separately labeled staggered endowment has4 cases,120 village-days and1,800
needs. Never pool these as a treatment/control contrast. Every case has15 residents
and four firms. Native condition names are `reference`, `tight`, `scarce`,
`no_brew_request`; their caps are21/19/16/21. Arms are the full native names
`R_baseline_instrumented` and `R_input_aware`. `fixture=none` means main endowment;
`fixture=staggered` means the preserved alternate initial term dates.

Goods, lots, workers and coins are integers. Mill/bakery input lots contain5
wheat/flour respectively; brewery lots contain3 wheat. `requested` in M28's
**input** tables means whole lots, unlike M26/M27 order-unit tables. There is one
daily meal need/resident. Visitor bread and discretionary ale are separate.
Blank/not-applicable, `unknown`, `prior_only`, and measured zero are distinct.
JSON arrays/maps inside CSV cells retain explicit source references and stocks.
Event IDs are one-based within a particular full native trace and its ledger hash.

## Native local evidence

The world stores own input receipts only after an original validated grain/flour
`demand_order_observed` event. It records no failure sample for an unplaced,
unfunded, remote, stale or illegal order. Requested and filled units must divide
exactly into their actual lot size; fills are real ownership transfers linked to
native purchase receipts. Entirely rationed positive requests can have an empty
successful-receipt list. Duplicate order/day or receipt IDs cannot become extra
samples. Entrusted own accounting does not require retail-owner coverage.

At15:55 the estimator gets only the owner's same-day inspected input terms and
that buyer's prior completed-day records, filtered by supplier/item/price. The
current morning's receipt is excluded. Up to three eligible days plus optimistic
prior K yield exact `numerator=N`, `denominator=D`; no sample gives K/K. Farm is
`inapplicable` with0/0, never a zero-reliability supplier. Missing inspected terms
give `unknown_quote` and baseline behavior. Baseline bookkeeping estimates N/D
passively; only treatment uses it to limit projected procurement. Midnight uses
the meeting-frozen estimate and independently rechecks actual cash/legal capacity.

No return value is a reservation, future order or available coin balance.
`input_projection.gd` charges predicted input purchases, produces from owned plus
predicted inputs only, and retains all30 coins of promised wages per employee.
`input_audit.py` reconstructs native provenance through the original audits and
checks projection output with a separate analytical shift bound and integer
quotient/remainder rounding. The M27 observer checks real cash/goods/cargo/debt.

## Published tables

| Artifact | Grain and interpretation |
| --- | --- |
| `M28_RUNS.csv`, `M28_STAGGERED_RUNS.csv` |24/4 case summaries with canonical new report/ledger hashes, production, meals, employment flows, wages, purchases, circulation and active jobs. |
| `M28_PARITY.csv`, `M28_STAGGERED_PARITY.csv` |12/2 instrumented-baseline comparisons against the pinned original R. Only M28 bookkeeping is removed; all original events, failures, states, obligations, reports and receipt links must agree. Raw new/old hashes are retained separately. |
| `M28_REFERENCE_PARITY.csv` |All three input-aware reference horizons likewise match complete original R economics after removing only the new bookkeeping. |
| `M28_PERFORMANCE.csv`, `M28_STAGGERED_PERFORMANCE.csv` |48/8 process rows; original native run/command/report time, peak RSS, event count, worst appointment/tick and fresh audit wall. `reused_checkpoint` identifies the32 short captures, not cached audit results. |
| `M28_BELIEFS.csv` |1,440 rows:12 cases ×30 days ×4 firms. Exact K/N/D, source sample days/order IDs, inspected quote and native frozen-estimate event. No ratio is presented as a posterior or guaranteed allocation. |
| `M28_CANDIDATES.csv` |9,654 candidate/projected-day rows. Each decision day has the original retained-through-capacity candidate search. `headcount`, contribution, receipts, inputs, feasible and cash are full-term summaries. `term_guaranteed_wages` covers three days; `guaranteed_wages` is that projected day's amount. `desired_lots` precedes the cap; `predicted_lots` is the actual modeled procurement after rounding. `chosen` identifies the selected candidate, not an executed production plan. |
| `M28_INPUT_ORDERS.csv` |994 genuine buyer-owned daily input receipts with whole requested/filled/rationed lots, exact quote and native inspection/order/purchase provenance. Absence of a row means unknown supply, not verified zero fulfillment. |
| `M28_FIRM_DAYS.csv` |1,440 actual firm-day rows, with opening/closing goods/cargo/cash, produced/consumed/purchased/sold goods, wages/accruals/arrears, productive/standby shifts, operating cash, future terms, own order status and frozen estimate. A missing eligible order has blank requested/filled/rationed fields. |
| `M28_BUSINESSES.csv` |48 final firm summaries with revenues, input purchases, accrued/paid wages, distributions, cash, inventory, productive/standby shifts, future guarantees and last productive day. Accrued margin expenses input purchases without inventory valuation; it is not formal inventory-valued profit. |
| `M28_FOOD_DAYS.csv` |5,400 actual resident-day rows: validated shopping-time cash, need, quote, stock, purchase and source event, wages/distributions, actual meals/misses, closing cash and immediate blocker provenance. Closing money cannot retroactively buy food. |
| `M28_RESIDENTS.csv` |180 final resident summaries, including wages, ownership income, paid attendance/standby, food/ale spending, meals/misses, cash and owned goods. |
| `M28_DAYS.csv` |360 actual village-day rows, separating resident meals, solvent stockouts, shopping-time poverty, visitor bread, ale, production, paid standby and circulation. |
| `M28_FAILURE_ATTRIBUTIONS.csv` |880 missed-meal observations across the explicitly labeled main and sensitivity cases. The M27 direct immediate blockers retain native sources; they are not exclusive macroeconomic root causes. |
| `M28_TERMS.csv`, `M28_BALANCES.csv` |Actual immutable term histories and final household/business/external coin distribution, owner/employee cash and richest resident cash. Do not treat concentration or any other column as a single welfare score. |

In balances, `employee_cash` covers all eleven non-owner resident households,
including people currently unemployed; it is not restricted to active employees.

Every real movement conserves9192 coins and valid custody. The inherited M27
firm-day source/sink and wage identities still hold; unknown future guarantees
are conditional promises, not current debt or coins. Temporary native traces
remain outside git, not verbose annual dumps.

## Conditional input-forecast evaluation

`M28_INPUT_EVALUATION.csv` contains1,044 opportunities:12 cases ×29 next-day
comparisons ×3 input-buying firms. Use the chosen candidate's first projected
day, then compare only a genuine next-day positive eligible order with the same
supplier/item/price **and same desired whole-lot quantity**. The published error
is predicted filled lots minus actual filled lots. Other projected days are not
scored against unobserved counterfactual futures.

An absent order is `unknown_no_eligible_order`; changed quantity/quote and unknown
quote are explicit exclusions. No order is manufactured to score the forecast.
Coverage and signed/absolute errors describe a selected endogenous subset whose
composition can differ between arms. A lower error sum is not a matched statistical
accuracy improvement, latent-supply RMSE or perfect-expectations certificate.

## Historical verification and cost manifests

`M28_EXPERIMENT_MANIFEST.json` preserves primary/sensitivity source/engine
fingerprints and measured driver walls. Final acceptance artifacts separately
record full native/Python suites,169 payload pins,88 published historical pairs,
36 fresh M26 runs, unchanged M27 diagnostic/proof digests, original C/D audits and
isolated smoke. The C/D dependency/build manifest discloses reused pinned native
traces; all independent audits run again. Overlapping verification walls must
not be summed as total elapsed development time or simulation-only cost.

`M28_PYTHON_SHARED_HOST_FIRST.txt` retains the initial133-method attempt with its
one old timing-challenge failure. `M28_QUEUE_DEPENDENCIES.json` checks the unchanged
eleven-file queue model. Final suite/isolated queue results are separate in
`M28_TEST_LOG.txt`; the phase CSV deliberately retains the initial nonzero status.
A later successful isolated run does not erase the earlier failure or establish
robustness of that completion-order timing assumption under arbitrary contention.
