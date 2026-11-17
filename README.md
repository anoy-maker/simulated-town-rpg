# Simulated Town RPG

**Status:** M0–M25 complete; M26 seller-local demand experiment for review; GDScript remains the default

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

The headless GDScript kernel provides separate scenarios for the original economic loop, purchases, needs and planning, commercial coordination, competing markets, calibration, workplace labor, and ownership income, with automated accounting tests. There is no main scene; use the script commands below. Licensing, public release plans, and the final title remain undecided.

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

See [M8 actual results and provisional-baseline assessment](docs/M8_RESULTS.md), [24 comparison summaries](docs/M8_RUNS.csv), [144 NPC outcomes](docs/M8_NPCS.csv), and [food-loss event links](docs/M8_FOOD_LOSSES.csv). Better aggregate meals alone do not establish viability or resilience. The candidate has not been adopted; M8 results remain a historical baseline.

## M9: Workplaces, Labor, and Employment

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_labor 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_labor 365 42
python3 -B scripts/tools/run_labor.py --output work/m9
python3 -B -m unittest discover -s tests -p 'test_*.py'
```

This separate experiment has twelve residents, three solely owned businesses, nine employee records, and 432 initial coins. A business owns its stock and operating cash in a separate account. Occupations and skills are separate from ownership and employment. All residents have one full shift/day; owners can work but have the same labor, skill, input, and compensation constraints as employees. Fixed prices are wheat 1 / flour 2 / bread 3; a funded shift pays 3 coins. The [predeclared configuration and feasibility calculation](docs/M9_RESULTS.md) specify initial capital, inputs, productive assets, workforce allocation, targets, and ordering before experiments.

Owners buy inputs and propose shifts using only their own firm's resources and authorized worker availability. Workers accept eligible paid work and independently buy food using personal holdings. Every shift is revalidated before wages and production commit together, using existing money/recipe receipts. Unfunded or resource-limited shifts perform no labor and create no debt. Offers do not reserve money, stock, or labor; daily limits also apply across businesses. No household can eat business inventory directly. The output-target policy can leave hired workers without shifts; employment does not guarantee daily earnings or meals.

The standard Godot suite includes workplace/payroll/authority/privacy/replay tests. The batch runs 30/365 days for seeds 7/42/99 twice, independently reconstructs complete state and unique work/payroll/production links, and saves JSON captures plus run/resident/business CSV tables. Full histories stay in the output directory. Historical worlds, policies, prices, defaults, and M0–M8 results remain unchanged.

Actual runs stop economic activity by day 13–15: household cash runs out while firms retain all 432 coins and 19–20 bread. Output targets prevent further shifts/payroll despite available operating funds. See [M9 results and limitations](docs/M9_RESULTS.md), [six run summaries](docs/M9_RUNS.csv), [resident results](docs/M9_RESIDENTS.csv), and [business results](docs/M9_BUSINESSES.csv). No configuration was adjusted to rescue this outcome. These results remain the unchanged labor baseline.

## M10: Business Income and Capital Circulation

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_finance --distribution needs 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_finance --distribution needs 365 42
# Same conditions, unchanged control or more conservative payout fraction:
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_finance --distribution none 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_finance --distribution half-surplus 365 42
python3 -B scripts/tools/run_labor.py --study m10 --baseline work/m9 --output work/m10
```

The separate `settlement_finance` scenario keeps every M9 endowment, labor/production rule, wage, price, inventory target, and market rule. Its optional withdrawal phase follows work and precedes household food purchases. Owners independently propose cash transfers from their own business to cover a two-meal personal stock/cash goal. `needs` caps payment by all cash above reserve; `half-surplus` additionally caps it at half that surplus rounded down. `none` skips the phase and preserves the exact M9 ledger. The finance scenario defaults to `needs` when selected; the project default remains M0.

The world enforces a two-day full-capacity operating buffer: farm **24**, mill **56**, bakery **88** coins. These funds remain available for actual payroll/input spending. Withdrawals cannot breach the buffer, invent money, access unrelated accounts, or exceed the owner's money limit. Ownership income has a distinct event and cash-flow category, separate from wages, and does not require a work shift. This measures distributable **cash**, not formal inventory-valued profit; even initial capital above reserve can be withdrawn. No loans, capital refills, guaranteed work, or employee subsidies are added.

