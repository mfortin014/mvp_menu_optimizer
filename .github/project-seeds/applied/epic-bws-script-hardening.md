<!--
title: Epic — Bitwarden-run DB scripts go env agnostic
labels: ["ci","db"]
uid: epic-bws-script-hardening
type: Epic
status: Todo
priority: P1
area: ci
children_uids: [
  "seed-uid:scripts-dump-schema-env-agnostic",
  "scripts-dump-sample-data-bws",
  "scripts-migrate-bws",
  "scripts-shared-db-helper-bws"
]
-->

# Epic — Bitwarden-run DB scripts go env agnostic

## Goal

All DB-affecting scripts run safely through `bws run --project-id=…`, synthesize `DATABASE_URL` internally, and avoid prod/staging branching.

## Acceptance

- Each child issue lands an approved PR that removes env branching, documents Bitwarden usage, and adds verification notes.
- Operators can target any Bitwarden project ID by exporting it in `.envrc` without further code changes.

## Children

- [ ] #seed-uid:scripts-dump-schema-env-agnostic — `dump_schema.sh`
- [ ] #scripts-dump-sample-data-bws — `dump_sample_data.sh`
- [ ] #scripts-migrate-bws — `migrate.sh`
- [ ] #scripts-shared-db-helper-bws — `utils/db.py`
