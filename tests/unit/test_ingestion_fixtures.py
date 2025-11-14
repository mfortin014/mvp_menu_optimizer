from __future__ import annotations

import json
from pathlib import Path


def test_ingestion_fixture_contains_required_fields() -> None:
    fixture = json.loads(
        Path("data/fixtures/ingestion_staging_sample.json").read_text(encoding="utf-8")
    )
    tables = (
        "stg_component",
        "stg_bom_header",
        "stg_product",
        "stg_bom_line",
        "stg_party",
        "stg_uom_conversion",
    )
    required_fields = (
        "job_id",
        "job_file_id",
        "tenant_id",
        "source_row_id",
        "row_checksum",
        "payload",
        "provenance",
        "validation_errors",
    )
    for table in tables:
        rows = fixture.get(table)
        assert rows, f"{table} missing rows"
        for row in rows:
            for field in required_fields:
                assert field in row, f"{table} row missing {field}"
            assert isinstance(row["payload"], dict)
            assert isinstance(row["provenance"], dict)
            assert isinstance(row["validation_errors"], list)
