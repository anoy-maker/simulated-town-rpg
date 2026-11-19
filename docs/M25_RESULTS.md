# M25 — Binding employment, guaranteed compensation and preserved wage claims

Implements [issue #35](https://github.com/anoy-maker/simulated-town-rpg/issues/35)
from `codex/m24-labor-market` at
`9e9fb8d3e1af1480aacb6fdc541472842299a7ca`, on `codex/m25-binding-contracts`.
Historical scenarios and defaults are preserved. This is not a viable-economy
adoption or a dynamic-wage experiment.

## Frozen rules and implementation choices

The [contract feasibility note](M25_CONTRACT_FEASIBILITY.md) was committed in
`d7f432f` before M25 outcome runs. Timing clarification `9ed061b` and its early-
receipt fixture `9e0e7f9` preceded the longitudinal matrix. All four conditions
retain the fifteen residents, four firms, equipment, recipes, output targets,
initial zero commodities, fixed prices 2/5/6/4 and total **9192 coins**. Eleven
initial contracts cover days 1–3. Every new term covers three consecutive days
at ten coins per verified daily hour of workplace availability. Owners manage
without wages. Homogeneous labor does not alter historical skills metadata.

A worker registers a full on-site hour of work or standby. Declining an employer
assignment because inputs/payroll are unavailable falls back to standby, not a
worker no-show. The ending clock verifies attendance and accrues a unique 10-coin
claim. Standby creates no goods or productive work event. Actual absence creates
an evidenced employee breach and no unearned guarantee.

Wage tenders use actual existing money, oldest due day first, then worker ID.
Partial amounts leave explicit arrears; the 120 owner-payout floor cannot protect
cash against earned wages. Before 16:00, actual early receipts clear eligible
arrears after completed appointments. Later retail receipts clear at 19:00 before
distributions. A productive shift references its already paid full ten-coin receipt
once and retains native affiliation, physical hour, asset, input, capacity and
labor validation. A worker whose full native wage cannot be funded does not
create unpaid production. Availability and unpaid claims remain real.

Current assignment reserves payroll once and compares additional output receipts
against incremental inputs. Renewal/hiring includes **all three days of wages**
and real input costs in a bounded cash/stock/demand projection. Demand is the
firm's own previous-day unit sales, with the existing target prior initially;
remaining-today receipts are a conditional forecast, never spendable money.
Retained staggered staff are projected to continue for the three-day horizon,
including conditional renewal if needed, with wages budgeted. This is a fallible
continuation assumption, not knowledge of their future acceptance. Actual labor
always requires a real active term.

Workers inspect notices/offers only at the physical 15:55 bakery meeting. They
use only own terms and recent wage receipts. Active terms cannot be abandoned
for a better offer. Actual applications concern next-day starts only on the
final day or while unemployed; the old relation ends before its successor.
An owner may refuse renewal and a worker may decline it. Optional verified
material-breach release requires the proper party's explicit choice and a native
breach receipt; no main policy deliberately breaches or automatically releases.
Past claims survive lawful release, expiry, nonrenewal and later employment.

Two modes share financial/attendance rules and starting conditions:

- `matching` permits locally observed eligible new hires, including rehire after
  unemployment and employment at another industry.
- `obligations_only` permits financially supported renewals by currently expiring
  incumbents. It does not automatically renew a loss-making job or restart an
  employer after all its incumbents have left. This restriction was predeclared.

## Thirty-day results, seed42

Each new condition/mode/horizon ran in **two fresh processes**, comparing complete
native events and reports, with independent reconstruction. Every main scheduled
day was attended and paid; **all main runs have zero earned wage arrears and zero
contract breaches**. Employment loss below is lawful nonrenewal, not unpaid pay
being silently erased.

| Condition / mode | Attendance days paid | Productive shifts | Standby days | Resident meals / missed | Wheat / flour / bread / ale produced | Circulation |
|---|---:|---:|---:|---:|---|---:|
| Reference / matching |330|330|0|450 /0|630 /450 /630 /360|13950|
| Reference / renewals only |330|330|0|450 /0|630 /450 /630 /360|13950|
| Tight19 / matching |171|143|28|260 /190|267 /230 /322 /72|6210|
| Tight19 / renewals only |81|69|12|134 /316|127 /115 /161 /24|2993|
| Scarce16 / matching |247|225|22|359 /91|426 /300 /420 /252|9408|
| Scarce16 / renewals only |111|93|18|158 /292|174 /140 /196 /60|3948|
| No brew request / matching |108|87|21|174 /276|161 /160 /224 /0|3920|
| No brew request / renewals only |87|63|24|127 /323|119 /115 /161 /0|2873|

Cash wages equal ten times attendance days, including standby. For example, tight
matching pays 1710:1430 accompanies productive work and 280 pays real availability
without output. The no-brew control still owes its initial two brewery employees
60 across their first three days, even though brewery production is disabled.
That firm ends at60 cash, with no fabricated beer or subsidy.

The supplied reference reproduces M23/M24's economic flows: all firms close daily
at 120, all meals occur, wages 3300 and owner distributions 1920 are actual transfers.
There are 110 continuous renewals, including eleven terms starting day 31 after
the final midnight. Those future terms carry 330 of conditional guaranteed wages;
they are neither current arrears nor newly created coins.

| Condition | M23 sorted meals | M24 rotation meals | M25 matching meals | M25 renewals-only meals |
|---|---:|---:|---:|---:|
| Reference |450|450|450|450|
| Tight19 |368|397|260|134|
| Scarce16 |368|397|359|158|
| No brew request |322|361|174|127|

M25 changes a bundle: binding terms, standby compensation, current marginal cost,
and ex-ante renewal decisions. These totals do not isolate a universal causal
effect of guaranteed pay. The matched M25 modes isolate the permitted matching/
rehire rule under those shared assumptions; they do not isolate cross-industry
movement alone. The renewals-only control's inability to restart after a gap is
an important part of that contrast.

## Why production and employment change

During the initial guaranteed term, actual harvest is 19/day under tight and 16/day
under scarce, rather than M24's 14/day. A third farm employee's already committed
wage is not deducted again when valuing five or two additional wheat. Production
still requires real attendance, available cap and inventory below target.

More grain does not ensure more bread. During the first three scarce days, 16
wheat clears as mill 10 / brewery 6 each day: 42 bread and 36 ale. M24's 14-plus-carry
pattern produced 49 bread and 12 ale over those days. M25 scarce has 38 resident
meals versus M24's 41, despite greater harvest and guaranteed pay. Tight has 43
versus 41; no-brew has 41 versus 37. These are actual unchanged-price allocations.

Day 3's observed full-term proposals illustrate the different renewal calculation.
Tuples below are `(headcount, projected receipts, inputs, wages, contribution)`:

- Tight farm: `(2,84,0,60,24)` beats `(3,108,0,90,18)` at observed demand18/day.
  The already used third employee is not automatically hired for another term.
- Tight bakery: two employees project 54 contribution, three 45. Mill retains 3.
- Tight brewery forecasts six ales carried after today's remaining sales. Zero
  employees can sell that stock for 24; one employee's projected72 receipts minus
  18 inputs and30 wages also yields 24. The declared fewer-commitments tie picks 0.
  Actual late sales empty that stock; the next day's new observation then supports
  hiring again. Matching restarts it on day 5; renewals-only leaves it closed.
- Scarce's first renewal selects farm2/mill2/bakery2/brewery2, based on observed
  demand16/10/14/12. Its day 3 brewery forecast chooses two employees with48
  contribution. The lower harvest cap therefore produces a different staffing,
  clearing and renewal trajectory; outcomes are not monotonic in the cap.

No source, price or policy was adjusted to repair these outcomes. Matching's
tight run ultimately has no farm grain supply and dependent downstream standby;
its last productive work and resident meal are day 25. Scarce matching continues
through day 30 with eight active next-day affiliates. Renewals-only last productive
days are 13/15/12 for tight/scarce/no-brew; matching extends those to 25/30/19.
Those are continuation differences, not evidence of a viable baseline.

## Real employment flows and individuals

`renewed` means uninterrupted same-employer succession. `hired` includes all other
entries; `rehired` is its same-employer-after-a-gap subset. `changed_employer`
counts immediate boundary switches, which are zero here. Other-employer hiring
after unemployment is separately visible as `hired − rehired`.

| Mode / condition | Terms expired | Continuous renewals | Other entries (rehire subset) | Other-employer entries after gap | Nonrenewed terms | Final active jobs |
|---|---:|---:|---:|---:|---:|---:|
| Either / reference |110|110|0 (0)|0|0|11|
| Matching / tight |57|34|12 (8)|4|23|0|
| Renewals only / tight |27|16|0 (0)|0|11|0|
| Matching / scarce |81|76|2 (1)|1|5|8|
| Renewals only / scarce |37|26|0 (0)|0|11|0|
| Matching / no brew |36|19|6 (4)|2|17|0|
| Renewals only / no brew |29|18|0 (0)|0|11|0|

Examples: tight Gale moves from expired farming to bakery on day 5; Nell later
enters milling and Jory brewing. Scarce Lyle enters brewery on day 8 after his
mill term ended. No-brew Oren enters farming on day 5 and Nell bakery on day 17.
These use observed public offers, genuine positions and unchanged homogeneous
labor. No skill is invented and no current term is broken to obtain the job.

Per resident, cells are **attendance days / missed meals / final coins**, matching
mode; the complete wages, production, purchases and inventories are in the CSVs.

| Resident | Tight19 | Scarce16 | No brew request |
|---|---:|---:|---:|
| Ada |0 /11 /14|0 /3 /14|0 /18 /14|
| Bram |0 /7 /2|0 /3 /14|0 /13 /14|
| Cora |0 /7 /102|0 /3 /122|0 /13 /90|
| Dain |15 /12 /4|30 /0 /10|9 /15 /6|
| Edda |15 /12 /4|30 /0 /10|3 /24 /0|
| Finn |21 /7 /34|30 /0 /10|15 /13 /54|
| Gale |12 /15 /20|3 /26 /0|3 /24 /0|
| Hale |24 /8 /94|30 /0 /54|15 /13 /54|
| Iona |27 /8 /136|30 /0 /70|15 /13 /54|
| Jory |18 /10 /62|30 /0 /74|6 /19 /0|
| Kira |3 /25 /2|3 /26 /0|3 /24 /0|
| Lyle |9 /15 /2|26 /3 /56|18 /16 /102|
| Mara |0 /27 /0|0 /6 /14|0 /29 /0|
| Nell |18 /12 /74|29 /0 /68|9 /24 /60|
| Oren |9 /14 /0|6 /21 /0|12 /18 /54|

High final cash does not ensure food: tight Iona has 136 coins while bread supply
ends. Scarce still excludes Gale/Kira/Oren substantially. Standby guarantees
honor valid contracts; they cannot create grain, flour, bread, new profitable jobs
or income after lawful expiry.

## Financial consequences and conservation

Main wages are paid in full, so cash payroll equals accrued wage expense. The
separate fields remain necessary for default fixtures. Main matching books:

| Condition / firm | Sales | Inputs | Cash/accrued wages | Distributions | Final cash | Accrued operating margin |
|---|---:|---:|---:|---:|---:|---:|
| Tight / farm |532|0|390|142|120|142|
| Tight / mill |1150|460|540|170|100|150|
| Tight / bakery |1932|1150|540|274|88|242|
| Tight / brewery |288|72|240|12|84|−24|
| Scarce / farm |852|0|630|222|120|222|
| Scarce / mill |1500|600|630|270|120|270|
| Scarce / bakery |2520|1500|630|390|120|390|
| Scarce / brewery |1008|252|580|176|120|176|
| No brew / farm |320|0|240|80|120|80|
| No brew / mill |800|320|390|110|100|90|
| No brew / bakery |1344|800|390|186|88|154|
| No brew / brewery |0|0|60|0|60|−60|

Earlier earned distributions may coexist with a later cumulative loss; they are
not retrospectively confiscated. No owner receives distributions while earned
arrears remain. Inputs are expensed as purchased, without inventory valuation;
the accrued operating margin is not a formal full inventory-valued profit figure.
Future conditional guarantees are shown separately from currently earned debt.

Matching final household / firm / visitor coins are tight 550/392/8250,
scarce 516/480/8196 and no-brew 502/368/8322. Each sums to 9192. Reference is
1174/480/7538. Final commodities: tight one farm wheat; scarce zero; no-brew one
farm wheat; reference zero. All other household/firm/cargo goods are accounted for.
Matching purchase successes/rejections: reference 1230/0, tight 498/7,
scarce 834/3, no-brew 288/6. Rejected real input purchases retain their consequences.

## Cash, attendance and lifecycle witnesses

Separately labeled fixtures change only their declared test endowments or physical
fault protocol; main initial conditions stay fixed. Every fixture conserves 9192.

| Witness | Actual result |
|---|---|
| Bakery cash6, Finn cash0, bakery21 bread | Finn receives6 at15:00, owns a 4-coin claim, buys bread at16:00, then receives4 at 19:00. All three bakery workers attend standby; no bread production is fabricated. |
| Bakery cash0, Finn cash0, bakery21 bread | Finn gets no early money and misses the meal. Actual retail receipts pay 10 at 19:00, without backdating food access. |
| Mill cash0, Hale cash0, mill15 flour | Verified idle mill workers accrue 30. Actual 12:10 flour sales clear wages before 16:00; Hale eats. Timely-payment breaches remain recorded despite cure. |
| Insolvent bakery, zero goods, four days | Three employees accrue 90 over days 1–3. They expire unrenewed; 90 remains payable/receivable. Cash wage expense 0 is not reported as profit: accrued margin −90. All 60 resident meals are missed in this chain failure. |
| Deferred retail until day 4 | The cash6 fixture withholds bakery shopping in a technical fault protocol. Its 21 bread stays real stock and 84 remains owed after expiry. Restored ordinary day 4 retail receipts clear oldest claims at 19:00, including Finn's first-day remainder. No capital injection or goods creation occurs. |
| Worker nonattendance | Dain's changed test route evidences absence; no guarantee is earned. Owner's explicit verified release takes effect next boundary. |
| Employer wage default | Iona may explicitly elect release from an unpaid breach; the old claim survives. No automatic main-run exit policy is added. |
| Staggered initial maturity | Four days have 44 genuine shifts and 60 meals, no overlap or extra hire; all new terms still last three days. |

Authority witnesses also cover productive wage once, standby following rejected
assignment, protected capital, oldest priority, overpaid/duplicate/forged payout,
remote notices, another applicant's acceptance, overlapping employer offers,
premature switching, renewal refusal, canceled future entry, exact final-day pay,
first new-day work and unchanged owner management-only roles. Pure one-grain and
one-coin examples verify the current/new-commitment marginal-cost distinction.
The one-coin fixture changes a pure output-value observation, never actual wages.

## Verification and development findings

The full Godot suite passed **3,244 checks, zero failures**, preserving all 3,202
previous checks. The complete Python suite passed **102 tests, zero failures and
zero skips**. All **169 historical payload hashes**, **12 M23 controls**, **24 M24
main cases** and **12 M24 vacancy fixtures** retain their published report/ledger
pins. All **12 fresh C/D synchronous/scheduled original independent audits** pass.
The M22 smoke passes canonical/parity/queue checks with **no performance warnings**.
No unresolved technical failure or unavailable required check remains. The public
`run_simulation.gd --scenario settlement_binding_contracts` entry point also
reproduces the published three-day reference JSON bytes. The new matrix has 24 cases/48 full-process replays and audits,
cash/maturity fixtures 6 cases/12 audited captures, and 10 independent lifecycle
traces. No report aggregate substitutes for event reconstruction.

Independent replay reconstructs every native transfer, commodity transformation,
cargo movement, presence/activity/clock, wage receipt, claim, knowledge view and
term transition. It checks 9192 after each movement, nonnegative unique claims,
payable=receivable, `cash payroll + arrears = accrued wages`, term-flow identities,
real attendance, no duplicate wage or labor, and payments at their real times.
Sixteen rehashed forgeries include attendance, claims, payments, dates, entry classification,
private data, renewal costs, erased debt, false profit and altered initial prices/cap.

Development fixes were correctness/verification fixes, not economic calibration:
an employer's rejected production offer must preserve standby; early receipts
must clear earned wages before shopping; and same-employer rehire after a gap
must not be labelled continuous renewal. The last correction added exhaustive
entry/exit identities. All24 captures were rerun afterward; their **complete
authoritative initial/final states and economic reports remained identical**
([correction check](M25_CORRECTION_CHECK.json)). Unit fixtures were also corrected
to use actual available funds and a manually controlled pre-offer meeting rather
than trying to offer jobs after automatic acceptance had already occurred.

Inherited `contract_shift`/`missed_shifts` annotate productive utilization. A false
productive annotation for paid standby is not a contractual breach; explicit
`binding_breach` and contracts tables are authoritative for that distinction.

A supplemental exact-initial-condition check also passes all 40 already fully
replayed case reports, rejecting altered prices or supply caps.

| Final verification phase | Actual command wall seconds | Exit |
|---|---:|---:|
| Full Godot suite |366.717|0|
| Full Python suite |190.433|0|
| 169 historical payload pins |692.850|0|
| Fresh original C/D capture |96.136|0|
| Original independent C/D audits |449.430|0|
| M22 performance smoke |3.255|0|

Some Godot/capture/historical/audit phases overlap; do not sum their walls as
total elapsed time. Python ran after Godot captures to avoid its deliberately
removed native descriptor fallback test racing other processes. Final isolated
M25 main/fixture/lifecycle driver walls were 225.896/13.833/12.181 seconds. The
[first and corrected experimental phase records](M25_EXPERIMENT_PHASES.csv)
include the reporting-correction rerun rather than hiding its verification cost.

## Measured cost and practical limits

Godot 4.6.3 / Python 3.12.14, Linux x86_64, three visible CPUs, two-CPU quota, 8 GiB.
Final matrix measurements ran sequentially without concurrent verification. Median
of two fresh 30-day runs; worst latency is the maximum sample across both:

| Condition / mode | Run s | Command s | Report s | Peak KiB | Events | Audit s | Worst appointment / tick ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| Reference / matching |3.987|9.650|2.764|660994|45251|4.630|76.298 /16.068|
| Reference / renewals only |4.107|8.857|2.574|661190|45251|4.665|115.148 /15.698|
| Tight / matching |3.166|7.450|2.015|569426|40123|3.820|31.084 /6.990|
| Tight / renewals only |2.807|6.845|1.704|514362|37731|3.457|28.589 /6.449|
| Scarce / matching |3.651|8.135|2.537|611892|42669|4.359|56.809 /10.384|
| Scarce / renewals only |2.834|7.213|1.866|530250|38552|3.736|43.682 /18.141|
| No brew / matching |2.927|6.967|2.133|531072|38355|3.700|26.537 /8.755|
| No brew / renewals only |2.838|6.638|1.950|515076|37674|3.519|33.243 /7.256|

The full reference now peaks around 646 MiB versus M24's roughly 565 MiB. More native
events, term/claim histories, copies and per-worker reports increase memory and
serialization cost. Reference appointment p99s are 35.047/32.753 ms for matching and
32.268/43.268 ms for renewals-only (870 samples/process), below the provisional
50-ms p99 diagnostic goal. Some real appointments still exceed 50 ms: matching
maxima occur at the 15:55 board; the 115.148-ms control maximum is at 18:30. Do not
describe this as
an interactive responsiveness guarantee. Two repeats are diagnostic, not a robust
performance estimate. No Rust/scheduler migration, annual scalability claim or
performance optimization was attempted. Timing/RSS sidecars never enter hashes. The legacy ten-job smoke callback p95
is 1.964 ms from 49 samples (no p99), with no regression warnings; this is not a
measurement of M25 worker responsiveness.

## Evidence and reproduction

- [Run results and pins](M25_RUNS.csv), [daily totals](M25_DAYS.csv)
- [Residents](M25_RESIDENTS.csv), [businesses](M25_BUSINESSES.csv),
  [all 3,600 person-days](M25_WORKER_DAYS.csv)
- [Terms](M25_CONTRACTS.csv), [earned wage claims and receipts](M25_WAGE_CLAIMS.csv)
- [Cash/maturity fixtures](M25_FIXTURES.csv), [lifecycle witnesses](M25_LIFECYCLES.csv),
  [fixture terms](M25_FIXTURE_CONTRACTS.csv), [fixture claims](M25_FIXTURE_CLAIMS.csv)
- [Unchanged M23/M24 pin pairs](M25_LEGACY_CONTROLS.csv),
  [169 payload regressions](M25_REGRESSIONS.csv), [original audits](M25_LEGACY_AUDITS.csv)
- [Verification walls](M25_VERIFICATION.csv), [M22 smoke](M25_SMOKE.json)
- [Per-process measurements](M25_PERFORMANCE.csv), [latency quantiles](M25_LATENCY.csv)

```sh
python3 -B scripts/tools/run_binding.py --output work/m25/experiments --verify-pins docs/M25_RUNS.csv
python3 -B scripts/tools/run_binding.py --fixtures --output work/m25/fixtures-final --verify-pins docs/M25_FIXTURES.csv
python3 -B scripts/tools/check_binding_lifecycle.py --output work/m25/lifecycle
python3 -B scripts/tools/summarize_binding.py --input work/m25 --output docs
python3 -B scripts/tools/run_labor_market.py --verify-pins docs/M24_RUNS.csv --output work/m25/m24-controls
python3 -B scripts/tools/run_labor_market.py --fixtures --verify-pins docs/M24_VACANCIES.csv --output work/m25/m24-fixtures
python3 -B scripts/tools/run_labor_market.py --legacy-controls --output work/m25/m23-controls
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m25/historical.csv
```

Use the unchanged M23/M24 documented C/D capture recipe with `work/m25/legacy-controls`,
then `measure_planning_jobs.py --phase audit --output work/m25/legacy-controls`.
The M22 smoke remains `performance_smoke.py --output work/m25/smoke.json`.
Full native traces are transient audit inputs, not committed event dumps.

## Assessment and review boundary

Binding obligations, genuine attendance, lawful maturity and conserved unpaid
claims work technically. That does not establish economic viability. Forecasts
remain local and fallible; integer lots, fixed prices/targets, volatile yesterday
sales, continued-staff assumptions and finite visitor money can terminate real
jobs and break production chains. Matching and rehire help relative to the
predeclared restricted control but do not guarantee recovery, food distribution
or stability. Historical parameters are not replaced. No dynamic wages, skill
progression, credit market, intentional breach policy, court, new sector or M26
was implemented. Stop after M25 for review.
