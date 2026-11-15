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

**Status:** Completed. [M5 results](M5_RESULTS.md) remain the commitment-aware four-person baseline.

- Separate `planning` scenario with commitment-first and immediate-needs-first spending priorities.
- Shared own-state/public-market input-cost estimates and advisory working-capital budgets.
- Identical financial parameters, opportunities, action capabilities, and authority across strategies.
- Focused testing of the M4 prepayment-spending failure and deterministic 30/365-day comparison.
- Preserve all historical scenarios and record remaining shortages or deadlocks without tuning outcomes.

**Done when:** budgeting and authoritative accounting are distinct, priority effects are reproducible and audited, all prior tests/hashes pass, and actual results/limitations are documented. Recovery is not required. This task replaces the earlier quests/Director M5 plan; those features remain deferred.

## M6: Competing Producers and Multiple Market Participants

**Status:** Completed. [M6 results](M6_RESULTS.md) remain the original two-farmer regression baseline.

- Separate six-person `market` scenario with two farmers, one miller, two bakers, and one laborer.
- Public multi-supplier discovery and deterministic price/stock/ID selection, without private seller finances.
- Common occupation behavior and commitment-first planning under authoritative purchases and agreements.
- Explicit fixed endowments/scheduling, supplier accounting, conservation, and predefined 30/365-day experiments for seeds 7, 42, and 99.
- Preserve all historical M0/M2/M3/M4/M5 outputs and prior test coverage; report concentration, shortages, and failures without tuning.

**Done when:** competing buyers cannot duplicate stock, either eligible producer can sell or fulfill agreements, reports and full ledgers reconcile, all replay/regression checks pass, and outcomes and experimental limitations are documented. Stability or improvement over a different-sized village is not required.

## M6B: Revised Downstream Market Experiment

**Status:** Completed. [M6B results](M6B_RESULTS.md) remain the downstream-demand baseline.

- Separate `market_downstream` configuration: one farmer, two millers, two bakers, one laborer; 115 initial coins.
- Reuse the existing configurable market runner and all occupation policies without duplicating simulation logic.
- Keep prices, targets, recipes, commitment-first priorities, wages, and all historical scenarios unchanged.
- Predefined 30/365-day experiments for seeds 7, 42, and 99; inspect farmer response, competition, cash flow, unmet needs, and commitments.

**Done when:** all regressions pass, actual outputs replay and reconcile, the farmer's four-wheat rule is explicitly examined, and results distinguish role/capacity/endowment/scheduling differences without tuning or causal improvement claims. Calibration remains deferred.

## M7: Economic Foundations and Calibration Laboratory

**Status:** Completed. [M7 results](M7_RESULTS.md) remain the isolated-intervention baseline.

- Separate calibration scenario with only the requested yield, target, price, wage, and initial-balance parameters.
- Fixed M6B baseline plus five isolated interventions; unchanged population, policies, recipes, authority, and scheduling.
- Feasibility arithmetic before agent-outcome analysis; distinguish capacity, affordability, working capital, and observed behavior.
- Predefined seeds 7/42/99 at 30/365 days, matched environments, full accounting/replay, and per-NPC CSV results.
- Preserve all historical outputs; report improvements, deterioration, or stalls without optimization or post-result tuning.

**Done when:** configuration boundaries and accounting are verified, all prescribed experiments replay, economic limits and actual results are documented, and future calibration directions remain suggestions only.

## M8: Candidate Viable Economic Baseline

**Status:** Implemented and verified; [M8 results](M8_RESULTS.md) await review. No candidate/default adoption; M9 has not started.

- Optional combined affordable-bread/productivity configuration; reuse the three matched M7 comparisons.
- Keep all other parameters, policies, authoritative mechanisms, historical outputs, and defaults unchanged.
- Six new 30/365-day cases for seeds 7/42/99, independent replay and shared audits.
- Observe food owned during planning but sold before consumption without reserving it or changing behavior.
- Assess capacity, household access, business continuity, distribution, and sampled resilience, not only aggregate meals.

**Done when:** all regressions pass, the four-way comparison and event-linked observation are documented, limitations are explicit, and adoption/future work remain for review.

## Later possibilities

Trade networks, land ownership, politics, combat, multi-town travel, long-term families, complex crafting, polished art, and a commercial release are potential expansions—not preconditions for learning whether the premise is fun.
