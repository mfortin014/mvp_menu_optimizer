Purpose

Upload periodic flat-file reports (price lists, inventory, sales, vendor quotes, “weekly BOM cost export”), and instantly:

turn them into a time series,

compare any two snapshots side-by-side,

highlight what changed (adds/removes/edits) with numeric deltas.

Core concepts

Snapshot Inbox
report_dataset(id, name, entity_type, key_hint) and report_snapshot(dataset_id, snapshot_id, snapshot_ts, file_id, parsed_schema).

Key Inference
Heuristics to find stable keys (single column or composite). If none, use the Alias Map or prompt the user to pick fields. Keys are stored per dataset.

Row Store (normalized)
report_row(snapshot_id, key, cols jsonb, metrics jsonb) with typed columns; retain raw for replays.

Diff Engine
Given two snapshots → classify rows (added/removed/changed); compute deltas for numeric fields (abs/%), text changes (levenshtein), UOM-aware changes (using the same converter).

Time-Series Builder
For any metric column, build per-key series across snapshots (even if columns evolve slightly). Supports totals and grouped aggregations.

UI

Timeline view: pick metric(s), filter/facet, see trend lines and anomalies.

Side-by-side compare: frozen panes; changed cells highlighted; per-row and per-column deltas; export CSV/PDF.

Saved views: “Weekly vendor price changes”, “Inventory variance by site”, “BOM cost drift”.

Alerts (later)
Threshold rules (“flag when >5% cost jump on essentials”), emailed diff extracts.

Why this lands fast

Zero integration: just drop reports.

Works before warehouses or ERPs are connected.

Bridges to the engine: once keys line up with canonical IDs, these time series join directly to components/recipes/SKUs.

How the pieces fit (platform view)

Ingestion Module brings files in → Identity & Dedupe unifies rows → Alias Map links sources to canonicals → Engine (COPPER) powers costing, versions, where-used → Snapshot/Diff visualizes drift and change over time with almost no setup.

Skins (Menu Optimizer / PLM) reuse all of it: same engine, same dedupe, same snapshot module; only labels and presets differ.

Guardrails & best practices

Explainability first: every match score shows its parts (name 0.82, size 0.90, UOM OK). Trust beats black-box magic.

Incremental & idempotent: re-uploads dedupe cleanly via checksums and source IDs.

Survivorship policies: configurable per field/entity (freshest, most trusted source, prefer vendor X).

Performance: precomputed signatures, GIN indexes on tokens, batched blocking; long jobs offloaded to a queue.

Security: tenant-scoped storage buckets; immutable raw files; full audit for merges/splits and snapshot diffs.

i18n: FR/EN labels and search baked in (same i18n tables); exports in FR, EN, or bilingual.

What to ship first (thin slice)

Universal Dedupe v1: CSV/Excel/Sheets; normalizers for text/UOM/size; heuristic matching + clusters; Workbench; alias map; publish to canonical.

Snapshot & Diff v1: dataset registry, key inference, two-snapshot compare, basic time series, CSV/PDF export.

Join the dots: optional step that uses alias map so snapshot keys resolve to canonical components/SKUs for richer charts.

Nail these, and you’ve solved the two problems even “$1M/week” projects stumble on: identity resolution and change visibility—with a user experience humans can actually drive.