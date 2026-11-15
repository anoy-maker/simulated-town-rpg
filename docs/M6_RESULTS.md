# M6 — Competing Producers and Multiple Market Participants

## Experimental contract (fixed before runs)

The separately selected `market` scenario uses commitment-first for all six NPCs. The original Ada/Bram/Cora/Dain IDs, roles, balances (30/20/20/5), and inventories (one bread, no wheat/flour each) remain unchanged. Edda (`farmer_2`) starts as a second farmer with 30 coins and one bread; Finn (`baker_2`) starts as a second baker with 20 coins and one bread. These symmetric occupation endowments add 50 coins and two bread **at initialization only**, giving 125 coins and six bread. They are not repayments, subsidies, or subsequent sources.

Prices remain wheat 1, flour 2, bread 3. Recipes, bounded inventory/money commands, goals (4 wheat / 4 flour / 6 bread; food 1; max two recipe batches), request limits, prepayment, delivery rules, and Ada's attempted daily two-coin payment to Dain remain unchanged. Edda has no wage obligation. There are exactly six participants.

Daily scheduling uses occupation order farmer → miller → baker → laborer, then ascending stable ID: Ada, Edda, Bram, Cora, Finn, Dain. First advance the day and attempt Ada's payment. Each producer gets inputs (except farmers), work, then delivery. Each farmer has a separate 2–6 wheat opportunity drawn from the single seeded RNG in that order, even if choosing to wait. Then all six receive request, acceptance, food, and meal phases in the same order; outstanding agreements are annotated at day's end. This is 37 decisions/day. There is no rotation or random priority. Earlier downstream turns can exhaust stock before later peers act; this intentional scheduling assumption must be considered in interpreting concentration.

Public observations advertise every producer's output stock (including zero), commodity, seller ID, and fixed price. They exclude other balances, unrelated inventories, and unrelated accepted agreements. The pure policy selects positive-stock offers by ascending price, descending stock, then ascending seller ID. If all stock is zero, a deterministically ranked zero-stock producer supplies the known price for request planning, not invented stock. A producer retains the existing own-output rule: it uses its own stock/production rather than buying its own output from peers. Requests are untargeted and visible to all eligible producers, who independently consider them in their turn; first valid acceptance wins. There is no stock reservation, second-supplier retry, bulk split order, or centralized allocation.

These conditions and policies were fixed before examining the six experiments: seeds **7, 42, 99**, each at **30 and 365 days**. They will not be tuned to improve outcomes. Comparisons to four-person M5 cannot establish a causal improvement from aggregate output/meal totals, because population, starting currency/food, harvest opportunities, and scheduling differ.

## Actual results

All six experiments completed without changing the fixed contract. Every run conserved all 125 coins. No rejected spot purchases or agreement lifecycle operations occurred in these runs: fresh observations led agents to wait or post requests rather than attempt unavailable/unaffordable spot orders. Economic failures were actual missed meals and Ada's unaffordable employer payments. Focused tests separately verify rejected transactions and stale competition; zero run-time rejections do not imply absence of shortages.

| Seed | Days | Harvested wheat | Flour produced | Bread produced | Meals eaten / unmet | Spot purchases success / rejected | Agreements made / fulfilled / outstanding | Open requests |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 112 | 104 | 150 | 149 / 31 | 160 / 0 | 1 / 1 / 0 | 0 |
| 7 | 365 | 650 | 642 | 960 | 962 / 1228 | 983 / 0 | 184 / 183 / 1 | 0 |
| 42 | 30 | 110 | 104 | 150 | 149 / 31 | 160 / 0 | 1 / 1 / 0 | 0 |
| 42 | 365 | 815 | 808 | 1212 | 1217 / 973 | 1045 / 0 | 267 / 266 / 1 | 1 |
| 99 | 30 | 110 | 104 | 150 | 148 / 32 | 159 / 0 | 1 / 1 / 0 | 0 |
| 99 | 365 | 818 | 808 | 1212 | 1217 / 973 | 1045 / 0 | 267 / 266 / 1 | 1 |