The fixed study runs all three policies at 30/365 days, seeds 7/42/99, twice. Cached M9 comparisons must match published hashes and pass the shared audit; omit `--baseline` to reproduce them instead. Separate directories protect original captures. The audit reconciles each withdrawal with ownership and the actual cash reserve, as well as the original labor/production receipts. Tests cover authority, reserves, atomic failures, privacy, income classification, controls and replay. See [M10 actual results, assumptions and limitations](docs/M10_RESULTS.md). No policy or parameter is tuned after outcomes; these remain historical comparison results.

Actual payout runs sustain trade through day 365 and provide 812–813 annual meals versus M9's 77–82, but only Cora eats daily; most employees remain excluded. All 432 coins are conserved and every withdrawal preserves its reserve. See [18 run summaries](docs/M10_RUNS.csv), [216 resident records](docs/M10_RESIDENTS.csv), and [54 business records](docs/M10_BUSINESSES.csv). Technical validity and increased circulation do not establish economic viability.

## M11: Deterministic Economic Equilibrium Reference

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 2 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 365 42
# Compact machine-readable report and complete ledger fingerprint, without events:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 365 42 --report-json
```

This is an **intentionally prescribed feasibility reference, not autonomous economic stability**. It retains M9's twelve residents and ownership/employment relationships, starts each resident with six coins and no food, and starts each firm with 120 coins and no commodities. Only here, prices are wheat 2 / flour 4 / bread 4, wages are eight, and a completed farming shift yields four wheat deterministically. The original two-batch recipes remain authoritative. Two worker pairs per firm alternate on odd/even days; daily output is eight wheat, eight flour and twelve bread, purchased and consumed through existing transactions.

The 1/2/30/365-day cases verify every event's 432-coin conservation and nonnegative holdings, every day's production/meals, the daily 120-coin business state, and the two-day household cycle. The year produces/consumes **4380 bread**, completes **2190 paid shifts**, and misses **zero meals**. Households return to six coins on even days; odd days leave six with ten and six with two. This depends on the exact prices, wages, initial buffers, prescribed rotation/order and guaranteed harvest opportunity; no autonomous policy discovers it.

Default output is eight concise lines. `--report-json` supports the M11 reference and M12 employer-choice scenarios; it includes a SHA-256 of the full canonical ledger without printing that ledger. The existing `--json` diagnostic remains available for short audits, but full-year event dumps are unnecessary. Tests audit annual receipts in memory and reuse the independent Python labor auditor on a short two-day trace. Historical scenarios and the default M0 CLI remain unchanged. See [M11 results and limitations](docs/M11_RESULTS.md). This prescribed control remains unchanged.


## M12: Employer-Driven Production and Labor Scheduling

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_employer_choice 2 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_employer_choice 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_employer_choice 365 42
# Compact annual report plus full ledger fingerprint, without events:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_employer_choice 365 42 --report-json
# All six M11/M12 comparisons, twice per case; compact summaries and CSV tables only:
python3 -B scripts/tools/run_employer.py --output work/m12
```

This isolated scenario retains every M11 initial resource, price, wage, recipe, productive asset and employment relationship. Owners forecast their own next sales from the immediately preceding day's realized sales, starting once with 8 wheat / 8 flour / 12 bread on day one. They subtract unsold stock, round to whole shifts, and jointly budget real inputs and wages. Selected labor goes to the owner first, then eligible employees in stable ID order. Contracts remain active without guaranteed hours or fair rotation. Management creates no wage; all income requires actual paid production.

Pure policies see only authorized own-firm/household information, own prior-day trade aggregates and public offers. The world validates plans through existing purchases, shift offers, worker acceptance, payroll and recipes. Structured plans record demand, stock offsets, budgets, selections/skips, reasons and actual receipt links. Existing household food decisions and industry ordering remain unchanged. Neither forecasts nor staffing guarantee full employment or twelve daily bread.

At 2/30/365 days M12 consumes **18/117/1122 meals** and misses **6/243/3258**, versus M11's **24/360/4380 meals** with zero misses. Annual paid shifts fall to 563; nine employees receive only nine shifts combined while all three owners eat daily. First misses are on day two, with six bread unsold because six residents cannot afford it. Currency stays 432 and trade continues, but this is not universal economic viability. No policy or parameter is tuned to repair the outcome.

