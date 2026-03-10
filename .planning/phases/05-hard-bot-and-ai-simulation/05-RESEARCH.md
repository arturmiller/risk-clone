# Phase 5: Hard Bot and AI Simulation - Research

**Researched:** 2026-03-10
**Domain:** Heuristic Risk AI strategy, AI-vs-AI simulation mode, batch testing
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOTS-03 | Hard bot plays at human-competitive level (threat assessment, army concentration, card timing, continent control) | `HardAgent` new class extending MediumAgent patterns; multi-factor scoring, border security ratio, card timing, threat model -- all detailed in Architecture Patterns below |
| BOTS-04 | AI-vs-AI simulation mode (watch bots play without human player) | `GameManager` refactored to support no-human mode; new `"simulation"` game_mode in StartGameMessage; frontend checkbox/button on setup screen; bot-only game loop without HumanWebSocketAgent |
</phase_requirements>

---

## Summary

Phase 5 has two distinct deliverables: (1) a `HardAgent` that plays at human-competitive level, and (2) an AI-vs-AI simulation mode where all players are bots and the user watches.

The Hard bot builds on the existing `MediumAgent` architecture but adds four strategic dimensions that the Medium bot lacks: **threat assessment** (tracking which opponents are dangerous and where), **army concentration** (massing forces rather than spreading thin), **card timing** (holding cards for higher escalation values when safe, trading early when forced), and **multi-factor territory evaluation** (combining continent progress, border security ratio, and opponent blocking into a single scoring function). The existing `PlayerAgent` protocol and `MapGraph` API provide everything needed -- no engine changes required.

For AI-vs-AI simulation, the server-side change is straightforward: `GameManager` currently hardcodes player 0 as a `HumanWebSocketAgent`. The simulation mode creates bot agents for ALL player slots, removes the human input waiting, and runs the game loop with a configurable delay between turns so the user can watch. The frontend adds a "Watch AI Game" option to the setup screen and disables all human input controls during simulation. The WebSocket protocol already supports all needed message types (game_state, game_event, game_over).

**Primary recommendation:** Implement `HardAgent` in `risk/bots/hard.py` using a weighted multi-factor scoring system (not ML/neural nets). Add `game_mode: "simulation"` to the WebSocket protocol. Keep the simulation game loop inside `GameManager` with a separate `_run_simulation_loop` that skips human agent creation entirely.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python stdlib `random` | 3.13 | RNG for HardAgent | Already used by RandomAgent and MediumAgent |
| Python stdlib `math` | 3.13 | Combat probability calculations | Binomial/combinatorial math for attack odds |
| Pydantic v2 | existing | Message model extensions | Already project dependency |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `networkx` | existing | MapGraph BFS and path queries | Fortify path validation, connected component analysis |
| `pytest` | existing | Batch testing Hard bot vs Medium/Easy | Statistical win-rate validation |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Heuristic scoring | Monte Carlo Tree Search (MCTS) | MCTS gives stronger play but is computationally expensive, hard to tune, and overkill for a heuristic bot |
| Hand-tuned weights | Neural network / reinforcement learning | ML requires training infrastructure, thousands of games, and adds complexity far beyond scope |
| Single scoring function | Separate evaluation per phase | Single function is simpler but less nuanced; per-phase evaluation (reinforce, attack, fortify) matches the existing agent method structure |

---

## Architecture Patterns

### Recommended Project Structure
```
risk/bots/
  __init__.py        # Add HardAgent export
  medium.py          # Existing MediumAgent
  hard.py            # NEW: HardAgent implementation
risk/server/
  game_manager.py    # Modified: support simulation mode
  messages.py        # Modified: game_mode field on StartGameMessage
  app.py             # Modified: pass game_mode through WebSocket
risk/static/
  index.html         # Modified: simulation checkbox/mode on setup screen
  app.js             # Modified: simulation mode UI logic
tests/
  test_hard_agent.py # NEW: unit tests for HardAgent strategy
  test_simulation.py # NEW: AI-vs-AI simulation tests
```

### Pattern 1: Multi-Factor Territory Scoring (HardAgent Core)

**What:** A weighted scoring function that evaluates each territory/action based on multiple strategic factors simultaneously.

**When to use:** Every decision point (reinforce, attack, fortify).

**Design:**

