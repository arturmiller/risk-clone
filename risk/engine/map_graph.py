"""NetworkX graph wrapper for Risk map with game-specific queries."""

import json
from pathlib import Path

import networkx as nx

from risk.models.map_schema import MapData


def load_map(map_path: Path) -> MapData:
    """Load and validate a map JSON file."""
    with open(map_path) as f:
        raw = json.load(f)
    return MapData.model_validate(raw)


class MapGraph:
    """Thin wrapper around NetworkX Graph for Risk territory queries."""

    def __init__(self, map_data: MapData) -> None:
        self.graph = nx.Graph()
        self.graph.add_nodes_from(map_data.territories)
        self.graph.add_edges_from(map_data.adjacencies)

        # Build continent lookups
        self._continent_map: dict[str, str] = {}
        self._continent_territories: dict[str, set[str]] = {}
        self._continent_bonuses: dict[str, int] = {}

        for continent in map_data.continents:
            self._continent_territories[continent.name] = set(continent.territories)
            self._continent_bonuses[continent.name] = continent.bonus
            for territory in continent.territories:
                self._continent_map[territory] = continent.name
                self.graph.nodes[territory]["continent"] = continent.name

    @property
    def all_territories(self) -> list[str]:
        """All territory names in the map."""
        return list(self.graph.nodes)

    def are_adjacent(self, t1: str, t2: str) -> bool:
        """Check if two territories share a border."""
        return self.graph.has_edge(t1, t2)

    def neighbors(self, territory: str) -> list[str]:
        """Get all territories adjacent to the given territory."""
        return list(self.graph.neighbors(territory))

    def connected_territories(
        self, start: str, friendly_territories: set[str]
    ) -> set[str]:
        """Find all territories reachable from start through friendly-only chain.

        Uses BFS on the subgraph of friendly territories.
        """
        if start not in friendly_territories:
            return set()
        subgraph = self.graph.subgraph(friendly_territories)
        return set(nx.node_connected_component(subgraph, start))

    def continent_territories(self, continent: str) -> set[str]:
        """Get all territories belonging to a continent."""
        return self._continent_territories[continent]

    def controls_continent(
        self, continent: str, player_territories: set[str]
    ) -> bool:
        """Check if player_territories contains all territories in a continent."""
        return self._continent_territories[continent].issubset(player_territories)

    def continent_bonus(self, continent: str) -> int:
        """Get the army bonus for controlling a continent."""
        return self._continent_bonuses[continent]
