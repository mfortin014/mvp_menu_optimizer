<!--
title: chore,scripts: Make dump_schema.sh environment-agnostic (use DATABASE_URL only)
labels: ["chore","scripts","CI-phase:phase-1"]
assignees: []
uid: scripts-dump-schema-env-agnostic
parent_uid: ci-phase1-epic
type: Chore
status: Todo
priority: P2
area: ci
project: "main"
doc: ""
pr: ""
-->

# chore,scripts: Make `dump_schema.sh` environment-agnostic (use `DATABASE_URL` only)

**Intent**  
Remove prod/staging branching from `dump_schema.sh` and run it against whatever database the shell provides via `DATABASE_URL`. This matches the new Bitwarden + direnv (local) and CI synthesis model, keeps one mental model, and avoids accidental prod hits.

---

## Scope

- Update **`dump_schema.sh` only**.
- Keep **modes**: `--mode latest` (default) and `--mode release`.
- Remove the **environment switch** entirely: `--env prod|staging|both|auto`.
- Require `DATABASE_URL` in the environment; fail with a clear message if absent.
- Enforce **SSL** for Supabase by appending `sslmode=require` to `DATABASE_URL` at runtime:
  - If the URL already contains a `?`, append `&sslmode=require`.
  - Otherwise append `?sslmode=require`.
- Keep folder structure and headers; simplify filenames to remove the env suffix:
  - `schema/current/schema.sql` (instead of `schema/current/<env>.schema.sql`)
  - `schema/releases/supabase_schema_<YYYY-MM-DD_HHMMUTC>.sql` (no `<env>`)
  - `schema/archive/<YYYY_MM_DD_HHMM>.sql` (+ collision guard `_v02`, etc.)

---

## Out of scope

- No changes to other scripts (`dump_sample_data.sh`, `migrate.sh`).
- No CI workflow edits here (CI already synthesizes `DATABASE_URL` from `DB_*`).
- No changes to Bitwarden/direnv except the existing `DATABASE_URL` synthesis.

---

## Changes (precise)

1. **Argument parsing**

   - Remove handling for `--env` and the `ENV_TARGET` variable.
   - Remove logic and variables related to `DATABASE_URL_PROD` and `DATABASE_URL_STAGING`.

2. **Inputs**

   - Require `DATABASE_URL` from the process environment.
   - Keep optional `--tag <release-tag>` as is.

3. **SSL enforcement**

   - Compute `EFFECTIVE_URL` from `DATABASE_URL` by appending `sslmode=require` as described above.
   - Do not print the full URL to stdout.

4. **Dump pathing**

   - Replace dual-target loop with a single function call using `EFFECTIVE_URL`.
   - Paths:
     - Current: `schema/current/schema.sql`
     - Archive: `schema/archive/<YYYY_MM_DD_HHMM>.sql` with collision guard `_v02`, `_v03`, …
     - Release (when `--mode release`): `schema/releases/supabase_schema_<YYYY-MM-DD_HHMMUTC>.sql`

5. **Header prelude**

   - Keep existing fields (`Mode`, `Timestamp (UTC)`, `Git commit`, `Release Tag`).
   - Change the `Env:` line to `Env: from DATABASE_URL`.

6. **Help text**
   - Update `usage()` examples to remove `--env` and show only:
     - `./dump_schema.sh`
     - `./dump_schema.sh --mode release`
     - Optional `--tag <release-tag>`

---

## Acceptance

- With only `DATABASE_URL` set in the shell:
  - Running `./dump_schema.sh`:
    - Writes `schema/current/schema.sql`.
    - Writes `schema/archive/<YYYY_MM_DD_HHMM>.sql` (collision-safe).
  - Running `./dump_schema.sh --mode release`:
    - Also writes `schema/releases/supabase_schema_<YYYY-MM-DD_HHMMUTC>.sql`.
- Works whether `DATABASE_URL` already has a query string or not.
- No references to `DATABASE_URL_PROD` or `DATABASE_URL_STAGING` remain in the script.
- Help text shows no `--env` flag and is accurate.

---

## Evidence to attach (screenshots or paste)

- Output of `env | grep '^DATABASE_URL=' | sed 's/=.*$/=****/'` before each run.
- A successful run of `./dump_schema.sh` showing file paths written.
- A successful run of `./dump_schema.sh --mode release` showing the release snapshot path.
- `git ls -1 schema/current schema/releases | sed -n '1,10p'` after runs.

---

## Implementation steps (operator checklist)

- Branch:
  - `git checkout -b chore/dump-schema-env-agnostic`
- Edit `dump_schema.sh`:
  - Remove `--env` parsing and all prod/staging variables and logic.
  - Require `DATABASE_URL`; if empty, exit with message: `Set DATABASE_URL (see .envrc or CI synthesis)`.
  - Build `EFFECTIVE_URL` by appending `sslmode=require` as specified.
  - Replace the multi-env loop with a single dump function call using `EFFECTIVE_URL`.
  - Update `usage()` to reflect the simplified interface.
- Local test:
  - Ensure `DATABASE_URL` exists (Bitwarden + direnv synthesis).
  - Run `./dump_schema.sh` and verify outputs.
  - Run `./dump_schema.sh --mode release` and verify outputs.
- Commit:
  - `git add dump_schema.sh`
  - `git commit -m "chore(scripts): make dump_schema.sh environment-agnostic; use DATABASE_URL and enforce sslmode"`
- PR:
  - Base: `codex-phase1` ← Head: `chore/dump-schema-env-agnostic`
  - Attach evidence.

---

## Backout

- `git revert <commit>` or restore the previous file:
  - `git checkout <base-branch> -- dump_schema.sh && git commit -m "revert(scripts): restore env-aware dump_schema.sh"`

---

## Notes

- Local: `.envrc` synthesizes `DATABASE_URL` from `DB_*` and appends `sslmode=require`.
- CI: a job step synthesizes `DATABASE_URL` from `DB_*` and exports it to the job env without logging the value.
