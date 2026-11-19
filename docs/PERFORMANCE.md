# Practical performance and verification cadence

Default historical simulations remain GDScript. Native/queue diagnostics are
opt-in and require the pinned M20 Rust/bridge build. Timings never enter canonical
reports, events, money, goods, decisions or replay hashes. No actual FPS/player
latency is established by a headless heartbeat.

## While editing

Run the focused tests for the touched mechanic. For queue/math work:

```sh
godot --headless --no-header --path . --script res://tests/run_dispatch_queue_tests.gd
python3 -B scripts/tools/performance_smoke.py --output work/perf-smoke.json
```

The smoke runs C/D for one day through the existing synchronous Rust simulation
and a ten-job representative one-worker queue. It writes **only a compact JSON
summary**, not verbose world traces or the 169-case sweep. It checks canonical
hashes, complete proposal parity, queue bounds and release order. It reports
run-only/command/report timing, decision samples/tails when enough samples exist,
worst real world appointment/tick, queue wait, callback service, event counts and
actual per-process peak RSS. It does not claim ten real NPCs or world progress
while a required decision is pending.

A checked-in initial reference is `docs/M22_SMOKE_REFERENCE.json`, medians from
three measured complete smoke runs on the recorded host. The command uses it by
default; `--reference other.json` selects another. Relative warnings trigger at:

- Run time increase >50%.
- Callback tail (p99 if available, else p95/worst) increase >50% **and** >5 ms.
- Peak RSS increase >25% **and** >32 MiB.

These are **warnings, not time-based exit failures**. Host/engine/kernel changes
are labeled noncomparable/informational; matching metadata does not control CPU
frequency or co-tenancy. Missing reference entries remain explicit. Never “fix” a
warning by reducing policy horizon, audit coverage or event logging. Record the
symptom, inspect changed work and repeat matched measurements if material.
Correctness/hash/parity failures still exit nonzero. p95 needs >=20 samples,
p99 >=100; a one-day decision cannot support a p99 estimate.

## At a meaningful checkpoint

Use representative three-day semantic comparisons, including the scheduled path
when relevant. `test_planning_jobs.py` compares C/D complete proposals and ledgers
with synchronous controls and exercises the actual barrier/stale/cancel path.
Avoid rerunning annual sweeps after each reversible edit.

```sh
python3 -B -m unittest discover -s tests -p test_planning_jobs.py
```

Immutable fixture/build caches can be reused when their source, engine/model
version, full input/proposal hashes and build flags are unchanged. M22's eight
lossless request/expected-proposal fixtures come from actual M21 observations,
with source full report/ledger pins. They accelerate **pure calculation tests**;
they never replace independent event/accounting/spatial/numerical acceptance.
Do not update a fixture/golden hash to conceal behavior drift.

## Once at final milestone acceptance

After implementation and isolated benchmarks: complete Godot/Python suites,
all published canonical pins, and the required independent financial/spatial/
observation/numerical audits. Significant later code changes justify rerunning
relevant checks and full acceptance again when semantics could change. Documentation
or formatting alone does not require another full expensive sweep.

```sh
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py'
python3 -B scripts/tools/check_historical.py --output work/historical.csv
# Audit fresh captured C/D 1/3/30 sync/scheduled traces with the original auditors:
python3 -B scripts/tools/measure_planning_jobs.py --phase audit --output work/controls
```

Use the applicable milestone capture driver to populate `work/controls`. M22's
`benchmark_planning_scale.py --controls` captures those cases and matched 30-day
context samples; future milestones need their own specified acceptance cases.
Do not skip independent audits merely because a report's aggregates look correct.
Measure actual command wall time by phase, store `phase,seconds,status` CSV, and
attach it with `performance_smoke.py --verification-times path.csv`. Distinguish
verification wall, benchmark run time, full command wall and unmeasured agent
reading/editing time; do not invent elapsed Codex time or sum overlapping phases.

