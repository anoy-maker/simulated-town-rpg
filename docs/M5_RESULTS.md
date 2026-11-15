# M5 — Commitment-Aware Planning: actual results

M5 adds a separate `planning` scenario with two configurable spending priorities. Both use the same information, cost model, action capabilities, schedule, resources, and authoritative M4 world. The policies were fixed before inspecting results, including the additional predefined seeds 7, 42, and 99. M0/M2/M3/M4 remain unchanged. M6 has not started.

## Assumptions and common implementation

Initial holdings remain Ada/Bram/Cora/Dain's 30/20/20/5 coins and one bread each; wheat/flour start at zero. Prices remain wheat 1, flour 2, bread 3. Recipes remain two wheat → two flour and two flour → three bread. Goals remain food 1, outputs 4 wheat / 4 flour / 6 bread, with max two batches per work turn. Ada attempts the same two-coin payment before sales. M4's request eligibility, immutable terms, prepayment, full delivery, duplicate limits, daily notifications, and absence of automatic refunds/waivers remain unchanged.

`planning_policy.gd` computes a common plan from the supplier's own accepted obligation, owned output/inputs, own cash, public recipe rules, and public input prices/stock:

1. Subtract owned deliverable output from the accepted quantity.
2. Round required production up to whole recipe batches.
3. Subtract owned recipe inputs from those required inputs.
4. Price the remaining input units using public offers. No anticipated income or other NPC's balance is assumed.
5. Identify whether stock is ready, production inputs are owned, input cash is insufficient, public supply is short, or inputs are currently fundable.

Farmer harvest needs no purchased-input budget. Missing supply remains missing; incoming unfulfilled promises do not count as owned stock. The replacement-cost estimate conservatively includes missing ingredients even while prepaid inputs are awaited. Partial affordable input purchases are possible, but production still requires actual complete recipe inputs.

**Commitment-first:** obligation inputs may use current cash; food or unrelated advance spending uses `max(0, cash − missing_input_cost)`.

**Immediate-needs-first:** food may use current cash; obligation input purchases/advances use `max(0, cash − missing_food_cost)`. Non-bakers calculate food cost from missing current target bread. Cora produces her own food rather than reserving money for a self-purchase.

Both modes share the same commitment-specific input quantities, batch calculations, production/delivery logic, and M4 commercial acceptance logic. With no supplier obligation, both use the existing M4 policy. Their sole priority difference is allocation of spending capacity. Neither gets extra turns, resources, market knowledge, or forecasts. The priority applies village-wide for a matched comparison. It governs cash spending; M4's physical goods, delivery, meal, and wage rules remain unchanged.

## Advisory budget and decision records

Budgeting creates no account, escrow, new money balance, or enforcement. It is recalculated before each decision from a fresh permitted observation. The unchanged world still permits a direct affordable purchase even if the policy would retain its funds; a focused test verifies this. Every selected action is executed through existing world methods and current funds/stock are revalidated.

Existing `decision` events retain actor, phase, proposal, reason, execution outcome, and command-event link. The proposal now includes `selected_action.planning`: priority, request ID, output/input shortfall, batches, known cost, cash, public availability, food cost, status, and input/discretionary spending budgets. The executor records that annotation but does not treat it as authority to spend or create goods.

Reasons distinguish `spend_immediate_needs`, `reserve_obligation_capital`, `acquire_obligation_inputs`, `produce_for_obligation`, `unable_to_satisfy_obligation`, and `fulfill_obligation`. A fulfillment reason describes intent; the linked world event and execution outcome determine success. Waiting under a budget is not a rejected purchase or an additional economic loss.

`planning_runner.gd` inherits M4's scheduler, world, RNG behavior, and economic report. It adds the priority, end-of-run cost estimates, and activity counts after historical day 26. Latest-activity day fields cover the whole run. The day-26 cutoff affects reporting only.

## Focused reproduction of the M4 failure

A controlled matched fixture gives Bram no food, no ingredients, and four coins after Cora prepays for two flour. Ada advertises wheat and Cora advertises bread. Both modes observe the same facts: two wheat cost two coins; one bread costs three. The money is transferred from the buyer through the real acceptance operation.

