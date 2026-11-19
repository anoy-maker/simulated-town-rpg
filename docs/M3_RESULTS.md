# M3 — Needs and Decisions: actual results

M3 adds the separately selected `agents` scenario. Policies choose economic actions from their own state and public offers; the world executes validated commands. The same fixed policy and goals were used for all reported runs. They were not adjusted to improve the observed economy. M0 and M2 regression outputs remain unchanged. No subsequent milestone has started.

## Assumptions and separation of concerns

**Unchanged economic parameters:** Ada/Bram/Cora/Dain start with 30/20/20/5 coins and one bread each, with no wheat/flour. Prices remain wheat 1, flour 2, bread 3. Ada attempts the same two-coin daily payment before sales. Recipes remain two wheat → two flour and two flour → three bread. Harvest opportunities remain 2–6 wheat from the same daily seed-42 sequence; one RNG draw is taken every day even if harvest is not selected. Currency remains 75 coins; no rescue, debt, subsidies, price changes, or extra resources were introduced.

**Goals/priorities:** `npc_policy.gd` declares food target 1, output targets farmer wheat 4 / miller flour 4 / baker bread 6, max two recipe batches per work turn, and a food-money reservation priority. Non-bakers reserve the cost of their missing food target before spending on production inputs. Cora instead buys ingredients for her own food production; she does not reserve coins to buy from herself. Constructor-supplied goals are copied and validated; the reported runs use the defaults without modification.

**Information:** `AgentWorld.observe()` supplies only the actor's ID, occupation, money, inventory, day, daily meal need, and explicitly public seller/item/price/stock offers. Ada's wheat, Bram's flour, and Cora's bread are advertised as available stock. Other balances, unadvertised inventory, goals, and global event history are not supplied. The policy receives dictionaries, not a world reference. Tests show that changing other NPCs' private money/inventory cannot change an observation. Policies run as trusted GDScript code with restricted input data.

**Decisions:** `Policy.decide(observation, goals, phase)` is pure and returns an action plus reason. Food orders cover only missing target stock and are limited by funds and advertised supply. Input orders cover production requirements after owned inputs, advertised supply, and available budget. Production uses only actual inputs and the number of whole batches needed toward the output target. Farmer harvest stops at/above the wheat target. Whole harvests/recipe batches may overshoot targets; further turns then wait. Existing stock prevents redundant purchases or work.

**Authority:** `AgentWorld.execute_decision()` validates the phase/action allowlist, fixed market offer, and acting account, then uses existing `purchase`, `produce`, `harvest`, or `consume`. It revalidates actual funds/stock/roles/recipes/capacity even if an observation was stale. The environment supplies harvest quantity; a proposal cannot invent a larger yield. Waits have no economic command. The original M0/M1 world and M2 runner are unchanged.

**Needs:** each NPC needs one meal per day. Observations derive whether it remains due from that actor's successful consumption events on the current day. The agents executor rejects a duplicate meal even when food remains. Needs reset daily without cumulative hunger debt, health penalties, or death. Eating still attempts to consume one actual bread even if food is unavailable, retaining explicit unmet-meal accounting. There is no second meal opportunity or repeated shopping/replanning loop within a phase.

## Fixed daily schedule and decision log

1. Advance the day; Ada attempts the unchanged employer payment.
2. Draw the day's harvest opportunity. Ada chooses harvest or wait from her stock and target.
3. Bram chooses an input purchase or wait, then production or wait, with fresh observations.
4. Cora chooses an input purchase or wait, then production or wait, with fresh observations.
5. Ada, Bram, Cora, and Dain choose a food purchase or wait. Cora has no external bread seller.
6. Ada, Bram, Cora, and Dain choose their daily consumption action.

There are 13 opportunities per day: Ada 3, Bram 4, Cora 4, Dain 2. The employer payment is an unchanged scenario rule, not an agent decision.

Every opportunity records a structured `decision` event with actor, phase, selected action, policy reason, outcome (`executed`, `rejected`, `wait`), execution failure reason, and the exact command event ID where present. A decision event annotates execution and never changes inventory or money. Failed commands and their rejected-decision annotations both remain in the raw ledger. Reports count the economic failure once and list decision outcomes separately. A wait for affordability/supply is not a rejected purchase.

## Actual economic comparison, seed 42

