# M26 preregistration — seller-local demand and three-day contracts

Issue #37; base `6b344dd5faec2edce80dd703d748c7ba6be9b799`.
Frozen before experimental outcomes. No price, wage, recipe, target, body,
route, appointment, capital, contract, worker incentive or financial objective
changes. All main runs use M25 matching and 9192 conserved coins. This is a
bounded smoother experiment, not the M18 Bayesian price model or a Rust port.

## Evidence and authority

At an existing shop visit the buyer computes the unchanged basket on its own
information. If that item's quoted stock is zero, a second *intent* calculation
permits one unit hypothetically available at the actual active quote. It changes
neither utility nor affordability, allowance, ceiling, money or actual stock.
A positive item choice discloses only buyer/item/quantity/seller/quote and native
inspection provenance. The ordinary purchase command then succeeds or rejects;
stockout requests do not transfer anything. Stocked buying remains identical.
The private consumer decision remains private audit evidence, never seller input.
An inspection alone is not a request. Repeated same-day buyer/seller/item/quote
visits are deduplicated. Already used bread/ale allowances remain binding;
visitors retain the combined ten-coin actual expenditure limit.

Farm orders are the existing physical 10:10 grain requests, capped by the
existing authority's funded worker/input budget and profitable procurement
proposal. Actual clearing determines filled versus rationed whole lots. The
public order book discloses that validated quantity, not buyer cash/payroll.
Mill orders are the real 12:10 flour plan and actual whole-lot purchase attempts;
only funded profitable quantities supported by that native plan count. Invalid,
cashless, stale, remote and late orders supply no unfilled demand. Sellers never
receive downstream bread demand, private customer money, budgets, preferences,
global visitor counts or future arrivals.

All native sales enter the entrusted own-firm register. Direct requests enter
the entrusted order book even if the owner is away; owner-on-site witness IDs
are separate. Five-minute clock intervals independently record owner coverage
through each existing public trade window. A complete window requires an active
unchanged quote and owner presence throughout; otherwise it is partial. An
inspection at empty stock or a rationed request adds censorship. Books retain
real lower bounds, not inferred latent customers. A day is eligible if the quote
remained active/unchanged and either the window was complete or at least one
credible positive order/sale was recorded. Thus a witnessed zero-interest full
window is zero; an unwitnessed empty/closed window is unknown. Partial days with
credible interactions are explicitly low-biased censored samples, in both arms.

## Frozen estimator and timing

`legacy_instrumented` uses exactly M25 yesterday sales/initial target.
`sales_smoothed` and `requests_smoothed` select the same last at most three
eligible **completed** days at today's exact posted price. For each, s is native
fulfilled quantity; u is deduplicated credible requested quantity unfilled due
only to stock/rationing. Sales control uses q=s; request treatment q=s+u.
With T the unchanged own output target, compute integer
`min(30, max(0, (T + sum(q) + n) // (1+n)))`, i.e. ceiling with exactly one
pseudo-day, n=0..3. No sample gives T. No hidden demand truth is used.

The 15:55 meeting alone refreshes forecasts from completed days. The unchanged
M25 `binding_policy.forecast()` and renewal solver consume this demand point;
remaining-today sales use the same expression with the substituted point and
legitimate today-so-far own sales. No 17:00 visitor or 19:00 information enters
15:55. Subsequent meeting validations reuse the same frozen demand estimate.
Financial candidate ties still prefer fewer commitments. No forced hiring.
The inherited midnight entry validator still rechecks actual funds and capacity;
it reuses the meeting-frozen demand point without fitting later retail outcomes.
An already recorded positive buyer/day/offer is rejected on repeat, rather than
creating a second commitment or a second unfilled-demand observation.

## Frozen verification and experiments

M25 matching reference21/tight19/scarce16/no_brew_request at 1/3/30 days seed42
retain exact published report/ledger pins. All twelve new legacy cases must
match economic actions/state/accounting after removing observation-only records,
empty-stock rejected requests and renumbering receipt links (never assert equal
new observational ledger hashes).

Run three arms × four conditions × 1/3/30 days, twice in fresh processes;
independently audit all 72 captures and full report/event replay. Staggered
initial 1/2/3-day terms: tight/scarce × legacy/request arms ×30 days ×two; clearly
separate legal endowment. No policy tuning after viewing outcomes.

Focused native witnesses cover solvent bread/ale stockout, insolvency, stocked
refusal, partial/full coverage and true zero, inspection without intent, stale
quote, duplicates, shared visitor allowance, funded/rationed grain21/19/16,
flour shortage, invalid/cashless/remote B2B and post-meeting visits. Labeled
fixture endowments reconcile goods and 9192. Independent Python reconstruction
checks public schemas, witnesses, quotes, request legitimacy/deduplication,
coverage/censorship, exact estimator/future embargo, original renewal arithmetic,
contracts/payroll, physical custody, all commodities and currency at every move.
Rehashed forgeries target each of those boundaries.

Measure each arm's 30-day run/command/report/RSS/event count, audit cost and
worst appointment/tick; no concurrent verification during benchmarks. Targeted
tests, three-day checkpoint, then one full historical acceptance: full native
and Python suites, 169 pins, published M23/M24/M25 controls and fixtures, fresh
C/D audits, M22 smoke. Retain compact logs/tables, not full-year event dumps.

Evaluate resident versus visitor meals, output, zero-production/stalls, employment
flows/standby/arrears, individual and firm cash. Distinguish consumer insolvency,
stock rationing, operating/input shortages, demonstrably underestimated observed
lower bounds and cautious lawful nonrenewal. Only complete uncensored windows
support exact request point errors; censored samples support lower-bound error,
never latent-demand RMSE. More resident sales by displacing visitors alone is not
greater output or established welfare. Stop M26 for review, no dynamic wages,
adaptive prices or M27.
