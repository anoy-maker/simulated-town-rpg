# M6B — Revised Downstream Market Experiment

## Contract fixed before experiments

The original M6 `market` scenario and `docs/M6_RESULTS.md` remain unchanged. The alternate `market_downstream` scenario has exactly Ada (farmer), Bram and Edda (millers), Cora and Finn (bakers), and Dain (laborer). Original IDs/endowments remain Ada `farmer`: 30 coins, Bram `miller`: 20, Cora `baker`: 20, Dain `laborer`: 5; all own one bread and zero wheat/flour. Edda `miller_2` matches Bram's 20 coins/one bread/zero ingredients; Finn `baker_2` matches Cora. Total initial money is **115 coins**, with six bread. No currency is created later.

Before implementation, a zero-day executable check instantiated the existing `Market` runner with this alternate entity array. It verified occupation/ID order, one wheat offer, two flour offers, two bread offers, and unchanged initial/final state. `Market._init(initial_entities)`, role-based scheduling, `MarketWorld` eligibility/offers, and the common policy already support the configuration. **No scheduler, world, or policy refactoring is necessary.** A thin subclass supplies only starting entities and the scenario label; it inherits the full runner, reporting, world authority, and policies.

Fixed conditions: wheat/flour/bread prices 1/2/3; two wheat → two flour; two flour → three bread; targets wheat 4, flour 4, bread 6, food 1; max two recipe batches/work turn; commitment-first for every NPC; unchanged Ada → Dain two-coin daily attempted payment. Both millers and both bakers use exactly the existing occupation policy. Public selection remains price ascending, stock descending, seller ID ascending, with the inherited own-output convention. No private balances/unadvertised stock enter observations. Requests, prepayments, real delivery, duplicate limits, and authoritative accounting remain unchanged.

Inherited scheduling orders Ada, Bram, Edda, Cora, Finn, Dain by production-chain occupation then ID. Payment precedes work. Each producer gets inputs (except Ada), work, and delivery; all six then get requests, acceptance, food, and meals; outstanding commitments are annotated. This is **38 decisions/day**. Exactly one seeded 2–6 wheat opportunity is drawn per day, even if Ada waits. Earlier millers/bakers can deplete real stock before their peers act. No rotation, retries, reservations, forecasts, or calibration are introduced.

Experiments are predefined seeds **7, 42, 99**, each for **30 and 365 days**. Initial conditions and all policies are fixed before inspecting results. M5, M6, and M6B differ in initial money (75/125/115), population/occupations, capacity, harvest opportunities, and scheduling. Their aggregate differences are descriptive, not controlled causal improvements.

## Actual results

All six experiments completed with the fixed configuration and unchanged economic policies. Each retained exactly 115 coins. Both millers bought wheat, produced/advertised flour, sold goods, and accepted/fulfilled supply requests; both bakers produced and sold bread. No spot purchase or agreement lifecycle rejections occurred in the default runs. Missing or unaffordable supplies usually caused waits or requests, so zero rejected purchases does **not** mean no competition or shortage. Actual failures were missed meals and unaffordable employer payments.

| Seed | Days | Wheat harvested | Flour / bread produced | Meals eaten / missed | Spot purchases successful / failed | Agreements accepted / fulfilled / outstanding |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 99 | 96 / 144 | 144 / 36 | 116 / 0 | 46 / 45 / 1 |
| 7 | 365 | 832 | 830 / 1242 | 1243 / 947 | 1008 / 0 | 414 / 414 / 0 |
| 42 | 30 | 102 | 98 / 147 | 149 / 31 | 130 / 0 | 52 / 50 / 2 |
| 42 | 365 | 743 | 738 / 1104 | 1107 / 1083 | 961 / 0 | 373 / 372 / 1 |
| 99 | 30 | 93 | 92 / 138 | 137 / 43 | 115 / 0 | 46 / 45 / 1 |
| 99 | 365 | 731 | 726 / 1086 | 1089 / 1101 | 946 / 0 | 365 / 364 / 1 |

