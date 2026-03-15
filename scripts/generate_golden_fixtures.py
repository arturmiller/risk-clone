"""Generate golden fixture JSON files from the Python Risk engine.

Run from repo root:
    python scripts/generate_golden_fixtures.py

Writes JSON fixtures to mobile/test/engine/fixtures/.
"""

import json
import os
import sys
from pathlib import Path

# Ensure repo root is on path
sys.path.insert(0, str(Path(__file__).parent.parent))

from risk.engine.combat import (
    resolve_combat,
    execute_attack,
    execute_blitz,
)
from risk.engine.reinforcements import calculate_reinforcements
from risk.engine.fortify import execute_fortify, validate_fortify
from risk.engine.map_graph import MapGraph, load_map
from risk.models.actions import AttackAction, BlitzAction, FortifyAction
from risk.models.game_state import GameState, TerritoryState, PlayerState
from risk.models.cards import TurnPhase


FIXTURES_DIR = Path(__file__).parent.parent / "mobile" / "test" / "engine" / "fixtures"
MAP_PATH = Path(__file__).parent.parent / "risk" / "data" / "classic.json"

# TurnPhase numeric -> Dart string mapping
TURN_PHASE_TO_DART = {
    TurnPhase.REINFORCE: "reinforce",
    TurnPhase.ATTACK: "attack",
    TurnPhase.FORTIFY: "fortify",
}


class FakeRandom:
    """Deterministic RNG: returns specified values in sequence."""

    def __init__(self, values: list[int]) -> None:
        self._values = list(values)
        self._index = 0

    def randint(self, a: int, b: int) -> int:
        v = self._values[self._index]
        self._index += 1
        return v

    def shuffle(self, lst: list) -> None:
        pass  # no-op for deterministic fixtures

    def choice(self, lst: list):
        return lst[0]  # deterministic


def write_fixture(filename: str, data: object) -> None:
    FIXTURES_DIR.mkdir(parents=True, exist_ok=True)
    path = FIXTURES_DIR / filename
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"  Wrote: {path}")


def state_to_dart_json(state: GameState) -> dict:
    """Serialize GameState to Dart-compatible JSON format (camelCase keys, string enums)."""
    territories = {}
    for name, ts in state.territories.items():
        territories[name] = {"owner": ts.owner, "armies": ts.armies}

    players = [
        {"index": p.index, "name": p.name, "isAlive": p.is_alive}
        for p in state.players
    ]

    return {
        "territories": territories,
        "players": players,
        "currentPlayerIndex": state.current_player_index,
        "turnNumber": state.turn_number,
        "turnPhase": TURN_PHASE_TO_DART[state.turn_phase],
        "tradeCount": state.trade_count,
        "cards": {},
        "deck": [],
        "conqueredThisTurn": state.conquered_this_turn,
    }


def make_game_state(territories: dict[str, tuple[int, int]], player_count: int = 2) -> GameState:
    """Build a GameState from a dict of {territory_name: (owner, armies)}."""
    t_states = {name: TerritoryState(owner=owner, armies=armies)
                for name, (owner, armies) in territories.items()}
    players = [PlayerState(index=i, name=f"P{i}") for i in range(player_count)]
    return GameState(territories=t_states, players=players)


