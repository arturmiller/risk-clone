"""Exhaustive validation tests for classic Risk map data."""

import pytest

from risk.models.map_schema import MapData


# ── Territory Tests ──────────────────────────────────────────────────────────


def test_territory_count(map_data: MapData):
    """Classic Risk has exactly 42 territories."""
    assert len(map_data.territories) == 42


def test_no_duplicate_territories(map_data: MapData):
    """All territory names are unique."""
    assert len(map_data.territories) == len(set(map_data.territories))


# ── Continent Tests ──────────────────────────────────────────────────────────


def test_continent_count(map_data: MapData):
    """Classic Risk has exactly 6 continents."""
    assert len(map_data.continents) == 6


def test_continent_bonuses(map_data: MapData):
    """Verify each continent's bonus matches classic Risk rules."""
    expected_bonuses = {
        "North America": 5,
        "South America": 2,
        "Europe": 5,
        "Africa": 3,
        "Asia": 7,
        "Australia": 2,
    }
    for continent in map_data.continents:
        assert continent.name in expected_bonuses, (
            f"Unexpected continent: {continent.name}"
        )
        assert continent.bonus == expected_bonuses[continent.name], (
            f"{continent.name} bonus should be {expected_bonuses[continent.name]}, "
            f"got {continent.bonus}"
        )


def test_continent_territory_coverage(map_data: MapData):
    """Every territory is in exactly one continent (no missing, no overlap)."""
    all_continent_territories: list[str] = []
    for continent in map_data.continents:
        all_continent_territories.extend(continent.territories)

    # No duplicates across continents
    assert len(all_continent_territories) == len(set(all_continent_territories)), (
        "Some territories appear in multiple continents"
    )

    # Covers all territories
    assert set(all_continent_territories) == set(map_data.territories), (
        "Continent territories don't match master territory list"
    )


def test_continent_territory_counts(map_data: MapData):
    """Verify territory count per continent."""
    expected_counts = {
        "North America": 9,
        "South America": 4,
        "Europe": 7,
        "Africa": 6,
        "Asia": 12,
        "Australia": 4,
    }
    for continent in map_data.continents:
        assert len(continent.territories) == expected_counts[continent.name], (
            f"{continent.name} should have {expected_counts[continent.name]} territories, "
            f"got {len(continent.territories)}"
        )


# ── Adjacency Tests ──────────────────────────────────────────────────────────


def _has_edge(map_data: MapData, t1: str, t2: str) -> bool:
    """Check if an edge exists in either direction."""
    for a, b in map_data.adjacencies:
        if (a == t1 and b == t2) or (a == t2 and b == t1):
            return True
    return False


def test_every_territory_has_neighbor(map_data: MapData):
    """Each territory appears in at least one adjacency edge."""
    territories_with_neighbors = set()
    for a, b in map_data.adjacencies:
        territories_with_neighbors.add(a)
        territories_with_neighbors.add(b)

    for territory in map_data.territories:
        assert territory in territories_with_neighbors, (
            f"Territory '{territory}' has no neighbors"
        )


def test_no_self_adjacency(map_data: MapData):
    """No edge connects a territory to itself."""
    for a, b in map_data.adjacencies:
        assert a != b, f"Self-adjacency found: {a}"