| Seed | Days | Spot money | Prepaid money | Wages paid | Wages successful / failed | Gross cash circulated | After day 26: spot / production / fulfillment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 355 | 204 | 52 | 26 / 4 | 611 | 11 / 10 / 5 |
| 7 | 365 | 2624 | 1592 | 390 | 195 / 170 | 4606 | 903 / 743 / 374 |
| 42 | 30 | 364 | 211 | 52 | 26 / 4 | 627 | 10 / 8 / 4 |
| 42 | 365 | 2449 | 1315 | 408 | 204 / 161 | 4172 | 841 / 647 / 326 |
| 99 | 30 | 361 | 174 | 48 | 24 / 6 | 583 | 13 / 12 / 6 |
| 99 | 365 | 2444 | 1260 | 408 | 204 / 161 | 4112 | 844 / 645 / 325 |

Gross circulation counts real spot payments + prepayments + employer transfers once. It does not represent new currency. No unpaid open requests, waivers, closures, automatic refunds, or rescues remain in these runs. Fulfillment transfers goods without a second payment. The village retains production/trade through the horizon: seed 7's latest production/fulfillment is day 365; seeds 42/99's is day 364, with spot purchases on day 365. Individual exclusion occurs despite continued village activity.

## Does Ada respond to downstream demand?

**Yes, through inventory depletion; she does not forecast demand or raise her ordinary target.** The unchanged ordinary rule chooses one harvest if owned wheat is below four at her work turn, otherwise waits. Sales later that day can trigger the next day's harvest. Four is a trigger, not an inventory cap: three owned wheat plus a six-wheat opportunity yields nine. She cannot harvest again during the same day when a later miller runs short. Existing voluntarily accepted wheat commitments can raise the effective target above four; a focused test demonstrates a six-wheat agreement triggering work with four already owned. The experiment does not add that behavior or alter its acceptance rules.

| Seed | Days | Harvest turns | All work waits | Ordinary target waits | Actual wheat | Sum of all daily opportunities | Ada wheat revenue (spot + prepaid) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | 29 | 1 | 0 | 99 | 102 | 96 |
| 7 | 365 | 211 | 154 | 153 | 832 | 1456 | 830 |
| 42 | 30 | 25 | 5 | 5 | 102 | 122 | 98 |
| 42 | 365 | 186 | 179 | 179 | 743 | 1470 | 738 |
| 99 | 30 | 23 | 7 | 1 | 93 | 119 | 92 |
| 99 | 365 | 186 | 179 | 173 | 731 | 1482 | 726 |

The opportunity sum is the yield of each seeded daily opportunity whether taken or skipped, derived independently from Godot's RNG and checked against every realized harvest. It is a utilization reference, not a simulated alternative policy or a prediction that producing all of it would find buyers. Other work waits are accepted-obligation stock already ready for delivery: one at seed 7 and six at seed 99 through day 365. No cash or wheat is invented when a harvest is skipped.

The target clearly prevents unconditional production and does not scale with the number of millers. But these ledgers do **not** show it directly blocking an otherwise funded spot order on its wait days: there are zero ordinary target-wait days followed by a funded empty-wheat or stock-limited partial input choice in any of the six runs. Over the whole runs, funded empty-wheat input waits occur 1/2/6 times (seeds 7/42/99); funded partial wheat purchases occur 6/2/3 times at 30 days and 7/4/5 at 365. All occur on other days. The diagnostic uses the acting miller's owned cash/inputs, the same recipe deficit and food/input budget, and actual public stock at that turn; awaiting a prepaid delivery is classified separately. It does not grant NPCs access to another actor's finances. It does not prove there are no other timing or commitment bottlenecks.

Descriptive comparison of **Ada alone** follows. Revenue includes spot sales and prepayments; it is not final wealth. M5 is commitment-first. Its one RNG draw/day matches M6B's environmental opportunity sequence, whereas M6's two draws/day interleave opportunities for Ada and Edda.

| Seed | Days | M5 Ada wheat / revenue | M6 Ada wheat / revenue | M6B Ada wheat / revenue |
| --- | --- | --- | --- | --- |
| 7 | 30 | 66 / 60 | 90 / 86 | 99 / 96 |
| 7 | 365 | 466 / 462 | 572 / 568 | 832 / 830 |
| 42 | 30 | 64 / 60 | 70 / 68 | 102 / 98 |
| 42 | 365 | 467 / 462 | 745 / 742 | 743 / 738 |
| 99 | 30 | 64 / 60 | 58 / 56 | 93 / 92 |
| 99 | 365 | 467 / 462 | 732 / 726 | 731 / 726 |

