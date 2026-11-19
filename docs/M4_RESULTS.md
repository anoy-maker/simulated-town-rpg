# M4 — Commercial Requests and Commitments: actual results

M4 adds `--scenario coordination`: autonomous commercial choices can post requests, voluntarily accept prepaid supply agreements, and deliver actual goods. M0/M2/M3 remain unchanged regression baselines. The new scenario formed valid agreements and briefly continued production beyond M3's historical day-26 stall, then stalled again with an unfulfilled obligation. Recovery was not an acceptance criterion. No M5 work was begun.

## Fixed assumptions and scope

Initial resources remain Ada/Bram/Cora/Dain's 30/20/20/5 coins and one bread each, with zero wheat/flour. Prices remain wheat 1, flour 2, bread 3. Ada attempts the same two-coin daily payment before sales. Recipes, M3 goals (food 1; output 4 wheat / 4 flour / 6 bread; max two batches), and the seeded daily harvest opportunities are unchanged. Prices, goals, resources, and policies were not adjusted after observing outcomes.

The new commercial policy can give accepted supply obligations priority during a producer's input/work turn. It may raise the effective output target to cover the obligation and spend input funds before applying the usual food-money reserve. Money and goods are not escrowed or reserved between turns; ordinary later purchases can still consume working capital. This new obligation priority is explicit and specific to M4.

Policies receive copied self state, public seller/price/stock offers, eligible public open requests, and their own active requests/agreements. They cannot inspect other balances, unadvertised stock, unrelated accepted agreements, or global history. Producers are the existing advertised sellers: Ada for wheat, Bram for flour, Cora for bread. There is no generalized contracting, loan, employment, or negotiation framework.

## Request and agreement rules

- Posting specifies buyer, commodity, quantity, and the existing fixed-price payment. It validates identity, positive bounded integer quantity, safe payment arithmetic, current affordability, capacity, and duplicate limits. Posting transfers no money and reserves no funds.
- At most one open/accepted request exists per buyer/commodity. A supplier may have only one accepted agreement per commodity. Quantity/price variations do not bypass these limits.
- A supplier independently accepts an eligible request. Acceptance revalidates funds/capacity and transfers the entire payment with `transfer_money` before recording accepted status. Failure leaves the request open and holdings unchanged. The payment is immediately spendable.
- Delivery validates supplier and accepted status, then transfers the full quantity using `transfer_item`. Only actual owned goods can move. Success marks fulfilled; repeated delivery is rejected before another transfer. Failure preserves the paid obligation without refund or fabricated goods.
- Only the buyer can explicitly close an open/accepted record with a reason. Closing a paid agreement waives the claim without refund. Default policies never automatically close, forgive, or refund obligations.
- Stable request IDs and complete terms/status/timestamps/payment and delivery receipt IDs remain in authoritative snapshots. Accepted obligations emit daily `agreement_outstanding` records until fulfilled or explicitly closed.

Commercial actions remain proposals. The world binds the actual actor, validates allowed phases and methods, derives the fixed payment, and executes accounting. A proposed buyer override or free payment cannot alter the agreement terms.

## Decisions and daily order

The unchanged wage payment and daily RNG draw occur first. Ada takes work/delivery turns; Bram takes inputs/work/delivery turns; Cora takes inputs/work/delivery turns. All four NPCs then take request-posting turns, acceptance turns, food turns, and meal turns. Outstanding obligations are logged at day end. There are 24 decision opportunities per day. The runner provides these turns; it never instructs Cora to fund Bram or triggers action on a historical stall date.

Buyers consider missing production inputs first, then needed food. They request only unavailable spot supplies they can afford, and avoid another order while an active request for that commodity exists. Suppliers consider owned stock, potential production within one work turn, public input prices, whether payment covers missing-input costs, and existing commitments. They can decline. Buyers awaiting supply avoid duplicate spot purchases. Suppliers deliver available goods immediately after work, letting downstream NPCs use them in the same day's work turn. Acceptance follows work, so an advance can fund the next day's input turn, but can also be spent in today's food turn.

## Agreements actually formed, seed 42

The same four records exist at day 30 and day 365:

| ID | Buyer | Supplier | Goods | Payment | Posted / accepted | Delivered | Final status |
| --- | --- | --- | --- | ---: | ---: | ---: | --- |
| r1 | Bram | Ada | 4 wheat | 4 | Day 1 | Day 2 | Fulfilled |
| r2 | Bram | Ada | 2 wheat | 2 | Day 7 | Day 8 | Fulfilled |
| r3 | Cora | Bram | 2 flour | 4 | Day 27 | Day 28 | Fulfilled |
| r4 | Cora | Bram | 2 flour | 4 | Day 28 | — | Accepted, outstanding |