def generate_combat_fixtures(map_graph: MapGraph) -> None:
    print("Generating golden_combat.json...")
    fixtures = []

    # Fixture 1: 3v2 attacker wins both — [6,5,4] vs [3,2]
    # Alaska (owner=0, 5 armies) attacks Alberta (owner=1, 3 armies)
    territories = {t: (1, 2) for t in map_graph.all_territories}
    territories["Alaska"] = (0, 5)
    territories["Alberta"] = (1, 3)
    state = make_game_state(territories)
    rng = FakeRandom([6, 5, 4, 3, 2])
    action = AttackAction(source="Alaska", target="Alberta", num_dice=3)
    new_state, result, conquered = execute_attack(state, map_graph, action, 0, rng)
    fixtures.append({
        "id": "combat_3v2_attacker_wins_both",
        "description": "Attacker rolls [6,5,4], defender rolls [3,2]",
        "injected_rolls": [6, 5, 4, 3, 2],
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Alberta", "num_dice": 3},
        "expected_attacker_losses": result.attacker_losses,
        "expected_defender_losses": result.defender_losses,
        "expected_conquered": conquered,
        "output_state": state_to_dart_json(new_state),
    })

    # Fixture 2: 3v2 split — [5,4] vs [6,3] → attacker loses 1, defender loses 1
    territories = {t: (1, 2) for t in map_graph.all_territories}
    territories["Alaska"] = (0, 5)
    territories["Alberta"] = (1, 3)
    state = make_game_state(territories)
    rng = FakeRandom([5, 4, 6, 3])
    action = AttackAction(source="Alaska", target="Alberta", num_dice=2)
    new_state, result, conquered = execute_attack(state, map_graph, action, 0, rng)
    fixtures.append({
        "id": "combat_3v2_split",
        "description": "Attacker rolls [5,4], defender rolls [6,3] — split result",
        "injected_rolls": [5, 4, 6, 3],
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Alberta", "num_dice": 2},
        "expected_attacker_losses": result.attacker_losses,
        "expected_defender_losses": result.defender_losses,
        "expected_conquered": conquered,
        "output_state": state_to_dart_json(new_state),
    })

    # Fixture 3: 1v1 attacker wins — [6] vs [5]
    territories = {t: (1, 2) for t in map_graph.all_territories}
    territories["Alaska"] = (0, 3)
    territories["Alberta"] = (1, 1)
    state = make_game_state(territories)
    rng = FakeRandom([6, 5])
    action = AttackAction(source="Alaska", target="Alberta", num_dice=1)
    new_state, result, conquered = execute_attack(state, map_graph, action, 0, rng, defender_dice=1)
    fixtures.append({
        "id": "combat_1v1_attacker_wins",
        "description": "1v1: attacker [6] vs defender [5] → attacker wins",
        "injected_rolls": [6, 5],
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Alberta", "num_dice": 1},
        "expected_attacker_losses": result.attacker_losses,
        "expected_defender_losses": result.defender_losses,
        "expected_conquered": conquered,
        "output_state": state_to_dart_json(new_state),
    })

    # Fixture 4: 1v1 tie goes to defender — [4] vs [4]
    territories = {t: (1, 2) for t in map_graph.all_territories}
    territories["Alaska"] = (0, 3)
    territories["Alberta"] = (1, 2)
    state = make_game_state(territories)
    rng = FakeRandom([4, 4])
    action = AttackAction(source="Alaska", target="Alberta", num_dice=1)
    new_state, result, conquered = execute_attack(state, map_graph, action, 0, rng, defender_dice=1)
    fixtures.append({
        "id": "combat_1v1_tie_defender_wins",
        "description": "1v1 tie: [4] vs [4] → defender wins (tie goes to defender)",
        "injected_rolls": [4, 4],
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Alberta", "num_dice": 1},
        "expected_attacker_losses": result.attacker_losses,
        "expected_defender_losses": result.defender_losses,
        "expected_conquered": conquered,
        "output_state": state_to_dart_json(new_state),
    })

    # Fixture 5: Blitz conquest — pre-loaded dice ensure attacker wins
    territories = {t: (1, 2) for t in map_graph.all_territories}
    territories["Alaska"] = (0, 6)
    territories["Alberta"] = (1, 2)
    state = make_game_state(territories)
    # 3v2: [6,5,4] vs [3,2] → defender loses 2 → conquered in 1 round
    rng = FakeRandom([6, 5, 4, 3, 2])
    blitz_action = BlitzAction(source="Alaska", target="Alberta")
    new_state, all_results, conquered = execute_blitz(state, map_graph, blitz_action, 0, rng)
    fixtures.append({
        "id": "combat_blitz_conquest",
        "description": "Blitz Alaska→Alberta with [6,5,4] vs [3,2] — one-round conquest",
        "injected_rolls": [6, 5, 4, 3, 2],
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Alberta"},
        "expected_conquered": conquered,
        "combat_rounds": len(all_results),
        "output_state": state_to_dart_json(new_state),
    })

    write_fixture("golden_combat.json", fixtures)