```python
class HardAgent:
    """Human-competitive Risk bot using multi-factor heuristic scoring."""

    # Tunable weights for the scoring function
    CONTINENT_PROGRESS_WEIGHT = 3.0    # How much to value continent completion
    BORDER_SECURITY_WEIGHT = 2.0       # How much to value border defense
    THREAT_WEIGHT = 1.5                # How much to penalize nearby threats
    CARD_TIMING_THRESHOLD = 4          # Hold cards until 4+ in hand (unless forced)
    ATTACK_PROBABILITY_THRESHOLD = 0.6 # Only attack with >= 60% win probability

    def __init__(self, rng: random.Random | None = None) -> None:
        self._rng = rng or random.Random()
        self._map_graph: MapGraph | None = None
```

**Key scoring factors per decision:**

1. **Continent completion score**: `(owned_in_continent / total_in_continent) * continent_bonus * CONTINENT_PROGRESS_WEIGHT`
   - Continents >50% complete get exponential boost
   - Small continents (Australia, South America) preferred early game

2. **Border Security Ratio (BSR)**: `enemy_armies_adjacent / own_armies` per territory
   - Lower BSR = more secure border
   - Reinforce territories with highest BSR (most vulnerable)

3. **Threat assessment**: For each opponent, sum of `(opponent_armies_near_border / distance)`
   - Track which opponent controls/nearly controls continents
   - Prioritize blocking opponent continent completion over own expansion

4. **Army concentration index**: Prefer placing ALL reinforcements on 1-2 territories rather than spreading

### Pattern 2: Strategic Card Timing

**What:** Hold cards for higher escalation bonus instead of trading immediately.

**When to use:** `choose_card_trade()` decision.

**Design:**
```python
def choose_card_trade(self, state: GameState, cards: list[Card], forced: bool) -> TradeCardsAction | None:
    if forced:
        # Must trade -- pick the set that maximizes territory bonus
        return self._best_trade(state, cards)

    if len(cards) < 3:
        return None

    # Hold cards until 4 in hand (trade at 5 is forced anyway)
    # Exception: trade early if escalation bonus is already high (trade_count >= 4 means 10+ armies)
    if len(cards) >= 4 or state.trade_count >= 4:
        return self._best_trade(state, cards)

    # Otherwise hold -- the escalation bonus increases with each global trade
    return None
```

**Rationale:** The escalation sequence is [4, 6, 8, 10, 12, 15, 20, 25...]. Trading later in the game yields dramatically more armies. A smart bot holds cards to maximize the bonus timing while avoiding the forced-trade penalty at 5 cards.

### Pattern 3: Threat-Aware Attack Selection

**What:** Evaluate attacks not just by local odds but by strategic impact.

**When to use:** `choose_attack()` decision.

**Attack priority ordering:**
1. **Continent-completing attacks** (even at slight disadvantage, like MediumAgent but with probability assessment)
2. **Block opponent continent completion** (if opponent owns N-1 of a continent, attack the remaining territory)
3. **Attacks into highest-value continent** with favorable probability (>= 60%)
4. **Attacks that improve border security** (reduce BSR by eliminating weak enemy neighbor)
5. **Any attack with overwhelming force** (3:1 or better army ratio)

**Stop attacking when:**
- Total army count drops below a safety threshold (preserve defense)
- Already earned a card this turn (conquered >= 1 territory) and remaining attacks are marginal
- BSR on critical borders would become too high if more armies are lost

### Pattern 4: Intelligent Army Advancement

**What:** After conquering a territory, decide how many armies to advance.

**When to use:** `choose_advance_armies()` decision.

**Design:** Unlike Easy/Medium (which advance minimum), Hard bot evaluates:
- If conquered territory borders more enemies, advance more armies
- If source territory is interior (no enemy neighbors), advance all but 1
- If source borders enemies too, split armies proportionally to threat on each side

### Pattern 5: AI-vs-AI Simulation Mode

**What:** Game loop where all players are bots, no human input needed.

**When to use:** User selects "Watch AI Game" from setup screen.

**Server-side changes to GameManager:**

```python
def setup(self, num_players, map_graph, send_callback, loop=None,
          bot_delay=None, difficulty="easy", game_mode="play"):
    """game_mode: 'play' (human + bots) or 'simulation' (all bots)."""
    ...
    if game_mode == "simulation":
        # All players are bots -- no human agent
        for i in range(num_players):
            bot = self._create_bot(difficulty, rng)
            bot._map_graph = map_graph
            self.agents[i] = bot
        self.human_agent = None
    else:
        # Existing logic: player 0 is human
        ...
```

**Simulation game loop differences from regular loop:**
- No `HumanWebSocketAgent` creation
- No `request_input` messages sent
- All turns use bot delay (configurable speed)
- Game state updates sent every turn for visualization
- Player names: "Bot 1", "Bot 2", etc. (no "You")