- M4 buys bread, leaving one coin, then purchases only one wheat and cannot mill the promised flour.
- Commitment-first logs a two-coin input requirement and declines the unaffordable discretionary bread purchase. In the next work turn it buys two wheat, mills, and fulfills the two-flour agreement. It foregoes the current meal in this fixture.
- Immediate-needs-first buys and consumes bread. The agreement remains underfunded and outstanding; no flour, refund, or extra money is invented.

Both modes begin with identical fixture state and use the same authority. Additional tests show that commitment-first does buy food when cash covers both costs; owned inputs reduce the budget; owned delivery stock frees it; whole-batch rounding is respected; unavailable supply stays unavailable; and stale/falsified planning annotations cannot override execution validation. These fixture conditions are unit-test boundaries, not changed starting resources for the reported village runs.

## Main results: seed 42

CF denotes commitment-first; NF denotes immediate-needs-first. M4 is the unchanged historical comparison.

| Measure | M4: 30 | CF: 30 | NF: 30 | M4: 365 | CF: 365 | NF: 365 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Agreements accepted | 4 | 5 | 3 | 4 | 206 | 3 |
| Agreements fulfilled | 3 | 4 | 2 | 3 | 205 | 2 |
| Agreements outstanding | 1 | 1 | 1 | 1 | 1 | 1 |
| Spot purchases, successful / failed | 104 / 0 | 104 / 0 | 100 / 0 | 104 / 0 | 573 / 0 | 100 / 0 |
| Prepayments transferred | 14 | 18 | 10 | 14 | 822 | 10 |
| Wheat harvested | 64 | 64 | 61 | 64 | 467 | 61 |
| Flour produced | 58 | 60 | 56 | 58 | 462 | 56 |
| Bread produced | 87 | 90 | 84 | 87 | 693 | 84 |
| Meals consumed | 91 | 91 | 88 | 91 | 694 | 88 |
| Unmet meals | 29 | 29 | 32 | 1369 | 766 | 1372 |
| Employer payments, successful / failed | 23 / 7 | 24 / 6 | 22 / 8 | 23 / 342 | 225 / 140 | 22 / 343 |
| Gross cash transferred | 399 | 406 | 384 | 399 | 2818 | 384 |
| Total currency | 75 | 75 | 75 | 75 | 75 | 75 |

Gross circulation counts cumulative real transfers of the same coins, not newly created money. CF's year total is 1546 coins in spot purchases + 822 in prepayments + 450 in employer payments = 2818. NF transfers 330 + 10 + 44 = 384. Fulfillment transfers goods without another payment. Neither strategy closed or waived an obligation, and neither had a lifecycle rejection in these default runs. Unit tests retain coverage of rejection and closure.

### Activity after day 26

| Measure | CF: 30 | NF: 30 | CF: 365 | NF: 365 |
| --- | ---: | ---: | ---: | ---: |
| Successful spot purchases after day 26 | 5 | 1 | 474 | 1 |
| Failed spot purchases after day 26 | 0 | 0 | 0 | 0 |
| Production commands after day 26 | 4 | 0 | 406 | 0 |
| Agreements accepted after day 26 | 3 | 1 | 204 | 1 |
| Agreements fulfilled after day 26 | 2 | 0 | 203 | 0 |
| Latest production day | 29 | 26 | 364 | 26 |
| Latest fulfillment day | 29 | 8 | 364 | 8 |
| Latest purchase day | 30 | 27 | 365 | 27 |

CF fulfills r3 on day 28 and the M4-style failing r4 on day 29. It continues a sequence of prepaid flour orders through the year. Its outstanding r206 was accepted on day 365; at the horizon Bram has three coins, two coins of missing-input cost, and advertised wheat available. This is a recent boundary obligation; fulfillment beyond the horizon was not claimed or tested.

NF accepts r3 on day 27, spends on food, and never fulfills it. At day 365 Bram holds two coins and can see that two wheat would cost two coins, but his food budget is three coins. The priority leaves zero input-spending capacity while the retained cash also cannot buy food. Cora has money but waits on her existing request, respecting the unchanged overlap limit. This is a new priority-induced deadlock, not insufficient total village money or an accounting loss. It was left unchanged after observation.

### Final resources, balances, and food distribution

