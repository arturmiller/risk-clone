# Phase 2: Game Engine - Research

**Researched:** 2026-03-08
**Domain:** Turn-based game engine (FSM, combat resolution, card system, state management)
**Confidence:** HIGH

## Summary

Phase 2 builds a complete Risk game engine on top of Phase 1's foundation (MapGraph, GameState, setup logic). The core challenge is modeling the turn lifecycle as a finite state machine (Reinforce -> Attack -> Fortify -> End Turn), implementing rules-correct combat resolution, and building a territory card system with global escalation. All state mutations must produce new Pydantic model instances (immutable snapshots), consistent with the Phase 1 pattern.

The existing codebase already provides the critical building blocks: MapGraph with `connected_territories()` for fortification path validation, `controls_continent()` for continent bonus calculation, and GameState with territory/player state models. The engine needs to extend GameState with turn phase tracking, card-related fields, and the escalation counter. A player action interface (protocol/ABC) should be defined so Phase 4-5 bots can plug in without engine changes.

**Primary recommendation:** Hand-roll a simple enum-based FSM for turn phases (no library needed -- only 4 states with linear flow). Use `model_copy(update=...)` for immutable state evolution. Define a `PlayerAgent` protocol for the action interface. Keep the engine as a pure function pipeline: action in, new state out.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Card trading: 3 matching, one-of-each, or 2+wild. Wild substitutes for any type.
- Escalation sequence: 4, 6, 8, 10, 12, 15, then +5 each (20, 25, 30...) -- official Hasbro sequence
- Global escalation counter (not per-player)
- Territory bonus: 2 extra armies on owned territory shown on traded card
- Forced trade at 5+ cards at start of reinforcement phase
- 1 card per turn if conquered at least 1 territory
- Eliminated player's cards transfer to eliminator; if 5+, must trade immediately
- Attacker: 1-3 dice, needs N+1 armies to roll N dice
- Defender: 1-2 dice, needs N armies to roll N dice
- Highest dice paired, ties go to defender
- Blitz mode: auto-resolve until attacker wins or has 1 army left
- Minimum 1 army must remain on attacking territory
- After conquest: move at least as many armies as dice rolled
- FSM: Reinforce -> Attack -> Fortify -> End Turn
- Reinforce is mandatory (must place all armies)
- Attack is optional
- Fortify is optional, one move per turn along connected friendly path

### Claude's Discretion
- Turn engine architecture (class-based FSM, function-based, etc.)
- How to represent the card deck and card types
- Player interface abstraction (for human vs bot compatibility)
- Test strategy for full-game simulation
- Error handling for invalid moves

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ENGI-01 | Reinforcements at turn start (territory/3 + continent bonuses, min 3) | MapGraph.controls_continent() + continent_bonus() already exist; compute reinforcement count as pure function |
| ENGI-02 | Attack adjacent enemy territory with 1-3 dice vs 1-2 dice | Combat resolver module; validate adjacency via MapGraph.are_adjacent() |
| ENGI-03 | Blitz mode auto-resolve combat | Loop combat resolver until attacker wins or has 1 army; same dice logic |
| ENGI-04 | Fortify along connected friendly path | MapGraph.connected_territories() already implements BFS on friendly subgraph |
| ENGI-05 | Earn territory card on conquest turn | Boolean flag per turn tracking if conquest occurred; draw from deck at end of attack phase |
| ENGI-06 | Trade card sets for bonus armies (escalating global sequence) | Card model + set validation + global counter on GameState |
| ENGI-07 | Must trade cards if holding 5+ at start of turn | Enforce in reinforce phase entry; loop trades until < 5 |
| ENGI-08 | Eliminated player's cards transfer to eliminator | On elimination event, move card list; check forced trade |
| ENGI-09 | Game ends when one player controls all 42 territories | Victory check: len(player_territories) == len(all_territories) |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pydantic | >=2.0 | Immutable game state models | Already established in Phase 1; model_copy(update=) for state evolution |
| networkx | >=3.0 | Graph queries (adjacency, reachability) | Already established in Phase 1; MapGraph wraps it |
| Python stdlib random | 3.12+ | Dice rolling, card shuffling | Seeded RNG pattern already used in setup.py |
| Python stdlib enum | 3.12+ | Turn phases, card types | No external dependency needed for simple enums |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pytest | >=8.0 | Testing | Already in dev dependencies |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled enum FSM | python-statemachine library | Overkill for 4 linear states; adds dependency for no benefit |
| Pydantic frozen models | Plain dataclasses | Would lose validation, serialization; break Phase 1 consistency |
| Protocol-based PlayerAgent | ABC-based | Protocol is more Pythonic for structural typing; no inheritance needed |

