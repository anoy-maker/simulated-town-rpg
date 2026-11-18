# Research Index — Simulated Town RPG

**Status:** Living research and decision-navigation document. Created 2026-11-17 on `codex/m26-demand-observation`.  
**Purpose:** Make existing engineering experiments, economic experiments, and standalone research reviews discoverable **without renaming milestones or rewriting their historical evidence**.  
**Authority:** The linked original reports, predeclared protocols, source, and independently verified artifacts remain authoritative for measured results. This index is a summary and routing guide, not a new experiment or replacement specification.

## How to classify research in this repository

Research is **a kind of work**, not a requirement that its identifier begin with `R`.

- **M-series (milestones):** Numbered development increments. Some implement a mechanic, some run controlled research experiments, and some do both. Their original IDs, issue references, branches, hashes, and regression controls are retained.
- **R-series (research reviews):** Standalone investigations that primarily synthesize sources, inspect architecture, identify hypotheses, or recommend experiments **without independently implementing or validating a new mechanic**. An R-series proposal is not proof that its proposed approach works.
- **Feasibility notes and experiment protocols:** Predeclared assumptions and executable or analytical witnesses supporting an M-series experiment. They are supporting research artifacts, not separate renamed milestones.
- **Results vs. recommendations:** Measured findings are valid only under the stated scenario, hardware, samples, and controls. A recommendation to investigate or implement something is not an approved default, completed implementation, or demonstrated performance gain.

For future work, preserve the original evidence and use this index to navigate. Do **not** relabel `M19` as `R19`, rename historical files, rewrite regression pins, or imply that a numerical Rust kernel means the whole town/world is written in Rust.

## Experimental engineering research: M19–M22

These **qualify as research reports in substance**: each poses a specific engineering question, compares explicit alternatives or workloads, records measured outcomes, verifies correctness, and states limits. They remain M-series because the experiments also produced implementation work and reproducible test infrastructure.