See [M12 actual results, causal trace and limitations](docs/M12_RESULTS.md), [six run summaries](docs/M12_RUNS.csv), [resident results](docs/M12_RESIDENTS.csv), and [business results](docs/M12_BUSINESSES.csv). Historical scenarios/default CLI remain unchanged. This employer-choice experiment remains an unchanged control for M13.


## M13: Employment Allocation versus Production Forecasting

```sh
# M13-A: prescribed NEW daily production, owner-first staffing (no stock offset).
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_fixed_owner_first 365 42
# M13-B: unchanged sales forecasting, exclusive M11 alternating worker pairs.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_sales_rotating 365 42
# All four conditions at 2/7/30/365 days, twice each; compact summaries/tables only:
python3 -B scripts/tools/run_causality.py --output work/m13
# Observation-only diagnostics, plus original summary and complete-ledger hashes:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_fixed_owner_first 30 42 --study-json
```

The controlled 2×2 study keeps all M11 resources, prices, wages, skills, assets, jobs, recipes, authority and transaction ordering. M11/M12 remain unchanged controls. A always attempts 8 wheat / 8 flour / 12 new bread per day, reducing shifts only when real resources, funds or eligible capacity limit production. B uses the original one-time startup/previous-day-sales/stock-offset calculation, considering only that day's designated pair and only as much labor as needed. Both reuse M12's budgeting and world execution; no full runner or economic engine is duplicated. No policy gains private household information.

Annual results: M11 and B each consume **4380 meals**, with **2190 paid shifts** and zero misses; their complete successful economic movement fingerprints match. A consumes **1182 meals**, with 631 shifts and 3198 misses; M12 consumes 1122, with 563 shifts and 3258 misses. Staffing causes the initial day-two exclusion while bread is available. Continued fixed production accumulates stock and becomes cash constrained on day six; forecasting preserves capital but further reduces employee income. These are matched findings for the specified rules, not proof about all employers or economies.

`--report-json` supports all four study scenarios while preserving control bytes. `--study-json` adds a separate post-run observer with food-access/stock/financial-constraint diagnostics, plan counts/selections and a short initial trace. It never enters NPC observations. Reports stay compact and do not export annual ledgers. All currency remains 432; no policy was tuned after outcomes. See [M13 setup, causal analysis, verification and limits](docs/M13_RESULTS.md), [run table](docs/M13_RUNS.csv), [resident table](docs/M13_RESIDENTS.csv), and [business table](docs/M13_BUSINESSES.csv). The M13 results remain an unchanged historical comparison.


