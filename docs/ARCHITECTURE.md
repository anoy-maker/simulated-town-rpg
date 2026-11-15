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

## M2 separate trading scenario

`trading_runner.gd` extends `simulation_runner.gd` and overrides only the daily routine and report projection. It reuses M0 initial endowments, the private seeded RNG, recipes, and the M1 purchase command. `WorldState` and the original runner are unchanged. The CLI selects the subclass only with `--scenario trading`; the default M0 execution and JSON payload retain their historical hash.

The README defines the fixed prices, payment, quantities, and ordering. This is a scripted economic experiment, with no autonomous buying or generalized employment system. All goods exchanges call `purchase`; the sole direct money transfer is the employer payment. Failed actions remain in history and the day continues without a fallback transaction or new resources.

The inherited report supplies production, consumption, initial/final state, unmet meals, and coarse failure totals. The trading projection adds scenario parameters, purchase counts/volumes/proceeds by item, employer-payment totals, per-NPC cash flow, and failure groups with exact participants/resource/reason/count/day range. Cash flow includes successful exchanges only; `earned = sales + payments_received`, `spent = purchases + payments_sent`. For each NPC, final money must equal initial money + earned − spent. A recipe ID identifies a production failure's resource group; its input requirements remain the existing recipe definition.

The existing ledger auditor reconstructs the trading world without new event types. Tests exercise 30 and 365 days, split-run replay, exact first-day cash flows, report isolation, failure grouping, commodity source/sink reconciliation, per-NPC meal accounting, and a controlled zero-money/zero-food fixture that verifies no rescue occurs. The original M0 JSON hash is pinned in the automated suite as well as checked through the CLI. Full JSON logs remain generated artifacts, not committed data.

## M3 needs, observations, proposals, and authority

`agents_runner.gd` extends the M2 runner and reuses its economic report. It selects an `AgentWorld` subclass for the new scenario, keeps a copied goal configuration, and coordinates decision phases. Existing M0/M2 classes, world commands, initial endowments, prices, recipes, and payment rules are unchanged. The CLI adds `--scenario agents`.

`npc_policy.gd` has no world reference: `decide(observation, goals, phase)` returns only a proposed action and reason. Goals specify food/output targets, a two-batch maximum, and a food-money reservation priority. The policy knows public recipe rules and uses only its own state and advertised offers. Quantities are derived from current deficits, budget, public stock, and whole recipe batches. No global planning or demand forecast is provided.

`AgentWorld.observe()` is the explicit information boundary. It returns a deep copy of the actor's ID, role, money, inventory, day, daily meal need, and public offers. Only each producer's sale commodity is advertised; other account balances, other inventory, and the full ledger are excluded. Changing private facts cannot affect an observation or policy choice. This boundary operates through the input data supplied to trusted GDScript policies.

`AgentWorld.execute_decision()` validates an allowlist for the phase, enforces the public fixed-price seller/item combination, binds purchases to the actual actor, and dispatches existing atomic commands. Harvest quantity comes from the scenario's seeded environment rather than an amount supplied by a proposal. World stock, money, role, recipe, and capacity checks still apply after a proposal is chosen. Waits have no economic command. The existing state is changed only by those validated commands.

The daily meal need is one, reset each day and cleared by a successful consumption event for that actor/day. Observations derive this from the authoritative ledger without a second mutable needs store. The agents executor rejects a duplicate daily meal, eating succeeds only against owned bread, and failed eating counts as an unmet meal. No additional health/debt state is introduced. The fixed phase order is payment → farmer work → miller inputs/work → baker inputs/work → each actor's food choice → each actor's meal choice. Fresh observations precede each choice. One RNG draw occurs per day whether or not harvest is selected, so a harvest on a given day has the same opportunity quantity as M2.

Each `decision` event follows its optional command event and records `phase`, `selected_action`, policy `reason`, `outcome`, `execution_reason`, and `command_event_id`. The envelope's `success` matches execution (wait is successful without a command). Rejected commands and their decision annotations both appear in the raw history. The agents report counts economic rejections once, separately from decision frequencies; waits caused by unavailable/unaffordable resources are decisions, not failed purchases. Wages are fixed scenario transfers and have no decision annotation.

The ledger auditor treats decision records as annotations and independently reconstructs economic state from the original command events. New tests verify each decision/command link and outcome, policy changes under changed circumstances, privacy/nonmutation, stale proposal rejection, fixed parameters, same environmental opportunities, 30/365-day accounting/replay, and all three M0/M2 historical hashes.