| Seed | Days | Spot cash paid | Prepayments | Wages paid | Wages successful / failed | Gross circulation | After day 26: spot / production / fulfillment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 551 | 8 | 46 | 23 / 7 | 605 | 16 / 8 / 0 |
| 7 | 365 | 2820 | 470 | 410 | 205 / 160 | 3700 | 839 / 508 / 182 |
| 42 | 30 | 551 | 8 | 34 | 17 / 13 | 593 | 16 / 8 / 0 |
| 42 | 365 | 3054 | 1072 | 608 | 304 / 61 | 4734 | 901 / 677 / 265 |
| 99 | 30 | 548 | 8 | 30 | 15 / 15 | 586 | 15 / 7 / 0 |
| 99 | 365 | 3054 | 1072 | 598 | 299 / 66 | 4724 | 901 / 676 / 265 |

Gross circulation sums actual spot payments, prepayments, and employer transfers. It measures repeated use of the same coins, not currency creation. Fulfillment moves goods without another charge. No waivers, refunds, automatic closures, or rescue resources occurred. All 30-day runs have production and spot purchases on day 30; all year runs have production, fulfillment, and spot purchases on day 365. There is no village-wide cessation of activity through the observed horizon.

## Final holdings, meals, and cash flow per NPC

Inventory columns are wheat/flour/bread. Earned/spent include spot trades, employer payments, and prepayments exactly once. Each row satisfies `final coins = starting coins + earned − spent`; eaten + unmet equals its run length. Unmet meals have the existing absence of health/death effects.

### 30 days

| Seed | NPC | Coins | W / F / B | Eaten | Unmet | Earned / spent |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | Ada | 1 | 4 / 0 / 0 | 24 | 6 | 86 / 115 |
| 7 | Edda | 0 | 4 / 0 / 0 | 17 | 13 | 18 / 48 |
| 7 | Bram | 29 | 0 / 4 / 0 | 30 | 0 | 200 / 191 |
| 7 | Cora | 59 | 0 / 0 / 3 | 30 | 0 | 147 / 108 |
| 7 | Finn | 36 | 0 / 0 / 4 | 30 | 0 | 108 / 92 |
| 7 | Dain | 0 | 0 / 0 / 0 | 18 | 12 | 46 / 51 |
| 42 | Ada | 1 | 2 / 0 / 0 | 22 | 8 | 68 / 97 |
| 42 | Edda | 0 | 4 / 0 / 0 | 23 | 7 | 36 / 66 |
| 42 | Bram | 29 | 0 / 4 / 0 | 30 | 0 | 200 / 191 |
| 42 | Cora | 59 | 0 / 0 / 3 | 30 | 0 | 147 / 108 |
| 42 | Finn | 36 | 0 / 0 / 4 | 30 | 0 | 108 / 92 |
| 42 | Dain | 0 | 0 / 0 / 0 | 14 | 16 | 34 / 39 |
| 99 | Ada | 2 | 2 / 0 / 0 | 19 | 11 | 56 / 84 |
| 99 | Edda | 0 | 4 / 0 / 0 | 27 | 3 | 48 / 78 |
| 99 | Bram | 29 | 0 / 4 / 0 | 30 | 0 | 200 / 191 |
| 99 | Cora | 56 | 0 / 0 / 4 | 30 | 0 | 144 / 108 |
| 99 | Finn | 36 | 0 / 0 / 4 | 30 | 0 | 108 / 92 |
| 99 | Dain | 2 | 0 / 0 / 0 | 12 | 18 | 30 / 33 |

### 365 days

