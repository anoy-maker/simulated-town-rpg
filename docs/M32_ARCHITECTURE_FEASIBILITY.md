# M32 — Simulation architecture separation: feasibility audit

Research for [issue #48](https://github.com/anoy-maker/simulated-town-rpg/issues/48).
No simulation extraction, new laboratory, economic experiment, or performance
optimization is implemented here. Proposed interfaces and tests below are designs.

## Recommendation and verified baseline

Retain one authoritative GDScript world and its ordered command execution. Work
toward composition behind that facade through individually verified, read-only
seams before extracting custody or scheduling. Do not implement a `space=false`
switch: space currently determines earned wages, usable inputs, legitimate market
knowledge, and the receipts from which later decisions learn.

The smallest recommended **M33** is a pure trade-window predicate extracted from
`spatial_world._open()`, with all seller lookup, locality, activity, accounting,
callbacks, and event emission left in place. This is deliberately smaller than a
replaceable purchase gate. It tests an extraction discipline, **not** economic-lab
independence or a likely material speedup. A transport adapter or clock rewrite
is premature. M33 requires separate review and authorization.

Starting `main`: **`f65144120067ab5018e719cb2b291786a966da99`**; research branch:
`codex/m32-architecture-audit`. Source citations refer to that commit. The accepted
[M31 full run #44449713489](https://github.com/anoy-maker/simulated-town-rpg/actions/runs/44449713489)
reports 17 successful stages, 3,482 Godot checks and 166 Python tests, including
historical pins, independent C/D audits, and the M30 matrix. I checked its job logs:
the actual checkout was **`70cc52e849f9efbd4830de72ed33131d529ce71c`**. The run
metadata's `head_sha` is `7202a0f11daa9a5232fb26d085cdddf78deac024`, which is **not**
the checkout selected for that manual run. Comparing the tested checkout to the
starting commit finds changes only in `.github/workflows/verification.yml`,
`README.md`, `docs/M31_RESULTS.md`, and `docs/ROADMAP.md`; simulation, native,
testing and tooling source are identical. This supports using the accepted source
evidence; it does not certify the subsequently edited workflow YAML.

No M32 simulation tests or benchmarks were run. The full suite is unnecessary for
this documentation-only change. M30 worker bidding remains opt-in experimental
behavior, not an adopted economic baseline.

## Actual dependencies and initialization

The following are **inheritance**, not interchangeable runtime components. Every
arrow points from parent to child; each named file is in `scripts/sim/`. The
declarations are at line 1 of the respective files.

```text
world_state -> labor_world -> equilibrium_world -> profitable_world
                                                  -> enterprise_world
                                                     -> pricing_world
                                                        -> spatial_world
                                                           -> brewery_world
                                                              -> labor_market_world
                                                                 -> binding_world
                                                                    -> demand_world
                                                                       -> input_world
                                                                          -> cash_allocation_world
                                                                             -> wage_world

world_state -> agent_world -> coordination_world -> market_world -> calibration_world
labor_world -> finance_world                   (sibling, not an M30 ancestor)
equilibrium_world -> employer_world            (sibling, not an M30 ancestor)
spatial_world -> learning_world -> planning_jobs_world (separate M18–M22 branch)
```

Declarations can be checked at [world_state.gd:1](../scripts/sim/world_state.gd#L1),
[labor_world.gd:1](../scripts/sim/labor_world.gd#L1),
[equilibrium_world.gd:1](../scripts/sim/equilibrium_world.gd#L1),
[profitable_world.gd:1](../scripts/sim/profitable_world.gd#L1),
[enterprise_world.gd:1](../scripts/sim/enterprise_world.gd#L1),
[pricing_world.gd:1](../scripts/sim/pricing_world.gd#L1),
[spatial_world.gd:1](../scripts/sim/spatial_world.gd#L1),
[brewery_world.gd:1](../scripts/sim/brewery_world.gd#L1),
[labor_market_world.gd:1](../scripts/sim/labor_market_world.gd#L1),
[binding_world.gd:1](../scripts/sim/binding_world.gd#L1),
[demand_world.gd:1](../scripts/sim/demand_world.gd#L1),
[input_world.gd:1](../scripts/sim/input_world.gd#L1),
[cash_allocation_world.gd:1](../scripts/sim/cash_allocation_world.gd#L1), and
[wage_world.gd:1](../scripts/sim/wage_world.gd#L1).
The side branches are visible in [agent_world.gd:1](../scripts/sim/agent_world.gd#L1),
[coordination_world.gd:1](../scripts/sim/coordination_world.gd#L1),
[market_world.gd:1](../scripts/sim/market_world.gd#L1),
[calibration_world.gd:1](../scripts/sim/calibration_world.gd#L1),
[finance_world.gd:1](../scripts/sim/finance_world.gd#L1),
[employer_world.gd:1](../scripts/sim/employer_world.gd#L1),
[learning_world.gd:1](../scripts/sim/learning_world.gd#L1), and
[planning_jobs_world.gd:1](../scripts/sim/planning_jobs_world.gd#L1).

Runner inheritance differs from world inheritance:

```text
simulation_runner -> labor_runner -> profitable_runner -> external_trade_runner
                                                          -> pricing_runner
                                                          -> spatial_runner
                                                             -> learning_runner
                                                                -> planning_jobs_runner
RefCounted -> brewery_runner -> labor_market_runner -> binding_runner
                                                        -> demand_runner
                                                           -> input_runner
                                                              -> cash_allocation_runner
                                                                 -> wage_runner
simulation_runner -> trading_runner -> agents_runner -> coordination_runner
                                                        -> planning_runner
                                                           -> market_runner
                                                              -> market_downstream_runner
                                                                 -> calibration_runner
labor_runner -> finance_runner / equilibrium_runner / employer_runner
employer_runner -> causality_runner
```

In particular, `spatial_runner` extends `external_trade_runner`, not
`pricing_runner` ([spatial_runner.gd:1](../scripts/sim/spatial_runner.gd#L1)).
M23 starts a fresh `RefCounted` runner
([brewery_runner.gd:1](../scripts/sim/brewery_runner.gd#L1)); it reuses spatial
**world authority**, not the M17 runner. Its timetable is explicit at
[brewery_runner.gd:5](../scripts/sim/brewery_runner.gd#L5). M24 adds 900/955
appointments and a sorted schedule ([labor_market_runner.gd:12](../scripts/sim/labor_market_runner.gd#L12));
M25 wraps attendance, wage tender and midnight closure
([binding_runner.gd:8](../scripts/sim/binding_runner.gd#L8)); M26 freezes demand
before the 955 board and closes windows after parent appointments
([demand_runner.gd:6](../scripts/sim/demand_runner.gd#L6)). M28–M30 keep this
schedule and replace the world in constructors
([wage_runner.gd:3](../scripts/sim/wage_runner.gd#L3)).

Initialization is also an interface. Subclass configuration must exist before
parent constructors call virtual methods: M30 sets its arm/anchors before
`super`, M29 selects initial cash via `_labor_market_initial`, M25 installs terms,
and M23 sets `_starting` before spatial initialization. Spatial creates presences
and cargo **before** passing the economy to pricing/enterprise/labor/root
([wage_world.gd:17](../scripts/sim/wage_world.gd#L17),
[cash_allocation_world.gd:4](../scripts/sim/cash_allocation_world.gd#L4),
[binding_world.gd:13](../scripts/sim/binding_world.gd#L13),
[brewery_world.gd:15](../scripts/sim/brewery_world.gd#L15),
[spatial_world.gd:12](../scripts/sim/spatial_world.gd#L12)). The root records
`initialize` using a virtual `snapshot()`
([world_state.gd:30](../scripts/sim/world_state.gd#L30)); moving construction past
that point would change the initial receipt. Labor seeds its RNG and validates
accounts/businesses/contracts before the root constructor
([labor_world.gd:15](../scripts/sim/labor_world.gd#L15)). This is not safe to replace
with a generic post-construction component registration step.

## State ownership and read/write inventory

“Owner” here means current code responsibility. Underscore fields in GDScript are
conventions, not an enforced private capability system. Administrative runners and
auditors legitimately see more than NPC policies; they must not become NPC views.

| State | Writer / invariant boundary | Readers and hazardous dependencies |
| --- | --- | --- |
| Entity IDs, personal/business/external money and warehouse/personal stock, `_entities` | Root initialization; validated `transfer_item`, `transfer_money`, `purchase`, production and sinks ([world_state.gd:60](../scripts/sim/world_state.gd#L60), [world_state.gd:94](../scripts/sim/world_state.gd#L94), [world_state.gd:138](../scripts/sim/world_state.gd#L138)) | Descendant authorities, snapshots, reports, controlled runners; policies get filtered copies. Public economic commands are further restricted by labor/quoted/spatial wrappers. |
| Business-owned cargo, `_cargo`; warehouse versus in-transit goods | Spatial receiving hook and validated `deposit` ([spatial_world.gd:291](../scripts/sim/spatial_world.gd#L291), [spatial_world.gd:309](../scripts/sim/spatial_world.gd#L309)) | Procurement may count owned warehouse+cargo; production may use warehouse only. Cargo is not the courier's personal stock and is counted once globally. |
| Business ownership, assets, employment, exclusive affiliation, pending jobs | `_businesses`, `_employment` initialized by labor; enterprise `_assets`, `_affiliations`, `_pending_hires` and boundary commands ([enterprise_world.gd:13](../scripts/sim/enterprise_world.gd#L13), [enterprise_world.gd:108](../scripts/sim/enterprise_world.gd#L108)) | Work checks assets/affiliation; labor-market hook maintains rosters and physical schedules. Business ownership, employee affiliation, asset holder and cargo holder are distinct facts. |
| Wage promises, terms, attendance, earned claims, arrears | Binding `_terms`, `_active_terms`, `_attendance`, `_obligations`, `_releases`; verify/tender/closure ([binding_world.gd:65](../scripts/sim/binding_world.gd#L65), [binding_world.gd:109](../scripts/sim/binding_world.gd#L109), [binding_world.gd:273](../scripts/sim/binding_world.gd#L273)) | Business planning and distributions consider claims; workers see their own. Claims are obligations/receivables, not new coins; earned arrears survive term expiry. |
| Cash-flow books, `_cash_results`, transfer purpose | Profitable/enterprise receipt overrides before root recording ([profitable_world.gd:39](../scripts/sim/profitable_world.gd#L39), [enterprise_world.gd:46](../scripts/sim/enterprise_world.gd#L46)) | Own-business observations, earnings settlement, reports/audits. Derived books participate in later decisions; they are not expendable diagnostic caches. |
| Live quotes, daily buying limits | Pricing `_quotes`, `_market_bought`, quote/revision/purchase authority ([pricing_world.gd:29](../scripts/sim/pricing_world.gd#L29), [pricing_world.gd:65](../scripts/sim/pricing_world.gd#L65), [pricing_world.gd:89](../scripts/sim/pricing_world.gd#L89)) | Global public terms exist administratively; spatial NPC access filters them. Offered availability does not reserve goods. |
| Day, minute, route, tile, activity, schedule, active presence | Root `_day`; spatial `_space` with validated day/clock/movement/activity commands ([spatial_world.gd:110](../scripts/sim/spatial_world.gd#L110), [spatial_world.gd:118](../scripts/sim/spatial_world.gd#L118), [spatial_world.gd:167](../scripts/sim/spatial_world.gd#L167)) | Runner proposes appointments; clock dispatch invokes economic work. Employment hooks change route assignments, not current tiles. |
| Visitor bodies versus external goods claims | Gate entry creates stable presence ID; successful economic-event hook updates per-body loaf/ale claims ([spatial_world.gd:345](../scripts/sim/spatial_world.gd#L345), [brewery_world.gd:176](../scripts/sim/brewery_world.gd#L176)) | Many bodies share one finite `visitors` account; claims partition that account's inventory. Inactive records remain for audit. |
| Interaction authorization contexts | Spatial `_courier`, `_shopper`, `_completing`, `_external_consumer`; pricing `_executing_quote`; enterprise `_transfer_purpose` ([spatial_world.gd:4](../scripts/sim/spatial_world.gd#L4), [enterprise_world.gd:68](../scripts/sim/enterprise_world.gd#L68)) | Scoped synchronous call chains depend on these fields. They are not transferable worker-thread credentials or spare money accounts. |
| Encounter sets and NPC observations | Spatial `_witnesses`, `_encounter`, `observe`; descendant inspection receipts and permitted views ([spatial_world.gd:99](../scripts/sim/spatial_world.gd#L99), [spatial_world.gd:410](../scripts/sim/spatial_world.gd#L410), [brewery_world.gd:56](../scripts/sim/brewery_world.gd#L56)) | Co-tile active presences are potential witnesses, not LOS/attention or crime knowledge. Inspection and successful purchase have different validation. |
| Beliefs and memories that affect decisions | Learning `memory/current/beliefs`; later demand/input/wage histories and frozen points ([learning_world.gd:16](../scripts/sim/learning_world.gd#L16), [demand_world.gd:126](../scripts/sim/demand_world.gd#L126), [input_world.gd:34](../scripts/sim/input_world.gd#L34), [wage_world.gd:35](../scripts/sim/wage_world.gd#L35)) | Separate experimental branches. Learning memory is outside native snapshot; later world snapshots include their observation state. Own receipts or permitted public disclosure establish provenance. |
| Canonical event array and receipt links | Root `_record` allocates IDs; overrides enrich books/details, timestamp and run hooks ([world_state.gd:229](../scripts/sim/world_state.gd#L229), [spatial_world.gd:60](../scripts/sim/spatial_world.gd#L60)) | Many callers capture `_events.back().id`; descendants can append nested events or mutate current details. Replacing this with asynchronous subscribers would change semantics. |
| Profiling, audit reconstruction, reports, queue timing | Execution-profile sidecars, independent Python/native auditors and post-run report builders ([spatial_audit.gd:18](../scripts/sim/spatial_audit.gd#L18), [brewery_audit.py:46](../scripts/tools/brewery_audit.py#L46)) | Observers reconstruct copies; research diagnostics can use hidden facts offline. Those facts must never feed policies. Timing must never select world actions. |

Direct access prevents treating these as existing service APIs. For example,
`brewery_runner.appointment()` reads `_cargo` before deposits, `_entities` before
drinking, and `_space` for visitors
([brewery_runner.gd:41](../scripts/sim/brewery_runner.gd#L41),
[brewery_runner.gd:60](../scripts/sim/brewery_runner.gd#L60),
[brewery_runner.gd:71](../scripts/sim/brewery_runner.gd#L71)). Binding runners read
`_active_staff`/`_affiliations`; demand reports read `_demand_days`; planning-job
validity reads quotes, Cora's presence and cargo
([binding_runner.gd:11](../scripts/sim/binding_runner.gd#L11),
[demand_runner.gd:15](../scripts/sim/demand_runner.gd#L15),
[planning_jobs_runner.gd:38](../scripts/sim/planning_jobs_runner.gd#L38)). They
orchestrate commands but are not cleanly isolated observation clients today.

### Rust boundary actually present

`native_math.gd` packs forecast/continuation jobs; the Godot C++ bridge calls the
Rust C ABI; results return as numeric values, not economic receipts
([native_math.gd:27](../scripts/sim/native_math.gd#L27),
[native_math.gd:52](../scripts/sim/native_math.gd#L52),
[bridge.cpp:16](../native/m20/bridge/bridge.cpp#L16),
[lib.rs:87](../native/m20/rust/src/lib.rs#L87)). Its hypothetical `operate/close`
finance arithmetic has no reference to live inventories or money. The worker
receives validated owned bytes and a private bridge/cache
([planning_job.gd:41](../scripts/sim/planning_job.gd#L41),
[planning_worker.gd:21](../scripts/sim/planning_worker.gd#L21)). Main-thread commit
checks actor/job/day/minute/input hash and relevant state before invoking the
normal quote proposal path ([planning_jobs_runner.gd:97](../scripts/sim/planning_jobs_runner.gd#L97)).
The planning token blocks simulation time while required work is pending
([planning_jobs_world.gd:12](../scripts/sim/planning_jobs_world.gd#L12)). This is
useful precedent for pure observation-in/proposal-out, not an existing Rust world,
spatial service, or M30 worker scheduler.

## Concrete economic–spatial coupling paths

Categories: **E** economic truth/configuration; **P** physical feasibility/custody;
**K** knowledge permission; **T** orchestration/time; **D** diagnostics. Economic
state changes; prices/recipes/identity rules are fixed within their configured
case unless an authorized scenario command changes them. A public price does not
imply permission to observe every seller everywhere.

| # / kinds | Actual caller → callee and consequence | Candidate boundary / preservation obligation |
| --- | --- | --- |
| 1 — K/P/T | `inspect_offers` → `_at`, `_available`, `_open`, `public_quotes`, `_encounter` ([spatial_world.gd:256](../scripts/sim/spatial_world.gd#L256)). Inspection emits an encounter only on success. | A read-only access predicate could inform this command; the world must keep rejection and encounter emission. Remote/closed/busy inspection must remain rejected. |
| 2 — K/P/E | `buy_from_market` → virtual `buyer_observation` → local/open quote filter → `purchase_quote` ([pricing_world.gd:138](../scripts/sim/pricing_world.gd#L138), [spatial_world.gd:265](../scripts/sim/spatial_world.gd#L265)). `_at` checks active co-location, **not idle activity**. | Do not conflate visible offers with executable purchases. Adding `_available` to this observation filter would change legitimate observations. |
| 3 — E/P/T | `shop`/`procure` install `_shopper`/`_courier` → spatial `purchase_quote` → pricing quote validation → labor `_commodity_purchase` → root `purchase` ([spatial_world.gd:295](../scripts/sim/spatial_world.gd#L295), [spatial_world.gd:328](../scripts/sim/spatial_world.gd#L328), [spatial_world.gd:272](../scripts/sim/spatial_world.gd#L272), [pricing_world.gd:89](../scripts/sim/pricing_world.gd#L89), [labor_world.gd:109](../scripts/sim/labor_world.gd#L109), [world_state.gd:94](../scripts/sim/world_state.gd#L94)). Location/open/context/activity checks precede quote/stock/cash checks. | Preserve rejection precedence, integer/overflow validation, atomic four writes, execution quote and physical actor. A helper may not call the protected root purchase to bypass wrappers. |
| 4 — E/P | Root `purchase` → virtual `_purchase_inventory` chooses live business cargo, while seller stock leaves warehouse ([world_state.gd:113](../scripts/sim/world_state.gd#L113), [spatial_world.gd:291](../scripts/sim/spatial_world.gd#L291)). Spatial checks owned warehouse+cargo capacity before the kernel. | A future custody adapter needs a validated destination owned by the world; a copied view cannot be a write destination. Exactly one holding gains goods. |
| 5 — E/P/T | `deposit` checks owner/holder/site/idle/capacity → `_begin` → moves real cargo to warehouse → deposit receipt ([spatial_world.gd:309](../scripts/sim/spatial_world.gd#L309)). Goods move immediately at command time, while the five-minute activity finishes later. | Separating “delivery completion” must preserve this exact boundary for integrated parity. Delaying goods until activity end or crediting both locations changes input feasibility. |
| 6 — E/P/K/T | `propose_grain` → physical inspection → own plan → request; `clear_grain` rechecks eligibility, real stock and quote → stable brewery-then-mill receipt order → normal purchases ([brewery_world.gd:94](../scripts/sim/brewery_world.gd#L94), [brewery_world.gd:124](../scripts/sim/brewery_world.gd#L124), [brewery_world.gd:145](../scripts/sim/brewery_world.gd#L145)). | Allocation is not a reservation or money source. Reordering equal-time execution can alter failures and cargo ownership; transport abstraction cannot duplicate grain. |
| 7 — E/P/K | `procure_flour` uses own inspected terms and whole lots; `business_observation` includes owned cargo for procurement; `plan_business` substitutes warehouse-only input stock ([brewery_world.gd:73](../scripts/sim/brewery_world.gd#L73), [brewery_world.gd:86](../scripts/sim/brewery_world.gd#L86), [brewery_world.gd:157](../scripts/sim/brewery_world.gd#L157), [binding_world.gd:153](../scripts/sim/binding_world.gd#L153)). | Keep owned resources distinct from usable production inputs. A warehouse-only lab changes delivery assumptions and must say so. |
| 8 — T/P/E | Runner appointment → `advance_time`: emit clock, move sorted walkers, complete sorted due activities → virtual `work_shift` → native wage/recipe/labor receipt ([spatial_world.gd:167](../scripts/sim/spatial_world.gd#L167), [spatial_world.gd:234](../scripts/sim/spatial_world.gd#L234), [labor_world.gd:204](../scripts/sim/labor_world.gd#L204)). | Clock and completion order are economically observable. A skipped-tick scheduler must prove identical boundaries and receipts; it is outside the proposed M33. |
| 9 — T/P/E | `begin_attendance` starts work or standby; ending **clock event hook** → `_verify_window` → attended/due claims → actual wage tender, before the clock loop completes productive work ([binding_world.gd:42](../scripts/sim/binding_world.gd#L42), [binding_world.gd:65](../scripts/sim/binding_world.gd#L65), [binding_world.gd:79](../scripts/sim/binding_world.gd#L79), [binding_world.gd:35](../scripts/sim/binding_world.gd#L35)). | Financial guarantees are earned through verified attendance, including standby. No attendance-free wages; no double wage on production. Partial payment can block production without erasing liability. |
| 10 — K/T/E/P | `appointment(955)` → `begin_board`, owner advertisements, worker inspection/applications, employer offers, worker responses; `_at_board` requires local five-minute board activity ([labor_market_runner.gd:37](../scripts/sim/labor_market_runner.gd#L37), [labor_market_world.gd:84](../scripts/sim/labor_market_world.gd#L84)). | A global job board would change who can learn and apply. Retain personally observed notices, employer/worker separation and deterministic meeting order. |
| 11 — T/E/P | Enterprise boundary ends old affiliations before starting new ones; labor-market receipt hook removes obsolete rosters and updates future schedules; binding archives dispositions once ([enterprise_world.gd:108](../scripts/sim/enterprise_world.gd#L108), [labor_market_world.gd:53](../scripts/sim/labor_market_world.gd#L53), [binding_world.gd:297](../scripts/sim/binding_world.gd#L297)). | Boundary timestamps represent the same midnight; route assignment must not teleport a worker, duplicate employment, forgive arrears or grant extra labor. |
| 12 — E/P/K | Visitor presence ID maps through `_body` to shared `visitors` account; purchase/sink hooks update that body's claims; exit requires no remaining goods ([spatial_world.gd:56](../scripts/sim/spatial_world.gd#L56), [spatial_world.gd:345](../scripts/sim/spatial_world.gd#L345), [brewery_world.gd:176](../scripts/sim/brewery_world.gd#L176), [brewery_world.gd:223](../scripts/sim/brewery_world.gd#L223)). | Do not spawn six funded accounts, confuse claims with extra stock, or permit one visitor to consume another's goods. Alias identity and physical holder must survive a future service boundary. |
| 13 — K/P/T | Encounter → `_witnesses` → learning callback → coverage/cohort joins → beliefs → permitted `planning_observation` ([spatial_world.gd:99](../scripts/sim/spatial_world.gd#L99), [learning_world.gd:43](../scripts/sim/learning_world.gd#L43), [learning_world.gd:103](../scripts/sim/learning_world.gd#L103)). | Counting hypothetical arrivals or global demand as observed would change decisions. Co-tile encounter sets are not crime witness truth, LOS or memory of an unseen act. |
| 14 — K/E/T | M26 shop/grain/flour commands disclose validated requests, link actual receipts and own seller witness; clock ticks measure coverage; 955 freezes own eligible history ([demand_world.gd:16](../scripts/sim/demand_world.gd#L16), [demand_world.gd:48](../scripts/sim/demand_world.gd#L48), [demand_world.gd:56](../scripts/sim/demand_world.gd#L56), [demand_world.gd:126](../scripts/sim/demand_world.gd#L126)). | A request is disclosed intent, not a commodity or guaranteed future sale. Lost spatial coverage changes censorship/forecasts even with identical aggregate sales. |
| 15 — K/E/T | M28 receipt callback captures only own non-retail input orders with inspection/quote provenance; M30 inspected encounters update own known prices, while shopping events update own history ([input_world.gd:15](../scripts/sim/input_world.gd#L15), [wage_world.gd:35](../scripts/sim/wage_world.gd#L35), [wage_world.gd:62](../scripts/sim/wage_world.gd#L62)). | Do not replace these with global supplier funds, other bids, future availability or researcher diagnostics. Input callback explicitly forbids recursive emission because its parent still links the last receipt. |
| 16 — E/P/T/D | Spatial `_record` adds custody/visitor claims before parent logging, timestamps afterward, then invokes descendant callbacks; parent financial books and quote counters also update ([spatial_world.gd:60](../scripts/sim/spatial_world.gd#L60), [pricing_world.gd:29](../scripts/sim/pricing_world.gd#L29), [profitable_world.gd:39](../scripts/sim/profitable_world.gd#L39)). | This is an ordered command continuation, not a passive log bus. Splitting event publication must retain receipt IDs, reentrancy rules and state visibility at every hook. |
| 17 — E/P/D | Brewery audit replays entity stock and cargo separately, matches visitor claims, validates each currency/resource step and full final state ([brewery_audit.py:46](../scripts/tools/brewery_audit.py#L46), [brewery_audit.py:340](../scripts/tools/brewery_audit.py#L340)); demand audit rebuilds witness coverage and request provenance ([demand_audit.py:148](../scripts/tools/demand_audit.py#L148)). | A new lab needs its own physical assumptions checked alongside unchanged economic invariants. Matching totals alone cannot certify observation/custody parity. |

The older prepaid-supply system is a separate branch: `accept_request` transfers
real money and `fulfill_request` transfers real goods before status changes
([coordination_world.gd:57](../scripts/sim/coordination_world.gd#L57),
[coordination_world.gd:82](../scripts/sim/coordination_world.gd#L82)). M30 does not
inherit that commercial-request registry. Reunification must not assume all
historical agreement types already share a universal contract service.

## Invariants and who must enforce them

1. **One identity/account/holding authority.** World commands validate integer
   bounds, funds, stock, recipient capacity and ownership before writes. Coin
   transfers conserve existing coins; production/consumption have explicit recipe
   sources/sinks. The M23–M30 reference total is 9,192; other scenarios retain their
   own initial totals. Custody transfers do not manufacture another commodity.
2. **Atomic rejection, honest consequences.** A rejected atomic economic command
   preserves its balances/holdings. It may append a rejection. A composite activity
   can already have consumed time or emitted inspection/intent before a purchase
   fails; do not describe the entire composite as snapshot-unchanged. Failed work
   cannot erase an independently earned wage claim or preceding valid payment.
3. **One clock and deterministic total order.** Integrated minute increments are
   five; preserve clock-before-movement-before-completion and sorted participants,
   including nested contract receipts during clock recording. Arrival, inspection,
   shop, deposit, attendance and midnight are specific causal boundaries.
4. **Labor, employment and liability differ.** On-site verified work/standby earns
   availability guarantees; productive work additionally needs paid guarantees,
   installed capacity and actual usable inputs. Future promises are not cash or
   current arrears. Expiry closes future duties without destroying earned claims.
5. **Ownership differs from custody and visibility.** An owned input in cargo is
   unavailable to the recipe until validated deposit. A visible offer is neither
   permission to transact nor reserved stock. A witness set is not omniscience.
6. **Views and policies cannot mutate truth.** Return copies of only own/permitted
   facts with provenance; proposals undergo current authoritative revalidation.
   Global audit state and wall-clock timings cannot become economic policy inputs.
7. **Preserve actual event semantics.** The current world mutates state then records;
   it is not an implemented event-sourced persistent database. `_record` assigns
   sequential IDs, parents update books, and hooks can synchronously emit or amend
   records. Snapshot equality alone misses learning state outside native snapshots.
   Byte parity must include events/IDs/order, reports and legitimate views, plus
   decision-relevant sidecars. No async listeners or reordered “equivalent” receipts.
8. **Independent reconstruction stays independent.** Native spatial audit and Python
   finance/physical/contract/information audits reconstruct copies from receipts.
   They must not call a new production access helper to decide whether its own
   output is valid. Unknown successful events remain failures. Hashes and aggregate
   conservation supplement, rather than replace, reconstruction.

## Three future creation-time profiles and eventual reunification

These are **proposed profiles**, absent from the current CLI. Choose a profile and
its complete assumptions at construction and bind them to experiment metadata.
No live switch may change custody, attendance or an NPC's knowledge mid-world.

| Concern | Integrated existing world | Economic laboratory | Physical/crime laboratory |
| --- | --- | --- | --- |
| Common authority | Existing accounts, IDs, ownership, holdings, quotes, atomic payments/purchases, recipes, labor/claims and event order | Same economic validators and single holding registry; explicit scenario configuration | Same identity/ownership/holding and atomic transfer rules; small fixed initial stocks/accounts |
| Physical assumptions | Existing routes, tiles, hours, cargo, deposits, attendance and encounter permissions | First a deterministic **logistics witness** fixture with explicit pickup/delivery times and access evidence; any later zero-distance or instant-delivery mode is a named counterfactual | Real movement, possession and blocked delivery, with a fixed/minimal economy so those effects can be isolated |
| Work and wages | Verified on-site timed activities and current funding rules | Real attendance if employed labor is included. A fixed exogenous attendance/production trace is prescribed input, not discovered behavior; never pay merely for scheduling a plan | Prefer no new production/employment initially; if included, use the same validated attendance and claims machinery |
| NPC information | Current personally inspected offers/notices, own receipts and local witnesses | Explicit permitted offers/observations at declared times, never blanket access to all balances, hidden supplier stock or future demand | Actor-local perception evidence; custody/ownership truth remains separate from suspicion, knowledge and later legal adjudication |
| Time and events | Current five-minute ticks and nested receipt order | Initially preserve the same clock/receipt boundaries. A future sparse clock needs separate equivalence proof; it cannot silently bypass attendance or coverage ticks | Same authoritative clock and deterministic ordering for movement and economic/physical effects |
| Valid comparison | Existing historical bytes | Equivalent only for a proved subset with identical physical/input/observation consequences; otherwise label effects as changed transport/information assumptions | Controlled physical tests, not a claim of equivalence to a self-sustaining settlement |

The economic lab must declare shipment owner, holder, quantity, departure/arrival,
site access, stock available before each command, and what each observer may see.
A “delivered” flag alone cannot grant working inputs. A witness-trace replay is a
controlled exogenous fixture: validate it against current stock/capacity/ownership,
reject inconsistencies, and never fabricate a missing delivery. Reusing a trace
after policies change physical choices can invalidate it. Full parity would also
require the exact movement/encounter events; omitting them makes the trace a
counterfactual even if its financial ledger happens to match.

For a later physical/crime lab, begin with owned goods in finite containers and
actual actors. Future unauthorized-taking, recovery or destruction commands need
their own validated atomic transitions and explicit evidence, without treating
theft as a consensual priced purchase. No such crime operation or law is present
in this milestone. Co-location can supply an encounter candidate; actual LOS,
attention, uncertainty, identity attribution and legal guilt require later design.
Do not give every co-tile actor true crime knowledge or edit bank balances because
a parcel was intercepted. Money is currently an account abstraction; coins are
not physical carried inventory.

Eventual composition should retain one `World` command facade, common IDs and
holding locations, one clock, and one canonical receipt writer. Economic commands
ask physical authority for access/current custody and ask observation authority
for permitted evidence; the world validates and commits once. Physical disruptions
change actual goods availability, then purchases/work/planning encounter those
facts normally. Read-only observation builders and offline research views remain
separate. Services may own disjoint internal state under the facade, but must not
keep competing authoritative copies or independently commit the same transaction.
Existing inherited validators remain the facade until each extraction is proven.
Persistence/reload and atomic durable commit are not implemented guarantees today.

## Feasible incremental designs

Effort is relative change surface, not an estimated schedule. No option has been
prototyped or benchmarked in M32.

| Design | Concrete boundary / effort | Trade-offs, audit and performance risks |
| --- | --- | --- |
| A. Read-only physical access service behind existing methods | Start with one pure time predicate; later consider explicit queries for presence/open window. Low for leaf; medium for a complete purchase/observation gate. | Lowest event-order risk if callers keep their distinct checks and side effects. Easy isolated negative tests. A broad boolean “may buy” would lose rejection precedence and observation distinctions. Delegation may add overhead; it does not remove ticks/copies and offers no demonstrated saving. Recommended entry. |
| B. Transport/custody adapter | World-owned receiving-location selection and deposit validation, later explicit shipment proposals. Medium/high: root purchase hook, spatial cargo/visitor claims, procurement, production availability and auditors. | Enables controlled logistics laboratories but touches live dictionary write destinations, combined capacity and timing. Must preserve exactly-once receipt custody, retain real delivery consequences and independently replay all holdings. Fewer route steps could save work in a counterfactual; matching financial totals would not prove integrated equivalence. Defer. |
| C. Compositional services with unchanged `World` facade | Gradually extract economic, physical, observation and orchestration responsibilities; keep canonical commits and stable wrappers. High across inheritance/initializers/hooks and direct runner reads. | Best eventual test boundaries and shared-world integration. Highest migration risk: initialization receipts, `super` order, recursive hooks, ownership and audits. Requires incremental adapters and parity before deleting old paths. Extra copies/dispatch can cost more; no performance claim. Long-term direction, not one milestone rewrite. |

Do not put a second “economic truth” database beside spatial inventory and reconcile
it afterward. Do not override `_at()`/`_open()` to always true in a subclass, replace
`_purchase_inventory()` with warehouse access, or drop `spatial_clock` receipts to
produce a nominal mapless world. Those shortcuts simultaneously change physical
access, timing, beliefs, paid attendance and production feasibility.

## Risk register and rollback

| Risk | Mitigation / stop condition |
| --- | --- |
| Nested callbacks change `_events.back()` linkage or observation state | Keep callbacks in place; compare full event bytes and provenance. Any unexplained link/order/view drift blocks extraction. |
| Construction calls virtual methods before new services exist | Extract stateless helpers first. Capture initialize receipt and construction snapshot exactly; no delayed registration. |
| Cargo becomes warehouse stock early or is counted twice | Keep live custody mutation and capacity checks in authority; independent per-event holdings replay and before/after deposit witnesses. |
| Tick removal pays absentees or changes coverage/learning | Keep clock implementation unchanged initially. Sparse/event-driven work needs its own proof and review. |
| Abstract transport grants new information, free wages or revenue | Declare profile assumptions; reject invalid witness inputs. Do not publish the counterfactual as integrated parity. |
| Composition leaks mutable dictionaries, world references or hidden finances | Value-only query contracts, copied observations, adversarial mutation/privacy tests. No worker authority. |
| An audit imports the extracted validator and shares its bug | Keep independent formulas/reconstruction; forge receipts and require rejection after rehashing. |
| New extraction is faster only because diagnostics/receipts were omitted | Compare matched coverage and raw counts; separate run/report/audit time, disclose intentional differences. |
| Cache reuse masks changed dependencies | New simulation source is uncertain under M31 closure: force fresh captures; separately review any new attestation. |
| Persistent save/contract/knowledge migration becomes irreversible | No persistence schema migration in pilot. Revert the helper/delegation/test commit as a unit; preserve old fixtures and reports. Future saved-state migration needs a separate design. |

Historical sources, golden results and canonical schemas are rollback anchors.
Do not “fix” mismatches by updating pins, normalizing receipts, changing economic
parameters, or selectively omitting failed commands. Keep experiments opt-in and
reject an unsupported profile at creation rather than falling back silently.

## Exact proposed M33: extract only the trade-window predicate

**Question:** Can one observational query leaf move out of inherited authority
while leaving all existing physical/economic effects and agent information exact?
This pilot intentionally does not yet create an economic or crime lab.

**Code boundary (proposal only):**

- Add `scripts/sim/trade_window.gd`, a stateless `RefCounted` utility with
  `static func contains(minute: int, opens: int, closes: int) -> bool`, returning
  `minute >= opens and minute < closes`. No world, dictionary, clock, observer,
  receipt, RNG, cache, native or filesystem access; no new input validation.
- In `scripts/sim/spatial_world.gd`, add one preload and replace only the final
  comparison in `_open(seller)` at lines 250–253 with this call. Keep unknown-seller
  rejection first, dynamic `_trade()` lookup and bakery `_space.retail_close`
  selection in the world, preserving existing lookup/evaluation order. M23 uses
  inherited `_open` with its own `_trade()` hook
  ([brewery_world.gd:28](../scripts/sim/brewery_world.gd#L28)); no duplicate brewery
  policy or predicate is needed. Do not cache hours or pass the world to the helper.
- Add a small focused `tests/trade_window_tests.gd` and matching runner; register
  it in `tests/run_tests.gd`. Extend existing `tests/spatial_tests.gd` with only
  missing boundary/privacy witnesses. Reuse existing Python capture/auditors for
  parity, plus a bounded comparison driver if their entry points cannot capture
  raw state/views. Do not change independent audit formulas to import the helper.
- Add an explicit `spatial_access` development/checkpoint profile to
  `scripts/tools/verify_workflow.py` only as needed to register those checks. Do
  not label the present `wages` profile as covering a new spatial seam. Declare
  changed dependencies; existing short raw-cache attestation must fail closed.

**Flow:** existing caller → unchanged `_open(seller)` resolves current window →
pure `contains` → boolean to same caller → unchanged local validation / command /
recording. There is no new event, envelope, alternate world, live switch or changed
authority. A separate query helper is the only implementation experiment.

**Bounded primary workload:** M17 `settlement_spatial`, `control`, seed 42, one and
three days, plus one-day `late_worker` and `early_close`. Capture a reviewed-base
run and candidate run in distinct processes with the same engine/environment.
Compare raw complete reports, initialization/final snapshots, full event arrays
including IDs/order/timestamps and actual per-actor views at matched cursors.
Capture view probes without emitting canonical events, and compare to the base
as well as checking that calling them mutates nothing. No normalization is allowed
for this behavior-preserving extraction. Include learning memory/belief equality
on a small learning control to detect state outside native snapshots.

**Negative and independence witnesses:** start-inclusive/end-exclusive times;
unknown seller; bakery early-close override; same-tile versus neighboring/inactive
body; busy-but-visible offer versus rejected busy inspection; stale/malformed
quote, unauthorized courier and missing interaction context; no stock/funds,
combined cargo capacity, premature production and duplicate deposit. Exercise an
absent worker and a valid attended-standby claim through existing contract
fixtures. Reuse existing tests for these mechanisms; add only uncovered cases.
Rehash a forged opening-time/remote-purchase receipt and require the original
physical audit to reject it. This ensures helper and checker do not merely agree
on the same incorrect boundary.

**Acceptance gates:**

1. Development: focused predicate/spatial tests and independently audited M17
   one-day control plus early-close failure; unchanged original pins and raw parity.
2. Checkpoint: primary one/three-day comparisons and disruptions; representative
   M23 reference, M25 attendance/no-show fixture, M28 input-aware, M30 fixed-ten
   control and optional worker-bids one/three-day paths. Each uses its existing
   independent auditor. Learning A1 checks sidecar equality; do not rerun the whole
   numerical learning matrix between edits. Seeds/conditions are fixed before runs.
3. Final M33 acceptance: complete M31 17-stage path after final meaningful source
   change, plus registered pilot checks and exact observation parity not covered by
   historical pins. Historical bytes, assertions and economic parameters unchanged;
   all required fresh audits pass. A short checkpoint is not final certification.

**Rollback:** any raw receipt, state, decision sidecar or permitted-view difference;
different rejection reason/order; auditor accepting a forged physical history;
unexplained dependency/cache acceptance; or need to alter custody/scheduling/kernel
to finish this pilot means revert and report the blocker. For timing, investigate
the existing smoke warning thresholds, then repeat matched pairs; retain no
material reproducible overhead without an explicit reviewed trade-off. No
predefined percentage is a license to accept incorrect behavior.

**Non-goals:** alternative lab execution, transport abstraction, removal of ticks,
new observation access, cargo representation, event bus or schema, crime law,
policy/price/wage changes, Rust migration, memory feature, universal contract
framework, performance claim, or persistent-save conversion. Do not enlarge the
pilot just to demonstrate a visible speed gain.

## Performance evidence and proposed measurement protocol

Existing measurements describe different workloads; none measures the proposed
separation or establishes current M30 spatial cost.

| Evidence | What it supports / what it cannot establish |
| --- | --- |
| [M19](M19_RESULTS.md), profiled C/D30 | Before optimization, exclusive clock/movement/deposit **1.279/1.243 s**, logging **0.738/0.795 s**, state copying **0.580/0.658 s**, transactions plus spatial purchase wrapper **0.054/0.060 s**. D continuation alone was **19.229/42.272 s** of profiled run time; math was a measured hotspot. These are M18 workloads/coarse scopes, not removable spatial overhead or a modern M30 profile. Inclusive nested times cannot be summed. |
| M19 run/report distinction | D30 unprofiled run medians **45.310→36.915 s** after numerical reuse; native report audit roughly **5–6 s** outside `run()`. A30 event count **27,331**. Logging, full copies and reports matter, but suppressing them would change evidence. Old nonspatial M16 versus spatial M17 is not a matched abstraction benchmark. |
| [M22](M22_RESULTS.md) | Independent synthetic 100-job D15 batches took median **7.883/5.137/5.887 s** with 1/2/4 workers on a two-CPU quota. Main callback p99 **3.435/5.519/36.815 ms** did not remove head-of-line logical ordering; outliers remained. This does not establish live 100-NPC scale, physical world progress during a barrier, or rendered responsiveness. |
| [M31](M31_RESULTS.md) | Matched fresh/reused wages development medians **6.838→2.407 s**, checkpoint **38.265→25.565 s** retained independent audits with cached native probe data. This reduces verification command time, not simulation execution cost. Legacy/tier comparisons differed in coverage. |
| Accepted M31 CI job log | Its full wrapper reports **2319.230 s command time**, 17 stages passed. This is that CI command, not a current-host simulation benchmark, predicted M33 duration, or total Codex work. No installation/reading/editing time is inferred. |

For M33, first measure unchanged-base versus helper candidate on the primary
one/three-day controls; a 30-day control is an after-checkpoint measurement, not
an edit loop. Use three alternating fresh-process pairs after an unmeasured
one-day warm-up, same Godot binary/version, platform, CPU quota, build/backend,
seed, policy, initial resources and inputs. Keep verification jobs idle during
timings; retain all samples and report medians/ranges. Separate instrumentation
runs from uninstrumented wall comparisons. A one-day decision is not a p99 sample.

Record command wall, initialization, `run()`, snapshots/history copies,
native-report audit, JSON, independent Python audit, and peak child RSS separately.
Use existing M19 scopes and M31 summaries where supported; unsupported modern
runner instrumentation is a measurement gap, not a zero cost. Proposed counters:
five-minute ticks and processed presences, route steps, activity completions,
inspections, purchases/rejections, deposits/cargo movements, claim/payment events,
canonical event count/bytes, full copy count/bytes, math jobs and barrier delays.
Keep counters/timings outside snapshots/decisions/receipts. Do not instrument every
arithmetic operation or add inclusive and exclusive costs twice.

For a **later separately approved abstract-lab prototype**, predeclare integrated
control versus logistics-witness prototype at 1/3/30 days, seed 42, three matched
pairs, and fixed economic policies/inputs. First certify each mode independently.
Only classify a case equivalent if its complete economic consequences, holdings,
claims, ordering and authorized observations match; full integrated parity also
requires full raw receipt/state equality. Deliberately omitted physical histories
must be reported as such, never hidden by a “canonical economic” normalizer.
Compare event/work counts alongside time so less verification or different work
cannot masquerade as a faster implementation. If policies/physical feasibility
diverge, report both outcomes and timing as a counterfactual comparison, without
attributing a speedup to equivalent modularization.

M31 already provides `development`, `checkpoint`, `full` and wages/inputs/contracts/
queue/workflow profiles ([verify_workflow.py:20](../scripts/tools/verify_workflow.py#L20)).
Its source closure deliberately treats new simulation code as uncertain
([verify_workflow.py:93](../scripts/tools/verify_workflow.py#L93)). A future profile
must add spatial access, per-agent view parity, custody/attendance negatives and
mode-specific independent audits; do not silently rely on the wage smoke. Reuse
immutable data only with reviewed source/engine/build/input/output dependencies,
and rerun independent reconstruction. No M32 cache receipts or timings were created.

Manageable later stage gates: (A) one pure integrated extraction; (B) an explicitly
configured access-view adapter with unchanged physical effects; (C) one commodity
shipment/custody fixture independently audited; (D) a counterfactual economic lab
with all transport/attendance/knowledge assumptions declared; (E) a minimal
physical lab using the same holdings; (F) combined-world interference tests.
Each gate needs review before expanding. The M33 proposal is gate A only.

## False parity traps, open questions and limits

- Same final money/meals can hide reversed sellers, late pay, absentee wages,
  premature inputs, contradictory visitor custody, changed failed commands or
  leaked private observations. Compare complete state, receipts and permitted views.
- Removing ticks changes coverage and attendance even when routes are short.
  Removing encounter receipts changes learning. Stripping IDs then remapping them
  can conceal altered causality; the M30 historical passive-event normalizer is
  not authorization to normalize a behavior-preserving M33 extraction.
- `snapshot()` is not a complete persistence/knowledge contract. Learning sidecars,
  runner state, RNG state and execution tokens need explicit future treatment.
  No save/reload equivalence is established by this audit.
- Account money is abstract; physical commodity cargo has one holder per business.
  Physical coins, splitting parcels among carriers, loss/theft attribution and
  durable atomic writes are not solved services waiting to be switched on.
- The current protected-field access and virtual construction require incremental
  migration. Whether a complete observation gate can preserve all branch-specific
  rejection precedence and learning semantics remains untested.
- There is no current measured M30 breakdown of route, hook, copying and audit
  cost sufficient to forecast a spatial-separation speedup. Pure helper delegation
  could be slower. Generalizing the profiler or removing ticks is separate work.
- No blocker requires user clarification to finish M32. Broader composition and
  laboratory implementation remain conditional on pilot evidence and review.

## Work performed, checks and stop decision

Read issue #48 in full, `AGENTS.md`, `README.md`, design/architecture/roadmap,
M17/M19/M31 results and performance guidance; inspected related M22 evidence,
world/runner hierarchies, core validators, event overrides, observation/contract
paths, native ABI/worker handoff and independent auditors. Used `rg`, `nl`/`sed`,
`git log`, `git diff`, GitHub run/job metadata and job logs. No Godot process,
economic experiment, native build or full acceptance command was executed.

Changed files: this report and a minimal M32 navigation entry in
`docs/ROADMAP.md`. No historical report, source, test, kernel, fixture, pin, event
schema, CI, initial resource or parameter was edited.

Low-cost checks performed: `git diff --check`; static validation of 142 local
Markdown targets and 123 unique cited source-line locations; exact verification
of 48 world/runner parent declarations and the 17 coupling rows; comparison of
accepted CI checkout source with starting `main`;
documentation-only path allowlist and unchanged tracked implementation bytes
against that baseline. These are documentation/source checks, not new economic
certification. No performance improvement or prototype correctness is claimed.

**Go:** documentation review and, if separately authorized, the single M33
trade-window extraction. **No-go:** whole-world refactor, implicit mapless mode,
custody/scheduler extraction, or economic-baseline adoption on present evidence.
M32 stops here; M33 has not begun.
