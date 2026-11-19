# M11 — Deterministic Economic Equilibrium Reference

## Prescribed reference and architecture decision

This isolated `settlement_equilibrium_reference` is a mathematical feasibility test with prescribed decisions. **It does not demonstrate autonomous stability**, and adopts no M9/M10 economy as viable. No policies search for equilibrium.

Inspection found that M9 already supports configurable compensation, employment eligibility, paid productive shifts, real-input recipes, purchases and meals. Only its inline fixed prices/harvest draw need two default-preserving methods. A thin reference subclass overrides these constants; a small scheduler reuses every original transaction/labor command. There is no kernel rewrite, new money account type, withdrawal mechanism or economic subsystem. Historical M0–M10 constants and policy choices stay unchanged.

Copy the original twelve residents, three owners and nine employment relationships. Every resident starts with **6 coins and zero food**. Every business starts with **120 coins and zero commodities**. All 15 accounts together contain **432 coins**. Prices are wheat **2**, flour **4**, bread **4**; each completed shift pays **8**. Harvest is **4 wheat/shift**, only here. Milling/baking use the original two-batch recipes: four wheat → four flour, four flour → six bread. Productive slots, skills and one full shift/person/day remain M9's. No loans, subsidies, free food, withdrawals or balance resets.

Within each business, take owner first then employee IDs ascending; alternate its two pairs:

| Business | Odd-day workers | Even-day workers |
| --- | --- | --- |
| farm | Ada, Dain | Edda, Gale |
| mill | Bram, Hale | Jory, Lyle |
| bakery | Cora, Finn | Iona, Kira |

Each day the farm pays/harvests two shifts. The mill buys eight wheat, pays/mills two shifts. The bakery buys eight flour, pays/bakes two shifts. All twelve residents then buy one bread in resident-ID order and each eats one. Scheduling an employee does not consume an additional owner work shift; administrative labor is not separately modeled, as in M9. Unselected employees' environmental opportunities are not production. All production still requires accepted, funded labor.

| Business | Daily sales | Input purchases | Wages | Net cash change | End-of-day money |
| --- | --- | --- | --- | --- | --- |
| farm | 16 | 0 | 16 | 0 | 120 |
| mill | 32 | 16 | 16 | 0 | 120 |
| bakery | 48 | 32 | 16 | 0 | 120 |

Daily production is 8 wheat, 8 flour, 12 bread. Daily consumption is 12 bread, leaving zero commodities everywhere. Daily paid labor is six shifts, daily wages 48, and total cash circulation 144 (48 input purchases + 48 household purchases + 48 wages), without changing the currency supply.

Every household earns eight coins per two days and spends eight. On odd-day endings the six first-group residents have 10 coins and the other six have 2; on even-day endings everyone has 6. Businesses' cash/inventory repeat daily; households' financial/inventory state repeats every two days. Calendar, ledger and cumulative earnings naturally advance. These are predictions to verify through actual commands, not assignments made by the scheduler.

## Actual verification results

**The exact scheduled reference passes.** All required horizons produce the predicted meals, paid shifts, money distribution and zero ending stocks through real transactions. This demonstrates feasibility of the existing authority under prescribed decisions; it is not evidence of autonomous stability or discovery.

| Days | Wheat harvested | Flour produced | Bread produced / eaten | Paid shifts | Missed meals | Currency | Household cash at end |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 8 | 8 | 12 / 12 | 6 | 0 | 432 | Six at 10; six at 2 |
| 2 | 16 | 16 | 24 / 24 | 12 | 0 | 432 | All twelve at 6 |
| 30 | 240 | 240 | 360 / 360 | 180 | 0 | 432 | All twelve at 6 |
| 365 | 2920 | 2920 | 4380 / 4380 | 2190 | 0 | 432 | Six at 10; six at 2 |

All three businesses end **every simulated day at 120 coins**. All fifteen accounts end every day with **zero wheat, flour and bread**. The ledger reconstruction checks the 432-coin supply and bounded, nonnegative balances after every event, not just at each horizon. Every successful payroll/production receipt belongs to exactly one actual shift; no free work, goods gift, withdrawal, debt or cash source is present. Daily harvest is exactly eight wheat, daily recipe output eight flour and twelve bread, and every person eats once daily.

The annual source/sink equations are exact: `0 + 2920 harvested − 2920 milled = 0 wheat`; `0 + 2920 flour made − 2920 baked = 0 flour`; `0 + 4380 bread made − 4380 eaten = 0 bread`. These are ledger totals, not post-run corrections. Each business provides 730 shifts and pays 5840 coins. Total wages are 17,520 and gross circulation is 52,560; those are repeated movements of the same 432 coins.

| Business, 365 days | Sales | Input purchases | Wages | Final cash |
| --- | --- | --- | --- | --- |
| farm | 5840 | 0 | 5840 | 120 |
| mill | 11680 | 5840 | 5840 | 120 |
| bakery | 17520 | 11680 | 5840 | 120 |

