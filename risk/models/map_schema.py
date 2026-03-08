"""Pydantic models for Risk map JSON validation."""

from pydantic import BaseModel, field_validator, model_validator


class ContinentData(BaseModel):
    """A continent with its territories and bonus armies."""

    name: str
    territories: list[str]
    bonus: int


class MapData(BaseModel):
    """Complete map data: territories, continents, and adjacencies."""

    name: str
    territories: list[str]
    continents: list[ContinentData]
    adjacencies: list[tuple[str, str]]

    @field_validator("territories")
    @classmethod
    def validate_no_duplicate_territories(cls, v: list[str]) -> list[str]:
        if len(v) != len(set(v)):
            dupes = [t for t in v if v.count(t) > 1]
            raise ValueError(f"Duplicate territory names found: {set(dupes)}")
        return v

    @field_validator("adjacencies")
    @classmethod
    def validate_adjacency_endpoints(
        cls, v: list[tuple[str, str]], info
    ) -> list[tuple[str, str]]:
        territories = set(info.data.get("territories", []))
        for a, b in v:
            if a not in territories or b not in territories:
                raise ValueError(
                    f"Adjacency references unknown territory: {a}-{b}"
                )
            if a == b:
                raise ValueError(f"Self-adjacency not allowed: {a}")
        # Check for duplicate edges
        seen: set[tuple[str, str]] = set()
        for a, b in v:
            edge = (min(a, b), max(a, b))
            if edge in seen:
                raise ValueError(f"Duplicate adjacency edge: {a}-{b}")
            seen.add(edge)
        return v

    @model_validator(mode="after")
    def validate_continent_coverage(self) -> "MapData":
        """Verify that continent territory lists exactly cover the master list."""
        all_continent_territories: list[str] = []
        for continent in self.continents:
            all_continent_territories.extend(continent.territories)

        continent_set = set(all_continent_territories)
        territory_set = set(self.territories)

        # Check for duplicates across continents
        if len(all_continent_territories) != len(continent_set):
            raise ValueError(
                "Duplicate territories across continents: some territory "
                "appears in multiple continents"
            )

        # Check coverage matches
        if continent_set != territory_set:
            missing = territory_set - continent_set
            extra = continent_set - territory_set
            parts = []
            if missing:
                parts.append(f"Missing from continents: {missing}")
            if extra:
                parts.append(f"Extra in continents: {extra}")
            raise ValueError(
                f"Continent territories don't match master list. {'; '.join(parts)}"
            )

        return self