| Seed | NPC | Coins | W / F / B | Eaten | Unmet | Earned / spent |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | Ada | 2 | 4 / 0 / 0 | 63 | 302 | 568 / 596 |
| 7 | Edda | 2 | 4 / 0 / 0 | 35 | 330 | 74 / 102 |
| 7 | Bram | 4 | 0 / 0 / 0 | 221 | 144 | 1286 / 1302 |
| 7 | Cora | 115 | 0 / 1 / 4 | 359 | 6 | 1047 / 952 |
| 7 | Finn | 1 | 0 / 1 / 0 | 145 | 220 | 315 / 334 |
| 7 | Dain | 1 | 0 / 0 / 0 | 139 | 226 | 410 / 414 |
| 42 | Ada | 2 | 3 / 0 / 0 | 55 | 310 | 742 / 770 |
| 42 | Edda | 0 | 4 / 0 / 0 | 33 | 332 | 66 / 96 |
| 42 | Bram | 4 | 0 / 0 / 0 | 277 | 88 | 1620 / 1636 |
| 42 | Cora | 97 | 0 / 0 / 0 | 324 | 41 | 921 / 844 |
| 42 | Finn | 21 | 0 / 0 / 1 | 323 | 42 | 777 / 776 |
| 42 | Dain | 1 | 0 / 0 / 0 | 205 | 160 | 608 / 612 |
| 99 | Ada | 2 | 6 / 0 / 0 | 53 | 312 | 726 / 754 |
| 99 | Edda | 1 | 4 / 0 / 0 | 38 | 327 | 82 / 111 |
| 99 | Bram | 4 | 0 / 0 / 0 | 277 | 88 | 1620 / 1636 |
| 99 | Cora | 100 | 0 / 0 / 0 | 323 | 42 | 924 / 844 |
| 99 | Finn | 18 | 0 / 0 / 1 | 324 | 41 | 774 / 776 |
| 99 | Dain | 0 | 0 / 0 / 0 | 202 | 163 | 598 / 603 |

## Production and sales by supplier

Sold quantities below are **spot purchases**; delivered agreement flour is listed separately. Successful sale counts are transactions, while the quantities count units. All failed-sale counts are zero in the experiments. Farmers sell wheat, Bram sells flour, and bakers sell bread. Both farmers and both bakers independently produce and make real sales. Dain produces/sells nothing under the unchanged role rules.

| Seed | Days | Supplier | Commodity | Produced | Spot units sold | Spot sale count | Spot receipts | Agreement units delivered |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | Ada | wheat | 90 | 86 | 23 | 86 | 0 |
| 7 | 30 | Edda | wheat | 22 | 18 | 5 | 18 | 0 |
| 7 | 30 | Bram | flour | 104 | 96 | 47 | 192 | 4 |
| 7 | 30 | Cora | bread | 81 | 49 | 49 | 147 | 0 |
| 7 | 30 | Finn | bread | 69 | 36 | 36 | 108 | 0 |
| 7 | 365 | Ada | wheat | 572 | 568 | 232 | 568 | 0 |
| 7 | 365 | Edda | wheat | 78 | 74 | 27 | 74 | 0 |
| 7 | 365 | Bram | flour | 642 | 408 | 270 | 816 | 234 |
| 7 | 365 | Cora | bread | 711 | 349 | 349 | 1047 | 0 |
| 7 | 365 | Finn | bread | 249 | 105 | 105 | 315 | 0 |
| 42 | 30 | Ada | wheat | 70 | 68 | 19 | 68 | 0 |
| 42 | 30 | Edda | wheat | 40 | 36 | 9 | 36 | 0 |
| 42 | 30 | Bram | flour | 104 | 96 | 47 | 192 | 4 |
| 42 | 30 | Cora | bread | 81 | 49 | 49 | 147 | 0 |
| 42 | 30 | Finn | bread | 69 | 36 | 36 | 108 | 0 |
| 42 | 365 | Ada | wheat | 745 | 742 | 325 | 742 | 0 |
| 42 | 365 | Edda | wheat | 70 | 66 | 18 | 66 | 0 |
| 42 | 365 | Bram | flour | 808 | 274 | 136 | 548 | 534 |
| 42 | 365 | Cora | bread | 630 | 307 | 307 | 921 | 0 |
| 42 | 365 | Finn | bread | 582 | 259 | 259 | 777 | 0 |
| 99 | 30 | Ada | wheat | 58 | 56 | 16 | 56 | 0 |
| 99 | 30 | Edda | wheat | 52 | 48 | 12 | 48 | 0 |
| 99 | 30 | Bram | flour | 104 | 96 | 47 | 192 | 4 |
| 99 | 30 | Cora | bread | 81 | 48 | 48 | 144 | 0 |
| 99 | 30 | Finn | bread | 69 | 36 | 36 | 108 | 0 |
| 99 | 365 | Ada | wheat | 732 | 726 | 321 | 726 | 0 |
| 99 | 365 | Edda | wheat | 86 | 82 | 22 | 82 | 0 |
| 99 | 365 | Bram | flour | 808 | 274 | 136 | 548 | 534 |
| 99 | 365 | Cora | bread | 630 | 308 | 308 | 924 | 0 |
| 99 | 365 | Finn | bread | 582 | 258 | 258 | 774 | 0 |