Relative to four-person M5, Ada realizes more wheat production and revenue in every sampled M6B run. Relative to M6's Ada, annual revenue rises in seed 7, falls slightly in seed 42, and is equal in seed 99. Thus more downstream participants do not guarantee greater revenue than every prior setup. Ada still ends with only zero-to-two coins because food and the unchanged wage obligation redistribute her receipts.

These comparisons change several things simultaneously. M5 has four people/75 coins; M6 has six/125 coins and two farmers/one miller; M6B has six/115 coins and one farmer/two millers. All have one initial bread/person. M6B doubles M5's installed mill and bake capacity; relative to M6 it removes one daily harvest source and adds a miller. Two millers can nominally process eight wheat/day and two bakers eight flour/day, only if actual ingredients and cash are available; Ada still receives one 2–6 wheat opportunity/day. Changing Edda's occupation also moves her turn, changes ingredient spending and food-budget needs, and changes which requests she can see/accept. Fixed ID ties and first valid acceptance favor earlier turns. No controlled ablation isolates competition, money supply, capacity, weather, or ordering; aggregate production/consumption is not evidence of a causal improvement.

## Per-character final holdings, meals, and cash flow

W/F/B means wheat/flour/bread. Earned/spent include spot payments, prepayments, and wages exactly once. Each NPC satisfies `final money = initial money + earned − spent`, and eaten + missed equals run length. Prepayments are detailed by route below. Missed meals retain the existing absence of health/death effects.

### 30 days

| Seed | NPC | Coins | W / F / B | Eaten | Missed | Earned / spent |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | Ada | 2 | 3 / 0 / 0 | 25 | 5 | 96 / 124 |
| 7 | Bram | 2 | 0 / 0 / 0 | 27 | 3 | 116 / 134 |
| 7 | Edda | 0 | 0 / 0 / 0 | 21 | 9 | 80 / 100 |
| 7 | Cora | 56 | 0 / 0 / 3 | 26 | 4 | 132 / 96 |
| 7 | Finn | 55 | 0 / 0 / 3 | 25 | 5 | 135 / 100 |
| 7 | Dain | 0 | 0 / 0 / 0 | 20 | 10 | 52 / 57 |
| 42 | Ada | 1 | 4 / 0 / 0 | 26 | 4 | 98 / 127 |
| 42 | Bram | 2 | 0 / 0 / 0 | 27 | 3 | 116 / 134 |
| 42 | Edda | 3 | 0 / 0 / 0 | 22 | 8 | 88 / 105 |
| 42 | Cora | 67 | 0 / 0 / 2 | 27 | 3 | 159 / 112 |
| 42 | Finn | 42 | 0 / 0 / 2 | 27 | 3 | 114 / 92 |
| 42 | Dain | 0 | 0 / 0 / 0 | 20 | 10 | 52 / 57 |
| 99 | Ada | 2 | 1 / 0 / 0 | 25 | 5 | 92 / 120 |
| 99 | Bram | 3 | 0 / 0 / 0 | 28 | 2 | 124 / 141 |
| 99 | Edda | 1 | 0 / 0 / 0 | 18 | 12 | 64 / 83 |
| 99 | Cora | 65 | 0 / 0 / 3 | 25 | 5 | 153 / 108 |
| 99 | Finn | 42 | 0 / 0 / 4 | 23 | 7 | 102 / 80 |
| 99 | Dain | 2 | 0 / 0 / 0 | 18 | 12 | 48 / 51 |

### 365 days

