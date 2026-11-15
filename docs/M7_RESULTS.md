# M7 — Economic Foundations and Calibration Laboratory

## Fixed design and feasibility, before agent results

The separate `calibration` scenario retains M6B's six NPCs, occupations, one initial bread each, recipes, 38 decision slots/day, public observations, supplier ranking, commitment-first policy, and agreement lifecycle. All historical scenarios remain baselines. These six configurations were fixed before M7 outcomes were examined:

| Configuration | Sole change from baseline |
| --- | --- |
| baseline | M6B: yield 2–6; farmer target 4; prices wheat/flour/bread 1/2/3; wage 2; money Ada/Bram/Edda/Cora/Finn/Dain 30/20/20/20/20/5 |
| higher_productivity | Add 2 to each underlying daily harvest opportunity (4–8); same seeded draw, including skipped opportunities |
| higher_target | Farmer ordinary wheat target 8 instead of 4 |
| lower_food_price | Bread price 2 instead of 3 |
| higher_wage | Ada attempts to pay Dain 3 instead of 2 daily |
| extra_liquidity | Add 10 coins to every initial balance; total 175 instead of 115, initialization only |

Seeds are **7, 42, 99**, horizons **30 and 365 days**, for 36 matched runs. No parameter combinations, optimization, or post-result policy tuning are allowed. Custom API configurations expose only the specified economic variables; CLI presets provide the fixed comparisons.

Six people need **six bread/day, 180 in 30 days, 2190 in 365 days**. Six initialized bread are a one-time food buffer, not daily production. Milling transforms 2 wheat → 2 flour; baking 2 flour → 3 bread. Two millers can process at most 8 wheat/day, and two bakers at most 8 flour/day → 12 bread/day, given real ingredients. The farmer gets one opportunity/day even when waiting. Baseline uniform opportunities 2–6 have mean 4 wheat → 6 bread/day: expected long-run production has **zero buffer above subsistence**, before integer batches, temporal supply, targets, finance, or distribution. Absolute daily yield 6 can support 9 bread; this best day is not an expected daily supply.

Higher productivity has mean 6 wheat → 9 bread/day, a nominal three-bread/day (50%) buffer, with maximum yield 8 meeting the processing limit of 12 bread/day. The other four interventions do not change physical opportunity or installed recipe capacity. For the fixed presets, all daily grain can be processed within that day's physical capacity if independently allocated, so horizon new-bread upper bound is `3 * floor(sum(opportunity_wheat) / 2)`. Unpaired grain carries forward. General API configurations additionally cap daily mill/bake batches. The report also computes a time-respecting meal upper bound using six initial bread, greedy maximum physical production, storage, and at most six meals/day; future food cannot repair earlier missed meals. These are supply/capacity bounds ignoring cash, policies, and distribution, not predictions that potential crops would be harvested, processed, sold, or eaten.

At baseline, one bread costs 3 and the daily payment is 2: nominal wage coverage is **2/3 of a meal**, a one-coin daily gap even if payment always succeeds. Dain starts with five coins and one bread; with no other income, 365 successful payments could fund at most `1 + floor((5 + 365*2)/3) = 246` meals, before stock/timing constraints. Lower bread price 2 or wage 3 makes one nominal daily meal affordable, provided Ada actually pays and bread is available. Extra liquidity gives Dain 15 starting coins, not an increased recurring wage.

Ada needs daily wheat receipts covering **wage + personal bread**: baseline `2 + 3 = 5` coins, or five wheat at price 1, versus mean potential four. This recurring one-coin expected gap exists even with perfect sales and no purchased farming inputs. Higher productivity offers mean six wheat against the same five-coin requirement; lower bread price requires four wheat; higher wage requires six wheat against baseline mean four. A higher target or starting liquidity does not change this recurring arithmetic. Ada pays before sales, adding a working-capital/timing constraint. Initial savings can bridge gaps but do not create a permanent revenue source.

Gross processing margins use **full output sold at posted prices**, excluding the processor's own consumption, unsold stock, and all unmodeled operating expenses (labor, fuel, maintenance, rent, spoilage, etc.). Mill batch: `2*flour_price − 2*wheat_price = 2` coins, one per flour. Bake batch: `3*bread_price − 2*flour_price = 5` coins at baseline, but only two coins with bread price 2. These are gross ingredient margins, not profit or guaranteed cash flow. Harvest has no purchased ingredient cost in the model; its receipts still fund Ada's wage and food.

