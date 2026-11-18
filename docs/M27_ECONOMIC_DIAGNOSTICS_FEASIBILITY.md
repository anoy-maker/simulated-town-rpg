# M27 preregistration — read-only economic diagnostics

Issue #39. Exact base/source: `2bc13ef8ca92809a77eaf78a47168d97fd8bf939`
on `codex/m26-demand-observation`; work branch `codex/m27-economic-diagnostics`.
Committed before new diagnostic comparisons. No Godot world, policy, quote,
contract, initializer, event, report or historical pin changes are planned.

## Meanings and information boundary

`actual` means an audited native event/outcome. `witnessed_feasible` means a
complete explicit alternative verified in its declared tier, not a prediction
of agent choice. `certified_upper_bound` and `certified_optimum` require a
proved bound/exhaustive declared search. `relaxed_potential` removes explicitly
named constraints and is not an actual reachable outcome without further proof.
`unproven` means a proposed property lacks a certificate; `unknown` means the
available data/calculation cannot answer; `unobserved` means no recorded evidence.
They are never substituted with measured zero. A `cause` is an immediate
evidence-supported blocker, permits overlapping contributors and `unresolved`,
and does not promise the counterfactual economy would succeed.

The diagnostic is offline Python only. Global cash, terms, positions and private
shopping-time funds are researcher inputs, never NPC observations, seller belief
records or renewal-policy inputs. Existing DemandAudit/BindingAudit replay is
reused; no report aggregate is accepted as proof of transactions. The analyzer
must leave its input data byte-canonically unchanged.

Four separate questions: integer bread supply, physically deliverable bread at
the resident shopping window, legal/financed realizability, and actual decentralized
meals. Ale and visitor bread are separate. No social-welfare objective is defined.

## Inputs, capture and passive evidence

Primary: main endowment, seed42, all four conditions and L/S/R, days1/3/30.
Existing retained full traces may be reused only after exact published report and
ledger pin checks. Retained M26 reports/CSVs alone lack full shopping-time money
and intermediate authoritative state; do not infer these from final cash. Where
necessary regenerate a native trace with the unchanged existing capture command.
One independently audited capture per required case suffices for unchanged
historical preservation; repeated analyzer/checker execution establishes new
diagnostic determinism. Compare short-run native traces with matching prefixes
of30-day traces. No new scenario or instrumentation events are needed.

Extract day1/day3 starts at audited `day_started` from replayed entities, cash
books, employment, affiliations, assets, cargo, positions and wage claims. Source
report/ledger and snapshot digests accompany all certificates. If faithful state
is unavailable, mark unknown and omit that witness rather than manufacture it.
Optional staggered experiments are excluded from this primary milestone; their
different legal initial endowment remains preserved in historical checks.

Per day/firm/cohort record actual sources/sinks, held/cargo inventory, whole-lot
requests/clearing/quotes, credible retail requests, censorship/coverage, cash at
procurement/payroll/shopping, accrued/paid/owed wages, future term guarantees and
19:00 owner distributions. Prove9192 after every actual money transfer, goods
conservation and payable/receivable equality. Rejections have no ledger effects;
native checkpoint/final comparisons and existing authority tests retain atomicity.

Flags are separate: resource cap; batch/asset/worker limit; legal term restriction;
input clearing/rationing; cash/timing; stockout/forecast lower bound; standby
obligation; firm profitability/incentive; household purchasing power. Attach native
event IDs/time/actor and direct, inferred, ambiguous or unknown status. In particular
read `consumer_decision`'s independently validated pre-purchase funds; an empty
shelf plus a cashless shopper is not a solvent unfilled request. Missing intent
stays unobserved. Censored lower bounds never become exact latent demand.

## Bounded physical certificates

Only day1 and, when faithfully reconstructable, day3. Today's real contracts and
named homogeneous employees are fixed; no reassignment, owner production, new
hire or extra slot. Installed limits3/3/3/2, one productive shift per worker.
Farm yields exactly `min(7, remaining_cap)` for each productive shift, positive
only; mill5 wheat→5 flour, bakery5 flour→7 bread, brewery3 wheat→6 ale. Stocks
remain with their owners until actual whole-lot transfers/deposits in the witness.

Two disclosed physical search spaces:

1. `fixed_orders`: hold the audited day's submitted grain/flour order ceilings
   fixed, use the native revenue-maximizing grain clearing and actual whole lots.
2. `voluntary_orders`: enumerate smaller/larger whole-lot request choices up to
   installed/current worker limits (mill0..3, brewer0..2, flour0..3), retain native
   grain clearing; no-brew still forbids brewery grain requests. Funding and own
   policy request gates are explicitly deferred to the finance checker.