| Seed | NPC | Coins | W / F / B | Eaten | Missed | Earned / spent |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | Ada | 2 | 2 / 0 / 0 | 157 | 208 | 830 / 858 |
| 7 | Bram | 1 | 0 / 1 / 0 | 204 | 161 | 1182 / 1201 |
| 7 | Edda | 0 | 0 / 0 / 0 | 87 | 278 | 476 / 496 |
| 7 | Cora | 110 | 0 / 0 / 5 | 361 | 4 | 1038 / 948 |
| 7 | Finn | 0 | 0 / 1 / 0 | 302 | 63 | 690 / 710 |
| 7 | Dain | 2 | 0 / 0 / 0 | 132 | 233 | 390 / 393 |
| 42 | Ada | 0 | 5 / 0 / 0 | 121 | 244 | 738 / 768 |
| 42 | Bram | 3 | 0 / 0 / 0 | 192 | 173 | 1110 / 1127 |
| 42 | Edda | 0 | 0 / 0 / 0 | 69 | 296 | 368 / 388 |
| 42 | Cora | 109 | 0 / 1 / 3 | 362 | 3 | 1041 / 952 |
| 42 | Finn | 1 | 0 / 1 / 0 | 225 | 140 | 507 / 526 |
| 42 | Dain | 2 | 0 / 0 / 0 | 138 | 227 | 408 / 411 |
| 99 | Ada | 0 | 5 / 0 / 0 | 117 | 248 | 726 / 756 |
| 99 | Bram | 3 | 0 / 0 / 0 | 192 | 173 | 1110 / 1127 |
| 99 | Edda | 0 | 0 / 0 / 0 | 65 | 300 | 344 / 364 |
| 99 | Cora | 110 | 0 / 1 / 3 | 360 | 5 | 1038 / 948 |
| 99 | Finn | 0 | 0 / 1 / 0 | 217 | 148 | 486 / 506 |
| 99 | Dain | 2 | 0 / 0 / 0 | 138 | 227 | 408 / 411 |

## Production, purchases, sales, and supplier selection

Quantities here are W/F/B triples. Bought/sold columns and counts cover **spot** purchases, with all failed counts zero; agreement quantities/routes follow separately. Each supplier's cash receipts from spot sales equal sold quantity × fixed price. Self-consumption is included in meals, not sales. Selected suppliers list the number of spot purchase attempts. Public offer selection uses current stock/price/ID at each fresh observation, with no reservation of stock.

