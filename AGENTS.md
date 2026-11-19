# Instructions for coding agents

This repository is a **simulation-first Godot 4 RPG prototype**, not a text-adventure engine. Read `README.md`, `docs/DESIGN.md`, `docs/ARCHITECTURE.md`, and `docs/ROADMAP.md` before significant changes. Keep this file brief; these documents contain the rationale.

- Work on the **currently requested milestone only**. Favor tiny, testable increments and minimal dependencies.
- The simulation is authoritative. All changes to items, money, needs, or other world facts must go through validated operations and structured events.
- NPCs/LLMs may propose actions but must not directly modify authoritative state. An AI Director is optional, never required for NPC-to-NPC coordination.
- Preserve deterministic seed-based replay, stable entity IDs, and explicit production/consumption sources and sinks.
- Do not allow an ordinary transfer to duplicate goods or money, or a failed transaction to partially mutate state.
- Add/adjust tests for each new mechanic. Run existing tests when possible. Report exactly what ran, what passed, what failed, and what could not be run.
- Keep the simulation runnable headlessly and independent of visuals. Prefer GDScript compatible with the Godot 4 version selected by the project.
- Never commit API keys, credentials, or secret configuration. Do not add paid network calls, external AI integration, asset downloads, or new services unless explicitly requested.
- Avoid unnecessary scaffolding, grand refactors, and speculative features. Ask for input only when a missing decision genuinely blocks progress; otherwise state a conservative assumption.
- For each change, summarize files touched, tested behavior, unresolved issues, and the next small increment.
- Follow the targeted → three-day checkpoint → once-per-milestone full acceptance cadence in `docs/PERFORMANCE.md`; the opt-in performance smoke emits advisory relative warnings, never substitutes for correctness or independent audits.

- Use `scripts/tools/verify_workflow.py` for explicit development/checkpoint/full levels; see `docs/PERFORMANCE.md`. Select the subsystem explicitly, retain full independent auditing on trace-cache hits, and never label a short or deliberately deferred run as full acceptance.