There were **4 requests, 4 accepted agreements, 3 fulfillments, 1 outstanding agreement, 0 closures, and 0 lifecycle rejections** in both default runs. Unit tests separately exercised lifecycle rejection and explicit closure. Prepayments total **14 coins**: six from Bram to Ada and eight from Cora to Bram. Fulfilled deliveries total six wheat and two flour, representing ten coins of prepaid orders. The remaining four-coin claim is outstanding; its payment is not held in escrow and is not additional circulating money.

r1/r2 arise from public wheat stock being unavailable after same-day sales, with Bram planning to replenish output. r3/r4 arise from Cora's missing flour and production target. The new scenario therefore diverges from M3 before day 26; the comparison is a separate trajectory, not a forced restart from identical day-26 state. A focused test also starts from M3-like holdings (Cora 73 coins, Bram 1, Ada 0 with five wheat, Dain 1) and demonstrates independent request → prepayment → wheat purchase → milling → flour delivery.

## Activity after M3's historical day-26 stall

M4 records **two successful production commands, five successful spot purchases, two acceptances, and one fulfillment after day 26**. The last production and delivery are on day 28; the last ordinary purchases are on day 29.

On day 27, Cora prepays four coins for two flour (r3). On day 28 Bram buys two real wheat for two coins, mills them into two flour, and delivers the flour. Cora then bakes it into three bread. This is actual multi-step activity supported by an agreement.

Cora also posts r4 on day 28, paying another four coins. Bram buys a three-coin bread in that day's later food turn and spends his remaining coin on one wheat on day 29. He cannot mill with only one wheat and has no money for another. The accepted two-flour obligation remains outstanding through day 365. Ada holds five wheat but only one coin; Cora holds 74 coins but waits for her existing claim instead of creating overlapping flour advances. No refund, additional loan, or rescue is invented.

This exposes a policy limitation: input priority applies at the work turn, while prepayments are accepted afterward and remain spendable before the next work turn. Acceptance estimates production cost but does not reserve the required capital against subsequent consumption. That behavior was retained after observation.

## Comparison with M3

| Measure | M3: 30 days | M4: 30 days | M3: 365 days | M4: 365 days |
| --- | ---: | ---: | ---: | ---: |
| Spot purchases, successful / rejected | 101 / 0 | 104 / 0 | 101 / 0 | 104 / 0 |
| Agreements accepted / fulfilled / outstanding | 0 / 0 / 0 | 4 / 3 / 1 | 0 / 0 / 0 | 4 / 3 / 1 |
| Prepayment circulation | 0 | 14 | 0 | 14 |
| Wheat harvested | 61 | 64 | 61 | 64 |
| Flour produced | 56 | 58 | 56 | 58 |
| Bread produced | 84 | 87 | 84 | 87 |
| Meals consumed | 88 | 91 | 88 | 91 |
| Unmet meals | 32 | 29 | 1372 | 1369 |
| Employer payments, successful / rejected | 22 / 8 | 23 / 7 | 22 / 343 | 23 / 342 |
| Total coins | 75 | 75 | 75 | 75 |

M4's final holdings and cash flows are identical at the two horizons; missed meals, failed payments, waits, and outstanding notifications continue accumulating:

| NPC | Final coins | Earned | Spent | Wheat | Flour | Bread | Unmet: 30 days | Unmet: 365 days |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ada | 1 | 59 | 88 | 5 | 0 | 0 | 15 | 350 |
| Bram | 0 | 120 | 140 | 1 | 0 | 0 | 2 | 337 |
| Cora | 74 | 174 | 120 | 0 | 0 | 0 | 0 | 335 |
| Dain | 0 | 46 | 51 | 0 | 0 | 0 | 12 | 347 |

Ada earns 53 from spot wheat sales and six in prepayments; she spends 46 on employer payments and 42 on bread. Bram earns 112 from spot flour sales and eight in prepayments; he spends 134 in ordinary purchases and six in wheat prepayments. Cora earns 174 from bread, spends 112 on spot flour and eight in prepayments. Dain receives 46 in employer payments and spends 51 on bread.

Gross cash circulation is **399 coins transferred**, comprising 339 in spot purchases, 14 in prepayments, and 46 in employer payments; M3 transferred 377. These are cumulative transfers of the same 75 coins. Each final balance equals initial + earned − spent, with prepayments counted once. Fulfillment moves goods without another payment. Outstanding claims are not added to anyone's money balance.

## Resource and decision accounting

Spot quantities are 53 wheat, 56 flour, and 58 bread. Agreement deliveries add six wheat and two flour, giving total traded quantities of **59 wheat, 58 flour, 58 bread**. Production consumes 58 wheat → 58 flour → 87 bread. Reconciliation: 64 harvested − 58 milled = six final wheat; 58 flour produced − 58 baked = zero; four initial bread + 87 produced − 91 eaten = zero. At 365 days, 91 eaten + 1369 unmet = 1460 meal needs.