## Architecture Patterns

### Recommended Project Structure
```
risk/
├── engine/
│   ├── map_graph.py          # [exists] Graph queries
│   ├── setup.py              # [exists] Game setup
│   ├── turn.py               # [NEW] Turn FSM, phase transitions, turn execution
│   ├── combat.py             # [NEW] Dice rolling, combat resolution, blitz
│   ├── cards.py              # [NEW] Card deck, set validation, trading
│   └── reinforcements.py     # [NEW] Reinforcement calculation
├── models/
│   ├── map_schema.py         # [exists] Map JSON validation
│   ├── game_state.py         # [EXTEND] Add card/phase/escalation fields
│   ├── actions.py            # [NEW] Action models (attack, fortify, trade, etc.)
│   └── cards.py              # [NEW] Card, CardType, Deck models
├── player.py                 # [NEW] PlayerAgent protocol
└── game.py                   # [NEW] Game runner (orchestrates full game loop)
tests/
├── conftest.py               # [EXTEND] Add game-in-progress fixtures
├── test_reinforcements.py    # [NEW]
├── test_combat.py            # [NEW]
├── test_cards.py             # [NEW]
├── test_turn.py              # [NEW]
├── test_fortify.py           # [NEW]
└── test_full_game.py         # [NEW] End-to-end programmatic game
```

### Pattern 1: Enum-Based Turn Phase FSM
**What:** Use a simple Python Enum for turn phases with a dispatch dict or match statement.
**When to use:** Always -- this is the turn lifecycle.
**Example:**
```python
from enum import Enum, auto

class TurnPhase(Enum):
    REINFORCE = auto()
    ATTACK = auto()
    FORTIFY = auto()

# Phase transitions are linear: REINFORCE -> ATTACK -> FORTIFY -> next player
```

### Pattern 2: Immutable State Evolution with model_copy
**What:** Never mutate GameState. Each action returns a new GameState via `model_copy(update={...})`.
**When to use:** Every state transition.
**Example:**
```python
# Pydantic v2 model_copy with update parameter
new_territories = {**state.territories}
new_territories[territory_name] = TerritoryState(owner=new_owner, armies=new_armies)
new_state = state.model_copy(update={"territories": new_territories})
```

### Pattern 3: PlayerAgent Protocol
**What:** A Protocol defining the interface bots and humans must implement.
**When to use:** All player decision points.
**Example:**
```python
from typing import Protocol

class PlayerAgent(Protocol):
    def choose_reinforcement_placement(self, state: GameState, armies: int) -> dict[str, int]:
        """Return {territory_name: armies_to_place}. Must sum to `armies`."""
        ...

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Return attack action or None to end attack phase."""
        ...

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """Return fortify action or None to skip."""
        ...

    def choose_card_trade(self, state: GameState, cards: list[Card], forced: bool) -> list[Card] | None:
        """Return 3 cards to trade or None (only if not forced)."""
        ...
```

### Pattern 4: Action Models as Pydantic Objects
**What:** Each player action is a validated Pydantic model.
**When to use:** All moves passed to the engine.
**Example:**
```python
class AttackAction(BaseModel):
    source: str
    target: str
    num_dice: int = Field(ge=1, le=3)

class FortifyAction(BaseModel):
    source: str
    target: str
    armies: int = Field(ge=1)
```

### Pattern 5: Result Types for Combat
**What:** Return structured combat results instead of mutating state inline.
**When to use:** Combat resolution.
**Example:**
```python
class CombatResult(BaseModel):
    attacker_losses: int
    defender_losses: int
    territory_conquered: bool
    # After resolution, the caller applies losses to state
```

