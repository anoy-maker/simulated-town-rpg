# M19 — Profile first, optimize one measured hot path

Implements [issue #23](https://github.com/anoy-maker/simulated-town-rpg/issues/23), from M18 `1d33b57ac30c2a77dac3869d6bd3c7ee4819e3b2`. No language migration or M20.

## Protocol fixed before profiling

No economic/model logic changes in Phase 1. Opt-in scopes measure exclusive and inclusive function time using Godot's monotonic microsecond clock. Exclusive totals partition instrumented work; nested inclusive totals must not be summed. Instrumentation is off by default and never enters canonical output, events, authoritative state, memory, beliefs or choices. Scope/counter overhead is assessed by comparing profiled and unprofiled runs, not assumed zero.

Run-only medians use at least three fresh independent processes per A/C/D × 1/3/30 days, seed 42, on the same host before/after. Unmeasured one-day A/C/D process warm-ups prime OS/code pages; Bayesian caches remain cold in each measured process. Case order rotates between repeats. B30 and M16-A30/M17-A30 receive one coarse context run each. Separate profiled repetitions collect phase attribution, counts and per-decision data (including days 1/3/15/30). No other verification jobs run concurrently with measurement. Load averages are captured; external container contention cannot be ruled out.

The harness separately reports engine-entry clock, runner initialization, `run()`, report/native auditing, canonical/envelope JSON serialization, history capture, complete subprocess wall time and independent Python auditing. Linux `wait4` returns that specific child's peak RSS, not a cumulative maximum over prior commands; Godot samples `/proc/self/status` when available for the high-water mark through `run()`. Process peak includes reporting/serialization. Canonical hashes are captured after `run()` and compared to published M18 values. Profiles remain outside scenario outputs. Full test-suite elapsed time is measured separately at final acceptance. Codex/development duration is not simulation execution time.

No optimization has been chosen before the baseline profile. One measured pure hot path may be optimized after Phase 1, with exact dependency keying, bounded lifetime and unchanged arithmetic order. Final verification includes complete native/Python suites, historical payloads, independent economic/physical/math audits, seed replay and D's actual day-15 probe/day-16 rollback.

## Measurements and findings

Pending baseline measurement.