Each buyer's spot purchase counts by selected supplier are also available in `report.participants[actor].selected_suppliers`; its commodity volumes are `spot_bought`, while sellers' are `spot_sold`. `report.cash_flow` distinguishes sales from prepaid receipts. The full retained request records identify agreement buyers and suppliers.

The year-end supplier shares illustrate concentration: Ada sells 88.5%, 91.8%, and 89.9% of spot wheat for seeds 7/42/99; Cora sells 76.9%, 54.2%, and 54.4% of bread. Wheat buyers do not inspect cash; they compare advertised stock and IDs. Edda's last wheat sale is day 112/77/89, respectively, and she finishes with four unsold wheat. Once Ada repeatedly replenishes to at least four stock while commitment-sized wheat purchases are small, the equal-stock ID tie favors Ada. Edda stops harvesting at her output target and cannot afford bread from her remaining zero-to-two coins. This is a schedule/selection/target interaction, not a special rule favoring a named farmer; alternate schedules/tie rules were not experimentally compared.

## Agreements, competition, and bottlenecks

In every seed, Finn posts r1 on day 1 for four flour (eight coins); Bram accepts that day and delivers on day 2. Cora's earlier turn can purchase the available flour before Finn acts. Finn observes the shortfall and independently requests supply; the runner does not order Bram to cooperate. The first 30 days have only that fulfilled agreement.

All agreements in the six default runs are flour supplied by Bram. Multi-farmer and multi-baker acceptance/delivery are exercised in controlled tests, not claimed as observed default-run agreements. At one accepted obligation per supplier/commodity, competing bakers queue for a single miller. Accepted goods are neither duplicated nor reserved from unrelated spot customers; payment and actual delivery use existing authoritative transfers.

| Seed, 365 days | Buyer | Accepted | Fulfilled | Outstanding | Open | Prepaid coins | Delivered flour |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | Cora | 159 | 158 | 1 | 0 | 370 | 184 |
| 7 | Finn | 25 | 25 | 0 | 0 | 100 | 50 |
| 42 | Cora | 133 | 132 | 1 | 0 | 532 | 264 |
| 42 | Finn | 134 | 134 | 0 | 1 | 540 | 270 |
| 99 | Cora | 133 | 132 | 1 | 0 | 532 | 264 |
| 99 | Finn | 134 | 134 | 0 | 1 | 540 | 270 |

Seed 7 ends with r184, Cora's one-flour request accepted on day 365 for two coins. Seeds 42/99 end with r267, Cora's two-flour request accepted on day 365 for four coins, plus Finn's still-open r268 for two flour, posted day 365. Bram holds four coins in all three cases, knows two wheat cost two coins, and sees enough advertised wheat. These are recent horizon obligations; fulfillment after day 365 was not assumed or verified.

