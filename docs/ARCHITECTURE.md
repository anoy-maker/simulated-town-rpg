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

## Implemented M0 boundaries

The first implementation intentionally combines commands, validation, and event recording in `scripts/sim/world_state.gd`. `simulation_runner.gd` holds the daily policy, seeded RNG, and report projection. There is no separate inventory framework or scene dependency.

`WorldState` owns its dictionaries and event array. Initialization copies trusted, developer-supplied entity data and asserts its shape. Callers use validated commands; `snapshot()` and `events()` return deep copies. GDScript's underscore naming is a convention, not a security boundary. Untrusted save-file loading is outside M0.

All command arguments representing quantities must be positive integers; stocks and money are bounded to one billion. Each command checks all preconditions, including recipient/output limits, before any mutation. A failed command returns `false`, preserves day/entities, and appends a failure event with a reason. Money uses integer coins, without float arithmetic. Recipes are fixed and role-specific. `advance_day()` records the day transition.

Events contain `id`, `day`, `action`, `actor`, `target`, `success`, and `details`. Details identify exact item/currency amounts, production inputs/outputs, or a failure reason. The initialization event includes the initial state. The tests independently reconstruct the final world from events, check money and nonnegative inventories at every event, and reconcile commodity sources/sinks against the report.

The daily policy uses an explicit NPC order and one private `RandomNumberGenerator`, seeded once. Running 12 days then 18 days has the same result as running 30 days. JSON output sorts dictionary keys; no wall-clock timestamps or engine object IDs enter the history. Reproduction is verified on Godot 4.6.3; engine-version-independent RNG and persistence/resume are deferred.

The CLI prints a compact report by default, or a complete JSON report/history with `--json`. History remains in memory and report retrieval copies it; the CLI bounds runs to 10,000 days. This is intended for small diagnostic runs, not an unbounded world server. There is no graphical main scene in M0.

## M1 atomic purchase command

`WorldState.purchase(buyer, seller, item, quantity, unit_price)` validates and commits one synchronous exchange. IDs and commodity names use the existing String API; quantities/prices accept Variant arguments so invalid numeric types can be rejected and logged without coercion. Quantities must be integers in 1..MAX_AMOUNT; unit prices must be integers in 0..MAX_AMOUNT. Buyer and seller must differ.

The command checks total price using integer `MAX_AMOUNT / quantity` before multiplication, then checks seller stock, buyer funds, buyer inventory capacity, and seller money capacity. Total price must fit MAX_AMOUNT. Capacity checks subtract from the bound before comparing. No state is written until every check succeeds; then goods move seller → buyer and money moves buyer → seller. It does not call the separate transfer commands, which would permit intermediate state and multiple events.

One event records the exchange using the existing envelope: `action="purchase"`, `actor=buyer`, `target=seller`, `success`, and `details`. Details record both named participants, commodity, quantity, unit price, and total price. `total_price` remains null if earlier validation fails or the total exceeds the bound; the original operands remain available. A rejection changes only the event log.

Participant/quantity errors reuse `unknown_actor` (buyer), `unknown_target` (seller), `same_entity`, and `invalid_amount` (quantity). Other reasons are `unknown_item`, `invalid_unit_price`, `total_price_limit`, `insufficient_stock`, `insufficient_money`, `buyer_inventory_limit`, and `seller_money_limit`. Validation returns the first applicable reason in documented command order.

The ledger auditor applies successful purchases as both item and money movements, ignores rejected attempts, and rejects unknown successful action types. It derives conserved money from each fixture's initial state, permitting boundary fixtures while preserving the existing 75-coin M0 audit. Purchase tests also check commodity conservation, exact events, rejection immutability, and deterministic replay interleaved with seeded ticks. The daily simulation and CLI are unchanged.
