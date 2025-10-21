<!--
title: chore,utils: Allow Bitwarden-run scripts to override DB driver
labels: ["ci","db"]
uid: scripts-shared-db-helper-bws
parent_uid: epic-bws-script-hardening
type: Chore
status: Todo
priority: P1
area: ci
-->

# chore,utils: Allow Bitwarden-run scripts to override DB driver

## Intent

Let `utils/db.py` build `DATABASE_URL` strings for both SQLAlchemy clients and CLI tools, keeping sslmode enforcement centralized.

## Scope

- Add a driver override (e.g., `DB_DRIVER`) while keeping the default `postgresql+psycopg`.
- Ensure `python -m utils.db` emits a URL suited for `pg_dump`/`psql` when the override requests `postgresql`.
- Document the environment variables in the module docstring and ensure percent-encoding still works.

## Acceptance

- Smoke test (`tests/smoke/test_db_connect.py`) continues to pass with defaults.
- Running `DB_DRIVER=postgresql python -m utils.db` produces a URL acceptable to `pg_dump` without double-encoding.
- No scripts need to hand-roll `sslmode=require`; callers rely on the helper instead.
