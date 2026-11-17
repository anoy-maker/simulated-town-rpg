# M22 — Bounded planning load and performance guardrails

Issue [#29](https://github.com/anoy-maker/simulated-town-rpg/issues/29), starting at
M21 `94fda4b449b45bde96b4ea178b562ea6a62ff5d6`. This is synthetic independent
planning work, not 100 citizens, businesses or settlements. No economic policy,
math, historical default, or M21 world/commit barrier changes.

**Go for review before returning to small economy/agency increments.** No measured
foundational blocker requires another architecture milestone. Prefer one worker
for a single required plan; two for independent bursts when justified. Four are
not justified as a default on this two-CPU quota. This is not a permanent migration,
100-person simulation, world-progress solution or rendered responsiveness proof.

## Predeclared protocol

Reuse M21's complete Rust-backed policy on lossless authorized snapshots from
C/D days 1/3/15/30, each source run verified against historical full report/ledger
hashes. Principal fixed workload: D day15. Counts 1/10/100, worker pools 1/2/4.
Also 100 mixed jobs cycling D30,D15,C15,D3,C30,C1,D1,C3, to vary actual cost.
No sleep-as-work or shortened graph. Delays occur only in a labeled ordering test.

Capacity is 16 total unacknowledged tasks (waiting/running/completed/released),
64-KiB requests, 512-KiB responses and 1024 admissions per dispatcher lifetime.
Backpressure rejects explicitly without consuming an ID/key; producer retries.
Main owns admission and ordered release; each worker owns immutable bytes, bridge
and private caches. Results become eligible by fixed key/ID order, never finish
time, and do not become world actions. M21 separately validates/executes authority.

Fresh independent processes, one excluded representative warmup per pool; >=3
repetitions for matrix/mixed/context. Five repetitions for the chosen critical
100-job/four-worker condition. Rotate cases/pools; no verification concurrently.
Use a ~60-Hz headless process callback, at most four admissions/releases per update.
Record numerical compute, full job, queue/dispatch/poll/release, callback work,
heartbeat gaps, throughput, input/output counts/bytes and per-child RSS. p95 for
n>=20, p99 for n>=100; publish actual n/ranges/worst. <50-ms necessary-main p99
is a diagnostic goal, not a flaky pass threshold or a player/FPS claim.

Same-host M21 C30/D30 sync/scheduled controls n=3; shorter semantic captures for
final audits. A 250-ms first-job delay in a ten-job/two-worker mixed fixture
forces finish-order differences; three repetitions. Lightweight smoke: C/D1
plus ten queued jobs, no historical sweep. Relative warnings fixed before timing:
run/queue throughput regression >50%, callback tail >50% and >5 ms absolute
increase, RSS >25% and >32 MiB increase. Warning only; missing/noncomparable
hosts explicitly noted. Correctness failures still exit nonzero.

Final cadence: targeted/schema/lifecycle and 1-day while editing, 3-day semantic
checkpoint, full Godot/Python/169 pins and independent audits once after benchmark.

## Implementation and authority

`planning_dispatcher.gd` is an opt-in wrapper around the **unchanged M21 worker**,
Rust kernel and complete policy. Main owns all queue records. Off-thread producers
receive `main_thread_only` before accessing containers. Stable keys must arrive in
monotone `(batch, priority, ordinal, ID)` order, including ID tie-breaking; an
earlier key cannot enter after the release watermark. These synthetic keys are
not actual simulation timestamps. IDs remain deduplicated after acknowledgement.
After 1024 admissions a caller must finish/shut down and create a new epoch.

Workers compute concurrently with owned mailboxes/bridges/caches. Polling may
free a worker and start another request while earlier work blocks **eligibility**.
Release is ordered and one-shot, including canceled/stale/failed tombstones;
acknowledgement frees capacity/payloads and requires the matching epoch. Full
queues reject before consuming an ID/key; the harness retries that same task.
Cancellation suppresses the result even if noninterruptible math finishes later.
Worker termination/invalid results fail closed, cancel pending work and reject
further admission. Explicit shutdown joins and prevents late release/acknowledgement.
Diagnostic containers are copies, not mutable queue state exposed to callers.

The harness has **no world**, emits zero world events, and never applies its price
proposals to imaginary NPCs. Each transport serial is distinct from the actual
source owner (Cora). The eight actual C/D observations/beliefs and expected whole
proposals are lossless Variant fixtures, 183,518 bytes total including provenance.
Source C30/D30 full report hashes are checked before export; those reports include
their original complete ledger hashes. Load checks validate every request and
**entire proposal**, not merely selected price. D15 still performs 150 forecast
jobs and 306 continuations in its original three batches on every computation.

The original M21 world separately checks observation/version/time/custody/quote
validity and executes authoritative commands once. Its 12:25 barrier remains.
No economic, mathematical, native, M21 worker/runner/world or default CLI source
was changed. The default full suite adds only the new native-independent pure
queue checks; no optional extension becomes mandatory for historical runs.

## Host and measurement boundaries

Godot **4.6.3 stable official**, Linux 6.18.57 x86_64/glibc 2.41, three visible CPUs,
**two-CPU cgroup quota** (`200000 100000`), 8 GiB memory limit. Reuse the unchanged
M20 release Rust library and official godot-cpp bridge, built as documented in
[native build instructions](../native/m20/README.md) (Rust 1.91.1, GCC 14.2.0,
SCons 4.9.1, pinned godot-cpp revision; Python 3.12.14 measurement drivers).
Exact engine/build hashes
and limits: [M22_HOST.json](M22_HOST.json). No benchmark ran concurrently with
verification; measurements precede the final acceptance lanes.

41 fresh load processes, **2,129 measured jobs**, plus excluded per-worker warmups;
20 matched world-control processes plus four excluded one-day warmups. Three
additional complete quick smoke runs establish the initial reference. Load command
wall totals 151.815 s, world-control command wall totals 251.663 s (warmups excluded).
These are measured command times, not elapsed agent/task duration.

Run-only load time starts after fixture loading and one D15 warmup on **each**
worker, ends when all results are acknowledged, and excludes shutdown/reporting.
Full command includes startup, fixture checks, warmup, JSON output and exit.
At most four admissions and releases occur per update. Callback measurements
include byte handling, full proposal hash checks, bounded periodic RSS sampling
and any OS preemption; they are not pure dispatcher CPU costs. Native numerical
time is instrumented inside the unchanged Rust ABI, nested within full policy.
Whole-job execution additionally includes result serialization. Worker-thread
startup is excluded from run-only but present in command wall.

All samples/ranges: [load runs](M22_RUNS.csv), [summary](M22_SUMMARY.csv),
[latencies](M22_LATENCY.csv), [world runs](M22_WORLD_RUNS.csv),
[world summary](M22_WORLD_SUMMARY.csv), [world tails](M22_WORLD_LATENCY.csv).
The driver also retains per-job raw timings in ignored `work/.../details.json`.
CSV timings are seconds for run/command and **milliseconds** for latency tables;
memory is KiB. Quantiles use nearest rank; p95 requires n>=20, p99 n>=100.
Latency distributions pool samples across processes; batch ranges preserve noise.

## Throughput and scaling

Homogeneous complete D15 work; entries are median run seconds [min–max], jobs/s.

| Jobs | One worker (n=3) | Two workers (n=3) | Four workers (n=3; 100 jobs n=5) |
|---:|---:|---:|---:|
| 1 | .100 [.099–.100], 10.04 | .099 [.083–.100], 10.12 | .096 [.081–.098], 10.37 |
| 10 | .816 [.750–.899], 12.25 | .550 [.500–.600], 18.19 | .566 [.566–.651], 17.68 |
| 100 | 7.883 [7.816–8.523], 12.69 | 5.137 [4.700–6.500], 19.47 | 5.887 [5.847–6.081], 16.99 |

For 100 jobs, two workers achieve **1.535× speedup / 76.7% efficiency**; four
achieve **1.339× / 33.5%** relative to one. A single job cannot benefit from more
workers; small differences are noise/frame alignment. Full-command medians for
100 jobs are 8.277 / 5.595 / 6.465 s, not the run-only numbers above.

The heterogeneous 100-job case (n=3 each) takes **7.100 [7.083–7.450]**,
**5.342 [4.316–5.449]**, **5.329 [5.248–5.492]** s for 1/2/4 workers;
14.08 / 18.72 / 18.77 jobs/s. Four has essentially no median benefit over two
here (1.332× versus 1.329× relative to one), with worse tails and higher RSS.
This host oversubscribes its quota at four; do not extrapolate linear scaling or
claims about 100 people in 5–6 towns from these independent price calculations.

## Responsiveness and scheduling delays

100-job homogeneous callback work and heartbeat gaps, pooled across repeats:

| Workers | Callback n | p50 / p95 / p99 / worst (ms) | Heartbeat p99 / worst (ms) |
|---:|---:|---:|---:|
| 1 | 1,448 | .294 / 2.185 / 3.435 / 105.539 | 18.627 / 105.626 |
| 2 | 980 | .320 / 4.159 / 5.519 / 11.892 | 17.369 / 20.629 |
| 4 | 1,623 | .376 / 9.396 / 36.815 / 46.505 | 53.259 / 68.599 |

All are below the provisional **50-ms main callback p99** goal; this is not a
hard guarantee. Mixed 1/2/4-worker callback p99 is 3.126 / 7.715 / 34.317 ms,
worst 6.660 / **134.790** / 50.807 ms; worst mixed heartbeat gap is **179.827 ms**
at two workers. Retain these outliers. Four-worker contention is visible in both
callback and worker latency; wall-clock samples include host scheduling effects.
No actual rendered FPS, keyboard responsiveness or concurrent gameplay was tested.

Homogeneous 100-job scheduling, median / p99 ms (n=300/300/500 jobs):

| Cost | 1 worker | 2 workers | 4 workers |
|---|---:|---:|---:|
| Enqueue → worker start | 1167.583 / 1339.952 | 668.102 / 918.202 | 653.796 / 794.971 |
| Worker execution | 68.831 / 112.301 | 90.591 / 143.829 | 206.829 / 381.849 |
| Complete policy computation | 68.225 / 111.863 | 89.890 / 143.137 | 205.857 / 379.575 |
| Native numerical compute (nested) | 9.029 / 17.606 | 10.036 / 15.491 | 12.645 / 57.665 |
| Finish → poll | 9.892 / 16.604 | 9.543 / 17.161 | 8.355 / 45.967 |
| Finish → ordered eligibility | 10.905 / 17.678 | 11.560 / 25.877 | 17.895 / 215.408 |
| Enqueue → eligibility | 1250.876 / 1423.335 | 768.156 / 1051.711 | 904.133 / 1104.364 |

Queue wait starts at **successful admission**; producer wait during full rejection
is additional, captured in total batch time. Dispatch and start are separate
columns in the latency CSV. Median request serialization is .017/.018/.019 ms,
admission .271/.259/.250 ms; release byte-copy/ledger work .006 ms each. Native
batch packing medians 3.371/4.443/6.394 ms and unpacking 1.397/1.834/2.359 ms
are part of policy time, not extra time to add to it. Across 100 results, main
full-parity validation medians total 80.469/106.757/250.944 ms; fixture-copy totals
3.562/2.547/1.740 ms. Idle shutdown medians .527/.992/1.498 ms. Shutdown can wait
for unfinished noninterruptible work; these idle numbers do not bound cancellation.

The three labeled ordering runs all finish `work-001` before `work-000`, with
later differences too, yet release exactly `work-000` through `work-009` with
identical whole-proposal and release digests. The injected 250-ms first-job delay
produces worst finish-to-eligibility waits **258.024 / 262.662 / 287.426 ms**.
[M22_ORDER.csv](M22_ORDER.csv) records actual orders. Those delays are ordering
fixtures only, excluded from throughput comparisons; no sleep substitutes for math.
Mixed four-worker p99 finish-to-eligibility is 219.975 ms even without injected
delays: strict ordering deliberately preserves head-of-line waiting.

## Bounded load and memory

Median peak RSS for homogeneous 100 jobs is **72,592 / 76,604 / 85,000 KiB** for
1/2/4 workers. Resident RSS before setup is about 63,520 KiB, after warmup
70,536 / 74,380 / 81,748, after 100 jobs 71,120 / 75,388 / 83,784, after cleanup
71,128 / 75,392 / 83,780. Allocator retention means teardown need not return RSS
to baseline; payload counts are explicitly zeroed. Mixed peaks are 72,604 /
76,788 / 85,556 KiB. Per-child `wait4` high-water is not cumulative child RSS.

All 100-job runs reach exactly **16 outstanding**, with maximum waiting counts
15/14/12. Input bytes never exceed **25,408**; largest completed/released response
payload is **115,580 bytes**, at most five results in this fixture. These are
observed maxima below explicit theoretical bounds (16×64 KiB requests, 16×512 KiB
responses). Worker-owned request/result copies, native arrays, cached forecast
tables and metadata are additional and represented in measured process RSS.
This does not prove a universal memory bound for future arbitrary policies.

All homogeneous 100-job runs record full rejections (totals 1,208 / 800 / 1,357
across 3/3/5 processes). Every requested job is retried and acknowledged once;
no silent drops. Counts of rejections depend on host service timing and are
diagnostic, never economic events or replay inputs. Dedup/history is bounded
separately at 1024; the rejection detail journal retains at most 64 examples.

## Unchanged world controls and remaining causality barrier

Same-host unchanged M21 C30/D30, three fresh processes per mode:

| Stage / mode | Run median [range], s | Main callback p99 / worst, ms | Required decision p50 / p95 / worst, ms |
|---|---:|---:|---:|
| C sync | 10.777 [10.476–10.861] | 82.221 / 121.036 | 71.735 / 102.400 / 121.019 |
| C scheduled | 11.746 [11.695–11.787] | 16.389 / 36.939 | 67.631 / 99.726 / 101.821 |
| D sync | 10.658 [10.603–10.937] | 83.050 / 152.142 | 72.546 / 94.352 / 152.094 |
| D scheduled | 12.189 [11.940–12.537] | 18.680 / 134.968 | 83.461 / 116.941 / 200.040 |

Required-decision distributions contain **90** actual decisions each, so p99 is
not estimated. Main callback counts are 1710/2113/1710/2194; heartbeat n is three
less. Scheduled D's main p99 improves but run time increases **14.4%**, and the
actual required decision still stalls authoritative progression. Scheduled C
run time increases **9.0%**. Different per-mode policy times are measurements,
not modified work. Full-command medians are 19.384/20.045/19.468/20.898 s,
including large original reporting/serialization costs. This is context for the
new queue, not proof that a multiworker world scheduler was integrated.

Both modes preserve 9192 coins; C/D retain **360/358 resident meals**, **174/168
visitor sales**, 270 paid shifts, and original movements/custody/memory/beliefs.
D still selects seven coins on day15 and six on day16. Complete report and
ledger pins, not those aggregates alone, establish parity.

## Verification and lightweight guardrails

Final acceptance passed with **zero failures**:

| Phase | Actual result | Command wall seconds |
|---|---|---:|
| Full Godot suite | 3,122 checks passed (all previous 3,103 retained) | 373.272 |
| Full Python discovery | 77 tests passed, no skips (previous 73 plus four) | 124.908 |
| Historical canonical sweep | 169/169 byte-identical pins | 518.142 |
| Original independent auditors | 12/12 C/D 1/3/30-day sync/scheduled captures | 225.594 |
| Headless editor import | exit 0, no script errors | 6.968 |

[Phase costs](M22_VERIFICATION.csv), [all pins](M22_REGRESSIONS.csv) and
[independent audits](M22_AUDITS.csv) retain exact results. The full Godot then
Python lane ran alongside the historical then independent-audit lane, after
isolated benchmarking; these overlapping command costs must not be added as
elapsed task wall time. No existing auditor, pin or expected economic result was
weakened. M0's original 30-day seed42 JSON remains
`6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`.

Focused native queue/lifecycle checks passed **33 checks, zero failures**;
the four new Python tests passed. They cover full/backpressure/retry, malformed
input, duplicate ID/release/ack, deterministic ties, off-main producer rejection,
queued/running cancellation, expiry/fingerprint changes, epoch restart/late ack,
actual worker thread termination without fallback, private cache ownership,
complete proposal parity, and advisory warning/sample-size behavior. Existing M21
authority tests retain stale-input/world-time/one-shot commit coverage.

The smoke median complete command wall is **2.754 s** [2.745–2.793], compared with
the full acceptance phases below. C1/D1 each have 913 actual events; run medians
.079/.087 s; queue10 .800 s. C/D one-day decision n=1 and queue decision n=10
cannot justify p95/p99. Queue callback samples 49/46/48 support p95, not p99.
[Raw smoke runs](M22_SMOKE_RUNS.json) and [reference](M22_SMOKE_REFERENCE.json)
retain exact observations. Reference values are medians of per-run metrics, not
invented pooled quantiles. A warning test intentionally worsens time/RSS/tail:
three advisory warnings, no correctness failure; host mismatch is informational.
The final isolated [reference check](M22_SMOKE_CHECK.json) completed in 2.873 s,
reported a comparable host and **no warnings**, with actual verification phase
costs attached. This extra check does not change the three-run reference.

[PERFORMANCE.md](PERFORMANCE.md) and the brief AGENTS link establish the cadence,
command, predeclared relative thresholds, safe immutable caching and independent
acceptance requirement. `--verification-times phase.csv` attaches actual phase
costs; an empty default list means unmeasured, never zero. Correctness failures
still exit nonzero. No historical sweep or large traces are produced by the smoke.

## Reproduction

Build the optional artifacts as in the M20 README. Use writable XDG directories
when needed by the host. From repository root:

```sh
godot --headless --no-header --path . --script res://tests/run_dispatch_queue_tests.gd
python3 -B -m unittest discover -s tests -p test_dispatch_queue.py
python3 -B scripts/tools/benchmark_planning_scale.py --output work/m22/load
python3 -B scripts/tools/benchmark_planning_scale.py --controls --output work/m22/controls
python3 -B scripts/tools/performance_smoke.py --output work/m22/smoke.json
# After isolated timing, perform final acceptance:
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/m22/historical.csv
python3 -B scripts/tools/measure_planning_jobs.py --phase audit --output work/m22/controls
python3 -B scripts/tools/summarize_planning_scale.py --input work/m22 --output docs
```

`--preflight` selects one job/four workers, heterogeneous ten/four and forced
ordering ten/two, for a small setup check. Fixture regeneration is explicit in
[fixture provenance](../tests/fixtures/m22/README.md); never update expected bytes
to hide drift. Full raw traces remain ignored, not year-long committed dumps.

## Limits and smallest next interface (not implemented)

Do not schedule a 100-job burst for every world tick. Prefer requests triggered
by meaningful observed economic changes and legal preparation before a deadline.
This codec remains Cora-specific; later approved businesses need only their own
permitted immutable input adapter, stable ID/key/fingerprint, proposal output,
and existing authoritative main-world validation/execution. Start with one worker,
capacity 16 and at most four admissions/releases per update; consider two after
matched measurements. Treat the 50-ms p99 goal as diagnostic, retain outliers,
and investigate the smoke's relative warnings before expanding work.

Deadlines invalidate work; they do not invent fallback choices. Genuine dependent
actions still wait. Time-sliced/partial forecasts could change policy semantics
and would need a separately reviewed experiment; none is implemented. No generic
causality graph, multi-town schedule, player, new business, economic policy or
permanent Rust authority migration is introduced. The finite eight-case workload,
1024-admission lifetime, same-host noise, retained allocator/cache memory and
remaining global barrier limit extrapolation.
The worker-failure fixture terminates an actual worker thread without a result;
it is not native panic/OOM recovery. The unchanged M20 native build still aborts
on panic/OOM; no process fault-tolerance system is added.

Files: new dispatcher; fixture export/loader and eight request/proposal pairs plus
manifest; bounded load runner, capture/matrix/summarizer and smoke tools; focused
GDScript/Python tests and one pure-suite call; README/architecture/roadmap/AGENTS
links, this report, workflow, compact measured CSV/JSON evidence. Existing native
and economic implementation sources are unchanged. **Stop after M22 for review;
do not begin M23.**