An illustrative full-subsistence day makes the cash-flow constraint clearer: four wheat become four flour and six bread; both bakers eat one own bread and sell the remaining four; everybody eats, wages are paid, and inventories stay steady. This is an accounting calculation, not an additional simulated intervention. Operating expenses remain unmodeled.

| Group | Daily cash change, baseline bread price 3 | Daily cash change, bread price 2 |
| --- | --- | --- |
| Ada | `4 − 2 − 3 = −1` | `4 − 2 − 2 = 0` |
| Dain | `2 − 3 = −1` | `2 − 2 = 0` |
| Two millers together | `8 − 4 − 6 = −2` | `8 − 4 − 4 = 0` |
| Two bakers together | `12 − 8 = +4` | `8 − 8 = 0` |

The four coins accumulating with bakers at baseline are conserved, but recurring full subsistence drains the other occupations' savings. Each miller needs three flour sales to fund three-coin bread from its one-coin/flour gross margin, while the average four-wheat source supports only four flour for both. This is a structural concentration pressure. Extra starting savings can delay that drift; extra productive capacity alone does not change prices or six daily meal needs.

The lower-price identity balances each group's ideal cash flow, but does not establish that agents can realize it. Schedules, stock, commitments, indivisible batches, and policy choices still matter, as the actual outcomes demonstrate below.

Initial balances total **115**: Ada 30 (26.1%), Bram/Edda/Cora/Finn 20 each (17.4%), Dain 5 (4.3%). Extra liquidity totals **175**: 40/30/30/30/30/15. Currency circulates by validated transfers and never grows after initialization. Aggregate liquidity is not equally accessible working capital: money held by a baker cannot automatically fund a miller or a laborer. Obligations may move it through voluntary prepayment, not a loan or subsidy.

## Feasibility for the actual seeded opportunities

The production capacities above refer to two processors per occupation, each with the unchanged two-batch/work-turn policy and one work turn/day. The kernel's general crafting command itself is not a daily-capacity scheduler. The following calculation precedes interpretation of agent outcomes. Baseline columns apply also to target/price/wage/liquidity interventions; none changes the physical opportunity sequence. New bread excludes the six initialized bread; timely meal bounds include them. A positive annual aggregate buffer need not prevent early shortages.

| Seed | Days | Baseline: wheat / new bread bound / timely meals bound | Production buffer | Productivity: wheat / new bread bound / timely meals bound | Production buffer |
| --- | --- | --- | --- | --- | --- |
| 7 | 30 | 102 / 153 / 159 | -27 | 162 / 243 / 180 | 63 |
| 7 | 365 | 1456 / 2184 / 2130 | -6 | 2186 / 3279 / 2190 | 1089 |
| 42 | 30 | 122 / 183 / 180 | 3 | 182 / 273 / 180 | 93 |
| 42 | 365 | 1470 / 2205 / 2181 | 15 | 2200 / 3300 / 2190 | 1110 |
| 99 | 30 | 119 / 177 / 180 | -3 | 179 / 267 / 180 | 87 |
| 99 | 365 | 1482 / 2223 / 2178 | 33 | 2212 / 3318 / 2190 | 1128 |

At 365 days, baseline's physical/timing bound alone leaves at least 60/9/12 meals unmet for seeds 7/42/99, even ignoring money and distribution. Higher productivity removes that bound within these samples, allowing 2190 timely meals in the abstract pooled-food calculation. Actual economic outcomes below remain far below those bounds. In particular, the baseline seed-7 harvest can yield 2184 new bread plus six initial bread in total, yet early shortages cannot be repaired by later surpluses, giving only 2130 timely meals. This distinguishes timing, aggregate subsistence, and realized access.

## Actual production and meal outcomes

All 36 runs completed without changing parameters or policies after results. Baseline reproduces M6B's exact ledger. Every case conserved its initialized 115 coins, or 175 for extra liquidity. No rejected spot purchases or agreement lifecycle operations occurred in these runs: fresh observations caused waits/requests instead of impossible spot orders. Missed meals and failed employer payments remain real failures. Rejection behavior is exercised in focused tests.

