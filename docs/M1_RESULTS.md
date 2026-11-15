# M1 atomic purchases — verification results

M1 introduces a callable transaction mechanism. The existing M0 economic routine and simulation CLI are unchanged. No purchasing decisions, negotiation, dynamic prices, wages, debt, AI, or graphics were added. Subsequent milestones have not started.

## Implementation and assumptions

`world.purchase(buyer, seller, item, quantity, unit_price)` returns a boolean and appends one purchase event. Every validation precedes every state mutation. Successful purchases move goods and money in opposite directions together; rejected attempts leave all authoritative state unchanged and append a reasoned rejection event.

- Identifiers/commodity names follow the existing String command API. Unknown participants/items and self-purchases are rejected.
- Quantity must be an integer in 1..1,000,000,000.
- Unit price must be an integer in 0..1,000,000,000. Zero means goods move without payment, even when buyer money is zero.
- Total price and resulting holdings must fit the existing one-billion-unit cap. Integer division checks the total before multiplication. No floating-point money calculations or integer wraparound are permitted.
- The existing cap applies separately to each commodity stack and each NPC balance; there is no new aggregate inventory capacity.
- Events use buyer as `actor`, seller as `target`, and include both participants, item, quantity, unit price, total price, success, and any rejection reason. A total that cannot be safely accepted is recorded as null alongside the original operands.
- Atomicity follows the existing synchronous kernel: all checks, four writes, and one event execute without awaits, nested transfer commands, or callbacks.

## Verification

Runtime: **Godot 4.6.3**. This change is based on M0 commit `1711af9`. Before changes, all **147 checks passed**, and a fresh 30-day JSON capture matched the historical M0 hash.

The complete updated suite passed with **436 checks, 0 failures**, including all **147 original M0 checks** and **289 additional purchase/audit checks**. Purchase tests cover:

- Exact transfers, entire-balance spending, entire-stock sales, zero-price exchanges, commodity and money conservation.
- Insufficient money/stock, unknown or identical participants, unknown commodities, and exact rejection event fields/reasons.
- Zero/negative/fractional/string/null/boolean quantities, invalid prices, NaN/infinities, and signed 64-bit extremes.
- Buyer inventory and seller money capacity rejections, with unchanged inventories/balances; accepted exact boundaries.
- Excessive total prices rejected before multiplication, including products that could wrap if checked too late; near-boundary integer totals without rounding.
- Mixed successful/rejected purchases interleaved with seeded ticks: identical state, event logs, and reports across replay.
- Independent event-ledger reconstruction including purchases, with nonnegative holdings and conserved money.

Actual commands ran from the project root with the same writable XDG locations as M0:

```sh
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://scripts/tools/run_simulation.gd
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/m1-before.json # captured before edits
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/m1-after-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/m1-after-b.json
cmp /workspace/work/m1-before.json /workspace/work/m1-after-a.json
cmp /workspace/work/m1-after-a.json /workspace/work/m1-after-b.json
sha256sum /workspace/work/m1-before.json /workspace/work/m1-after-a.json /workspace/work/m1-after-b.json
git diff --check
```

Both comparisons passed (exit 0). Before and both after captures share SHA-256:

`6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`

This is the same hash recorded for M0, covering the complete report and all 421 events. Accounting remains: 75 coins; 122 wheat harvested; 116 wheat milled into 116 flour; 116 flour baked into 174 bread; 120 bread consumed; zero unmet meals; final inventories total six wheat, zero flour, and 58 bread. The four expected day-3 stock-shortage rejections are unchanged.

Headless editor import and the whitespace check passed. No test failures or outstanding verification blockers were observed. Only Godot 4.6.3 was verified; cross-version replay was not tested.

## Files changed

- `scripts/sim/world_state.gd`: purchase command and complete prevalidation.
- `tests/run_tests.gd`: runs the new tests after the original 147 checks; extends the event auditor for purchases and arbitrary fixture endowments.
- `tests/purchase_tests.gd` (and Godot UID metadata): focused purchase scenarios and replay/conservation checks.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`: command contract, event schema, run instructions, and current milestone scope.
- `docs/M1_RESULTS.md`: this actual-results report.

M1 ends at this mechanism. Further economic behavior requires a subsequent reviewed task.
