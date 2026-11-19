# First Codex task — build the smallest trustworthy village simulation

Read `README.md`, `AGENTS.md`, and the files in `docs/` before you implement anything. This repository is a Godot 4 / GDScript simulation-first RPG prototype. Work only on **Milestone M0**.

Create a minimal Godot 4 project plus a **headless, deterministic simulation kernel**. Do not build UI, a tile map, dialogue, LLM integrations, or an AI Director yet.

## Requirements

1. Implement four named NPCs with stable IDs, roles (farmer, miller, baker, laborer), individual money balances, and stackable inventories.
2. Define a small commodity chain (wheat → flour → bread). Implement validated operations for item transfer, currency transfer, production from recipes, and consumption. Treat harvest as an explicit source and eating as an explicit sink; log both.
3. Advance one simulated day per tick for a configurable number of days. Rule-based routines can be intentionally simple and need not be a stable economy. Use a specified random seed for any randomness.
4. Record each meaningful world-state change as a structured event containing tick/day, action type, actors/targets, item or money amounts, and success/failure where relevant.
5. Produce a readable summary of initial and final inventories/money, basic production/consumption totals, unmet needs, and notable events after 30 days.
6. Provide a headless way to run this from the project root and explain the exact commands in the README. Aim for a command like `godot --headless --path . --script res://scripts/tools/run_simulation.gd` if appropriate for your implementation.
7. Include a small automated test runner verifying:
   - transferring an item conserves quantity;
   - transferring money conserves total money;
   - invalid or unaffordable transactions do not partly modify state;
   - crafting consumes the correct inputs and creates the correct outputs;
   - eating consumes actual stock;
   - same starting state and seed produce identical event logs and final state.

## Working constraints

- Keep code small and understandable; no large framework, third-party test dependency, or mock game engine.
- Never invent success from an LLM response; the kernel updates world truth.
- No API calls, no API keys, no paid services, and no assets to download.
- If a Godot binary is not available, first check whether you can use an available approved installation path. Do not claim tests ran unless they really did. If unavailable, provide code and precise instructions for later testing and list the limitation.
- Do not spend effort tuning the simulation to ensure everyone survives. Economic failure can be a valid outcome; accounting errors cannot.
- Keep the work on one small branch/change set; do not add later roadmap features.

## Report back

Summarize the structure created, actual commands executed, test results, one example 30-day simulation summary, design assumptions, and any issues. If M0 is complete, propose **one** next tiny testable improvement, not an entire feature backlog.