The full [36-run table](M7_RUNS.csv) includes successful/failed purchases, agreements, payment failures, cash circulation, wealth, environmental hashes, replay hashes, and matched deltas. The [216-NPC table](M7_NPCS.csv) includes final inventories/balances, cumulative earnings/spending split by spot/prepayment/wage, production, trade, supplier selections, meals, affordability, and inactivity. All figures come from ledger receipts or explicitly identified post-run diagnostics; large ledgers stay in workspace artifacts.

Each cell's delta compares the intervention with its same-seed/same-horizon baseline. These are matched outcomes in this model, not optimal settings or evidence about real medieval economies.

### 30 days

| Seed | Configuration | Wheat harvested | Flour made | Bread made / physical bound | Meals eaten | Unmet | Meal delta |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | baseline | 99 | 96 | 144 / 153 | 144 | 36 | +0 |
| 7 | higher_productivity | 109 | 108 | 159 / 243 | 153 | 27 | +9 |
| 7 | higher_target | 99 | 96 | 144 / 153 | 144 | 36 | +0 |
| 7 | lower_food_price | 99 | 96 | 144 / 153 | 150 | 30 | +6 |
| 7 | higher_wage | 93 | 92 | 138 / 153 | 140 | 40 | -4 |
| 7 | extra_liquidity | 99 | 96 | 144 / 153 | 148 | 32 | +4 |
| 42 | baseline | 102 | 98 | 147 / 183 | 149 | 31 | +0 |
| 42 | higher_productivity | 110 | 106 | 156 / 273 | 151 | 29 | +2 |
| 42 | higher_target | 105 | 100 | 150 / 183 | 151 | 29 | +2 |
| 42 | lower_food_price | 110 | 106 | 159 / 183 | 164 | 16 | +15 |
| 42 | higher_wage | 100 | 98 | 147 / 183 | 146 | 34 | -3 |
| 42 | extra_liquidity | 99 | 98 | 147 / 183 | 152 | 28 | +3 |
| 99 | baseline | 93 | 92 | 138 / 177 | 137 | 43 | +0 |
| 99 | higher_productivity | 110 | 108 | 159 / 267 | 153 | 27 | +16 |
| 99 | higher_target | 95 | 92 | 138 / 177 | 137 | 43 | +0 |
| 99 | lower_food_price | 91 | 90 | 135 / 177 | 141 | 39 | +4 |
| 99 | higher_wage | 95 | 94 | 141 / 177 | 140 | 40 | +3 |
| 99 | extra_liquidity | 92 | 92 | 138 / 177 | 144 | 36 | +7 |

### 365 days

| Seed | Configuration | Wheat harvested | Flour made | Bread made / physical bound | Meals eaten | Unmet | Meal delta |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | baseline | 832 | 830 | 1242 / 2184 | 1243 | 947 | +0 |
| 7 | higher_productivity | 759 | 754 | 1128 / 3279 | 1130 | 1060 | -113 |
| 7 | higher_target | 836 | 830 | 1242 / 2184 | 1243 | 947 | +0 |
| 7 | lower_food_price | 1110 | 1108 | 1659 / 2184 | 1665 | 525 | +422 |
| 7 | higher_wage | 679 | 676 | 1011 / 2184 | 1013 | 1177 | -230 |
| 7 | extra_liquidity | 904 | 904 | 1356 / 2184 | 1356 | 834 | +113 |
| 42 | baseline | 743 | 738 | 1104 / 2205 | 1107 | 1083 | +0 |
| 42 | higher_productivity | 726 | 724 | 1083 / 3300 | 1085 | 1105 | -22 |
| 42 | higher_target | 767 | 760 | 1137 / 2205 | 1139 | 1051 | +32 |
| 42 | lower_food_price | 940 | 938 | 1401 / 2205 | 1404 | 786 | +297 |
| 42 | higher_wage | 664 | 660 | 987 / 2205 | 989 | 1201 | -118 |
| 42 | extra_liquidity | 910 | 908 | 1362 / 2205 | 1361 | 829 | +254 |
| 99 | baseline | 731 | 726 | 1086 / 2223 | 1089 | 1101 | +0 |
| 99 | higher_productivity | 759 | 754 | 1128 / 3318 | 1130 | 1060 | +41 |
| 99 | higher_target | 737 | 728 | 1089 / 2223 | 1093 | 1097 | +4 |
| 99 | lower_food_price | 1229 | 1224 | 1833 / 2223 | 1839 | 351 | +750 |
| 99 | higher_wage | 677 | 674 | 1008 / 2223 | 1011 | 1179 | -78 |
| 99 | extra_liquidity | 906 | 904 | 1356 / 2223 | 1356 | 834 | +267 |

