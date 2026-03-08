# Phase 3: Web UI and Game Setup - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

A human player can set up and play a complete game of Risk in a web browser. Includes: browser client with interactive SVG map, WebSocket server bridging frontend to Python engine, player setup screen, territory interaction, game log, and turn phase display. Bot AI strategy is Phase 4-5; this phase uses the existing RandomAgent for non-human players.

</domain>

<decisions>
## Implementation Decisions

### Map interaction
- Click-click model: click source territory (highlights), then click target territory for attacks and fortification
- Valid targets indicated by glowing/thicker borders; invalid territories dim slightly
- Reinforcement: click a territory to open a number input for how many armies to place; counter shows remaining armies
- Attack dice: defaults to max dice (3 if possible); small UI element allows reducing dice count
- Post-conquest: prompt asks how many armies to move in (minimum = dice rolled) — strategic choice preserved

### Game setup flow
- Setup screen offers only player count (2-6) and a Start button — minimal and functional
- Human is always Player 1 (goes first); other slots filled by RandomAgent bots
- Colors and names auto-assigned (no customization in v1)
- Single HTML page: setup form shows first, replaced by game board on start (no routing)
- Game end: show win/loss result with a "New Game" button that returns to setup

### Information layout
- Map takes ~75% of screen width; right sidebar contains turn info, continent bonuses, and game log
- Turn phase indicator: horizontal stepper at top of sidebar showing Reinforce -> Attack -> Fortify with active phase highlighted; current player name and color shown
- Continent bonuses: sidebar section listing each continent, its bonus value, and how many territories the human controls in it
- Game log: scrollable list of key events only — attacks (with dice results), conquests, card trades, eliminations, reinforcement totals. One line per event.
- Phase prompt banner: clear banner when it's the human's turn (e.g., "Your Turn: Place 5 reinforcements" or "Your Turn: Attack or End Phase")

### Turn flow visibility
- Bot turns execute with brief delays (~500ms between actions); map updates in real time, key events appear in game log
- Human always auto-defends with max dice during bot attacks (no interruption)
- Banner disappears during bot turns; reappears when human's turn begins

### Claude's Discretion
- WebSocket server framework choice (FastAPI, aiohttp, etc.)
- SVG map creation/sourcing approach (decided in Phase 1)
- Frontend framework choice (vanilla JS vs lightweight library)
- Exact styling, spacing, and color palette
- Error handling for invalid moves in the UI
- Card trading UI design (how to present cards and trade options)
- How to present dice roll results visually

</decisions>

<specifics>
## Specific Ideas

- PROJECT.md states "functional UI is sufficient" and "no animations/polished graphics" — keep it clean and usable, not fancy
- PlayerAgent protocol has 6 decision methods the human WebSocket agent must implement: choose_reinforcement_placement, choose_attack, choose_blitz, choose_fortify, choose_card_trade, choose_defender_dice
- The engine's execute_turn() runs a full turn synchronously — WebSocket agent will need to pause execution and await human input for each decision point

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `risk/player.py`: `PlayerAgent` protocol — human player needs a WebSocket-backed implementation
- `risk/game.py`: `run_game()` loop + `RandomAgent` — bots fill non-human slots
- `risk/engine/turn.py`: `execute_turn()` drives the Reinforce -> Attack -> Fortify FSM
- `risk/models/actions.py`: All action models (AttackAction, BlitzAction, FortifyAction, ReinforcePlacementAction, TradeCardsAction) — these are the inputs the UI must produce
- `risk/data/classic.json`: Map data with territories, adjacencies, continents — frontend needs this for SVG rendering
- `risk/engine/map_graph.py`: `MapGraph` with `neighbors()` and `connected_territories()` — useful for computing valid targets client-side or server-side

### Established Patterns
- Pydantic v2 models for all game state (immutable snapshots via model_copy)
- PlayerAgent uses typing.Protocol (structural subtyping) — human agent just needs matching methods
- Game state is a single immutable object passed through the turn engine — WebSocket server can serialize and send to frontend

### Integration Points
- Human WebSocket agent must implement PlayerAgent protocol, blocking on WebSocket messages for each decision
- `run_game()` currently runs synchronously — will need async adaptation or threading to handle WebSocket I/O
- `classic.json` territory names must match between backend game state and frontend SVG element IDs
- Frontend receives GameState snapshots to render map colors, army counts, and sidebar info

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-web-ui-and-game-setup*
*Context gathered: 2026-03-08*