Shortage decisions remain visible even with zero failed spot orders. In the year runs, Cora waits for missing production inputs on 107/133/133 work turns (seeds 7/42/99), and Finn on 246/135/135. On day 99 in each seed, Finn's input decision explicitly waits with `market_unavailable` after earlier turns. Both bakers can have money while flour is unavailable; money alone does not create ingredients. Fresh observations and a fixed serial schedule reduce rejected attempts but do not eliminate competition.

Seed 7 develops a persistent individual production deadlock: Finn's last bread sale is day 150. At the horizon he has one flour, one coin, no bread, and no active request or obligation. One additional flour costs two coins, so he cannot complete a two-flour baking batch or prepay a one-flour request. He misses 220 meals while Cora holds 115 coins (92% of village currency). Existing commitment budgeting does not solve this non-obligated buyer's shortage. Seeds 42/99 keep Finn selling through day 365 and leave Cora with 97/100 coins. Neither result establishes fairness or stability. No endowments, targets, prices, priorities, or schedule were adjusted to correct these outcomes.

Compared with M5, the qualitative new evidence is competition among public sellers and buyers, supplier switching, a shared flour queue, and possible exclusion of an individual producer. Extra people, initialized money/food, and daily harvest opportunities differ from M5. The larger meal/output totals therefore are not a controlled estimate of the benefit of competition or the priority policy.

## Verification and reproducibility

Base: M5 commit `1c93279`. Runtime: **Godot 4.6.3**. The pre-change baseline passed **1024 checks, 0 failures**. The final full suite passed **1409 checks, 0 failures**, preserving all earlier checks and adding 385. New checks cover multi-supplier discovery and rankings, common occupation rules, privacy and copying, stale stock and affordability, actor/price/arithmetic authority, second-producer acceptance and real production/delivery, competing acceptances, duplicate limits, rejection reporting, cash/commodity conservation, all six ledgers, report reconciliation, split replay, farmer RNG opportunities, and all four M5 hashes. Existing tests continue pinning earlier historical outputs.

One development test run had one failed assertion in a controlled bread-delivery fixture: its three-coin prepayment could not fund the four-coin recipe the test expected to finish. The fixture was corrected to request two bread for six coins, with an explicit fulfilled-status assertion. No experimental starting conditions or behavior were changed. The corrected final suite passes. No unresolved test, import, CLI, or ledger-audit failures remain.

All **eleven** historical CLI payloads were captured before implementation and compared byte-for-byte after it. All **six** new experiment payloads were produced twice in independent processes and were byte-identical. An additional independent Python reconstruction checked every event's identity/day, nonnegative bounded holdings, conserved currency, exact final state and request receipts, supplier selections, sales, and total meals for all six captures. Readable CLI output was checked as well. Headless editor import and `git diff --check` passed.