### Anti-Patterns to Avoid
- **Mutating GameState in place:** Violates the immutable snapshot pattern; breaks undo/replay potential and makes debugging impossible.
- **God-class engine:** Don't put all logic in one TurnEngine class. Separate combat, cards, reinforcements into focused modules.
- **Coupling dice to combat:** Keep dice rolling separate from combat resolution logic. Inject dice results for testability (seeded RNG).
- **Hardcoding 42 territories:** Use `len(map_graph.all_territories)` for victory check; don't assume classic map.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Graph reachability | BFS/DFS for fortification paths | MapGraph.connected_territories() (NetworkX) | Already implemented, handles edge cases |
| Continent control check | Manual set comparison | MapGraph.controls_continent() | Already implemented |
| Model validation | Manual field checks | Pydantic validators on action models | Consistent with codebase; catches invalid actions early |
| Random number generation | Custom RNG | stdlib random.Random with seed | Already pattern in setup.py; deterministic testing |

**Key insight:** Phase 1 already built the hard graph-theory parts. Phase 2's complexity is in correctly implementing game rules and state transitions, not in data structures.

## Common Pitfalls

### Pitfall 1: Off-by-One in Army Requirements
**What goes wrong:** Attacker with 3 armies rolls 3 dice (should only allow 2 -- need N+1 to roll N).
**Why it happens:** Confusing "armies on territory" with "armies available to attack."
**How to avoid:** Validate: `num_dice <= territory.armies - 1` (must leave 1 behind).
**Warning signs:** Tests pass with 4+ armies but fail at boundary (2 armies, 1 die).

### Pitfall 2: Forgetting Minimum 1 Army on Source
**What goes wrong:** All armies move during conquest or fortification, leaving source with 0.
**Why it happens:** Easy to forget the "must leave at least 1" rule in multiple places.
**How to avoid:** Add Pydantic validator `armies = Field(ge=1)` on TerritoryState (already done!). Also validate in action processing.
**Warning signs:** Pydantic validation error on TerritoryState construction.

### Pitfall 3: Global vs Per-Player Escalation Counter
**What goes wrong:** Each player gets 4, 6, 8... independently instead of globally.
**Why it happens:** Seems logical to track per player; but Risk uses a global counter as an anti-stalemate mechanism.
**How to avoid:** Store `trade_count: int` on GameState, not on PlayerState.
**Warning signs:** Late-game trades should give 20+ armies; if not, counter is wrong.

### Pitfall 4: Forced Trade Cascade on Elimination
**What goes wrong:** Player A eliminates Player B who has 4 cards. Player A already has 3 cards, now has 7. Must immediately trade before continuing.
**Why it happens:** Easy to implement card transfer without checking for forced trade afterward.
**How to avoid:** After card transfer, loop: while cards >= 5, force trade.
**Warning signs:** Player ends up with 5+ cards during attack phase.

### Pitfall 5: Dice Pairing Logic
**What goes wrong:** Comparing wrong dice. E.g., attacker rolls [6,3,1], defender rolls [5,2]. Must compare 6 vs 5 (attacker wins) and 3 vs 2 (attacker wins). NOT 6 vs 5 and 1 vs 2.
**Why it happens:** Not sorting dice before pairing.
**How to avoid:** Sort both lists descending, zip, compare.
**Warning signs:** Defender loses more than expected in tests.

### Pitfall 6: Card Earning Timing
**What goes wrong:** Player earns card at wrong time (immediately on conquest vs end of attack phase).
**Why it happens:** Ambiguity in when to award the card.
**How to avoid:** Set a `conquered_this_turn: bool` flag on conquest; draw card once when transitioning out of attack phase. Only 1 card per turn maximum.
**Warning signs:** Player earns multiple cards in one turn.

### Pitfall 7: Victory Check After Elimination
**What goes wrong:** Game doesn't end when last opponent is eliminated mid-attack.
**Why it happens:** Victory check only happens at end of turn.
**How to avoid:** Check victory condition after every conquest (when a player is eliminated).
**Warning signs:** Game continues after one player owns all territories.

## Code Examples

