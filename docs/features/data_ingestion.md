getting ingestion right is what turns a neat app into a platform. Here’s a clean, industry-agnostic design for a Data Ingestion Module that serves the Menu Optimizer first and grows into PLM.

Objectives

Self-serve for non-tech users, power tools for data-savvy users.

Safe by default: tenant-isolated, idempotent, recoverable.

Works across skins (Restaurant/PLM), languages (EN/FR), and your core engine (COPPER).

Personas & Entry Points

Wizard (Self-Serve): CSV/Excel upload → auto-detect → map → validate → load.

Workbench (Pro): saved mappings, transform rules, test runs, dependency graph, diffs.

Admin Monitor: job history, row-level errors, replays, metrics.

Pipeline (end-to-end, ELT style)

Discover

Sniff headers, types, encodings; profile nulls, uniques, ranges.

Suggest target domain (Ingredients/Components, Variants, Assemblies/Recipes, BOM/Lines, Parties, UOMs, Conversions).

Map

Column mapping UI with presets per skin (“Restaurant CSV”, “Manufacturing BOM”).

Dictionaries for UOM aliases (“kg”, “kgs”, “kilogram”) and identifier types (supplier_sku, client_code).

Multilingual fields supported via suffixes: name_en, name_fr, or a separate translations sheet.

Transform

No-code transforms: split, merge, trim, regex extract, unit parsing (e.g., “12x1 L” → qty 12, pkg 1 L).

Controlled “advanced” expressions (sandboxed) for power users (e.g., price_per_unit = price / net_qty_g).

Built-ins: currency normalization, UOM normalization, density lookups, date parsing.

Validate

Schema: required columns, types, enums.

Business:

UOM convertibility (mass↔volume via item/variant mapping or global map).

Cycle detection in assemblies/recipes.

Variant ties to a valid ingredient/component.

Identifier uniqueness per party/type.

SCD policies (per entity): Update in place, Type-2 version, or Reject.

Simulate (Dry Run)

Show write plan: inserts/updates, SCD closures/openings, conflicts.

Cost deltas preview (what this load changes in totals/margins).

Where-Used blast radius (which recipes/assemblies will be affected).

Load

Into staging tables first (idempotent with source_id + checksum).

Merge to core via stored procedures honoring tenant RLS, SCD rules, and code auto-generation.

Partial success allowed; invalid rows quarantined.

Reconcile

Summary: rows ingested, rejected, updated, versioned.

Downloadable errors.csv with reasons and fix hints.

Job artifact links (original file, mapping config, validation report).

Staging & Config (data contracts, not code)

Ingest Job: metadata (tenant, user, file, preset, started/ended, status).

Staging tables per domain (stg_component, stg_variant, stg_bom_line, …) with raw columns + a payload jsonb.

Mapping Config (versioned): source→target column rules, transforms, defaults, SCD policy, conflict policy (create/link/skip).

Idempotency: (tenant_id, source_system, source_row_id) + row_hash prevent dupes.

Identity & Matching

Business keys: prefer external identifiers (supplier_sku+party, client_code) then internal codes; configurable priority.

Fuzzy matching (opt-in): for names when identifiers missing; review queue required.

Create-or-link strategy knobs per import (strict link vs. create missing refs).

Units, Conversions, and Cost Normalization

Normalize incoming UOM strings via alias dictionaries; map to ref_uom.

If cross-dimension conversion needed and missing (e.g., ml↔g), route to item/variant conversion creation workflow (or block if strict).

Price normalization: derive unit_cost in base unit (g/ml/unit); keep raw package price/size for traceability.

Currency: capture currency and (optionally) convert with a daily rate table; store raw and normalized values.

SCD & Versioning Behavior

Entity-level defaults (overridable per job):

Ingredients/Components, Variants → SCD2 for economic fields; close previous version; open new.

Assemblies/Recipes → either update draft or fork new version if marked “live”.

Conversions & Yields → replace current if is_current, retire old with valid_to.

Snapshots: if a load affects an active recipe/assembly, queue a recompute snapshot or require manual re-activation (configurable).

Multilingual (ties to i18n design)

Accept name_en, name_fr, description_en, description_fr.

Wizard shows completion status per row (“FR missing”).

On load: write to i18n_text for entity/field/lang.

Exports honor tenant default language or bilingual as chosen.

Error Handling & UX

Soft failures (non-blocking): unmapped optional columns, extra columns → warnings.

Hard failures: missing required fields, non-convertible UOM, cycles → block row; continue rest.

Explainability: validation messages cite the rule and the fix (“Add an item-specific ml↔g conversion for ‘Aioli, House’ or change line UOM”).

Replay: re-run failed rows after fixing mapping without re-uploading the file.

Security, RLS, and Audit

All staging and jobs carry tenant_id; RLS mirrors core.

Store artifacts (original files, reports) in tenant-scoped storage buckets.

Audit trail: who mapped what, which SCD changes were created, before/after hashes.

Presets & Templates (reduce friction)

Restaurant presets: Ingredients, Variants, Recipes, Recipe Lines, UOM Conversions, Parties/Identifiers.

Manufacturing presets: Components, Component Variants, Assemblies, BOM Lines, Parties/Identifiers.

Each preset ships with example CSVs and saved mapping configs; one-click import for demos.

Minimal Scope for Menu Optimizer (first cut)

CSV upload for: Ingredients, Variants (with costs), Prep Recipes, Recipe Lines, Parties/Identifiers, UOM Conversions.

Wizard: detect, map, validate, dry run, load.

Business rules: UOM convertibility, cycle detection, identifier uniqueness.

Reports: cost/margin impact; where-used list.

Power Features for Later (but designed for now)

Scheduled connectors (Sheets, S3), API ingestion endpoints.

Multi-file bundles with referential order (“load parties → ingredients → variants → recipes → lines”).

Transformation library with reusable macros (e.g., “pack ‘12x1 L’ parser”).

Data quality scorecards per tenant; alerts on regressions.

Success Metrics (to keep us honest)

Time-to-first-load ≤ 15 min (self-serve wizard).

≥ 95% rows import successfully on first pass with presets.

Reproducibility: any job can be replayed from stored artifacts/config.

Accuracy: post-load costing deltas match source within tolerated variance.