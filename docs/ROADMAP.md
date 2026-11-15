# Roadmap — deliberately small experiments

Each milestone must leave the repository in a runnable, testable state. Do not implement later milestones early merely because they're interesting.

## M0: Project setup and simulation kernel (first Codex task)

**Status:** Completed. [M0 results](M0_RESULTS.md) remain the regression baseline for M1.

- Minimal Godot 4 project that opens without an editor-only dependency.
- Four simulated NPCs with stable IDs, money, inventory, and a role.
- Explicit inventory and money transactions with validation.
- Small recipe/consumption loop, seeded daily ticks, event records.
- Headless test runner and short simulation report.

**Done when:** the tests pass (or failures are clearly reported), a 30-day headless run yields understandable events and final balances, and a repeated run with the same seed reproduces identical output.

## M1: Atomic purchases

**Status:** Completed. [M1 verification results](M1_RESULTS.md) remain part of the regression suite.

- Validated buyer/seller/item/quantity/unit-price exchange with simultaneous goods and money movement.
- Structured success/rejection events and compatibility with ledger auditing.
- Tests for conservation, failed-operation immutability, arithmetic boundaries, capacity, and replay.
- Preserve all M0 checks and the exact existing 30-day output.

**Done when:** atomic purchase tests and all M0 checks pass, events reconstruct purchases correctly, and the existing 30-day simulation remains byte-identical. The current task narrows the earlier economic-robustness plan to this transaction mechanism; NPC purchasing policies, wages, and production planning remain deferred.

## M2: The Trading Village

**Status:** Completed. [M2 results](M2_RESULTS.md) remain the fixed-policy comparison and regression baseline.

- Separately selected deterministic scenario with fixed-price wheat/flour/bread purchases and a basic employer payment.
- Explicit initial endowments, tick order, source/sink accounting, and failure consequences.
- Cash-flow, trade, production, consumption, and shortage reports for 30 and 365 days.
- Preserve M0's historical output and all M0/M1 tests.

**Done when:** the trading ledger reconstructs exact state, cash and commodities reconcile, both run lengths reproduce, and results document failures without economic tuning. This task replaces the earlier visual-village M2 plan; rendering and movement remain deferred.

## M3: Needs and Decisions

**Status:** Completed. [M3 results](M3_RESULTS.md) remain the needs-based baseline for coordination.

- Separate `agents` scenario with deterministic needs, priorities, and state-dependent economic choices.
- Explicit separation of copied observations, goals, proposed actions, and authoritative execution.
- Information limited to self state and explicitly advertised public market offers.
- Structured decision/outcome annotations, accounting, and 30/365-day comparison against unchanged M2 parameters.
- Preserve all prior coverage and historical M0/M2 outputs.

**Done when:** focused tests demonstrate changed choices under changed circumstances, economic/decision logs reconcile, both run lengths replay, regressions remain identical, and failures are reported without tuning economic parameters. This task replaces the earlier social-behavior M3 plan; relationships, negotiation, and recruitment remain deferred.

## M4: Commercial Requests and Commitments

**Status:** Completed. [M4 results](M4_RESULTS.md) remain the unbudgeted-commitment baseline.

- Separately selected `coordination` scenario with voluntary public supply requests and prepaid acceptance.
- Validated, one-time real-stock delivery and retained outstanding/closed obligations.
- Pure commercial decisions from permitted observations, with no forced redistribution.
- Ledger reconstruction, conservation, duplicate limits, and 30/365-day comparison against unchanged M3 parameters.
- Preserve M0/M2/M3 historical outputs and all prior tests.

**Done when:** independent NPC choices can form and execute valid supply agreements, failures remain auditable, all regressions pass, and actual outcomes are documented without tuning the economy. Recovery is not required. This task replaces the earlier LLM M4 plan; AI integration remains deferred.

## M5: Commitment-Aware Planning

**Status:** Implemented and verified; [M5 results](M5_RESULTS.md) await review. Stop here; M6 has not started.

- Separate `planning` scenario with commitment-first and immediate-needs-first spending priorities.
- Shared own-state/public-market input-cost estimates and advisory working-capital budgets.
- Identical financial parameters, opportunities, action capabilities, and authority across strategies.
- Focused testing of the M4 prepayment-spending failure and deterministic 30/365-day comparison.
- Preserve all historical scenarios and record remaining shortages or deadlocks without tuning outcomes.

**Done when:** budgeting and authoritative accounting are distinct, priority effects are reproducible and audited, all prior tests/hashes pass, and actual results/limitations are documented. Recovery is not required. This task replaces the earlier quests/Director M5 plan; those features remain deferred.

## Later possibilities

Trade networks, land ownership, politics, combat, multi-town travel, long-term families, complex crafting, polished art, and a commercial release are potential expansions—not preconditions for learning whether the premise is fun.