**Frontend changes:**
- Add "Watch AI Game" checkbox or separate button on setup screen
- When simulation mode: hide dice controls, hide action buttons
- Game log and map updates work identically (same WebSocket messages)
- Setup screen difficulty selector applies to simulation bots too

### Anti-Patterns to Avoid
- **Over-engineering the scoring function:** Keep weights simple and tunable. Do not implement full MCTS or neural network evaluation -- heuristics are sufficient for "human-competitive" play.
- **Mutating agent state between turns:** Follow existing convention -- all strategy computed fresh from GameState each call, no persistent state on self.
- **Computing attack probability with full simulation:** Use precomputed probability tables for 1v1, 2v1, 3v1, 2v2, 3v2 dice matchups, not Monte Carlo simulation per attack.
- **Ignoring the advance armies decision:** Medium/Easy bots advance minimum; Hard bot should advance intelligently as this significantly impacts game outcomes.
- **Breaking the existing game loop:** The simulation mode should reuse `execute_turn()` unchanged. Only `GameManager` orchestration changes.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Attack success probability | Monte Carlo dice simulation | Precomputed lookup table | Only 6 attacker/defender dice combinations exist (1v1, 1v2, 2v1, 2v2, 3v1, 3v2); precompute once |
| Graph connectivity | Custom BFS | `MapGraph.connected_territories()` | Already implemented with NetworkX |
| Continent ownership check | Manual territory iteration | `MapGraph.controls_continent()` | Already exists |
| Card set validation | Custom combination logic | `is_valid_set()` from engine | Already implemented |
| Escalation bonus calc | Custom formula | `get_trade_bonus()` | Already implemented in cards.py |

**Key insight:** The game engine and MapGraph already provide every query the Hard bot needs. The bot's complexity is in the DECISION LOGIC (scoring, prioritization), not in new game mechanics.

### Precomputed Attack Probability Table

These are the exact probabilities of the attacker winning each dice comparison, accounting for tie-goes-to-defender:

| Attacker Dice | Defender Dice | P(attacker wins at least 1) | P(attacker wins all) |
|---------------|---------------|-----------------------------|-----------------------|
| 1 | 1 | 0.417 | 0.417 |
| 2 | 1 | 0.579 | 0.579 |
| 3 | 1 | 0.660 | 0.660 |
| 1 | 2 | 0.255 | 0.255 |
| 2 | 2 | 0.228 (win both) | 0.228 |
| 3 | 2 | 0.372 (win both) | 0.372 |

These should be embedded as constants, not recomputed.

---

## Common Pitfalls

### Pitfall 1: Hard Bot Plays Too Conservatively
**What goes wrong:** With threat assessment and probability thresholds, the bot refuses to attack and turtles behind borders.
**Why it happens:** Threshold set too high (e.g., requiring 80%+ win probability).
**How to avoid:** Set attack probability threshold to 60% for normal attacks, allow continent-completing attacks at even lower probability. Include an "aggression check" -- if the bot hasn't attacked for N turns, lower thresholds.
**Warning signs:** In batch testing, Hard bot games take 2-3x longer than Medium bot games.

### Pitfall 2: Hard Bot Plays Too Aggressively
**What goes wrong:** Bot drains armies chasing conquests and gets eliminated next turn.
**Why it happens:** No stopping condition during attack phase; bot keeps attacking until it can't.
**How to avoid:** Implement an "army preservation" check: stop attacking when total army count on border territories drops below a safety threshold relative to adjacent enemy armies.
**Warning signs:** Hard bot has high territory count mid-game but gets eliminated in late game.

### Pitfall 3: Simulation Mode WebSocket Race Condition
**What goes wrong:** In simulation mode, game loop runs too fast and floods the WebSocket with messages before the client processes them.
**Why it happens:** Bot turns have no human input delays, so turns execute in milliseconds.
**How to avoid:** Keep `bot_delay` (currently 0.5s) in simulation mode. Allow user-adjustable speed but always enforce a minimum delay (e.g., 100ms) to prevent WebSocket buffer overflow.
**Warning signs:** Browser becomes unresponsive during simulation; game log entries appear garbled.

### Pitfall 4: Infinite Card Hold
**What goes wrong:** Bot never trades cards voluntarily, misses strategic advantage of early large armies.
**Why it happens:** Card timing logic always defers trading.
**How to avoid:** Force voluntary trade at 4 cards (5 is engine-forced anyway). Also trade early if escalation bonus is already high (>= 10 armies).
**Warning signs:** Bot consistently holds 4 cards and only trades when forced.

