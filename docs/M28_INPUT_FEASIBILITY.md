# M28 — Frozen own-input reliability experiment

Issue #41; exact base `e735df8cf3dd46fe32f2bee5b22f2b366cc70d73` on
`codex/m27-economic-diagnostics`, verified against the remote head. Work branch
`codex/m28-input-reliability`. Commit this protocol before comparative outcome
runs. No M29, merge, default adoption or post-result parameter tuning.

## Hypothesis and isolation

Does a firm's own history of genuinely funded input orders improve its three-day
employment projections, and what happens to household income/food if it declines
more renewals? More cash or less standby alone is not economic success.

Use an isolated `settlement_input_reliability` scenario with two arms:

- `R_baseline_instrumented`: unchanged M26 `requests_smoothed` decisions. Added
  own-input records and forecast diagnostics are passive.
- `R_input_aware`: identical demand estimate, current assignment, purchasing,
  transactions, employer objective, headcount candidates and tie order; only
  prospective new input lots in the existing renewal projection are limited.

Keep fifteen residents, four owners/firms, eleven initial three-day terms,
all initial cash/goods, prices2/5/6/4, wage10, recipes, targets21/15/21/12, installed
slots3/3/3/2, cap conditions21/19/16/21, appointments, grain clearing, real custody,
claims and distributions. Total coins remain9192. Farm has no purchased input.
Historical worlds and CLI defaults remain unchanged. No Rust or generic optimizer.

Small implementation boundary: a default-preserving renewal-calculation hook,
with an optional pure forecast callable in the existing bounded headcount solver.
The historical forecast remains the default. The new world supplies the callable
only in the treatment. Financial authorization at midnight uses the same frozen
meeting estimate, with actual funds/capacity/claims rechecked as before.

## Knowledge, receipts and completed days

Use the existing native `demand_order_observed` grain/flour receipts, backed by
real physical requests, inspected quotes, eligible funded quantities and actual
purchase/clearing links. Buyer-owned input evidence is distinct from the seller's
inbound-demand book. For mill/brewery read only that firm's own wheat receipt;
for bakery read only its flour receipt. A valid zero fill is evidence only when
a genuine positive authorized funded order existed. No invented request or
assumption from a supplier visit, missing order, closed shop or no employment.

Store requested/filled/rationed whole lots (sizes mill5 wheat, brewery3 wheat,
bakery5 flour), owner, supplier, item, posted quote/price, day/minute, inspection,
native order and actual receipt IDs. Deduplicate order keys and purchase IDs.
Invalid, remote, stale, late and unfunded attempts do not create samples. Native
authority validates eligibility; an independent Python observer must reconstruct
it from the underlying native events rather than trust the new record.

At15:55 use the owner's genuinely inspected input terms, retained by the existing
M24/M26 quote interface. A fresh same-day inspection is required for a new
estimate; missing inspection/quote yields unknown and baseline behavior. Do not
replace the remembered price with unseen live supplier state. Fixed experimental
quotes do not change intraday; separate stale/changed-price fixtures test filtering.
No supplier private stock/cash, competitor request, future receipt, visitor budget,
other firm's history or M27 omniscient result enters the observation.

Select at most the last three comparable **completed calendar days**, `day<t`:
same buyer, supplier, input product and exact posted unit price, positive eligible
request. Thus today's already-completed morning purchase is recorded but excluded
from today's15:55 estimate. A day without a valid positive order is unknown, not a
zero-supply observation. Keep chronological day/order-ID ordering and one sample
per genuine daily procurement order. Later17:00 traffic and19:00 income cannot
refresh the15:55 estimate. Reuse the frozen estimate at24:00.

## Frozen integer mathematics and financial timing

`K` is full-target input lots, bounded by installed positions: mill3, bakery3,
brewery2. The optimistic one-pseudoday prior is a model assumption, not stock.
For selected samples `(r_t,f_t)`, `N=K+sum(f_t)`, `D=K+sum(r_t)`; preserve exact
integers, `0<N<=D`. With no sample, `N=D=K`, exactly baseline. Farm is inapplicable.
This is an endogenous bounded fill-rate heuristic, not a Bayesian posterior,
independent-lot process or perfect rational expectation.

For each candidate and each of three projected days:

1. Retain the original cash, output/carry inventory, owned raw inputs, daily cap,
   demand and guaranteed headcount. Reserve all ten-coin wages before procurement.
2. Run the original full-availability plan to determine new desired whole lots `k`
   under that projected day's actual model inventory and cash.
