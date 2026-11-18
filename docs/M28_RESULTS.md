# M28 — Owner-local input reliability and contractual employment

The frozen input forecast changes renewal decisions and can preserve brewery
capital, but **does not consistently improve household food access**. Main scarce
resident meals fall378→355 while brewery margin rises−60→156 and paid standby
falls. The treatment remains opt-in; it is not an adopted economic baseline.
No M29 work or price/wage reform is included.

Issue [#41](https://github.com/anoy-maker/simulated-town-rpg/issues/41), branch
`codex/m28-input-reliability`, exact reviewed M27 base
`e735df8cf3dd46fe32f2bee5b22f2b366cc70d73`. The
[protocol](M28_INPUT_FEASIBILITY.md) was committed as `f80b291` before comparative
outcomes. Native model fingerprint in both matrices is
`33b24031d0c29609653639c192c8aa0978ca83dd4068034962a56ea1eaa9a642`;
implementation `ad5737d`, final checks/export utilities `1bc23d2`.

## Frozen mechanism and knowledge boundary

The new `settlement_input_reliability` scenario inherits M26 R's timetable, demand
smoothing, procurement, work assignment, physical clearing, ten-coin guarantees,
three-day contracts, fixed prices/recipes/targets, initial resources and9192 coins.
No native transaction or current-term wage/production rule is replaced.

`R_baseline_instrumented` records input beliefs passively and uses the original
renewal forecast. `R_input_aware` changes only hypothetical new input availability
inside that same candidate solver. Default-preserving hooks let the existing
solver use a pure optional forecast callable; its original default remains intact.
All candidate headcounts, cash/claim gates, strict contribution comparison and
fewer-commitments tie behavior are retained.

Each buyer remembers only its own native funded, on-time, inspected grain/flour
orders and actual receipt links. Up to three completed same-supplier/item/price
days plus one optimistic K-lot pseudoday give exact `N=K+sum(filled)` and
`D=K+sum(requested)`. K is3/3/2 for mill/bakery/brewery. No eligible history gives
the original behavior. Today's morning order is excluded from today's15:55
estimate; the frozen point is reused at midnight without fitting visitors or
late cash. Missing or invalid orders are unknown, not failed supply observations.

For each prospective day the original planner first determines desired missing
lots k under the candidate's current modeled stocks/cash/staff. Only new purchases
are replaced by exact half-up rounded `k_pred=(2*k*N+D)//(2*D)`. Retain owned inputs,
charge predicted purchases, produce only from those inputs and retain all three
days' wages even when output is zero. These are predictions, not actual orders,
reservations or coins. Farm has no direct estimator. Its realized behavior can
still change through legitimate downstream market responses.

The policy receives no supplier private cash/stock, competitor orders, private
consumer funds or M27 optimum. Python uses those global facts only inside
independent verification and offline diagnostics. Own-input receipts and a seller's
own inbound-demand record remain distinct. The fill-rate heuristic is endogenous
to requested quantity, other buyers and employment; it is not a posterior,
independent-lot probability model or rational-expectations solution.

## Main thirty-day outcomes, seed42

Every main case ran in two fresh processes:24 cases/48 captures including1/3-day
checkpoints. Those32 short captures were reused after fingerprint/replay checks;
the16 thirty-day captures were fresh. All12 instrumented-baseline cases match the
original pinned M26 R's native economic events, complete report/state/obligations
and normalized receipt links. Extra input bookkeeping changes raw event hashes;
the old/new hashes are published separately rather than claimed identical.
All three input-aware reference horizons also match the complete original R
economics and receipt linkages; see [reference parity](M28_REFERENCE_PARITY.csv).

B denotes instrumented baseline, I denotes input-aware. Resident need is450 meals
per30-day case; visitors are separate. Reference is economically unchanged.

| Condition / arm | Resident eaten / missed | Visitor bread | Wheat / flour / bread / ale | Productive / standby | Cash wages | Circulation |
| --- | ---: | ---: | --- | ---: | ---: | ---: |
| Reference, B or I |450 /0|180|630 /450 /630 /360|330 /0|3300|13950|
| Tight B |395 /55|102|414 /360 /497 /84|217 /44|2610|9335|
| Tight I |398 /52|78|435 /340 /476 /186|230 /39|2690|9770|
| Scarce B |378 /72|70|384 /320 /448 /120|205 /56|2610|8840|
| Scarce I |355 /95|65|426 /300 /420 /252|225 /24|2490|9408|
| No brew B |325 /125|116|315 /315 /441 /0|171 /21|1920|7557|
| No brew I |317 /133|124|315 /315 /441 /0|171 /20|1910|7557|

All primary earned guarantees are paid, with zero arrears/breaches. More productive
shifts or circulation is not more bread: scarce I makes42 more wheat and132 more
ale, but28 fewer bread and23 fewer resident meals. Tight's three-meal gain occurs
with21 less bread and24 fewer visitor meals. No-brew produces the same441 bread
and shifts eight meals from residents to visitors. None is a single welfare score.

## Decisions, firms and individual consequences

The first tight difference is day3's brewery renewal. Its own two prior days each
requested2 lots and filled1, so `N/D=4/6`. B values two new employees at contribution48;
I predicts one of two desired lots per projected day and values that candidate
at−6 **including all60 promised wages**. One employee remains worth24, so I
chooses one. Current-day guarantees and work are identical; the new term starts
only after natural expiration at the boundary. Later market/staffing feedbacks
are endogenous, not additional policy interventions.

The exact rounding matters: after just one1-of2 fill, the optimistic prior gives
3/4 and a desired two lots still rounds to two. Two such samples give4/6 and
round two to one. Similarly, scarce food inputs go from5/6 (three desired rounds
to three) to7/9 (three rounds to two). These are the frozen integer thresholds,
not parameters selected after observing outcomes.

Scarce's brewery initially has full input history6/6 and is unchanged. The early
constraint instead reaches mill/bakery: their first two input days filled2 of3
lots, giving7/9. At day3 the treatment selects two rather than three food-chain
employees. It reduces expected input availability and pays all promised wages
when comparing candidates; it never waives an existing term. No-brew's first
headcount difference is bakery day12 with9/11. No brew order is ever invented to
learn brewery supply in that control.

| Main brewery | Productive / standby | Sales / inputs / wages | Input-expensed accrued margin | Distributions | Final cash | Last output day |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| Tight B |14 /22|336 /84 /360|−108|12|0|17|
| Tight I |31 /19|744 /186 /500|58|62|116|30|
| Scarce B |20 /22|480 /120 /420|−60|48|12|20|
| Scarce I |42 /18|1008 /252 /600|156|156|120|30|

These margins expense actual input purchases and earned wages without inventory
valuation. They are not formal inventory-valued profits. Treasury116 is below
the initial120; the existing distribution floor does not protect coins against
earned wages. No cash, food or obligation forgiveness is introduced. No-brew still
pays its initial brewery employees60 for standby, ends with60 and never brews.

Food-chain labor also changes. Scarce bakery/mill productive shifts each fall64→60,
standby22→3 and12→3, and wages860→630 and760→630. Three residents suffer persistent
income exclusion: Gale/Kira/Lyle each receive only their initial30 wage coins
and miss26 meals, versus6/2/11 misses in B. Mara's misses fall23→7 and her real
ownership income rises48→156. Preserving one business can coexist with serious
losses for other households.

Tight also has winners and losers: Gale/Kira misses6→0 each and Mara27→20, while
Oren0→14 and Nell0→3. No-brew Edda misses1→19 and Iona14→24 despite unchanged
aggregate bread/circulation. All fifteen residents' wages, ownership income,
spending, cash, inventories and daily shopping observations are retained in the
CSV evidence rather than replaced by averages.

Main final active jobs B→I are reference11→11, tight5→8, scarce6→8, no-brew5→6.
These include next-day accepted terms, not a count of productive shifts on day30.
Tight renewals73→76 and other entries6→10; scarce renewals75→80 but other entries
5→0. All constrained food chains produce through day30. Standby remains real;
no result establishes survival for365 days or after visitor funds run out.

## Household purchasing power and currency

The M27 read-only observer reconstructs the actual shopping turn, not final cash.
Across constrained main B cases,225 of252 missed meals are immediately cash
blocked, as in M26. I has270 of280 cash blocked: fewer solvent stockouts do not
mean more households can buy food.

| Condition | B cash / solvent-stockout failures | I cash / solvent-stockout failures |
| --- | ---: | ---: |
| Tight |55 /0|52 /0|
| Scarce |57 /15|94 /1|
| No brew |113 /12|124 /9|

These are evidence-backed immediate blockers with overlapping contextual flags,
not exclusive macroeconomic root causes. An empty shelf beside a cashless shopper
is not fabricated solvent demand. Late wage/distribution transfers cannot fund
the earlier shopping appointment.

| Main condition / arm | Household / business / external coins | Owner / non-owner household coins |
| --- | --- | --- |
| Reference, either |1174 /480 /7538|876 /298|
| Tight B |822 /360 /8010|202 /620|
| Tight I |562 /476 /8154|118 /444|
| Scarce B |658 /336 /8198|96 /562|
| Scarce I |552 /480 /8160|154 /398|
| No brew B |846 /420 /7926|336 /510|
| No brew I |894 /420 /7878|346 /548|

Each row sums to9192. The independent replay checks that total and nonnegative
balances after every transfer, actual goods/cargo source-sinks, and earned wage
payable/receivable parity. Future conditional guarantees remain separate from
coins and accrued debt. No account reset or simulated rescue creates these totals.

## Staggered sensitivity and forecast evidence

The frozen historical1/2/3-day initial maturities are a different legal endowment.
Four sensitivity cases ran twice in fresh processes; baseline matches the two
original staggered R cases. Their outcomes are kept separate from the main matrix.

| Staggered condition / arm | Resident / visitor bread | Bread output | Standby | Wages |
| --- | ---: | ---: | ---: | ---: |
| Tight B |363 /92|455|37|2610|
| Tight I |376 /79|455|30|2540|
| Scarce B |354 /80|434|31|2530|
| Scarce I |359 /75|434|27|2490|

Here resident gains13/5 displace exactly13/5 visitor meals with unchanged bread.
The sign of scarce's resident effect differs from the main case. Initial term
timing therefore matters; this is not general food-access evidence for the policy.

Input prediction is evaluated only when a genuine next-day positive order has
the same supplier/item/price **and desired lot quantity** as the chosen candidate's
first projected day. Each case has87 opportunities:29 days ×3 buying firms.

| Main condition | B comparable /87; total absolute lot error | I comparable /87; total absolute lot error |
| --- | --- | --- |
| Reference |87;0|87;0|
| Tight |75;39|85;34|
| Scarce |74;51|87;22|
| No brew |56;8|56;7|

Changed-size and absent orders remain explicit exclusions/unknowns. Different
coverage is selected endogenously by behavior, so these sums are not a matched
statistical accuracy ranking. No hidden hypothetical allocation, latent-supply
RMSE or fictitious measurement order is calculated. The estimator still omits
nonlinear grain competition, changing requested quantities and future counterparties.

## Verification, development findings and cost

Final acceptance is recorded in the [manifest](M28_VERIFICATION.json),
[phase walls](M28_VERIFICATION_PHASES.csv) and [test log](M28_TEST_LOG.txt).

| Check | Actual result |
| --- | --- |
| Complete Godot suite |3,334 checks, zero failures; all3,272 previous checks preserved|
| Final complete Python suite, isolated |133 methods passed; all123 previous methods preserved|
| Initial complete Python attempt, concurrent verification |133 methods, one old queue timing-challenge failure; retained below|
| Unmodified isolated queue tests |4 methods passed|
| Historical payload pins |169/169 original byte hashes unchanged|
| Published M23–M25 controls/fixtures/lifecycles |88/88 report-and-ledger pairs unchanged and independently audited|
| Fresh M26 controls |36/36 main report-and-ledger pairs unchanged;12 M25/L economic parity checks and8 additional pinned controls passed|
| M27 observer and independent witnesses |36/36 diagnostic digests and48/48 checkpoint proofs unchanged; all16 committed certificates checked|
| New main/sensitivity process replay |48/8 fresh captures audited; complete reports/events equal within each repeat pair|
| Baseline/control economics |12 main plus2 staggered B comparisons and3 input-aware reference horizons match complete original R economics|
| Original C/D numerical/financial/spatial/observation audits |12/12 passed again on verified unchanged-source native trace inputs|
| Final isolated M22 smoke |Passed canonical/proposal/order/queue checks with matching reference metadata and zero advisory warnings|

All required final checks ran; no unresolved accounting, provenance, policy-parity
or economic-conservation failure remains. The known shared-host queue-fixture
limitation is retained rather than hidden. [Historical pins](M28_REGRESSIONS.csv),
[published pairs](M28_HISTORICAL_CONTROLS.csv), [M26/M27 checks](M28_M26_M27_CONTROLS.csv),
[old proofs](M28_M27_PROOFS.csv), [original audits](M28_ORIGINAL_AUDITS.csv),
[C/D trace provenance](M28_CD_SOURCE_MANIFEST.csv) and
[dependency checks](M28_CD_DEPENDENCIES.json) retain individual evidence.
C/D's38 reachable GDScript files and native builds match M27; raw traces were
reused with exact published trace hashes, while independent audits ran again.

Focused checks passed62 native assertions and10 Python methods, covering whole-lot
full/partial/zero provenance, no-history/full-reliability candidate and daily cash/
wage identity, half-up/overflow rejection, quote context, duplicate/unknown orders,
owned inputs, all three days of standby wages, farm applicability, morning embargo,
baseline parity and deterministic replay. Native no-harvest/cashless/remote/invalid
fixtures preserve actual consequences and9192 coins. Rehashed forgeries of ratio,
future/foreign/private knowledge, price, wages, output, rounding, cash, receipts
and erased claims reject independently.

The separate `no_harvest` native fixture transfers the farm's initial120 coins
to visitors, so real harvest payroll fails while funded mill/brewery orders can
be entirely rationed; earned farm claims persist. `cashless_inputs` transfers
the mill/brewery's240 coins to visitors, producing no eligible wheat-order sample.
Both retain zero initial goods. Remote and invalid-attempt fixtures retain the
ordinary endowment and change only the test route or rejected command attempts.
These are technical witnesses, never longitudinal treatment resources.

Development caught a GDScript builtin-name collision, a pure owned-input test
that accidentally lacked payroll cash, and an exporter collision between daily
and full-term wage labels. Those were fixed before final acceptance; no economic
parameter or policy was tuned after longitudinal outcomes.
The initial parity helper also used report-digest newline conventions for ledger
hashing; native ledger encoding was restored before the checkpoint comparisons.
The original M27 observer only gains optional observer/fixture arguments; its default diagnostic
and certificate digests remain required historical checks. Its old CLI's exact-
source guard is preserved; `check_input_controls.py` runs those tools against
fresh pinned M26 traces on this branch rather than weakening the guard.

The first complete Python attempt ran133 tests with one failure in the existing
M22 `test_pool_and_order_parity`: its250ms delayed job did not demonstrate the
assumed reversal of completion order during concurrent verification. Proposal
and ordered-release validations had passed before that timing-dependent assertion.
The test and all eleven reachable queue source files are unchanged from M27.
All four unmodified queue tests subsequently passed in isolation. The first
failure log is retained rather than reclassified as a passing run; the complete
Python suite then passed all133 methods without concurrent verification.
No delay, queue assertion, economic policy or reference hash is weakened.
The [first-attempt traceback](M28_PYTHON_SHARED_HOST_FIRST.txt) and
[unchanged queue dependency hashes](M28_QUEUE_DEPENDENCIES.json) remain explicit.
The initial/final Python command walls were666.548/221.597 seconds; the isolated
queue check took5.413 seconds. This verifies the unchanged test in isolation,
not the robustness of its completion-order timing assumption under arbitrary load.

Checkpoint driver wall41.722s; main265.541s including re-auditing reused short
captures; staggered151.975s. Thirty-day captures ran without concurrent verification.
Medians of two fresh processes below; worst appointment/tick is the maximum over
both. Timings never enter canonical economic state.

| Main condition / arm | Run s | Command s | Report s | Peak KiB | Audit s | Worst appointment / tick ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Reference B |4.464|9.999|2.987|791868|5.457|114.897 /82.323|
| Reference I |4.156|9.118|2.662|793184|5.510|83.019 /7.435|
| Tight B |3.457|7.593|2.072|752620|5.289|48.364 /5.483|
| Tight I |4.481|9.452|2.418|763536|5.155|110.792 /17.697|
| Scarce B |3.850|8.590|2.440|756142|5.712|48.248 /9.822|
| Scarce I |3.654|8.129|2.379|750278|5.596|63.842 /6.593|
| No brew B |4.017|9.096|2.763|706556|4.889|79.500 /54.910|
| No brew I |3.324|7.598|2.289|703626|5.537|38.752 /7.190|

No simulator speedup or interactive-latency claim follows from these samples.
The treatment changes future economic work; it is not an equivalent-workload
performance optimization. Some real appointments still exceed100ms. Input books,
projection receipts and retained snapshots have memory/report costs. The native
three-day calculation remains GDScript; no Rust bridge or optimization is added.
Host: Godot4.6.3, Python3.12.14, Linux x86_64, three visible CPUs/two-CPU quota,
8GiB. Phase walls can overlap and must not be summed as total development time.
The final isolated [smoke](M28_SMOKE.json) command took3.276 seconds: C1/D1
run-only0.081/0.096 seconds and ten-job queue0.783 seconds, with no advisory
warning. These are guardrail samples, not a timing guarantee under contention.

## Reproduction and review boundary

```sh
export XDG_DATA_HOME=/tmp/m28-data XDG_CONFIG_HOME=/tmp/m28-config XDG_CACHE_HOME=/tmp/m28-cache
godot --headless --no-header --path . --script res://tests/run_input_tests.gd
python3 -B -m unittest discover -s tests -p test_input_reliability.py -v
python3 -B scripts/tools/run_input.py --checkpoint --output work/m28/checkpoint --traces work/m28/traces
python3 -B scripts/tools/run_input.py --reuse-checkpoint --output work/m28/experiments --traces work/m28/traces
python3 -B scripts/tools/run_input.py --staggered --output work/m28/staggered --traces work/m28/traces
python3 -B scripts/tools/summarize_input.py --input work/m28 --traces work/m28/traces --output work/m28/published
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_input_reliability --condition scarce --arm R_input_aware 30 42 --report-json
python3 -B scripts/tools/check_input_controls.py --output work/m28/m26-m27-controls
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m28/historical.csv
```

Historical M23–M25 drivers/pins, original C/D audits and isolated M22 smoke retain
their existing commands. See [artifact definitions](M28_SCHEMAS.md) for exact
units, denominators, known/unknown distinctions, candidate scope and cache
provenance. Raw full traces are transient; compact reports do not substitute for
the native event audit.

Proved: local provenance/timing, integer arithmetic, preserved guarantees and
conservation, deterministic case outcomes and baseline parity. Bounded/model-
dependent: the fill heuristic and conditional three-day contribution forecasts.
Still unknown: latent future supply, unplaced-order counterfactuals, universal
individual rationality, annual resilience and robust food-access improvement.
Keep the mechanism optional and stop after M28 for review. No M29.