def generate_reinforcements_fixtures(map_graph: MapGraph) -> None:
    print("Generating golden_reinforcements.json...")
    fixtures = []

    all_terr = map_graph.all_territories

    # Fixture 1: 9 territories → base 3 (minimum enforced)
    player0_terr = all_terr[:9]
    player1_terr = all_terr[9:]
    territories = {}
    for t in player0_terr:
        territories[t] = (0, 3)
    for t in player1_terr:
        territories[t] = (1, 2)
    state = make_game_state(territories)
    result = calculate_reinforcements(state, map_graph, 0)
    fixtures.append({
        "id": "reinf_9_territories_minimum",
        "description": "9 territories → base = max(9//3, 3) = 3 (at minimum threshold)",
        "player_index": 0,
        "territory_count": len(player0_terr),
        "continents_controlled": [],
        "expected_reinforcements": result,
        "input_state": state_to_dart_json(state),
    })

    # Fixture 2: 12 territories → base 4
    player0_terr = all_terr[:12]
    player1_terr = all_terr[12:]
    territories = {}
    for t in player0_terr:
        territories[t] = (0, 3)
    for t in player1_terr:
        territories[t] = (1, 2)
    state = make_game_state(territories)
    result = calculate_reinforcements(state, map_graph, 0)
    fixtures.append({
        "id": "reinf_12_territories_base4",
        "description": "12 territories → base = max(12//3, 3) = 4",
        "player_index": 0,
        "territory_count": len(player0_terr),
        "expected_reinforcements": result,
        "input_state": state_to_dart_json(state),
    })

    # Fixture 3: continent bonus — player 0 owns all of Australia (4 territories, bonus 2)
    australia_terr = ["Indonesia", "New Guinea", "Western Australia", "Eastern Australia"]
    other_player0_terr = all_terr[:5]  # a few extra
    territories = {}
    for t in all_terr:
        territories[t] = (1, 2)
    for t in australia_terr:
        territories[t] = (0, 3)
    for t in other_player0_terr:
        territories[t] = (0, 3)
    state = make_game_state(territories)
    total_p0 = len(set(australia_terr) | set(other_player0_terr))
    result = calculate_reinforcements(state, map_graph, 0)
    fixtures.append({
        "id": "reinf_australia_continent_bonus",
        "description": f"Player 0 owns Australia (bonus 2) + {len(other_player0_terr)} other territories",
        "player_index": 0,
        "territory_count": total_p0,
        "continents_controlled": ["Australia"],
        "expected_reinforcements": result,
        "input_state": state_to_dart_json(state),
    })

    write_fixture("golden_reinforcements.json", fixtures)


