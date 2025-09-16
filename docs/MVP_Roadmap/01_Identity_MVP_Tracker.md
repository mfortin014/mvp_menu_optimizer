
# Identity_MVP — Implementation Tracker
**Version:** 1.0  \n**Updated:** 2025-09-16 05:02  \n**Owner:** Identity_MVP  \n**Status:** Draft

---

## Scope (MVP)
Deterministic ingredient identity, tenant safety, soft delete, exact aliasing, manual merges, and tenant-scoped views. No fuzzy matching.

## Out of Scope (v1+)
ML/fuzzy dedupe, supplier adapters, global registries, review UI.

---

## Schema changes
- [ ] Create `ingredients` (with fields listed in spec).
- [ ] Create partial unique index `ux_ingredients_code_active`.
- [ ] Create `ingredient_aliases` + unique index `ux_alias_unique`.
- [ ] Create `ingredient_merges` (lineage log).
- [ ] Add/confirm `base_unit` column (owned by Measure_MVP; allowed values g/ml/unit).

## Functions & Views
- [ ] Add `normalize_code(text)` (SQL, immutable).
- [ ] Add `v_ingredients_active` view.
- [ ] Add `find_ingredient_id(tenant_id, code_or_alias)` resolver.

## RLS (optional now; pattern ready)
- [ ] Enable RLS on `ingredients` and `ingredient_aliases`.
- [ ] Add tenant policies using `current_setting('app.tenant_id', true)`.

## App changes (Streamlit)
- [ ] All reads go through views or resolver (no raw table scans).
- [ ] Upsert uses `ingredient_upsert()` local function (future APL-compatible signature).
- [ ] Alias add uses `ingredient_alias_add()`.
- [ ] Manual merge admin script wired (SQL function or simple page).
- [ ] Event emits (optional): `ingredient.created`, `ingredient.merged` to `event_log`.

## Data migration
- [ ] Normalize existing codes; report duplicates by tenant.
- [ ] Prepare merge sheet; execute merges; soft-delete duplicates.
- [ ] Move legacy codes into `ingredient_aliases` (`alias_type='legacy_code'`).

## Tests
- [ ] Unit: normalization (edge cases), upsert idempotency, alias uniqueness.
- [ ] SQL: uniqueness with soft delete; resolver hit for alias and code.
- [ ] Manual: RLS smoke and cross-tenant leak check.

## Acceptance gate
- [ ] Uniqueness guaranteed for active ingredients per tenant.
- [ ] Reads exclude soft-deleted rows.
- [ ] Aliases resolve correctly; no duplicate aliases.
- [ ] Merge lineage recorded; duplicates eliminated in seed data.

---

## Links
- Spec: *Identity_MVP — Ingredient Identity & Deterministic Dedupe (Spec)*
- Related: Measure_MVP (base_unit), Chronicle_MVP (events/idempotency), Intake_MVP (imports), Lexicon_MVP (labels)