3. Limit new lots to `k_pred=(2*k*N+D)//(2*D)`, clipped to`[0,k]`. Exact integer
   half-up rounding; zero stays zero. Bound operands before multiplying. Native
   main values have at most3 lots and at most12 denominator units; guards reject
   malformed/overflowing ratios, never wrap or create availability.
4. Add only those predicted lots to **owned inputs**, charge their genuine quoted
   input cost, then run the original production planner with further procurement
   disabled. Owned input stock is never discounted. Production/receipts/remaining
   stock must follow only from these available inputs and installed staff/targets.
5. Pay all guaranteed wages even for projected standby; retain the original
   three-day sales order, cash-feasibility tests, arrears deduction and objective.

`N=D` or inapplicable/no history must reproduce **every** original candidate
summary, all three cash/wage trajectories and tie choices, not just headcount.
The policy neither reserves future goods nor issues real transactions. Actual
current-term assignment still excludes already committed wages from marginal
cost; prospective guarantees always include30 coins per candidate employee.
No future-today sales become actual spendable money, no unpaid claim disappears,
no midterm employment or wage rule changes, and no late information is fitted.

## Fixed matrix, diagnostics and evaluation boundary

Main: reference/tight/scarce/no-brew × two arms ×1/3/30 days ×seed42 ×**two fresh
processes**,24 cases/48 captures. First run the1/3-day checkpoint after focused
fixtures. Immutable checkpoint captures may populate the final matrix only when
all source/engine/command fingerprints and both complete report/event replays
are unchanged; otherwise recapture. Never reuse one process as two repeats.
Also run the separately labeled historical staggered initial1/2/3-day-term
sensitivity: tight/scarce ×both arms ×30 ×two processes,4 cases/8 captures. Do
not pool its different legal endowment with the main comparison.

All12 main baseline cases must match the original pinned M26 R economics:
every retained native event/action, renamed receipt linkage, state, accounts,
obligations, production and daily results. Added input-only bookkeeping can change
raw hashes; publish both, remove only that bookkeeping for parity. Preserve
original scenario reports/ledger hashes directly as separate controls.

Report per firm/day input requested/filled/rationed lots or unknown, sample IDs,
N/D, candidate/projected-day k/k_pred, production, revenue/input expense, wages,
standby, treasury, distributions, terms and inventories. Report all15 residents'
shopping-time cash, legitimate unfilled bread requests, actual consumption and
missed meals. Use M27's offline observer for goods/cargo/cash/debt identities and
immediate blockers; its global truth never enters policy. Compare visitor bread/
ale, last productive day, active jobs, concentration and circulation separately.

Score prior next-day input predictions only when a new genuine positive valid
order exists at the same supplier/item/price **and desired lot quantity** as the
forecasted day-one purchase. Publish coverage, exclusions and signed/absolute
whole-lot error for this selected endogenous subset. No request is unknown, not
a forecast failure; no hidden hypothetical allocation or latent-demand RMSE.
Deterministic repeats are not independent statistical worlds.

## Focused fixtures and final acceptance

Before long outcomes: absent/full history identity for all candidates; exact
full/partial/zero fills across all three lot sizes; last-three selection; half-up
ties and overflow guards; zero/unobserved orders; cashless/late/stale/remote/
illegal/changed supplier/item/price and duplicate receipts; owned raw inventory
under poor history; full guaranteed standby cost versus current marginal wage;
morning receipt embargo, farm invariance, native grain competition and reference.
Include real native read-only provenance cross-checks and rehashed forgeries,
not only pure estimator arithmetic fixtures.

After the last meaningful source edit, once: full Godot/Python suites,169 historical
payload pins,88 published M23–M25 pairs, all36 M26 main pins and parity, additional
M26 controls, M27 passive replay/checkpoint certificate preservation, original
12 C/D audits and isolated M22 smoke. Reuse unchanged pinned raw traces only with
explicit provenance; rerun independent audits. Record capture/run/report/audit
cost, RSS, phase walls and advisory warnings without summing overlapping phases.
Run comparative performance captures without concurrent verification.

Deliver compact input beliefs/candidates, firm-day and resident/food diagnostics,
historical verification manifest/logs, commands and `M28_RESULTS.md`. Update the
research index with one measured M28 row only after reviewing actual outcomes.
Keep negative and contrary findings. Separate proved accounting/provenance from
bounded forecast heuristics and unknown future outcomes. Stop for review after
M28; no M29, wage/price changes, debt, rescue, new sectors or baseline adoption.