## Small scheduling budget for later economy work

Start with one worker, bounded admission and a small fixed per-update producer/
release budget. Use two only if matched throughput/tail/memory data justify it;
four workers on a two-CPU quota are not four free CPUs. Preserve deterministic
eligibility and main-world revalidation. A 16-entry capacity rejects explicitly
on saturation; retain/retry the same request or defer intentionally, never drop.

Later businesses should provide owned authorized observation bytes, a stable
ordering key/ID, input/version fingerprint and optional logical deadline, and
receive an immutable proposal. World authority separately validates current
accounts, quotes, custody, time and ownership before execution. M22 still uses
Cora's M21 codec; add only the needed per-industry adapter when that industry is
approved. No generic causality graph, distributed engine, forced sleep, population
expansion or broader NPC agency is part of this workflow. M21's 12:25 barrier
remains a real world-progression constraint.


## M31 versioned verification entry point

Use the commands in [M31 results](M31_RESULTS.md#three-explicit-levels)
from the repository root, with a fresh output directory per invocation. Reuse a
separate `--cache-dir` if desired. Output `summary.json` records status, command
wall, printed test counts, probe/audit counts, hashes, deferred checks and the
full-acceptance flag; raw command logs and detailed dependency proof stay in work.
Never add those raw logs or verbose traces to an outcome report unnecessarily.

| Level | Intended use and scope |
| --- | --- |
| `development --subsystem …` | Native focused group (workflow: its Python tests), plus one-day pinned complete replay/independent audit for the integer economic profiles. Queue uses the existing canonical/proposal/ten-job smoke; its independent accounting/numerical audit is deferred. |
| `checkpoint --subsystem …` | Full focused Python module and one-/three-day probes. Wages/input controls use existing full event/receipt/report normalizers. Queue adds eight fresh C/D1/3 sync/scheduled independent audits and complete economic parity. |
| `full` | Complete suites,169 historical pins, all M23–M30 controls, original C/D1/3/30 audits, full milestone matrix and final performance smoke. Serial commands keep full Python and timing smoke isolated. `full --plan` lists all17 stages without executing them. |

Profiles are `wages`, `inputs`, `contracts`, `queue`, `workflow`. They are explicit
coverage choices, not an automatic changed-file/dependency oracle. New subsystems
need a reviewed registry entry using their existing focused/capture/audit tools.
The wage smoke tests experimental M30 code; it does not adopt that economy.

Optional immutable raw reuse is restricted to short integer-economic probes;
never cache focused-test or independent-audit pass conclusions. A receipt binds
all repository files/pins, engine binary/version, Python/runtime libraries,
actual native build/binaries/configuration, environment digest, exact inputs and
expected report/ledger hashes. Each hit still runs the original independent
whole-event audit, complete replay and full applicable economic comparison.
Two originally distinct native captures support each replay pair. Native run
times retained in payloads are historical measurements, not new executions.

Unchanged reviewed M30 native/capture sources define the current known closure.
Changed/new sources are uncertain and force fresh execution on every invocation
until a reviewed closure is explicitly registered; they are never auto-trusted
under a new cache key. Unresolved/symlink dependencies fail closed. Whole-tree
proofs are intentionally conservative; even documentation/environment changes
can invalidate reuse. This is not a general cache for arbitrary scripts or a
native build-cache manager. Rebuild changed kernels with the existing helper
before verification; no new Rust/build policy is introduced.

Nonzero process status, script errors, skipped required tests, or native JSON
failure counters prevent acceptance. Short and planned runs always state
`full_acceptance=false`. Full native/annual controls remain mandatory after
meaningful simulation changes; M31's user-authorized tooling-only deferral is
explicit, not a blanket exemption. [M31 results](M31_RESULTS.md) distinguish
same-coverage cache savings from narrower tier coverage and preserve the
superseded queue checkpoint finding. No CI migration is implemented here.
