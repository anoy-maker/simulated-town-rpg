# Simulated Town RPG

**Status:** M0–M7 complete; M8 combined economic candidate implemented and awaiting review

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

The headless GDScript kernel provides M0, atomic purchases, fixed trading, needs-based agents, commercial coordination, and a separate planning experiment, with automated accounting tests. There is no main scene; use the script commands below. Licensing, public release plans, and the final title remain undecided.

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

Prices, initial endowments, recipes, wage amount/timing, and the seed remain M2's. Goals and policies were fixed before examining economic results. See [M3 actual results and comparison with M2](docs/M3_RESULTS.md).

## M4: Commercial Requests and Commitments

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 365 42
mkdir -p work
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 365 42 --json > work/coordination-365.json
```

All M0/M2/M3 commands and historical outputs are preserved. The same initial resources, prices, recipes, goals, two-coin employer payment, and daily harvest opportunities apply.

`coordination_world.gd` adds `post_request(buyer, item, quantity)`, `accept_request(supplier, request_id)`, `fulfill_request(supplier, request_id)`, and `close_request(buyer, request_id, reason)`. An open request states quantity and payment at the existing fixed unit price. It becomes a prepaid agreement when the eligible producer voluntarily accepts: payment transfers once using the existing money operation. Delivery uses an actual item transfer, all at once, without another payment. A failed delivery leaves the obligation and prepayment intact. Only the buyer can explicitly close an unfinished request; closing a paid agreement waives the claim without a refund. Policies do not automatically close requests.

There is at most one active request per buyer/commodity and one accepted agreement per supplier/commodity. Terms are immutable. Stable IDs and full records remain in `snapshot().requests` with status `open`, `accepted`, `fulfilled`, or `closed` and linked payment/delivery event IDs. Unfulfilled accepted agreements generate an end-of-day `agreement_outstanding` event, preserving split-run replay. Closed/fulfilled records remain in history.

`coordination_policy.gd` remains a pure function. It can see its own active requests/obligations and eligible public open requests, in addition to M3's permitted self state and public offers. Other balances and private stock remain inaccessible. Buyers request missing inputs (or needed food) only when spot stock is unavailable and they can fund a request. Suppliers consider their own stock, one-turn production capacity, public input prices, payment coverage of missing-input costs, and existing obligations. They can decline. Buyers awaiting supply avoid redundant spot purchases.

An accepted supply obligation takes priority over the supplier's normal output target and food-money reservation during the input/work turn. Funds and goods remain spendable; they are not escrowed or reserved between turns. This limited new priority supports voluntary production but does not guarantee fulfillment.

Daily order: unchanged wage payment and RNG draw; then Ada's work/delivery, Bram's inputs/work/delivery, Cora's inputs/work/delivery; request decisions by Ada/Bram/Cora/Dain; acceptance decisions by those four; food decisions; meals; outstanding-agreement events. Delivery follows each producer's work so downstream NPCs can use received inputs in their own turn. Acceptance occurs after work, making its prepayment usable in the next work turn and immediately in ordinary transactions. There are 24 decision opportunities per day. The runner offers turns and executes proposals; it never orders a particular NPC to fund another.

Reports distinguish spot purchases, delivered agreement quantities, prepayments, employer payments, cash flow, open/fulfilled/outstanding/waived agreements, lifecycle rejections, and decision frequencies. A prepayment is counted once as money spent/earned; fulfillment adds goods without another money movement. Outstanding payment totals describe paid claims, not a balance held in escrow.

See [M4 actual results and comparison with M3](docs/M4_RESULTS.md), including the agreement that remains unfulfilled. The economy was not tuned after observing outcomes.

## M5: Commitment-Aware Planning

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority commitment-first 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority immediate-needs-first 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority commitment-first 365 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority immediate-needs-first 365 42
```

The optional `--priority` follows `--scenario planning`, before day/seed arguments; it defaults to `commitment-first`. Add `--json` after day/seed for the complete report and ledger. Other scenarios reject `--priority`. The selected priority applies to the whole village for this comparison. All historical scenarios retain their commands and output.

`planning_policy.gd` computes the same working-capital estimate for both priorities from the supplier's owned stock, accepted obligation, public recipe, and advertised input prices. Missing output determines whole batches; owned inputs reduce missing purchases. Owned deliverable stock needs no further capital. Farmer harvest requires no purchased inputs. Unavailable ingredients, insufficient cash, and pending deliveries remain real constraints.

- **Commitment-first:** accepted-obligation inputs may use current cash; discretionary food or unrelated advance spending uses only cash left after the known missing-input cost.
- **Immediate-needs-first:** missing current target food is budgeted first; accepted-obligation input spending uses cash left after that food cost. Food purchases can consume funds needed for an agreement.