### Pitfall 5: Hard Bot Doesn't Beat Medium Statistically
**What goes wrong:** Despite more complex logic, win rate against Medium is near 50%.
**Why it happens:** Scoring weights are poorly tuned, or the additional complexity adds no real strategic value.
**How to avoid:** Run batch testing (100+ games) during development. Expect Hard bot to win >= 60% of 1v1 games against Medium. Tune weights iteratively based on results.
**Warning signs:** Win rate below 55% in batch testing after initial implementation.

---

## Code Examples

### Attack Probability Lookup (Precomputed)

```python
# Source: Exact calculation from Risk dice rules (ties go to defender)
# Key: (attacker_dice, defender_dice) -> (p_attacker_net_gain, p_defender_net_gain, p_split)
ATTACK_PROBABILITIES = {
    (1, 1): (0.4167, 0.5833),  # attacker wins, defender wins
    (2, 1): (0.5787, 0.4213),
    (3, 1): (0.6597, 0.3403),
    (1, 2): (0.2546, 0.7454),
    (2, 2): (0.2276, 0.4483, 0.3241),  # both lose 1, defender loses 2, attacker loses 2
    (3, 2): (0.3717, 0.2926, 0.3358),
}
```

### Border Security Ratio Calculation

```python
def _border_security_ratio(self, state: GameState, territory: str) -> float:
    """Calculate BSR for a territory: sum(enemy_adjacent_armies) / own_armies.

    Lower BSR = more secure. BSR > 1.0 means territory is vulnerable.
    """
    mg = self._map_graph
    if mg is None:
        return 0.0
    own_armies = state.territories[territory].armies
    enemy_adjacent = sum(
        state.territories[n].armies
        for n in mg.neighbors(territory)
        if state.territories[n].owner != state.territories[territory].owner
    )
    return enemy_adjacent / max(own_armies, 1)
```

### Threat Assessment per Opponent

```python
def _opponent_threat_scores(self, state: GameState) -> dict[int, float]:
    """Score each opponent by how threatening they are.

    Factors: total armies, continent control progress, armies near our borders.
    """
    mg = self._map_graph
    player = state.current_player_index
    threats: dict[int, float] = {}

    for p in state.players:
        if p.index == player or not p.is_alive:
            continue

        # Factor 1: Total army count
        total = sum(
            ts.armies for ts in state.territories.values() if ts.owner == p.index
        )

        # Factor 2: Continent control (nearly complete continents are threatening)
        continent_threat = 0.0
        for cont_name, cont_terrs in mg._continent_territories.items():
            owned = sum(1 for t in cont_terrs if state.territories[t].owner == p.index)
            if owned >= len(cont_terrs) - 1:  # Missing only 1 territory
                continent_threat += mg.continent_bonus(cont_name) * 2
            elif owned >= len(cont_terrs) * 0.7:
                continent_threat += mg.continent_bonus(cont_name)

        threats[p.index] = total * 0.5 + continent_threat * 2.0

    return threats
```

### Batch Testing Script Pattern

