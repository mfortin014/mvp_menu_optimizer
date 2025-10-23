<!--
title: chore,scripts: Align `migrate.sh` with Bitwarden-run secrets
labels: ["ci","db"]
uid: scripts-migrate-bws
parent_uid: epic-bws-script-hardening
type: Chore
status: Todo
priority: P2
area: ci
-->

# chore,scripts: Align `migrate.sh` with Bitwarden-run secrets

## Intent

Ensure migrations run through `bws run --project-id=…` with internally synthesized connection URLs, dropping legacy env heuristics.

## Scope

- Resolve the DB URL via `python -m utils.db`, allowing a driver override.
- Remove `.env` auto-loading and legacy `DB_URL`/`SUPABASE_DB_URL` fallbacks once Bitwarden is the source of truth.
- Update usage/help text to document the Bitwarden invocation and failure modes.

## Acceptance

- `bws run --project-id="$STAGING" -- ./migrate.sh up --dry-run` works without extra exports.
- Script errors clearly when required secrets are absent.
- No references remain to prod/staging env-specific URLs.