| Measure | M2: 30 days | Agents: 30 days | M2: 365 days | Agents: 365 days |
| --- | ---: | ---: | ---: | ---: |
| Successful purchases | 137 | 101 | 1544 | 101 |
| Rejected purchase attempts | 13 | 0 | 281 | 0 |
| Wheat harvested | 122 | 61 | 1470 | 61 |
| Flour produced | 116 | 56 | 1448 | 56 |
| Bread produced | 174 | 84 | 1938 | 84 |
| Bread consumed | 110 | 88 | 1226 | 88 |
| Unmet meals | 10 | 32 | 234 | 1372 |
| Successful employer payments | 27 | 22 | 194 | 22 |
| Rejected employer payments | 3 | 8 | 171 | 343 |
| Total coins | 75 | 75 | 75 | 75 |

All 101 agents purchases succeed because the policy replaces known unavailable/unaffordable orders with waits. Spending and production stop, and unmet meals are much worse.

Agents' economic holdings and cash flows are identical at day 30 and day 365; only missed meals and failed payments/decision counts continue accumulating:

| NPC | Final coins | Earned | Spent | Wheat | Flour | Bread | Unmet: 30 days | Unmet: 365 days |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ada | 0 | 56 | 86 | 5 | 0 | 0 | 15 | 350 |
| Bram | 1 | 112 | 131 | 0 | 0 | 0 | 4 | 339 |
| Cora | 73 | 165 | 112 | 0 | 0 | 0 | 0 | 335 |
| Dain | 1 | 44 | 48 | 0 | 0 | 0 | 13 | 348 |

Ada's spending is 44 coins of payments and 42 for bread; her earnings are wheat sales. Bram spends 56 on wheat and 75 on bread, earning 112 from flour. Cora spends 112 on flour and earns 165 from bread. Dain earns 44 from payments and spends 48 on bread. Every balance equals initial + earned − spent. For comparison, M2's day-365 balances are 1/61/13/0, with 22 wheat, 156 flour, and 716 total bread.

## Purchases, production, and reconciliation

The following agents totals are unchanged between the two horizons:

| Commodity | Successful purchase commands | Quantity traded | Coins paid |
| --- | ---: | ---: | ---: |
| Wheat | 23 | 56 | 56 |
| Flour | 23 | 56 | 112 |
| Bread | 55 | 55 | 165 |

Orders can be smaller than M2's unconditional four-unit orders. Actual production consumes 56 wheat → 56 flour, then 56 flour → 84 bread. All 88 bread available (four initial + 84 produced) are eaten. Final stocks reconcile to five wheat (61 − 56), zero flour (56 − 56), and zero bread (4 + 84 − 88). At 365 days, 88 meals eaten + 1372 unmet = 1460 required meals. There are no failed input purchases or production commands in these agents runs: unmet prerequisites lead to waits rather than invalid commands.

## Decisions and the observed stall

| Decision measure | 30 days | 365 days |
| --- | ---: | ---: |
| Total opportunities | 390 | 4745 |
| Executed actions | 249 | 249 |
| Rejected actions | 32 | 1372 |
| Waits | 109 | 3124 |
| Selected harvests | 15 | 15 |
| Selected production commands | 45 | 45 |
| Selected purchases | 101 | 101 |
| Selected consumption attempts | 120 | 1460 |
| Wait: food already covered | 33 | 33 |
| Wait: output target met | 25 | 360 |
| Wait: unaffordable with priorities | 37 | 372 |
| Wait: market unavailable | 4 | 1679 |
| Wait: missing production inputs | 10 | 680 |

Decision annotations raise the raw event counts to 732 and 7097. Rejected decisions are failed eating attempts in these runs. Separate economic failures are 32/1372 failed meals and 8/343 failed payments; rejected decision annotations are not counted as additional economic failures.

The behavioral divergence begins on day 1: all four skip food purchases because they already own today's meal. Cora therefore receives no first-day bread revenue, unlike M2. Later, output targets cap stock accumulation, ingredient orders shrink to deficits/affordable amounts, and work may use one batch instead of two. These are decision effects; prices, initial resources, recipes, wages, and daily harvest opportunities have not changed.

Ada last harvests on day 23. Bram last mills on day 25; Cora last buys flour and bakes on day 26. The final successful employer payment and bread purchases occur on day 26. From day 27, Ada waits because five wheat exceed her four-wheat target; Bram has one coin but reserves money for food, leaving no production budget; Cora has money but sees no flour offer. Ada and Dain cannot afford bread. Cora eats remaining bread through day 30 and then misses every later meal. The default policy has no investment exception, cooperation, redistribution, or replanning mechanism that would restart this chain.

