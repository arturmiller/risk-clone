---
phase: 02-game-engine
plan: 01
subsystem: engine
tags: [pydantic, risk-cards, reinforcements, protocol, game-models]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: GameState, TerritoryState, PlayerState, MapGraph with continent queries
provides:
  - Card, CardType, TurnPhase Pydantic models
  - AttackAction, BlitzAction, FortifyAction, TradeCardsAction, ReinforcePlacementAction models
  - Extended GameState with turn_phase, trade_count, cards, deck, conquered_this_turn
  - PlayerAgent protocol with all decision-point methods
  - calculate_reinforcements function (base + continent bonus)
  - Card system (create_deck, is_valid_set, get_trade_bonus, draw_card, execute_trade)
affects: [02-02-combat, 02-03-turn-engine, 03-web-ui, 04-bots, 05-ai]

# Tech tracking
tech-stack:
  added: []
  patterns: [immutable state updates via model_copy, Protocol for player interface, escalation sequence]

key-files:
  created:
    - risk/models/cards.py
    - risk/models/actions.py
    - risk/player.py
    - risk/engine/reinforcements.py
    - risk/engine/cards.py
    - tests/test_models.py
    - tests/test_reinforcements.py
    - tests/test_cards.py
  modified:
    - risk/models/game_state.py
    - risk/models/__init__.py
    - risk/engine/__init__.py

key-decisions:
  - "CardType uses Python enum with auto() for INFANTRY, CAVALRY, ARTILLERY, WILD"
  - "All new GameState fields have defaults for Phase 1 backwards compatibility"
  - "PlayerAgent uses typing.Protocol (structural subtyping) not ABC"
  - "Escalation formula: index into [4,6,8,10,12,15] then 15+5*(n-5) for higher trades"
  - "Card deck is unshuffled on creation; caller shuffles with their RNG for determinism"

patterns-established:
  - "Protocol pattern: PlayerAgent defines decision points as methods returning action models or None"
  - "Immutable state: engine functions return new GameState via model_copy(update=...)"
  - "Territory ownership query: {name for name, ts in state.territories.items() if ts.owner == idx}"

requirements-completed: [ENGI-01, ENGI-05, ENGI-06, ENGI-07]

# Metrics
duration: 4min
completed: 2026-03-08
---

# Phase 2 Plan 1: Data Models and Reinforcement/Card System Summary

**Extended GameState with turn tracking, Pydantic action/card models, PlayerAgent protocol, reinforcement calculator with continent bonuses, and complete card trading system with escalation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T07:12:49Z
- **Completed:** 2026-03-08T07:16:55Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Extended GameState with turn_phase, trade_count, cards, deck, conquered_this_turn (backwards compatible)
- Card system: 44-card deck creation, set validation (matching/one-of-each/wild), escalating trade bonuses, territory bonus on trade
- Reinforcement calculation: territory count // 3 (min 3) plus continent control bonuses
- PlayerAgent Protocol defining all 6 decision-point methods for human/bot interface
- 5 Pydantic action models with proper field validation (dice range, army minimum, card count)
- 78 new tests (34 model + 44 engine), full suite at 132 tests

## Task Commits

Each task was committed atomically:

1. **Task 1: Card models, action models, extended GameState, and PlayerAgent protocol** - `d05559a` (feat)
2. **Task 2: Reinforcement calculation and card system with tests** - `6dd839f` (feat)

## Files Created/Modified
- `risk/models/cards.py` - CardType enum, TurnPhase enum, Card Pydantic model
- `risk/models/actions.py` - AttackAction, BlitzAction, FortifyAction, TradeCardsAction, ReinforcePlacementAction
- `risk/models/game_state.py` - Extended GameState with turn tracking and card fields
- `risk/models/__init__.py` - Updated exports for all new models
- `risk/player.py` - PlayerAgent Protocol with 6 decision methods
- `risk/engine/reinforcements.py` - calculate_reinforcements function
- `risk/engine/cards.py` - create_deck, is_valid_set, get_trade_bonus, draw_card, execute_trade
- `risk/engine/__init__.py` - Updated exports for engine functions
- `tests/test_models.py` - 34 tests for models, enums, validation, serialization
- `tests/test_reinforcements.py` - 9 tests for base reinforcements and continent bonuses
- `tests/test_cards.py` - 35 tests for deck, set validation, trading, drawing

## Decisions Made
- Used `typing.Protocol` (structural subtyping) for PlayerAgent instead of ABC -- allows bots to implement the interface without inheriting from a base class
- All new GameState fields default to safe values so Phase 1 code and tests work unchanged
- Card deck returned unshuffled from `create_deck()`; caller shuffles with their own RNG for deterministic testing/replay
- Escalation formula: fixed sequence [4,6,8,10,12,15] then 15+5*(trade_count-5) for subsequent trades

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test territory selection to avoid accidental continent completion**
- **Found during:** Task 2 (reinforcement tests)
- **Issue:** Tests picking first N territories from `all_territories` inadvertently completed North America (first 9 territories), causing continent bonus to inflate expected values
- **Fix:** Created `_pick_no_continent()` helper that distributes territory picks across continents, never taking all from any single continent
- **Files modified:** tests/test_reinforcements.py
- **Verification:** All reinforcement tests pass with exact expected values
- **Committed in:** 6dd839f (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Test-only fix, no production code affected. No scope creep.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All action models, card models, and GameState extensions ready for combat system (Plan 02)
- PlayerAgent protocol ready for turn engine (Plan 03) to call decision methods
- Reinforcement calculator ready for turn engine reinforce phase
- Card system ready for turn engine card trading integration

---
## Self-Check: PASSED

All 8 created files verified. Both task commits (d05559a, 6dd839f) verified.

---
*Phase: 02-game-engine*
*Completed: 2026-03-08*
