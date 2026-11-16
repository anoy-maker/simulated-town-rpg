# M19 — Profile the simulation; optimize one measured hot path

Implements [issue #23](https://github.com/anoy-maker/simulated-town-rpg/issues/23), starting from M18 **`1d33b57ac30c2a77dac3869d6bd3c7ee4819e3b2`**. Profiling-only checkpoint/reference: **`7fb0fc7`**; numerical optimization: **`6e6be8e`**. Historical branches, economic parameters and artifacts are untouched. No language migration, new scenario, rendering, gameplay or M20.

## Result

Retain one exact, call-local reuse table in `bakery_finance.gd::continuation()`. Thirty-day run-only medians change from **32.864863 to 30.023780 seconds for C (−8.6%)**, and **45.310453 to 36.915384 for D (−18.5%)**. An alternating three-pair replay of the actual D day-15 continuation workload changes median **0.690523→0.456207 seconds (−33.9%)**, with all **306 values identical** in every process. This is an observed improvement on this host, not a guaranteed universal speedup. Exactness refers to implementing M18's existing bounded approximation, not discovering true demand or an optimal policy.

Final verification: **3078 Godot checks, zero failures; 66 Python tests passed; 169 published-output comparisons unchanged**. All twelve M18 stage/horizon cases pass fresh independent financial, physical, observation and numerical audits. The C six-coin hold, D's day-15 seven-coin probe/day-16 return, missed meals, distributions, event ordering and every published report hash remain unchanged. No verification is disabled to obtain a timing gain.

## Protocol and boundaries

Phase 1 added instrumentation without numerical/economic logic changes. The baseline profile was completed before choosing or implementing the optimization. All benchmark processes use **Godot 4.6.3.stable.official.7d41c59c4**, Python **3.12.14**, Linux **6.18.57 x86-64/glibc 2.41**. The container exposes three logical CPUs with a **two-CPU cgroup quota** (`200000/100000`) and an **8 GiB** memory limit. Same host, seed **42**, horizon and initial conditions before/after; no verification jobs run concurrently with benchmark processes. External host scheduling/frequency/bandwidth effects were not controlled.

For A/C/D × 1/3/30, use **three fresh independent processes** per case, reporting medians and min–max rather than one sample. One unmeasured fresh-process one-day A/C/D warm-up primes OS/code pages; it does not preserve model caches in measured processes. Case order rotates across repetitions. B30 and existing M16-A30/M17-A30 receive one coarse context run each. Separate profiled repetitions provide attribution and per-decision work, rather than using instrumented elapsed time as the speed benchmark.

The harness measures runner initialization and `runner.run()` separately using Godot's monotonic microsecond clock. It then captures report/native-audit time, canonical JSON time, history-copy time and full diagnostic-envelope JSON time. Captures/hash calculation occur **after the timed run**. Python measures complete subprocess wall time separately. Godot ticks at harness entry provide engine-startup context; OS startup, shutdown, output and unscoped harness overhead are not falsely classified as pure initialization. Canonical scenarios/exported hashes never contain timings, process IDs or profiling counters.

Linux `wait4(pid)` supplies that individual command's actual peak RSS, not the accumulated maximum from previous children. `/proc/self/status` supplies VmHWM immediately after `run()` when available; this is high-water memory **through startup/init/run**, not a purported isolated incremental allocation measurement. Command peak additionally includes reporting, audit copies and serialization.

Instrumentation uses conditional RAII-style scopes with refcount teardown covering returns. Exclusive phase time subtracts nested child intervals. Exclusive totals can be composed; inclusive totals **must not be summed**, particularly where spatial/logging/native-audit scopes nest under the same category. The residual is runner orchestration, unscoped methods and instrumentation bookkeeping. This is a single-threaded coarse script profiler, not an allocator/hardware sampler.

## Before/after run-only benchmarks

Seconds; brackets show min–max. Negative delta means faster. Learning A/B are controls that do not call the optimized function. Context rows have n=1 and do not establish reliable speed changes. M16 A is a nonspatial reference, M17 A is the old spatial fixed control; neither is a matched learning treatment for M18 C/D.

| Scenario | Stage | Days | n before/after | Before median [range] | After median [range] | Change |
|---|---|---:|---:|---:|---:|---:|
| learning | A | 1 | 3/3 | 0.041707 [0.034750–0.045764] | 0.031821 [0.030216–0.064764] | -23.7% |
| learning | A | 3 | 3/3 | 0.113992 [0.112382–0.118266] | 0.113224 [0.111160–0.113351] | -0.7% |
| learning | A | 30 | 3/3 | 2.815194 [2.502542–2.827902] | 3.032172 [2.488403–5.316604] | +7.7% |
| learning | B | 30 | 1/1 | 2.763460 [2.763460–2.763460] | 2.606191 [2.606191–2.606191] | -5.7% |
| learning | C | 1 | 3/3 | 0.676912 [0.589034–0.690214] | 0.678221 [0.606877–0.801332] | +0.2% |
| learning | C | 3 | 3/3 | 2.572151 [2.443966–2.609291] | 2.239119 [2.133716–2.411711] | -12.9% |
| learning | C | 30 | 3/3 | 32.864863 [30.747273–34.092048] | 30.023780 [29.282919–32.274445] | -8.6% |
| learning | D | 1 | 3/3 | 0.850426 [0.840865–1.060151] | 0.856315 [0.825427–0.955291] | +0.7% |
| learning | D | 3 | 3/3 | 3.073227 [2.783571–3.211846] | 3.925806 [2.790398–4.131100] | +27.7% |
| learning | D | 30 | 3/3 | 45.310453 [42.330166–51.426698] | 36.915384 [36.893609–41.050835] | -18.5% |
| m16 | A | 30 | 1/1 | 0.171359 [0.171359–0.171359] | 0.279245 [0.279245–0.279245] | +63.0% |
| m17 | A | 30 | 1/1 | 2.545537 [2.545537–2.545537] | 2.693631 [2.693631–2.693631] | +5.8% |

There are negative/neutral results. One-day C/D differences are **+0.2%/+0.7%**. The unpaired D3 median is **+27.7%** and A30 is **+7.7%**, with A30 candidate samples ranging **2.488–5.317 seconds** despite unchanged A execution and zero continuation calls. Two slow D3 samples also slow unchanged reporting. We retain those observations rather than discard them.

Because a material D3 regression would require reverting, after verification became idle we ran a predeclared follow-up: three alternating reference/candidate pairs for D3 plus unchanged A3, fresh processes and common one-day process warm-ups. D3 reference **2.958738 [2.892251–2.965889]** becomes **2.747596 [2.733865–2.849479]**, **−7.1%**. A3 medians are **0.111865/0.113644**, +1.6%, with overlapping ranges. This does not prove all timing variation is environmental, but the original unpaired D3 slowdown is not reproducible as an optimization-caused regression. Together with the pure paired replay and unchanged hashes, it supports retaining the change. Both studies are published; there is no universal or statistically precise speedup claim from n=3.

[M19_BENCHMARKS.csv](M19_BENCHMARKS.csv) retains all raw timings, including the first after-pass under `after-initial`. That preliminary pass updated a profiling dictionary millions of times. We aggregated those diagnostic counts once per continuation and repeated the complete final after protocol; the numerical reuse algorithm was unchanged. Original measurements were not overwritten or silently substituted. [M19_SUMMARY.csv](M19_SUMMARY.csv) contains final medians/ranges, command wall time and RSS; [M19_PAIRED.csv](M19_PAIRED.csv) retains the D3/control follow-up. Variation in unchanged controls, single context samples and an outlying D30 candidate sample all limit confidence.

The historical M18 one-off 7.29/57.10/39.74-second A/C/D values are not the M19 baseline. Different host/load conditions already produce different measurements **before** the optimization. M19 comparisons use the same-stage measurements above. No M16 C/D price-activation stage is presented as an economic control for M18 C/D.

## Profile: identify first, then inspect the hot function

Separate 30-day profiled runs (seconds, exclusive categories):

| Phase | C before / after | D before / after |
|---|---:|---:|
| Cash-flow continuation | 10.747 / 7.937 | 19.229 / 14.186 |
| Forecast mixtures | 14.690 / 15.067 | 14.704 / 14.773 |
| Forecast matrix orchestration/convolution | 2.550 / 2.504 | 2.531 / 2.577 |
| Observable outcome enumeration/quadrature | 1.610 / 1.560 | 1.514 / 1.550 |
| Bayesian/hazard math, actual + hypothetical | 0.510 / 0.523 | 0.494 / 0.523 |
| Candidate orchestration itself | 0.168 / 0.154 | 0.220 / 0.211 |
| Clock/movement/deposit | 1.279 / 1.247 | 1.243 / 1.266 |
| Event logging, excluding observed-memory child | 0.738 / 0.732 | 0.795 / 0.715 |
| Owner observed memory/accounting | 0.190 / 0.184 | 0.208 / 0.184 |
| Snapshot/history copying | 0.580 / 0.573 | 0.658 / 0.627 |
| Kernel transactions + spatial quote-purchase wrapper | 0.054 / 0.056 | 0.060 / 0.057 |

D is the slowest stage, and its **largest isolated function** before optimization is continuation: **19.229 s / 42.272 s = 45.5%** of its profiled run. C's largest isolated function is forecast mixture (14.690 s), not continuation (10.747 s). Combined C/D continuation self-time is 29.976 s; the mixture function totals 29.394 s, while the broader matrix+mixture group is also substantial. We targeted D's dominant continuation function, leaving the different C bottleneck and the remaining forecast code untouched. Profiling does not establish that Godot's engine is the underlying problem.

Price-search **inclusive** time is 30.272→27.743 s for C and 38.689→33.816 s for D; those totals include the forecast/continuation/Bayes/outcome rows and must not be added to them. The outcome-enumeration row is not the whole cost of EVSI: hypothetical updates, future forecasts and maximizing continuation values are timed in their respective children. Actual observed Bayesian work is only **3.243/3.277 ms** before and **3.651/3.980 ms** after for C/D, obtained by subtracting decision-nested Bayesian work from global Bayesian time. Most Bayesian math is hypothetical future planning, not fitting raw owner history.

Transaction scopes cover original kernel commands and the spatial quoted-purchase wrapper. Clock/movement/deposit scopes include advance-time/move/deposit work, with nested financial/logging/observation work subtracted. Route setup, other validation and unscoped runner work contribute to the residual. [M19_PHASES.csv](M19_PHASES.csv) includes call counts, inclusive and exclusive times/shares for every profiled case.

The after-profile run totals are 31.127/37.259 s for C/D, distinct from unprofiled medians 30.024/36.915. Observer overhead and host variation cannot be separated precisely with one diagnostic repetition. The lightweight scopes are low cost relative to expensive planning but have a larger relative effect in A (3.786 s profiled versus 3.032 s unprofiled median). Consequently **all speed comparisons use unprofiled runs**. Fine per-arithmetic-operation timing is intentionally avoided.

### Per-decision growth and work

Before optimization, profiled per-decision seconds:

| Stage | Day 1 | Day 3 | Day 15 | Day 30 | Continuations at days 1 / 3 / 15 / 30 |
|---|---:|---:|---:|---:|---|
| C | 0.671 | 1.065 | 1.044 | 0.901 | 108 / 171 / 171 / 171 |
| D | 0.752 | 1.300 | 1.199 | 1.221 | 189 / 306 / 306 / 306 |

Raw previous-day memory grows from 0 to 2/14/29 records. On the inspected days, candidates grow from three to four, branches from 27 to 36, and prospective price vectors from 90 to 150. With four candidates, C computes 9×sum(future-price-count+1)=171 continuations; D computes 9×sum(2×future-price-count+1)=306. Higher current quotes temporarily admit five candidates on C day 4 and D days 4/16; those entries are included in [M19_DECISIONS.csv](M19_DECISIONS.csv). This explains work growth without a scan proportional to memory length. No raw movement ledger is reprocessed for forecasting.

| 30 days | Events including initialization | Candidates / branches | Continuation calls | Forecast price vectors | Beta-table / traffic-component misses |
|---|---:|---:|---:|---:|---:|
| A | 27331 | 0 / 0 | 0 | 0 | 26 / 0 |
| C | 27335 | 119 / 1071 | 5076 | 4450 | 1352 / 861 |
| D | 27337 | 120 / 1080 | 9198 | 4510 | 1352 / 840 |

These common work counts are **identical before and after**. B's original short-memory policy evaluates three prices/day (90 proposals), not the Bayesian continuation graph. Cold beta misses are 845 on day 1, 169 on day 3 and zero at days 15/30. Traffic-component misses also decline. A larger remembered history does not cause the observed forecast cost; prospective prices, branches and fixed-size numerical projections do. Dictionary/Variant lookup/allocation remains visible by code inspection, but we did not measure allocator-specific bytes or assign it a fabricated timing percentage.

## The only numerical optimization and its proof

Inspection of `continuation()` after profiling found repeated `mean_sales(forecast[t], stock)` calls across alternative first-day sales branches. A row's supported quantities are 0..PMF.size()-1. When **stock >= that upper bound**, every min(stock, quantity) is exactly quantity. Therefore the original support-bound calculation produces the **same floating-point products and additions, in the same order**, as the nonbinding-stock call.

A lazy Array local to that continuation holds one scalar per tail day; thirteen slots exist and at most twelve fill (next-day sales are still integrated separately). On the first nonbinding request for a day, execute the original `mean_sales` function at its support bound. Later nonbinding requests reuse that scalar. **Stock-limited requests use the original function**. No prefix-sum reassociation, sampling, shortened horizon, branch pruning, reduced candidate set, altered reserve or changed price belief is introduced.

The index is sufficient only because the row is immutable within this call. Its price, beliefs, hazard, traffic and public context are already embedded in the exact forecast argument. Cash/inventory still pass through the original ordering/whole-shift/closing transitions; they influence whether stock binds. The table cannot survive a call, day, price change, new forecast, world or seed. There are no rounded persistent keys or cross-agent cached facts.

Tests compare **36 price/cash/input/stock/supply cases exactly** against M18's original arithmetic, including stock immediately below/above the support boundary, insolvency, unused inputs and capital. They check input immutability, a changed forecast on a later call, at most twelve entries, and zero-valued means distinguished from missing entries. The normative money/production/quote authority is unchanged.

| After 30-day diagnostic | Reused nonbinding means | First nonbinding calculations | Stock-limited calculations | Original requests (derived) | Remaining calculations | Reduction |
|---|---:|---:|---:|---:|---:|---:|
| C | 1282439 | 57321 | 172384 | 1512144 | 229705 | 84.8% |
| D | 2353097 | 103648 | 283767 | 2740512 | 387415 | 85.9% |

Original requests are inferred from exact matched-path counters (hits+misses+limited); M18 executes `mean_sales` once per request. After counts are measured directly. Financial projections themselves remain 5076/9198; no financial path was skipped. [M19_WORK.csv](M19_WORK.csv) contains all counters. Millions of `operate`/`close` result Arrays/Dictionaries remain: from measured D tail requests, the unchanged helper bodies imply 2×2740512 tail result dictionaries and state copies. That is a code-based count, **not** an allocator profile or a claim that allocation alone dominates.

The paired microbenchmark builds all 306 actual D day-15 continuation problems outside its clock, uses the same one-task warm-up in each fresh process and alternates build order across three pairs. Reference times **0.690523 [0.648893–0.781161]** become **0.456207 [0.424852–0.472727]**. Input digest and all output values match exactly for every pair. It does not time world stepping, model preparation or reports. It calls the existing GDScript calculation, not a native binding or redesigned policy interface. [M19_CONTINUATION.csv](M19_CONTINUATION.csv) preserves the six samples.

## Startup, reporting, command wall time, audit and memory

M19 measures actual execution boundaries, not task-completion duration. For D30, complete unprofiled subprocess medians are **55.980→47.218 seconds**, compared with **45.310→36.915** inside `run()`. A30 complete-command medians are **12.060→16.741**, versus **2.815→3.032** inside `run()`: reporting/output and host variation matter. Canonical and envelope JSON, history copying, engine-entry ticks and initialization are individually recorded in the raw CSV. Native report auditing alone takes roughly **5–6 seconds** in the diagnostic thirty-day C/D runs. Its nested time is part of reporting, never part of timed `run()` and never summed twice.

| 30 days | High-water through init/run, before / after KiB | Whole-command peak, before / after KiB |
|---|---:|---:|
| A | 137548 / 137540 | 356936 / 356868 |
| C | 148112 / 148112 | 391300 / 391232 |
| D | 147960 / 147980 | 391100 / 391096 |

Values are medians of unprofiled samples. Memory differences are negligible allocator/measurement noise; there is **no demonstrated RSS improvement**. Reporting/auditing/serialization raise command peak well beyond the run-through high-water mark. The new small table is transient and does not grow with memory length. Histories, inactive visitor presences, snapshots and report copies remain intentionally unchanged.

Acceptance ran separately from benchmarks. The native suite took **517.109 seconds command wall** during concurrent verification. The latest complete Python pass took **92.530 seconds command wall** (an earlier concurrent complete pass took **196.848 seconds**). Fresh independent M18 audits sum **303.444 seconds** in Python; the 157 legacy direct-CLI checks take **419.752 seconds** in their serial phase. These are verification intervals, can overlap and must not be added as one simulation time. For example, a verification-loaded C30 run took 73.512 seconds under concurrent jobs; that is not substituted into the isolated 30.024-second benchmark median. Codex reading/editing/review time and the many independent commands are also not one game execution.

## Verification and artifacts

- **Godot 3078 checks / 0 failures:** all 3066 M18-era checks plus twelve profiling/reuse checks. Separate M18 pure math: 37 passed. Targeted M19: 12 passed.
- **Python 66 tests passed:** all previous 63 plus three profiling non-interference/timing/counter/RSS checks.
- **169 pins:** 157 direct historical M0–M17 CLI byte hashes, plus all twelve native M18 canonical report fingerprints with matching ledger hashes and fresh independent audits. The M18 harness computes the exact standalone CLI report wrapper after timing; its underlying trace is independently reconstructed. Main CLI formatting/semantics are unchanged. `check_historical.py` can replay all 169 directly without local old captures.
- A remains the exact M17 control. C still produces 360 resident meals, zero missed, 174 visitor sales and **1218** bakery distributions; D still produces **358 meals, two missed, 168 visitor sales, 1180 distributions**, with its exact day-15 seven/day-16 six sequence. Currency remains **9192** and every account/commodity/transaction audit passes.
- Canonical before/after benchmark outputs match M18 pins in every repetition, including profiled runs. Paired micro inputs/values are identical. M19 Python checks additionally compare complete profiled/unprofiled D1 report **and event arrays**, and require empty instrumentation when disabled. Existing split-run/replay tests all pass.
- Editor import and `git diff --check` pass. No test failures, parity failures or blocked checks remain. A non-failing ResourceWarning in the new test CSV loader was fixed with explicit handle closure; the three affected profiling tests passed cleanly again. Complete-suite/audit timing was acceptance-only, following the requested efficient cadence; no before/after test-suite speedup is claimed. The initial detailed-counter observer effect and original negative timing observations are retained and explained, rather than hidden.

[M19_REGRESSIONS.csv](M19_REGRESSIONS.csv) records expected/actual hashes and capture type; [M19_AUDITS.csv](M19_AUDITS.csv) records independent timings and fingerprints. Its `run_usec` is from **verification-load captures**, not performance comparisons. No giant profiling trace, full annual ledger or historical artifact is committed.

## Recommendation: continue GDScript before a compiled spike

The measured bottleneck is an expensive explicit lookahead calculation, not evidence that Godot cannot move twelve residents or execute their transactions. A small exact GDScript reuse improves its paired workload by 34% without a port. Residual cost is now dominated by forecast mixtures/matrix work and the remaining financial transitions; observed-memory fitting and authoritative transactions are small. **Continue narrowly measured GDScript work before introducing a compiled runtime.** There is no approved latency budget here against which to justify migration, and no compiled version was benchmarked.

If a later approved experiment establishes a need, test **one pure continuation batch**, not the town/world engine. A possible data-oriented boundary takes a packed N×4 projected-state table, integer price/supply arrays, an indexed M×13×25 PMF table and forecast indices; it returns N financial values. Batch prospective branches/prices in one or a few passes per decision, amortize conversion over each whole pass, and never call native code per customer or loaf. The authoritative ledger and price execution remain in Godot. Preserve double arithmetic order, the 1e-9 affordability boundary and terminal-value rules; avoid fast-math/reassociation that could change whole shifts. This is a proposed interface only; no FFI or compiled scaffolding is built.

| Option | Relevant strengths | Costs/risks for this project |
|---|---|---|
| C#/.NET | Easiest managed-code iteration; typed arrays/structs and JIT can suit numerical batches. | Requires a .NET-capable Godot distribution and platform/export checks; GC behavior and Variant/array marshalling remain design costs. Avoid per-step managed/Godot calls and repeated temporary allocations. |
| C++ GDExtension | Official native extension route; fits the current standard Godot build and tightly controlled packed numeric loops. | Per-platform build/export/tooling, ABI/binding/version discipline, memory safety/debugging and data-conversion costs. Native is not automatically faster if calls are fine grained. |
| Rust GDExtension bindings | Compiled numeric code with memory safety inside the Rust boundary. | Community-maintained Godot bindings/version support, FFI ownership/panic/error rules, conversion and build/export overhead. Memory safety does not remove boundary cost or prove numerical parity. |

If a compiled spike eventually becomes justified, C++ GDExtension is the most direct fit for the **current non-.NET distribution**; C# is attractive if adopting that runtime is acceptable, and Rust requires accepting the binding/toolchain obligations. This is an architectural comparison, not a measured language ranking or authorization to start it.

## Reproduction

```sh
# Same engine; writable XDG setup from README applies.
git worktree add --detach /tmp/sim-m19-before 7fb0fc7
python3 -B scripts/tools/profile_simulation.py --root /tmp/sim-m19-before --label before --output work/m19/before
python3 -B scripts/tools/profile_simulation.py --label after --output work/m19/after
# Raw captures/hashes are taken outside the run clock. Optional --audit runs audits afterward.
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial_learning --stage D 30 42 --report-json > work/m19/D-30-summary.json
python3 -B scripts/tools/compare_profile.py --reference /tmp/sim-m19-before --fixture work/m19/D-30-summary.json --output work/m19
python3 -B scripts/tools/summarize_profile.py --input work/m19 --output work/m19/tables
# Acceptance, separately from benchmarks:
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
godot --headless --no-header --path . --script res://tests/run_learning_tests.gd -- --math
godot --headless --no-header --path . --script res://tests/run_profile_tests.gd
python3 -B scripts/tools/check_historical.py --output work/m19/historical.csv
python3 -B scripts/tools/run_learning.py --output work/m19/independent-replay
```

Acceptance in this workspace uses one fresh audited M18 capture per required case plus the 157 legacy CLI checks, avoiding gratuitous reruns; the existing M18 driver above is the public audit/process/split-replay reproduction. Counts, commands, pass results and wall intervals are retained. Timing reproduction will vary; economic/decision output must not.

Changed implementation: opt-in `execution_profile.gd` and conditional scopes/counters in existing targets; **one** numerical change in `bakery_finance.gd`; bounded profiling/pairing/export/pin-check tools; native/Python tests; README/architecture/roadmap and these M19 artifacts. No production rules, M18 beliefs/objective, recipes, prices, initial resources, NPC policies, employment, capital retention or historical result files are modified.

**Stop after M19 for review. No language migration or M20 implemented.**