| Priority / horizon | NPC | Coins | Wheat | Flour | Bread | Unmet meals |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| CF / 30 | Ada | 0 | 4 | 0 | 0 | 15 |
| CF / 30 | Bram | 3 | 0 | 0 | 0 | 2 |
| CF / 30 | Cora | 70 | 0 | 0 | 3 | 0 |
| CF / 30 | Dain | 2 | 0 | 0 | 0 | 12 |
| CF / 365 | Ada | 0 | 5 | 0 | 0 | 350 |
| CF / 365 | Bram | 3 | 0 | 0 | 0 | 203 |
| CF / 365 | Cora | 70 | 0 | 0 | 3 | 0 |
| CF / 365 | Dain | 2 | 0 | 0 | 0 | 213 |
| NF / 30 | Ada | 0 | 5 | 0 | 0 | 15 |
| NF / 30 | Bram | 2 | 0 | 0 | 0 | 3 |
| NF / 30 | Cora | 72 | 0 | 0 | 0 | 1 |
| NF / 30 | Dain | 1 | 0 | 0 | 0 | 13 |
| NF / 365 | Ada | 0 | 5 | 0 | 0 | 350 |
| NF / 365 | Bram | 2 | 0 | 0 | 0 | 338 |
| NF / 365 | Cora | 72 | 0 | 0 | 0 | 336 |
| NF / 365 | Dain | 1 | 0 | 0 | 0 | 348 |

CF increases production and consumption in this setup, but does not provide equitable food access: Ada still misses 350 of 365 meals, Bram 203, and Dain 213. Cora still holds 70 of 75 coins. Missing meals have the same existing absence of health/death effects. The experiment does not establish optimal priorities or a stable economy.

CF's 365-day trade comprises 456 spot wheat + six agreement wheat, 56 spot flour + 406 agreement flour, and 326 spot bread. It mills 462 wheat into 462 flour and bakes that flour into 693 bread. Final wheat = 467 − 462 = five; final bread = four initial + 693 − 694 eaten = three. NF retains 61 − 56 = five wheat and four + 84 − 88 = zero bread. CF's 694 eaten + 766 unmet and NF's 88 eaten + 1372 unmet both equal 1460 daily meal needs.

## Additional predefined seeds

No policies or parameters changed after any seed result. All comparisons used the same initial state, goals, prices, wages, actions, observations, and daily environmental opportunities within each pair.

| Seed | CF: 30 accepted / fulfilled / outstanding | NF: 30 accepted / fulfilled / outstanding | CF: 365 accepted / fulfilled / outstanding | NF: 365 accepted / fulfilled / outstanding |
| ---: | --- | --- | --- | --- |
| 7 | 3 / 2 / 1 | 1 / 0 / 1 | 204 / 203 / 1 | 1 / 0 / 1 |
| 42 | 5 / 4 / 1 | 3 / 2 / 1 | 206 / 205 / 1 | 3 / 2 / 1 |
| 99 | 4 / 3 / 1 | 2 / 1 / 1 | 205 / 204 / 1 | 2 / 1 / 1 |

In these three seeds, CF consumes 91 meals at day 30 and 694 at day 365; NF consumes 88 at both horizons. Final per-priority coin distributions, circulation totals, and latest activity days also coincide across these samples. Successful spot-purchase counts differ: at day 365 CF has 575/573/574 for seeds 7/42/99; NF has 102/100/101. These finite samples support a reproducible policy effect here, without implying broader robustness.

## Verification, failures, and reproducibility

Base commit: M4 `68a90a7`. Runtime: **Godot 4.6.3**. The baseline passed all **834 checks**. The complete updated suite passed **1024 checks, 0 failures**, retaining all prior coverage and adding 190 matched-fixture, budget, privacy, execution, report, ledger, and replay checks. No unexpected test or script failures occurred. Headless editor import, all four readable seed-42 planning commands, and `git diff --check` passed.

Tests audit both strategies' 30/365-day full ledgers and accounting, verify identical initial economics and RNG state, and pin both M4 historical hashes in addition to earlier hashes. Focused tests prove that the budget is pure/internal, that hidden financial changes cannot affect either policy, and that actual stock/funds remain authoritative after observations become stale. Policy metadata cannot invent money or bypass validation.

