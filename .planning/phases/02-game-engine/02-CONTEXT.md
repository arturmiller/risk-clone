# Phase 2: Game Engine - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete Risk game engine: turn FSM (reinforce → attack → fortify), combat resolution (dice + blitz), territory card system (earn/trade/escalate), fortification with path validation, player elimination with card transfer, and victory detection. Must run a full game programmatically without UI. Builds on Phase 1's MapGraph, GameState models, and setup logic.

</domain>

<decisions>
## Implementation Decisions

### Card Trading Rules
- Valid sets: 3 matching type (infantry/cavalry/artillery), OR one of each type, OR any 2 + wild card
- Wild cards substitute for any type
- Escalation sequence: 4, 6, 8, 10, 12, 15, then +5 each (20, 25, 30...) — official Hasbro sequence
- Global escalation counter (not per-player) — tracks across all trades in the game
- Territory bonus: if you trade a card showing a territory you own, place 2 extra armies on that territory
- Forced trade: must trade if holding 5+ cards at start of reinforcement phase
- Card earned: 1 card per turn if you conquered at least 1 territory that turn
- Elimination transfer: when eliminating a player, inherit all their cards; if now holding 5+, must trade immediately

### Combat Resolution
- Attacker: 1-3 dice (must have at least N+1 armies to roll N dice)
- Defender: 1-2 dice (must have at least N armies to roll N dice)
- Highest dice paired, ties go to defender
- Blitz mode: auto-resolve by rolling repeatedly until attacker wins or has only 1 army left
- Minimum 1 army must always remain on attacking territory
- After conquest: attacker must move at least as many armies as dice rolled into conquered territory

### Turn Phase Flow
- FSM: Reinforce → Attack → Fortify → End Turn
- Reinforce is mandatory (must place all armies)
- Attack is optional (player can skip entire attack phase)
- Fortify is optional (player can skip or move armies once along connected friendly path)
- One fortify move per turn (from one territory to one adjacent-connected territory)

### Claude's Discretion
- Turn engine architecture (class-based FSM, function-based, etc.)
- How to represent the card deck and card types
- Player interface abstraction (for human vs bot compatibility)
- Test strategy for full-game simulation
- Error handling for invalid moves

</decisions>

<specifics>
## Specific Ideas

- Research flagged: card escalation must be global (not per-player) — this is Risk's built-in anti-stalemate mechanism
- The engine must be runnable without UI — programmatic move inputs for testing and AI-vs-AI simulation (Phase 5)
- Player interface should be abstract enough that Phase 4-5 bots plug in without engine changes

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `risk/engine/map_graph.py`: MapGraph with `connected_territories()` — use for fortification path validation
- `risk/models/game_state.py`: TerritoryState (owner, armies), PlayerState (index, name, is_alive), GameState
- `risk/engine/setup.py`: `setup_game()` returns initialized GameState

### Established Patterns
- Pydantic v2 models for game state (immutable snapshots)
- NetworkX subgraph queries for reachability
- JSON data files for configuration

### Integration Points
- Phase 3 (Web UI) will call engine methods to process player actions
- Phase 4-5 (Bots) will use the player interface to make decisions
- Phase 5 (AI-vs-AI) needs the engine to run full games without UI

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-game-engine*
*Context gathered: 2026-03-08*