| Seed | Days | NPC | Produced W/F/B | Spot bought W/F/B | Spot sold W/F/B | Purchase / sale count | Selected suppliers: attempts |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | Ada | 99 / 0 / 0 | 0 / 0 / 24 | 40 / 0 / 0 | 24 / 21 | Cora 12, Finn 12 |
| 7 | 30 | Bram | 0 / 56 / 0 | 27 / 0 / 26 | 0 / 4 / 0 | 39 / 1 | Cora 12, Finn 14, Ada 13 |
| 7 | 30 | Edda | 0 / 40 / 0 | 13 / 0 / 20 | 0 / 20 / 0 | 28 / 5 | Cora 10, Finn 10, Ada 8 |
| 7 | 30 | Cora | 0 / 0 / 72 | 0 / 12 / 0 | 0 / 0 / 44 | 3 / 44 | Bram 1, Edda 2 |
| 7 | 30 | Finn | 0 / 0 / 72 | 0 / 12 / 0 | 0 / 0 / 45 | 3 / 45 | Edda 3 |
| 7 | 30 | Dain | 0 / 0 / 0 | 0 / 0 / 19 | 0 / 0 / 0 | 19 / 0 | Cora 10, Finn 9 |
| 7 | 365 | Ada | 832 / 0 / 0 | 0 / 0 / 156 | 772 / 0 / 0 | 156 / 388 | Cora 112, Finn 44 |
| 7 | 365 | Bram | 0 / 592 / 0 | 562 / 0 / 203 | 0 / 41 / 0 | 484 / 38 | Cora 134, Finn 69, Ada 281 |
| 7 | 365 | Edda | 0 / 238 / 0 | 210 / 0 / 86 | 0 / 21 / 0 | 193 / 6 | Cora 33, Finn 53, Ada 107 |
| 7 | 365 | Cora | 0 / 0 / 711 | 0 / 50 / 0 | 0 / 0 / 346 | 41 / 346 | Bram 38, Edda 3 |
| 7 | 365 | Finn | 0 / 0 / 531 | 0 / 12 / 0 | 0 / 0 / 230 | 3 / 230 | Edda 3 |
| 7 | 365 | Dain | 0 / 0 / 0 | 0 / 0 / 131 | 0 / 0 / 0 | 131 / 0 | Cora 67, Finn 64 |
| 42 | 30 | Ada | 102 / 0 / 0 | 0 / 0 / 25 | 75 / 0 / 0 | 25 / 36 | Cora 17, Finn 8 |
| 42 | 30 | Bram | 0 / 56 / 0 | 43 / 0 / 26 | 0 / 6 / 0 | 46 / 2 | Cora 15, Finn 11, Ada 20 |
| 42 | 30 | Edda | 0 / 42 / 0 | 32 / 0 / 21 | 0 / 2 / 0 | 37 / 1 | Cora 13, Finn 8, Ada 16 |
| 42 | 30 | Cora | 0 / 0 / 81 | 0 / 8 / 0 | 0 / 0 / 53 | 3 / 53 | Bram 2, Edda 1 |
| 42 | 30 | Finn | 0 / 0 / 66 | 0 / 0 / 0 | 0 / 0 / 38 | 0 / 38 | none |
| 42 | 30 | Dain | 0 / 0 / 0 | 0 / 0 / 19 | 0 / 0 / 0 | 19 / 0 | Cora 8, Finn 11 |
| 42 | 365 | Ada | 743 / 0 / 0 | 0 / 0 / 120 | 713 / 0 / 0 | 120 / 356 | Cora 89, Finn 31 |
| 42 | 365 | Bram | 0 / 554 / 0 | 541 / 0 / 191 | 0 / 91 / 0 | 460 / 87 | Cora 140, Finn 51, Ada 269 |
| 42 | 365 | Edda | 0 / 184 / 0 | 172 / 0 / 68 | 0 / 3 / 0 | 155 / 2 | Cora 30, Finn 38, Ada 87 |
| 42 | 365 | Cora | 0 / 0 / 711 | 0 / 94 / 0 | 0 / 0 / 347 | 89 / 347 | Bram 87, Edda 2 |
| 42 | 365 | Finn | 0 / 0 / 393 | 0 / 0 / 0 | 0 / 0 / 169 | 0 / 169 | none |
| 42 | 365 | Dain | 0 / 0 / 0 | 0 / 0 / 137 | 0 / 0 / 0 | 137 / 0 | Cora 88, Finn 49 |
| 99 | 30 | Ada | 93 / 0 / 0 | 0 / 0 / 23 | 29 / 0 / 0 | 23 / 12 | Cora 19, Finn 4 |
| 99 | 30 | Bram | 0 / 60 / 0 | 18 / 0 / 27 | 0 / 28 / 0 | 34 / 13 | Cora 12, Finn 15, Ada 7 |
| 99 | 30 | Edda | 0 / 32 / 0 | 11 / 0 / 17 | 0 / 12 / 0 | 22 / 6 | Cora 12, Finn 5, Ada 5 |
| 99 | 30 | Cora | 0 / 0 / 78 | 0 / 24 / 0 | 0 / 0 / 50 | 11 / 50 | Bram 7, Edda 4 |
| 99 | 30 | Finn | 0 / 0 / 60 | 0 / 16 / 0 | 0 / 0 / 34 | 8 / 34 | Bram 6, Edda 2 |
| 99 | 30 | Dain | 0 / 0 / 0 | 0 / 0 / 17 | 0 / 0 / 0 | 17 / 0 | Cora 7, Finn 10 |
| 99 | 365 | Ada | 731 / 0 / 0 | 0 / 0 / 115 | 661 / 0 / 0 | 115 / 329 | Cora 89, Finn 26 |
| 99 | 365 | Bram | 0 / 554 / 0 | 512 / 0 / 191 | 0 / 117 / 0 | 445 / 102 | Cora 138, Finn 53, Ada 254 |
| 99 | 365 | Edda | 0 / 172 / 0 | 149 / 0 / 64 | 0 / 14 / 0 | 139 / 8 | Cora 29, Finn 35, Ada 75 |
| 99 | 365 | Cora | 0 / 0 / 708 | 0 / 114 / 0 | 0 / 0 / 345 | 101 / 345 | Bram 95, Edda 6 |
| 99 | 365 | Finn | 0 / 0 / 378 | 0 / 17 / 0 | 0 / 0 / 162 | 9 / 162 | Bram 7, Edda 2 |
| 99 | 365 | Dain | 0 / 0 / 0 | 0 / 0 / 137 | 0 / 0 / 0 | 137 / 0 | Cora 89, Finn 48 |

Finn makes no spot flour purchases at all in seed 42, even though he bakes: his real ingredients arrive through prepaid agreements. An empty supplier-selection dictionary must not be interpreted as no economic participation. Every run has flour from both Bram and Edda and bread from both Cora and Finn; neither peer has an individualized economic policy.

## Commercial agreements and shortages

The following groups every accepted agreement by buyer, supplier, and commodity. Accepted/fulfilled/outstanding counts and delivered quantities come from retained request records; payments match the linked money-transfer receipts. No agreement delivery creates a commodity. Both millers independently accept flour requests, and both buy/prepay wheat from Ada. Seed 99 also contains Ada's three-coin prepaid request for one bread supplied by Cora; this is an observed voluntary food agreement, not a new wage/food rule.

