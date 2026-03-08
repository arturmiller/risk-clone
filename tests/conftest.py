"""Shared test fixtures for Risk game tests."""

import json
from pathlib import Path

import pytest

from risk.models.map_schema import MapData
from risk.engine.map_graph import MapGraph


DATA_DIR = Path(__file__).resolve().parent.parent / "risk" / "data"


@pytest.fixture
def map_data() -> MapData:
    """Load and validate the classic Risk map data."""
    classic_path = DATA_DIR / "classic.json"
    with open(classic_path) as f:
        raw = json.load(f)
    return MapData.model_validate(raw)


@pytest.fixture
def map_graph(map_data: MapData) -> MapGraph:
    """Build a MapGraph from the classic Risk map data."""
    return MapGraph(map_data)
