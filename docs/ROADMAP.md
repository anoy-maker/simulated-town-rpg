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

**Status:** Completed. [M8 results](M8_RESULTS.md) remain unchanged; no candidate/default adoption.

- Optional combined affordable-bread/productivity configuration; reuse the three matched M7 comparisons.
- Keep all other parameters, policies, authoritative mechanisms, historical outputs, and defaults unchanged.
- Six new 30/365-day cases for seeds 7/42/99, independent replay and shared audits.
- Observe food owned during planning but sold before consumption without reserving it or changing behavior.
- Assess capacity, household access, business continuity, distribution, and sampled resilience, not only aggregate meals.

**Done when:** all regressions pass, the four-way comparison and event-linked observation are documented, limitations are explicit, and adoption/future work remain for review.

## M9: Workplaces, Labor, and Employment

**Status:** Completed. [M9 results](M9_RESULTS.md) remain the unchanged labor baseline.

- Separate twelve-resident `settlement_labor` experiment with business accounts, productive assets, owners, skills, employment, and actual paid shifts.
- Predeclared prices, wages, endowments, capacity, and positive potential physical buffer; no post-result rescue or tuning.
- Pure owner/worker decisions, authoritative eligibility/payroll/input/capacity validation, bounded labor across workplaces.
- Individual food needs from personal funds; explicit skipped, unfunded, and failed shifts.
- Fixed 30/365-day seeds 7/42/99, replay, independent full ledger/receipt reconciliation, household/business reports, all prior hashes preserved.

**Done when:** actual participation, productive capacity/utilization, payroll and capital, food access, inactivity and failures are documented without guaranteeing prosperity. Historical scenarios remain unchanged; further settlement systems wait for review.

## M10: Business Income and Capital Circulation

**Status:** Completed. [M10 results](M10_RESULTS.md) remain unchanged and have not been adopted as a viable economy.

- Separate `settlement_finance` scenario using exactly M9's population, initial holdings, labor/production, wages, prices and market rules.
- Atomic, ownership-authorized cash withdrawals with a conservative two-day operating reserve; separate income from wages and formal profit.
- Predeclared no-withdrawal, household-needs and half-surplus policies; no outcome tuning or forced work/subsidy.
- Matched 30/365-day seeds 7/42/99, independent replay/reconstruction, exact M9 control and all historical hashes preserved.
- Per-business capital/revenue/expenses/production and individual wages/distributions/food access; assess employee participation and sustained circulation.

**Done when:** technical accounting/reserve safeguards and actual economic effects are independently verified and documented. Increased circulation alone does not establish broad viability; further changes wait for review.

## M11: Deterministic Economic Equilibrium Reference

**Status:** Completed. [M11 results](M11_RESULTS.md) remain the unchanged prescribed control.

- Isolated prescribed reference with the exact twelve-person endowments, 2/4/4 prices, eight-coin shifts and deterministic four-wheat harvest.
- Reuse authoritative purchases, payroll and recipes; alternate two worker pairs per industry and feed everyone daily.
- Verify 1/2/30/365 days, every-event conservation/bounds, daily business recurrence and two-day household recurrence.
- Check 4380 annual meals, 2190 shifts, zero misses, actual commodity sources/sinks and deterministic replay.
- Preserve historical outputs; use concise reports and ledger fingerprints rather than verbose annual dumps.

**Done when:** the exact reference invariants pass, actual results/deviations are documented, and feasibility under prescribed decisions remains explicitly distinct from autonomous stability. No sector expansion or new autonomous economic behavior.

## M12: Employer-Driven Production and Labor Scheduling

**Status:** Completed. [M12 results](M12_RESULTS.md) remain the unchanged employer-choice control.

- Isolated `settlement_employer_choice` keeps every M11 economic parameter, initial holding and employment relationship.
- Pure own-last-sales forecasting, one-time reference startup, unsold-stock offsets and minimum funded productive shifts.
- Owner-first then stable-ID employee staffing; no rotation, guaranteed hours, management wages or rescue.
- Read-only own-firm history, public offers and authorized workforce; original authority executes all purchases/payroll/production.
- Matched 2/30/365-day control/experiment, receipt reconstruction, deterministic replay and all historical hashes preserved.
- Document first financial exclusion, reduced realized demand/output, persistent employee unemployment and continuing owner-supported trade without tuning policies.

**Done when:** technical correctness and the actual departure from M11 are documented, with physical capacity distinguished from paid food access. Its outcomes are preserved for the separately authorized M13 diagnosis.

## M13: Employment Allocation versus Production Forecasting

**Status:** Completed. [M13 results](M13_RESULTS.md) remain unchanged.

- Complete the 2×2 experiment: fixed production/owner-first staffing and sales-based production/exclusive rotating pairs, with M11/M12 as unchanged controls.
- Reuse exact endowments, rules, authority and small existing policy components; no fixed-target stock offset or out-of-group worker substitution.
- All four conditions at 2/7/30/365 days, seed 42, receipt reconstruction, independent process replay and historical hashes.
- Distinguish financial food exclusion, physical availability, operating-capital limits and reduced forecast production; report individual participation and cash distribution.
- Use matched contrasts and interaction, preserve outcomes and avoid economic repairs or general claims about employers/markets.

