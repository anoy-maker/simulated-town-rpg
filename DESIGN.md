# Design notes — what the game is trying to be

*Working document. Proposed choices are not locked in.*

## Player fantasy

You enter a living fantasy society as one person, not its designated hero or manager. You can work, trade, explore, make friends, make enemies, protect people you care about, build coalitions, start disputes, or ignore local affairs. Other inhabitants continue pursuing goals and reacting to circumstances without waiting for you.

The goal is not merely an LLM that chats convincingly. The goal is **a simulation in which people can meaningfully affect one another and the world**.

## The world is the authority

World facts (inventories, homes, employment, ownership, physical location, health, relationships, transactions, scheduled commitments, events) must come from the simulation. A model can choose an intention or request an action but cannot silently alter these facts.

World truth, character beliefs, and information sent to an LLM are three different things:

- **World truth:** what actually exists and happened.
- **Character knowledge and belief:** observations, memories, rumors, mistaken assumptions, and confidence.
- **Model context:** relevant subset of what that character can reasonably access for this decision.

No NPC should know a secret just because it exists in the database.

## Persistent economy

Characters and institutions should have real inventories, ownership, payments, income, expenses, needs, and obligations. Items can be produced, moved, transformed, consumed, spoiled, lost, and traded. Money transfers between accounts; any creation or destruction of currency must be an explicit event.

Start with **stackable commodities** rather than unique instances for every loaf or grain. Unique objects can be represented separately when their identity matters.

Economic instability is allowed. It must be possible to diagnose whether a collapse came from rules and decisions or a faulty implementation.

## Autonomous characters

NPCs should have:

- Personal needs, interests, temperament, commitments, and goals.
- Routines and ordinary non-LLM behaviors.
- Limited beliefs and memories derived from events they perceived or learned about.
- Available actions that can affect real state through validated commands.
- The ability to communicate, bargain, delegate, recruit others, and form shared undertakings (later milestone).

Independent NPC-to-NPC activity should **not** require player involvement or a central Director's permission.

## Emergent quests

Quests are **player-facing interpretations of ongoing situations**, not invisible scripts that force the world to reach an ending. Several participants in one crisis can offer competing opportunities. Player-generated undertakings can become trackable too.

A quest or commitment may be resolved by checking a state predicate (e.g. household has five days of accessible food), not by an LLM merely declaring victory. Multiple solutions and partial outcomes should be possible.

Discovery tools—rumors, dialogue, noticeboards, journals, optional markers, and last-known locations—should help players find relevant opportunities while preserving knowledge limitations.

NPCs can accommodate a player commitment without freezing the wider world. Deadlines, notifications, and player advantages may eventually be configurable based on playtesting.

## Optional Director

The Director is a **separate, optional** system that may introduce or highlight plausible pressures (bad harvests, visitors, rumors, opportunities) in order to create interesting conditions. It should not dictate NPC decisions or outcomes. Eventually test settings such as Off, Light, and Active; do not build or require it in the first prototype.

## Priorities and deliberate non-goals

### Priorities now

- Reliable world-state transitions.
- A minimal working economy with observable transactions.
- Deterministic replay, test coverage, and understandable logs.
- A low-friction phone-to-Codex workflow.

### Not yet

- Thousands of NPCs; city-scale simulation; generational history.
- Complex physical pathfinding or a finished tile-map UI.
- Combat, deep politics, or a comprehensive crafting tree.
- Unlimited NPC conversations or continuous LLM calls.
- Fully authored quest lines, advanced graphics, or a commercial launch.

## Open design questions

- How granular should time, individual belongings, and land ownership become?
- When should a routine decision escalate to paid LLM reasoning?
- How should NPCs learn, forget, lie, and evaluate rumors?
- Which events warrant journal tracking, and who gets notified?
- How much player accommodation is enjoyable without breaking autonomy?
- How will the simulation handle absent/unloaded maps and travel?
- Should wealth be held in wallets, accounts, physical currency, or a combination?

These are intentionally deferred until a simpler system teaches us something.