def test_specific_adjacencies_north_america(map_data: MapData):
    """Verify all North America internal edges."""
    edges = [
        ("Alaska", "Alberta"),
        ("Alaska", "Northwest Territory"),
        ("Alberta", "Northwest Territory"),
        ("Alberta", "Ontario"),
        ("Alberta", "Western United States"),
        ("Ontario", "Northwest Territory"),
        ("Ontario", "Quebec"),
        ("Ontario", "Eastern United States"),
        ("Ontario", "Western United States"),
        ("Ontario", "Greenland"),
        ("Quebec", "Eastern United States"),
        ("Quebec", "Greenland"),
        ("Greenland", "Northwest Territory"),
        ("Eastern United States", "Western United States"),
        ("Central America", "Eastern United States"),
        ("Central America", "Western United States"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_specific_adjacencies_south_america(map_data: MapData):
    """Verify all South America internal edges."""
    edges = [
        ("Venezuela", "Brazil"),
        ("Venezuela", "Peru"),
        ("Brazil", "Peru"),
        ("Brazil", "Argentina"),
        ("Argentina", "Peru"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_specific_adjacencies_europe(map_data: MapData):
    """Verify all Europe internal edges."""
    edges = [
        ("Iceland", "Scandinavia"),
        ("Iceland", "Great Britain"),
        ("Scandinavia", "Great Britain"),
        ("Scandinavia", "Northern Europe"),
        ("Scandinavia", "Ukraine"),
        ("Great Britain", "Northern Europe"),
        ("Great Britain", "Western Europe"),
        ("Northern Europe", "Southern Europe"),
        ("Northern Europe", "Ukraine"),
        ("Northern Europe", "Western Europe"),
        ("Southern Europe", "Ukraine"),
        ("Southern Europe", "Western Europe"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_specific_adjacencies_africa(map_data: MapData):
    """Verify all Africa internal edges."""
    edges = [
        ("North Africa", "Egypt"),
        ("North Africa", "East Africa"),
        ("North Africa", "Congo"),
        ("Egypt", "East Africa"),
        ("East Africa", "Congo"),
        ("East Africa", "South Africa"),
        ("East Africa", "Madagascar"),
        ("Congo", "South Africa"),
        ("Madagascar", "South Africa"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_specific_adjacencies_asia(map_data: MapData):
    """Verify all Asia internal edges."""
    edges = [
        ("Afghanistan", "China"),
        ("Afghanistan", "India"),
        ("Afghanistan", "Middle East"),
        ("Afghanistan", "Ural"),
        ("China", "India"),
        ("China", "Mongolia"),
        ("China", "Siam"),
        ("China", "Siberia"),
        ("China", "Ural"),
        ("India", "Middle East"),
        ("India", "Siam"),
        ("Irkutsk", "Kamchatka"),
        ("Irkutsk", "Mongolia"),
        ("Irkutsk", "Siberia"),
        ("Irkutsk", "Yakutsk"),
        ("Japan", "Kamchatka"),
        ("Japan", "Mongolia"),
        ("Kamchatka", "Mongolia"),
        ("Kamchatka", "Yakutsk"),
        ("Siberia", "Ural"),
        ("Siberia", "Yakutsk"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_specific_adjacencies_australia(map_data: MapData):
    """Verify all Australia internal edges."""
    edges = [
        ("Indonesia", "New Guinea"),
        ("Indonesia", "Western Australia"),
        ("New Guinea", "Eastern Australia"),
        ("New Guinea", "Western Australia"),
        ("Eastern Australia", "Western Australia"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_specific_adjacencies_cross_continent(map_data: MapData):
    """Verify all cross-continent edges."""
    edges = [
        ("Alaska", "Kamchatka"),
        ("Greenland", "Iceland"),
        ("Central America", "Venezuela"),
        ("Brazil", "North Africa"),
        ("North Africa", "Southern Europe"),
        ("North Africa", "Western Europe"),
        ("Egypt", "Southern Europe"),
        ("Egypt", "Middle East"),
        ("East Africa", "Middle East"),
        ("Southern Europe", "Middle East"),
        ("Ukraine", "Afghanistan"),
        ("Ukraine", "Middle East"),
        ("Ukraine", "Ural"),
        ("Siam", "Indonesia"),
    ]
    for t1, t2 in edges:
        assert _has_edge(map_data, t1, t2), f"Missing edge: {t1} - {t2}"


def test_cross_ocean_routes(map_data: MapData):
    """Dedicated test for the 6 cross-ocean/water connections."""
    cross_ocean = [
        ("Alaska", "Kamchatka"),
        ("Greenland", "Iceland"),
        ("Brazil", "North Africa"),
        ("East Africa", "Middle East"),
        ("Siam", "Indonesia"),
        ("Central America", "Venezuela"),
    ]
    for t1, t2 in cross_ocean:
        assert _has_edge(map_data, t1, t2), (
            f"Missing cross-ocean route: {t1} - {t2}"
        )


# ── Validation / Rejection Tests ────────────────────────────────────────────


def test_invalid_duplicate_territories():
    """MapData should reject duplicate territory names."""
    with pytest.raises(ValueError, match="[Dd]uplicate"):
        MapData.model_validate({
            "name": "Bad",
            "territories": ["A", "A", "B"],
            "continents": [{"name": "C1", "territories": ["A", "B"], "bonus": 1}],
            "adjacencies": [["A", "B"]],
        })


def test_invalid_unknown_territory_in_adjacency():
    """MapData should reject adjacencies referencing unknown territories."""
    with pytest.raises(ValueError, match="[Uu]nknown"):
        MapData.model_validate({
            "name": "Bad",
            "territories": ["A", "B"],
            "continents": [{"name": "C1", "territories": ["A", "B"], "bonus": 1}],
            "adjacencies": [["A", "C"]],
        })


def test_invalid_territory_missing_from_continents():
    """MapData should reject when a territory is not in any continent."""
    with pytest.raises(ValueError, match="[Cc]ontinent|[Mm]atch|[Mm]issing|[Cc]over"):
        MapData.model_validate({
            "name": "Bad",
            "territories": ["A", "B", "C"],
            "continents": [{"name": "C1", "territories": ["A", "B"], "bonus": 1}],
            "adjacencies": [["A", "B"]],
        })


def test_invalid_territory_in_multiple_continents():
    """MapData should reject when a territory appears in multiple continents."""
    with pytest.raises(ValueError, match="[Dd]uplicate|[Mm]ultiple|[Oo]verlap|[Cc]ontinent|[Mm]atch"):
        MapData.model_validate({
            "name": "Bad",
            "territories": ["A", "B"],
            "continents": [
                {"name": "C1", "territories": ["A", "B"], "bonus": 1},
                {"name": "C2", "territories": ["A"], "bonus": 2},
            ],
            "adjacencies": [["A", "B"]],
        })