This is a liquidity stall caused by the selected local priorities and inventory limits, with 73 of 75 coins concentrated in Cora's account. The ledger accounts for every coin and item. The result was left intact; no parameters, targets, priorities, or starting resources were tuned after viewing it.

## Verification

Base commit: M2 `96805e8`. Runtime: **Godot 4.6.3**. The baseline passed all 530 checks. The completed suite passed **633 checks, 0 failures**, preserving all prior checks and adding 103 focused policy/privacy/execution/replay/accounting checks. No test or script failures occurred in the M3 verification runs. Headless editor import and `git diff --check` passed.

Focused coverage demonstrates different choices under changed inventory, money, need, role, input supply, output target, configured priority, and public stock. It also verifies pure-policy nonmutation; private-fact exclusion; snapshot/proposal isolation; exact event links/outcomes; stale funds/stock revalidation; inability to spoof the paying account, change the market price, or invent harvest quantity; decision accounting without duplicate failures; same environmental opportunities; and deterministic split-run replay for both lengths. The ledger auditor reconstructs all final state from economic events while treating decisions as annotations.

Final review corrected the observation of an already-satisfied meal need and added duplicate-meal rejection. Four additional checks cover cleared needs, next-day reset, and duplicate execution. Re-running both agents simulations after that correction was byte-identical to the earlier captures, so the correction did not alter the reported economic behavior, policy, or parameters.

Actual commands used the existing writable XDG locations, from the project root:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 365 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/m3-m0-after.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 30 42 --json > /workspace/work/m3-trading-30-after.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 365 42 --json > /workspace/work/m3-trading-365-after.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 30 42 --json > /workspace/work/m3-agents-30-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 365 42 --json > /workspace/work/m3-agents-365-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 30 42 --json > /workspace/work/m3-agents-30-b.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario agents 365 42 --json > /workspace/work/m3-agents-365-b.json
cmp /workspace/work/m3-m0-before.json /workspace/work/m3-m0-after.json
cmp /workspace/work/m3-trading-30-before.json /workspace/work/m3-trading-30-after.json
cmp /workspace/work/m3-trading-365-before.json /workspace/work/m3-trading-365-after.json
cmp /workspace/work/m3-agents-30-a.json /workspace/work/m3-agents-30-b.json
cmp /workspace/work/m3-agents-365-a.json /workspace/work/m3-agents-365-b.json
sha256sum /workspace/work/m3-m0-after.json /workspace/work/m3-trading-30-after.json /workspace/work/m3-trading-365-after.json /workspace/work/m3-agents-30-a.json /workspace/work/m3-agents-365-a.json
git diff --check
```

The three pre-change captures used those same M0/M2 commands before edits. All five comparisons passed, including complete reports and event histories. The historical hashes are also pinned in automated tests:

| Scenario, seed 42 | SHA-256 |
| --- | --- |
| M0, 30 days | `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9` |
| M2 trading, 30 days | `5d569a193111d3ad5ff90dc6317b567596c4b51b4fe54c11e676e3eda0bcd9aa` |
| M2 trading, 365 days | `e564ebe6f5638be17f8cfe2b78748bbaebb7907d818a9ade1247b7624ea12278` |
| Agents, 30 days | `53ca0029214319d352453c62e637340a7ae6b2e75bc42c29504885f5c0acef82` |
| Agents, 365 days | `d8f65499e0fe1d08cebc4485d18220a20f361fef42c9abdf92193e7b720ac2b2` |

Only Godot 4.6.3 and runs through 365 days were verified. Cross-version RNG replay and persistence remain unverified. Logs remain in memory and reproducible generated artifacts are not committed. No economic failure was rescued.

## Files changed

- `scripts/sim/npc_policy.gd`: goals/priorities and pure state-dependent proposals.
- `scripts/sim/agent_world.gd`: restricted observations, validated execution, decision annotations.
- `scripts/sim/agents_runner.gd`: separate scenario, phase ordering, and decision report.
- `scripts/tools/run_simulation.gd`: `agents` selection and readable output.
- `tests/agents_tests.gd`, `tests/run_tests.gd`: new focused coverage and annotation-aware audit, preserving existing tests.
- Godot UID metadata for new scripts; `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/M3_RESULTS.md`: scope, contracts, assumptions, and actual outcomes.

M3 is complete for review. No subsequent milestone work was begun.