| Decision/event measure | 30 days | 365 days |
| --- | ---: | ---: |
| Decision opportunities | 720 | 8760 |
| Executed / rejected / wait | 269 / 29 / 422 | 269 / 1369 / 7122 |
| Request / acceptance / fulfillment decisions | 4 / 4 / 3 | 4 / 4 / 3 |
| Selected production commands | 47 | 47 |
| Selected ordinary purchases | 104 | 104 |
| Raw event records | 1092 | 11477 |

Rejected decisions are failed meals in these runs. Economic failures are 29/1369 failed meals and 7/342 failed employer payments. No goods or money are lost by failed operations. Raw lifecycle and decision events annotate their accounting receipts; reports do not count those annotations as extra payments, transfers, or economic failures. r4 receives an outstanding event on every day from acceptance through the reporting horizon, with no automatic expiry.

## Verification and actual failures

Base commit: M3 `d1ea959`. Runtime: **Godot 4.6.3**. Before changes all **633 checks passed**. The final suite passed **834 checks, 0 failures**, preserving all prior coverage and adding **201 commercial/coordination checks**. Headless editor import and `git diff --check` passed.

One initial new test failed because it expected Cora to decline a bread request while she already owned the requested bread. The fixture was corrected to remove that bread and test the intended missing-input-cost refusal. No economic policy or parameter changed in response. There are no outstanding test failures.

Coverage includes exact payment and stock transfers, spendable working capital, multi-step production, refusal, affordability/capacity changes, integer/type/overflow boundaries, duplicate requests and acceptance/fulfillment, immutable history, supplier/buyer authorization, explicit closure without refund, public/private observations, proposal identity/payment binding, persistent daily obligation records, exact receipt auditing, per-NPC cash/meal accounting, trade volume reporting, 30/365-day split-run replay, and historical M3 hashes. All prior M0/M2/M3 checks remain active.

The auditor reconstructs request state, validates lifecycle transitions and immutable terms, matches each successful acceptance/delivery to one unique real transfer receipt, and reconstructs all inventories/balances. Replay comparisons used complete reports and event histories, not only final balances.

Commands ran from the repository root with writable workspace paths:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --editor --path . --import
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 365 42
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 30 42 --json > /workspace/work/m4-coordination-30-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario coordination 365 42 --json > /workspace/work/m4-coordination-365-a.json
git diff --check
```

Before implementation, five independent CLI captures were saved for M0 30 days, M2 trading 30/365 days, and M3 agents 30/365 days. After implementation, a Python `subprocess.run(..., check=True, capture_output=True)` verification repeated all five and both coordination runs using the same arguments. It asserted empty stderr and byte-for-byte equality with each reference, saved `*-verified.json` captures, and printed SHA-256 hashes. All seven comparisons passed:

| Scenario, seed 42 | SHA-256 |
| --- | --- |
| M0, 30 days | `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9` |
| Trading, 30 days | `5d569a193111d3ad5ff90dc6317b567596c4b51b4fe54c11e676e3eda0bcd9aa` |
| Trading, 365 days | `e564ebe6f5638be17f8cfe2b78748bbaebb7907d818a9ade1247b7624ea12278` |
| Agents, 30 days | `53ca0029214319d352453c62e637340a7ae6b2e75bc42c29504885f5c0acef82` |
| Agents, 365 days | `d8f65499e0fe1d08cebc4485d18220a20f361fef42c9abdf92193e7b720ac2b2` |
| Coordination, 30 days | `f835a43f45c8867ee0e5a861923260aa9a00e04efd680d594726aa70eca23646` |
| Coordination, 365 days | `5dcdb3e42ca3cbd3d285ee0044b7f89915ab9450ececff0f7ee521d30c9139bf` |

## Limits and files changed

Acceptance uses a conservative missing-input-cost estimate and potential one-turn production, not demand forecasts or knowledge of other cash balances. It may decline a small bread order whose payment cannot cover an entire recipe batch, even when surplus output could later be sold. Unaccepted requests can remain open indefinitely. There are no deadlines, automatic cancellation, refunds, top-ups, escrow, penalties, resale promises, or general-purpose loans. The one-active-commitment limits deliberately prevent repeated advances against the same unfulfilled supply. The final unfulfilled agreement is retained as a real limitation, without economic correction.

Only Godot 4.6.3 and runs through 365 days were verified; cross-version RNG replay and persistence remain unverified. Full generated logs remain reproducible workspace artifacts and are not committed.

- New `scripts/sim/coordination_world.gd`, `coordination_policy.gd`, `coordination_runner.gd` and UID metadata: lifecycle authority, permitted commercial decisions, scenario/report.
- `scripts/tools/run_simulation.gd`: explicit `coordination` selection and readable agreement report.
- New `tests/coordination_tests.gd` and UID, plus `tests/run_tests.gd`: focused tests and lifecycle-aware ledger reconstruction.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/M4_RESULTS.md`: contract, scope, rules, comparisons, and verification.

The original world, M0/M2/M3 runners, and M3 policy/observation implementations are unchanged. Stop at M4 for review; M5 has not started.