| Seed | Days | Buyer → supplier | Commodity | Accepted / fulfilled / outstanding | Coins prepaid | Units delivered |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | 30 | Cora → Bram | flour | 14 / 14 / 0 | 72 | 36 |
| 7 | 30 | Finn → Bram | flour | 6 / 5 / 1 | 36 | 16 |
| 7 | 30 | Finn → Edda | flour | 9 / 9 / 0 | 40 | 20 |
| 7 | 30 | Bram → Ada | wheat | 9 / 9 / 0 | 29 | 29 |
| 7 | 30 | Edda → Ada | wheat | 8 / 8 / 0 | 27 | 27 |
| 7 | 365 | Cora → Bram | flour | 227 / 227 / 0 | 848 | 424 |
| 7 | 365 | Finn → Bram | flour | 60 / 60 / 0 | 252 | 126 |
| 7 | 365 | Finn → Edda | flour | 108 / 108 / 0 | 434 | 217 |
| 7 | 365 | Bram → Ada | wheat | 10 / 10 / 0 | 30 | 30 |
| 7 | 365 | Edda → Ada | wheat | 9 / 9 / 0 | 28 | 28 |
| 42 | 30 | Cora → Bram | flour | 22 / 21 / 1 | 88 | 42 |
| 42 | 30 | Cora → Edda | flour | 1 / 1 / 0 | 8 | 4 |
| 42 | 30 | Finn → Bram | flour | 3 / 3 / 0 | 16 | 8 |
| 42 | 30 | Finn → Edda | flour | 19 / 18 / 1 | 76 | 36 |
| 42 | 30 | Bram → Ada | wheat | 4 / 4 / 0 | 13 | 13 |
| 42 | 30 | Edda → Ada | wheat | 3 / 3 / 0 | 10 | 10 |
| 42 | 365 | Cora → Bram | flour | 232 / 231 / 1 | 756 | 377 |
| 42 | 365 | Cora → Edda | flour | 1 / 1 / 0 | 8 | 4 |
| 42 | 365 | Finn → Bram | flour | 42 / 42 / 0 | 172 | 86 |
| 42 | 365 | Finn → Edda | flour | 89 / 89 / 0 | 354 | 177 |
| 42 | 365 | Bram → Ada | wheat | 4 / 4 / 0 | 13 | 13 |
| 42 | 365 | Edda → Ada | wheat | 5 / 5 / 0 | 12 | 12 |
| 99 | 30 | Cora → Bram | flour | 12 / 11 / 1 | 52 | 24 |
| 99 | 30 | Cora → Edda | flour | 1 / 1 / 0 | 8 | 4 |
| 99 | 30 | Finn → Bram | flour | 3 / 3 / 0 | 16 | 8 |
| 99 | 30 | Finn → Edda | flour | 8 / 8 / 0 | 32 | 16 |
| 99 | 30 | Ada → Cora | bread | 1 / 1 / 0 | 3 | 1 |
| 99 | 30 | Bram → Ada | wheat | 13 / 13 / 0 | 42 | 42 |
| 99 | 30 | Edda → Ada | wheat | 8 / 8 / 0 | 21 | 21 |
| 99 | 365 | Cora → Bram | flour | 222 / 221 / 1 | 712 | 355 |
| 99 | 365 | Cora → Edda | flour | 1 / 1 / 0 | 8 | 4 |
| 99 | 365 | Finn → Bram | flour | 40 / 40 / 0 | 164 | 82 |
| 99 | 365 | Finn → Edda | flour | 78 / 78 / 0 | 308 | 154 |
| 99 | 365 | Ada → Cora | bread | 1 / 1 / 0 | 3 | 1 |
| 99 | 365 | Bram → Ada | wheat | 13 / 13 / 0 | 42 | 42 |
| 99 | 365 | Edda → Ada | wheat | 10 / 10 / 0 | 23 | 23 |

At day 30, seed 7's r46 owes Finn two flour; seed 42's r51/r52 owe Cora/Finn two flour each; seed 99's r46 owes Cora two flour. At day 365, seed 7 has no outstanding agreement. Seeds 42/99 have r373/r365 respectively: Cora prepaid Bram two coins for one flour on day 365. Bram has three coins and visible wheat; these are recent horizon obligations, with no claim of fulfillment beyond the horizon. None of the excluded producers below has a remaining supplier obligation or pending incoming request.

