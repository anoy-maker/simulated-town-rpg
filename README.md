# Simulated Town RPG

**A simulation-first fantasy RPG project: autonomous inhabitants, an interdependent economy, and a world that keeps moving without the player.**

**Status (November 2026):** Active research prototype, **not yet a playable RPG**. The working title, design, and future commercial plans are subject to change.

> **Looking for the actual simulation?** The default [`main`](https://github.com/anoy-maker/simulated-town-rpg/tree/main) branch now includes the cumulative **M0–M31** implementation and research history. M31's verification tooling has passed all **17 full-acceptance stages** on [GitHub Actions](https://github.com/anoy-maker/simulated-town-rpg/actions/runs/44449713489) and was integrated via [PR #47](https://github.com/anoy-maker/simulated-town-rpg/pull/47). M30's negotiated-wage treatment remains experimental, not the adopted economic baseline.

## The vision

Imagine a medieval-fantasy settlement where the baker buys grain from a real mill, the mill hires real workers, customers have limited money, and everyone makes decisions based on what they actually know. Businesses can succeed, run out of cash, compete for inputs, or collapse. Those outcomes affect the lives of the people around them.

The eventual goal is **not just to watch a simulation**. A player should be able to enter this same persistent world and participate under the same underlying rules as its NPCs: work, trade, negotiate, own a business, steal, defend someone, or respond to a crisis. NPCs should continue pursuing their own goals if the player chooses to do nothing.

For example, a worker who loses their job *might eventually* turn to banditry, disrupting deliveries between towns and creating a bounty that either the player or another NPC could take on. **That is a design aspiration, not a currently implemented crime/quest feature.** We want quests to represent situations emerging from the world rather than stories written solely for the player.

Inspirations include the systemic depth of *Dwarf Fortress*, grounded routines of *Kingdom Come: Deliverance*, and freedom to explore and intervene in *The Elder Scrolls*. This project is not affiliated with those games.

## What exists today

The current executable prototype is a **headless Godot 4 simulation**, developed in deliberately small, separately selectable scenarios. Later scenarios expand the original four-character economy into experiments with **15 residents (including four business owners), four firms (farm, mill, bakery, brewery), workers, and visiting customers**.

| Area | Implemented experimental capabilities |
| --- | --- |
| **World authority** | Stable entities; validated, atomic transfers; inventories, ownership, production/consumption sources and sinks; structured events and deterministic replay. |
| **Production and markets** | Wheat → flour → bread, with brewing competing for the same grain; finite inputs, equipment, prices, purchases, and real stockouts. |
| **Businesses and labor** | Firm cash, business income, labor capacity, employment choice, vacancies, switching employers, wages, and enforceable three-day contracts. |
| **Autonomous decisions** | Rule-based choices made from permitted observations; bounded forecasting, seller-local demand learning, input reliability estimates, and business financial projections. |
| **Space and observation** | Experimental town locations, travel/custody, physical access to market information, and spatially constrained transactions. This is **not** a rendered or playable open world. |
| **Research tooling** | Separately selectable policy treatments, short and 30-day experiments, independent ledger audits, historical regression pins, and focused verification workflows. |
| **Performance experiments** | Optional C++/Rust numerical kernels and bounded Rust-backed planning queues for specific workloads. **The whole simulation has not been migrated to Rust**; historical/default scenarios remain in GDScript. |

The simulations deliberately allow economic failure. A run that conserves every coin and respects every contract can still produce unemployment, hunger, business losses, or supply-chain collapse. Those are outcomes to investigate, not automatically bugs to paper over.

**Illustrative result:** M30 introduced optional worker wage bidding. Bids were legal and correctly accounted for, but the reference scenario's resident meals fell from **450 to 52 over 30 days** versus its fixed-wage control. The report traces this to the combined hiring/funding and application-selection rules—not simply to lower wages. This treatment is **not** an adopted economic baseline. See [M30 results](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/M30_RESULTS.md).

## How we got here

This is a cumulative experimental project, not a collection of finished gameplay features:

| Milestones | Focus |
| --- | --- |
| **M0–M6B** | Simulation kernel, accounting, purchasing, needs, commitments, competing producers. |
| **M7–M16** | Economic calibration, labor, enterprise ownership, profitability, and dynamic pricing experiments. |
| **M17–M18** | Spatial town experiments and Bayesian, imperfect-information bakery learning. |
| **M19–M22** | Profiling, exact numerical optimization, narrow Rust/C++ ports, async-planning and queue benchmarks. |
| **M23–M25** | Brewery and bakery grain competition, labor-market matching, binding wage contracts. |
| **M26–M30** | Unmet demand, economic feasibility analysis, input reliability, initial cash distribution, and negotiated wages. |
| **M31** | Development/checkpoint/full verification tiers, verified reuse of short captures, and completed independent 17-stage full acceptance. |

Key places to explore:

- [Research index — measured experiments, findings, and limitations](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/RESEARCH_INDEX.md)
- [M30 — Negotiated wages and actual economic outcomes](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/M30_RESULTS.md)
- [M31 — Faster development and verification](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/M31_RESULTS.md)
- [M20 — GDScript, C++, and Rust performance comparison](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/M20_RESULTS.md)
- [M23 — Competing industries and shared grain](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/M23_RESULTS.md)
- [Design principles](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/DESIGN.md) · [Architecture and invariants](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/ARCHITECTURE.md) · [Development cadence](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/PERFORMANCE.md)

These links point to the current **`main` branch**; the milestone reports and their original data remain available in Git history.

## Try the simulation

Use the default [`main` branch](https://github.com/anoy-maker/simulated-town-rpg/tree/main), **Godot 4.6.3**, and **Python 3.12** for the documented M30/M31 environment. No external AI API or credentials are required for the ordinary headless economic scenarios. The optional native performance tests have additional build requirements documented in [M20](https://github.com/anoy-maker/simulated-town-rpg/blob/main/docs/M20_RESULTS.md).

```sh
git clone https://github.com/anoy-maker/simulated-town-rpg.git
cd simulated-town-rpg
# `main` is the verified development baseline.

# Sample three-day worker-bidding experiment:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_dynamic_wages --condition scarce --arm worker_bids --allocation original 3 42 --report-json

# Focused developer checks for wages (creates a local work/ output directory):
python3 -B scripts/tools/verify_workflow.py development --subsystem wages --output work/readme-dev
```

The default `run_simulation.gd` scenario remains the original M0 test case. For other conditions, historical scenarios, detailed audits, or complete acceptance commands, see [the verification workflow guide](docs/PERFORMANCE.md) and [M31 results](docs/M31_RESULTS.md). GitHub Actions runs the native-enabled Godot and Python regression suites on relevant changes to `main`; its **Simulation verification** workflow also offers a manual `full` scope for complete acceptance. Short development checks are **not** a substitute for full milestone certification.

## Where we're heading

Near-term work is about refining the simulated economy and making experiments quicker and cheaper to run. We are exploring how to separate economic decisions from expensive spatial calculations while preserving a single authoritative world. Later work may add crime, transport disruption, social relationships, memory, emergent quests, and an explorable player-controlled character.

These are **directions**, not a claim that those systems already work together or that there is a release date.

## Discussion and collaboration

Ideas, questions, bug reports, and thoughtful critiques are welcome through [GitHub Issues](https://github.com/anoy-maker/simulated-town-rpg/issues). Please open an issue before proposing substantial code contributions. Contributor licensing and a commercial release policy have not yet been established.

## Copyright and licensing

**Copyright © 2026 anoy-maker. All rights reserved in copyrightable project material, to the extent permitted by applicable law.**

This repository is public so people can follow and examine its development. **It is not currently offered under an open-source license.** No general permission is granted to redistribute, sublicense, or commercially reuse copyrightable project material, except where applicable law or GitHub's Terms of Service permits it (including GitHub's platform-provided viewing and forking functionality).

Publication does not confer ownership of the project's code or other protected expression. Ideas, methods, and game mechanics are not claimed as exclusive rights merely by including them here. Licensing and contribution terms may be revisited as the project develops.
