# M27 diagnostic artifacts and units

These are offline researcher outputs, never NPC observations. The frozen source
is `2bc13ef8ca92809a77eaf78a47168d97fd8bf939`, with simulation tree
`52825d822ec952b9981c6431d2657aa44c5bff87`. The independently audited full native
trace is the primary evidence; CSV totals alone cannot establish a transaction.
See [protocol](M27_ECONOMIC_DIAGNOSTICS_FEASIBILITY.md) and
[findings](M27_RESULTS.md).

## Keys, units and missing values

Unless stated otherwise, tables use seed42 and all twelve main combinations:
four conditions × three arms. L/S/R abbreviate `legacy_instrumented`,
`sales_smoothed`, `requests_smoothed`. Main conditions retain the same initial
endowment and binding terms; staggered maturities are historical controls only.
`days` is the run horizon; `day` is the within-run day. Minutes are integer minutes
after midnight. Native event IDs are one-based within the particular trace;
combine them with condition/arm and the report/ledger digests in `M27_CASES.csv`.

Money is whole coins, goods are whole units, labor is completed one-hour shifts.
One resident bread consumption is one meal; there are15 resident meal needs/day,
450 per30-day case. Visitor meals are separate consumption opportunities, not
resident obligations. JSON objects/arrays are encoded inside CSV cells. Zero is
measured zero. Empty inapplicable columns are not zero; `unknown`, `unobserved`
and `unproven` are explicit epistemic labels. No latent demand estimate is made.

## Actual observations

| Artifact | Grain and meaning |
| --- | --- |
| `M27_CASES.csv` |36 pinned run records: four conditions × three arms × horizons1/3/30. Report and ledger SHA256, diagnostic digest, read-only/replay/full-audit checks. `cached` refers to final reader input reuse, not a skipped audit. |
| `M27_FIRM_DAYS.csv` |1,440 rows:12 runs ×30 days ×4 firms. Opening/closing owned warehouses and cargo; per-item production, recipe inputs, purchases and sales; actual cash, sales receipts, input expenditure, paid/accrued wages, arrears, distributions, productive/standby/eligible workers, installed slots. `produced` counts the firm's output commodity. |
| `M27_ORDERS.csv` |2,366 groups by run/day/minute/seller/buyer-or-cohort/item/kind/quote. `requests` counts native legitimate order receipts; requested/filled/unfilled count commodity units, not whole-lot counts. Grain lots are5 wheat for mill and3 for brewer; flour lots are5. Paid coins equal filled units × validated quote. Source IDs preserve actual request and receipt provenance. |
| `M27_COHORT_DAYS.csv` |1,440 rows:12 runs ×30 days × resident/visitor × bread/ale. Visits, positive intent counts, requested/filled/stockout-unfilled units, unaffordable visits and actual consumption. Seller coverage/censoring is retained. An unaffordable visit is not a positive request. |
| `M27_CASH_TIMELINES.csv` |2,955 checkpoint rows, **only days1 and3** of the30-day runs. Actual money transfers show payer before/after and recipient before/after; planning and shopping rows show independently validated observed cash. Claim accrual/application and future guarantees are liabilities/promises, not extra coins. Distinct row kinds can describe the same transaction; never sum every `coins` column as separate flow. |
| `M27_CONSTRAINTS.csv` |6,251 grouped run/day/subject/flag/evidence/item rows. Event IDs, related sources, actors and first/last minutes retain provenance. Flags overlap and their count is neither lost output nor an exclusive root-cause total. A direct policy-reason event proves the recorded reason, not realized profitability. |
| `M27_FAILURE_ATTRIBUTIONS.csv` |1,170 actual missed resident meals. Immediate blocker uses validated shopping-time cash, need, shelf stock and legitimate intent. Secondary flags can overlap. Closing cash and transfers after16:00 are contextual evidence, never earlier purchasing power. `late_income_coins` includes any such incoming money transfer; separate native IDs establish its actual time and purpose. |

Firm-day checks explicitly assert, for each good:

```text
opening warehouse + opening cargo + produced + purchased − recipe inputs − sold
    = closing warehouse + closing cargo
closing cash = opening cash + sales − input spending − paid wages − distributions
opening arrears + accrued wages − paid wages = closing arrears
```

`minimum_cash` is the actual minimum across opening funds and outward transfers.
`cash_operating_flow` excludes distributions. `accrued_input_expensed_margin`
subtracts input purchases and earned wages from sales; it is not formal profit
with inventory valuation. `future_guarantees` is compensation conditional on
future attendance under the terms actually active after the24:00 boundary,
including accepted successors. Its event/minute fields identify that checkpoint.
Future guarantees are not earned arrears or additional currency. The independent
inherited audit checks every native movement and claim, including intermediate
states, beyond these daily identities.

