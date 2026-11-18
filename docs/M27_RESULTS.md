# M27 — Read-only economic feasibility and failure attribution

M27 adds offline diagnostics and independently checked one-day alternatives.
It changes **no Godot simulation code, NPC decision, initial endowment, quote,
contract, report, or historical pin**. The economy remains the M26 experiment;
the new outputs explain it rather than rescue it. No M28 mechanism is implemented.

Issue [#39](https://github.com/anoy-maker/simulated-town-rpg/issues/39), branch
`codex/m27-economic-diagnostics`, exact base
`2bc13ef8ca92809a77eaf78a47168d97fd8bf939` on
`codex/m26-demand-observation`. The [protocol](M27_ECONOMIC_DIAGNOSTICS_FEASIBILITY.md)
was committed as `8aa2af0` before new comparative conclusions. Native simulation
tree remains `52825d822ec952b9981c6431d2657aa44c5bff87`.

## What the evidence establishes

There are four separate answers: integer productive capacity, physical delivery,
time-ordered legal funding, and actual decentralized consumption. A bound on
bread is not a bound on funded meals. A funded alternative is not evidence that
profit-seeking firms will choose it or renew the required contracts.

The passive reader independently replays all36 main seed42 runs: four conditions
× L/S/R forecasts × horizons1/3/30. It retains actual custody, cash, payroll,
claims, demand provenance, censorship and settlement times. All30-day native
prefixes match their1/3-day runs. Each final diagnostic was recomputed identically
from unchanged input. Day1/day3 snapshots come from replayed authoritative state,
including held inventory, cargo, exclusive terms and installed assets.

The search generates48 checkpoint alternatives, all independently verified.
Every reported physical optimum is limited to its declared **one-day physical
space**, relaxing money, customer choices and own-profit/request-policy gates.
Each selected alternative also has a constructive one-day finance witness using
actual positive requests; none has a certified financed optimum or incentive
compatibility. Future contract funding remains unproven. There is no30-day plan.

## Physical capacity versus meals

The following checkpoint numbers apply to each arm's corresponding main run.
The published certificates include all L conditions; every S/R proof was also
checked. Day1 economic state/actions coincide; by day3 the renewal decisions and
future terms can differ even where the displayed production/meals still agree.

| Condition / checkpoint | Actual bread produced / resident meals | Fixed-order bread at shop / financed resident meals | Alternative-order bread at shop / financed resident meals |
| --- | ---: | ---: | ---: |
| Reference, day1 |21 /15|21 /15|21 /15|
| Reference, day3 |21 /15|21 /15|21 /15|
| Tight, day1 |21 /15|21 /15|21 /15|
| Tight, day3 |21 /14|22 /14|22 /14|
| Scarce, day1 |14 /14|14 /14|21 /15|
| Scarce, day3 |14 /12|14 /12|21 /12|
| No brew request, day1 |21 /15|21 /15|21 /15|
| No brew request, day3 |21 /13|23 /13|23 /13|

Shop stock includes carried bread: one loaf in tight day3 and two in no-brew
day3. Daily output and available stock must not be interchanged. All recipes,
active named employees, equipment slots, exclusive terms, owned inputs, whole
lots and native grain clearing are checked. Seventy-eight actual-timetable trips
per certificate have independently reconstructed x-then-y paths and nonoverlapping
work, standby, management, delivery and shopping activities. Everyone is at the
proper workplace/store/home in time. Owners do not replace employed workers.

The reference reproduces the M23 feasible day under binding payroll:21 wheat,
15 flour,21 bread and12 ale;15 resident meals and6 visitor meals. Each firm
returns to120 coins after its authorized distribution. This is a feasible
scheduled day, not a proof of autonomous equilibrium.

In scarce day1 the actual eligible mill/brewery requests clear ten wheat to the
mill and six to brewing. Fourteen bread is the checked maximum in that
**fixed-order space**. If the brewery requests zero lots,15 wheat can reach the
mill and21 bread can be made. The alternative uses real accounts and15 actual
resident bread requests, serves six actual visitor requests, pays all eleven
guaranteed employees including standby, and conserves cash. It does **not** prove
that the brewer would voluntarily forgo its own opportunity. The claim that cap16
imposes a universal fourteen-bread recipe limit would be false.

Scarce day3 has the same physical distinction, but both checked financial
executions yield only12 resident meals. Additional goods cannot finance a
cashless customer at16:00. The alternative serves six visitors instead of two;
no visitor request, willingness to pay, new purchasing power or compelled resident
purchase is invented. This is a conservative witness, not a maximal funded-meals
calculation. Tight/no-brew day3 similarly retain food while some residents cannot
afford it. In no-brew day3, carried farm wheat also allows fewer productive farm
shifts in the physical tie-break; remaining employees still earn standby wages.

## Correct attribution of actual failures

Across the twelve30-day cases there are5,400 resident meal needs and1,170 missed
meals. Independently validated shopping-time funds and native legitimate intents
support901 purchasing-power blockers and269 solvent bread-stockout blockers.
These are immediate observed blockers, not a disjoint causal decomposition of the
whole economy. The failure rows retain overlapping contributors:190 cash-poor
missed-meal visits also saw empty shelves. Those visits are not counted as solvent
unfilled demand.

| Condition | L meals; cash / solvent-stockout missed | S meals; cash / solvent-stockout missed | R meals; cash / solvent-stockout missed |
| --- | --- | --- | --- |
| Reference |450;0 /0|450;0 /0|450;0 /0|
| Tight |260;122 /68|362;88 /0|395;55 /0|
| Scarce |359;90 /1|341;108 /1|378;57 /15|
| No brew request |174;138 /138|286;130 /34|325;113 /12|

Fifty-two purchasing-power failures receive later transfer income that day;
38 end with at least the six-coin bread price. Neither observation makes those
coins available at the earlier shopping appointment. The CSV retains late-transfer
IDs and actual shopping cash so the timing can be checked. All primary missed
meals have direct immediate evidence; latent demand remains unknown, including
censored traffic. A visit or a final wallet balance is never a request proxy.

Separate provenance flags cover resource caps, indivisible/installed labor limits,
legal employment restrictions, input clearing, cash timing, stockout lower bounds,
paid standby, observed profitability-model reasons and household purchasing power.
They overlap. No actual primary `timing_working_capital` flag fired; the fixtures
demonstrate that this constraint can fail. Forecast-reason flags prove what a firm
decided under its own model, not that an omniscient counterfactual is profitable.

The original economic outcomes are retained. For example, request-aware R in
tight/scarce pays44/56 standby shifts and ends with brewery cash0/12 respectively,
despite zero earned-wage arrears in all primary runs. R improves meals over S in
these constrained main cases but does not establish sustainable employment or a
generally better policy. Staggered results remain distinct historical evidence.

## Cash, liabilities and the incentive gap

Every native purchase/transfer is replayed with exactly9,192 combined coins and
nonnegative accounts. Commodity sources/sinks and custody are audited at each
movement; added firm-day warehouse-plus-cargo identities agree with production,
input use, purchases and sales. Opening arrears plus earned wages minus actual
payments equals closing arrears; firm payables equal worker receivables. Conditional
future guarantees are recorded after the24:00 term boundary, including accepted
successors, and are not current money or earned debt. Owner distributions remain
at19:00 after wages and meals, not retroactive food or procurement finance.

The independent finance checker retains actual own request-budget evidence and
positive retail intents in their source order. It never presumes that every loaf
or ale unit sells. In a changed schedule, an originally positive request can fail
if the earlier alternative spends that customer's funds. Cashless firms, poor
visitors, late receipts and erased liabilities cannot be used to complete a proof.
Where that conservative overlay cannot certify a schedule, it says `unproven`,
not economically impossible. It requires fully funded productive wage receipts;
it does not search partial-payment or late-cure alternatives.

For a **new** third farm wage obligation, cap19 leaves five wheat: ten coins
conditional sales minus ten wage =0. Cap16 leaves two wheat: four minus ten =−6.
For an already-guaranteed employee, additional current wage cost is zero; the same
conditional current-day margins are+10/+4. Actual first-day harvest is19/16,
not14. Standby expense cannot simply disappear when a witness reduces production.

The separate five-wheat chain fixture has conditional new-work margins farm0,
mill+5 and bakery+7, aggregate+12 **if all marginal output sells**. At unchanged
flour/bread prices, both farm and mill cannot earn strictly positive margins at
an integer wheat price: farm requires `p>2`, mill requires `p<3`. Positive joint
value therefore proves neither a mutually attractive agreement nor actual sales.
No price or contract change is made. All incentive-compatibility outputs remain
`unproven`; matching observed quantities is reported separately.

## Verification, costs and implementation limits

The final [acceptance manifest](M27_VERIFICATION.json),
[phase walls](M27_VERIFICATION_PHASES.csv) and [test log](M27_TEST_LOG.txt)
record the actual completed runs:

| Check | Actual result |
| --- | --- |
| Complete Godot suite |3,272 checks, zero failures|
| Complete Python suite |123 methods, passed; includes all111 previous methods and12 new methods|
| Historical M0–M18 payloads |169/169 original hashes unchanged|
| Published M23/M24/M25 controls, vacancies, cash and lifecycle fixtures |88/88 report-and-ledger pairs unchanged; independently audited|
| M26 main conditions/arms/horizons |36/36 report-and-ledger pairs unchanged; double final passive replay|
| M26 L versus M25 matching |12/12 normalized economic comparisons passed|
| Additional M26 staggered/observation controls |8/8 pinned pairs unchanged; audits passed|
| Original C/D1/3/30 sync/scheduled audits |12/12 financial/spatial/observation/numerical audits passed again|
| Independent checkpoint proofs |48/48 checked, plus a standalone trace-to-certificate CLI check|
| Isolated M22 performance smoke |Passed; matching reference metadata, zero advisory warnings|

No required check was skipped and there are no unresolved correctness failures.
The original native C/D traces were reused with recorded unchanged-source and
pinned-digest checks; their audit results were recomputed, not reused. Main M26
traces captured during checkpoint/primary verification were reused for the final
reader pass. [Historical payload evidence](M27_REGRESSIONS.csv),
[published controls](M27_HISTORICAL_CONTROLS.csv), [C/D source provenance](M27_CD_SOURCE_MANIFEST.csv),
[original audits](M27_ORIGINAL_AUDITS.csv) and
[additional M26 controls](M27_EXTRA_M26_CONTROLS.csv) retain the individual hashes.

Twelve focused Python methods cover
read-only deterministic replay, truthful unknowns, reconstructed day3 state,
current/new wage costs, independent physical maxima, conservative demand/funding,
due-pay priority and negative certificates. Mutations include fractional shifts,
negative stock, duplicate workers/transfers, owner production, expired terms,
wrong site/time, invented money/future sales, erased earned debt, forged fulfillment
and censored evidence presented as exact demand.

The original36-case capture/parity command took329.387 seconds. A final cached
trace replay with explicit daily goods/cargo/debt checks took313.908 seconds,
including double analysis and all checkpoint witnesses. Both phases ran alongside
other verification on a shared host; these are costs, not performance gains.
`M27_CAPTURE_PERFORMANCE.csv` separates native capture/reuse from
`M27_PERFORMANCE.csv`'s final reader measurements. Final30-day per-case analysis
median was7.923 seconds (range6.588–18.071); replay median11.142 seconds.
Witness generation/checking median was0.195 seconds per30-day case's four
checkpoint certificates. Researcher RSS is a cumulative process high-water mark
(final maximum189,344KiB), not isolated per-case memory. Retained native process
RSS is also reported. No Rust acceleration or language migration is involved.

An additional isolated single-case sample read48,363 reference/L30-day events:
parse0.500 seconds, audit/analysis5.366 seconds, exact replay5.985 seconds, four
checkpoint proofs0.116 seconds, process peak122,736KiB. Its diagnostic digest
matches the final published case. This is a cost sample, not a speed comparison
or NPC latency estimate; see [reader cost](M27_READER_COST.json).
The isolated [smoke](M27_SMOKE.json) took3.468 seconds at the command boundary:
C1/D1 run-only0.087/0.093 seconds, queue10 run-only0.933 seconds. All correctness,
proposal/release-order and canonical-hash checks passed with no performance
warning. Overlapping verification walls must not be summed as elapsed work.

Host: Godot4.6.3 (`7d41c59c4`), Python3.12.14, Linux x86_64, three visible CPUs
with a two-CPU quota,8GiB memory. Original C/D native traces can be reused because
their exact model source, native build and pinned results are unchanged; their
independent audits run again. Reuse is recorded rather than described as fresh
native capture. All other preserved native controls run with the same Godot.

During development the first daily summary omitted explicit purchased/consumed
commodity and cargo fields even though the inherited audit checked the full
ledger. That reporting omission was fixed, then all36 cached native traces were
re-audited/replayed with the added source-sink and wage identities. No economic
policy was adjusted after observing results. Detailed cash tables cover days1/3;
daily observational attribution covers all30 days. Whole-year optimization,
finance maximization, counterfactual intention inference and incentive proofs are
deliberately absent. All48 proofs were rechecked;16 complete L examples keep the
committed evidence bounded. Full raw event dumps remain outside git.
The primary experiment uses only seed42; replay establishes determinism, not
statistical robustness across towns or environmental distributions.

## Reproduction and review decision

From this branch, with Godot4 installed and writable XDG directories:

```sh
export XDG_DATA_HOME=/tmp/m27-data XDG_CONFIG_HOME=/tmp/m27-config XDG_CACHE_HOME=/tmp/m27-cache
python3 -B -m unittest discover -s tests -p test_economic_diagnostics.py -v
python3 -B scripts/tools/run_economic_diagnostics.py --checkpoint --traces work/m27/traces --output work/m27/checkpoint
python3 -B scripts/tools/run_economic_diagnostics.py --legacy-parity --traces work/m27/traces --output work/m27/experiments
python3 -B scripts/tools/summarize_economic_diagnostics.py --input work/m27/experiments --traces work/m27/traces --output work/m27/published
python3 -B scripts/tools/check_economic_witness.py --trace work/m27/traces/scarce-30-legacy_instrumented.json --certificate docs/M27_CERTIFICATES/scarce-30-legacy_instrumented-day1-voluntary_orders.json
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m27/historical.csv
```

Historical M23/M24/M25 controls use their unchanged drivers and published pin
files; `check_diagnostic_controls.py` verifies the additional M26 staggered and
observation fixtures. Original C/D `measure_planning_jobs.py --phase audit` and
isolated `performance_smoke.py` remain required; the final verification manifest
records exact commands and cache provenance. See [artifact definitions](M27_SCHEMAS.md).

For review, the smallest recommended next experiment is a preregistered **own-firm
input-availability forecast** treatment against unchanged R. Use only the firm's
legitimate past requested/cleared/deposited whole lots in its prospective contract
valuation; keep wages, prices, terms, targets and money fixed. Measure standby,
nonrenewal, cash, downstream production and household failures separately. This
could test whether demand-only renewal forecasts assume unavailable inputs; it
does not promise more food and cannot resolve the conditional farm incentive gap.
No such treatment or M28 code is included. Stop after M27 for review.
