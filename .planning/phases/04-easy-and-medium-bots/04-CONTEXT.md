# Phase 4: Easy and Medium Bots - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Two AI difficulty levels (Easy and Medium) selectable from the browser setup screen. A human player can choose a global difficulty and play a full game against 1-5 bots of that difficulty. Bot AI strategy is implemented in Python; the setup screen gets a difficulty selector. Hard bot and AI-vs-AI simulation are Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Difficulty Selection UI
- One global difficulty dropdown on the setup screen: Easy / Medium
- All bot slots use the same difficulty
- Setup screen layout: Player count selector + Difficulty selector + Start button
- No per-bot difficulty in Phase 4 (v2 concern per REQUIREMENTS SETUP-04)

### Easy Bot Behavior
- `RandomAgent` (already implemented in `risk/game.py`) IS the Easy bot
- BOTS-01 is already satisfied — just expose it via the UI and rename/alias as needed
- Easy bot: advantage-based attack selection, random reinforcement, 50% fortify chance
- No changes needed to RandomAgent behavior

### Medium Bot — Reinforcement
- Reinforce territories on the borders of continents you're close to completing
- Border territory = adjacent to at least one enemy-owned territory
- Prioritize continents where the bot owns the most territories (closest to completion)
- Fall back to random owned territory if no suitable border territory found

### Medium Bot — Attack
- Attack when both conditions hold: favorable odds (more armies than defender) AND strategic value
- Strategic value: target territory is in a continent where bot owns the most territories, OR blocking opponent from completing a continent
- Skip unfavorable attacks (bot armies ≤ defender armies) unless target would complete a continent bonus

### Medium Bot — Fortification
- Move armies toward continent borders after attacking
- Border = owned territory adjacent to at least one enemy territory
- Pick the interior territory with the most surplus armies, move toward the most exposed border territory
- If no interior surplus, skip fortify

### Medium Bot — Card Trading
- Same as Easy (RandomAgent): always trade when a valid set exists, never skip if forced
- Card trading strategy differences are Hard bot territory (Phase 5)

### Bot Labeling in UI
- Bot names remain "Bot 1", "Bot 2", etc. — no difficulty shown during play
- Difficulty is global and set at game start; no need to repeat it in the turn indicator or game log
- PLAYER_NAMES constant in app.js stays as-is

### Claude's Discretion
- Exact continent-completion scoring formula for Medium bot
- How to break ties when multiple continents are equally close to completion
- Internal class structure for MediumAgent (new class vs subclass of RandomAgent)
- Test strategy for verifying Medium bot exhibits continent focus behavior

</decisions>

<specifics>
## Specific Ideas

- RandomAgent already has advantage-based attack logic — Medium bot extends this with continent awareness on top
- PROJECT.md: "Medium bot visibly pursues continent control" — the behavior should be observable in normal play, not just statistically

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `risk/game.py`: `RandomAgent` — Easy bot, no changes needed; also `run_game()` for simulation
- `risk/player.py`: `PlayerAgent` Protocol — Medium bot just implements the same 6 methods
- `risk/engine/map_graph.py`: `MapGraph` with `neighbors()`, `connected_territories()`, `continent_territories()`, `continent_bonus()` — all useful for continent-aware strategy
- `risk/server/game_manager.py`: `GameManager.setup()` — creates agents per player slot; needs to accept difficulty param to choose Easy vs Medium agent class

### Established Patterns
- `map_graph` injected into agents after construction (see GameManager.setup() pattern)
- Bot agents are stateless decision-makers — they read GameState and return actions, no internal mutable state
- `PlayerAgent` is structural (Protocol), not ABC — Medium bot just needs matching method signatures

### Integration Points
- `GameManager.setup()` must accept `difficulty: str` ("easy" | "medium") and instantiate the right agent class for bot slots
- `index.html` setup screen: add difficulty `<select>` element alongside existing player count selector
- `app.js` `startBtn` handler: read difficulty value and include in `start_game` WebSocket message
- Server `app.py` WebSocket handler: parse difficulty from `start_game` message and pass to `GameManager.setup()`
- `StartGameMessage` Pydantic model in `messages.py`: add `difficulty` field

</code_context>

<deferred>
## Deferred Ideas

- Per-bot difficulty selection — v2 (REQUIREMENTS SETUP-04 already tracks this)
- Medium bot threat assessment (tracking which opponents are strongest) — Hard bot territory (Phase 5)
- Bot turn speed controls (slow/fast/instant) — v2 UIEN-01

</deferred>

---

*Phase: 04-easy-and-medium-bots*
*Context gathered: 2026-03-09*