The nine flag names are declared in `economic_diagnostics.FLAGS`. No main-run
`timing_working_capital` flag fired; this is distinct from whether that mechanism
could bind in another economy. Negative fixtures exercise it. `evidence` is
`direct`, `inferred`, `ambiguous` or `unknown`; actual generated flags need not
populate every category. Unknown latent demand is never replaced by zero.

## Alternatives and certificates

`M27_PHYSICAL_WITNESSES.csv` contains48 rows:12 cases × day1/day3 × two tiers.
`fixed_orders` retains actual eligible grain/flour ceilings;
`voluntary_orders` enumerates alternative whole-lot requests. Both keep actual
held stocks/cargo, quotes, native clearing, installed assets, named active workers,
contracts and physical routes. Both initially relax money, customer choices and
own-profit/request-policy gates, so their physical label is `relaxed_potential`.

`bread_at_shop` includes carried bakery bread; `bread`/`actual_bread` are daily
production. The physical objective is bread stock before16:00, followed by ale,
fewer productive shifts, and fixed lexicographic order. The independent checker
derives an upper bound over the **declared one-day physical space** separately
from the generator. `certified_optimum` never means financed or30-day optimal.
The resident delivery ceiling is a physical ceiling with customer choices and
cash relaxed; the route proof supplies named bodies and site/time checks.

`finance_witnessed=True` proves a constructive **one-day** lower bound using
existing cash, legally earned guarantees and only actual positive customer
request evidence. It does not maximize meals or finance future renewals.
`resident_meals_witness`/`visitor_meals_witness` report that execution. All
`incentive_compatible` and financial-optimality claims remain `unproven`.
`current_policy_quantity_agreement` merely compares observed request/headcount
choices, not beliefs or the rationality of alternative choices.

`M27_CERTIFICATES/` holds16 complete representative L certificates, all four
conditions × two days × two tiers, selected independently of outcome. Each has
source hashes, snapshot/evidence hashes, proposal and recomputed proof, including
named workers, paths, whole-lot allocations, per-step goods and cash, earned claims
and remaining debt. Financial step inventory/cargo maps are sparse: an omitted
cell is **exact zero** over the declared holders/items. Cash maps are dense.
`M27_CERTIFICATE_INDEX.csv` hashes the complete examples; all48 primary proofs
were rechecked, including the uncommitted reproducible S/R examples. Certificate
filenames for S/R refer to the transient experiment output, not committed files.

The checker re-audits a pinned trace and reconstructs its snapshot; a self-hashed
arbitrary starting snapshot is not an authority certificate. It then recomputes
and exactly compares the claimed proof. Unsupported funding yields `unproven`,
not a proof that no alternative exists. `M27_CONDITIONAL_WEDGES.json` contains
separate **if-sold** arithmetic; it is not actual buyer demand or a contract offer.

## Verification and cost evidence

`M27_CASE_MANIFEST.json` separates original native capture/parity from the final
reader replay. `M27_LEGACY_PARITY.csv` records12 M25/M26 normalized comparisons.
`M27_PERFORMANCE.csv` measures final passive replay; native timing/RSS cells are
retained original capture measurements. `M27_CAPTURE_PERFORMANCE.csv` records
the original phase, including which native captures were reused from the earlier
checkpoint. Reader RSS is the cumulative process high-water mark, not isolated
per-case allocation. Cache read/parse and CSV serialization are outside individual
analysis timers; command wall includes them. Shared-host timings are verification
costs, not controlled simulator-speed comparisons.

The final acceptance manifest, phase CSV, historical pins, historical controls,
original C/D source and audit manifests, test log, and isolated smoke remain
separate artifacts. Raw full-event traces stay outside git; reproduce them with
the unchanged capture commands. No annual verbose dump is committed.

`M27_REGRESSIONS.csv` contains169 original payload pins and actual byte hashes;
`M27_HISTORICAL_CONTROLS.csv` contains88 independently matched historical report
and ledger pairs. `M27_EXTRA_M26_CONTROLS.csv` has four staggered main controls
and four observation fixtures. `M27_CD_SOURCE_MANIFEST.csv` declares the twelve
reused native source files/digests; `M27_ORIGINAL_AUDITS.csv` records their fresh
original-auditor passes, not cached audit outcomes. `M27_TEST_LOG.txt` preserves
the native/Python/focused and standalone-check output.

`M27_VERIFICATION.json` records source checksums, exact base/implementation,
counts, commands, host/native build digests and actual phase statuses.
`M27_VERIFICATION_PHASES.csv` adds the final smoke phase; the smoke's embedded
phase list necessarily predates its own measured completion.
`M27_SMOKE.json` retains the unchanged M22 guardrail definitions and reference
comparison. `M27_READER_COST.json` is one isolated reference/L30-day offline
reader/replay/proof cost sample, including parse time and process RSS; it is not
a comparative speed benchmark or claim about NPC response time.
