# M20 — Equivalent C++ and Rust numerical kernels

Issue [#25](https://github.com/anoy-maker/simulated-town-rpg/issues/25), base
`35975e851418ee438bd105b0a2a65bcee4b87a70`. Experimental, opt-in backends;
GDScript remains the default. No M21 or permanent migration.

**Result:** Both native kernels pass parity and preserve every historical economic
fingerprint. D30 run-only medians are **29.99 s GDScript → 4.09 s C++ / 3.99 s
Rust**; representative pure arithmetic is ~103× faster. Native full-decision
p99 remains ~98 ms, above the provisional 50-ms goal. **3093 Godot checks,
69 Python tests, 169 historical fingerprints and 21 independent audits pass.**
Keep GDScript default; no permanent migration is selected.

## Predeclared protocol (before comparative timings)

Port only forecast mixtures/convolution and financial continuations. GDScript
retains candidate generation, observable branches, posterior updating, ranking,
world authority, memory, events and audits. Each whole decision submits three
batches: all forecasts, frozen continuations, then posterior continuations.
Both native languages receive identical bytes and perform identical work. C/D
retain all original branches, prices, thirteen future periods, posterior/prior
weights, hazard .02, quadrature, 1e-9 affordability/tie thresholds, payout rules
and integer shifts. No fast math, FMA contraction, parallel kernels or sampling.

Schema v1 is documented in `native/m20/SCHEMA.md`. Float64 arithmetic follows
original loop order; compare numerical values at **absolute 1e-9**, normalized
PMFs at 1e-12. Exact candidate ranking, native events/state, beliefs, memory,
prices, meals, wages/distributions and native ledger hashes are mandatory.
Report hashes may differ only in the strictly checked numerical projection
fields. A choice/event mismatch fails acceptance; no economic retuning.

Corpus: recorded M19 D days 1,3,15,30, plus zero cash, stock below/at/above 24,
limited flour/supply, high stock and malformed/negative inputs. Synthetic batches
repeat identical whole-decision jobs 1/10/100 times; these are CPU stress tests,
not simulated additional people. Native pure timings exclude I/O and packing;
Godot timings separately include packing/unpacking, bridge/copy, kernel, decision,
appointment/tick, runner, reports/audits/serialization and command wall time/RSS.

Fresh same-host processes, one unmeasured one-day process per backend/stage,
rotating backend order; no concurrent verification during performance runs.
C/D 1/3 days, C30 and A30: >=3 repetitions/backend; D30: >=5. Isolated corpus
cases and 1/10/100 batches: >=3. Publish median/min/max and actual sample counts.
Full suites and historical pins run once at final acceptance, after focused
parity tests and preflight. Provisional future necessary main-thread p99 target:
**<50 ms**; this headless experiment cannot establish interactive responsiveness.

## Architecture and comparison limits

The shared bridge uses official godot-cpp, pinned at
`abb196939767b7bbee0b3a380faefdcbdb118a54`, against an API exported by the actual
Godot 4.6.3 binary. Current godot-cpp versions independently of the engine; the
build explicitly targets 4.6 and verifies its API header. Two independently
compiled shared libraries expose the same stable C ABI. GDScript packs permitted
own/public observations, branches and posterior weights; neither library sees
identities, world objects, private customer accounts, authoritative inventories,
receipts or raw history. Original GDScript updates/ranking and world validation
remain responsible for every actual price and economic event.

Three calls per C/D decision cover all forecast jobs, all frozen continuation
jobs, then all posterior continuation jobs. C preserves its single unadapted
posterior evaluation; D preserves that evaluation **and** all adaptive candidates,
including the duplicate evaluation when prices coincide. No cached answer or
shorter graph replaces work. Actual day-15 D uses 150 forecast-price jobs and
306 continuations, as in M19. Across 30 days each native backend executes
C: 4450 forecast-price jobs/5076 continuations; D: 4510/9198, exactly matching
the GDScript profile counts. The artificial high-branch fixture uses all twelve
candidate prices. Each forecast-price job recomputes thirteen hazard steps;
M19's original multi-price call shares those steps among prices. That native
schema adds redundant hazard arithmetic, not a shortcut. The isolated GDScript
schema benchmark calls the original `forecasts([price])`/`continuation()`; its
loop packaging differs from the original integrated multi-price policy. The
whole-run GDScript control always uses the unchanged original policy graph.

Pure ABI timings include validation, binary decoding, arithmetic and writing the
owned response buffer, excluding file I/O and request construction. They are
not a timer on arithmetic alone. Godot kernel timings use the same libraries
through the shared bridge. Its input bytes are borrowed; output allocation and
reference wrapping are included in bridge time. Packing/copying and decoding
back to Arrays are timed separately. Diagnostic JSON/digest work follows the
measurement. The same output values/digests must be validated; computation is
never replaced with a hash lookup. Libraries are single-threaded, with no
persistent belief/model caches.

The experimental loading descriptor and binaries are ignored build artifacts;
`.gdignore` prevents editor discovery. Explicit loading succeeds only after the
optional build. Omitted/`gdscript` selects the historical policy directly and
requires neither compiler nor compiled module. The only shared runner/world
changes are observation-only timing sidecars, excluded from snapshots/reports
and decisions. Appointment/tick collection is opt-in to the benchmark harness.
No goods, coins, prices, shifts, meals, movement or market rules are ported.

Primary integration references consulted:

- [Godot 4.6 GDExtension C++ example](https://docs.godotengine.org/en/4.6/tutorials/scripting/cpp/gdextension_cpp_example.html)
- [Official godot-cpp overview](https://docs.godotengine.org/en/stable/tutorials/scripting/cpp/about_godot_cpp.html)
- [godot-rust compatibility](https://godot-rust.github.io/book/toolchain/compatibility.html)
- [godot-rust book](https://godot-rust.github.io/book/)

Direct gdext integration could wrap this same pure Rust library and pin an
appropriate Godot API feature. Its community-maintained compatibility policy
requires runtime >= compiled API and distinguishes runtime/API versions. It is
feasible, but was **not built or benchmarked** here: introducing a second bridge
would confound this language comparison. The shared C++ bridge is an integration
dependency for both candidates. Rust's safe kernel does not make that bridge or
the caller's borrowed-pointer contract memory-safe by itself. C++ uses RAII and
checked lengths; Rust's one documented unsafe FFI block creates borrowed slices,
with safe indexed/checked numerical code thereafter. Rust release panics abort;
malformed numerical requests must return status, never panic.

## Measured results

Godot **4.6.3.stable.official.7d41c59c4**, GCC **14.2.0**, Rust
**1.91.1 (ed61e7d7e)**, Python **3.12.14**, SCons **4.9.1**;
Linux **6.18.57 x86-64**, glibc **2.41**, three visible logical CPUs,
two-CPU cgroup quota, 8 GiB limit. No CPU affinity/frequency or external host
load control. All 69 whole-run and 105 isolated samples completed, rotating
backend order in fresh processes. Kernel cases have n=3, including all twelve
candidate prices and 1/10/100 repeated day-15 jobs. One-day process warm-ups and
one whole-decision isolated warm-up are excluded. Pure ABI processes warm their
complete repeated batch; no persistent numerical cache crosses processes.

Run-only seconds, median [min–max]; ratios use fresh same-host GDScript, never
M19's older host measurements:

| Stage / days | n/backend | GDScript | C++ | Rust | C++ / Rust speedup |
|---|---:|---:|---:|---:|---:|
| C / 1 | 3 | 0.5776 [0.5362–0.5931] | 0.0757 [0.0737–0.0825] | 0.0769 [0.0762–0.0894] | 7.63× / 7.51× |
| C / 3 | 3 | 2.0053 [1.8123–2.2105] | 0.2585 [0.2495–0.3449] | 0.2503 [0.2479–0.2530] | 7.76× / 8.01× |
| C / 30 | 3 | 25.3517 [25.1826–26.0438] | 4.1085 [3.9484–4.1849] | 4.1197 [3.9807–4.5957] | 6.17× / 6.15× |
| D / 1 | 3 | 0.6822 [0.6488–0.7321] | 0.0803 [0.0799–0.1010] | 0.0822 [0.0750–0.1089] | 8.50× / 8.30× |
| D / 3 | 3 | 2.5300 [2.3464–2.5813] | 0.2869 [0.2530–0.3693] | 0.2651 [0.2409–0.2726] | 8.82× / 9.54× |
| D / 30 | 5 | 29.9873 [29.0984–32.1978] | 4.0940 [3.8619–4.2834] | 3.9888 [3.8582–4.3703] | 7.32× / 7.52× |
| A / 30 | 3 | 2.2257 [2.2186–2.2777] | 2.1446 [2.0468–2.2508] | 2.1242 [2.0033–2.3884] | 1.04× / 1.05× |

A executes **zero native numerical calls**. Its overlapping 2.00–2.39-second
ranges and small median differences are noise/context, not economic or algorithmic
improvements. Neither language wins reliably: D30 Rust is 2.6% faster than C++,
while C30 C++ is 0.3% faster, with overlapping ranges. No significance claim from
n=3/5. All raw samples, including slow observations, remain in
[M20_RUNS.csv](M20_RUNS.csv) and [M20_SUMMARY.csv](M20_SUMMARY.csv).

Thirty-day complete-command medians are C **33.659/12.184/12.204 s** and D
**37.971/11.765/11.711 s**, in GDScript/C++/Rust order: only **2.76×/2.76×**
and **3.23×/3.24×** command speedups. Reporting, including the original native
accounting/spatial audit, takes roughly **6.1–6.6 s**, outside `run()`. JSON,
history copying, startup/loading/shutdown/output remain additional costs.
Native library loading medians are **2.2–3.0 ms**; the original backend selector
costs about two microseconds. Startup, initialization and serialization are
retained separately in the CSV, not conflated with kernel time. Peak command
RSS is about **403000 KiB (394 MiB)** for native C/D versus
**405000 KiB (396 MiB)** for GDScript; verbose reporting/history copies dominate.
This is whole-command high-water memory, not kernel incremental allocation.

### Pure compute and boundary costs

Day-15 single-decision numerical work, n=3: original GDScript functions take
**864.757 ms** compute. Standalone C ABI medians are C++ **8.419 ms**, Rust
**8.412 ms**: **102.7×/102.8×**. Including Godot packing/copy/unpacking, totals
are **13.170/13.920 ms**, compared with GDScript's schema-harness **872.365 ms**.
The latter also packs the wire format for a fair interface exercise; it is not
the original full policy timer. These math batches exclude outcome enumeration,
posterior construction, candidate ranking, world execution and report work.

| Day-15 jobs/batch | GDScript Godot total s [range] | C++ Godot total s [range] | Rust Godot total s [range] |
|---:|---:|---:|---:|
| 1 | 0.87236 [0.83997–0.97189] | 0.01317 [0.01298–0.01405] | 0.01392 [0.01286–0.01414] |
| 10 | 8.64279 [8.28875–8.70869] | 0.15099 [0.14476–0.15207] | 0.14199 [0.14046–0.20233] |
| 100 | 85.55817 [84.95943–86.04620] | 1.48034 [1.45676–2.06988] | 1.51465 [1.49100–2.22508] |

For 100 jobs, standalone kernels take **0.875/0.884 s**; Godot totals are
**1.480/1.515 s**, roughly **67.6/66.0 jobs/s**, versus GDScript **1.17 jobs/s**.
Only n=3 batch samples exist; report ranges/worst, not spurious p95/p99 estimates.
The 100-job slow C++/Rust observations **2.070/2.225 s** are retained.
Every Godot output digest matches across languages and repetitions. This is
synthetic repeated math, not a 100-person world or forecast of interactive scale.

In actual D30 decisions, mean **per complete decision** (three batches) is:
C++/Rust packing **3.711/3.684 ms**, computation **8.907/8.816 ms**, total bridge
calls **9.214/9.130 ms**, unpacking **2.265/2.373 ms**, complete numerical adapter
**15.190/15.187 ms**. Bridge allocation/wrapping contributes about **0.27 ms**
above computation per decision. Call time includes compute; do not add them.
Most of the remaining ~63-ms median decision is GDScript outcomes, posterior and
batch orchestration. This residual is not separately allocator-profiled.
[M20_BOUNDARY.csv](M20_BOUNDARY.csv), [M20_KERNEL_RUNS.csv](M20_KERNEL_RUNS.csv)
and [M20_KERNEL_SUMMARY.csv](M20_KERNEL_SUMMARY.csv) retain both pure and Godot
measurements, digests, command wall and actual per-process RSS.

### Synchronous latency and Amdahl limits

D30 decision samples, 150/backend; nearest-rank quantiles, milliseconds:

| Backend | Median | p95 | p99 | Worst | Worst day/time |
|---|---:|---:|---:|---:|---|
| GDScript | 912.989 | 1262.897 | 1363.508 | 1374.763 | 4 / 12:25 |
| C++ | 62.853 | 80.996 | 98.932 | 134.466 | 16 / 12:25 |
| Rust | 62.962 | 81.457 | 97.349 | 111.012 | 6 / 12:25 |

The price choice is synchronous on the main-thread 12:25 appointment. The
provisional **p99 <50 ms** target is **not met** even without rendering/input.
Across 2850 appointment advances/backend, worst durations are GDScript
**1374.964 ms** (day4 12:25), C++ **135.072 ms** (day16 12:25), Rust
**139.717 ms** (day22 09:00). That Rust outlier includes an actual **127.427-ms**
five-minute tick at day22 **08:10**; its cause was not separately established.
C++'s worst individual tick is **13.162 ms** (day27 02:55), GDScript's
**5.173 ms** (day2 20:00). Do not hide that negative native tail observation.
Tick p99 is **0.940/0.825/0.852 ms**, but fast routine ticks do not make the
price decision responsive. Aggregate appointment p99 similarly mixes mostly
routine work with a few expensive decisions.

[M20_LATENCY.csv](M20_LATENCY.csv) includes every stage/horizon, sample count,
median, tails and worst timestamp. p95 requires >=20 samples, p99 >=100;
short runs/C30 decision p99 are left blank, rather than estimated confidently.
Tail observations are elapsed wall durations and can include host descheduling.
No frame/keyboard latency, renderer, player, 100-NPC simulation or scheduler was
implemented or measured. A future ~100 persistent people across 5–6 settlements
would need immutable permitted snapshots, bounded/event-triggered queued planning,
possible worker execution, deterministic ordering and authoritative revalidation.
Movement must not synchronously run an entire day or a 100-job batch. These are
future design considerations, not an implemented scheduling guarantee.

Fresh separate GDScript profiles give forecast-inclusive/continuation times of
**14.644/6.506 s in C**, **13.943/11.357 s in D**. These disjoint categories
cover **83.68%/86.11%** of profiled execution. Remaining profiled work is
**4.125/4.081 s**: outcomes, posterior/policy dispatch, movement, logs, memory and
other orchestration. With zero cost in the scoped port region, estimated ceilings
are **6.13×/7.20×**; finite native math and conversion remain. See
[M20_AMDAHL.csv](M20_AMDAHL.csv).

Those single-profile fractions are estimates, not a strict prediction for other
unprofiled processes: observer effects, load and reorganized caller/Variant work
matter. Actual unprofiled speedups **6.17×/6.15×** (C) and **7.32×/7.52×** (D)
slightly exceed these profile-based ceilings, by up to 4.4%. This is measurement
boundary/load mismatch, not a violation of Amdahl's law or evidence that all
remaining work disappeared. M19's older ~4.6× estimate removed only two exclusive
categories; this port also moves forecast-matrix/hazard/convolution work. Its
older-host times are not used for ratios. **103× kernel is not 103× settlement.**

## Build, correctness and maintenance

[Build timings](M20_BUILDS.csv), seconds; cold includes SDK generation/compilation,
not network acquisition. No-change C++ still recompiles its one source file;
Rust/SCons can reuse their build products. Source-touch rebuild changes mtimes
without changing contents, and every resulting library SHA256 is identical to
the benchmark artifact. Content-hash SCons can skip an unchanged touch; a separate
comment-only edit forces recompilation. After measuring it, sources and all
libraries were restored byte-for-byte to the verified benchmark state.

| Component | Cold | No-change helper | Source-touch | Comment edit |
|---|---:|---:|---:|---:|
| C++ library | 0.848 | 0.825 | 1.166 | 1.086 |
| Rust library | 0.824 | 0.026 | 0.880 | 0.852 |
| Shared official bridge/SDK | 32.759 | 0.727 | 0.969 | 2.304 |
| C++ ASan/UBSan library | 1.544 | 1.461 | 1.446 | 1.685 |

Rust/Cargo and SCons were initially absent. Rustup installed pinned 1.91.1 under
workspace scratch, pip installed SCons 4.9.1 outside the repository, and the SDK
was cloned at the recorded revision. No crates were downloaded for this project;
`Cargo.lock` has only the local package. Acquisition duration was not timed.
C++ uses release `-O3 -fno-fast-math -ffp-contract=off`, Rust opt-level3/one
codegen unit and generic x86-64 without FMA; no LTO/fast-math/CPU-specific advantage
was assigned to either language. Runtime dependencies/export support outside
Linux x86-64 were not tested.

Resolved setup failures are retained: nonexistent `godot-4.6-stable` SDK tag;
API export crashed before writable XDG directories were configured; the first
minimal SDK profile omitted the `OS` class required by SDK printing support.
Pinned current bindings with the actual 4.6 API, correct XDG paths and a minimal
RefCounted/OS profile resolved them. Python HTTP fetching of official docs returned
403; curl fetched the primary documentation. These are setup failures, not hidden
failed economic experiments. No permanent installation or migration is required
by historical commands.

The [16-packet corpus manifest](M20_CORPUS.csv) records raw-input/output digests,
including day1/3/15/30, 144 financial boundaries/limited supplies and the artificial
12-candidate graph. [M20_PARITY.csv](M20_PARITY.csv) records all 32 language/case
checks: every native output, normalization, determinism and selected independent
Python recomputations (all boundary jobs, first/middle/last actual jobs).
Maximum absolute native-vs-Godot-JSON error is **5.116e-13**; independent Python
error remains below **1e-9**. Historical JSON decimal export itself rounds f64s;
full integrated runs use the actual in-memory beliefs. Focused internal Godot
checks additionally compare complete candidate graphs exactly. Malformed lengths,
versions, excessive counts, prices, NaN/infinity, invalid probabilities and
negative cash reject without touching output/input buffers, including a bad
second job after a valid first. ASan/UBSan corpus runs pass; Python-host leak
checking is disabled, and sanitizer time is not used as a speed result.

All 69 measured full-run reports match the published canonical fingerprints
exactly, stronger than the permitted projected-value tolerance. Full native
ledgers, all account/inventory/custody state, beliefs/memory, branches/rankings,
prices and accounting match. C30 still has **360 resident meals, zero missed,
174 visitor loaves, 270 paid shifts, 1218 bakery distributions and six bread
left**. D30 still has **358 meals, two missed (Ada/Bram on day15), 168 visitor
loaves, 270 shifts, 1180 distributions and fourteen bread left**. D probes seven
on day15 and returns to six on day16. Combined currency stays **9192**; businesses
end at 120 each. C final households: Cora1044, eleven others6; visitors7722.
D: Cora1005, Ada/Bram12 each, nine employees5; visitors7758. Unchanged cash
circulation is **8556/8480** for C/D. No economic improvement is claimed from
running the same behavior faster.

## Recommendation and remaining limits

Keep **GDScript as the default** and review the narrow optional math boundary.
The measured ~100× arithmetic speedup supports considering that limited extension;
it does **not** establish a reason to migrate authoritative simulation/accounting,
observations or all NPC policies. Both languages are viable for this tested math;
there is no material speed winner. C++ has lower integration/toolchain friction
with the already-required official bridge. Rust provides safe owned arithmetic
and a reusable engine-independent library, but still depends on the C++ bridge
here and adds Cargo/toolchain maintenance. Neither choice establishes long-term
portability or game responsiveness. Maintaining three equivalent numerical paths
also has a real parity/test cost.

If later approved, first choose one maintained narrow backend and retain golden
parity checks; profile the remaining synchronous outcomes/orchestration and design
bounded off-main-thread/event-triggered decisions before scaling. Do not infer
social/quest intelligence, multi-settlement performance or frame responsiveness
from repeated bakery math. No language was adopted, world kernel rewritten,
scheduler built or M21 begun. Stop after M20 for review.

## Reproduction

Build with the pinned commands in [native/m20/README.md](../native/m20/README.md);
configure writable XDG directories first. Source data can be the first captured
GDScript D30 report, whose canonical hash must match M18/M19.

```sh
python3 -B scripts/tools/compare_native_math.py --phase preflight --output work/m20/preflight
# Isolated performance phase; do not run verification concurrently:
python3 -B scripts/tools/compare_native_math.py --phase benchmark --output work/m20/bench
python3 -B scripts/tools/benchmark_native_kernels.py --source work/m20/bench/D-30-gdscript.json --corpus work/m20/corpus --output work/m20/kernels
python3 -B scripts/tools/profile_simulation.py --label m20-reference --profiles-only --output work/m20/profiles
# Acceptance after all measurements:
python3 -B scripts/tools/verify_native_corpus.py work/m20/corpus
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libasan.so.8 ASAN_OPTIONS=detect_leaks=0 python3 -B scripts/tools/verify_native_corpus.py work/m20/corpus --sanitize
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m20/historical.csv
python3 -B scripts/tools/compare_native_math.py --phase audit --audit-jobs 2 --output work/m20/bench
python3 -B scripts/tools/summarize_native_math.py --input work/m20 --output docs
godot --headless --path . --editor --import --quit
git diff --check
```

Full native/Python tests need no network or compiler. Native-specific Python
arithmetic tests skip clearly if optional libraries are absent; default Godot
and explicit-unavailable loading checks still run. Acceptance here uses both
built libraries. Generated binaries, captured full traces and downloads stay
outside version control; only bounded tables/source/documentation are committed.

## Final acceptance

- Complete Godot suite: **3093 checks, zero failures**, including all 3078 old
  checks and 15 focused batch/loading/domain/replay checks; **273.365 s** wall.
- Complete Python suite: **69 tests passed, zero failures/skips**, all original
  66 retained plus three native/schema/optional-loading tests; **81.501 s**.
- **169/169 published fingerprints unchanged** (M0–M18 outputs, reused by M19),
  including M0 seed42/30-day byte hash
  `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`;
  direct CLI verification **425.806 s**. Old result documents/CSV artifacts are
  untouched. See [M20_REGRESSIONS.csv](M20_REGRESSIONS.csv).
- **21 independent audits pass**: C/D ×1/3/30 ×all three backends, plus A30
  ×all three. Original unmodified Python financial/spatial/observation/numerical
  auditors reconstruct every trace and re-evaluate decisions. Native quantities,
  9192-coin conservation after events, custody, memory/beliefs, ranks and hashes
  match. Two verification workers run **after** benchmarks; **392.202 s** wall.
  See [M20_AUDITS.csv](M20_AUDITS.csv). Their per-worker elapsed times overlap
  and must not be summed as one simulation run.
- Release corpus and ASan/UBSan corpus both pass; malformed requests do not
  partially publish output. Default D1 was separately run with the generated
  native descriptor removed: historical hash exact, explicit native request
  exits2 with a clear unavailable error. Thus no compiler/library is silently
  required by the default.
- Editor import succeeds; final staged whitespace checks succeed. No unresolved
  test, parity, accounting, build or audit failure remains. Platform exports,
  direct Rust Godot bindings, game-frame responsiveness, long-term autonomous
  stability and a 100-person world were **not verified**.

[Verification timings](M20_VERIFICATION.csv) are acceptance intervals, not
performance comparisons. [Host/build identity](M20_HOST.json) records actual
versions, API/binary hashes and limits. Changed files comprise two isolated pure
libraries/shared bridge/schema/build instructions; optional batch policy/adapter;
minimal runner/CLI/timing hooks; focused tests; benchmark/corpus/audit/export
tools; README/architecture/roadmap and these bounded result tables. No historical
production, financial authority, mathematical objective or policy was retuned.

**M20 is complete for review. GDScript remains default. Do not begin M21.**
