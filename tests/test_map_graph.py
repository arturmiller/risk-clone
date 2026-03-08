"""Tests for the NetworkX graph wrapper (MapGraph)."""

from risk.engine.map_graph import MapGraph


# ── Graph Construction Tests ─────────────────────────────────────────────────


def test_graph_node_count(map_graph: MapGraph):
    """Graph should have exactly 42 nodes."""
    assert len(map_graph.all_territories) == 42


# ── Adjacency Tests ──────────────────────────────────────────────────────────


def test_adjacency_bidirectional(map_graph: MapGraph):
    """Adjacency should work in both directions."""
    pairs = [
        ("Alaska", "Kamchatka"),
        ("Brazil", "North Africa"),
        ("Siam", "Indonesia"),
        ("Ontario", "Quebec"),
    ]
    for t1, t2 in pairs:
        assert map_graph.are_adjacent(t1, t2), f"{t1} -> {t2} should be adjacent"
        assert map_graph.are_adjacent(t2, t1), f"{t2} -> {t1} should be adjacent"


def test_non_adjacent_territories(map_graph: MapGraph):
    """Known non-adjacent pairs should return False."""
    pairs = [
        ("Alaska", "Brazil"),
        ("Japan", "Argentina"),
        ("Iceland", "Madagascar"),
        ("Western Australia", "Greenland"),
    ]
    for t1, t2 in pairs:
        assert not map_graph.are_adjacent(t1, t2), (
            f"{t1} and {t2} should not be adjacent"
        )


# ── Neighbor Tests ───────────────────────────────────────────────────────────


def test_neighbors_alaska(map_graph: MapGraph):
    """Alaska should have exactly 3 neighbors."""
    neighbors = set(map_graph.neighbors("Alaska"))
    expected = {"Northwest Territory", "Alberta", "Kamchatka"}
    assert neighbors == expected


def test_neighbors_count_spot_check(map_graph: MapGraph):
    """Spot check neighbor counts for several territories."""
    expected_counts = {
        "Alaska": 3,
        "Ukraine": 6,  # Scandinavia, Northern Europe, Southern Europe, Middle East, Afghanistan, Ural
        "Argentina": 2,  # Brazil, Peru
        "Eastern Australia": 2,  # New Guinea, Western Australia
    }
    for territory, expected_count in expected_counts.items():
        actual = len(map_graph.neighbors(territory))
        assert actual == expected_count, (
            f"{territory}: expected {expected_count} neighbors, got {actual}"
        )


# ── Connected Territory Tests ────────────────────────────────────────────────


def test_connected_territories_simple(map_graph: MapGraph):
    """Small friendly set should return connected component."""
    # Alaska, Alberta, Northwest Territory are all adjacent
    friendly = {"Alaska", "Alberta", "Northwest Territory"}
    result = map_graph.connected_territories("Alaska", friendly)
    assert result == friendly


def test_connected_territories_isolated(map_graph: MapGraph):
    """Start territory with no friendly neighbors returns only itself."""
    friendly = {"Alaska", "Brazil"}  # Not adjacent to each other
    result = map_graph.connected_territories("Alaska", friendly)
    assert result == {"Alaska"}


def test_connected_territories_full_continent(map_graph: MapGraph):
    """All of South America owned -> all 4 reachable from any."""
    sa_territories = {"Venezuela", "Peru", "Brazil", "Argentina"}
    for start in sa_territories:
        result = map_graph.connected_territories(start, sa_territories)
        assert result == sa_territories, (
            f"From {start}, expected all SA territories reachable"
        )


# ── Continent Tests ──────────────────────────────────────────────────────────


def test_continent_territories(map_graph: MapGraph):
    """Verify each continent returns its correct territory set."""
    expected = {
        "North America": {
            "Alaska", "Northwest Territory", "Greenland", "Alberta",
            "Ontario", "Quebec", "Western United States",
            "Eastern United States", "Central America",
        },
        "South America": {"Venezuela", "Peru", "Brazil", "Argentina"},
        "Europe": {
            "Iceland", "Scandinavia", "Ukraine", "Great Britain",
            "Northern Europe", "Southern Europe", "Western Europe",
        },
        "Africa": {
            "North Africa", "Egypt", "East Africa", "Congo",
            "South Africa", "Madagascar",
        },
        "Asia": {
            "Siam", "India", "China", "Mongolia", "Japan",
            "Irkutsk", "Yakutsk", "Kamchatka", "Siberia",
            "Afghanistan", "Ural", "Middle East",
        },
        "Australia": {
            "Indonesia", "New Guinea", "Western Australia",
            "Eastern Australia",
        },
    }
    for continent_name, territories in expected.items():
        result = map_graph.continent_territories(continent_name)
        assert result == territories, (
            f"{continent_name}: expected {territories}, got {result}"
        )


def test_controls_continent(map_graph: MapGraph):
    """Player controls continent when owning all its territories."""
    australia = {
        "Indonesia", "New Guinea", "Western Australia", "Eastern Australia"
    }
    assert map_graph.controls_continent("Australia", australia)


def test_does_not_control_continent_missing_one(map_graph: MapGraph):
    """Player does not control continent if missing one territory."""
    almost_australia = {
        "Indonesia", "New Guinea", "Western Australia"
    }
    assert not map_graph.controls_continent("Australia", almost_australia)


def test_continent_bonus(map_graph: MapGraph):
    """Verify bonus values via MapGraph."""
    expected = {
        "North America": 5,
        "South America": 2,
        "Europe": 5,
        "Africa": 3,
        "Asia": 7,
        "Australia": 2,
    }
    for continent, bonus in expected.items():
        assert map_graph.continent_bonus(continent) == bonus