### Interpretation of the isolated changes

- **Higher productivity:** annual meal deltas are **−113, −22, +41** (seeds 7/42/99), despite 1095 more potential new bread in each year. Ada harvests on 128/119/124 days rather than baseline's 211/186/186. A larger harvest can overshoot the unchanged four-wheat trigger and postpone work; altered transaction timing and capital distribution feed back into demand. Edda/Finn stop earlier in seeds 7/42. Potential resources do not automatically enter inventories, find buyers, or preserve another producer's capital. The higher productive bound is not a realized food-security guarantee.
- **Higher target:** annual deltas **0, +32, +4**. Seed 7 harvests four more wheat but produces/eats exactly the same food; the extra grain remains in Ada's final inventory (six rather than two). Seeds 42/99 show modest changes, not removal of finance/distribution limits. The higher target creates no extra weather draw or processing turn. Realized harvest frequency need not rise for every seed because different wait days select different opportunities.
- **Lower food price:** annual deltas **+422, +297, +750**, and all three 30-day comparisons improve. It changes food affordability and the existing millers' food-money reservation simultaneously through the same public price, while reducing the baker's gross batch margin from five to two. This is still one changed parameter, with several existing policy consequences. No physical potential increased. Aggregate access improves, but not every individual benefits, and concentration can worsen.
- **Higher wage:** annual deltas **−230, −118, −78**, although seed 99's 30-day meals improve by three. Actual successful payments fall to 36/35/38 days (108/105/114 coins) from baseline 195/204/204 days (390/408/408 coins). Dain eats only 38/37/40 meals versus 132/138/138. Ada attempts the whole payment before sales; an unaffordable transfer fails without partial pay, arrears, or extra income. The nominal three-coin payment covers one bread only when paid. This experiment models a fixed transfer obligation, not a labor market or a productivity response to wages; no broader wage-policy conclusion follows.
- **Extra liquidity:** annual deltas **+113, +254, +267**. Edda and Finn retain business activity near the horizon, unlike the long baseline stalls, but 834/829/834 meals remain unmet. Dain eats 130/134/132 meals, fewer than his matched baseline despite receiving ten more starting coins. Recurring wage/price arithmetic is unchanged, and Ada completes fewer employer transfers. More initial aggregate currency does not guarantee each actor better access or long-run stability.

No intervention dominates all metrics or all NPCs. Three seeds and one year do not establish robust calibration or statistical generality. The scenarios intentionally preserve deterministic scheduling and current policy limitations.

## Final money, concentration, and capital circulation

Every row's money vector sums to 115 or 175. Cora is the largest holder in all 18 annual outcomes. At day 30, lower-price seeds 7/42/99 instead have Finn/Bram/Dain as the largest holder, and extra-liquidity seed 42 has Finn; short-horizon rankings can differ. Shares are integer basis-point diagnostics, truncated to two decimal percent; accounting itself uses only integer coins. Circulation is cumulative **spot payments + prepayments + employer transfers**, counted once, not money creation. It may exceed the fixed money supply many times.