All seven legacy CLI captures were taken before editing and compared byte-for-byte after implementation. All 12 new planning captures (three seeds × two horizons × two priorities) were repeated in independent processes and were byte-identical. Six strategy pairs were checked for exact initial-state/price/goal/wage equality. Realized harvests were compared against the unchanged M2 daily opportunity sequence for each of the three seeds. No extra environmental knowledge was supplied to either policy.

Use the same writable XDG setup as prior milestones. Actual commands included:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority commitment-first 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority immediate-needs-first 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority commitment-first 365 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario planning --priority immediate-needs-first 365 42
git diff --check
```

Serial Python `subprocess.run(..., check=True, capture_output=True)` invocations used the same CLI arguments with `--headless --no-header` and appended `--json`, saved full captures under `/workspace/work/m5-planning-{priority}-{seed}-{days}-a.json`, repeated them as `-b.json`, asserted empty stderr, and compared bytes. Legacy captures used the unchanged scenario arguments and `m5-{scenario}-{days}-before.json` / `-verified.json` paths. CLI checks confirmed the default priority matches explicit commitment-first; invalid priorities and priorities on other scenarios return the expected exit 2.

| Historical scenario, seed 42 | Unchanged SHA-256 |
| --- | --- |
| M0, 30 days | `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9` |
| Trading, 30 days | `5d569a193111d3ad5ff90dc6317b567596c4b51b4fe54c11e676e3eda0bcd9aa` |
| Trading, 365 days | `e564ebe6f5638be17f8cfe2b78748bbaebb7907d818a9ade1247b7624ea12278` |
| Agents, 30 days | `53ca0029214319d352453c62e637340a7ae6b2e75bc42c29504885f5c0acef82` |
| Agents, 365 days | `d8f65499e0fe1d08cebc4485d18220a20f361fef42c9abdf92193e7b720ac2b2` |
| Coordination, 30 days | `f835a43f45c8867ee0e5a861923260aa9a00e04efd680d594726aa70eca23646` |
| Coordination, 365 days | `5dcdb3e42ca3cbd3d285ee0044b7f89915ab9450ececff0f7ee521d30c9139bf` |

| Planning priority, seed 42 | Days | SHA-256 |
| --- | ---: | --- |
| Commitment-first | 30 | `0f90a40f0e3f32e19bbbdbb44ba2f783dee42cdee2c989d1db0b6ddcecf1ad72` |
| Immediate-needs-first | 30 | `a085c5bc2f0cbf1ca5da044393f69c4f1bc232bb4a34c845b782bd70aacc3585` |
| Commitment-first | 365 | `61318efc50bea7b7fe0a75fa72ee414d209f981e90de9d58fda39774d3170469` |
| Immediate-needs-first | 365 | `3ca879b7e9f4294e8eef97e7419d4ded56447a05ccec4f9b295eb90415030ddb` |

## Limits and files changed

Budgeting covers accepted supplier obligations only. It uses current known input prices and owned resources, with no demand forecast, anticipated sales income, dynamic prices, or knowledge of private finances. It does not reserve physical goods, enforce future behavior, cancel requests, waive obligations, or create credits. Partial input purchases can strand capital. Conservative food reservation can deadlock immediate-needs-first, even when production is currently fundable. Commitment-first can delay meals and still leave severe hunger and wealth concentration. These outcomes were not corrected.

Only Godot 4.6.3, the specified sample seeds, and runs through 365 days were verified. Persistence and cross-version RNG replay remain unverified. Full generated logs remain reproducible workspace artifacts and are not committed.

- New `scripts/sim/planning_policy.gd` and UID: shared cost model, priority budgets, reasons, proposal annotations.
- New `scripts/sim/planning_runner.gd` and UID: configuration, policy selection, planning/activity report.
- `scripts/tools/run_simulation.gd`: separate planning scenario and validated priority option.
- New `tests/planning_tests.gd` and UID; `tests/run_tests.gd`: focused checks and reuse of existing accounting/lifecycle audits.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/M5_RESULTS.md`: contract, scope, actual comparisons, and limitations.

All existing world authority, agreement lifecycle, M3/M4 policies, and scenario runners are unchanged. Stop at M5 for review; M6 has not started.