Both modes share the same exact-quantity ingredient acquisition and commitment production/delivery logic. They can buy only affordable available units, work only with real inputs, and fulfill only with actual output. Neither invents extra resources or accesses other NPCs' money. With no supplier obligation, both use the existing M4 policy. Accepted supply, current observations, phase order, recipes, prices, wage rules, and starting resources are identical.

The budget is recalculated at every decision. It creates no account, escrow, lock, or authoritative balance. The unchanged M4 world validates all purchases/transfers/production. Existing `decision` events record explanatory `selected_action.planning` metadata (known cost, cash, missing inputs, availability, status, priority, and spending budgets) alongside reasons such as `spend_immediate_needs`, `reserve_obligation_capital`, `acquire_obligation_inputs`, `unable_to_satisfy_obligation`, and `fulfill_obligation`. Execution success/rejection still comes from the world.

`planning_runner.gd` inherits the M4 scheduler/authority/report and adds priority, current end-of-run cost estimates, and activity counts after historical day 26. Its `last_*_day` fields describe the latest activity over the entire run. Planning controls spending on accepted obligations, without general forecasting or goods reservation. Incoming promises are not counted as owned ingredients; the cost estimate conservatively includes missing goods even while prepaid supply is awaited. Food budgets may remain held when food is unavailable or unaffordable, so either strategy can stall.

See [M5 actual comparisons, focused failure test, seeds, and limitations](docs/M5_RESULTS.md). These policies and outputs remain regression baselines.

## M6: Competing Producers and Multiple Market Participants

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market 365 42
# Repeat both horizons with seeds 7 and 99; fixed commitment-first spending.
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario market 365 7 --json > work/market-365-7.json
```

Create `work/` before redirection and use the writable XDG setup above if needed. Default CLI behavior remains M0; all prior scenario outputs remain unchanged. `--priority` remains an M5 option; market uses commitment-first throughout.

Market adds Edda (`farmer_2`, farmer, 30 coins) and Finn (`baker_2`, baker, 20 coins), each with one bread and zero wheat/flour. Ada/Bram/Cora/Dain retain their original endowments. Total starting resources are 125 coins and six bread. Prices, recipes, goals, and Ada's two-coin employer payment remain unchanged. These conditions were fixed before examining results.

The public board advertises every producer's output commodity, price, and current stock, including zero stock. A pure policy chooses among positive-stock sellers by lower price, greater stock, then ascending stable seller ID. Producers retain M5's own-output rule for their own needs. No seller cash or unadvertised inventory is disclosed. Selected offers and candidates are recorded with purchase decisions; the world revalidates the actual seller, fixed price, money, and stock through the existing atomic purchase command. There is one supplier choice per action slot, without retries, split orders, or reservations.

Daily order is Ada → Edda → Bram → Cora → Finn → Dain, derived from production-chain occupation order and ascending ID. After Ada's attempted wage payment, each producer chooses inputs (except farmers), work, then delivery. Farmers each receive one seeded 2–6 wheat opportunity, even when waiting. All six then choose requests, acceptance, food, and meals, followed by outstanding-agreement annotations: 37 decisions/day. Earlier actors can exhaust real stock; later actors see fresh observations. Requests are untargeted and public to all eligible producers; the first valid voluntary acceptance wins. Both farmers and both bakers use common occupation and commitment-aware rules.

Reports add per-NPC production, consumption, unmet meals, successful/failed purchases and sales, quantities bought/sold, supplier selections, and accepted/fulfilled/outstanding supplier commitments. Existing inventory, cash-flow, request records, lifecycle receipts, shortages, decision frequencies, and day-26 activity reports remain available. Counts of selections include attempted purchases; successful quantities and cash exclude rejections.

See [M6 actual results, all six experiments, regression hashes, and limitations](docs/M6_RESULTS.md). Population, initial resources, harvest draws, and scheduling differ from M5, so aggregate comparisons do not establish a causal improvement. M6 remains an unchanged regression baseline.

## M6B: Revised Downstream Market Experiment

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market_downstream 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market_downstream 365 42
# Repeat both horizons with seeds 7 and 99; add --json for the complete report/ledger.
```

This separate configuration has **Ada as the only farmer, Bram and Edda as millers, Cora and Finn as bakers, and Dain as laborer**. Original holdings are unchanged. Edda (`miller_2`) receives Bram's 20 coins and one bread; Finn (`baker_2`) receives Cora's 20 coins and one bread. Ingredients start at zero. Initial money is **115 coins**, with six bread. The original `market` still has two farmers, one miller, and 125 coins.

`market_downstream_runner.gd` supplies only the initial entity array and scenario label. Existing market scheduling, reporting, public offers, world authority, and common occupation/commitment-first policies are inherited unchanged. No separate miller/baker policies or copied economic runner are introduced. Prices, recipes, output/food targets, and Ada's wage obligation remain unchanged.