| Seed | Configuration | Coins: Ada / Bram / Edda / Cora / Finn / Dain | Largest share | Gross circulation | Matched circulation delta |
| --- | --- | --- | --- | --- | --- |
| 7 | baseline | 2 / 1 / 0 / 110 / 0 / 2 | 95.65% | 4606 | +0 |
| 7 | higher_productivity | 2 / 4 / 0 / 107 / 1 / 1 | 93.04% | 4252 | -354 |
| 7 | higher_target | 2 / 1 / 0 / 110 / 0 / 2 | 95.65% | 4606 | +0 |
| 7 | lower_food_price | 0 / 2 / 0 / 112 / 0 / 1 | 97.39% | 6062 | +1456 |
| 7 | higher_wage | 1 / 0 / 0 / 111 / 1 / 2 | 96.52% | 3556 | -1050 |
| 7 | extra_liquidity | 0 / 2 / 0 / 161 / 10 / 2 | 92.00% | 5013 | +407 |
| 42 | baseline | 0 / 3 / 0 / 109 / 1 / 2 | 94.78% | 4172 | +0 |
| 42 | higher_productivity | 2 / 4 / 0 / 107 / 1 / 1 | 93.04% | 4102 | -70 |
| 42 | higher_target | 2 / 4 / 0 / 108 / 0 / 1 | 93.91% | 4276 | +104 |
| 42 | lower_food_price | 0 / 26 / 0 / 88 / 0 / 1 | 76.52% | 4990 | +818 |
| 42 | higher_wage | 0 / 1 / 1 / 110 / 1 / 2 | 95.65% | 3472 | -700 |
| 42 | extra_liquidity | 0 / 4 / 2 / 148 / 21 / 0 | 84.57% | 5041 | +869 |
| 99 | baseline | 0 / 3 / 0 / 110 / 0 / 2 | 95.65% | 4112 | +0 |
| 99 | higher_productivity | 2 / 4 / 0 / 107 / 1 / 1 | 93.04% | 4252 | +140 |
| 99 | higher_target | 0 / 3 / 2 / 108 / 1 / 1 | 93.91% | 4117 | +5 |
| 99 | lower_food_price | 0 / 2 / 0 / 112 / 0 / 1 | 97.39% | 6750 | +2638 |
| 99 | higher_wage | 2 / 2 / 0 / 108 / 1 / 2 | 93.91% | 3557 | -555 |
| 99 | extra_liquidity | 2 / 4 / 2 / 159 / 8 / 0 | 90.85% | 5021 | +909 |

Lower food price improves total meals yet leaves Cora with 112/115 coins in seeds 7/99, more concentrated than baseline. Seed 42 instead leaves Cora 88 and Bram 26. Extra liquidity leaves Cora 148–161 coins out of 175: smaller shares than baseline but greater absolute holdings. A circulation or consumption increase does not establish equitable access. Full per-NPC cumulative `earned`/`spent` and their component flows are in `M7_NPCS.csv`; for every NPC, `final = initial + earned − spent`. Prepaid goods delivery adds no second money movement.

## Affordability and access by occupation

The following reports **meals eaten / days with cash at least the bread price at the food-choice snapshot**. Farmer/laborer denominators are 365; miller/baker denominators are 730 (two people). Affordability is measured from authoritative receipts before that actor's food command. It does not imply available stock, policy-approved discretionary cash, payment actually received every day, or goods reserved for later eating. `owned_food_days` is separately recorded per NPC. Both diagnostics can differ from meals eaten.