## M14: Profitable Ownership and Contractual Employment Reference

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 2 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 3 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 365 42
python3 -B scripts/tools/run_profitable.py --output work/m14
# Compact annual report, verification flags and complete-ledger fingerprint:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_profitable_reference 365 42 --report-json
```

This isolated prescribed reference retains M11's twelve residents, ownership, skills, assets, 432 starting coins, empty inventories, 2/4/4 prices and paid production recipes. The three owners manage without productive shifts or wages. Nine employees earn six coins per completed shift, working two shifts per three-day cycle under the exact fixed rotation. Required work is attempted regardless of sales or unsold stock; real stock, wages, eligibility and capacity still constrain execution. Explicit due/attempt/outcome records distinguish fulfilled work, constrained breaches and failure to schedule, without debt, substitutions or catch-up shifts.

After household buying and consumption, actual owners receive all eligible realized operating cash above the original 120-coin capital floor. Cumulative sales minus input spending, payroll and prior distributions must support every payment. Unsold goods and initial capital create no income. A linked native transfer moves existing coins; ownership income is reported separately from wages. This is restricted cash-surplus accounting, not inventory-valued accrual profit or M10's discretionary capital withdrawal policy.

All requested horizons reproduce the reference. The year has **4380 meals, 2190 employee shifts, 13140 wage coins, 4380 owner-distribution coins, zero missed meals and zero breaches**. Owners receive 1460 each without working; each firm closes daily at 120 with no inventory. Household balances repeat every three days. Every event conserves 432 coins. These prescribed results demonstrate feasibility under fixed assumptions, not autonomous stability or shock resilience.

See [M14 actual results, accounting, synthetic failures and limitations](docs/M14_RESULTS.md), [five run rows](docs/M14_RUNS.csv), [resident outcomes](docs/M14_RESIDENTS.csv) and [business outcomes](docs/M14_BUSINESSES.csv). This remains an unchanged historical reference.


## M15: Open Economy and Business Formation

```sh
# A: finite external funds, all nine employees working daily, genuine owner income.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_external_trade_reference 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_external_trade_reference 3 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_external_trade_reference 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_external_trade_reference 365 42
# B/C: separate prescribed fixtures, not full village simulations (fixed horizon/seed).
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario enterprise_startup_fixture 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario enterprise_delegation_fixture 2 42
# All six cases twice; compact reports, accounting tables and finite asset records:
python3 -B scripts/tools/run_enterprise.py --output work/m15
# Annual report and canonical ledger hash; no verbose event export:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_external_trade_reference 365 42 --report-json
```

A retains M14's twelve residents, businesses, endowments, prices, recipes, workplace capacity and minimum contracts. Nine employees perform paid work daily; the third shift per three-day cycle is additional work. Visitors buy six real loaves daily from a finite 8760-coin external account. Its money belongs to the combined ledger, outside the village boundary; its consumed bread creates no household meal requirement. At day 365 the village holds **9192 coins**, visitors hold **zero**, each resident holds **736**, and each firm retains **120**. Actual receipts yield **4380 resident meals, 2190 visitor loaves, 3285 paid shifts**, and zero misses/breaches. A separate exhaustion test preserves rejected purchases and subsequent hardship without refilling the purse.

B/C explicitly endow Finn with 500 coins, legitimate finite asset sellers, twelve flour at the original mill and one finite customer purse. Finn contributes 300, buys an oven/workshop for 180/60, and retains 200 personal/60 business coins. The new firm receives no free inventory, equipment, workers or sales. After authorized resignation and a self-employment transition, his real unpaid baking shift and specified sales leave **68 cash/eight operating earnings**. A public job posting, employer offer, Iona's acceptance and an actual boundary transition delegate the next shift to Iona for six coins, leaving **70 cash/ten cumulative earnings**. Finn retains ownership without a productive affiliation. Unsold goods, missing assets, conflicting work and unfulfilled old obligations remain real.

Contributions, durable asset purchases, operating flows, unpaid owner labor and distributions are separately auditable. New firms default to retaining earnings with an explicit 24-coin reserve; optional half/full policies require genuine realized remaining earnings and liquidity. Contributions never become profit. The local board exposes terms rather than private business accounts. These prescribed fixtures test infrastructure, not autonomous business development or guaranteed demand. See [M15 results and limitations](docs/M15_RESULTS.md), [run fingerprints](docs/M15_RUNS.csv), [all account outcomes](docs/M15_ACCOUNTS.csv) and [fixture assets](docs/M15_ASSETS.csv). M15 remains an unchanged historical reference.


## M16: Dynamic Pricing and Rational Market Competition

```sh
# A fixed; B bakery adaptive; C mill/bakery adaptive; D entire chain adaptive.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage A 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage B 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage C 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage D 30 42
# Two finite bakery stocks, independently priced at three/five coins (fixed 1 day/seed 42):
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario pricing_competition_fixture 1 42
# Twelve preflight/30-day runs twice, independent receipt audits and compact CSV/JSON:
python3 -B scripts/tools/run_pricing.py --output work/m16
```

All commodity purchases in M16 bind an authorized seller-specific, versioned public quote and revalidate real stock/funds. Owners can post different positive integer wheat/flour/bread prices, at most once per item/day. Quotes expose offered availability, not private business accounts. Buyers satisfy only their actual requirement, choose affordable cheapest offers with a deterministic day/buyer rotation for equal prices, and reconsider legitimate alternatives after stale/stock failures. Visitors retain finite funds and a private six-coin bread ceiling. Historical purchases and default M0 behavior remain unchanged.

The separate pure pricing policy considers current−1/current/current+1 under a declared linear demand belief, choosing maximum estimated one-period operating cash with fixed production/payroll. It sees own prior transactions, resources and public offers; no customer finances, private visitor ceiling or future arrivals. All stages retain M15's exact production, labor, endowments and distribution treatment. `fixed` is the control, `rational_pricing` uses the stated belief, and `personality` is a reserved, unimplemented interface. The world executes all monetary, goods and labor operations.

Actual 30-day resident meals/misses are **A 360/0, B 257/103, C 210/150, D 102/258**; contractual breaches are **0/2/41/116**. Accounting and decision-objective audits pass, but the adaptive treatments reduce food access under these particular beliefs and fixed commitments. D eventually posts one-coin prices yet loses productive working capital; no meals occur after day fourteen. No resources, demand or prices were adjusted to repair outcomes. The competition fixture and tests show real order-dependent allocation rather than assigned customers. These mechanisms do not establish autonomous stability or globally optimal pricing.

`--report-json` includes daily business/household results and complete ledger fingerprints without verbose events; `--json` supports short trace inspection. See [M16 choices, actual results and limitations](docs/M16_RESULTS.md), [run fingerprints](docs/M16_RUNS.csv), [daily business results](docs/M16_BUSINESS_DAYS.csv), [village days](docs/M16_DAYS.csv) and [all final account outcomes](docs/M16_ACCOUNTS.csv). M16 remains an unchanged historical experiment.


## M17: Headless Spatial Town and Scheduling

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 3 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 30 42
# Isolated one-day disruptions, seed 42; only the declared spatial parameter changes:
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial --spatial-case late_worker 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial --spatial-case early_close 1 42
# Repeat/audit all five experiments; compact reports and small CSVs:
python3 -B scripts/tools/run_spatial.py --output work/m17
# Optional short event trace; use --report-json for compact output without events:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 1 42 --json
```

