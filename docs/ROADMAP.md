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

**Status:** Atomic transaction mechanism implemented; [verification results](M1_RESULTS.md) await review. Stop here before subsequent work.

- Validated buyer/seller/item/quantity/unit-price exchange with simultaneous goods and money movement.
- Structured success/rejection events and compatibility with ledger auditing.
- Tests for conservation, failed-operation immutability, arithmetic boundaries, capacity, and replay.
- Preserve all M0 checks and the exact existing 30-day output.

**Done when:** atomic purchase tests and all M0 checks pass, events reconstruct purchases correctly, and the existing 30-day simulation remains byte-identical. The current task narrows the earlier economic-robustness plan to this transaction mechanism; NPC purchasing policies, wages, and production planning remain deferred.

## M2: Observable 2D village

- Simple Godot tile map and a handful of buildings.
- NPC schedules and movement with constraints and reachable destinations.
- Inspector UI showing inventories, goals, and event history.

**Done when:** the user can watch simulated daily life and inspect why an NPC took an action.

## M3: Social behavior without LLMs

- Relationships, information sharing, personal goals, commitments, and basic negotiation.
- NPC-to-NPC coordination and shared undertakings, initially through structured rules.

**Done when:** one NPC can recruit another into a shared goal without the player or a Director commanding the outcome.

## M4: LLM decisions as an optional capability

- Provider-neutral adapter, credentials kept out of Git, strict tool/command validation, and per-run usage budgets.
- Player/NPC conversations and selected high-impact autonomous decisions.
- Model failure and budget exhaustion fall back safely to deterministic behavior.

**Done when:** an LLM can propose a meaningful strategy without being able to falsify inventory or historical facts.

## M5: Emergent quests and optional Director

- Player commitments and state-based resolution.
- Rumor/noticeboard/journal discovery of competing opportunities in shared crises.
- Player-originated undertakings and NPC independent responses.
- Director Off/Light/Active experiments with comparable scenario seeds.

**Done when:** one shared crisis supports multiple independent participants and at least two legitimate player approaches, while the world can progress without the player.

## Later possibilities

Trade networks, land ownership, politics, combat, multi-town travel, long-term families, complex crafting, polished art, and a commercial release are potential expansions—not preconditions for learning whether the premise is fun.