**Done when:** concise results and limitations are documented with technical verification. The separately authorized M14 is a prescribed reference, not a repair to these policies.

## M14: Profitable Ownership and Contractual Employment Reference

**Status:** Completed. [M14 results](M14_RESULTS.md) remain the unchanged contractual reference.

- Isolated prescribed reference with original twelve-person ownership/assets/endowments/prices; owners manage without paid productive work.
- Nine employees receive two six-coin productive shifts per three-day cycle; real constraints produce explicit unmet obligations rather than imaginary work, wages or debt.
- Cumulative realized sales/input/payroll cash supports bounded owner distributions after household consumption, retaining all 120 business capital.
- Reuse native purchases/paid labor/recipes/transfers; preserve all historical scenarios and pinned outputs.
- Verify 1/2/3/30/365 days, every-event accounting, daily business recurrence, three-day household recurrence, replay and synthetic failure behavior.

**Done when:** actual results and architectural limits are documented, with prescribed feasibility clearly separated from autonomous stability. Its results remain unchanged for M15.

## M15: Open Economy and Business Formation

**Status:** Completed. [M15 results](M15_RESULTS.md) remain the unchanged open-economy and formation reference.

- External-trade reference with finite visitor funds, original twelve residents/three firms, nine genuine daily employee shifts and unchanged two-of-three minimum contracts.
- Actual paid purchases and visitor consumption, separate village/combined money boundaries, realized owner income and daily financial recurrences at 1/3/30/365 days.
- Controlled Finn startup using personal capital, a zero-endowment firm, identifiable pre-existing assets and real inputs; distinguish capital flows from operating earnings.
- Unpaid owner production, retained earnings and explicit bounded distribution policies with no universal 120-coin floor for new firms.
- Public local postings, applications, employer offers, employee acceptance and boundary-effective jobs/resignations; one productive affiliation, ownership separate from labor, prior promises preserved.
- Native and independent Python reconstruction, compact results/fingerprints, deterministic process and split replay, all M0–M14 historical results preserved.

**Done when:** A/B/C and failure tests verify actual transactions and transitions, limitations and disrupted old commitments are explicit, and results are reviewable. No autonomous entrepreneurial or hiring decisions, investment optimization or additional sectors were introduced.

## M16: Dynamic Pricing and Rational Market Competition

**Status:** Completed. [M16 results](M16_RESULTS.md) remain the unchanged pricing experiment.

- Isolated seller-specific versioned commodity quotes, owner authorization, one revision/item/day, actual stock and atomic purchase authority.
- Pure essential/input buyer selection, affordable cheapest offers, rotating ties, legitimate stale/stock retry and finite visitors with private reservation prices.
- Restricted own/public pricing observations, explicit demand priors/sensitivity, current±1 candidates and independently checked one-period cash objective; fixed and reserved personality interfaces.
- Predeclared A fixed / B bakery / C mill-bakery / D whole-chain stages, preserving M15 production, jobs, wages, prices at initialization, assets, money and distributions.
- Separate finite-stock competition fixture, 1/3/30-day process/split replay, full financial/labor/quote/decision auditing, daily reports and all historical outputs unchanged.

**Done when:** actual trade, price choices, unmet demand, inventory/cash consequences and contractual failures are documented without economic rescue or tuning. Correct decisions under a limited belief do not imply accurate forecasts or stability. No autonomous entrepreneurship, production/staffing optimization or new sectors were introduced.

## M17: Headless Spatial Town and Scheduling

**Status:** Implemented and verified; [M17 results](M17_RESULTS.md) await review. Stop after M17.

- Isolated 10×7 integer map, deterministic shared housing, persistent positions/schedules, five-minute adjacent movement and a render-independent clock.
- Actual non-overlapping commutes, one-hour employee work and unpaid owner management; on-site quote purchases and warehouse-ready inputs through authorized owner cargo custody.
- Six temporary visitor requests use one unchanged finite account, arrive/inspect/shop/consume/exit physically, and never create currency or permanent residents.
- Personally co-located arrival/inspection/purchase/no-purchase encounter views; no private customer finances, remote sightings or future-demand disclosure.
- Fixed-price 1/3/30-day controls reproduce M15/M16-A financial/goods outcomes; one-day late-worker/early-close fixtures preserve real consequences without economic repairs.
- Full accounting/custody/location/time/witness audits, independent process and split replay, complete native/Python suites and all historical fingerprints unchanged.

**Done when:** map/routes/schedules, actual parity/failures, authority extensions and limits are documented for review. No M18 memory/value-of-information pricing, autonomous staffing/investment, economic calibration, additional sectors or graphics.

## Later possibilities

Trade networks, land ownership, politics, combat, multi-town travel, long-term families, complex crafting, polished art, and a commercial release are potential expansions—not preconditions for learning whether the premise is fun.


## M18: Bayesian bakery memory and capital-aware discovery

**Status:** Implemented experiment; [M18 results](M18_RESULTS.md) await review.
Isolated spatial A–D pricing treatments, exact permitted cohort memory, explicit
subjective model/financial objective and bounded EVSI. Preserve M0–M17 baselines.
This tests a provisional price-learning approximation; it does not establish optimal
prices, viable autonomous settlement policy or structural demand identification.
**Stop after M18. Do not begin M19.**
