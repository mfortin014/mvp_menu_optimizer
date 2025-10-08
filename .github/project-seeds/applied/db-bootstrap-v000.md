<!--
title: Capture 2025-09-09 schema as V000 bootstrap
labels: ["db", "migration"]
assignees: []
uid: db-bootstrap-v000
type: Chore
status: Todo
priority: P1
target: mvp-0.7.0
area: db
project: "main"
doc: "migrations/sql/V000__bootstrap_schema.sql"
-->

# Capture 2025-09-09 schema as V000 bootstrap

## Goal

Produce `V000__bootstrap_schema.sql` that rebuilds the Supabase schema exactly as it existed on **2025-09-09**, so the database can be recreated from migrations alone.

## Plan

1. **Baseline review**
   - Check out `chore/migration-v000`.
   - Re-read migrations `V001+` to note the schema objects they expect (tables, columns, policies) so V000 leaves the database in that state.
   - Confirm the 2025-09-09 schema dump (live reference) is the baseline you are targeting.
2. **Review the archived schema dump (2025-09-09)**
   - Locate `schema/archive/supabase_schema_2025-09-09_01.sql` (already captured from the baseline).
   - Copy the file to a working location (e.g., `tmp/schema-20250909.sql`) without modifying the original archive.
   - Confirm the dump matches the expected live snapshot (spot-check key tables, columns, policies).
3. **Normalize for migration use**
   - Strip non-deterministic SQL (`SET`, `COMMENT`, `OWNER`, `GRANT`, `SELECT pg_catalog.set_config`, etc.).
   - Keep the object creation order compatible with V001+ expectations (tables before indexes/views/policies).
   - Add `BEGIN;` / `COMMIT;` wrappers if consistent with existing migration files.
4. **Create `V000__bootstrap_schema.sql`**
   - Copy the sanitized dump into `migrations/sql/V000__bootstrap_schema.sql`.
   - Add a header comment documenting the snapshot date (2025-09-09), dump command, and refresh instructions.
   - Update tooling/docs (`migrate.sh`, runbooks) if they assumed migrations start at V001.
5. **Validation**
   - Reset a local/shadow database.
   - Run migrations sequentially (`./migrate.sh up` from V000 onward).
   - Compare the resulting schema to the live reference (`pg_dump --schema-only` + `diff` or `schema/supabase_schema.sql`).
6. **Documentation & follow-up**
   - Update runbooks or policies describing how to regenerate the bootstrap when the baseline changes.
   - Note the change in `Menu_Optimizer_Changelog.md` and any release notes.
   - Prepare the PR with V000, doc updates, and validation notes.

## Acceptance

- `migrations/sql/V000__bootstrap_schema.sql` captures the 2025-09-09 schema and leaves V001+ migrations runnable without conflicts.
- Fresh database rebuild (V000 → latest) matches the live Supabase schema.
- Documentation clearly states the baseline snapshot and maintenance steps for refreshing V000.