Competition is observable as rationing, requests, and supplier switching, even without rejected orders. The first scheduled miller can consume wheat before the second; bakers can deplete an offered flour stock before a later baker's fresh choice. Focused tests additionally submit stale competing proposals to prove authority rejects the later one without moving goods or money. Cash limits and waiting on existing requests must be distinguished from physical stock exhaustion.

| Seed, 365 days | NPC | Inputs: market unavailable | Inputs: unaffordable | Inputs: awaiting delivery | Work: missing inputs / unable | Last production day | Last spot sale day |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | Bram | 0 | 67 | 6 | 76 | 365 | 364 |
| 7 | Edda | 4 | 234 | 10 | 252 | 304 | 304 |
| 7 | Cora | 189 | 0 | 6 | 134 | 365 | 364 |
| 7 | Finn | 206 | 24 | 7 | 195 | 303 | 301 |
| 42 | Bram | 0 | 87 | 3 | 90 | 364 | 365 |
| 42 | Edda | 3 | 264 | 4 | 274 | 225 | 225 |
| 42 | Cora | 146 | 0 | 1 | 129 | 364 | 365 |
| 42 | Finn | 217 | 55 | 6 | 235 | 224 | 222 |
| 99 | Bram | 3 | 89 | 4 | 96 | 364 | 365 |
| 99 | Edda | 1 | 266 | 10 | 282 | 221 | 222 |
| 99 | Cora | 132 | 0 | 2 | 131 | 364 | 365 |
| 99 | Finn | 206 | 56 | 10 | 240 | 221 | 218 |

The unavailable-market reason checks stock before affordability in the inherited policy, so it is not by itself proof the buyer could have paid. The funded-wheat diagnostic above applies the additional budget check. Input waits under `unable_to_satisfy_obligation`, owned inputs, and target-met decisions remain separately visible in the complete ledger.

At day 365 Edda has **zero money, zero ingredients, and no bread in all seeds**. Her last production is day 304/225/221 for seeds 7/42/99. Finn ends with **one flour and zero/one/zero coins**; he needs another flour costing two coins to bake, cannot prepay it, and has no bread to sell. His last production is day 303/224/221, and last spot sale day 301/222/218. These are individual production deadlocks without outstanding accepted obligations; commitment-first budgeting cannot supply absent cash to a non-obligated buyer. No cash, food, ingredients, or waivers were injected to correct them.

Cora holds 110/109/110 of 115 coins (95.7%/94.8%/95.7%) at the year horizon. Bram continues producing through the last day or preceding day, while Edda and Finn stop. Ada misses 208/244/248 meals despite 830/738/726 coins of cumulative wheat receipts. Dain misses 233/227/227. The population's unmet meals total 947/1083/1101 out of 2190; continued trade does not establish food access or stability. Original M6 had a different individual exclusion pattern; this configuration does not consistently cure it and was not tuned to do so.

## Verification, reproduction, and actual failures

Base commit: M6 `24a62d3`. Runtime: **Godot 4.6.3**. Before changes, the complete suite passed **1409 checks, 0 failures**. The final complete suite passed **1780 checks, 0 failures**, preserving every prior check and adding 371. Shared M6 report-audit parameters retain their historical defaults while checking M6B's 115 coins and 38 decisions/day. Focused checks cover alternate population/endowments, exact inheritance equivalence, both millers' common policies and prepaid production, wheat/flour competition, authoritative stale rejection, private-information boundaries, the harvest trigger and commitment exception, all six report/accounting ledgers, split replay, actual harvest yields/RNG state, and all six historical M6 hashes. Earlier tests retain M0–M5 hashes and mechanics.

All **17 published historical outputs** were freshly captured and checked against their documented hashes before implementation, then compared byte-for-byte after it. All six downstream JSON runs were repeated in independent processes and matched exactly, with empty stderr. Their readable CLI outputs included all six NPCs. Invalid priority/day/JSON options returned expected exit 2. An independent Python auditor reconstructed all six final states and requests, checked ordered events, conserved money and bounded stocks after every event, verified supplier rankings/receipts, and reconciled sales and meals. The farmer analysis separately replayed actor budgets and input deficits; its metrics are post-run diagnostics and were never supplied to policies.

