# Simulated Town RPG

**Status:** M0/M1/M2 complete; M3 needs and decisions implemented and awaiting review

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

The headless GDScript kernel provides the original M0 simulation, M1 atomic purchases, M2 fixed trading, and a separate M3 agents scenario, with automated accounting tests. There is no main scene; use the script commands below. Licensing, public release plans, and the final title remain undecided.

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

The existing test command runs all 147 M0 checks plus the purchase, trading, and agents tests. The M0 routine remains unchanged and never calls purchases. See [M1 verification results and exact assumptions](docs/M1_RESULTS.md).

## M2: The Trading Village

Select the separate trading scenario explicitly; omitting `--scenario` still runs M0 with the original defaults and JSON format:

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 365 42

# Full reproducible report and ledger (use the writable XDG setup above if needed).
mkdir -p work
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 365 42 --json > work/trading-365.json
```

`--scenario m0` explicitly selects the original scenario. The selector precedes the existing optional day/seed/JSON arguments. Defaults remain 30 days and seed 42; supported day counts remain 0..10000. `scripts/sim/trading_runner.gd` reuses the existing runner's initialization, seeded RNG, world commands, and basic report; `tests/trading_tests.gd` verifies its accounting and replay.

Trading starts with **exactly the same endowments as M0**: Ada/Bram/Cora/Dain have 30/20/20/5 coins and one bread each, with zero wheat/flour. Fixed unit prices are **wheat 1, flour 2, bread 3 coins**. Ada is Dain's employer and attempts a **2-coin daily payment**, using `transfer_money`; this does not create currency. The fixed daily order is:

1. Advance the day; Ada attempts to pay Dain 2 coins, before receiving any sales revenue.
2. Ada harvests 2–6 wheat with the seeded RNG.
3. Bram attempts to buy four wheat from Ada, then mill twice (four wheat → four flour).
4. Cora attempts to buy four flour from Bram, then bake twice (four flour → six bread).
5. Ada, Bram, and Dain, in that order, each attempt to buy one bread from Cora.
6. Ada, Bram, Cora, and Dain each attempt to eat one actual bread. Cora consumes her own production and does not buy from herself.

Every goods exchange uses `world.purchase()`. These are unconditional scripted attempts, even when an NPC still has bread or an earlier operation failed. There are no adaptive purchasing decisions, partial orders, retries, arrears, rescue payments, or rule changes after observing results. A failed payment does not cancel harvest; an unfunded purchase does not create input stock; later production can use only stock already owned. Existing bread may cover a failed purchase until depleted. Unmet meals are recorded without health/death effects.

The trading report includes initial/final holdings, production/consumption totals, successful/rejected purchase counts and volumes per commodity, each NPC's sales/purchase/payment cash flow, unmet meals, and failure groups with participants, resource/recipe, reason, count, and first/last day. `earned` includes sales and employer payments received; `spent` includes purchases and employer payments sent. Rejected attempts contribute no cash or goods flow. These figures are derived from the event ledger.

See [M2 actual results and verification](docs/M2_RESULTS.md), including shortages and financial distress at 30 and 365 days.

## M3: Needs and Decisions

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 365 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 365 42 --json > work/agents-365.json
```

Create `work/` first for redirected output; the same writable XDG setup and day limits apply. The default remains M0, and `--scenario trading` retains the exact M2 report and ledger.

The new scenario separates four concerns:

- **Goals/priorities:** `npc_policy.gd` declares defaults; `Agents.new(seed, initial_entities, goals)` accepts a copied, validated configuration. Food target is one bread, output targets are 4 wheat / 4 flour / 6 bread, and production is capped at two batches per work turn. Non-bakers reserve the cost of missing target food before buying inputs. Cora buys ingredients for her own bread instead of reserving money for a self-purchase.
- **Available information:** `agent_world.gd` projects only the actor's ID, occupation, inventory, money, current day, and daily meal need, plus public seller/item/price/stock offers. All farmer wheat, miller flour, and baker bread are explicitly advertised. Other money, unadvertised inventory, and global event history are excluded. Observations are copies.
- **Proposals:** `npc_policy.gd` is a pure function over observations, goals, and the current phase. It receives no world instance. It proposes `wait`, `purchase`, `harvest`, `produce`, or `consume`, with a reason.
- **Authority:** `agent_world.gd` validates phase/action and fixed market offers, then dispatches to existing world commands using the actual actor. Current funds, stock, roles, recipes, and capacity are revalidated even if the observation was stale. Policies never write state.

The daily schedule retains M2's payment, work-chain, food, and eating order. Ada attempts the same two-coin payment first. One harvest opportunity is drawn per day, even if she waits, keeping M2's day-by-day random environment. Ada then decides whether wheat is below target. Bram and Cora each decide on inputs, then work, using fresh observations. All four choose food actions, then meal actions. There are 13 decision opportunities per day; the employer payment remains a fixed scenario rule.

Food purchases fill only the target shortfall, limited by cash and advertised stock. Production targets determine required batches and inputs; actual input stock limits work. Existing inputs/output prevent redundant purchases or work. Whole harvests/recipe batches can overshoot a target; subsequent turns wait until stock falls below it. A villager still attempts one actual-stock consumption for the daily meal, even when food is unavailable, so unmet meals remain explicit. Successful consumption records clear that day's need, and the agents executor rejects a duplicate meal. Needs reset to one meal each day without health effects or accumulated hunger debt.

Every choice appends a `decision` event with actor, phase, selected action, policy reason, outcome (`executed`, `rejected`, or `wait`), execution failure reason, and the underlying command event ID where present. Decision records do not move money or goods. Reports add goal settings and decision frequencies by actor/action/reason and outcome; economic failures exclude the duplicate decision annotation.

Prices, initial endowments, recipes, wage amount/timing, and the seed remain M2's. Goals and policies were fixed before examining economic results. See [M3 actual results and comparison with M2](docs/M3_RESULTS.md). Stop after M3; no later milestone has started.