| Seed | Configuration | Farmer eaten / affordable | Millers eaten / affordable | Bakers eaten / affordable | Laborer eaten / affordable | Wage payments success / fail |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | baseline | 157 / 157 | 291 / 420 | 663 / 661 | 132 / 133 | 195 / 170 |
| 7 | higher_productivity | 125 / 125 | 266 / 364 | 600 / 592 | 139 / 139 | 205 / 160 |
| 7 | higher_target | 157 / 157 | 291 / 420 | 663 / 661 | 132 / 133 | 195 / 170 |
| 7 | lower_food_price | 347 / 349 | 576 / 597 | 516 / 650 | 226 / 250 | 223 / 142 |
| 7 | higher_wage | 200 / 200 | 240 / 345 | 535 / 537 | 38 / 39 | 36 / 329 |
| 7 | extra_liquidity | 191 / 191 | 324 / 461 | 711 / 730 | 130 / 135 | 187 / 178 |
| 42 | baseline | 121 / 121 | 261 / 374 | 587 / 585 | 138 / 139 | 204 / 161 |
| 42 | higher_productivity | 115 / 115 | 256 / 350 | 575 / 567 | 139 / 139 | 205 / 160 |
| 42 | higher_target | 129 / 129 | 268 / 385 | 605 / 599 | 137 / 138 | 202 / 163 |
| 42 | lower_food_price | 353 / 358 | 475 / 494 | 441 / 525 | 135 / 150 | 132 / 233 |
| 42 | higher_wage | 196 / 196 | 234 / 333 | 522 / 520 | 37 / 38 | 35 / 330 |
| 42 | extra_liquidity | 189 / 191 | 324 / 459 | 714 / 730 | 134 / 139 | 192 / 173 |
| 99 | baseline | 117 / 118 | 257 / 370 | 577 / 582 | 138 / 138 | 204 / 161 |
| 99 | higher_productivity | 125 / 125 | 266 / 364 | 600 / 592 | 139 / 139 | 205 / 160 |
| 99 | higher_target | 119 / 120 | 257 / 371 | 580 / 584 | 137 / 137 | 202 / 163 |
| 99 | lower_food_price | 351 / 353 | 634 / 657 | 574 / 706 | 280 / 307 | 277 / 88 |
| 99 | higher_wage | 197 / 197 | 240 / 342 | 534 / 537 | 40 / 41 | 38 / 327 |
| 99 | extra_liquidity | 189 / 191 | 324 / 462 | 711 / 730 | 132 / 139 | 189 / 176 |

This exposes a policy/scheduling limit distinct from cash poverty. In lower-price seed 7, Cora can afford food on all 365 food turns yet eats only 293 meals, versus baseline 361. On **day 53**, her decision 3394 waits with `food_already_covered` while she owns food and 32 coins. Dain then buys her last bread in purchase 3396 for two coins; her consumption 3404 fails for insufficient stock. Owned food is advertised and not reserved. Bakers also retain the inherited own-output convention instead of buying peers' bread. These are unchanged decision/execution rules; they were not corrected in M7. Reduced baker gross margins and changed customer affordability do not imply a simple or uniform baker welfare effect.

The unchanged commercial policy also judges a farmer's missing-request quantity against its original six-unit willingness limit, even in the more productive environment. No extra foresight, supplier intelligence, or commitment capacity was awarded to an intervention. Normal miller food reservation can block input spending even when some coins remain; commitment-first changes priority only for accepted obligations. These limitations help explain why physical opportunity, gross affordability, and realized access are different quantities.

## Agreements, inactivity, and individual business stalls

All runs have **zero whole-village business-inactive days** under the definition below, while individuals can stop. Successful agreements are backed by real prepayments and real delivery; outstanding records remain until fulfilled or explicitly closed. No waivers, refunds, rescues, or runtime currency injections occurred. Every outstanding agreement at the year horizon was accepted on day 365; these are boundary obligations, not assumed future deliveries.

| Seed | Configuration | Spot success / fail | Agreements accepted / fulfilled / outstanding | Edda last production / trailing business-idle days | Finn last production / trailing business-idle days |
| --- | --- | --- | --- | --- | --- |
| 7 | baseline | 1008 / 0 | 414 / 414 / 0 | 304 / 61 | 303 / 61 |
| 7 | higher_productivity | 1025 / 0 | 307 / 306 / 1 | 232 / 133 | 231 / 133 |
| 7 | higher_target | 1008 / 0 | 412 / 412 / 0 | 304 / 61 | 303 / 61 |
| 7 | lower_food_price | 1616 / 0 | 656 / 655 / 1 | 290 / 75 | 288 / 75 |
| 7 | higher_wage | 900 / 0 | 339 / 339 / 0 | 178 / 186 | 176 / 187 |
| 7 | extra_liquidity | 1063 / 0 | 446 / 445 / 1 | 364 / 1 | 364 / 0 |
| 42 | baseline | 961 / 0 | 373 / 372 / 1 | 225 / 140 | 224 / 140 |
| 42 | higher_productivity | 1007 / 0 | 290 / 289 / 1 | 207 / 158 | 206 / 158 |
| 42 | higher_target | 979 / 0 | 380 / 379 / 1 | 242 / 123 | 241 / 123 |
| 42 | lower_food_price | 1500 / 0 | 324 / 324 / 0 | 165 / 200 | 165 / 200 |
| 42 | higher_wage | 906 / 0 | 331 / 331 / 0 | 160 / 205 | 160 / 203 |
| 42 | extra_liquidity | 1079 / 0 | 456 / 455 / 1 | 364 / 1 | 364 / 0 |
| 99 | baseline | 946 / 0 | 365 / 364 / 1 | 221 / 143 | 221 / 144 |
| 99 | higher_productivity | 1020 / 0 | 312 / 311 / 1 | 232 / 133 | 231 / 133 |
| 99 | higher_target | 946 / 0 | 364 / 363 / 1 | 223 / 142 | 223 / 140 |
| 99 | lower_food_price | 1765 / 0 | 710 / 709 / 1 | 346 / 19 | 344 / 19 |
| 99 | higher_wage | 909 / 0 | 337 / 336 / 1 | 176 / 189 | 176 / 187 |
| 99 | extra_liquidity | 1068 / 0 | 464 / 462 / 2 | 365 / 0 | 365 / 0 |

