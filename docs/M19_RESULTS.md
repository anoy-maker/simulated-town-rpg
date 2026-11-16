# M19 — Profile first, optimize one measured hot path

Implements [issue #23](https://github.com/anoy-maker/simulated-town-rpg/issues/23), from M18 `1d33b57ac30c2a77dac3869d6bd3c7ee4819e3b2`. No language migration or M20.

## Protocol fixed before profiling

No economic/model logic changes in Phase 1. Opt-in scopes measure exclusive and inclusive function time using Godot's monotonic microsecond clock. Exclusive totals partition instrumented work; nested inclusive totals must not be summed. Instrumentation is off by default and never enters canonical output, events, authoritative state, memory, beliefs or choices. Scope/counter overhead is assessed by comparing profiled and unprofiled runs, not assumed zero.

Run-only medians use at least three fresh independent processes per A/C/D × 1/3/30 days, seed 42, on the same host before/after. Unmeasured one-day A/C/D process warm-ups prime OS/code pages; Bayesian caches remain cold in each measured process. Case order rotates between repeats. B30 and M16-A30/M17-A30 receive one coarse context run each. Separate profiled repetitions collect phase attribution, counts and per-decision data (including days 1/3/15/30). No other verification jobs run concurrently with measurement. Load averages are captured; external container contention cannot be ruled out.

The harness separately reports engine-entry clock, runner initialization, `run()`, report/native auditing, canonical/envelope JSON serialization, history capture, complete subprocess wall time and independent Python auditing. Linux `wait4` returns that specific child's peak RSS, not a cumulative maximum over prior commands; Godot samples `/proc/self/status` when available for the high-water mark through `run()`. Process peak includes reporting/serialization. Canonical hashes are captured after `run()` and compared to published M18 values. Profiles remain outside scenario outputs. Full test-suite elapsed time is measured separately at final acceptance. Codex/development duration is not simulation execution time.

No optimization has been chosen before the baseline profile. One measured pure hot path may be optimized after Phase 1, with exact dependency keying, bounded lifetime and unchanged arithmetic order. Final verification includes complete native/Python suites, historical payloads, independent economic/physical/math audits, seed replay and D's actual day-15 probe/day-16 rollback.

## Measurements and findings

Phase 1 completed before economic/math edits. Unprofiled 30-day medians: A 2.815194 s, C 32.864863 s, D 45.310453 s (three independent processes each). The separate profiled C30/D30 runs take 33.714726/42.271652 s. Their largest isolated-function times differ: C spends 14.690 s in demand mixtures versus 10.747 s in continuation; D spends 19.229 s in continuation versus 14.704 s in mixtures. D is the slowest stage; continuation is its largest actionable function (45.49% of run), and combined C/D continuation self-time is 29.976 s. Forecast matrix+mixture work is also substantial and remains untouched in this milestone.

C30 evaluates 119 candidates, 1071 observable branches and 5076 continuation projections. D30 evaluates 120, 1080 and 9198 respectively. Per-decision work stabilizes at four candidates/36 branches after day 3, even as raw memory grows from two to 29 previous days. D's day-3/15/30 continuation count stays exactly 306; C's stays 171. There is no forecast scan proportional to raw memory length. Cold beta-table misses fall to zero by day 15; traffic-component misses also decline. Finance branch count and repeated fixed-size numerical work dominate, not growing remembered-event queries.

## Single optimization chosen after measurement

Inspect only the measured continuation hot path. Its twelve-day tail repeatedly computes the same full-stock sales expectation for a given forecast row across first-day sales branches. When stock >= PMF.size()-1, min(stock, quantity) is exactly quantity for every supported outcome. Reusing the original mean_sales result at that support bound therefore preserves its floating-point additions/multiplications in the same order, including boundary cases; stock-limited paths still execute the original calculation.

Add a lazy table with one entry per forecast tail day **local to one continuation call**. Each slot is bound to that call's exact immutable forecast row. No cross-call state, rounded keys, persistent model cache, finance-state cache, approximation, candidate pruning or arithmetic reassociation is introduced. Different beliefs/price/market context produce different forecast arguments and fresh tables; different cash/inventories continue through the original integer/mean-state transitions. The table is discarded on return. Profile counters will record reused evaluations and misses; expected-value/EVSI parity and published canonical JSON hashes remain mandatory.

Before/after tables and final verification pending.
