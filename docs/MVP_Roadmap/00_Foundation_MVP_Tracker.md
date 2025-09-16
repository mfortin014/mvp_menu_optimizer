
# Foundation_MVP — Implementation Tracker
**Version:** 1.0  \n**Updated:** 2025-09-16 05:13  \n**Owner:** Foundation_MVP  \n**Status:** Draft

---

## Scope (MVP)
Invariants, data/event plumbing, and app skeleton to keep MVP v1‑ready.

## Out of Scope (v1+)
Full RLS, gateway, brokered events, formal audit catalog, E2E CI.

---

## Migrations / DDL
- [ ] V001 — Create `event_log` + indexes.
- [ ] V002 — Add partial unique index pattern to active entities (ingredients once Identity lands).
- [ ] V003 — Add `idempotency_key` columns where needed (import batches, ingredient_costs).
- [ ] Runner/checklist to apply all migrations idempotently.

## Tenant context & soft delete
- [ ] Add `tenant_id` to connection/session (or pass as param everywhere).
- [ ] Ensure all list/detail queries filter `deleted_at is null`.
- [ ] Verify partial unique indexes exclude soft‑deleted rows.

## Idempotent writes
- [ ] Imports require `idempotency_key`; duplicate keys are no‑ops.
- [ ] Cost updates require `idempotency_key`; duplicate windows are blocked/no‑op.
- [ ] Unit tests for duplicate submissions (import, cost update).

## Events
- [ ] Wire `emit_event(...)` helper.
- [ ] Emit `ingredient.cost.updated` after cost write.
- [ ] Emit `import.completed` after commit.
- [ ] Emit `recipe.recomputed` after recompute.
- [ ] Sanity SQL returns counts in last hour.

## Client layer
- [ ] Implement `MOClient` interface and `LocalClient` adapter.
- [ ] Implement `HttpClient` adapter (stub now; will be used at cutover).
- [ ] Set `MO_API_MODE` in `.env`; confirm pages only call the client.

## Error shape & handling
- [ ] Raise/handle uniform error `{ "error": { "code","message","details" } }` in client & services.
- [ ] Add minimal toasts/messages in Streamlit for error presentation.

## Parity export
- [ ] Add a windowed export (CSV/JSON) of `event_log` to a simple admin screen.

## Acceptance gate
- [ ] All invariants satisfied (tenant, soft delete, idempotency, events, errors, client abstraction).
- [ ] Migrations applied cleanly; sanity tests pass; no business logic in widgets.

---

## Links
- Spec: *Foundation_MVP — Platform Invariants & App Skeleton (Spec)*
- Related specs: Identity_MVP, Measure_MVP, Chronicle_MVP, Intake_MVP, Lexicon_MVP
