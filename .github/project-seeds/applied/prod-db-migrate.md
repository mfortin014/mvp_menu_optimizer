<!--
title: Supabase (prod) — run migrate.sh to build DB
labels: ["db","ci","phase:prod-setup"]
assignees: []
uid: prod-db-migrate
parent_uid: prod-setup-epic
type: Chore
status: Todo
priority: P1
target: mvp-0.7.0
area: db
doc: "docs/policy/migrations_and_schema.md"
pr: ""
-->

# Supabase (prod) — run migrate.sh to build DB

Apply **append-only, idempotent** migrations against the **production Supabase** instance, then refresh schema snapshots according to our policy.

## Acceptance

- Production DB URL is resolved securely (no plaintext in repo).
- `./migrate.sh up` completes with **no errors**.
- Post-migration: `./dump_schema.sh` captures **current** prod snapshot and archives previous release dump.
- RLS and views confirmed (quick spot-check on critical views).
- Notes added to the release PR regarding **Expand → Migrate → Contract** if applicable.

## References

- Migrations & Schema Discipline
- CI/CD Constitution — Expand → Migrate → Contract
