# M17 — Headless spatial town and scheduling

Implements [issue #19](https://github.com/anoy-maker/simulated-town-rpg/issues/19), based on M16 commit `5fa1246fdf03aef9af44f9c791236b8b018bf769`. No historical branch, configuration or result is replaced.

## Choices fixed before experiments

Use the exact M15/M16-A twelve residents, three businesses, owners, original contracts (six coins/shift, two guaranteed shifts/three days plus prescribed daily additional work), assets, recipes, empty stocks, fixed 2/4/4 prices, 432 village + 8760 external coins, six daily visitor intentions and existing earnings distributions. No economic parameters, staffing or productive resources change.

The 10×7 grid has no obstacles, collisions or occupancy limits. Movement is one orthogonal tile per five simulated minutes, x-coordinate first then y. Simultaneous steps/completions use sorted presence IDs. Time is authoritative, independent of rendering. All residents initially spawn at home; there are no subsequent position resets. Shared free housing has no property/rent economy.

| Home | Residents, sorted ID groups of four |
|---|---|
| (1,1) | Ada, Bram, Cora, Dain |
| (1,3) | Edda, Finn, Gale, Hale |
| (1,5) | Iona, Jory, Kira, Lyle |

Farm (6,1), mill (6,3), bakery (8,3), visitor gate (9,3). Every resident has authoritative tile/home/destination/activity, route, working appointment and prescribed schedule. One hour of actual presence is required for a productive shift; payroll/recipe execution occurs only on completion. Owners manage without wages. Walking, work/management and shopping appointments cannot overlap for an individual.

| Time | Prescribed operation / route |
|---|---|
| 08:00 | All residents leave home. Workers go to their employer; Ada goes to farm, Bram to farm to procure wheat, Cora to mill to procure flour. Longest initial commute: 45 minutes. |
| 09:00–10:00 | Three farm employee shifts; Ada manages on site. Output appears through real completed shifts at 10:00. |
| 10:10 | Bram buys three four-wheat lots at farm, using mill funds. Goods enter mill-owned custody carried by Bram. |
| 10:15–10:25 | Bram walks farm→mill; deposits actual cargo at mill at 10:25, with a five-minute unloading appointment before work. Farm trade hours 10:00–11:00. |
| 11:00–12:00 | Three mill employee shifts; Bram manages on site. |
| 12:10 | Cora buys three four-flour lots at mill with bakery funds. Mill trade hours 12:00–13:00. |
| 12:15–12:25 | Cora walks mill→bakery and deposits bakery-owned cargo at 12:25, with a five-minute unloading appointment. |
| 14:00–15:00 | Three bakery employee shifts; Cora manages on site. |
| 15:30 | Residents commute to bakery for shopping; Cora remains there. Longest workplace→bakery trip: 20 minutes. |
| 16:00–16:05 | Resident food shopping in sorted ID order, at bakery. Retail hours 15:00–17:15, end exclusive. |
| 17:00–17:05 | Six temporary visitor presences enter at gate and walk to bakery. Each references the single finite `visitors` account and can acquire at most one loaf. |
| 17:05–17:10 | Six separate visitor shopping requests, sorted presence ID. Private six-coin ceiling stays with the buyer. |
| 17:10 | Visitors consume their own purchased bread; no new household needs or money accounts. |
| 17:10–17:15 | Visitors walk back to gate and exit; no teleportation. |
| 17:15–18:00 | Residents return home; longest return: 45 minutes. |
| 18:30 | Each resident consumes one actual owned bread at home and rests. |
| 19:00 | Genuine business distributions and contract closure. |

Purchases require physical buyer/courier presence at the seller, valid current quotes, trade hours and an available individual. Shop interactions occupy five minutes. Native business purchases redirect only their goods destination to an audited transit container; funds remain business funds. Deposits move existing goods from courier custody to warehouse without another payment or new production. Transit goods cannot feed production until deposited. Resident inventories travel with their owner. Each visitor's loaf is a custody claim against the shared external inventory, counted once.

Control A: 1/3/30 days seed 42, twice each, plus split 1+2 and 3+27 replay. Compare actual accounts, goods, meals, shifts, contracts and distributions with M15 and M16 A. Preserve all historical pinned outputs including M15 365 days and the M16 competition fixture.

Two separate one-day, seed-42 disruptions, declared before runs: `late_worker` changes only Dain's home departure from 08:00 to 09:00 (missing the 09:00 farm start); `early_close` changes only bakery retail closing from 17:15 to 16:00, so scheduled local and visitor requests occur after closure. No catch-up shifts, replacement worker, free inputs, remote sales or subsidy repairs consequences.

Encounters distinguish physical arrival, on-site inspection, completed purchase, visible no-purchase and closed-shop attempt. Public encounter records list only co-located potential witnesses; Cora learns no remote visits, private balances/ceilings or hidden intentions. A no-arrival produces no bakery encounter. This is an observation foundation, not a learned memory or pricing policy.

## Actual results and verification

### Feasible control A: parity established

All controls ran with seed **42**, twice in independent processes. Actual transactions reproduce M15 and M16-A, including complete final economic state, **every per-account flow/count**, commodity totals, successful purchases, wages, ownership income, business activity, minimum obligations and distributions. No balance/inventory resets establish this equality. New location/time/encounter receipts intentionally produce different ledger fingerprints.

| Days | Resident meals / missed | Visitor loaves | Paid shifts / wages | Owner distributions | Breaches | Village / external / combined money | Actual steps |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 12 / 0 | 6 | 9 / 54 | 18 | 0 | 456 / 8736 / 9192 | 220 |
| 3 | 36 / 0 | 18 | 27 / 162 | 54 | 0 | 504 / 8688 / 9192 | 660 |
| 30 | 360 / 0 | 180 | 270 / 1620 | 540 | 0 | 1152 / 8040 / 9192 | 6600 |

At 30 days each resident holds **66 coins**, eats thirty meals and finishes at their assigned home. Each of nine employees completes thirty actual hour-long productive shifts and receives 180 wage coins; the three owners complete management/courier tasks but receive **zero productive wages** and 180 each in ownership income. Every resident spends 120 on food. Each business returns to 120 daily; no commodity inventory or cargo remains. Production is **360 wheat, 360 flour, 540 bread**, with 360 local and 180 external bread consumed. The 180 temporary visitors all leave through the gate; there are still only **sixteen financial entities**, including the single shared external account.

| Business, 30 days | Sales | Input spending | Payroll | Owner distributions | Closing cash |
|---|---:|---:|---:|---:|---:|
| Farm | 720 | 0 | 540 | 180 | 120 |
| Mill | 1440 | 720 | 540 | 180 | 120 |
| Bakery | 2160 | 1440 | 540 | 180 | 120 |

Each day contains **208 resident steps plus twelve visitor steps**. Finn and Hale travel seventy minutes/day; each other resident travels ninety. These are person-minutes of concurrent travel, not added town-clock duration or paid labor. Thirty days transport **360 wheat and 360 flour** in actual owner custody, with 720 units purchased into cargo and exactly 720 deposited. Neither couriers’ private inventories nor warehouse inventories include those goods while in transit. The 30-day control makes **720 successful purchases**, zero rejected purchases and 6480 gross monetary circulation, matching the references. Its complete ledger has **27331 events**; compact JSON is **109109 bytes**, without events. No annual spatial event dump was generated.

### C: isolated, one-day spatial disruptions

Both fixtures preserve the exact initial economic holdings, original schedules except the stated parameter, policies, prices, production recipes and accounting authority. Both replay independently and conserve **9192** coins at every event.

| Case, day 1 seed 42 | Sole changed parameter | Meals / missed | Visitors sold | Actual shifts / wages | Distributions | Breaches | Produced wheat/flour/bread |
|---|---|---:|---:|---:|---:|---:|---:|
| Control | none | 12 / 0 | 6 | 9 / 54 | 18 | 0 | 12 / 12 / 18 |
| Late worker | Dain departs home at 09:00 | 12 / 0 | 0 | 6 / 36 | 12 | 3 | 8 / 8 / 12 |
| Early close | bakery closes at 16:00 | 0 / 12 | 0 | 9 / 54 | 12 | 0 | 12 / 12 / 18 |

**Late worker causal chain:** Dain departs at 09:00, when his farm shift must start. His request is rejected while absent/walking; his actual arrival is 09:25. There is no catch-up or substitution. Edda/Gale complete only eight wheat at 10:00. Bram can buy/deposit only eight rather than twelve. Three mill shifts are attempted under the original non-reserving offer authority, but Lyle’s completion lacks inputs after the first two genuine batches. Only eight flour reaches the bakery; Kira’s corresponding attempt also lacks inputs. Neither failed productive attempt gets wages or goods. Dain, Lyle and Kira each retain the already-due contractual breach. Twelve bread feed the residents, leaving none for the six visitors who actually arrive and inspect. Their visible no-purchase encounters are genuine; nobody secretly adds stock or a replacement customer.

All businesses close at 120; each owner receives four rather than six. Dain/Lyle/Kira finish with **two coins**, the six paid workers with **eight**, and the owners with **six**. Village/external money remains **432/8760**. Sixteen actual commodity units are transported, deposited once and consumed by dependent recipes. Walking still totals 220 steps: a late commute does not become shorter or instantaneous.

**Early-close causal chain:** all nine hour-long shifts complete and produce eighteen bread. The bakery closes at 16:00, before the residents’ fixed 16:00 transaction attempts (closing is end-exclusive). They may already be waiting there; they do not invent an earlier purchase or change their prescribed appointment. Six visitors subsequently enter at 17:00, arrive at 17:05 and also encounter a closed shop. All eighteen requests are rejected by spatial authority before a quote purchase can execute. The twelve home meal attempts fail. The bakery retains **eighteen unsold bread and 54 coins**, with no ownership payout; farm/mill retain 120 and distribute six each from real upstream trade. Every resident except Cora finishes with twelve coins; Cora holds six. Money in a household is not proof that food was physically accessible. Village/external money is again **432/8760**.

The early-close fixture has **eighteen location/time-gated retail rejections**, distinct from rejected atomic purchases. Only six successful upstream input purchases occur; no invalid retail transfer is submitted after spatial validation fails. There are zero contractual breaches because all actual productive labor was paid. The one-day fixtures do not claim long-run stability or recovery; no economic parameter is tuned to compensate.

### Observation foundation

Arrival, inspection and purchase are distinct events. A co-located customer with no eligible offer produces a visible `declined` (no-purchase) encounter; it does **not** reveal a private reason, balance or willingness-to-pay. A closed-shop attempt is a different event and exposes no offer inspection. A visitor who enters and leaves at the gate without reaching the bakery produces **no bakery encounter**. Filtered market requests are not automatically projected as seller-visible refusals; partial wholesale procurement, for example, exposes the actual aggregate transfer rather than fabricating a refusal for each internal unmet lot.

Potential witnesses are computed from actual active co-location at each event. Simultaneous movement is serialized in stable ID order at the same five-minute timestamp; witness sets use that event order, with no assumed sight across neighboring tiles or future arrivals. In the control, Cora personally witnesses **fifteen bakery arrival encounters and eighteen inspections/purchases per day**. Earlier baker-employee arrivals happen while she is elsewhere; they are not retroactively disclosed. In the late-worker fixture she sees six actual visitor no-purchases; in early-close she sees eighteen closed attempts and no retail inspections. The off-site test moves Cora home and proves she receives no later shop inspection/decline observation.

`observe()` exposes the actor’s own funds/inventory/schedule, nearby IDs, on-site open offers, public jobs and only personally witnessed encounters. Public encounter payloads contain kind, commodity, actual quantity, tile and potential witnesses; no customer finances, private six-coin ceiling or hidden request list. Administrative full traces remain world truth for auditing, not agent context. This milestone adds no belief update, remembered demand estimate, value-of-information policy or price learning.

### Architecture and compatibility

- `spatial_config.gd` stores map, homes, shared housing, work/trade times and each resident’s fixed schedule, including owner courier appointments.
- `spatial_world.gd` validates movement, global five-minute clock progression, non-overlapping activities, completed on-site work, trade hours, buyer/courier presence, physical deposit, home consumption, gate entry/exit and witness projections. An inherited unpaid-owner-production path is explicitly disabled in this employee-only reference. Premature day advance and aggregate remote visitor consumption are rejected.
- `spatial_runner.gd` dispatches the fixed schedule; it never edits money or goods. Three employee shifts run in parallel per workplace and settle only after their actual hour. Transactions occupy five-minute appointments; goods change ownership/custody at the transaction timestamp, and the actor remains busy until the appointment ends. Warehouse deposit records actual arrival, not remote delivery. Ownership distributions remain inherited account bookkeeping at 19:00, not a new physical-money transport system.
- A small protected `_purchase_inventory()` hook in the existing kernel chooses the receiving inventory **before** native purchase validation/writes. Its historical default is unchanged. M17 directs business purchases to business-owned, owner-held cargo; the original atomic operation still transfers existing money and stock. No new monetary account, parallel purchase implementation or free goods are introduced.
- `spatial_audit.gd` uses the existing enterprise receipt audit with an optional observer that reconstructs physical state. The shared audit independently handles cargo destinations/deposits; the observer checks every timestamp, step, appointment, transaction location, visitor alias and witness set, plus global commodity conservation including cargo **after every event**. Full final snapshots must match. Historical default audit results remain unchanged.
- The independent Python `spatial_audit.py` combines existing finance/commodity/quote/asset/payroll reconstruction with a separate physical replay. Both auditors reject forged teleports, custody and witnesses. `spatial_report.gd` projects compact day/resident/witness counts after execution; no report supplies decisions.

The new scenario is `settlement_spatial`; the existing CLI/default M0 and all historical configurations/runners stay unchanged. The M16 adaptive collapse remains an unchanged historical finding. No kernel rewrite, new productive resources, dynamic economic policy or rendering system was needed.

### Verification

- **Godot 4.6.3: 3005 checks, zero failures** — all 2932 historical checks plus 73 focused M17 checks. The focused 73 were also rerun after courier appointments were made explicit in each resident’s stored schedule; times, routes and economic behavior stayed unchanged.
- **Python full suite: 51 tests passed** — all 44 historical plus seven M17 tests. The seven were rerun after the schedule projection refinement.
- **152 historical payload comparisons passed:** 151 published comparisons through M16 (139 through M15 plus twelve M16 stage summaries/full-ledger fingerprints), and M16’s complete competition-fixture trace compared byte-for-byte against a detached worktree at original commit `5fa1246`. Its SHA-256 is `343e25cb82af654d027c30306e1cef966391020c87c56845e9072208dfec17eb`. The original M0 30-day seed-42 hash and the M15 365-day reference remain unchanged. No old artifacts were rewritten.
- All five experiments ran twice in independent processes with byte-identical command/report output and complete-ledger fingerprints. Each full trace was independently audited **in memory**, not exported. Native tests additionally compare exact **1+2 versus 3** and **3+27 versus 30** state, ledger, report and timestamp replay, and matched M15/M16-A accounting.
- Focused failures cover remote purchase/work, insufficient travel time, malformed/out-of-bounds/non-adjacent movement, step budget, invalid/backward clocks, unauthorized courier, production before deposit, repeated deposit, after-hours/wrong-tile buying, overlapping appointments, premature work/day completion, external-account meal misuse and off-site inspection. Failed commands are compared against complete snapshots; rejection receipts may be appended. Housing, shopping order, simultaneous arrivals, real return-home routes and distinct funded visitor intentions are checked explicitly.
- Two preflight assertion failures were corrected: the movement count originally included rejected movement receipts, and the cargo-corruption assertion initially targeted total conservation rather than the correct negative-custody/bounded-holdings violation. No reference parameters or economic outcomes were changed. Final tests pass.

Editor import completed without script errors. All five published compact-summary/ledger fingerprints, artifact row counts, unchanged economic results after schedule projection, seven-line readable CLI reports, invalid case/scenario/fixture argument rejection, final M0 hash and `git diff --check` passed. **No final test failures or blocked verification.** No adaptive economic behavior or graphical system was added.

Five run rows/fingerprints are in [M17_RUNS.csv](M17_RUNS.csv); [M17_DAYS.csv](M17_DAYS.csv) has **32** daily rows (30-day control plus two one-day disruptions), [M17_RESIDENTS.csv](M17_RESIDENTS.csv) has **36** resident rows, and [M17_BUSINESSES.csv](M17_BUSINESSES.csv) has **nine** business rows. Control 1/3-day summaries remain reproducible from the commands. Final private positions, owned cargo and temporary visitor records are also included in the compact JSON snapshot.

```sh
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 3 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial --spatial-case late_worker 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial --spatial-case early_close 1 42
python3 -B scripts/tools/run_spatial.py --output work/m17
# Compact output, no events:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 30 42 --report-json
# Opt-in short event trace with actual timestamps/custody/witnesses:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_spatial 1 42 --json
```

### Limits and stop

This is feasibility under prescribed decisions, not autonomous spatial planning or equilibrium discovery. Routes have no obstacles, congestion, fatigue, carrying weight, rent or travel cost; shared tiles have unlimited occupancy. Posted offers execute for an authorized on-site buyer without adding a separate cashier/service-capacity economic system. Witnesses indicate possible co-located observation, not attention or a learned memory. There are no remote sightings or assumed knowledge of future customers. Busy intervals are not resource escrow: independently validated work can fail at completion if an earlier genuine shift used its inputs, as the late-worker fixture demonstrates.

Courier procurement still attempts the original three four-unit lots. It is grouped before dependent industry work to make physical delivery possible, retaining the original purchase counts/quantities/money flows. Business money remains an abstract account balance; only commodity custody is spatially transported. The reference demonstrates that this ordering fits the chosen map and hours; it does not claim all towns, queues, shift lengths or shocks would fit. Disruptions preserve failure instead of adapting schedules or economics. Inactive visitor presences remain at the gate in snapshots for audit, so history/state storage grows with days. Snapshot reload/persistence, route optimization, perception beyond the tile and more detailed service/cargo throughput are deferred.

**Stop after M17 for review. No M18 memory/value-of-information pricing, economic calibration, new industries, staffing/investment decisions or graphics.**
