# Architecture sketch — simulation-first Godot project

## Guiding separation

**Simulation kernel → validated world-state changes → structured event log → views, memory, and AI adapters.**

Godot provides the eventual 2D presentation and project runtime. Keep the initial simulation code independent of scenes, camera, sprites, animations, and player input so the same rules run headlessly.

Proposed boundaries (refine as implementation teaches us more):

- **WorldState:** authoritative entities, IDs, inventories, balances, jobs, current day/tick, and relevant world data.
- **Commands:** explicit requests such as `transfer_item`, `transfer_money`, `produce`, and `consume`.
- **Rules/validation:** check ownership, availability, nonnegative amounts, legal recipes, recipient capacity if implemented, and required conditions.
- **SimulationRunner:** advances a fixed time step in documented order; all random draws from a seeded generator.
- **Policies:** uncomplicated rule-based NPC routines for the initial prototype. Later, a policy can consult an LLM and propose the same command types.
- **EventLog:** append-only structured records for every successful state change and meaningful failure, with stable IDs, tick, actor, action, amounts, and targets.
- **Reports/tests:** headless inspection of trajectories, per-NPC state, and invariants.

Later (not in milestone one): character belief stores; rumor propagation; goal and commitment systems; shared undertakings; LLM adapter; Director; journal projection; renderer and spatial movement.

## Invariants to preserve

1. **No negative money or inventory** unless an explicit debt or overdraft mechanic is introduced later.
2. **Conservation on transfers:** a normal item transfer cannot create or destroy items; a normal money transfer cannot create or destroy money.
3. **Explicit sources and sinks:** harvest, crafting, eating, decay, taxes leaving the modeled region, and minting are distinct documented operations. Crafting consumes declared inputs and creates declared outputs.
4. **Atomic operations:** failed commands leave authoritative state unchanged (but may create a failure record if designed that way).
5. **Stable entity IDs:** names can change without breaking references.
6. **Replayability:** same seed, initial state, rules, and ordered inputs produce the same report and event sequence.
7. **Single source of truth:** UI, LLM summaries, journals, and reports do not mutate authoritative state directly.

Tests should verify these rules at boundaries and after many sequential simulated actions.

## Time and performance

Begin with **one economic tick per simulated day**, not per-frame agent deliberation. Physical movement and finer-grained schedules come later. A future spatial layer may have its own tick rate, but should not determine economic accounting correctness.

LLM calls should occur only at decision points where flexible reasoning adds value. Keep provider selection, token budgets, failure handling, caching, and per-NPC context construction behind a replaceable interface. No API keys in the repository.

## Testing and observability

Use Godot's official headless command-line execution (for example `godot --headless --path . --script res://tests/run_tests.gd`, adjusted for the installed binary and scripts). A minimal custom test runner is acceptable; avoid an elaborate third-party test stack at the start.

Every development task should include:

- How to run or verify the change.
- At least one deterministic test of the new rule.
- A readable simulation summary (e.g. 30-day run) if applicable.
- Specific known limitations or unverified behavior.

Capture event logs and a CSV/JSON summary only when useful. Don't commit large generated run artifacts by default.

## Suggested folder boundaries

```text
project.godot
scripts/
  sim/
    world_state.gd
    simulation_runner.gd
    inventory.gd
    economy.gd
    events.gd
    policies.gd
  tools/
    run_simulation.gd
scenes/                 # later: minimal visual layer
tests/
  run_tests.gd
  ...
docs/
prompts/
AGENTS.md
```

This layout is a guide, not an instruction to create dozens of empty placeholder files. Prefer a small number of cohesive scripts initially.

## Constraints for AI-assisted implementation

- Prefer small changes that can be run and independently inspected.
- Explain assumptions instead of quietly inventing elaborate rules.
- Avoid unrelated refactoring and unnecessary dependencies.
- Report test commands and results truthfully; do not claim execution if the runtime was unavailable.
- Keep code easy to replace rather than tightly coupled to a particular model or UI.
