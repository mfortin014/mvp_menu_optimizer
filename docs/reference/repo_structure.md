# Repo Structure & Paths
**Updated:** 2025-09-18 21:15

Purpose: quick map of the directories you will touch during Phase-1 work. Pair this with `docs/README.md` when you need the wider doc context.

---

## Top-Level Map

### MVP now
- `Home.py`, `pages/`, `components/`, `utils/` — Streamlit MVP surface area.
- `data/fixtures/` — tiny, non-sensitive CSV fixtures used in docs and smoke tests.
- `data/exports/` — larger Supabase export snapshots (ignored; keep local only).
- `migrations/sql/` — ordered `V###__desc.sql` migrations (apply via Supabase/psql; never edit in place).
- `schema/current/` — latest production schema dump (`prod.schema.sql`).
- `schema/releases/` — tagged release snapshots (one file per shipped release).
- `tests/unit/`, `tests/smoke/` — minimal test suites exercised by CI.
- `docs/` — index, policies, runbooks, and specs (see `docs/README.md`).
- `.github/workflows/` — GitHub Actions, including `ci.yml`.

### v1 later
- `apps/` (future React client) and `services/` (API workers) will join once the MVP graduates.
- Additional schema slices (`schema/tenant/`, `schema/analytics/`) once the data model bifurcates.
- Infra manifests (`infra/terraform/`, `helm/`) when we move to managed deployments.

---

## Naming Rules

### MVP now
- Use `snake_case` for filenames; avoid spaces.  
- Migrations follow `V###__desc.sql` and live under `migrations/sql/` only.  
- Release schema dumps are `schema/releases/<version>.schema.sql` (human-triggered via `dump_schema.sh`).

### v1 later
- Expect module splitting (`menu_optimizer/`) once we package the core library.  
- Stable API docs will move into `docs/reference/api/` alongside typed client references.

---

## Editing Guardrails

- Keep generated assets (`dist/`, `archive/`) read-only in Git.  
- When adding new directories, update this file and `docs/README.md`.  
- Coordinate cross-cutting refactors through specs (`docs/specs/`).