| Residents, 365 days | Shifts per person | Wages per person | Bread expenditure per person | Meals per person | Final coins per person |
| --- | --- | --- | --- | --- | --- |
| Ada, Dain, Bram, Hale, Cora, Finn | 183 | 1464 | 1460 | 365 | 10 |
| Edda, Gale, Jory, Lyle, Iona, Kira | 182 | 1456 | 1460 | 365 | 2 |

At every even-day boundary each person has one shift per completed two-day cycle and returns to six coins. On day 365 the odd group has one extra shift because the final cycle is half-complete. Each person's final balance independently reconciles `6 + wages − bread purchases`. All personal inventories are zero.

### Explicit recurrence and reconstruction

The in-process checker reconstructs every entity's money and inventory from initialization and successful receipts. It verifies all 365 end-of-day checkpoints: actual daily output, purchases and meals; two eligible workers per industry with no duplicate daily worker; eight-coin pay linked to real production; zero stocks; and each business at 120. Each household's odd/even financial/inventory state is compared with its previous same-parity state, with even-day states also compared against initialization. This explicitly checks the one-day business and two-day household recurrence. Day, log length, cumulative wages, offers and daily labor bookkeeping naturally advance; they are not claimed to be timeless repeating history.

A copied-ledger fault test changes an eight-coin wage to seven: total currency remains conserved, but the checker rejects the business/household cycle. Authority tests reject missing-stock purchases, unpaid harvest and historical prices in the reference without partial mutation. Public offers and purchases agree on 2/4/4 prices. The unchanged independent Python labor auditor also reconstructs a two-day reference, covering every worker and all native offer/payment/production lifecycle records.

All four required horizons pass split-run replay of their complete in-memory ledger, world snapshot and report. Independently launched processes reproduce each compact report byte-for-byte, including its complete ledger SHA-256. Two-day traces at seeds 7 and 99 are identical: reference opportunities are constant, so the economic schedule has no random seed dependency. Seed 42 labels the four reported runs; the seed argument remains compatible with the existing CLI.

[Four compact run records](M11_RUNS.csv) contain actual totals, canonical ledger hashes, report hashes and output byte counts. `ledger_sha256` hashes Godot's compact sorted-key JSON encoding of all events; `summary_sha256` hashes report-only CLI stdout including its newline. No full-year event dump was generated or saved for this reference. Annual verification uses in-memory receipts; its report-only JSON is 14,879 bytes, and readable output is eight lines.

### Tests and historical compatibility

Base: M10 commit `f771628`; runtime **Godot 4.6.3**. Pre-change suite: **2615 checks, zero failures**. Full suite: **2673 checks, zero failures**, preserving all previous coverage and adding 58 focused reference checks. All **18 Python tests** pass (16 previous plus the two reference/audit-output tests). The focused checks pass for 1, 2, 30 and 365 days. No unexpected test, simulation, audit, replay or import failure remains.

All **89 previously pinned M0–M10 JSON outputs remain byte-identical**: 23 through M6B, 36 M7, six M8, six M9 and eighteen M10. Only default-preserving price/opportunity methods change the existing labor authority; the original kernel, recipes, configurations, NPC policies, M9/M10 runners and historical result tables remain unchanged. No reference parameter or old policy was tuned after seeing results. Headless editor import, compact/readable CLI runs, and `git diff --check` pass.

Actual verification commands use the README writable XDG setup:

```sh
godot --headless --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py' -v
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 1 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 2 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 365 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_equilibrium_reference 365 42 --report-json
godot --headless --editor --path . --import
git diff --check
```

Workspace results are `/workspace/work/m11/reference-{days}.txt` and `reference-{days}-summary.json`; the compact CSV is copied unchanged into docs. The ordinary `--json` diagnostic remains available for short traces, but was not used for annual reference output. There is no new history storage or economic subsystem. The in-memory append-only ledger and copied reports retain the existing scaling limits.

### Deviations, assumptions and limits

There are **no economic deviations from the requested reference**. The only deterministic tie choice is the documented owner-first/employee-ID pairing. All original relationships, skills and productive assets are retained. Existing inventory targets remain metadata; the autonomous target-based policies are not run. Scheduling offers does not add administrative work or compensation beyond the specified shifts.

This result assumes exactly these prices, wages, initial buffers, fixed productive opportunities, accepted alternating shifts, and transaction order. It does not test shortages, absences, shocks, extra sectors, price discovery, negotiations, incentives, independent policy choices or a route from M9/M10 to this state. The prescribed cycle and its financial identities support repetition under unchanged assumptions; actual simulation verification stops at 365 days. Cross-version replay and larger populations/horizons are unverified. This reference is not adopted as an autonomous default.

Files changed: three small reference config/world/runner scripts and their UIDs; two protected methods and call sites in `labor_world.gd`; CLI scenario/concise output support; focused in-memory Godot checks and Python tests; README/architecture/roadmap, this document and a four-row CSV. No historical scenario's economic behavior changes, and no account balances/inventories are reset after initialization.

Stop after M11 for review. No subsequent milestone, sector expansion or new autonomous behavior has begun.
