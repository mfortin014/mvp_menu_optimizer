# Changelog

All notable changes to this project will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

[Compare](https://github.com/mfortin014/mvp_menu_optimizer/compare/v0.7.0...HEAD)

### Added

- Bootstrap migration `V000__bootstrap_schema.sql` capturing the 2025-09-09 schema baseline so fresh environments can replay the full chain.

## [0.7.0] - 2025-10-17

[Tag: v0.7.0](https://github.com/mfortin014/mvp_menu_optimizer/releases/tag/v0.7.0) ·
[Compare](https://github.com/mfortin014/mvp_menu_optimizer/compare/mvp-0.6.0...v0.7.0)

### Added

- **Multi-job CI** with clear visibility:
  - `lint` (ruff), `format` (black), `imports` (isort), `unit-tests`, and `smoke-tests`.
  - Per-job environment scoping (`environment: staging`) so jobs can read environment-scoped **variables** and **secrets**.
  - Concurrency/cancel-in-progress to avoid wasted runs.
- **CLI helper**: `python -m utils.db` prints a correctly encoded Postgres URL for shell tools (pg_dump/psql).

### Changed

- **Single source of truth for DB URLs**: `utils/db.py` now _always_ synthesizes `DATABASE_URL` from `DB_*` (host/port/name/user/password), percent-encodes the password, and enforces `sslmode=require`. Callers use `get_engine()` instead of assembling URLs.
- **Secrets model (local)**: favor explicit `bws run --project-id=... -- <cmd>` and a **minimal** `.envrc`; stop relying on local `.env` or `secrets.toml` for dev.
- **CI organization**: replaced the catch-all `check` with dedicated jobs; update branch protections to match job names.
- **Data/layout**: rename `sample` → `fixtures` and `sample_data` → `exports`; ignore `exports/` in VCS.

### Removed

- `scripts/synthesize_db_url.sh` (DB URL construction is centralized in Python).
- Assumption that `DATABASE_URL` must exist in the environment; code now derives it at runtime.

### Fixed

- Resolved `ModuleNotFoundError` for `utils` in tests by ensuring repo root on `PYTHONPATH`.
- Resolved `psycopg` vs `psycopg2` mismatch by pinning runtime to `psycopg` and using the `postgresql+psycopg` dialect.
- Eliminated CI “stuck pending **check**” by aligning job names with branch protection rules.

### Security

- No plaintext secrets in logs; CI only injects **raw inputs** (DB\_\* & project id) and never prints the synthesized URL.
- Local secrets are **opt-in** via Bitwarden (BWS) and live only in the process environment (no files on disk).

### Documentation

- Updated **first_run.md** for Bitwarden-driven secret injection and new run commands.
- Added/updated smoke harness docs; clarified DB URL centralization and removal of legacy `.env`/`secrets.toml` in dev.

### Chore

- Minor CI “nudge” commits and housekeeping.
- Applied automation seeds; routine repo maintenance.

### Reverted

- Reverted earlier experimental scaffolding branches (restored pre-E state).

## [0.6.0] - 2025-09-16

[Tag: mvp-0.6.0](https://github.com/mfortin014/mvp_menu_optimizer/releases/tag/mvp-0.6.0)

### Added

- Multi-tenant architecture: tenant-aware DB proxy for reads/writes; single default client constraint; RLS policies and views; migration set V001–V011.
- Client management UI: unified **Clients** page, **Tenant Manager** (list/add/edit/activate/deactivate/switch), pre-auth client picker with DB default, **Active Client** badge.
- Tenant branding: DB-driven logo/colors; global brand colors across UI.
- Configurable default tenant (env + DB fallback); sample data + schema dumps via `dump_schema.sh`.
- Release hygiene: `VERSION` source of truth, migration markers, and helper scripts (`bump_version.sh`, `release_stamp.sh`).

### Fixed

- Client page state: reliable hydration and selection, enforce single default, prevent deactivating the default client.
- UI stability: clear form state without rehydration glitches; sticky focus issues; grid selection edge cases.
- Branding loader: always return safe defaults (no KeyError/None).

### Changed

- Tenant resolution now uses session/env; removed per-page tenant dropdown in favor of the **Active Client** badge and centralized switching.
- Consolidated navigation and forms for a simpler, predictable flow.

### Documentation

- MVP roadmap, feature specs, and trackers updated; schema snapshots added under `schema/`.
