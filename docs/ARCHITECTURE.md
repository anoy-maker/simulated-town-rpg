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

## M4 commercial requests and prepaid commitments

`coordination_world.gd` extends the agents world only for the new scenario. It owns a retained request dictionary included in snapshots and initialization events. The lifecycle is `open → accepted → fulfilled`, with explicit buyer closure from open/accepted to closed. Acceptance establishes the supplier and moves payment; delivery moves actual goods once. Existing world, agents, and trading classes are unchanged.

Posting validates identity, commodity, positive integer quantity, safe fixed-price payment, current affordability, inventory limit, and the buyer/commodity active-request limit. Acceptance validates open status, eligible producer, and one accepted supplier/commodity commitment before calling `transfer_money`. Failed payment leaves the request open. After payment succeeds, only status assignment and event recording remain. Fulfillment validates accepted status and the supplier, then calls atomic `transfer_item` before marking fulfilled. Failed delivery preserves accepted status without refund. Buyer closure records a reason and retains the original payment history; it never moves money. All arithmetic uses the existing bounded integer accounting.

Open request terms are public to eligible producers. Buyers and accepted suppliers see their own active records. Private balances, unadvertised stock, and unrelated accepted agreements are excluded from observations. `coordination_policy.gd` receives only these copied data plus goals and proposes the commercial actions; `execute_decision` binds actor identity and phase, then executes the validated methods. Request terms and payment are derived by authority, so proposed buyer/payment overrides cannot alter them.

Producers deliver immediately after their work turn. All NPCs then get request-posting and acceptance opportunities before food/meals. A request can follow an output-stock shortfall after same-day sales. An accepted obligation raises the supplier's effective production target when necessary and gives its input spending priority over food-money reservation. No funds are ring-fenced; later ordinary purchases may consume working capital. This is a narrow commercial policy, with no loans, negotiation, enforcement, automatic cancellation, or rescue.

Lifecycle events are `request_posted`, `agreement_accepted`, `agreement_fulfilled`, and `request_closed`, with success/rejection reasons. Successful records include the complete updated request. Acceptance links the exact `transfer_money` receipt; fulfillment links the exact `transfer_item` receipt. End-of-day `agreement_outstanding` events annotate still-accepted records without mutating them. Decisions link the lifecycle event, which in turn links the underlying accounting operation.

The ledger auditor reconstructs request state as well as holdings, checks lifecycle transitions and immutable terms, validates exact payment/delivery receipts, and prevents receipt reuse. Accounting applies each original transfer once; lifecycle/decision annotations do not repeat it. The coordination report reclassifies linked prepayments out of employer-payment totals, includes prepaid cash in earned/spent once, and adds delivered quantities to total trade. Failed wrapper events with accounting receipts are annotations of the same failed operation, while lifecycle rejection counts remain separately visible.

Tests cover real multi-step prepaid production, failed/duplicate acceptance and delivery, stale money/capacity, immutable history, buyer-only closure without refunds, duplicate limits, privacy, voluntary acceptance/refusal, actor/price binding, persistent outstanding obligations, 30/365-day accounting/replay, and all five historical M0/M2/M3 outputs.

## M5 decision-level working-capital planning

`planning_policy.gd` wraps the unchanged commercial policy with a shared cost model and two spending priorities. `planning_runner.gd` extends the M4 runner, overriding only decision selection and report projection. It uses the exact same world type, schedule, RNG draws, goals, market rules, agreement lifecycle, and starting resources. No new world balance or event type is introduced.

For an accepted supplier obligation, missing deliverable output determines whole recipe batches. The planner subtracts owned inputs and prices the remainder from public offers. It reports missing units, known cost, own cash, availability, food cost, and whether inputs are fundable, unavailable, already owned, or ready for delivery. Both strategies run this identical calculation from the same permitted observations.

