from __future__ import annotations

import csv
from pathlib import Path


def test_sample_ingredients_fixture_parses() -> None:
    fixture = Path("data/sample/ingredients.csv")
    assert fixture.exists(), "Expected sample ingredients fixture"

    with fixture.open(encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    assert rows, "Fixture should contain at least one ingredient"
    for row in rows:
        assert row.get("ingredient"), "Every fixture row must have an ingredient"
        assert row.get("unit_cost") not in (None, ""), "Every row needs a unit_cost"
        # Ensure unit_cost looks numeric without casting (keeps test non-destructive)
        assert set(row["unit_cost"]) <= set("0123456789."), "unit_cost should be numeric"