def generate_fortify_fixtures(map_graph: MapGraph) -> None:
    print("Generating golden_fortify.json...")
    fixtures = []

    all_terr = map_graph.all_territories

    # Fixture 1: valid fortify move — Alaska → Alberta (connected via NWT)
    territories = {t: (1, 2) for t in all_terr}
    territories["Alaska"] = (0, 5)
    territories["Alberta"] = (0, 3)
    # Make Northwest Territory owned by player 0 so path exists (Alaska-NWT-Alberta)
    territories["Northwest Territory"] = (0, 2)
    state = make_game_state(territories)
    action = FortifyAction(source="Alaska", target="Alberta", armies=3)
    new_state = execute_fortify(state, map_graph, action, 0)
    fixtures.append({
        "id": "fortify_valid_move",
        "description": "Alaska (5 armies) → Alberta (3 armies), move 3 armies via connected path",
        "player_index": 0,
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Alberta", "armies": 3},
        "output_state": state_to_dart_json(new_state),
        "expected_source_armies": new_state.territories["Alaska"].armies,
        "expected_target_armies": new_state.territories["Alberta"].armies,
    })

    # Fixture 2: validate path — disconnected territories should raise ValueError
    territories = {t: (1, 2) for t in all_terr}
    territories["Alaska"] = (0, 5)
    territories["Eastern Australia"] = (0, 3)
    # No path: Alaska and Eastern Australia owned by player 0 but disconnected
    state = make_game_state(territories)
    action = FortifyAction(source="Alaska", target="Eastern Australia", armies=2)
    try:
        validate_fortify(state, map_graph, action, 0)
        path_validation_raises = False
        path_validation_error = ""
    except ValueError as e:
        path_validation_raises = True
        path_validation_error = str(e)
    fixtures.append({
        "id": "fortify_disconnected_path_raises",
        "description": "Alaska → Eastern Australia disconnected — should raise ValueError",
        "player_index": 0,
        "input_state": state_to_dart_json(state),
        "action": {"source": "Alaska", "target": "Eastern Australia", "armies": 2},
        "expected_raises": path_validation_raises,
        "expected_error_contains": "reachable",
    })

    write_fixture("golden_fortify.json", fixtures)


def generate_turn_sequence_fixtures(map_graph: MapGraph) -> None:
    """Generate turn FSM fixtures — wrapped in try/except since turn.py may have import issues."""
    print("Generating golden_turn_sequence.json...")
    try:
        from risk.engine.turn import check_victory, check_elimination
        from risk.models.game_state import GameState, TerritoryState, PlayerState

        fixtures = []
        all_terr = map_graph.all_territories

        # Fixture 1: check_victory — single owner
        territories = {t: (0, 2) for t in all_terr}
        state = make_game_state(territories, player_count=2)
        winner = check_victory(state)
        fixtures.append({
            "id": "turn_check_victory_single_owner",
            "description": "All territories owned by player 0 → victory detected",
            "expected_winner": winner,
            "output": winner,
        })

        # Fixture 2: check_victory — multiple owners, no winner
        territories = {t: (0, 2) for t in all_terr[:21]}
        territories.update({t: (1, 2) for t in all_terr[21:]})
        state = make_game_state(territories, player_count=2)
        winner = check_victory(state)
        fixtures.append({
            "id": "turn_check_victory_multiple_owners",
            "description": "Territories split between p0 and p1 → no winner (None)",
            "expected_winner": winner,
            "output": winner,
        })

        # Fixture 3: check_elimination
        territories = {t: (1, 2) for t in all_terr}
        state = make_game_state(territories, player_count=2)
        eliminated = check_elimination(state, 0)
        fixtures.append({
            "id": "turn_check_elimination_no_territories",
            "description": "Player 0 owns 0 territories → eliminated",
            "player_index": 0,
            "expected_eliminated": eliminated,
            "output": eliminated,
        })

        write_fixture("golden_turn_sequence.json", fixtures)
    except Exception as e:
        print(f"  WARNING: turn_sequence fixtures skipped — {e}")


def main() -> None:
    print(f"Loading map from {MAP_PATH}...")
    map_data = load_map(MAP_PATH)
    map_graph = MapGraph(map_data)
    print(f"Map loaded: {len(map_graph.all_territories)} territories")

    FIXTURES_DIR.mkdir(parents=True, exist_ok=True)

    generate_combat_fixtures(map_graph)
    generate_reinforcements_fixtures(map_graph)
    generate_fortify_fixtures(map_graph)
    generate_turn_sequence_fixtures(map_graph)

    print("\nDone. Fixtures written to:", FIXTURES_DIR)
    fixture_files = list(FIXTURES_DIR.glob("*.json"))
    print(f"  {len(fixture_files)} fixture files:")
    for f in sorted(fixture_files):
        print(f"    {f.name}")


if __name__ == "__main__":
    main()