Actual commands used the same writable XDG setup documented in README:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market 365 42
git diff --check
```

The experiment script ran serial `subprocess.run(..., check=True, capture_output=True)` commands for `--scenario market {30|365} {7|42|99} --json`, using `--headless --no-header` and asserting empty stderr. Full captures are workspace artifacts `/workspace/work/m6-market-{seed}-{days}-{a|b}.json`; summaries and audit scripts are alongside them. Historical captures use `m6-baseline-{scenario}-{priority}-{days}.json`. Large generated logs are not committed.

| Market seed | Days | Events | Complete JSON SHA-256 |
| --- | --- | --- | --- |
| 7 | 30 | 1623 | 4a7edae82f7248515905f19c039ca1586a73e0180735151354793d416eaf2d4d |
| 7 | 365 | 19245 | 4e5c030bc8b54678ab078cb41951c66cae0a1e5b4f7f4721659325a30ae071ad |
| 42 | 30 | 1620 | dd8b29bf0bdc13eb9a872d183e0984f5a0011e231a35f1bf234799703114e015 |
| 42 | 365 | 20026 | 6e2d526d9d4c3965f9bee0818c346e37b0e07d1dd4119c661cba0dc495551bb9 |
| 99 | 30 | 1620 | 9bffea37fcd88e0fa2bc7a1287fe6e1d576a6f8cbdfabac6dc652024a58f9f12 |
| 99 | 365 | 20023 | 905532de7686c26987de5a632713c160a4b73690c1e8d9b82f553700ca977c9c |

| Historical scenario / priority / days (seed 42) | Unchanged SHA-256 |
| --- | --- |
| agents--30 | 53ca0029214319d352453c62e637340a7ae6b2e75bc42c29504885f5c0acef82 |
| agents--365 | d8f65499e0fe1d08cebc4485d18220a20f361fef42c9abdf92193e7b720ac2b2 |
| coordination--30 | f835a43f45c8867ee0e5a861923260aa9a00e04efd680d594726aa70eca23646 |
| coordination--365 | 5dcdb3e42ca3cbd3d285ee0044b7f89915ab9450ececff0f7ee521d30c9139bf |
| m0--30 | 6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9 |
| planning-commitment-first-30 | 0f90a40f0e3f32e19bbbdbb44ba2f783dee42cdee2c989d1db0b6ddcecf1ad72 |
| planning-commitment-first-365 | 61318efc50bea7b7fe0a75fa72ee414d209f981e90de9d58fda39774d3170469 |
| planning-immediate-needs-first-30 | a085c5bc2f0cbf1ca5da044393f69c4f1bc232bb4a34c845b782bd70aacc3585 |
| planning-immediate-needs-first-365 | 3ca879b7e9f4294e8eef97e7419d4ded56447a05ccec4f9b295eb90415030ddb |
| trading--30 | 5d569a193111d3ad5ff90dc6317b567596c4b51b4fe54c11e676e3eda0bcd9aa |
| trading--365 | e564ebe6f5638be17f8cfe2b78748bbaebb7907d818a9ade1247b7624ea12278 |

## Implementation decisions, files, and limits

- New `scripts/sim/market_world.gd`: public multi-producer offers and occupational agreement eligibility using inherited authority.
- New `scripts/sim/market_policy.gd`: pure deterministic supplier selection and copied-observation adapter to M5 commitment-first.
- New `scripts/sim/market_runner.gd`: fixed six-person initialization, role/ID scheduling, and per-NPC/supplier report projection.
- Small hooks in `agent_world.gd`, `coordination_world.gd`, `coordination_policy.gd`, `simulation_runner.gd`, `trading_runner.gd`, and `planning_runner.gd`: preserve singleton/default behavior while enabling the new scenario. The base accounting kernel and recipes are unchanged.
- `scripts/tools/run_simulation.gd`: `market` selector and six-person readable report, preserving old JSON payloads and default M0 behavior.
- New `tests/market_tests.gd`, corresponding Godot UID files, and `tests/run_tests.gd`: focused tests and full suite registration.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and this document: explicit assumptions, boundaries, commands, and actual outcomes.

All stock is automatically advertised under the existing output-offer rule, rather than via a new advertisement action. Selection is a single offer per action slot; it does not combine suppliers, retry, forecast demand, or account for other buyers' future turns. Public prices are fixed, so lower-price ranking is unit-tested but does not vary experimentally. Inputs available in the planning report refer to the selected offer, not a sum across sellers. Producers do not buy their own output from peers, retaining M5's own-food convention. Open requests are considered in creation order, with first eligible voluntary acceptance by scheduled turn. There is no fairness guarantee or physical reservation; supply promises can remain outstanding and real goods can be sold before delivery. These choices can amplify concentration and stranded partial batches.

The endowment matching adds a second farmer's explicit harvest source and a second baker's initial capital/food; the wage burden remains only Ada's. Fixed ordering, stable-ID ties, output targets, and unequal occupations remain experimental confounders. No alternate ordering/endowment ablation was run. Only the specified three seeds through 365 days on Godot 4.6.3 were verified; cross-version replay, persistence, and longer horizons remain unverified. No further occupations, resources, policies, enforcement, rescue mechanism, or M7 work were introduced.

Stop after M6 for review.