Occupation/ID order is Ada → Bram → Edda → Cora → Finn → Dain. There are 38 decisions/day and one seeded harvest opportunity/day, including waits. Both millers independently purchase wheat, produce and advertise flour, and consider public requests. Both bakers independently select flour suppliers and produce/sell bread. Supplier selection remains price, stock, then ID. The four-wheat farmer target is an inventory trigger: sales below four can cause another harvest on the next work turn; extra downstream producers alone do not change the target or grant another daily harvest. Existing voluntarily accepted supply obligations can raise the effective target.

All existing commands and historical outputs remain preserved. See [actual M6B results, farmer-response analysis, supplier choices, and limitations](docs/M6B_RESULTS.md). Comparisons across M5/M6/M6B change money supply, capacity, roles, or scheduling and do not establish causal improvements. M6B remains an unchanged regression baseline.

## M7: Economic Foundations and Calibration Laboratory

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario calibration --experiment baseline 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario calibration --experiment lower_food_price 365 42
# Complete fixed matrix, independent replay, ledger audit, JSON captures and CSV tables:
python3 scripts/tools/run_calibration.py --output work/m7
```

Use the same writable XDG setup for direct Godot commands. The Python batch tool needs only the standard library and Godot, configures its own writable data/cache directories, and runs all six presets × seeds 7/42/99 × horizons 30/365 twice. `--experiment` follows `--scenario calibration`; it defaults to `baseline`. Other scenarios reject that option. Calibration uses the unchanged commitment-first policies and M6B population/schedule.

Presets are `baseline`, `higher_productivity` (+2 to the same seeded harvest draw), `higher_target` (farmer target 8), `lower_food_price` (bread 2), `higher_wage` (payment 3), and `extra_liquidity` (+10 coins per NPC at initialization, total 175). Every intervention changes only its declared economic variable. Baseline retains M6B's exact economic ledger and inherited report fields.

`Calibration.new(seed, configuration)` also accepts a copied, validated dictionary containing only harvest bonus, farmer target, fixed commodity prices, daily payment, and six initial balances. Prices/targets/payments are positive bounded integers; balances may be zero; the additive harvest bonus is nonnegative and bounded so the largest opportunity fits the kernel limit. Zero prices are excluded here because the unchanged policies divide by public prices; M1's underlying zero-price purchase API is preserved. Fixed instance prices govern public offers, decision validation, and agreement terms together. No runtime price changes or money injections are introduced.

The report adds the configuration, matched underlying opportunities, physical food/meal bounds, per-NPC affordability/owned-food snapshots, production/business inactivity, underfunding flags, total cash circulation, and wealth concentration. These are post-run diagnostics; NPCs receive only their existing permitted observations. Existing recipes, policies, agreements, and integer inventory/money commands remain authoritative.

See [M7 feasibility calculations, matched results, and limitations](docs/M7_RESULTS.md), [all 36 run summaries](docs/M7_RUNS.csv), and [all 216 NPC results](docs/M7_NPCS.csv). No preset or policy was tuned after results. These presets, results, and default economics remain unchanged.

## M8: Candidate Viable Economic Baseline

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario calibration --experiment combined_candidate 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario calibration --experiment combined_candidate 365 42
# Reuse the full M7 JSON captures produced by the M7 batch command:
python3 scripts/tools/run_calibration.py --study m8 --reuse work/m7 --output work/m8
```

The optional `combined_candidate` uses bread price 2 and harvest opportunities 4–8, keeping all other M6B/M7 conditions fixed, including 115 starting coins, wage 2, farmer target 4, and commitment-first. It uses the existing calibration runner and policies. No default parameters change. The default M7 batch still runs only its original six presets.

The M8 study compares baseline, affordable bread, higher productivity, and the combined candidate for seeds 7/42/99 at 30/365 days. With `--reuse`, existing M7 comparison files must match the committed hashes and pass the existing ledger audit; only the six combined cases are newly simulated, each twice. Without cached captures, omit `--reuse` to reproduce all four cases. Separate output directories protect the M7 artifacts.

M8 also exports `food_losses.csv`: event-linked incidents where an NPC owned bread at food-planning time, sold it afterward, and then failed to eat that day. This is a post-run observation, not a food reservation or policy change. Other post-planning bread transfers are excluded to avoid mixed-cause attribution. Run its six focused tests with `python3 -B -m unittest discover -s tests -p 'test_calibration_observations.py'`.

See [M8 actual results and provisional-baseline assessment](docs/M8_RESULTS.md), [24 comparison summaries](docs/M8_RUNS.csv), [144 NPC outcomes](docs/M8_NPCS.csv), and [food-loss event links](docs/M8_FOOD_LOSSES.csv). Better aggregate meals alone do not establish viability or resilience. The candidate awaits review and has not been adopted. Stop after M8; M9 has not started.
