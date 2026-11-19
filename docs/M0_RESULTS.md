# M0 verification results

M0 is implemented and ready for review. M1 has not started. The original design files were moved from the repository root into `docs/`, and the unchanged task prompt into `prompts/FIRST_CODEX_TASK.md`.

## What was verified

Runtime: `4.6.3.stable.official.7d41c59c4`, Linux. No dependencies or assets were installed. Tests exercised the real GDScript kernel in Godot.

The cloud workspace restricts writes to the normal home directory. Successful runs used this setup (the exact paths used during verification):

```sh
mkdir -p /workspace/work/godot-data /workspace/work/godot-config /workspace/work/cache
export XDG_DATA_HOME=/workspace/work/godot-data
export XDG_CONFIG_HOME=/workspace/work/godot-config
export XDG_CACHE_HOME=/workspace/work/cache
```

Commands executed from the repository root:

```sh
godot --version
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://scripts/tools/run_simulation.gd
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/run-a.json
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- 30 42 --json > /workspace/work/run-b.json
cmp /workspace/work/run-a.json /workspace/work/run-b.json
sha256sum /workspace/work/run-a.json /workspace/work/run-b.json
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- -1 42
git diff --check
```

- Headless editor import: exit 0, no script/import errors.
- Final test suite: **147 checks, 0 failures**, exit 0. Covers transfer conservation, all-balance/stock transfers, invalid participants/items/amounts/recipes, unaffordable payments, role checks, capacity rejection before mutation, exact recipe quantities, real-stock consumption, failure reasons, snapshot isolation, unmet-meal reporting, seeded replay, split-run equivalence, and a 30-day ledger audit.
- Default 30-day run: exit 0; results below.
- Separate-process JSON replay: `cmp` exit 0; complete reports and event histories are byte-identical. Both SHA-256 hashes: `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`.
- Negative-day CLI check: expected exit 2 with `Days must be between 0 and 10000.`
- Whitespace check: passed.

The test ledger independently reconstructs final inventories, money, and day from structured events. It checks nonnegative holdings and conserved money after each event, and verifies aggregate commodity sources/sinks against the report.

## Example: 30 days, seed 42

Every NPC starts with one bread and no wheat/flour. Money and inventory quantities are integers.

| NPC / stable ID | Money, initial → final | Final wheat | Final flour | Final bread | Unmet meals |
| --- | ---: | ---: | ---: | ---: | ---: |
| Ada / farmer | 30 → 0 | 6 | 0 | 1 | 0 |
| Bram / miller | 20 → 20 | 0 | 0 | 1 | 0 |
| Cora / baker | 20 → 20 | 0 | 0 | 55 | 0 |
| Dain / laborer | 5 → 35 | 0 | 0 | 1 | 0 |

- Total money: **75 → 75**; 30 one-coin gifts moved from farmer to laborer.
- Harvest: **122 wheat** created explicitly.
- Milling: **116 wheat → 116 flour**.
- Baking: **116 flour → 174 bread**.
- Eating: **120 bread** consumed; all 120 meal needs met.
- Final bread: **58 = 4 initial + 174 produced − 120 eaten**.
- Event records: **421**, including initialization, daily transitions, successful operations, and four rejected operations.

On day 3, the farmer could not supply the full four-wheat transfer. That transfer, milling, flour transfer, and baking each failed with `insufficient_stock` (event IDs 32–35). Failed commands preserved state. Existing bread stocks covered meals. A separate controlled no-food test verifies that failed meals are recorded without fictitious consumption.

## Assumptions and limitations

The README documents the complete tick order, recipes, and initial endowments. Goods are gifted along the chain; the farmer's one-coin gift to the laborer is independent of goods. There are no prices, atomic purchases, wages, death, debt, or planning yet. The laborer receives goods and money and consumes food. Baker stock accumulation and eventual farmer insolvency are accepted consequences of these deliberately simple rules.

The first test launch, before redirecting Godot's data directory, failed during engine startup: Godot could not create `/home/agent/.local/share/godot` and crashed with signal 11 (process exit 134). No tests ran in that attempt. Redirecting data/cache/config paths into the workspace resolved it. All reported successful tests and simulations used writable workspace paths.

No outstanding simulation/test failures remain. Verification covers Godot 4.6.3 only; cross-version RNG equivalence, graphical editor interaction, exports, persistence, and long-running performance were not verified. There is no graphical main scene. Complete generated logs are reproducible with the README commands and are not committed.

After M0 review, one next tiny testable improvement would be an atomic purchase command, with a test proving insufficient funds leave both goods and money unchanged. That M1 work is not implemented here.