Enumerate all productive headcounts0..3/3/3/2 and request combinations (at most
9216 tuples before stock/worker restrictions). Optimize bread available at16:00,
then ale output; ties use fewer productive shifts, then lexicographic firm counts
and requests in farm/mill/bakery/brewery order. Worker subsets use sorted active
IDs because work capacity is homogeneous; all active employees still attend.
No current policy inventory target is an authority production cap; any deviation
from its choices remains explicit in the incentive assessment.

The physical tier relaxes money, customer choices and policy request/profit gates;
label it `relaxed_potential`, with a checked physical witness, not a legal-financial
claim. Recipe-only15 wheat→15 flour→21 bread is an additional explicitly relaxed
screen, not a substitute witness. A checker independent of the search generator
validates whole batches, material balances, named workers/terms/assets and routes.
A universal bakery ceiling is starting bakery bread plus seven times the number
of legally available installed baker slots. Attaining it certifies a physical
optimum in the stated space; otherwise retain a feasible lower bound and declare
optimality unproven unless an independent exhaustive bound establishes it.

Timetable: workers/owners depart08:00; farm09–10; grain10:10; couriers depart10:15,
mill deposit10:25–10:30 and brewery10:45–10:50; mill11–12; flour12:10; Cora returns
12:15–12:25 and deposits five minutes; brewery13–14; bakery14–15. Residents shop
bread16:00 and ale16:15; visitors enter17:00, shop bread17:05 and ale17:20. Preserve
Cora's16:20–16:30 return, household17:30 departures,18:30 meals and19:00 settlement.
Routes are x then y, one tile/five minutes; body activities cannot overlap. Actual
15:55 board attendance is compatible; no hypothetical new terms are silently made.

## Finance and incentives

Overlay each selected physical witness with exact prices2/5/6/4 and wage10.
Do not search finances or claim a financed optimum. Check time-ordered owned cash,
authorized counterparties, observed active quotes, native request-budget gates,
real cargo, all active workers' earned wages including standby and carried FIFO
claims. A productive worker needs the native single fully paid wage receipt.
Existing future terms/conditional guarantees remain recorded; no midterm waivers.
Owner payouts occur only19:00 after meal attempts/wages and never spend the120
floor ahead of legally due pay.

For retail use only the audited day's actual positive request/valid purchase
evidence, in original shopping order. An alternative may fill an actual stockout
request only if the buyer is still funded/eligible at that time in the alternative.
If earlier purchases remove affordability, skip and report it. No invented buyer,
latent willingness, compelled purchase, or assumed sale of all output. No-request
shopping cannot be converted into alternative demand. Consequently a verified
finance witness is a lower bound, not a maximum achievable meals calculation.

The checker separately reports `physically_feasible`, `finance_witnessed`, and
`incentive_compatible`. Funding failure gives an unproven finance claim, not a
global impossibility. A voluntarily reduced profitable order can be authorized
but disagree with the observed own-profit policy; mark this false where directly
proved, otherwise unproven. Positive integrated surplus alone proves neither
participating-firm incentives nor a mutually acceptable supply agreement.

Conditional wedge fixture: new third farm shift at cap19 sells5 wheat for10,
wage10, margin0; at cap16 sells2 for4, margin−6. The five-wheat mill/bakery
extensions have margins+5/+7 if sold, aggregate+12. Already-guaranteed current
assignment has additional wage0: farm+10/+4 respectively. These are conditional
arithmetic certificates, not measured sales or policy changes.

## Negative controls, acceptance and outputs

Fixtures: prospective zero/negative farm margin, sunk standby, due pay versus
owner floor, grain21/19/16 competition, insufficient cash, mere sold-out inspection,
late visitors/revenues, and positive chain surplus with a nonpositive local link.
Reject altered proofs for negative stock, fractional shifts, reused worker,
site/time error, free cash, future sale, erased wage claim, duplicated transfer,
forged fulfillment/source, illegal term and censored demand called exact truth.

Targeted Python tests and1/3-day checkpoints precede one final full acceptance:
complete native/Python suites;169 old payload pins; published M23/M24/M25 controls;
all M26 arm pins and legacy parity; original C/D audits and M22 smoke. Immutable
unchanged source/engine/pinned trace caches may be reused with declared digests;
never replace an independent audit with a cached aggregate. Record actual phase
walls, capture/audit/diagnostic cost and RSS; no simulation-speed or hardware-scale
claims. No expensive annual sweep during editing.

Commit compact physical certificates and independently replayable steps, cash
timelines (detailed days1/3), all30-day firm/cohort summaries, constraints and
missed-meal attribution rows with provenance, case/acceptance manifests and schemas.
Transient full native traces stay outside git. Report actual findings and unknowns
in `M27_RESULTS.md`, recommend one smallest controlled next experiment without
implementing it, and stop for review. No M28, dynamic wages or adaptive prices.