`production_idle_days` counts days without successful harvest/crafting (null for laborer). A business-active day has a successful harvest, crafting, spot purchase/sale, agreement acceptance, or fulfillment involving that NPC. Consuming food, attempting/receiving wages, and merely posting an offer/request do not count as business. Thus wage cash circulation can coexist with business inactivity. Last/trailing days describe the observed horizon, not whether activity could ever resume. All per-NPC total idle days and last days are in the CSV.

`underfunded_without_active_request` means an input processor has no sellable occupation output, lacks cash for the missing inputs of one minimum batch, and has no own active incoming/outgoing request. It is an end-of-run diagnostic, not a formal absorbing-state proof. It can flag a recent one-day shortage, miss an unsold-output stall, or be resolved by a later voluntary prepaid opportunity. It is never used to rescue an actor or choose policy actions.

For example, lower-price seed 42 leaves Edda inactive for 200 business days with no money and one unsold flour. Her underfunding flag is false because flour is still sellable in principle; the long observed stall is nevertheless visible. Finn's one-flour partial batch and insufficient cash are a recurring input deadlock pattern. In higher-productivity seeds 7/42, Edda/Finn cease production earlier than baseline; in extra-liquidity cases they work on days 364/365, so an end-state underfunding flag alone should not be labeled an established collapse. Future recovery or permanence beyond 365 was not tested.

## Implementation and validation boundaries

`calibration_config.gd` contains the fixed presets and exact-key validation. `calibration_runner.gd` inherits M6B's schedule/policy, substitutes copied initial money and farmer goal, and overrides wage/yield hooks. `calibration_world.gd` supplies fixed instance prices and the authorized harvest range. Price hooks govern public offers, decision checks, request payments, and overflow checks consistently; actual exchanges still use the unchanged kernel. The historical singleton defaults remain unchanged. Calibration baseline has identical economic events and inherited report fields to M6B; new configuration/potential/diagnostic fields identify the laboratory.

The API accepts only bounded integers: positive target, prices and daily payment; nonnegative per-NPC balances; nonnegative harvest bonus at most `MAX_AMOUNT − 6`. Positive laboratory prices avoid division by zero in unchanged policies. The underlying M1 zero-price purchase command remains supported. Zero wages/targets are rejected rather than silently changing existing command semantics; custom rules outside the laboratory's parameter set are rejected. Custom configuration support is for reproducible fixed conditions, not runtime repricing. Initial/configuration/observation/report dictionaries are copies. No private global result metrics enter NPC observations.

`calibration_report.gd` reconstructs money and bread for food snapshots and computes physical bounds without advancing the simulation RNG. `run_calibration.py` invokes the Godot CLI; it does not implement alternative agent behavior. It repeats each case in independent processes, matches underlying draw arrays/hashes across configurations, compares each baseline history with M6B, independently reconstructs every event and agreement receipt, checks bounded holdings/conserved currency, and audits per-NPC flows/food snapshots/activity metrics and wealth. Compact CSVs are projections of those checked reports. Large generated JSON captures are not committed.

## Verification, failures, and reproduction

