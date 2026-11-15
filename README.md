# Simulated Town RPG

**Status:** M0 complete; M1 atomic purchases implemented and awaiting review

**Working title:** Simulated Town RPG (subject to change)

## The idea

A tile-based fantasy RPG set in a persistent society whose inhabitants have their own needs, work, possessions, relationships, beliefs, plans, and conflicts. The world continues to develop whether or not the player intervenes. Events, quests, and political movements emerge from the simulated world rather than depending on a fixed sequence of authored stories.

Think **Dwarf Fortress-like systemic depth**, **Kingdom Come-like plausibility**, and **Skyrim-like freedom to explore and intervene**—starting at the scale of one small village rather than trying to reproduce any of those games.

Language models may help characters reason through unusual situations, negotiate, communicate, and devise plans. **They are not the source of truth.** A deterministic game simulation owns the facts and decides whether attempted actions succeed.

## Design pillars

1. **A world that exists without the player.** Villagers live, trade, cooperate, quarrel, change careers, and make plans when the player is absent.
2. **Consequences, not performances.** Goods must be transferred, consumed, produced, owned, or lost in the game state. NPCs cannot merely narrate that something occurred.
3. **Autonomy with imperfect knowledge.** A character acts on what they know or believe, not omniscient access to all world data.
4. **Emergent situations over prescribed quests.** Multiple people may have competing goals within one crisis. Player commitments are trackable, but the crisis continues independently.
5. **Player-initiated change.** The player can propose and organize plans, and NPCs can then recruit, negotiate, defect, or act without the player.
6. **Interesting failure is allowed.** Economic collapse and social disorder can be valid outcomes. Arithmetic bugs, duplicated items, and broken invariants are not.
7. **AI is optional, bounded, and replaceable.** Routine behavior can be rule-based. LLM-assisted decisions are added selectively, with configurable cost limits. An AI Director is optional and adjustable, not the controlling consciousness of every NPC.

## What we're building first

The first milestone is deliberately *not* a complete RPG. It is a **headless simulation kernel** in a minimal Godot 4 project:

- Four named NPCs with stable IDs, occupations, money, and inventories.
- Stackable commodities and atomic item/currency transfers.
- A small production chain (for example, wheat → flour → bread).
- Food consumption and explicit resource creation/consumption events.
- A time-step loop, seeded randomness, and a structured event history.
- Automated tests for conservation rules and invalid transactions.
- A report after a short run that can be inspected from Codex on a phone.

We will *not* attempt complex pathfinding, elaborate maps, natural-language dialogue, full NPC social politics, or paid LLM calls in this milestone. A tile-map visualization can follow as soon as the simulation kernel is trustworthy.

## Technology direction

- **Engine:** Godot 4.x, using GDScript for the simulation and eventual game UI.
- **Execution:** Headless runs and tests in a cloud development environment; playable Godot scene later.
- **Source control:** GitHub repository, with small changes and clear checkpoints.
- **LLMs:** Not required for the initial prototype. Future integration via a provider-independent adapter.
- **Data:** Begin with simple serializable structures; decide on long-term persistence once the core data model stabilizes.

This is a working direction, not a commitment to a particular Godot minor release, commercial model, AI provider, or final art style.

## Documents

- [Design principles and feature boundaries](docs/DESIGN.md)
- [Technical architecture and simulation invariants](docs/ARCHITECTURE.md)
- [Incremental roadmap](docs/ROADMAP.md)
- [Codex development instructions](AGENTS.md)
- [First Codex implementation task](prompts/FIRST_CODEX_TASK.md)

## Definition of an honest prototype

A credible early demonstration is **four people who can complete—or fail to complete—a basic economic cycle, where every inventory change and money transfer is accounted for, and the same seed reproduces the same outcome**. A failed economy is acceptable; an unexplainable economy is not.

## Project status

The headless GDScript kernel provides the M0 daily simulation plus an independently callable M1 atomic purchase command, with automated accounting tests. There is no main scene; use the script commands below. Licensing, public release plans, and the final title remain undecided.

## Run M0

Use **Godot 4.6.x** (verified with 4.6.3). No packages, assets, API credentials, or editor import step are required. From the repository root:

```sh
# Automated tests: exit 0 on success, 1 on a failed assertion.
godot --headless --path . --script res://tests/run_tests.gd

# Readable 30-day report, seed 42 (the defaults).
godot --headless --path . --script res://scripts/tools/run_simulation.gd

# Optional positional arguments: days (0..10000), seed, then --json.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- 30 42

# Machine-readable report plus complete event history; compare independent runs.
mkdir -p work
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > work/run-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > work/run-b.json
cmp work/run-a.json work/run-b.json
```

If your binary is named `godot4`, substitute that name. Invalid CLI arguments exit 2. Reproducibility assumes the same Godot version, rules, initial state, seed, and command order; Godot does not promise identical RNG sequences across engine versions.

In a restricted environment where Godot cannot write its normal Linux data/config/cache directories, run this once in the same shell before the commands above:

```sh
mkdir -p work/data work/config work/cache
export XDG_DATA_HOME="$PWD/work/data"
export XDG_CONFIG_HOME="$PWD/work/config"
export XDG_CACHE_HOME="$PWD/work/cache"
```

## M0 structure and assumptions

- `scripts/sim/world_state.gd`: state, integer accounting, validated commands, and structured events. Snapshots/history are deep copies; failed commands change only the event log.
- `scripts/sim/simulation_runner.gd`: seeded daily routine and report aggregation.
- `scripts/tools/run_simulation.gd`: headless CLI and readable/JSON output.
- `tests/run_tests.gd`: conservation, invalid operations, recipes, eating, isolation, event audit, and deterministic replay.
- `tests/purchase_tests.gd`: atomic purchase success/rejection, conservation, arithmetic/capacity boundaries, and replay.

Ada (`farmer`), Bram (`miller`), Cora (`baker`), and Dain (`laborer`) start with 30/20/20/5 coins and one bread each. IDs are independent of display names. Money and stacks are integers bounded to 0..1,000,000,000; commands require positive integer amounts.

Each day, in fixed order:

1. Advance the day and harvest 2–6 wheat using a private seeded RNG.
2. Attempt to give four wheat to the miller; mill twice (each batch: two wheat → two flour).
3. Attempt to give four flour to the baker; bake twice (each batch: two flour → three bread).
4. Attempt to give one bread each to the farmer, miller, and laborer.
5. Attempt a one-coin gift from farmer to laborer, independent of all goods transfers.
6. Each NPC attempts to eat one actual bread. Failed meals count as unmet needs.

Goods and currency gifts are separate operations. The daily routine has no prices, purchases, wages, debt, death, or economic planning. A failed action is logged and the routine continues. Harvest is an explicit source; recipes declare inputs/outputs; eating is an explicit sink. Initial endowments appear in the day-zero initialization event. No currency is minted during a run.

See [actual M0 verification and 30-day results](docs/M0_RESULTS.md).

## M1 atomic purchases

Call `world.purchase(buyer, seller, item, quantity, unit_price)`. For example, when the farmer owns four wheat and the miller can pay 12 coins:

```gdscript
world.purchase("miller", "farmer", "wheat", 4, 3)
```

The command returns `true` only after moving all four wheat to the miller and all 12 coins to the farmer. It checks both participants, distinct IDs, the commodity, positive integer quantity, nonnegative integer unit price, stock, affordability, and destination limits before any writes. A zero unit price is legal. Quantities, unit prices, total prices, and resulting holdings respect the existing one-billion-unit bound; a division check rejects an excessive total before multiplication. Floats (including NaN/infinity), booleans, strings, and null are rejected as quantities/prices.

Each attempt appends one `purchase` event: `actor` is the buyer, `target` the seller, and `details` contains `buyer`, `seller`, `item`, `quantity`, `unit_price`, and `total_price`. Rejections also contain a failure `reason`. `total_price` is null when validation stops before safe total calculation. Rejected purchases leave day, inventories, and balances unchanged.

The existing test command runs all 147 M0 checks plus the purchase tests. The 30-day routine remains unchanged and never calls purchases. See [M1 verification results and exact assumptions](docs/M1_RESULTS.md). Stop after M1 until reviewed.