### Reinforcement Calculation
```python
def calculate_reinforcements(state: GameState, map_graph: MapGraph, player_index: int) -> int:
    """Calculate total reinforcement armies for a player."""
    player_territories = {
        name for name, ts in state.territories.items()
        if ts.owner == player_index
    }
    # Base: territory count / 3, minimum 3
    base = max(len(player_territories) // 3, 3)

    # Continent bonuses
    bonus = 0
    for continent_name in map_graph._continent_bonuses:
        if map_graph.controls_continent(continent_name, player_territories):
            bonus += map_graph.continent_bonus(continent_name)

    return base + bonus
```

### Combat Resolution (Single Roll)
```python
def resolve_combat(
    attacker_dice: int, defender_dice: int, rng: random.Random
) -> CombatResult:
    """Resolve one round of combat."""
    attack_rolls = sorted([rng.randint(1, 6) for _ in range(attacker_dice)], reverse=True)
    defend_rolls = sorted([rng.randint(1, 6) for _ in range(defender_dice)], reverse=True)

    attacker_losses = 0
    defender_losses = 0
    for a, d in zip(attack_rolls, defend_rolls):
        if a > d:
            defender_losses += 1
        else:  # ties go to defender
            attacker_losses += 1

    return CombatResult(
        attacker_losses=attacker_losses,
        defender_losses=defender_losses,
        territory_conquered=(False),  # caller checks if defender armies hit 0
    )
```

### Card Set Validation
```python
from enum import Enum, auto
from collections import Counter

class CardType(Enum):
    INFANTRY = auto()
    CAVALRY = auto()
    ARTILLERY = auto()
    WILD = auto()

def is_valid_set(cards: list[CardType]) -> bool:
    """Check if 3 cards form a valid trading set."""
    if len(cards) != 3:
        return False
    wilds = sum(1 for c in cards if c == CardType.WILD)
    non_wilds = [c for c in cards if c != CardType.WILD]

    if wilds >= 2:
        return True  # 2 wilds + anything
    if wilds == 1:
        return True  # 1 wild + any 2 (wild substitutes)
    # No wilds: 3 matching OR one of each
    types = set(non_wilds)
    return len(types) == 1 or len(types) == 3

ESCALATION_SEQUENCE = [4, 6, 8, 10, 12, 15]
# After index 5: 15 + 5*(n-5) = 20, 25, 30...

def get_trade_bonus(trade_count: int) -> int:
    """Get bonus armies for the Nth trade (0-indexed)."""
    if trade_count < len(ESCALATION_SEQUENCE):
        return ESCALATION_SEQUENCE[trade_count]
    return 15 + 5 * (trade_count - 5)
```