Base: M6B `57c923b`. Runtime: **Godot 4.6.3**. Pre-change suite: **1780 checks, 0 failures**. Final complete suite: **2504 checks, 0 failures**, retaining every historical check and adding 724. Tests cover preset isolation and copies, strict parameter validation, all three price paths, lower/higher price trades, stale funds, overflow/capacity safeguards, agreement terms/failed delivery, trusted environmental yields, privacy, zero-day reports, physical bounds, all six presets at both horizons, full ledger reconstruction, split replay, and exact M6B baseline equivalence. All **23 historical CLI captures** match their published hashes and their pre-change bytes; historical result documents remain unchanged.

All **36 cases** ran twice in independent processes with identical JSON and empty stderr. The driver audited each complete ledger, then an additional audit of all 36 saved captures checked the final activity/wealth/circulation assertions. Twelve readable calibration commands (all presets, both horizons, seed 42) included all six NPCs. The omitted experiment selector matched explicit baseline byte-for-byte. Invalid/missing experiment, experiment on a legacy scenario, invalid priority, and invalid day options returned expected exit 2. Editor import, Python syntax compilation, and `git diff --check` passed. Final Godot test/import logs contain no script errors.

Two development harness/fixture issues were corrected: the first capture harness double-counted six M6 rows (29 instead of 23); its input selection was fixed before capturing baselines. An early expanded test run encountered a script error because a price-test fixture had already cleared Dain's meal need but expected a purchase; advancing its test day fixed the fixture. That run's zero assertion-failure count was not treated as a pass. The corrected full run passes all 2504 checks without script errors. No unresolved test, simulation, audit, or import failure remains. No economic preset or decision policy was changed in response to outcomes.

Actual commands used the writable XDG setup from README:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import
python3 scripts/tools/run_calibration.py --output /workspace/work/m7
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario calibration --experiment lower_food_price 365 42
git diff --check
```

The committed Python tool runs seeds 7/42/99, horizons 30/365, and the six fixed presets using `--headless --no-header ... --json`, asserts empty stderr and identical independent captures, and writes `runs.csv`/`npcs.csv`. Actual full captures are `/workspace/work/m7/{experiment}-{seed}-{days}.json`; repeat bytes were compared in memory. Historical captures/logs use `/workspace/work/m7-baseline-*` and `m7-verified-hashes.txt`. The first CSV contains all new full-output SHA-256 hashes and matched environment hashes. Earlier published hashes remain in [M6B results](M6B_RESULTS.md). Reproduction assumes the same Godot version and fixed rules.

## Limits and suggested future calibration directions (not implemented)

- Define explicit assessment goals before choosing settings: aggregate meals, worst-served occupation, capital continuity, and concentration can move in different directions. No winner or optimal medieval price system is established here.
- Predeclare a larger seed sample and longer horizons before repeating the fixed comparisons. Three seeds/one year do not establish stable equilibria or statistical robustness; cross-version RNG replay, persistence, and longer-term recovery remain unverified.
- A future matched experiment could distinguish aggregate starting liquidity from its distribution while holding total money fixed. The current +10-per-person intervention changes both total supply and relative initial shares.
- Consider future paired wage/price/yield combinations only as a new declared experiment: recurring household budgets and gross processing margins must be feasible together. No combination, automatic optimizer, subsidy, or gameplay cash injection was tested or added here.
- Hold economic parameters fixed in any later comparison of scheduling, food-stock retention, batch/input budgeting, or request priorities. Current output targets, food reservations, late customer purchases, one-turn production, and one accepted supplier obligation remain agent/scheduling limitations. M7 changes none of them.
- Gross ingredient margins omit operating expenses and actors' own food opportunity cost. Adding realism would require an explicitly scoped future model; these numbers should not be presented as net profits or historical-economic estimates.

Files changed: four new calibration configuration/world/runner/report scripts and UIDs; narrow hooks in `agent_world.gd`, `coordination_world.gd`, `market_world.gd`, and `market_runner.gd`; CLI selection in `run_simulation.gd`; the standard-library batch/audit tool; focused Godot tests and registration; README, architecture, roadmap, this report, and the two compact result CSVs. `world_state.gd`, all decision policy files, recipes, agreement transitions, and prior result documents are unchanged.

Stop after M7 for review. Suggested future changes are not implemented. M8 has not started.
