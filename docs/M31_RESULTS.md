# M31 — Fast development and verification workflow

**Accepted and merged:** M31 passed the complete **17-stage** GitHub Actions
verification on November 18, 2026, including **3,482 Godot checks**, **166 Python
tests**, historical regressions, independent economic audits, the M30 matrix and
the final performance smoke. See [the successful full run](https://github.com/anoy-maker/simulated-town-rpg/actions/runs/44449713489)
and [merged PR #47](https://github.com/anoy-maker/simulated-town-rpg/pull/47).
The initial draft intentionally deferred acceptance; references to deferral
elsewhere below describe that earlier review-stage status, not today's result.
A GitHub-runner cgroup metadata portability fix was added before final
acceptance without changing the simulation's economics or native kernels.
Tooling branches from completed M30 `f142f7b` on `codex/m31-fast-verification`.
Every M30 source checksum is unchanged. No simulation, policy, state, schedule,
accounting/audit assertion, Rust kernel, gameplay or golden result was changed.
M30 worker bidding remains experimental and is not an economic baseline.

## Workflow audit

The [audit and measurement plan](M31_WORKFLOW_AUDIT.md) maps focused runners,
short captures, independent auditors, historical pins and full acceptance. M30
recorded Godot 983.6 s, Python 241.7 s, historical pins 1593.1 s, M28/M29 controls
1732.3 s and C/D audits 607.2 s. These command walls overlapped; their sum is
neither elapsed Codex work nor billable CPU time. Simulation run-only time is a
separate field in `M30_PERFORMANCE.csv`. Reading/coding/orchestration was not timed.

The primary avoidable costs are broad sweeps between edits, duplicated native
checks when a focused Python module already runs them, engine recaptures whose
inputs are genuinely unchanged, and unversioned scratch orchestration. M30's
historical recaptures were justified because shared payroll authority changed.
Equal aggregate meals/currency never replace full economic/audit comparisons.

## Three explicit levels

Run from the repository root; each invocation uses a **fresh output directory**.
Use `--subsystem wages|inputs|contracts|queue|workflow`; there is no automatic
changed-file guessing or implied coverage of a new, unregistered subsystem.

```sh
python3 -B scripts/tools/verify_workflow.py development --subsystem wages --output work/dev-01 --cache-dir work/verified-traces
python3 -B scripts/tools/verify_workflow.py checkpoint --subsystem wages --output work/check-01 --cache-dir work/verified-traces
python3 -B scripts/tools/verify_workflow.py full --plan --output work/full-plan-01
# Explicit expensive certification after meaningful changes:
python3 -B scripts/tools/verify_workflow.py full --output work/full-01
```

| Level | Checks performed | Explicitly deferred |
| --- | --- | --- |
| Development | Selected native group (workflow profile: its Python unit module); scarce seed42 original-funds1-day replay, published full report/ledger pins and original independent auditing for wages/inputs/contracts/workflow. F and old baseline comparisons use the existing complete event/receipt/report normalizers. | Complete Python fixture module, other conditions/horizons and full acceptance. Queue uses original C/D1 canonical/proposal and ten-job smoke; independent queue audits are deferred to checkpoint. |
| Checkpoint | Complete selected Python module, including original adversarial/authority fixtures; scarce1/3-day complete replays/pins/audits and normalized economic comparisons. Wage fixtures also exercise real post-day3 variable pay/partial claims. Queue adds fresh C/D1/3 sync/scheduled worlds, eight original independent audits, complete report/event parity, existing stale/barrier tests and smoke. |30/365-day cases, remaining conditions/endowments, full suites and historical certification. |
| Full | Existing complete suites,169 byte pins,88 M23–M25 pinned pairs, M26/M27 controls/proofs/certificates,76 fresh M28/M29 controls, original C/D1/3/30 capture/audit, full28-case M30 repeats/pins/parities and final smoke.17 serial stages keep Python/timing checks isolated. | Nothing in the preserved M30 certification scope. This path is planned/unit-checked, **not executed end-to-end in M31**. |

The wrapper imports existing capture/audit/normalization functions; it does not
reimplement economic verification. Nonzero processes, native JSON failures,
script errors and skipped required tests cannot yield acceptance. Failure writes
`summary.json` and exits1. `full_acceptance` remains false for short/plan/failed
runs. Existing assertions and golden hashes are not edited.

## Immutable raw reuse

Optional `--cache-dir` reuses **only native short-probe payloads**, never focused
test passes or independent audit conclusions. Each use reruns the original whole
independent audit, fixed report/ledger pins, complete deterministic comparison
and applicable full economic normalization. Two originally distinct process
captures are retained for each replay pair. Cache hits do not mean fresh native
execution; focused tests still execute their own original native fixtures.

A receipt binds exact inputs/repeat/expected outputs to all repository files
(including dirty/untracked sources and pins), Godot binary/version, Python,
loaded runtime-library hashes, native binaries/build files, platform, effective
environment digest and extension configuration. Generated caches/work outputs
are excluded. End-of-command fingerprints detect concurrent changes. Symlink or
unresolved runtime dependencies fail closed; unsupported inputs/expectations fail.

The native/capture dependency closure is attested at M30. Changed/new economic
or capture code is **uncertain**, so it forces fresh captures on every call until
a reviewed closure is registered; it does not merely create an automatically
trusted new cache. No Rust queue raw reuse is implemented. Whole-tree/environment
fingerprints are deliberately conservative: documentation or environment changes
can cause misses. Cache portability/hit rate is not promised; cross-run CI trace reuse is not
established by this whole-environment key. Use fresh CI captures until a narrower
portable proof has been reviewed. No legacy raw
cache is silently imported as evidence of a new execution.

## Actual timings and correctness

Serial same-host measurements: Godot 4.6.3, Python 3.12.14, Linux x86_64, two-CPU
quota/8 GiB. Three paired wages samples per mode; warm and cold commands perform
**identical checks**. Medians [min–max], whole command seconds:

| Command | Fresh probe captures | Verified reuse | Change |
| --- | --- | --- | --- |
| development | 6.838 [6.774–7.211] | 2.407 [2.398–2.549] | 64.8% shorter |
| checkpoint | 38.265 [37.639–38.347] | 25.565 [25.110–25.992] | 33.2% shorter |

Development's five probes become zero fresh probes but still five independent
audits; checkpoint's ten become zero but still ten audits. Focused tests always
run. Probe capture walls include startup/serialization/parse; probe native
run-only fields in `M31_BENCHMARKS.csv` are recovered from measured raw receipts,
not inferred from total command time. Other profile rows have command walls only.

Current-host legacy wage Python group:22.048 s; legacy short driver:55.092 s
(16 cases/32 primary captures/eight full F comparisons). New development defers
that Python fixture coverage; new checkpoint includes it but samples four primary
cases rather than16. **Those legacy/tier comparisons have different coverage**;
only the paired new-command cache comparison above is a like-for-like saving.

Primary timing source is2954966. A JSON-counter follow-up at9e4e00e confirms
another pair: development7.035→2.364 s; checkpoint37.786→26.556 s. Final89c498f
adds original queue auditors; it does not alter the wages path. Initial queue
checkpoint24.683 s omitted those independent audits and is **superseded**, not a
valid faster-equivalent result. Final queue checkpoint61.234 s includes all eight.

All five profiles were exercised at both levels. Final focused counts: wages66
native /9 Python methods; inputs62/10; contracts42/11; queue33 native /4 planning
methods plus eight independent audits; workflow16 methods. The final workflow
commands pass with 16 methods. The original economic auditor rejects a rehashed
real money forgery. The actual CLI rejects rehashed corrupt cached evidence
(exit1) and forces five fresh audited captures for an unreviewed dependency.
A first witness setup refused a mismatched environment proof; reseeding through
the exact CLI environment resolved setup without weakening a guard. Initial CSV
ResourceWarnings were fixed with context-managed readers before final tests.
Final unit tests pass with ResourceWarnings promoted to errors.

`M31_VERIFICATION.json` preserves dispositions/source identity and the deliberate
full-acceptance deferral. `M31_BENCHMARKS.csv`, `M31_CASES.csv`, dependency proofs,
follow-up summaries, queue audits, negative witnesses, plan and compact unit log
retain exact machine evidence. Large raw logs/traces stay in work directories.
No full M30 matrix or annual sweep was executed for M31. Previous M30 acceptance
is historical evidence, not a substitute M31 certificate.

## Recommended future policy and CI costs

Use development on ordinary edits; checkpoint at meaningful boundaries and before
long experiments. Require full acceptance after final meaningful simulation
changes and before adopting/merging an economic milestone. A short pass must
never be presented as full certification. M31's explicit user-authorized deferral
is not a general waiver. Extend the registry for new subsystems rather than
assuming existing probes test a new scenario.

Next, pilot one GitHub Actions manual/full milestone workflow on pinned Linux
x86_64; no CI migration is implemented here. Pin Godot4.6.3/Python3.12.14,
Rust1.91.1, GCC14.2, SCons4.9.1, Godot API and godot-cpp revision
`abb196939767b7bbee0b3a380faefdcbdb118a54`. Fetch full history (`fetch-depth: 0`), including the reviewed base and older
commits required by the existing control checkers, for source attestation; use a2-CPU/8-GiB-class pilot before comparing timings. Install/build
via the existing [M20 instructions](M20_RESULTS.md), then invoke the same registry
commands, retain compact summaries/pins, and publish raw artifacts separately.

Installation cost in M31 was zero new installation because tools were present;
that is not a free cold setup. The installed Godot executable is132.54 MiB.
M20's recorded cold C++/Rust/bridge+SDK/sanitizer compilation totals35.975 s,
excluding unmeasured downloads/package installation; warm Rust/bridge helpers
were0.026/0.727 s. Pin/source/build/binary-proof keys are required before reuse;
do not cache compiled binaries under a branch-name-only key. Cold hosted setup
and acquisition need their own first-pilot measurements.

For execution budgeting, M30's recorded20 phase walls sum to138.6 command-minutes
under overlapping host contention; that is **not a billable-runner or elapsed-time
prediction**. Individual full commands span4.0 minutes (Python) to28.9 minutes
(M28/M29), and the included M30 economic driver contributed8.2 minutes. Start with an
explicit bounded full-job timeout (e.g.180 minutes), measure actual allocated
runner-minutes, then consider independent lanes for units,169 pins, M23–M27,
M28/M29, C/D and the milestone matrix. Keep timing/Python queue tests isolated and
require all lane artifacts/case sets at the final gate. Missing lanes are failure,
not partial acceptance. Parallelism can reduce elapsed wait while increasing
allocated runner-minutes; measure both. Monetary cost is measured allocation
minutes × the account's current runner rate, subject to repository/plan quotas;
no unverified dollar tariff or free allowance is assumed.

Changed files: new wrapper/unit tests/audit and evidence; concise additions to
AGENTS, README, PERFORMANCE, research index and roadmap. No framework rewrite,
CI YAML, gameplay, mapless implementation, memory or event scheduling was added.
Stop M31 for review; no subsequent milestone or baseline adoption.
