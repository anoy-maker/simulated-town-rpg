# Simulated Town RPG

**Status:** Pre-production / simulation-first prototype  
**Working title:** Simulated Town RPG (subject to change)

## The idea

A tile-based fantasy RPG set in a persistent society whose inhabitants have their own needs, work, possessions, relationships, beliefs, plans, and conflicts. The world continues to develop whether or not the player intervenes. Events, quests, and political movements emerge from the simulated world rather than depending on a fixed sequence of authored stories.

Think **Dwarf Fortress-like systemic depth**, **Kingdom Come-like plausibility**, and **Skyrim-like freedom to explore and intervene**—starting at the scale of one small village rather than trying to reproduce any of those games.

Language models may help characters reason through unusual situations, negotiate, communicate, and devise plans. **They are not the source of truth.** A deterministic game simulation owns the facts and decides whether attempted actions succeed.

## Design pillars

1. **A world that exists without the player.** Villagers live, trade, cooperate, quarrel, change careers, and make plans when the player is absent.
2. **Consequences, not performances.** Goods must be transferred, consumed, produced, owned, or lost in the game state. NPCs cannot merely narrate that something occurred.
3. **Autonomy with imperfect knowledge.** A character acts on what they know or believe, not omniscient access to all world data.
4. **Emergent situations over prescribed quests.** Multiple people may have competing goals within one crisis. Player commitments are trackable, but the crisis continues independently.
5. **Player-initiated change.** The player can propose and organize plans, and NPCs can then recruit, negotiate, defect, or act without the player.
6. **Interesting failure is allowed.** Economic collapse and social disorder can be valid outcomes. Arithmetic bugs, duplicated items, and broken invariants are not.
7. **AI is optional, bounded, and replaceable.** Routine behavior can be rule-based. LLM-assisted decisions are added selectively, with configurable cost limits. An AI Director is optional and adjustable, not the controlling consciousness of every NPC.

## What we're building first

The first milestone is deliberately *not* a complete RPG. It is a **headless simulation kernel** in a minimal Godot 4 project:

- Four named NPCs with stable IDs, occupations, money, and inventories.
- Stackable commodities and atomic item/currency transfers.
- A small production chain (for example, wheat → flour → bread).
- Food consumption and explicit resource creation/consumption events.
- A time-step loop, seeded randomness, and a structured event history.
- Automated tests for conservation rules and invalid transactions.
- A report after a short run that can be inspected from Codex on a phone.

We will *not* attempt complex pathfinding, elaborate maps, natural-language dialogue, full NPC social politics, or paid LLM calls in this milestone. A tile-map visualization can follow as soon as the simulation kernel is trustworthy.

## Technology direction

- **Engine:** Godot 4.x, using GDScript for the simulation and eventual game UI.
- **Execution:** Headless runs and tests in a cloud development environment; playable Godot scene later.
- **Source control:** GitHub repository, with small changes and clear checkpoints.
- **LLMs:** Not required for the initial prototype. Future integration via a provider-independent adapter.
- **Data:** Begin with simple serializable structures; decide on long-term persistence once the core data model stabilizes.

This is a working direction, not a commitment to a particular Godot minor release, commercial model, AI provider, or final art style.

## Documents

- [Design principles and feature boundaries](docs/DESIGN.md)
- [Technical architecture and simulation invariants](docs/ARCHITECTURE.md)
- [Incremental roadmap](docs/ROADMAP.md)
- [Codex development instructions](AGENTS.md)
- [First Codex implementation task](prompts/FIRST_CODEX_TASK.md)

## Definition of an honest prototype

A credible early demonstration is **four people who can complete—or fail to complete—a basic economic cycle, where every inventory change and money transfer is accounted for, and the same seed reproduces the same outcome**. A failed economy is acceptable; an unexplainable economy is not.

## Project status

Design documents only. No running simulation is claimed yet. Licensing, public release plans, and the final title remain undecided.
