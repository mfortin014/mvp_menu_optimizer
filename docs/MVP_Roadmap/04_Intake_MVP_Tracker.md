
# Intake_MVP — Implementation Tracker
**Version:** 1.0  \n**Updated:** 2025-09-16 17:47  \n**Owner:** Intake_MVP  \n**Status:** Draft

---

## Scope (MVP)
CSV ingestion with validation & quarantine for `ingredients` and `ingredient_costs`; idempotent commit; `import.completed` events.

## Out of Scope (v1+)
Multi-entity workbooks, async workers, vendor profile library, full audit catalog.

---

## Schema
- [ ] Create `import_batches` (+ `ux_import_idem`).
- [ ] Create `import_rows_quarantine`.
- [ ] Create `import_errors` (optional per-row detail; codes still go on quarantine row).
- [ ] Create `import_mapping_profiles` (nice-to-have).

## Functions
- [ ] `intake_start_batch(tenant_id, import_type, source_filename, idempotency_key, file_sha256)`.
- [ ] `intake_validate(import_batch_id, header_map, rows)`.
- [ ] `intake_commit(import_batch_id, actor)`.
- [ ] `intake_discard(import_batch_id, actor)`.

## Mappers
- [ ] Ingredients mapper: normalize `ingredient_code`, optional `name`, `base_unit`.
- [ ] Ingredient_costs mapper: resolve ingredient (code or alias), parse `unit_cost`, `currency`, `effective_from`.

## Streamlit Wiring
- [ ] Upload step: parse CSV -> preview first 50 rows.
- [ ] Header map step: apply profile or manual mapping (persist mapping as profile if chosen).
- [ ] Validate step: show quarantine table (errors & normalized preview).
- [ ] Commit button: disabled if `invalid_rows > 0`; shows summary on success.

## Idempotency & Dedupe
- [ ] Enforce `(tenant_id, idempotency_key)` uniqueness.
- [ ] (Optional) Warn on `file_sha256` duplicates for same tenant & import_type.

## Events
- [ ] Emit `import.completed` with counts after commit.
- [ ] Ensure Chronicle emits `ingredient.cost.updated` for cost rows committed.

## QA / Tests
- [ ] Unit: header mapping; ingredients validation; costs validation.
- [ ] Integration: happy path; all-bad file fully quarantined; mixed file blocks commit.
- [ ] SQL: valid status state machine; idempotency index works.

## Acceptance Gate
- [ ] Good file fully commits; bad file fully quarantines; no partial writes.
- [ ] Event emitted; counts accurate.
- [ ] Tenant scoping respected end-to-end.
