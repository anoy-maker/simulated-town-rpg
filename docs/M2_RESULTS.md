# M2 — The Trading Village: actual results

M2 adds a separate fixed-price trading scenario. M0/M1 are preserved. The experiment ran for 30 and 365 days with seed 42, without changing its endowments, prices, payment, or rules after observing economic outcomes. M3 has not started.

## Fixed assumptions

Initial state is exactly M0's: Ada/Bram/Cora/Dain hold 30/20/20/5 coins and one bread each, with zero wheat and flour. Total currency is 75 coins. Unit prices are wheat **1**, flour **2**, bread **3** coins. Money and stack limits remain one billion. Bread does not spoil; missed meals have no health/death effect.

The daily order is fixed:

1. Advance the day. Ada attempts a 2-coin employer payment to Dain from her existing balance.
2. Ada harvests 2–6 wheat from the existing private seeded RNG.
3. Bram attempts to purchase four wheat from Ada for four coins, then mills twice: four wheat → four flour.
4. Cora attempts to purchase four flour from Bram for eight coins, then bakes twice: four flour → six bread.
5. Ada, Bram, and Dain each attempt to purchase one bread from Cora for three coins, in that order.
6. Ada, Bram, Cora, and Dain each attempt to consume one owned bread. Cora uses her own stock rather than self-purchasing.

Every goods exchange uses M1 `world.purchase()`. The employer payment uses `world.transfer_money()`; it is a fixed transfer, with no generalized employment records, work requirements, or arrears. All attempts occur even if a previous action failed or an NPC still has bread. Failed transactions create neither resources nor currency; no partial order, retry, subsidy, or rescue follows. Harvest continues even after a missed payment. Production can use only actual owned inputs. Initial bread may cover a failed purchase until it is depleted.

These are scripted attempts, not autonomous decisions. There is no negotiation, dynamic pricing, debt, relationship system, LLM, Director, or graphics.

## Final state and per-NPC cash flow

Earned money includes sales and employer payments received; spent money includes purchases and employer payments sent. Only successful events contribute. Each balance reconciles as initial + earned − spent.

| Days | NPC | Final coins | Earned | Spent | Wheat | Flour | Bread | Unmet meals |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 30 | Ada | 2 | 116 | 144 | 6 | 0 | 1 | 0 |
| 30 | Bram | 46 | 232 | 206 | 0 | 0 | 1 | 0 |
| 30 | Cora | 25 | 237 | 232 | 0 | 0 | 66 | 0 |
| 30 | Dain | 2 | 54 | 57 | 0 | 0 | 0 | 10 |
| 365 | Ada | 1 | 1448 | 1477 | 22 | 0 | 0 | 1 |
| 365 | Bram | 61 | 2584 | 2543 | 0 | 156 | 1 | 0 |
| 365 | Cora | 13 | 2577 | 2584 | 0 | 0 | 715 | 0 |
| 365 | Dain | 0 | 388 | 393 | 0 | 0 | 0 | 233 |

Total money remains **75 coins** at both horizons. Ada's spending includes 54 coins of employer payments after 30 days and 388 after 365; the remainder buys bread. Dain's earnings are entirely those payments. All other earnings are goods sales; Bram/Cora spending is entirely purchases.

## Purchases and goods accounting

| Days | Item | Successful purchases | Rejected purchases | Quantity traded | Coins paid |
| ---: | --- | ---: | ---: | ---: | ---: |
| 30 | Wheat | 29 | 1 | 116 | 116 |
| 30 | Flour | 29 | 1 | 116 | 232 |
| 30 | Bread | 79 | 11 | 79 | 237 |
| 365 | Wheat | 362 | 3 | 1448 | 1448 |
| 365 | Flour | 323 | 42 | 1292 | 2584 |
| 365 | Bread | 859 | 236 | 859 | 2577 |

Totals: **137 successful / 13 rejected purchases** after 30 days; **1544 successful / 281 rejected** after 365. There are five scripted purchase attempts per day. Successful employer payments: **27 / 30** (54 coins) and **194 / 365** (388 coins); the other 3 and 171 payments fail without moving money.

| Accounting measure | 30 days | 365 days |
| --- | ---: | ---: |
| Wheat harvested | 122 | 1470 |
| Wheat consumed by milling | 116 | 1448 |
| Flour produced | 116 | 1448 |
| Flour consumed by baking | 116 | 1292 |
| Bread produced | 174 | 1938 |
| Bread consumed | 110 | 1226 |
| Unmet meals | 10 | 234 |
| Final total wheat | 6 | 22 |
| Final total flour | 0 | 156 |
| Final total bread | 68 | 716 |
| Event records | 421 | 5111 |

Examples of reconciliation: 365-day wheat is 1470 − 1448 = 22; flour is 1448 − 1292 = 156; bread is 4 initial + 1938 produced − 1226 eaten = 716. Food needs reconcile as 1226 eaten + 234 unmet = 1460 (= 4 × 365). Trades move existing goods; they do not add to production totals.

## Economic failures and observed behavior