Commitment-first gives obligation inputs the current-cash budget and limits discretionary spending to `max(0, cash - missing_input_cost)`. Immediate-needs-first gives food current cash and limits input spending to `max(0, cash - missing_food_cost)`. The distinction is a budget ordering; both use the same acquisition, whole-batch production, and fulfillment logic. Incoming unfulfilled promises are not treated as owned stock. Suppliers can partially acquire affordable inputs but cannot produce without real recipe stock. Unavailable supply remains unavailable. A farmer's explicit harvest source requires no input money.

The planner annotates the proposed action's `planning` dictionary and chooses a structured reason. The existing executor copies this metadata into the decision event but uses only recognized command arguments for validation/execution. Tests prove that annotations cannot override stock/funds and that a direct world purchase can still spend notionally reserved cash. Working capital is advisory arithmetic, with no escrow or enforcement. Ledger reconstruction continues to apply original accounting events once and treat decisions as annotations.

Reports retain M4's agreement, receipt, cash-flow, trade, production, meal, and rejection accounting. Planning adds the selected priority, end-of-run own-information cost estimates, and actual activity after day 26; the historical cutoff is used only for reporting. The tests preserve all previous coverage/hashes and add matched-start comparisons, common RNG-state checks, private-information isolation, the precise prepaid-food-versus-input failure, cost/batch boundaries, and both strategies' 30/365-day replay and full ledger audit.

## M6 multiple public suppliers

`market_world.gd` extends the commercial authority with occupation-based supplier eligibility and copied public offer arrays. It publishes only each producer's output stock, fixed price, and stable ID. Active requests use the existing visibility/lifecycle rules, with eligible open requests visible to every producer of that commodity. Public requests have no predetermined target; existing actor binding, duplicate limits, atomic prepayments, real-stock delivery, capacity validation, receipt links, and permanent lifecycle records remain authoritative.

`market_policy.gd` selects a public offer using price, stock, and stable ID, then adapts the copied observation to the existing M5 planner. Every actor uses commitment-first. Producers keep the existing own-output convention, which applies to both bakers rather than depending on the original baker ID. Purchase proposals include the selected offer and public candidates as explanatory annotations. Authority does not trust those annotations or grant reservations. Empty offers remain empty, and stock/funds are rechecked at execution. No retry or multi-supplier order allocator is introduced.

`market_runner.gd` declares six initial endowments and sorts producer turns by occupation-chain order and stable ID. Every farmer receives its own seeded daily harvest opportunity; the producer phases, request/acceptance phases, meals, and reporting reuse existing mechanisms. It inherits the commercial and planning report and adds per-participant production, meals, supplier selections, spot trade, and supply commitments. All projections derive from receipts and final request records, counting prepaid cash once.

Small default-preserving hooks in the existing classes separate public offer projection, seller eligibility, public-request target, report participant IDs, and final working-capital projection. The commercial policy accepts optional authorized `supplies` in the new observation, with its historical singleton fallback unchanged. Historical schedules, prices, endowments, command arithmetic, recipes, and policies are otherwise unchanged; `world_state.gd` is unchanged. All eleven historical CLI payloads are verified byte-for-byte. The same independent ledger auditor reconstructs six-person states and agreements without a new economic event type.

## M6B alternate occupation mix

A pre-implementation zero-day executable check verified that `Market.new(seed, initial_entities)` already supports one farmer and two millers: scheduling reads each entity's occupation, offers/acceptance use occupational eligibility, and reporting iterates configured participant IDs. No production code refactor was needed. `market_downstream_runner.gd` is a thin subclass that supplies alternate initial entities and overrides only the report scenario label; it inherits the complete M6 scheduler, observations, decision adapter, authority, and report projection. Edda's `miller_2` ID and miller role replace M6's extra farmer only in this separate configuration. No new policies or economic event types are introduced.

Tests reuse the M6 report auditor with explicit expected money and daily-decision parameters, keeping the original 125-coin/37-decision defaults. M6B expects 115 coins and 38 decisions; one farmer gives one RNG draw/day. They exercise both millers' common input/production/agreement behavior, supplier competition, privacy, and the unchanged farmer inventory trigger. The full ledger reconstruction remains shared. All seventeen published historical payloads, including all six M6 experiments, remain byte-identical.