| Original report | Research question and method | Supported findings | What it does **not** establish |
| --- | --- | --- | --- |
| [M19 — Profiling and one measured optimization](M19_RESULTS.md) ([issue #23](https://github.com/anoy-maker/simulated-town-rpg/issues/23)) | Profile M18 Cora decision costs, then test an exact call-local continuation reuse table against an instrumented baseline. | On the recorded host, 30-day run-only medians C **32.865→30.024 s** (−8.6%) and D **45.310→36.915 s** (−18.5%); decision arithmetic and canonical outputs stayed consistent. | Not a general simulation speed claim, a new demand theory, or a language migration. |
| [M20 — Equivalent C++ and Rust numerical kernels](M20_RESULTS.md) ([issue #25](https://github.com/anoy-maker/simulated-town-rpg/issues/25)) | Port the same bounded forecast/financial numerical subset to opt-in C++ and Rust backends; compare like-for-like decisions and simulations under parity requirements. | D30 run-only medians **29.99 s GDScript, 4.09 s C++, 3.99 s Rust** on tested hardware; economic outputs and historical fingerprints preserved. Rust is a demonstrated option for this narrow workload. | Not a full-Godot-to-Rust port, permanent engine migration, or guaranteed frame responsiveness. Native full-decision p99 remained approximately **98 ms**. |
| [M21 — Deterministic Rust-backed planning jobs](M21_RESULTS.md) ([issue #27](https://github.com/anoy-maker/simulated-town-rpg/issues/27)) | Move one complete Cora proposal computation to a persistent worker while keeping world authority and ordered commitment on the main thread. | D30 main-update p99 **76.166→16.743 ms**, but median decision appointment **66.742→84.020 ms** and tested frame-pump elapsed time increased **13.5%**. Correct proposal parity and main-thread authority were retained. | Not nonblocking authoritative world progress, actual player movement during planning, multi-NPC scaling, or a default migration. |
| [M22 — Planning-scale and performance guardrails](M22_RESULTS.md) ([issue #29](https://github.com/anoy-maker/simulated-town-rpg/issues/29)) | Exercise bounded Rust-backed queues using **synthetic** 1/10/100-job and mixed workloads with 1/2/4 workers; measure throughput, tails, ordering, memory and backpressure. | A single worker suits a single required proposal; two can help independent bursts; four were **not justified as a default on the tested two-CPU quota**. Produced bounded dispatcher tests and reusable [performance cadence](PERFORMANCE.md). | Not a live 100-citizen simulation, scaled world simulation, FPS benchmark, or proof of safe parallel world-state mutation. |

### Engineering evidence worth reusing

- [M19](M19_RESULTS.md) explains the baseline-first profiling protocol, how to isolate a hotspot, and how to keep optimization semantically exact.
- [M20](M20_RESULTS.md) and [`native/m20/SCHEMA.md`](../native/m20/SCHEMA.md) document the **narrow numerical ABI**, float tolerance and native parity. Reuse it only if a later workload is shown to match; do not pass new world authority or new economic semantics through it by assumption.
- [M21](M21_RESULTS.md) documents permitted snapshot handoff, stale work/cancellation, and the **decision appointment barrier**. Making calculations asynchronous does not mean the world can advance past a decision that has not been validated and committed.
- [M22](M22_RESULTS.md) and [`PERFORMANCE.md`](PERFORMANCE.md) preserve lightweight performance smoke, bounded queue load, measured tails, and the *targeted checks → checkpoint → full milestone acceptance* cadence. Do not infer player-facing smoothness from headless callbacks.

**Standing engineering decision:** The historical/default world and contracts still run in **GDScript**. The opt-in Rust work accelerates and schedules particular M18 Cora calculations; M25/M26 do not use Rust by default. Reconsider a Rust boundary only after profiling a real new bottleneck and specifying the narrow, reproducible calculation contract.

## Economic policy and mechanism experiments: selected M-series

These are also research-bearing, but unlike the primarily technical M19–M22, they test agent information, incentives and economic consequences. Link the preflight/feasibility material and experimental results together; neither is complete context alone.

| Report and support | Main question | Key evidence / interpretation |
| --- | --- | --- |
| [M18 — Bayesian bakery learning](M18_RESULTS.md) | Can Cora learn from seller-local, incomplete observations and reason financially about bread pricing? | Separates arrivals, quotes, purchases, voluntary declines, stockouts and censored observations; tests bounded cohort-specific Bayesian pricing/EVSI. This specialized model is **not** a drop-in posterior for all B2B firms. |
| [M23 — Brewery and shared grain inputs](M23_RESULTS.md) · [predeclared feasibility](M23_FEASIBILITY.md) | What happens when bread and brewing compete for grain under finite funds, physical delivery and indivisible production? | Establishes an independently checked possible production day and compares reference/tight/scarce/no-brew cases. A feasible witness is **not** a claim that autonomous firms will discover or sustain the allocation. |
| [M24 — Local labor selection and matching](M24_RESULTS.md) · [feasibility](M24_LABOR_FEASIBILITY.md) | How do fixed-wage firm vacancies, locally observed offers, and voluntary worker switching affect the supply chain? | Controlled labor mobility with legal opportunities and separate labor conditions, without claiming that matching alone guarantees viable employment. |
| [M25 — Binding three-day contracts](M25_RESULTS.md) · [feasibility](M25_CONTRACT_FEASIBILITY.md) | How do guaranteed wages, standby, cash constraints and enforceable claims change production and hiring? | Makes future wage commitments legally and financially meaningful; shows lawful nonrenewals and stalls can emerge despite conserved funds and zero unpaid main-case wages. |
| [M26 — Demand observation and renewal](M26_RESULTS.md) · [preregistered protocol](M26_DEMAND_FEASIBILITY.md) | Does adding credible stockout-unfilled requests to an otherwise matched demand smoother change renewal decisions? | Request-aware forecast improves resident meals over matched sales smoothing in three constrained **main seed-42 cases**, but can raise standby costs, exhaust brewery capital, and perform worse in a staggered comparison. **No request-aware default, universal welfare improvement, or viable economy is established.** |
| [M27 — Offline economic diagnostics](M27_RESULTS.md) · [protocol](M27_ECONOMIC_DIAGNOSTICS_FEASIBILITY.md) · [schemas](M27_SCHEMAS.md) | Can independent integer, transport and cash witnesses separate supply capacity from funded meals and actual decisions without changing the economy? | Checked scarce day1 alternatives support21 rather than14 bread; day3 extra supply still leaves three residents unable to buy. Actual901 purchasing-power and269 solvent-stockout missed meals have native provenance. These are one-day witnesses and immediate blockers, **not an incentive proof, financed optimum or new viable default**. |
| [M28 — Own-input reliability in contract forecasts](M28_RESULTS.md) · [frozen protocol](M28_INPUT_FEASIBILITY.md) | Does a bounded own funded-order fill estimate change three-day renewals while all other R rules remain fixed? | Main tight/scarce brewery margins improve and output continues through day30, but resident meals change395→398 and378→355; no-brew325→317. Staggered resident gains displace visitors at unchanged bread output. **Local forecast/capital gains do not establish household welfare, annual resilience or an adopted default.** |

**Research interpretation:** These findings are not an unbroken series of global improvements. Each uses particular initial conditions, interventions, price/wage rules, and horizons. When comparing milestones, read their scenario provenance and controls first. A single seed replayed twice establishes determinism, not broad robustness across worlds or seeds.

## Standalone research investigations: R-series

### [R26 — Economic architecture research and feasibility diagnostics](R26_ECONOMIC_ARCHITECTURE_REVIEW.md)

**Type:** Research synthesis and inspection of existing source; **no new simulator code or experiment**.  
**Inputs:** M23–M26 scenario evidence and implementation; agent-based computational economics, input-output/Leontief analysis, stock-flow consistent accounting and discrete production/incentive issues.  
**Main finding:** Distinguish physical capacity, ability to finance legally timed production, and what decentralized profit-seeking agents actually choose. Demand evidence alone cannot resolve inputs, contract obligations or purchasing-power limitations.  
**Proposed next step:** A **read-only M27 economic-feasibility/failure-attribution diagnostic** with explicit integer/timing/financial witnesses, independent auditing and preregistered controls **before** changing wages, prices, contracts or business heuristics.  
**Status:** Recommendation only. M27 is **not** implemented or validated by R26.

Read R26's [implementation facts and limits](R26_ECONOMIC_ARCHITECTURE_REVIEW.md) before transferring its worked examples into a new design. Especially retain the distinction between **accepting a new wage obligation** and **assigning productive work to someone already owed a guaranteed wage**; day-one tight/scarce output with existing employees is not governed by the same incremental cost as a fresh hire.

## Research-to-implementation workflow

When proposing the next milestone, record the following in its issue/protocol or an R-series review:

1. **Question:** What specific bottleneck, agent belief, accounting gap or causal hypothesis is under study?
2. **Existing evidence:** Cite relevant M/R reports, predeclared assumptions, source paths, and exact measured results rather than asserting them from memory.
3. **Alternatives and mechanisms:** Compare at least the unmodified control and a narrowly isolated treatment; explicitly identify what remains fixed.
4. **Knowledge boundary:** Distinguish omniscient researcher diagnostics from only the information a firm/NPC could genuinely know. Never use a diagnostic optimum as an NPC's hidden oracle.
5. **Prognostic and accounting tests:** Specify conserved resources, lawful payments, integer goods, timing, event provenance and independent reconstruction. For stockouts, observed requests are lower bounds, not omniscient latent demand.
6. **Measurement plan:** Predeclare seeds, horizons, matched runs, correctness/parity tests, environmental metadata and meaningful error bars/limitations. Report regressions and negative results.
7. **Decision:** Record what the evidence supports, which assumptions failed, whether a feature stays optional, and what would justify promotion to a default. Avoid retuning after seeing the target outcomes.
8. **Documentation:** Keep the original report and audit artifacts; update **this index** with a short question/result/limitations row. Do not alter historical milestone identifiers.

### Suggested reading routes

- **Considering more Rust or parallelism:** [M19](M19_RESULTS.md) → [M20](M20_RESULTS.md) → [M21](M21_RESULTS.md) → [M22](M22_RESULTS.md) → [performance practices](PERFORMANCE.md).
- **Designing business demand beliefs:** [M18](M18_RESULTS.md) → [M25](M25_RESULTS.md) → [M26 protocol](M26_DEMAND_FEASIBILITY.md) → [M26 results](M26_RESULTS.md).
- **Diagnosing supply chains / town sustainability:** [M23 feasibility](M23_FEASIBILITY.md) → [M23 results](M23_RESULTS.md) → [M25](M25_RESULTS.md) → [M26](M26_RESULTS.md) → [R26](R26_ECONOMIC_ARCHITECTURE_REVIEW.md) → [M27 diagnostics](M27_RESULTS.md).
- **Changing global architecture:** Start with [`DESIGN.md`](DESIGN.md), [`ARCHITECTURE.md`](ARCHITECTURE.md), [`ROADMAP.md`](ROADMAP.md) and [`AGENTS.md`](../AGENTS.md), then follow the relevant evidence above.

## Maintenance rule

This index is a **curated pointer to preserved primary evidence**. Update it when a research result materially changes a decision, an experiment closes, or a new standalone R-series review is completed. Do not promise that a proposed next milestone exists until it is explicitly created, and do not present isolated research conclusions as accepted economic baselines.