Headless editor import and `git diff --check` passed. No test, simulation, import, or audit failures remain, and no economic policy changed after any result. A standalone early version query printed a fontconfig cache warning before the writable XDG setup; all actual simulation/test commands used that setup. Only Godot 4.6.3 and the specified seeds/horizons were verified; cross-version replay, saves/resume, alternate scheduling, and later fulfillment remain unverified.

Actual commands used:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --no-header --path . --script /workspace/work/m6b_architecture_check.gd
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market_downstream 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario market_downstream 365 42
git diff --check
```

The preflight ran before new scenario code and asserts that the existing market runner schedules an alternate `initial_entities` array as one farmer/two millers/two bakers/one laborer, advertises 1/2/2 output offers, and keeps zero-day initial/final state equal. Those capabilities are also preserved in automated configuration tests. Experiment scripts used serial Python `subprocess.run(..., check=True, capture_output=True)` calls for `--scenario market_downstream {30|365} {7|42|99} --json`, with `--headless --no-header`. Captures are reproducible workspace artifacts at `/workspace/work/m6b-market_downstream-{seed}-{days}-{a|b}.json`; summaries, audits, opportunity sequences, analysis, readable reports, and test logs are alongside them. Large generated ledgers are not committed.

| Seed | Days | Events | Full downstream JSON SHA-256 |
| --- | --- | --- | --- |
| 7 | 30 | 1884 | 4661145fb04409805dadc0e86344100bab3a7821ae66d1bcfec252c2c5770bc7 |
| 7 | 365 | 21312 | a3fdbcad5eafa918327883cd41d44b401074b8734eb9740fd27ee47a3d75ec01 |
| 42 | 30 | 1944 | 1faab3966135ee4109b63de24c39e067771527cc970d18febdfb49c82440311b |
| 42 | 365 | 20915 | b5939eb8f50f12b3f9ede8e5f72f0e260f9e2f44dc432f6a18a9a272dd24c81a |
| 99 | 30 | 1883 | 9a2d704d3dafd0bba318889841e3a61e6052454cdffa6acdfaf51b1441d47009 |
| 99 | 365 | 20836 | 7691205ec35041155f4370fdac2df9cdf3faf9bebc1e4a36f62b158c5a08771a |

| Preserved historical output | Unchanged SHA-256 |
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
| market-7-30 | 4a7edae82f7248515905f19c039ca1586a73e0180735151354793d416eaf2d4d |
| market-7-365 | 4e5c030bc8b54678ab078cb41951c66cae0a1e5b4f7f4721659325a30ae071ad |
| market-42-30 | dd8b29bf0bdc13eb9a872d183e0984f5a0011e231a35f1bf234799703114e015 |
| market-42-365 | 6e2d526d9d4c3965f9bee0818c346e37b0e07d1dd4119c661cba0dc495551bb9 |
| market-99-30 | 9bffea37fcd88e0fa2bc7a1287fe6e1d576a6f8cbdfabac6dc652024a58f9f12 |
| market-99-365 | 905532de7686c26987de5a632713c160a4b73690c1e8d9b82f553700ca977c9c |

## Files and limits

- New `scripts/sim/market_downstream_runner.gd` and UID: only alternate initial endowments and scenario label; no duplicate scheduler, world, report aggregation, or policies.
- `scripts/tools/run_simulation.gd`: separate `market_downstream` selector and readable header/report sections.
- New `tests/market_downstream_tests.gd` and UID; `tests/run_tests.gd`: focused tests, six experimental ledgers/replays, six M6 hash pins, and suite registration.
- `tests/market_tests.gd`: reuse the same report audit with configurable expected money/decision count; original assertions and defaults retained.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and this document: fixed configuration, preflight evidence, commands, actual results, and limitations.

All existing production runner, policy, world authority, recipe, price, wage, target, and agreement implementations are unchanged. M5/M6 result documents are preserved. Own-output food behavior, automatic public output advertisements, one supplier/action without retries or split orders, first scheduled acceptance, no physical stock reservation, partial batches, and fixed scheduling remain inherited limitations. Nominal capacity does not allocate working capital, make an insolvent buyer affordable, or guarantee sales. Changing roles and endowments is the experiment; calibration is not part of it.

Stop after M6B for review. No economic calibration, dynamic pricing, LLM integration, or M7 work was introduced.