## M7 fixed economic configurations

`calibration_config.gd` defines six predeclared configurations and validates only additive harvest yield, farmer target, three fixed prices, daily payment, and starting balances. Dictionaries are deep copies. `calibration_runner.gd` inherits the M6B schedule and decision selection, supplying configured initial money/goals, wage, and a bonus on the same daily seeded draw. `calibration_world.gd` inherits the market authority and supplies fixed instance prices and permitted environmental yield range. Default-preserving hooks in the older classes route offers, price checks, request terms, wages, and harvest opportunities consistently. The kernel, recipes, decision policies, and agreement transitions remain unchanged. Configuration is included in the calibration report; historical snapshots and event formats retain their prior shape. Baseline's complete economic ledger is identical to M6B.

`calibration_report.gd` computes post-run physical bounds and receipt-derived diagnostics. It reconstructs balances and bread holdings for food-choice snapshots, separates production/business inactivity from consumption/wage transfers, and reports minimum-batch underfunding without assuming a permanent deadlock. Opportunity sequences are reproduced from the seed without advancing the world's RNG. These global/private diagnostics never enter NPC observations. Potential capacity assumes the unchanged two-batch/work-turn policies, ignores money and distribution, and is not a guaranteed feasible economic trajectory.

`scripts/tools/run_calibration.py` is a standard-library experiment driver, not another economic simulator. It calls the CLI twice per fixed case, verifies matched environmental opportunities and M6B baseline histories, independently reconstructs ledgers and receipt links, reconciles cash/production/trade/meals/affordability, and saves full workspace logs plus compact CSV projections. The committed result tables describe all 36 cases and 216 NPC outcomes. Godot tests separately exercise configuration rejection/isolation, higher/lower price authority, arithmetic bounds, report correctness, replay, and twelve calibration ledgers; earlier tests and CLI captures preserve all 23 historical outputs.

## M8 combined candidate and observational study

`calibration_config.gd` adds an optional combined preset through `available_experiments()` while retaining the original six-entry M7 study list and all defaults. No world, runner, recipe, schedule, or decision-policy code changes. The existing batch tool's `--study m8` selects the four comparison cases and can reuse M7 captures after checking committed hashes and independently auditing them. Its original M7 invocation and output schemas remain unchanged.

`food_sale_losses()` in the batch tool reconstructs bread from receipts, takes a snapshot before each food proposal's command, tracks later same-day successful sales, and links a failed meal. It excludes other bread outflows after the snapshot and records planning/sale/consumption event IDs. This observer receives only completed run data and cannot affect agents or authoritative state. The new CSV projections include incident counts; historical Godot reports and JSON payloads are unchanged. Focused tests cover the combination, replay/accounting, and positive/negative observer cases without duplicating the historical test matrix.

## M9 workplaces and paid labor

`labor_config.gd` declares the separate twelve-resident experiment before outcomes. Resident accounts contain occupation, skills, and bounded daily labor capacity. Three business accounts reuse the kernel's integer money/inventory representation; separate workplace records specify sole ownership, employee IDs, industry, productive slots, batches/shift, targets, and owner compensation. Employee records bind worker, business, fixed wage, and active status. Business stock/funds belong to its account, not the owner's household. Initial records are trusted developer configuration, asserted and copied; no runtime recruitment or capital/debt subsystem is introduced.

`labor_world.gd` extends the unchanged kernel. The command boundary authorizes an owner to offer a shift and its worker to accept it. Offers reserve nothing and expire on day advancement; accepted work, receipts and decisions remain in the ledger. `work_shift()` validates actual ownership/employment, skill, daily worker/global workplace labor limits, wage and recipient capacity, all recipe inputs/output bounds, and the current offer before any write. It then uses the kernel's money transfer and harvest/recipe commands synchronously and records unique receipt links plus one unit of labor. All compensation, including an owner's, requires a funded productive shift. Direct harvest/production and nonmarket resource/ordinary-money transfers are disabled in this world to prevent bypassing paid labor or business ownership. Purchases retain native atomic accounting plus fixed-price industry eligibility. Food can only be consumed from personal stock, once successfully per day.

