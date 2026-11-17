# M24 — Fixed-wage labor selection and genuine local job mobility

Implemented for [issue #33](https://github.com/anoy-maker/simulated-town-rpg/issues/33),
from `codex/m23-brewery-economy` at
`790327546b1c5637940afa11a18e91e4df512dbf`, on `codex/m24-labor-market`.
This is an isolated headless experiment. Historical defaults remain unchanged.

## Frozen assumptions and implementation

The [labor feasibility note](M24_LABOR_FEASIBILITY.md) was committed as
`34bc4dc` before the main outcomes. It retains the fifteen residents, four firms,
9192 coins, zero initial commodities, real equipment, M23 recipes/targets,
wheat 2 / flour 5 / bread 6 / ale 4, wage 10, visitor budgets and shop/meal/settlement rules.
Owners remain management-only. Every completed shift uses native payroll and
production authority; no wage, resource or vacancy subsidy is introduced.

`settlement_labor_market` has two modes:

- `shift_selection`: compare available affiliated workers financially, retaining
  M23's strictly positive marginal contribution and actual working-capital budget.
- `matching`: the same decisions plus a physical 15:55–16:00 bakery meeting.
  Owners may advertise only genuinely unfilled installed positions supported by
  their conditional financial forecast. Workers observe notices, apply while
  retaining their old jobs, inspect offers, and voluntarily accept a contingent
  next-day transfer. Midnight revalidation precedes both old-job exit and entry.

Homogeneous effective labor is an M24-only eligibility override. Original skills
arrays are never rewritten, and old qualification gates remain effective. The
financial comparison ranks availability, then lower actual wage; equal candidates
use sorted IDs or a frozen left rotation by `day % equal_group_size`. All main
M24 wages are 10; the controlled different-cost test does not alter the economy.

Worker expected income uses only own rolling three-day due/paid receipts:
`10 × (paid+1)/(due+2)` for current employment, zero when unemployed, and five
coins for an unfamiliar actually observed notice (prior 1/2). Status quo wins
exact ties; there is no invented switching cost. Owners see their own books,
stock, staff and previously inspected input terms, never applicants' private
funds. Posting forecasts subtract yesterday's own unit sales from current stock
to estimate remaining carry, then apply the same profitable-shift budget to
installed slots. They spend only actual current cash. This forecast is an explicit,
fallible assumption, not a promise of tomorrow's paid work.

The first three-day Gale-inactive technical fixture rehired Gale. Before the
longitudinal matrix, `e8778cf` froze a disclosed extension enumerating all eleven
single-incumbent-ended fixtures. Every case is reported below; no outcome was
selected to retune the policy. No cash, commodity or equipment changed in those
initializations. The original Gale fixture remains separately identifiable.

## Main comparisons: 30 days, seed 42

Every M24 cell ran in **two fresh Godot processes**, comparing complete reports
and native events. Both modes produced identical economic accounts/day results
within each condition; their event ledgers differ because matching records the
meeting and decisions. All main runs have zero postings, applications, offers,
acceptances and employment transfers: existing staffing fills installed positions.
Missed shifts do not create fictitious vacancies.

| Condition | Policy | Paid shifts /330 | Resident meals /450 | Missed | Wheat / flour / bread / ale produced | Circulation |
|---|---|---:|---:|---:|---|---:|
| Reference | M23 sorted |330|450|0|630 /450 /630 /360|13950|
| Reference | M24 rotation, either mode |330|450|0|630 /450 /630 /360|13950|
| Tight19 or scarce16 | M23 sorted |225|368|82|420 /375 /525 /90|9711|
| Tight19 or scarce16 | M24 rotation, either mode |225|397|53|420 /375 /525 /90|9723|
| No brew request | M23 sorted |201|322|128|378 /370 /511 /0|8599|
| No brew request | M24 rotation, either mode |215|361|89|406 /395 /546 /0|9242|

The supplied reference retains exactly M23's economic results. Tight and scarce
still harvest14/day: the cap 19 third farm shift has zero marginal contribution;
cap 16's third shift loses money. Neither is scheduled. Rotation redistributes
existing wages without creating additional paid shifts or output in these cases.
Resident bread access increases by 29 while visitor bread sales fall from 155 to 127;
one fewer loaf remains unsold (1 instead of 2). This is a distribution/spending
change, not additional productive capacity or successful matching.

Without brewery requests, redistributed wages change household demand and later
inventory continuation. The first production difference is day 8: the bakery
starts with 6 bread under rotation versus 8 historically. Replenishing to target 21
then selects three rather than two profitable shifts. Over 30 days this path has
14 more paid shifts and 39 more resident meals, without new employment relations.
It still misses 89 meals and leaves bread unsold alongside missed meals on 29 days.
This is a controlled trajectory difference, not a general stability result.

| 30-day condition | Successful / rejected purchases | Bread sold to visitors | Ale consumed | Days with missed meals and unsold bread | Final firm cash: farm / mill / bakery / brewery |
|---|---:|---:|---:|---:|---|
| Reference, either M24 mode |1230 /0|180|360|0|120 /120 /120 /120|
| Tight19 or scarce16, either mode |779 /15|127|90|15|120 /120 /120 /120|
| No brew request, either mode |698 /0|180|0|29|120 /110 /120 /120|

The 15 rejected scarcity purchases remain real insufficient-flour failures. No
automatic replacement or refund is made. Successful movement totals count wages,
input/retail payments and existing realized-earnings distributions; circulation
is gross transfer volume, not newly created currency or accounting profit.

## Individuals, exclusion and business results

Under either scarcity cap, farm workers Dain/Edda/Gale each receive 20 shifts,
instead of historical 30/30/0. Mill and bakery employees each receive 25. This does
not ensure equal food access: Dain/Edda each miss 5 meals while Gale misses none,
because the time of income and spending matters. Brewery Oren receives 15 shifts;
Nell receives **zero** and misses 29 meals. The fixed rotation's period 2 aligns
with brewery opportunities on odd days, repeatedly selecting Oren. Sorted ties
historically selected Nell instead. This deterministic phase alignment is a real
limitation; rotation is a tie rule, not an employment guarantee or fairness policy.
The underlying grain clearing alternates mill 2 / brew 1 lots with 14 wheat available
and mill 3 / brew 0 with 15 available (the preceding day retained one wheat). The
unchanged whole-lot revenue objective therefore supplies brewery work on the
same odd-day phase as the two-worker rotation.

Scarcity household final coins (all household inventories empty):

| Resident | Shifts | Meals / missed | Final coins |
|---|---:|---:|---:|
| Ada |0|30 /0|10|
| Bram |0|30 /0|145|
| Cora |0|30 /0|289|
| Dain |20|25 /5|8|
| Edda |20|25 /5|4|
| Finn |25|30 /0|20|
| Gale |20|30 /0|6|
| Hale |25|30 /0|76|
| Iona |25|30 /0|72|
| Jory |25|30 /0|72|
| Kira |25|30 /0|72|
| Lyle |25|30 /0|72|
| Mara |0|20 /10|6|
| Nell |0|1 /29|0|
| Oren |15|26 /4|0|

Scarcity firm sales/input costs/payroll/distributions are respectively:
farm840/0/600/240, mill1875/750/750/375,
bakery3144/1875/750/519, brewery360/90/150/120.
All four finish at 120 cash; bakery retains one bread, others zero stock. The
existing realized-earnings distributions are unchanged, not an M24 intervention.

In the no-brew control, Mara/Nell/Oren each eat only their initial affordable meal
and miss29. Rotating other employees cannot create brewery demand or a funded
opening elsewhere. Final commodities are farm 11 wheat, mill 5 flour, bakery 5 bread;
firms retain 480−10 coins and all other stocks are zero. Household and visitor cash
remain within the conserved9192. Complete per-resident income/food/balances and
per-business accounts for all conditions are linked below.

## Deliberate vacancies and actual transfers

All following cases run three days, twice, seed 42. A single initial contract is
inactive; no funds/goods/assets change. Day2 entry occurs at the previous day's
24:00, strictly after day 1's contract closure. Native due/missed records persist.

| Initially ended worker | Accepted entry | Incumbent cross-industry transfer? | Paid shifts | Meals / missed |
|---|---|---|---:|---:|
| Gale (original fixture) | Gale → farm |No, unemployed rehire|29|44 /1|
| Dain | Finn → farm |Yes, bakery → farm|26|41 /4|
| Edda | Finn → farm |Yes, bakery → farm|26|41 /4|
| Finn |None|No|28|39 /6|
| Gale (systematic fixture) | Gale → farm |No, unemployed rehire|29|44 /1|
| Hale | Hale → mill |No, unemployed rehire|31|43 /2|
| Iona |None|No|28|39 /6|
| Jory | Jory → mill |No, unemployed rehire|31|43 /2|
| Kira |None|No|28|39 /6|
| Lyle | Lyle → mill |No, unemployed rehire|31|43 /2|
| Nell | Nell → brewery |No, unemployed rehire|32|45 /0|
| Oren | Oren → brewery |No, unemployed rehire|32|45 /0|

In the Dain fixture, four workers apply to Ada's one real vacancy. Finn's own
unpaid bakery shift makes expected current income 10/3 versus the observed
offer's 5. The frozen equal-contribution applicant rotation selects Finn. He
accepts while remaining a bakery employee on day 1. Midnight ends that job before
creating the farm contract, updates tomorrow's route, and pays an actual wage 10
for real farm harvest on day 2. His `skills` stays `["baker"]`; homogeneous legal
labor authorization makes the work valid. The vacancy moves to the bakery; its
current-cash forecast does not justify a new posting. Turnover does not repair
the whole chain or improve this fixture's total meals to the full reference.

Focused authority fixtures also cover competing applicants, another applicant's
acceptance, conflicting employers, blind resignation, duplicate acceptance,
unobserved/forged notices, absent/busy participants, same-day premature work,
cancelled and offered-but-unaccepted entry, changed boundary funding, historical
breach retention and zero-margin vacancies. Cancellation/failure preserves the
old affiliation and creates no wage, commodity, second job or negative account.

## Verification

The experimental matrix verifies 24 new cases × two fresh
processes, 12 vacancy cases × two processes, and 12 fresh M23 report/ledger pins.
Every captured economic ledger is independently replayed, not inferred from
summary equality. The Python adapter reconstructs local knowledge, worker receipt
history, vacancies, applications, reserved offers, boundaries and route changes
alongside the original financial/custody/physical/quote/consumer audit. Rehashed
forgeries exercise these checks rather than only a digest mismatch.

The complete Godot suite passed **3,202 checks, zero failures**, preserving all 3,168
previous checks. All **169 historical payload pins** and **12 M23 report/ledger
pins** passed unchanged. The original independent financial/spatial/observation/
numerical auditors passed all **12 fresh C/D 1/3/30 synchronous/scheduled traces**.
The final vacancy verification repeated all 24 captures against the published pins
with the completed auditor. Separate cancellation, unaccepted-offer expiry and
no-vacancy rejection witnesses are replayed by the Python suite.

The complete Python suite passed **91 tests, zero failures and zero skips**,
including native integration and the independent lifecycle witnesses. During
development, replay exposed a remaining fixed-roster audit assumption, and two
corruption tests initially selected an empty history or an unchanged schedule.
Those audit/test fixtures were corrected before final acceptance; economic
parameters and decision policies were not retuned. No correctness failure remains. The public `run_simulation.gd --scenario
settlement_labor_market` entry point also reproduces the published one-day
reference JSON bytes.

| Final verification phase | Actual command wall seconds | Exit status |
|---|---:|---:|
| Complete Godot suite |387.974|0|
| Complete Python suite |152.187|0|
| 169 historical payload pins |704.774|0|
| Fresh C/D synchronous/scheduled capture |113.249|0|
| Original independent C/D audits |345.023|0|
| M22 performance smoke |3.572|0|

Godot verification overlapped the capture/historical lane, and independent audit
work later overlapped the historical sweep. Python verification ran afterward to
avoid its deliberate native-descriptor fallback test racing Godot captures.
These phase walls must not be added as total elapsed time. The isolated new
matrix's measured capture-command plus audit components sum to 174.847 seconds;
the 12 fresh M23 control components sum to 40.417 seconds. Those component sums
exclude driver/report-export overhead and are not complete session wall times.

The final [M22 performance smoke](M24_SMOKE.json) passed canonical hashes, proposal
and ordered-release parity, queue bounds and regression checks, with **no timing
or memory warnings**. The ten-job callback p95 was 1.971 ms (53 samples; no p99);
C/D one-day world appointment maxima were 50.229/55.104 ms. These legacy numerical
planning costs remain, even though M24 uses no native planning queue.

## Isolated performance measurements

Godot 4.6.3 / Python 3.12.14, x86_64, three visible CPUs with two-CPU cgroup quota,
8 GiB memory. No other verification lane ran during the following matrix timings.
Each table entry is the median of two fresh 30-day processes; worst latency is
the maximum sample across those repeats. These small samples do not establish a
speedup or interactive frame-rate guarantee. Timing metadata is outside hashes.

| Mode / condition | Run seconds | Command seconds | Report seconds | Godot peak MiB | Events | Audit seconds | Worst appointment / tick ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| Selection / reference |2.510|5.605|1.471|513.3|40080|3.436|34.524 /6.700|
| Matching / reference |2.488|5.809|1.634|565.5|42540|3.721|29.839 /5.718|
| Selection / tight |2.426|5.431|1.451|492.1|38241|3.509|21.808 /14.588|
| Matching / tight |2.652|5.840|1.466|538.7|40701|3.525|19.294 /5.588|
| Selection / scarce |2.292|5.464|1.298|492.2|38241|3.242|21.041 /5.702|
| Matching / scarce |2.680|6.073|1.639|538.7|40701|3.556|23.609 /6.252|
| Selection / no brew |2.238|5.319|1.302|487.4|37819|3.295|20.214 /5.257|
| Matching / no brew |2.608|5.945|1.486|533.9|40279|3.580|25.224 /4.965|

Full native traces are temporary capture/audit inputs, not committed. Per-process
peak RSS comes from `wait4`, not Python's aggregate replay memory. Event logging,
report building, serialization and process startup explain why command time
exceeds run-only time. Matching's unchanged-economy reference still adds 2,460
events and about 52 MiB peak RSS. No scheduler/native migration is introduced.

## Evidence and reproduction

- [24 run results and report/ledger pins](M24_RUNS.csv)
- [30-day resident accounts](M24_RESIDENTS.csv), [firm accounts](M24_BUSINESSES.csv),
  [daily totals/unsold bread](M24_DAYS.csv)
- [All vacancy outcomes](M24_VACANCIES.csv), [native employment transitions](M24_EMPLOYMENT_EVENTS.csv),
  [fixture resident accounts](M24_FIXTURE_RESIDENTS.csv)
- [Fresh M23 pin checks and timing](M24_LEGACY_CONTROLS.csv),
  [verification phase walls](M24_VERIFICATION.csv), [M22 smoke](M24_SMOKE.json)
- [Per-process performance](M24_PERFORMANCE.csv), [latency samples/quantiles](M24_LATENCY.csv)

```sh
python3 -B scripts/tools/run_labor_market.py --output work/m24/experiments --verify-pins docs/M24_RUNS.csv
python3 -B scripts/tools/run_labor_market.py --fixtures --output work/m24/fixtures --verify-pins docs/M24_VACANCIES.csv
python3 -B scripts/tools/run_labor_market.py --legacy-controls --output work/m24/legacy-brewery
python3 -B scripts/tools/summarize_labor_market.py --input work/m24 --output docs
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m24/historical.csv
python3 -B scripts/tools/performance_smoke.py --output work/m24/smoke.json
```

## Limits and review boundary

Technical correctness and a valid cross-industry transfer are demonstrated;
universal employment, food access and autonomous economic stability are not.
The main fixtures have full affiliations despite unpaid shifts, so there is no
opening to solve with matching. The fixed income prior, three-day window, carry
forecast, daily meeting, contract duration, bounded 30-day horizon and periodic
tie rule are experiment assumptions, not validated models of human labor markets.
No promised shift becomes a coin until completed native work is paid. Finite
visitor purchasing power and owner distributions remain the inherited context.
No policy was tuned after outcomes. No dynamic wages, training, rescue resources,
new industry or generalized employment framework was added. Stop after M24 for
review; M25 has not begun.
