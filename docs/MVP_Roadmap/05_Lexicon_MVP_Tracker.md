
# 05_Lexicon_MVP — Tracker
**Version:** 1.0  
**Updated:** 2025-09-16 18:02  
**Owner:** Cath (MVP)  
**Dependencies:** Identity_MVP (codes are canonical), Measure_MVP (base units), MVP Readiness (event_log)

---

## Milestone A — Schema & Settings
- [ ] Create table `ingredient_i18n` (PK: ingredient_code+locale; columns: name, description, updated_at, updated_by)
- [ ] Add/confirm `tenant_settings.default_locale` with constraint in ('en','fr')
- [ ] Create view `v_ingredient_label` with fallback ladder (session vars `app.locale`, `app.default_locale`)
- [ ] Add indexes: (`locale`, `name`) on `ingredient_i18n`

**Acceptance:** DDL applied; view returns expected label & quality for test rows.

---

## Milestone B — Session & App Wiring
- [ ] On DB connect, set `app.default_locale` and `app.locale` (use tenant default when UI unset)
- [ ] Add UI locale picker (simple toggle en/fr saved to session)
- [ ] Ensure searches use the view’s `label`

**Acceptance:** Switching locale updates list labels; fallback badge appears when appropriate.

---

## Milestone C — CRUD Helpers (mirror v1 shapes)
- [ ] Implement `ingredient_i18n_upsert(ingredient_code, locale, name?, description?)`
- [ ] Implement read helper `ingredient_label(locale)` using the view
- [ ] Uniform error shape on failures (`INVALID_PAYLOAD`, `NOT_FOUND`, `CONFLICT`)

**Acceptance:** Unit tests green; shape matches the Spec’s examples.

---

## Milestone D — CSV Ingestion
- [ ] Extend ingestion parser to accept `name_en`, `name_fr`, `description_en`, `description_fr`
- [ ] Validation: ignore unknown locale columns; do **not** block on missing localized fields
- [ ] Quarantine messages include per‑locale validation errors (if any)

**Acceptance:** Sample file with partial locale columns imports; rows show localized labels.

---

## Milestone E — Events & Audit
- [ ] Emit `ingredient.updated` event with `changed_fields` like `["name.fr","description.fr"]`
- [ ] Verify `event_log` entries after localized writes
- [ ] Add one parity export query covering localized changes

**Acceptance:** Sanity query returns events; export produces expected JSON/CSV.

---

## Milestone F — Backfill & Rollout
- [ ] Optional backfill: if legacy `ingredients.name` exists, copy to `ingredient_i18n` using `tenant_settings.default_locale`
- [ ] Update Streamlit pages (list/form) to use view + helpers
- [ ] Smoke test: both locales render, fallbacks correct, import path clean

**Acceptance:** Smoke tests pass; zero regressions on identity, costing, or imports.

---

## Risks & Mitigations
- **Partial translations** → badge + fallback ladder keeps UI trustworthy.
- **Locale drift** → session vars set on connect; default is enforced per tenant.
- **Search mismatch** → search targets `label` (view) and `ingredient_code` as secondary.

---

## Out of Scope (deferred to v1)
- ICU/plurals/gender, RTL; translation memory/workflows; locale negotiation via headers; cross‑module i18n service.

---

## Quick Test Matrix
| Case | Locale | name.en | name.fr | Expected label | quality |
|------|--------|---------|---------|----------------|---------|
| A    | fr     | ✗       | ✓       | fr name        | exact   |
| B    | fr     | ✓       | ✗       | en name        | default_fallback |
| C    | fr     | ✗       | ✗       | ingredient_code| code_fallback |
| D    | en     | ✓       | ✓       | en name        | exact   |

---

## Done Definition (overall)
- [ ] Schemas, view, session vars implemented
- [ ] UI shows localized labels with clear fallback indicator
- [ ] CSV import supports localized columns (optional)
- [ ] Events emitted and verifiable in `event_log`
- [ ] Unit + integration tests pass
