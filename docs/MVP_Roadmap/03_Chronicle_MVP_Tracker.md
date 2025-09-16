
# Chronicle_MVP — Implementation Tracker
**Version:** 1.0  
**Updated:** 2025-09-16 16:40  
**Owner:** Chronicle_MVP  
**Status:** Draft

---

## Scope (MVP)
SCD-lite for ingredient costs, recipe versions (draft/publish) + lines, price history; recompute now and as-of; events; idempotency.

## Out of Scope (v1+)
Backdating UI, bitemporal, async recompute queues, audit catalog.

---

## Schema & Indexes
- [ ] Create `ingredient_costs` (+ `ux_ing_cost_current`, `ix_ing_cost_tenant_time`).
- [ ] Create `recipe_versions` (+ `ux_recipe_current`, `ux_recipe_draft`, `ux_recipe_publish_idem`).
- [ ] Create `recipe_line_versions`.
- [ ] Create `recipe_price_history` (+ `ux_recipe_price_current`).

## App Functions
- [ ] `ingredient_cost_upsert(tenant_id, ingredient_id, unit_cost, currency, idempotency_key)`.
- [ ] `recipe_get_or_create_draft(tenant_id, recipe_id)`; clone from current if none.
- [ ] `recipe_publish_version(tenant_id, recipe_id, publish_idempotency_key)`; atomic close/open + recompute.
- [ ] `recipe_recompute_now(tenant_id, recipe_id)`.
- [ ] `recipe_cost_as_of(tenant_id, recipe_id, at)`.

## Streamlit Wiring
- [ ] Recipe editor loads/creates **draft** transparently when editing a published recipe.
- [ ] Save → calls **publish** (no manual clone step).
- [ ] Cost editor uses **cost upsert**; recompute button calls recompute.
- [ ] As-of view (simple input timestamp) computes and displays cost/price/margin.

## Idempotency
- [ ] Enforce publish once per `publish_idempotency_key` (partial unique index).
- [ ] Enforce no-op on repeating cost `idempotency_key` for latest current row.

## Events
- [ ] Emit `ingredient.cost.updated` on cost change.
- [ ] Emit `recipe.versioned` after publish.
- [ ] Emit `recipe.recomputed` after recompute.
- [ ] Ensure `correlation_id` ties publish→recompute and import→cost updates.

## Migration
- [ ] Backfill one published version per recipe; copy current lines.
- [ ] Backfill one current price per recipe.
- [ ] Seed `ingredient_costs` current rows from existing data.

## Tests
- [ ] Unit: cost SCD transitions, publish atomics, as-of math.
- [ ] SQL: uniqueness invariants (current, draft), cost current uniqueness.
- [ ] Event sanity: expected rows in `event_log` with sensible payloads.

## Acceptance Gate
- [ ] Edit-save produces one new published version; previous closed.
- [ ] As-of results match expectations across cost and structure changes.
- [ ] Events emitted; idempotency prevents duplicates.
