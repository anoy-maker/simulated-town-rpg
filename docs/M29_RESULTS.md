# M29 — Whose initial cash matters?

Extra initial non-owner cash increases resident meals in every constrained
condition under both fixed policies. Extra firm capital changes constrained
baseline behavior, but leaves input-aware production, jobs and meals unchanged.
Neither treatment eliminates constrained hunger. Some residents lose food or
employment despite aggregate gains; two baseline treatments create genuine
unpaid wage claims. These are counterfactual initial ownership results, not an
adopted benefit policy or a sustainable economic baseline.

Issue [#43](https://github.com/anoy-maker/simulated-town-rpg/issues/43), branch
`codex/m29-cash-allocation`, exact reviewed M28 base
`29aae2f3852965968a9cefcf06f508c2ff469890`. The
[protocol](M29_CASH_ALLOCATION_FEASIBILITY.md) was committed as `40669ad`
before longitudinal comparisons; implementation `d05885e`, final source
`9c00b03`. No policy, price, wage, recipe, target, term maturity or economic
parameter was tuned after viewing results. No M30 work or default adoption.

## Isolation and initial ownership

The new opt-in `settlement_cash_allocation` world changes only creation-time
cash. Its initializer wraps the unchanged M28 source world; the full timetable,
B/I policies, observations, authoritative purchases, physical clearing, labor,
claims, three-day guarantees and distributions remain inherited. Research
metadata is outside agent observations and snapshots. No new economic event,
reservation, transfer policy, debt facility or kernel is introduced.

| Allocation | Four owners, each | Eleven non-owners, each | Farm / mill / bakery / brewery | External visitors | Total |
| --- | ---: | ---: | --- | ---: | ---: |
| original |6|6|120 /120 /120 /120|8622|9192|
| households_330 |6|36|120 /120 /120 /120|8292|9192|
| firms_330 |6|6|203 /203 /202 /202|8292|9192|

The same330 coins have different initial owners, drawn from the same external
account. These are not wages, profit, later payments or added purchasing power
from a new source. All twenty real account IDs and all eleven existing employee
terms are checked independently. Initialization event1/day0/minute0 supplies
provenance; commodities, operating receipts and accrued wage claims start at zero.
Existing future employment guarantees remain binding. Initial firm
capital never enters sales/profit books. The existing120 payout threshold and
realized-income restriction remain unchanged, including actual later payouts.

Visitors retain six visits/day and a combined ten-coin bread/ale allowance per
visit. Their smallest final account is7208, so external account exhaustion does
not explain these30-day differences. Their wallet and private allowance remain
separate. Resident bread need remains one/day, with no food reservation or rescue.

## Frozen matrix and actual thirty-day outcomes

Seed42 only. Primary scarce/no_brew_request × B/I × three allocations ×1/3/30
days gives36 cases/72 captures. Secondary tight/reference × B/I × three allocations
×30 days gives12 cases/24 captures, independently reported below. Each case has
two fresh processes with identical complete reports/events. The final matrix
reuses the48 actual short checkpoint captures under exact engine/model fingerprints;
all48 thirty-day captures are fresh. Repeats prove determinism, not independent
towns or statistical generality.

B=`R_baseline_instrumented`; I=`R_input_aware`. Need is450 resident meals/case;
visitor bread is separate. H/F abbreviate households_330/firms_330. Jobs are
terminal active affiliations, which can include next-day terms. Wages are actual
coins paid, distinct from accrued expense and arrears.

### Primary

| Condition / policy / allocation | Resident eaten / missed | Visitor bread | Wheat / flour / bread / ale | Paid wages | Productive / standby | Jobs | Arrears |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
|scarce /B /O|378 /72|70|384 /320 /448 /120|2610|205 /56|6|0|
|scarce /B /H|382 /68|66|384 /320 /448 /120|2610|205 /56|6|0|
|scarce /B /F|385 /65|77|426 /330 /462 /192|2850|227 /58|9|0|
|scarce /I /O|355 /95|65|426 /300 /420 /252|2490|225 /24|8|0|
|scarce /I /H|391 /59|36|426 /305 /427 /240|2580|225 /33|8|0|
|scarce /I /F|355 /95|65|426 /300 /420 /252|2490|225 /24|8|0|
|no_brew_request /B /O|325 /125|116|315 /315 /441 /0|1920|171 /21|5|0|
|no_brew_request /B /H|381 /69|95|350 /340 /476 /0|2170|186 /31|6|0|
|no_brew_request /B /F|325 /125|116|315 /315 /441 /0|1920|171 /21|5|0|
|no_brew_request /I /O|317 /133|124|315 /315 /441 /0|1910|171 /20|6|0|
|no_brew_request /I /H|353 /97|88|315 /315 /441 /0|1950|171 /24|6|0|
|no_brew_request /I /F|317 /133|124|315 /315 /441 /0|1910|171 /20|6|0|

### Secondary

| Condition / policy / allocation | Resident eaten / missed | Visitor bread | Wheat / flour / bread / ale | Paid wages | Productive / standby | Jobs | Arrears |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
|tight /B /O|395 /55|102|414 /360 /497 /84|2610|217 /44|5|0|
|tight /B /H|408 /42|96|414 /360 /504 /102|2704|221 /50|6|6|
|tight /B /F|413 /37|98|435 /365 /511 /132|2946|231 /64|9|4|
|tight /I /O|398 /52|78|435 /340 /476 /186|2690|230 /39|8|0|
|tight /I /H|409 /41|109|414 /375 /518 /78|2640|222 /42|5|0|
|tight /I /F|398 /52|78|435 /340 /476 /186|2690|230 /39|8|0|
|reference /B /O|450 /0|180|630 /450 /630 /360|3300|330 /0|11|0|
|reference /B /H|450 /0|180|630 /450 /630 /360|3300|330 /0|11|0|
|reference /B /F|450 /0|180|630 /450 /630 /360|3300|330 /0|11|0|
|reference /I /O|450 /0|180|630 /450 /630 /360|3300|330 /0|11|0|
|reference /I /H|450 /0|180|630 /450 /630 /360|3300|330 /0|11|0|
|reference /I /F|450 /0|180|630 /450 /630 /360|3300|330 /0|11|0|

Reference serves all450 resident meals in every allocation/arm, with330 shifts,
3300 wages and13950 circulation. Extra cash stays with its recipients there;
production, food and employment do not improve. Tight/reference secondary counts
are not mixed into primary short-horizon counts.

## Matched effects and mechanisms

At fixed B, household cash adds4 scarce and56 no-brew resident meals; at fixed I,
it adds36 in each primary condition. Tight adds13/11 under B/I. These gains do
not share one mechanism:

- Scarce B H produces the same448 bread and shifts four from visitors to
  residents; wages, work and circulation remain unchanged.
- Scarce I H produces seven more bread, shifts29 from visitors, pays90 more
  wages and supplies36 more resident meals. Circulation rises only13,9408→9421.
  Cash-blocked misses fall94→54 while solvent stockouts rise1→5. The extra
  demand does not remove physical food constraints.
- No-brew B H produces35 more bread, shifts21 from visitors and pays250 more
  wages, giving56 more resident meals. No-brew I H produces the same441 bread,
  shifts36 from visitors and pays40 more wages with unchanged7557 circulation.
- Tight I H makes42 more bread but108 less ale; productive shifts fall230→222,
  wages2690→2640 and jobs8→5 while resident meals rise398→409. Better food
  totals coexist with reduced work and a weaker brewery.

These are total effects of the initial ownership treatment, including actual
orders, local demand memories, renewals, sales and income feedback. They cannot
be attributed exclusively to recipients' direct purchases. Request counts change
with legitimate affordability, so raw cross-allocation counts are not comparable
latent-demand or forecast-accuracy samples.

Actual ale purchases are also separated by cohort in the shopping evidence:
scarce I O→H changes resident ale234→235 and visitor ale18→5, while output
falls252→240. Tight I's resident ale falls186→78 with zero visitor ale in both.
No-brew has no ale production or purchases. Reference retains359 resident and
one visitor ale under every allocation/arm. Extra initial cash does not override
the original needs, discretionary choices or visitor allowance.

At fixed B, firm capital adds7 scarce and18 tight resident meals, with14 more
bread in each. Scarce visitor bread also rises7, wages rise240, productive work
205→227 and jobs6→9. Tight wages rise336, but earned expense rises340; standby
44→64, jobs5→9 and brewery capital still reaches zero. No-brew B has unchanged
production, meals and work. At fixed I, **every tested condition's real economic
activity is unchanged by F**: business cash is simply330 higher and visitors330
lower than O. Additional available cash does not compel the unchanged planner
to make new contracts or produce.

The direct H versus F comparison consequently depends on policy/condition:
scarce B has382 versus385 meals; scarce I391 versus355; no-brew B381 versus325;
no-brew I353 versus317; tight B408 versus413; tight I409 versus398. No treatment
wins all comparisons. Within H, B→I changes scarce meals382→391, no-brew381→353
and tight408→409; within F it changes385→355,325→317 and413→398. Reference is
unchanged. All36 matched contrasts, including output, cash and labor, are in
[M29_COMPARISONS.csv](M29_COMPARISONS.csv).

## Individuals, timing and duration

All fifteen residents in every30-day case are listed in
[M29_RESIDENTS.csv](M29_RESIDENTS.csv), including initial/final cash, goods,
wages, ownership receipts, missed meals, work and arrears. As a complete named
example, scarce I O→H has:

| Resident | Missed meals O→H | Paid wages O→H | Ownership income O→H | Final coins O→H |
| --- | ---: | ---: | ---: | ---: |
|ada|3→3|0→0|222→220|14→8|
|bram|3→5|0→0|270→265|10→25|
|cora|3→4|0→0|390→287|118→25|
|mara|7→6|0→0|156→172|12→6|
|dain|0→0|300→300|0→0|6→40|
|edda|0→0|300→300|0→0|6→40|
|finn|0→0|300→300|0→0|6→40|
|gale|26→2|30→210|0→0|0→10|
|hale|0→0|300→300|0→0|54→100|
|iona|0→0|300→240|0→0|74→52|
|jory|0→10|300→120|0→0|78→0|
|kira|26→2|30→230|0→0|0→58|
|lyle|26→22|30→30|0→0|0→2|
|nell|0→0|300→300|0→0|82→132|
|oren|1→5|300→250|0→0|92→120|

Gale and Kira gain later earned work, not just the initial30; Lyle still earns
only30 and misses22 meals despite his endowment. Jory loses180 wages and goes
from zero to ten misses. Non-owner misses fall79→41 while owner misses rise16→18.
In no-brew I, Finn's misses worsen4→9 while Dain's improve4→0; tight I Mara's
misses worsen20→26 and her ownership receipts62→20. More aggregate food is not
universal improvement or a moralized welfare ranking.

| Condition / policy | H minus O meals, days1–10 /11–20 /21–30 | F minus O, same windows |
| --- | --- | --- |
|scarce /B|2 /0 /2|0 /0 /7|
|scarce /I|9 /16 /11|0 /0 /0|
|no_brew_request /B|6 /24 /26|0 /0 /0|
|no_brew_request /I|6 /20 /10|0 /0 /0|
|tight /B|5 /-8 /16|0 /0 /18|
|tight /I|2 /6 /3|0 /0 /0|

Benefits can persist through the last observed ten days, but are not monotonic:
tight B H loses eight meals in the middle window, despite a positive30-day total.
All cases retain some food-chain work through day30; that says nothing about365
days or continued access for every household. No annual extrapolation is made.

Native shopping-time evidence is retained rather than inferred from final cash.
In scarce I H on day2, Ada has two coins and14 bread on the shelf at16:00
(source IDs2250/2251), misses the meal at18:30 (event2972), and receives two
ownership coins only at19:00 (event3008). Her four closing coins cannot finance
the earlier purchase. [Failure rows](M29_FAILURES.csv) keep late income separate;
no cashless visit is invented as a credible stockout request. The same fixture
with added household cash still has14 bread/15 needs on day1: money cannot
fabricate the missing loaf.

## Firms, cash and genuine liabilities

The [firm table](M29_FIRMS.csv) retains every business/case, and
[firm/day evidence](M29_FIRM_DAYS.csv) includes minimum/closing cash, inputs,
held/cargo stock, accrued/paid wages, future guarantees, demand coverage and source
IDs. Closing capital relative to future guarantees describes payroll coverage;
it is not a formal runway forecast including future inputs/revenue. Margins
expense actual inputs and accrued wages without inventory valuation.

Scarce B F keeps brewery production through day30 instead of20, with32 versus20
productive shifts and closing130 instead of12 coins. Yet its accrued margin
remains negative,−24 versus−60. Scarce I F retains the original42 productive
shifts and+156 margin, merely closing at202 rather than120. Initial82 is never
booked as operating income. In reference F each business ends at its initial
203/203/202/202 while paying the same actual realized distributions as O.

Tight B's brewery is not rescued by either allocation:

| Allocation | Productive / standby | Sales / inputs / accrued wages | Accrued margin | Distributions | Final capital | Owed wages | Last production |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| O |14 /22|336 /84 /360|−108|12|0|0|17|
| H |17 /25|408 /102 /420|−114|12|0|6|23|
| F |22 /37|528 /132 /590|−194|12|0|4|28|

H day26 at14:00 pays Gale only4 of10, records breach39124 with claim
`0026:brewery:gale` and retains six owed coins. F day30 pays Oren6 of10 and
records breach45558/claim `0030:brewery:oren`, retaining four. Native term handling
remains unchanged; no debt is forgiven or minted. Payable/receivable claims match
independently and are distinct from9192 actual coins and conditional future wages.
No other30-day case ends with arrears. Extra working capital can prolong
loss-making employment and produce a larger negative margin.

Actual money is nonnegative and conserved after every transaction in all captures.
Final owner/non-owner/firm/visitor wealth is published for all24 cases in
[M29_OUTCOMES.csv](M29_OUTCOMES.csv), with daily paths in
[M29_DAYS.csv](M29_DAYS.csv). For scarce I O→H those groups change
154/398/480/8160→64/594/478/8056. Household liquidity benefits some workers while
owner wealth and brewery production can fall. Initial savings, actual wages,
19:00 distributions, accrued unpaid claims and future guarantees remain separate.

## Verification and measured costs

All required final checks passed. The [acceptance manifest](M29_VERIFICATION.json),
[test log](M29_TEST_LOG.txt), [phase walls](M29_VERIFICATION_PHASES.csv) and
[command record](M29_VERIFICATION_COMMANDS.txt) preserve the actual evidence.

| Check | Actual result |
| --- | --- |
| Complete Godot suite |3416 checks, zero failures; all3334 previous checks retained|
| Complete Python suite, isolated |140 methods passed; all133 previous methods retained; no queue timing failure|
| Focused final fixtures |82 native assertions and7 Python methods passed|
| Historical byte pins |169/169 unchanged|
| Published M23–M25 report/ledger pairs |88/88 unchanged and independently audited, including lifecycles|
| Fresh M26 controls |36/36 pinned pairs;12 M25/L economic parities and8 additional controls passed|
| M27 independent diagnostics/proofs |36 unchanged diagnostic digests;48 unchanged witness proofs;16 complete certificates checked|
| M28 controls |24 main and4 staggered pinned pairs re-audited;12 baseline,3 input-aware reference and2 staggered full economic parities recomputed|
| New matrix |48 cases/96 complete native captures audited and replay-identical; all16 original-allocation event/ledger comparisons literally equal M28, full reports differ only in declared scenario/research metadata|
| Opt-in CLI selection |Fresh three-day default-entrypoint report equals the audited checkpoint exactly|
| Original C/D audits |12/12 original numerical, financial, spatial and observation audits passed again|
| Isolated M22 smoke |Canonical/proposal/order/queue checks passed; matching reference metadata and zero advisory warnings|

All captures conserve9192 actual coins and forbid negative accounts after every
transfer; goods/cargo, real input receipts, private-information boundaries,
attendance, accrued claims, future terms and actual shopping time are independently
reconstructed. Eight rehashed initial/runtime forgeries reject. Existing duplicate
order, cashless request, budget and authority negatives remain in the full suites.
The export checks480 initial-account,360 resident,96 firm,2880 firm/day and720
day rows,96 capture hashes and36 matched contrasts against audited reports.

The [historical pins](M29_REGRESSIONS.csv), [88 published pairs](M29_HISTORICAL_CONTROLS.csv),
[M26/M27 checks](M29_M26_M27_CONTROLS.csv), [M27 proofs](M29_M27_PROOFS.csv),
[M28 pins](M29_M28_CONTROLS.csv), [M28/R parities](M29_M28_ECONOMIC_PARITY.csv),
[original audits](M29_ORIGINAL_AUDITS.csv) and [raw capture hashes](M29_CAPTURE_MANIFEST.csv)
retain individual evidence. M28 raw controls were reused only after unchanged
reachable-source/engine and pinned-payload checks, with full independent audits
rerun. C/D reuse additionally checks38 unchanged reachable files, native builds
and all12 published raw trace hashes; audits ran again. Source/cache evidence is
in the M28/CD dependency maps and source manifests. No cached audit conclusion
substitutes for event replay. Two original staggered R controls were freshly
captured for the additional parity proof, separately from the96 M29 captures.

The first focused development attempt had one failure and one error: tests used
obsolete `capital_floor` and nonexistent visitor `spent` fields. The actual fields
are the existing distribution-policy `reserve` and `bread_spending+ale_spending`.
These test assumptions were corrected before checkpoints, without changing the
economy or relaxing a bound; the [initial log](M29_DEVELOPMENT_FIRST.txt) is retained.
Godot's initial script abort exited zero, but the Python stderr check caught it;
final native check counts and clean logs are both required. A later console-only
correction labels original parity only on original rows; the completed matrix
already performed exactly the16 comparisons recorded in its CSV. No native,
capture, audit or economic logic changed. Final native sources match the tested
Godot tree; final Python ran on the corrected source. No unresolved correctness
failure or required unverified check remains.

Godot4.6.3, Linux x86_64, three visible CPUs/two-CPU quota and8GiB cgroup memory.
The short checkpoint took64.46s; the final matrix command784.03s includes re-audits
of cached short captures,48 fresh thirty-day captures and original controls.
For those48 fresh thirty-day captures, median simulation/report/whole-command
walls were3.76/2.72/8.82s; median independent audit5.63s. Native process peak RSS
ranged687–775MiB. Worst observed headless appointment/tick were108.31/68.37ms.
These sequential captures had no concurrent verification workload. Correctness
lanes later overlapped: Godot642.78s, historical1277.67s and isolated Python209.52s
are separate command walls, not quantities to sum into elapsed work. Final smoke
command wall2.99s. Headless timings are not rendered frame responsiveness,
comparative algorithm speedups or independent-population estimates.

## Reproduction and limitations

```sh
python3 -B scripts/tools/run_cash_allocation.py --checkpoint --output work/m29/checkpoint --traces work/m29/traces
python3 -B scripts/tools/run_cash_allocation.py --reuse-checkpoint --output work/m29/experiments --traces work/m29/traces
python3 -B scripts/tools/summarize_cash_allocation.py --input work/m29/experiments --traces work/m29/traces --output work/m29/published
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
```

`--old-traces` optionally supplies verified M28 raw controls; without it they are
captured and independently audited. Use writable XDG data/config/cache directories
when the host home is restricted. The [schemas](M29_SCHEMAS.md), initial-account
provenance, capture manifest and acceptance manifest describe exact joins,
checksums, commands and historical raw-trace reuse. Verbose traces remain outside
git; compact evidence does not substitute for the full event audits that ran.

This is one deterministic seed and30 days with prescribed preferences, fixed
prices, visitor funds, scheduling and existing forecasts. It identifies a causal
initial ownership sensitivity within that model, not a recurring transfer policy,
matched latent-demand forecast score, real-world distribution ranking or long-run
equilibrium. Firm liquidity is useful in some B cases, redundant under I, and
neither guarantees solvent wage payment or household food. Household liquidity
usually reduces cash blockers but cannot ensure bread, income or jobs for everyone.

A next isolated hypothesis could examine why renewed work excludes particular
households under unchanged liquidity; it needs its own reviewed protocol. No
employment/food reservation rule, benefit system or M30 is implemented. Stop at
M29 for review.