```python
def test_hard_vs_medium_batch():
    """Hard bot should win significantly more than chance against Medium."""
    from risk.bots.hard import HardAgent
    from risk.bots.medium import MediumAgent
    from risk.game import run_game

    wins = {0: 0, 1: 0}
    num_games = 100

    for seed in range(num_games):
        rng = random.Random(seed)
        agents = {
            0: HardAgent(rng=random.Random(seed * 2)),
            1: MediumAgent(rng=random.Random(seed * 2 + 1)),
        }
        final = run_game(MAP_GRAPH, agents, rng, max_turns=1000)
        winner = next(p.index for p in final.players if p.is_alive)
        wins[winner] += 1

    # Hard bot (player 0) should win >= 55% of games
    assert wins[0] >= 55, f"Hard bot won only {wins[0]}% -- expected >= 55%"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Random play | Continent-aware heuristics (MediumAgent) | Phase 4 | Baseline strategic play |
| Single-factor attack decision | Multi-factor scoring with threat assessment | This phase | Human-competitive strategy |
| Always trade cards immediately | Strategic card timing | This phase | Better resource management |
| Minimum army advancement | Context-aware advancement | This phase | Better territory control after conquest |
| Human-only games | AI-vs-AI simulation | This phase | New game mode for entertainment/testing |

---

## Open Questions

1. **Exact weight tuning for scoring function**
   - What we know: The scoring factors (continent progress, BSR, threat) are well-established in Risk AI literature
   - What's unclear: Optimal weight values require iterative testing
   - Recommendation: Start with the weights in the Architecture Patterns section, run batch tests, adjust. Plan should include a "tuning" task with batch testing.

2. **Simulation mode bot speed**
   - What we know: Current `BOT_DELAY` is 0.5 seconds per turn
   - What's unclear: Whether user wants speed controls (this is v2 per UIEN-01)
   - Recommendation: Use 0.5s default for simulation. Do NOT implement speed controls (out of scope). Mention in UI that this is auto-play mode.

3. **How many games for statistical validation**
   - What we know: 100 games gives reasonable confidence for win-rate comparison
   - What's unclear: Exact confidence interval needed
   - Recommendation: Run 100 games in batch test. Hard bot should win >= 55% against Medium in 1v1. This is a pytest test that runs in ~60 seconds.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest (existing) |
| Config file | pyproject.toml or pytest.ini (existing project config) |
| Quick run command | `python -m pytest tests/test_hard_agent.py tests/test_simulation.py -x -q` |
| Full suite command | `python -m pytest tests/ -x -q` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOTS-03 | Hard bot prioritizes continent completion | unit | `python -m pytest tests/test_hard_agent.py::TestHardReinforce -x` | No -- Wave 0 |
| BOTS-03 | Hard bot concentrates armies on borders | unit | `python -m pytest tests/test_hard_agent.py::TestHardReinforce::test_concentrates_on_vulnerable -x` | No -- Wave 0 |
| BOTS-03 | Hard bot times card trades strategically | unit | `python -m pytest tests/test_hard_agent.py::TestHardCardTiming -x` | No -- Wave 0 |
| BOTS-03 | Hard bot assesses threats from opponents | unit | `python -m pytest tests/test_hard_agent.py::TestHardThreat -x` | No -- Wave 0 |
| BOTS-03 | Hard bot wins > chance vs Medium in batch | integration | `python -m pytest tests/test_hard_agent.py::TestHardBatch -x` | No -- Wave 0 |
| BOTS-03 | Hard bot completes full game without crash | integration | `python -m pytest tests/test_hard_agent.py::TestHardFullGame -x` | No -- Wave 0 |
| BOTS-04 | AI-vs-AI simulation starts without human | integration | `python -m pytest tests/test_simulation.py::TestSimulationMode -x` | No -- Wave 0 |
| BOTS-04 | AI-vs-AI simulation completes and emits game_over | integration | `python -m pytest tests/test_simulation.py::TestSimulationCompletion -x` | No -- Wave 0 |
| BOTS-04 | Setup screen offers simulation mode | manual-only | Browser verification | N/A |

### Sampling Rate
- **Per task commit:** `python -m pytest tests/test_hard_agent.py tests/test_simulation.py -x -q`
- **Per wave merge:** `python -m pytest tests/ -x -q`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/test_hard_agent.py` -- covers BOTS-03 (unit + batch integration)
- [ ] `tests/test_simulation.py` -- covers BOTS-04 (simulation mode integration)
- [ ] No new framework install needed -- pytest already available

---

## Sources

### Primary (HIGH confidence)
- Project codebase: `risk/bots/medium.py`, `risk/game.py`, `risk/player.py`, `risk/engine/turn.py`, `risk/server/game_manager.py` -- direct code analysis of existing bot architecture and game loop
- Project codebase: `risk/engine/combat.py` -- exact dice mechanics for probability calculation
- Project codebase: `risk/engine/cards.py` -- escalation sequence [4, 6, 8, 10, 12, 15, +5...] for card timing strategy

### Secondary (MEDIUM confidence)
- [Cornell CS 473 - An Intelligent Agent for Risk](https://www.cs.cornell.edu/boom/2001sp/Choi/473repo.html) -- evaluation function design, threat assessment via "fake player", 60% probability threshold
- [Maastricht University BSc Thesis - Evaluating Heuristics in Risk](https://project.dke.maastrichtuniversity.nl/games/files/bsc/Hahn_Bsc-paper.pdf) -- Border Security Ratio (BSR), supply/attack/reinforce heuristic categories
- [Stanford CS 229 - A Risky Proposal](https://cs229.stanford.edu/proj2012/LozanoBratz-ARiskyProposalDesigningARiskGamePlayingAgent.pdf) -- heuristic vs ML approaches for Risk AI

### Tertiary (LOW confidence)
- [GitHub risk-bot](https://github.com/cathal-killeen/risk-bot) -- attack evaluation sorting by probability + continent value (community implementation, not peer-reviewed)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, builds entirely on existing architecture
- Architecture: HIGH -- HardAgent follows exact same protocol as MediumAgent; AI-vs-AI uses existing game loop
- Pitfalls: HIGH -- well-known Risk AI challenges documented in academic literature
- Batch testing: MEDIUM -- 55% win rate target is reasonable but exact threshold needs validation

**Research date:** 2026-03-10
**Valid until:** Indefinite (heuristic Risk strategy is stable domain)