| Rejected action / cause | 30 days | 365 days |
| --- | ---: | ---: |
| Bram buys wheat: insufficient stock | 1 | 3 |
| Cora buys flour: insufficient stock | 1 | 1 |
| Cora buys flour: insufficient money | 0 | 41 |
| Ada buys bread: insufficient money | 0 | 2 |
| Dain buys bread: insufficient money | 11 | 234 |
| Bram mills: insufficient stock | 1 | 3 |
| Cora bakes: insufficient stock | 1 | 42 |
| Ada pays Dain: insufficient money | 3 | 171 |
| Ada eats: insufficient stock | 0 | 1 |
| Dain eats: insufficient stock | 10 | 233 |

The first wheat shortage occurs on day 3 and propagates to milling, flour purchase, and baking. Existing bread covers meals that day. Dain's first unaffordable bread purchase is day 6; his first missed meal is day 9. His two-coin payment is below the three-coin bread price even on days it succeeds, and Ada first fails to pay him on day 26. Payments precede same-day wheat revenue, so later sales cannot retroactively fund a failed payment.

By day 49, Cora first cannot afford a flour purchase. She continues holding unsold bread; it is not converted into cash automatically. Bram can continue milling owned wheat and accumulate flour that Cora cannot buy. Ada's first rejected bread purchase is day 98; her one missed meal is day 111. The report's failure groups include the exact actor, target, resource/recipe, reason, count, and first/last day; the full JSON includes every event.

At 365 days, Bram holds 61 of 75 coins; Cora holds 715 bread, while Dain has no coins or bread and has missed 233 meals. This demonstrates financial scarcity alongside abundant food. These outcomes were retained, without price changes, subsidies, altered starting resources, or production-planning fixes.

## Verification and reproducibility

Base commit: M1 `db5c1d8`. Runtime: **Godot 4.6.3**. Before changes, all **436 M0/M1 checks passed**. The final suite passed **530 checks, 0 failures**: all 436 prior checks plus 94 trading checks. Headless editor import and `git diff --check` also passed.

New coverage includes exact first-day operation order/cash flows, retained endowments, no-rescue behavior under zero-money/zero-food test conditions, 30/365-day ledger reconstruction, currency and commodity reconciliation, per-NPC cash flows and meals, trade/payment counts, failure grouping, report isolation, same-seed/split-run replay, different-seed harvests, and the historical M0 JSON hash.

An initial test attempt failed to parse a multiline filter lambda in the new test module. That syntax error was corrected before the successful full-suite run. No unresolved test failures remain.

Actual verification used the existing writable workspace directories:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import

# Original default CLI path and explicit M0 selector.
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/m2-m0-after.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario m0 30 42 --json > /workspace/work/m2-m0-explicit.json
cmp /workspace/work/m2-m0-before.json /workspace/work/m2-m0-after.json
cmp /workspace/work/m2-m0-after.json /workspace/work/m2-m0-explicit.json

# Trading runs, each repeated in a separate process with the same arguments.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 30 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 30 42 --json > /workspace/work/m2-trading-30-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 365 42 --json > /workspace/work/m2-trading-365-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 30 42 --json > /workspace/work/m2-trading-30-b.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario trading 365 42 --json > /workspace/work/m2-trading-365-b.json
cmp /workspace/work/m2-trading-30-a.json /workspace/work/m2-trading-30-b.json
cmp /workspace/work/m2-trading-365-a.json /workspace/work/m2-trading-365-b.json
sha256sum /workspace/work/m2-m0-after.json /workspace/work/m2-trading-30-a.json /workspace/work/m2-trading-365-a.json
git diff --check
```

All comparisons passed, with byte-identical complete reports and histories. The pre-change M0 capture was produced with the same original CLI command before implementation. The no-argument text output was also compared against the original CLI script from M1 commit `db5c1d8` and was byte-identical. An unknown scenario returned the expected exit 2 with `Scenario must be m0 or trading.` The 365-day readable trading command also completed successfully. SHA-256 results:

| Scenario | SHA-256 |
| --- | --- |
| M0, 30 days, seed 42 | `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9` |
| Trading, 30 days, seed 42 | `5d569a193111d3ad5ff90dc6317b567596c4b51b4fe54c11e676e3eda0bcd9aa` |
| Trading, 365 days, seed 42 | `e564ebe6f5638be17f8cfe2b78748bbaebb7907d818a9ade1247b7624ea12278` |

Only Godot 4.6.3 was verified; cross-version RNG equivalence and runs beyond 365 days were not verified. CLI input is bounded to 10,000 days, and events remain in memory. Complete generated logs are reproducible with these commands and are not committed.

## Files changed

- `scripts/sim/trading_runner.gd` and UID: scenario and event-derived economic report.
- `scripts/tools/run_simulation.gd`: explicit scenario selection and readable trading output; the original default output remains unchanged.
- `tests/trading_tests.gd` and UID, `tests/run_tests.gd`: new coverage after the existing 436 checks.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/M2_RESULTS.md`: contract, assumptions, current scope, and actual results.

M2 ends with this experiment and its observations. No economic imbalance was corrected and no M3 work was begun.
