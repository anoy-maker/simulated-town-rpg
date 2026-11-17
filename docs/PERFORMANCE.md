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
