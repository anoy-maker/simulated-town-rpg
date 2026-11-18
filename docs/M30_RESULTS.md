# M30 — Negotiated wages: actual results

Implemented issue [45](https://github.com/anoy-maker/simulated-town-rpg/issues/45)
from exact reviewed M29 base `9f7268e130d5e1efa341c858e9b14c4d42ab5e80`, on
`codex/m30-dynamic-wages`. The revised direct-bidding specification supersedes
neutral rotation. Protocol commit **e58c8e2** preceded outcomes; technical witnesses
and historical control provenance were committed separately before the matrix.
Implementation **7038575** produced the final native model; later commits add
read-only evidence exporters. No parameters, priors, ordering, recipes, targets,
prices or population were changed after results. Stop M30 for review; no M31,
merging of stacked drafts, dynamic-wage adoption or economic rescue.

**Finding:** Actual lawful wage bids change hiring and reduce some workers'
exclusion, but this frozen institution worsens aggregate resident food access in
all six matched thirty-day worlds. Reference bread production stops after day7.
No automatic run earns a wage below six coins; wages below ten and unemployment
are distinct. Technical correctness is not economic viability, and the contrast
is an entire bargaining institution, **not an isolated exogenous wage cut**.

## Institution and preserved behavior

The opt-in scenario is `settlement_dynamic_wages`. F=`fixed10_instrumented`
delegates historical M29 `R_input_aware` decisions and adds passive observations.
W=`worker_bids` uses the same local15:55 bakery meeting, existing schedules,
verified work/standby, binding three-day terms and midnight next-day entry.
Original eleven terms stay10 through days1–3. All six matched worlds have exactly
identical first three full daily economic results. Raw F instrumentation hashes
change; fourteen **complete normalized economic event/receipt/report** controls
match historical pins. The exact new-event whitelist retains historical
`wage_payment_applied`; it does not remove everything prefixed `wage_`.

All worlds retain15 residents/four management-only owners, four firms, installed
slots3/3/3/2, prices2/5/6/4, physical grain competition, whole recipes, labor rules,
need/utility, distributions, M26 local demand and M28 input-fill estimation.
Initial actual currency is9192 and goods zero. `households_330` is the existing
separate M29 initial-cash sensitivity; no money is introduced afterward.

W workers choose one personally witnessed public notice and whole-coin ask1–20.
They compare conditional three-day household utility over no new wage, weighted
by the frozen own-anchor Beta heuristic and at most six comparable completed own
applications. Today's remaining basket is a common no-new-wage prelude; wages
start next day. Exact ties prefer higher ask then stable notice ID. Known bread
quotes are required; ale is included only when personally observed. Goods
availability in this budget is a conditional assumption, never a reservation.
No rivals' asks, business cash, allocation label, future sales or researcher
feasibility information is disclosed. Outcomes become knowledge only at the
next physically attended board; an unfilled/canceled post is unknown.

Firms evaluate submitted asks and retained actual salaries with their own cash,
inputs, local demand/fill beliefs and installed capacity. Strictly positive new
marginal contribution, projected solvency and current first-day funding are
required. Financial ties retain incumbents, then stable worker IDs. The current
cash gate covers arrears, salaries and prospective missing inputs; conditional
later-today sales are valuation evidence, not current cash. **F does not gain this
veto.** Its actual ten-coin choices are passively tested offline against the same
gate, making this institutional difference explicit. Offer, acceptance and
midnight recheck are authoritative. No locked term is repriced. Actual salary
drives claims, full-pay productive authorization, standby, arrears and guarantees;
old liabilities survive expiry. Retained three-day forecast continuation is a
conservative assumption, not an extension of legal rights.

See the [full frozen mathematics](M30_DYNAMIC_WAGE_FEASIBILITY.md),
[technical witnesses](M30_TECHNICAL_FIXTURES.md), and
[schemas and denominator definitions](M30_SCHEMAS.md).

## Frozen experiments

Seed42 only; four original-endowment conditions ×F/W ×1/3/30 days ×two distinct
processes =24 cases/48 captures. Two sensitivity conditions ×F/W ×30 ×two
processes add4 cases/8 captures: **28 cases,56 captures** total. All complete
reports and economic ledgers replay identically within each pair, independently
audited. Sixteen short cases were captured at the final checkpoint and reused
only with exact model/engine hashes; twelve long cases were captured afterward
without concurrent verification. No365-day, extra-seed or fitted-prior sweep.

The following cells are **F→W**, not percentages. Each30-day world needs450
resident meals. Sensitivity rows are separated by their allocation label.

| Condition | Initial allocation | Resident meals | Productive shifts | Paid wages | Bread made | Ale made |
| --- | --- | --- | --- | --- | --- | --- |
| reference | original | 450→52 | 330→111 | 3300→1133 | 630→70 | 360→318 |
| tight | original | 398→52 | 230→109 | 2690→1092 | 476→70 | 186→306 |
| scarce | original | 355→273 | 225→195 | 2490→1995 | 420→308 | 252→300 |
| no_brew_request | original | 317→272 | 171→128 | 1910→1333 | 441→329 | 0→0 |
| scarce | households_330 | 391→290 | 225→195 | 2580→2023 | 427→308 | 240→300 |
| no_brew_request | households_330 | 353→291 | 171→125 | 1950→1269 | 441→315 | 0→0 |

Reference and tight W both consume only52 meals:45 during initial contracts,
seven on day7, none during days11–30. Scarce W still consumes108 meals during
days21–30 (household sensitivity114); no-brew W consumes105 (sensitivity104).
These latter worlds remain active within the horizon, but neither proves a
long-run repeating state. All matrix claims are fully paid; there are zero
unpaid accrued coins in these twelve worlds. Standby remains paid and consumes
capital; it is not productive employment.

## Wage formation, renewal and exclusion

Automatic asks across the six W worlds:10 in463 submissions,9 in442,8 in216,7 in46,
6 in22. Actual successor hires:10 at72,9 at120,8 at63,7 at11,6 at11; total277.
No automatic ask/hire exceeds10 or falls below6. Higher asks and rational below6
choices are possible under the frozen mathematics and are demonstrated in
focused private-budget fixtures; they are not claimed as automatic outcomes.

The wage statistic below is among **actual paid claim-worker-days**, not all
residents or unemployed days. All eleven workers receive pay in the initial
period, so each case has11 distinct paid workers. F always has nominal mean and
median10; its paid-day counts are shown. Owners receive distributions, not wages.

| Condition/allocation | Paid days F→W | W mean / median | W earned days below10 | Longest below10 spell | Eligible W no-notice days |
| --- | --- | --- | --- | --- | --- |
| reference/original | 330→125 | 9.064 / 10 | 59 | 9 | 70 |
| tight/original | 269→124 | 8.806 / 10 | 58 | 12 | 54 |
| scarce/original | 249→216 | 9.236 / 9 | 135 | 21 | 0 |
| no_brew_request/original | 191→146 | 9.130 / 9 | 83 | 12 | 5 |
| scarce/households_330 | 258→216 | 9.366 / 9 | 135 | 23 | 0 |
| no_brew_request/households_330 | 195→141 | 9.000 / 9 | 84 | 14 | 7 |

There are **zero earned days strictly below6** in all automatic cases, hence no
prolonged below-bread wage spell. The 23-day below10 spell is Kira in household
scarce, days8–30; original scarce Kira has21 consecutive earning days below10,
days8–28. A below10 wage can still buy bread6. In original scarce,135 such paid
days include110 meals and25 misses, not135 misses. The separate real-authority
witness lawfully contracts at5 and earns a five-coin claim; this is not an extra
policy arm or evidence the automatic policy chose5.

**A real economic replacement:** original scarce day7, brewery selection event
9560 selects Kira9 and Lyle9, contribution54. Replacing Kira with expiring
incumbent Dain10 gives an otherwise feasible portfolio contribution51. Kira's
term starts day8. This is higher firm value, not worker skill or forced rotation.
At exact financial equality, incumbent priority remains: reference day3 Nell and
Oren retain the brewery's two posts over nine outside10-coin requests. Focused
one-slot tests separately prove outsider8 beats incumbent10 when genuinely
profitable and equal asks retain the incumbent.

The following counts are actual native applications/entries. Unselected at a
filled notice is distinct from an unfilled notice and from no observed vacancy.
An actual eventual outcome might remain unobserved to its worker at day30.

| W condition/allocation | Bids / hires | Unselected, filled notice | Unselected, unfilled notice | Own outcome not yet observed | Continuous renewals / returns / switches |
| --- | --- | --- | --- | --- | --- |
| reference/original | 176 / 33 | 111 | 32 | 10 | 14 / 4 / 15 |
| tight/original | 193 / 32 | 131 | 30 | 10 | 17 / 3 / 12 |
| scarce/original | 183 / 66 | 103 | 14 | 5 | 41 / 6 / 19 |
| no_brew_request/original | 227 / 41 | 110 | 76 | 10 | 20 / 9 / 12 |
| scarce/households_330 | 183 / 66 | 100 | 17 | 5 | 43 / 9 / 14 |
| no_brew_request/households_330 | 227 / 39 | 133 | 55 | 7 | 9 / 9 / 21 |

All eleven workers are physically present at every observed meeting. The 3960-row
participation table retains330 worker-days per case, locked terms separately,
observed notices, competing applicants, requested terms, portfolio financial
value/rank, acceptance, next-day entry and reasons. In original scarce W, the183
eligible submissions yield66 hires and117 nonselections:68 exact-value ties,
35 higher-value competing portfolios and14 without strictly positive marginal
gain at the submitted wage. No eligible day lacks a notice in that world;
reference W instead has70 eligible no-notice days. These are different forms of
exclusion. A no-notice day never adds a worker's failed-application pseudocount.

Across W worlds there are144 continuous same-firm successor terms,40 returns
after gaps and93 employer changes. These are not 277 forced rotations: firms
choose actual asks, and workers can leave their own renewal unrequested. Paths
and repeated losses/rehiring remain named in `WORKER_CYCLES`; unselected actual
filled-notice bids total688, with unknown outcomes kept separate.

## Food, cash and business feedback

Immediate missed-meal classifications prioritize insufficient shopping cash;
that partition alone does not imply shelf stock existed. The distinct
`cash_blocked_with_stock` resident/day field tests actual cash shortage despite
available food. Late19:00 distributions cannot buy16:00 bread retroactively.

| Condition/allocation | Cash-blocked misses F→W | Solvent stockouts F→W | Resident ale F→W | Visitor ale F→W | Cash circulation F→W |
| --- | --- | --- | --- | --- | --- |
| reference/original | 0→118 | 0→280 | 359→274 | 1→44 | 13950→4230 |
| tight/original | 52→122 | 0→276 | 186→258 | 0→48 | 9770→4122 |
| scarce/original | 94→92 | 1→85 | 234→278 | 18→22 | 9408→7959 |
| no_brew_request/original | 124→109 | 9→69 | 0→0 | 0→0 | 7557→5653 |
| scarce/households_330 | 54→64 | 5→96 | 235→296 | 5→4 | 9421→7959 |
| no_brew_request/households_330 | 83→46 | 14→113 | 0→0 | 0→0 | 7557→5436 |

Original scarce W has75 resident-days unable to afford bread **while shelf stock
is present**, versus94 in F. This narrower financial-access count improves even
though total resident meals fall355→273: solvent stockouts increase1→85 and
wages2490→1995. Household purchasing power and production disruption coexist;
neither a lower wage nor insufficient money alone explains all misses.
The household sensitivity moves scarce W cash/stock misses to64/96 and meals290,
with unchanged prices and policy. It does not restore the fixed-ten result391.

W does not uniformly increase firm margins or uniformly hurt brewery revenue.
Original scarce brewery revenue rises1008→1200 and its input-expensed accrued
margin156→373; bakery revenue falls2520→1848, mill1500→1100, farm852→750.
Resident ale rises234→278, visitor ale18→22 despite worse bread access. Reference
instead has resident ale359→274, visitor ale1→44, and total ale360→318. Visitor
substitution and surviving brewery activity are distinct from universal household
food access. Aggregate production and sales are not inferred from hypothetical
consumer intent; all values come from actual authoritative goods/payment events.

Original scarce business results, **F→W**:

| Business | Sales | Paid inputs | Actual wages | Accrued margin | Owner distributions | Final cash |
| --- | --- | --- | --- | --- | --- | --- |
| farm | 852→750 | 0→0 | 630→512 | 222→238 | 222→238 | 120→120 |
| mill | 1500→1100 | 600→450 | 630→486 | 270→164 | 270→177 | 120→107 |
| bakery | 2520→1848 | 1500→1100 | 630→470 | 390→278 | 390→278 | 120→120 |
| brewery | 1008→1200 | 252→300 | 600→527 | 156→373 | 156→373 | 120→120 |

Margins expense purchases and earned pay without inventory valuation; these are
not formal accounting profits. Mill W closes with5 flour and107 coins, farm with
2 wheat, bakery/brewery with zero goods. Every other final inventory is in
`FIRMS`/`RESIDENTS`. Across all W cases fully paid standby days are14/15/21/18/21/16
(reference/tight/scarce/no-brew/scarce-household/no-brew-household). Standby makes
cash claims even without output; full pay remains required for productive work.

The following final wealth still reconciles to9192 in every world. Household
cash includes owners; visitor money is a separate existing account.

| Condition/allocation | Household cash F→W | Business cash F→W | Visitor cash F→W | Owner distributions F→W |
| --- | --- | --- | --- | --- |
| reference/original | 1174→522 | 480→332 | 7538→8338 | 1920→707 |
| tight/original | 562→538 | 476→332 | 8154→8322 | 914→700 |
| scarce/original | 552→401 | 480→467 | 8160→8324 | 1038→1066 |
| no_brew_request/original | 894→492 | 420→420 | 7878→8280 | 796→701 |
| scarce/households_330 | 658→557 | 478→467 | 8056→8168 | 944→1038 |
| no_brew_request/households_330 | 1008→635 | 420→409 | 7764→8148 | 756→692 |

Named original-scarce households, **F→W**. Owner wages remain zero; owner income
is separately retained in the resident evidence. Gains to formerly excluded
Gale/Kira/Lyle coexist with losses to other employees and owners.

| Resident | Actual wages | Missed meals | Final personal cash |
| --- | --- | --- | --- |
| ada | 0→0 | 3→8 | 14→28 |
| bram | 0→0 | 3→13 | 10→21 |
| cora | 0→0 | 3→11 | 118→90 |
| dain | 300→231 | 0→5 | 6→3 |
| edda | 300→173 | 0→11 | 6→1 |
| finn | 300→189 | 0→10 | 6→3 |
| gale | 30→210 | 26→9 | 0→2 |
| hale | 300→114 | 0→18 | 54→0 |
| iona | 300→177 | 0→11 | 74→1 |
| jory | 300→172 | 0→14 | 78→6 |
| kira | 30→219 | 26→12 | 0→25 |
| lyle | 30→192 | 26→12 | 0→6 |
| mara | 0→0 | 7→13 | 12→193 |
| nell | 300→154 | 0→15 | 82→10 |
| oren | 300→164 | 1→15 | 92→12 |

Original scarce worker paid-wage HHI falls0.11656→0.09358 (equal eleven-worker
shares would be1/11), while total wages and meals fall. This is not a welfare
improvement metric. W reference production concentrates47.75% of shifts at the
brewery; all share vectors and denominators are in `CONCENTRATION`. Owner Mara's
scarce final cash rises12→193 while other households lose. Whole-world feedback
must not be replaced with imagined swaps of recorded bid IDs.

## Why the reference chain collapses

This is a documented limitation of the frozen institution, not a repaired result.
At reference day3's board, F's actual three-baker10-coin choice has current cash15
and first-day salary/input front cost105. F's inherited forecast can count
conditional remaining-day revenue; W's current-cash test does not. Even minimum
new salaries cannot fund the same bakery commitment at that time, so W posts no
bakery notice. F violates the passive stricter gate on66 actual new-commitment
firm-days overall (10 reference,14 tight,10 scarce,9 no-brew,14 scarce-household,
9 no-brew-household). This does **not** make F transactions unauditable: actual
entry/work/input transactions still require legally available funds.

Reference W day3 has three observed public notices. Equal private utilities and
priors lead all eleven workers to the same stable first notice, brewery, at10.
Nell/Oren renew; the other nine do not apply to farm/mill. Day4 consequently has
no productive shift, no new bread and15 solvent missed meals. Day4 bids herd to
bakery; day5 to farm; day6 to mill. Delayed/partial chain recovery produces only
seven bread on day7. Bakery's last productive day is7, mill's8; farm and brewery
continue through30. The interruption occurs **before any lower wage starts**.
Later low demand and request histories cannot guarantee chain restart.

Thus the 52-versus-450 result cannot be described as “cheaper wages caused hunger”
or as a pure comparison of incumbent preferences. The frozen real-cash timing,
one-application/stable-notice rule, bounded subjective beliefs and endogenous
firm/input/demand feedback all form the treatment. No extra arm or post-result
policy fix was added to isolate them. Scarce/no-brew retain business activity
but show their own unequal household access; they are not equilibrium evidence.

## Correctness, verification and development failures

Final acceptance **passed**, with no unresolved correctness failures. Exact
commands, hashes, source checks and phase walls are in `M30_VERIFICATION.json`.

| Verification | Actual result |
| --- | --- |
| Complete Godot suite | **3482 checks,0 failures**;3416 previous checks +66 M30 |
| Complete isolated Python suite | **149 methods,OK**;140 previous +9 M30;241.156s unittest wall |
| Original canonical payloads | **169/169 byte hashes unchanged** |
| M23–M25 published controls/fixtures/lifecycles | **88 report/ledger pairs unchanged**, independent audits |
| M26 / M27 |36 fresh M26 pairs and36 exact diagnostic digests;48 proofs,16 complete committed certificates;12 M25 parity cases;8 additional pinned M26 controls |
| M28 / M29 |**76 fresh cases**:28 M28 and48 M29;17 normalized M28/R parities,16 literal M29-original/M28 native parities |
| New F controls |14 complete economic event/receipt/report parities:10 direct M29 pins,4 explicitly M28-derived short pins |
| New experiment determinism/conservation |28 cases/56 distinct process captures fully audited;9192 actual coins; six initial three-day daily-economic parity pairs |
| Original C/D acceptance |12 original independent audits rerun;38 exact reachable source dependencies, same engine/native builds and12 published raw hashes |
| Technical authority witnesses / CLI |Three fresh labeled fixtures fully audited; compact opt-in dispatch matches the audited direct runner |
| Isolated M22 smoke |Correct canonical/proposal/queue checks; **zero warnings**, comparable reference metadata;2.515s smoke collector wall |

Full native command983.632s, historical pin sweep1593.106s, isolated Python
command241.693s, fresh M28/M29 controls1732.254s, original C/D audits607.187s.
These correctness walls overlap; see `M30_VERIFICATION_PHASES.csv`, not their sum.
Full logs and all retained development failures are committed separately as
`M30_TEST_LOG.txt` and `M30_DEVELOPMENT_FIRST.txt`. Original fixed-ten forecast,
input projection, recipes/configuration, initializers and native kernels are
byte-identical to the reviewed base. The simulation, wage auditor and focused-test sources stay unchanged from
implementation7038575 throughout final checkpoint, experiments and acceptance;
later commits add read-only control and evidence exporters.

Focused native checks cover exact all-ten trajectory parity, mixed wages,
incumbent financial ties, real wage advantages, current cash, private budgets,
observed offers/refusals, locked/duplicate/forged/invalid wages and sources,
natural expiry, cancellation, no-show and safe invalid authority calls.
Independent Python tests rehash fourteen forged traces and reject private/future
information, changed asks/quotes/salaries, due/paid wages, lost liabilities,
false predicted inputs, utility/prior changes, commodity/currency errors and
capacity violations. The old fixed-ten auditor still rejects a forged8 claim.

Three declared native technical witnesses were captured and fully audited again:
10/8/5 successors with real payments/work; partial5 paid2 with3 coins owed after
expiry and no productive authorization from partial pay; actual Kira absence
with no unearned5 claim. Their altered initial treasury in the partial witness
is explicitly labeled, conserved, and never mixed with matrix outcomes.

Development failures were retained rather than hidden: an initial GDScript
`Projection` name collision; two wrong test expectations about an anchor3
household (fixture corrected to anchor5, policy unchanged); overbroad parity
filter accidentally dropping historical `wage_payment_applied`; missing new-event
whitelist entry for `wage_portfolio_selected`. Corrected before final matrix.
A successful earlier32-capture checkpoint was discarded after authority/API and
observation hardening changed its source fingerprint; all32 were recaptured.
Reporting preparation also corrected an unselected-bid applicant-count join and
a scratch dependency-helper import (`host`, not nonexistent `metadata`). None
changed a parameter or economic choice to improve results.

## Measured costs and limits

Godot4.6.3, Python3.12.14, Linux x86_64, three visible CPUs/two-CPU quota,8GiB.
Sequential isolated30-day capture run-only medians pooled over the six cases and
two repeats: F3.995s, W4.788s; ranges3.446–4.997s and4.119–5.200s. These mixed-world
samples are not a like-for-like optimized workload benchmark. Independent audit
medians5.557s/5.537s, maxima6.158s/6.219s. Actual process peak RSS maxima841.54MiB F,
1078.99MiB W. Worst measured headless appointment103.333ms F,415.217ms W; no
player-facing responsiveness is established. The small policy has no Rust port.

Final checkpoint command50.205s; final driver492.864s includes re-auditing reused
short evidence, long capture/audit/replay and historical comparisons, not only
simulation work. Original discarded checkpoint49.830s is separate development
cost. Correctness lanes overlap on the shared host; do not sum their walls as
elapsed work or infer simulation speed from them. Full Python and final smoke
are isolated. Larger private-observation/candidate tables are compressed without
dropping rows; raw full traces stay outside git with hashes and reproduction.

This is seed42/30 days and a tiny disclosed game. Priors are fallible assumptions,
not measured hiring probabilities; evidence is sparse and context-specific.
No high-ask/prior sensitivity, longer-run equilibrium or representative labor-market
claim is supported. Firms' retained continuation, conditional sales/input beliefs
and household availability assumptions can fail. Source-linked budgets prove
rationality only under those declared beliefs; they do not prove optimal market
knowledge. Current-commitment labor selection still uses sunk guaranteed wages,
whereas new hiring charges the full actual term wage. Neither cheaper work nor
initial wealth guarantees more bread or higher aggregate utility.

Literature framing follows the issue's [Treasury labor-market report](https://home.treasury.gov/system/files/136/State-of-Labor-Market-Competition-2022.pdf),
[wage-setting protocols](https://www.sciencedirect.com/science/article/pii/S0927537125001307)
and [agent-based labor-market dynamics](https://link.springer.com/article/10.1007/s11403-026-00481-7).
These motivate a limited computational experiment; no empirical calibration or
validation against those studies is claimed.

## Reproduction and review boundary

```sh
# Focused checks, then complete suites (run full Python alone).
godot --headless --no-header --path . --script res://tests/run_wage_tests.gd
python3 -B -m unittest discover -s tests -p test_wages.py
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'

# 16 short cases; final driver finds checkpoint as output's sibling.
python3 -B scripts/tools/run_wages.py --checkpoint --output work/m30/checkpoint --traces work/m30/traces
python3 -B scripts/tools/run_wages.py --reuse-checkpoint --output work/m30/experiments --traces work/m30/traces
python3 -B scripts/tools/summarize_wages.py --input work/m30/experiments --traces work/m30/traces --output work/m30/tables

# Fresh M28/M29 published controls after the shared authority hooks.
python3 -B scripts/tools/check_wage_controls.py --output work/m30/m28-m29-controls
```

Without historical raw comparison caches the driver executes comparison worlds
fresh. Actual experiment captures remain two distinct processes per case. The
verification manifest lists all other historical/audit/smoke commands and source
checks, with actual phases and statuses. See `M30_SCHEMAS.md` for all compact
source-linked tables and `M30_CAPTURE_MANIFEST.csv` for raw payload hashes.

**Review decision:** Keep W optional. Real wage competition and immutable variable
salary accounting work, but no viable economy or superior matching rule is
adopted. Review the disclosed timing/notice/knowledge limitations before proposing
another experiment. M31 and economic policy tuning have not begun.