The world draws four fixed farm opportunities each day regardless of work decisions. `observe()` exposes personal state, own offered shifts, and output-only public seller offers. An owner additionally sees their own workplace balances, inputs, employment terms, skill eligibility, and worker availability, but no other household finances, private firm inputs/funds, history, or future harvest draws. `labor_policy.gd` is a pure function with common owner/worker rules. The runner schedules opportunities in industry order and executes fresh proposals. Food choices use personal funds only. Output targets and wage/input budgeting are policy choices, not compulsory work or prosperity guarantees.

`labor_runner.gd` reuses the original totals projection and adds business/household cash flow, receipts-derived labor and production, skipped/unfunded reasons, meals, trailing activity, physical bounds, and money circulation. `run_labor.py` is a separate standard-library experiment/audit driver: it reconstructs accounts, daily offers/labor/meals, resource sources/sinks, verifies every payroll/production receipt belongs to exactly one valid shift, and reconciles reports. All historical worlds/policies and reports are untouched. Histories still grow in memory, and snapshots/events/JSON make deep copies; this is a bounded 12-person experiment, not long-term historical storage.

## M10 ownership income and operating reserves

Four small finance scripts extend M9. `finance_config.gd` fixes three payout policies, a two-meal personal cash/stock goal, and a two-day full-capacity cash reserve. Reserve calculation uses the highest active employee/owner compensation, workplace slots, existing recipe inputs/batches and fixed prices; it does not value inventory or classify cash as accounting profit. An excessive reserve is safely capped at the money bound, leaving no distributable cash. `finance_policy.gd` is pure: it proposes only the personal shortfall capped by all or half the firm's available surplus, or waits. It receives the same authorized observations in both payout cases.

`finance_world.gd` inherits every M9 work, production, market and consumption command. Its sole new economic command, `owner_withdrawal(owner, business, amount)`, validates ownership, bounded integer amount, actual source funds, retained reserve and recipient capacity before writing either balance. One distinct `owner_withdrawal` event records the inverse business-to-owner cash movement, reserve, pre-transfer distributable amount and remaining funds; it is not a wage receipt. Failures change only history. The finance executor binds actor and business context and ignores spoofed parties/reserves. Only the authorized owner's copied business observation gains the cash-budget fields; no other private balances or inputs are exposed. Buffers constrain withdrawals only; business operations may spend them.

`finance_runner.gd` uses M9's scheduler through a default-empty `_before_food()` hook. Payout decisions occur after all productive shifts and before personal food choices. The no-withdrawal control skips the hook's actions, preserving the exact M9 ledger and inherited report projection. The report adds ownership receipts/spending separately from wages, payout/rejection counts, reserve/remaining cash, payouts without a same-day shift, and cash circulation. Withdrawal activity does not falsely reset the inherited real-production/trade inactivity metrics. No initial state, existing decision policy, recipe, wage or market-selection rule changes.

The existing experiment tool adds `--study m10` with optional hash-verified M9 capture reuse. Its original M9 matrix/CSV schema remain intact. The shared independent auditor conditionally reconstructs ownership cash, recomputes reserves without trusting event metadata, enforces post-withdrawal floors, verifies recipient ownership, and reconciles separate wage/distribution flows and report summaries. Payroll and production receipts still require unique actual labor. All policies share each seed's full environmental history, and the control's complete events and normalized report must equal M9. This remains a cash-flow experiment; there is no general accounting-profit, banking, debt or dividend framework.

## M11 prescribed equilibrium reference