The separate 10×7 data grid retains M15/M16-A's twelve residents, original businesses/assets/contracts, six-coin shifts, fixed 2/4/4 prices and 9192 combined coins. Residents start at three shared free housing tiles, walk one orthogonal tile per five simulated minutes, perform genuine one-hour shifts or owner tasks, shop on site, return home and consume. Owner couriers purchase real inputs with business funds and physically carry business-owned cargo to the correct warehouse before production. Temporary visitor presences share the existing finite external purse; none gets a new money account. No rendering, travel income/cost, economic policy or additional productive resources are added.

Control runs at 1/3/30 days reproduce actual M15/M16-A accounting. The 30-day case has **360 resident meals, 180 visitor loaves, 270 paid shifts, zero breaches and 6600 actual movement steps**, with every resident ending at home holding 66 coins and every firm holding 120. All movement, time, custody, work, purchase and witness constraints are authoritative and independently reconstructed. Encounter views expose only personally co-located observations, without private customer balances, reservation prices or hidden future requests.

The one-day late-worker fixture loses three productive shifts and all visitor sales through real input shortages; early closure leaves eighteen bread unsold and all twelve resident meals unmet. No replacement worker, remote purchase or free stock repairs either outcome. These are prescribed feasibility/failure experiments, not autonomous planning or pricing-learning results. See [M17 map, schedule, actual results and limitations](docs/M17_RESULTS.md), [run fingerprints](docs/M17_RUNS.csv), [daily results](docs/M17_DAYS.csv), [resident summaries](docs/M17_RESIDENTS.csv) and [business summaries](docs/M17_BUSINESSES.csv). Stop after M17 for review; no M18.


## M18: Bayesian bakery learning (isolated experiment)