### GameState Extension
```python
# Extend the existing GameState for Phase 2
class GameState(BaseModel):
    territories: dict[str, TerritoryState]
    players: list[PlayerState]
    current_player_index: int = 0
    turn_number: int = 0
    # Phase 2 additions:
    turn_phase: TurnPhase = TurnPhase.REINFORCE
    trade_count: int = 0  # Global escalation counter
    cards: dict[int, list[Card]] = {}  # player_index -> cards
    deck: list[Card] = []  # draw pile
    conquered_this_turn: bool = False  # for card earning
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pydantic v1 .copy(update=) | Pydantic v2 .model_copy(update=) | Pydantic 2.0 (2023) | Must use new API name |
| typing.Protocol (3.8+) | runtime_checkable Protocol | Python 3.8+ stable | Use for PlayerAgent interface |
| match/case | match/case (3.10+) | Python 3.10 | Can use for FSM dispatch since project requires 3.12+ |

**Deprecated/outdated:**
- Pydantic v1 `.copy()` method: Use `.model_copy()` in v2
- Pydantic v1 `.dict()` method: Use `.model_dump()` in v2

## Open Questions

1. **Should GameState be frozen (immutable)?**
   - What we know: Phase 1 models are NOT frozen. TerritoryState is rebuilt on change (setup.py line 68).
   - What's unclear: Whether to add `model_config = ConfigDict(frozen=True)` now.
   - Recommendation: Keep unfrozen for now (matching Phase 1 pattern). The engine should still follow the immutable-by-convention pattern (always create new states), but `frozen=True` adds friction without clear benefit at this stage.

2. **Card model: territory reference?**
   - What we know: Risk cards show a territory + a troop type. If you trade a card showing a territory you own, you get 2 bonus armies on it.
   - What's unclear: How many cards in the deck (42 territory cards + 2 wilds = 44 total in classic Risk).
   - Recommendation: 44 cards total. Card model: `Card(territory: str | None, card_type: CardType)`. Wild cards have `territory=None`.

3. **Where to place PlayerAgent protocol?**
   - What we know: Bots (Phase 4-5) and potentially human input (Phase 3) need same interface.
   - Recommendation: `risk/player.py` at package root since it's cross-cutting.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest >=8.0 |
| Config file | pyproject.toml [tool.pytest.ini_options] |
| Quick run command | `pytest tests/ -x -q` |
| Full suite command | `pytest tests/ -v` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENGI-01 | Correct reinforcement calculation (territory/3 + continent bonus, min 3) | unit | `pytest tests/test_reinforcements.py -x` | No -- Wave 0 |
| ENGI-02 | Single combat roll (1-3 vs 1-2 dice, ties to defender) | unit | `pytest tests/test_combat.py::test_single_combat -x` | No -- Wave 0 |
| ENGI-03 | Blitz auto-resolve until win or 1 army left | unit | `pytest tests/test_combat.py::test_blitz -x` | No -- Wave 0 |
| ENGI-04 | Fortify along connected friendly path only | unit | `pytest tests/test_fortify.py -x` | No -- Wave 0 |
| ENGI-05 | Card earned on conquest turn (max 1 per turn) | unit | `pytest tests/test_cards.py::test_card_earning -x` | No -- Wave 0 |
| ENGI-06 | Card set trade for escalating bonus | unit | `pytest tests/test_cards.py::test_card_trading -x` | No -- Wave 0 |
| ENGI-07 | Forced trade at 5+ cards | unit | `pytest tests/test_cards.py::test_forced_trade -x` | No -- Wave 0 |
| ENGI-08 | Eliminated player cards transfer | unit+integration | `pytest tests/test_turn.py::test_elimination_card_transfer -x` | No -- Wave 0 |
| ENGI-09 | Victory when all 42 territories controlled | unit | `pytest tests/test_turn.py::test_victory -x` | No -- Wave 0 |
| E2E | Full game runs to completion programmatically | integration | `pytest tests/test_full_game.py -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `pytest tests/ -x -q`
- **Per wave merge:** `pytest tests/ -v`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/test_reinforcements.py` -- covers ENGI-01
- [ ] `tests/test_combat.py` -- covers ENGI-02, ENGI-03
- [ ] `tests/test_cards.py` -- covers ENGI-05, ENGI-06, ENGI-07
- [ ] `tests/test_fortify.py` -- covers ENGI-04
- [ ] `tests/test_turn.py` -- covers ENGI-08, ENGI-09, turn phase transitions
- [ ] `tests/test_full_game.py` -- covers E2E full game simulation
- [ ] `tests/conftest.py` update -- add mid-game state fixtures, seeded RNG fixtures

## Sources

### Primary (HIGH confidence)
- Existing codebase: `risk/engine/map_graph.py`, `risk/models/game_state.py`, `risk/engine/setup.py` -- establishes all patterns
- [Pydantic v2 official docs - Models](https://docs.pydantic.dev/latest/concepts/models/) -- model_copy(update=) API
- Phase 2 CONTEXT.md -- locked decisions on all game rules

### Secondary (MEDIUM confidence)
- [Game Programming Patterns - State](https://gameprogrammingpatterns.com/state.html) -- FSM pattern reference
- Official Hasbro Risk rules (referenced in CONTEXT.md decisions) -- card escalation sequence, combat rules

### Tertiary (LOW confidence)
- None -- all findings verified against official sources or existing codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies needed, extending established patterns
- Architecture: HIGH -- clear module boundaries, well-understood game rules
- Pitfalls: HIGH -- Risk game rules are well-documented; common edge cases are known
- Validation: HIGH -- pytest already configured, clear requirement-to-test mapping

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable domain, no fast-moving dependencies)