`equilibrium_config.gd` copies M9's entities, ownership, skills and employment, applying only the exact reference endowments/prices/wages. `equilibrium_world.gd` overrides two small methods in the labor authority: `_unit_price()` and `_harvest_opportunity()`. Their defaults retain the original prices and identical seeded RNG call order for M9/M10. Public offers and purchase validation use the same price method. The kernel, atomic purchases, shift eligibility/capacity, payroll, recipes and consumption commands are unchanged; direct unpaid production remains forbidden. M10's withdrawal world is not used.

`equilibrium_runner.gd` prescribes the alternating worker pairs and the farm → mill → bakery → household purchase → consumption order. It calls the existing authority for every movement, never resets holdings, and calls no autonomous policy. The inherited labor report projects actual receipts; reference metadata explains the prescribed groups and expected daily output, with a corrected zero-initial-stock physical bound. A canonical sorted-key ledger SHA-256 permits process replay comparisons through compact report-only CLI output. Historical CLI output stays unchanged.

Focused tests reconstruct every account from receipts at all four horizons, check currency/bounds at every event, require each payroll/production receipt to belong to one real shift, and check all daily production/consumption and end-of-day financial states. Odd/even household states are compared to their earlier phase, including even days against initialization. A deliberately incorrect but currency-conserving wage is detected. Two-day data pass the unmodified independent Python labor auditor; annual ledgers stay in memory rather than verbose dumps. This verifies feasibility under prescribed decisions, not autonomous discovery, market stability or response to perturbations.

## M12 employer production and staffing choices

`employer_world.gd` inherits M11's price/harvest authority and all M9 labor/market rules. Its only observation extension projects an authorized owner's own completed previous-day output sales, input purchases and prior forecast from existing receipts. The reverse scan stops before that day; it exposes neither other households' money, unrelated firm internals, raw history nor future transactions. Observations remain deep copies. Reporting aggregates do not enter decisions.

`employer_policy.gd` has no world reference. It uses one day of own realized sales, with the one-time 8/8/12 initial forecast, offsets unsold stock and computes minimum whole productive shifts. It selects owner first then eligible available employee IDs, reducing that prefix until real/public inputs and current cash cover inputs plus payroll. There is no recurring output floor, fair rotation or work to sustain demand. The policy proposes input purchases and worker IDs, with forecasts, costs, limiting reasons and skipped candidates.

`execute_plan()` binds owner/business authorization, rejects duplicate/unrelated workers and invalid input terms, recomputes authoritative wages/prices and checks joint cash before dispatch. It uses the original validated purchase, shift offer, worker policy acceptance and paid production commands; no new money/inventory mutation is introduced. Individual transactions retain their original atomic guarantees. A whole employer plan is not atomic: prior successful commands remain real if a later command fails. Its structured annotation reports executed/wait/partial/rejected and actual input/offer/work receipt IDs, cash and output stock. Failed/partial annotations apply no additional economic changes or refunds.

`employer_runner.gd` preserves industry order and ordinary household food/meal decisions while replacing prescribed production and rotating pairs with one fresh plan per owner/day. Its report adds plan counts, selections/skips/reasons, first unmet meal, first pre-food bread stock below twelve, misses with unsold bread, seven-day inactivity and the first eight daily aggregates. Native reports retain their old per-worker-wait metric; plan skips/actual paid shifts describe M12 nonparticipation. `run_employer.py` runs the matched M11/M12 six-case matrix twice, validates published M11 hashes, and saves compact summaries/tables with complete ledger fingerprints. No annual event exports are needed.

Focused Godot tests audit full annual cash/goods/payroll/production and unique plan/work receipt links in memory, plus split-run replay, forecast/stock/budget decisions, stale command failures, partial execution and privacy boundaries. The shared independent Python auditor conditionally checks own-sales forecasts and unique work claims alongside existing labor receipts; short-trace corruption tests and annual process replay cover the new annotations. Historical worlds/policies remain unchanged. This narrow last-sales/owner-first experiment is not a general demand model, fair scheduler or economic rescue mechanism.