Start from the unchanged M17 town. Only Cora's bread pricing differs: A fixed,
B original M16 short-memory policy, C Bayesian financial continuation, D the same
model with bounded one-step EVSI. Farm/mill prices, staffing, movement, resources,
visitors and distributions remain unchanged.

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial_learning --stage D 30 42 --report-json
python3 -B scripts/tools/run_learning.py --output /workspace/work/m18
python3 -B -m unittest discover -s tests -p 'test_learning.py'
godot --headless --path . --script res://scripts/tools/learning_fixtures.gd
```

Reports separate append-only witnessed cohort memory from own-business accounting,
include Bayesian beliefs and each price candidate's subjective values, sales PMF,
conditional finances and information value. The matrix driver independently audits
full transient traces, compares process replay, and measures **run-only simulation
execution** alongside corresponding existing M16 runs; timing never enters canonical
scenario JSON. Mathematical assumptions and actual outcomes are in
[docs/M18_RESULTS.md](docs/M18_RESULTS.md). Stop after M18 for review.


## M19: profiling and one exact numerical reuse

M19 measures startup/init, run-only execution, planning, transactions, observations,
logging, reports/serialization, audits and full verification separately. Profiling
is **off by default** and never enters scenario state, reports, hashes or choices.
The only numerical change reuses a nonbinding-stock sales expectation locally within
one continuation call; all historical outputs remain unchanged.

```sh
python3 -B scripts/tools/profile_simulation.py --label after --output work/m19/after
python3 -B scripts/tools/check_historical.py --output work/m19/historical.csv
godot --headless --path . --script res://tests/run_profile_tests.gd
```

[M19 results](docs/M19_RESULTS.md) contain the before/after protocol and medians,
negative/noisy results, paired comparisons, work/RSS counts, full verification,
remaining bottlenecks and an architectural language comparison. The recommendation
is to continue measured GDScript work; no compiled interface or language migration
has been implemented. Stop after M19 for review; do not begin M20.


## M20: optional native numerical comparison

C++ and Rust implement the same pure forecast/continuation batches behind one
optional official Godot C++ bridge. GDScript retains policy ranking, authoritative
transactions, observations and all economic behavior. Build instructions and
pinned tools are in [native/m20/README.md](native/m20/README.md).

```sh
# Requires the optional local build; no backend option retains historical GDScript.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial_learning --stage D --backend cpp 30 42 --report-json
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial_learning --stage D --backend rust 30 42 --report-json
```

[M20 results](docs/M20_RESULTS.md) distinguish pure computation, conversion, full
execution and main-thread decision latency. No historical defaults are replaced,
no permanent migration is chosen, and no game responsiveness claim is made from
headless throughput alone. Stop after M20 for review; no M21.

## M21: opt-in planning jobs and frame-service experiment

```sh
# Requires the optional M20 Rust build. Historical run_simulation.gd stays unchanged.
godot --headless --no-header --path . --script res://scripts/tools/run_planning_jobs.gd -- D 30 scheduled
# Same ~60-Hz host pump, synchronous Rust pricing control:
godot --headless --no-header --path . --script res://scripts/tools/run_planning_jobs.gd -- D 30 sync
python3 -B scripts/tools/measure_planning_jobs.py --phase benchmark --output work/m21
```

One worker computes Cora's complete proposal using serialized permitted facts and
private caches. At 12:25 a deterministic barrier holds authoritative simulation
time until main-thread validation/commit; host heartbeats continue. This is a
headless service proof, not a claim that a player could move while world time is
held. No new night routine, economic parameter or permanent migration is added.
[M21 results](docs/M21_RESULTS.md) report actual timing, staleness/cancellation,
ordering/parity, earlier-preparation limits and reproducible checks. Stop after
M21 for review; no M22.

## M22: bounded planning loads and quick performance checks

The opt-in dispatcher reuses M21's complete Rust policy on recorded authorized
snapshots, with 16 unacknowledged slots, private worker caches and deterministic
ordered eligibility. It does not add residents or change world authority/time.

```sh
# Requires the optional M20 Rust/bridge build.
godot --headless --no-header --path . --script res://scripts/tools/run_planning_load.gd -- 100 2 mixed
python3 -B scripts/tools/performance_smoke.py --output work/perf-smoke.json
python3 -B scripts/tools/benchmark_planning_scale.py --output work/m22/load
```

[M22 results](docs/M22_RESULTS.md) compare 1/10/100 jobs and pools of 1/2/4.
Two workers gave the best representative throughput on the two-CPU quota;
four increased memory and callback tails. The [verification cadence](docs/PERFORMANCE.md)
keeps quick advisory performance checks separate from complete historical and
independent audit acceptance. M21's real world barrier remains. Stop after M22
for review; do not begin M23.

## M23: isolated brewery economy

```sh
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_brewery --condition reference 30 42 --report-json
# Other predeclared conditions: tight, scarce, no_brew_request. Diagnostic horizons 0..30.
python3 -B scripts/tools/brewery_feasibility.py
python3 -B scripts/tools/run_brewery.py --output work/m23/experiments
godot --headless --no-header --path . --script res://tests/run_brewery_tests.gd
```

Fifteen residents and four firms use explicitly endowed M23-only techniques,
ten-coin employee shifts and fixed wheat2/flour5/bread6/ale4 prices. Mill and brewery
submit physical whole-lot requests together; the farm maximizes real grain sales
at the common quote. Consumers buy bread before traveling to the brewery for
optional ale, with actual funds and a shared ten-coin per-visitor daily allowance.
Owners receive only realized surplus after meals, above the 120 capital floor.

The [independent feasibility witness](docs/M23_FEASIBILITY.md) was verified and
committed before outcomes. [M23 results](docs/M23_RESULTS.md) separate that
witness from actual policy decisions, shortages, distribution and performance.
Historical goods, residents, rules, outputs and Rust experiments remain unchanged.
No Bayesian pricing model is transplanted to the new population. Stop after M23
for review; do not begin M24.

## M24: isolated fixed-wage labor market

```sh
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_labor_market --condition tight --mode matching 30 42 --report-json
godot --headless --no-header --path . --script res://scripts/tools/run_labor_market.gd -- --fixture vacancy:dain 3 42 --report-json
```

`shift_selection` and `matching` reuse M23's physical economy at wage10. Ordinary
employees supply homogeneous labor only in M24; historical skills stay unchanged.
Financially equal workers use a frozen daily rotation (`--tie legacy_sorted`
retains sorted ties). Matching adds a physical 15:55 bakery meeting, personally
observed notices, applications, offers and contingent next-day transfers. Vacancies
require a funded, positive-contribution position within existing equipment capacity.

The [precommitted design](docs/M24_LABOR_FEASIBILITY.md) and
[actual results](docs/M24_RESULTS.md) distinguish redistributed shifts, real
vacancy transfers, and structural shortages. No historical scenario is replaced.
Stop after M24 for review; do not begin M25.

## M25: binding three-day employment contracts

```sh
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_binding_contracts --condition tight --mode matching 30 42 --report-json
godot --headless --no-header --path . --script res://scripts/tools/run_binding.gd -- --condition tight --mode obligations_only 30 42 --report-json
python3 -B scripts/tools/run_binding.py --output work/m25/experiments
python3 -B scripts/tools/check_binding_lifecycle.py --output work/m25/lifecycle
```

M25 retains M24's fifteen residents and real economy. Three-day exclusive terms
owe ten coins for a verified hour of workplace availability, including standby.
Existing cash pays earned wages; any shortfall remains an explicit worker-by-firm
claim through expiration or lawful release. Productive work references its wage
receipt once. No-shows earn no guarantee. Current assignment excludes wages
already committed; renewal forecasts include all three days of guaranteed wages.

Local observed offers can renew or replace employment after natural expiration.
The `obligations_only` control restricts new terms to incumbent renewals under
the same financial conditions. Actual results distinguish attendance, productive
work, standby, cash wages, arrears, expiration, renewal and rehire after a gap.
Historical scenarios remain unchanged. See the
[frozen contract rules](docs/M25_CONTRACT_FEASIBILITY.md) and
[results, verification and limitations](docs/M25_RESULTS.md).
Stop after M25 for review; no dynamic wages or M26.

## M26: seller-local requests and demand-aware contract renewal

```sh
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_demand_observation --condition tight --arm requests_smoothed 30 42 --report-json
python3 -B scripts/tools/run_demand.py --checkpoint --output work/m26/checkpoint
python3 -B scripts/tools/run_demand.py --output work/m26/experiments
python3 -B scripts/tools/run_demand.py --staggered --output work/m26/staggered
python3 -B scripts/tools/check_demand_fixtures.py --output work/m26/fixtures
python3 -B scripts/tools/summarize_demand.py --input work/m26 --output docs
```

The opt-in scenario keeps M25 matching, fixed prices, ten-coin wages and binding
three-day terms. `legacy_instrumented` keeps its exact yesterday-sales forecast;
`sales_smoothed` and `requests_smoothed` share a three-completed-day smoother and
one output-target pseudo-day. Only the latter adds legitimate funded stockout
requests. They all use the unchanged M25 contract financial evaluator.

Public buyer intent and actual seller books are separate from private consumer
state. Empty shelves do not prove willingness to pay. Owner coverage, witnessed
encounters, entrusted registers and censored lower bounds remain explicit.
See the [preregistered protocol](docs/M26_DEMAND_FEASIBILITY.md) and
[actual outcomes and verification](docs/M26_RESULTS.md). No default parameters
are adopted. Stop after M26 for review; no adaptive prices, dynamic wages or M27.
