# DB Backups — Runbook (MVP)

**Owner:** Ops  
**Script:** `scripts/backup_db.sh`  
**Scope:** Staging (default) and Prod backups for the Supabase Postgres DB  
**Why:** Patch upgrades, schema changes, and auth tweaks should never be risky without a safety net.

---

## What this captures

- Full database dump (`.dump`, custom format) — reliable restores via `pg_restore`
- Schema-only snapshot (`schema.sql`) — quick to grep/diff
- Server version and extensions inventory — post-upgrade sanity
- View `reloptions` (e.g., `security_invoker=true`) — permission posture snapshot

Backups land under `./backups/<YYYYMMDD_HHMMSS>_<env>[_label]/`.  
`backups/` is gitignored.

---

## Prereqs

- PostgreSQL client tools installed: `pg_dump` and `psql`
- `.env` in repo root:
  - **Staging:** `DATABASE_URL_STAGING` (preferred) or legacy `DATABASE_URL`
  - **Prod:** `DATABASE_URL_PROD`
- Use **Direct** connection strings (port **5432**, not 6543), ideally with `?sslmode=require`.

> Tip: In Supabase → Database → Connection Info, copy the **Direct** URL.

---

## When to back up

- Before **DB patch upgrades** (Supabase → Database → Upgrades)
- Before **schema-changing migrations**
- Before changing **Auth** controls (password/attack protection)
- Before **bulk data** operations (backfills, purges, id remaps)
- Before **tenant** split/merge work

---

## Run it

### Staging (default)

```bash
# Uses DATABASE_URL_STAGING, falling back to DATABASE_URL (legacy)
scripts/backup_db.sh pre-upgrade
```

### Prod

```bash
# Uses DATABASE_URL_PROD
scripts/backup_db.sh prod pre-upgrade
```

### One-off URL (rare)

```bash
scripts/backup_db.sh --url "postgresql://user:pass@host:5432/db?sslmode=require" manual
```

### Quiet output (no local restore hint)

```bash
scripts/backup_db.sh --no-restore-hint pre-upgrade
```

---

## Verify the backup

After a run, expect a folder like `backups/20251002_121314_staging_pre-upgrade` containing:

- `db_full.dump`
- `schema.sql`
- `version.txt`
- `extensions.tsv`
- `views_reloptions.tsv`

Quick checks:

```bash
ls -lh backups/*_staging_*/db_full.dump
head -1 backups/*_staging_*/version.txt
column -t -s $'\t' backups/*_staging_*/extensions.tsv | head
grep -E 'security_invoker' backups/*_staging_*/views_reloptions.tsv | wc -l
```

---

## (Optional) Restore test — disposable container

You do **not** need Postgres installed locally. Use Docker:

```bash
# 1) Start a temporary Postgres 15 container
docker run --rm -d --name pg-restore -e POSTGRES_PASSWORD=pass -p 5455:5432 postgres:15

# 2) Restore the dump
pg_restore --clean --if-exists --no-owner --no-privileges   -j4 -h localhost -p 5455 -U postgres -d postgres   backups/2025xxxx_xxxxxx_staging_pre-upgrade/db_full.dump

# 3) Spot-check
psql "postgresql://postgres:pass@localhost:5455/postgres" -c "SELECT current_database(), current_schema();"

# 4) Stop container (it auto-removes due to --rm)
docker stop pg-restore
```

If you don’t use Docker, skip this section. It’s an optional sanity check.

---

## Restore (incident playbook — summary)

- **Preferred:** Restore into a **new Supabase project** (fresh DB), point staging to it, and validate.
- **Emergency in-place:** Coordinate downtime; restore with `pg_restore --clean --if-exists` against the target DB.
  - Confirm extensions match.
  - Supabase-managed objects defined in SQL (e.g., policies) are included in the dump.

> Avoid overwriting production blindly. Practice a restore into a throwaway environment at least once per quarter.

---

## Retention policy (MVP)

- **On-demand backups:** keep last **5** per environment.
- **Pre-upgrade backups:** keep last **2** per env (folders tagged with `_pre-upgrade`).
- Move older `.dump` files to cold storage (encrypted bucket) periodically.

Examples:

```bash
# Keep only the 5 most recent staging backups
ls -1dt backups/*_staging_* | tail -n +6 | xargs -r rm -rf
```

---

## Common errors & fixes

- **connection to server on socket … failed**  
  The script didn’t get a URL. Ensure `.env` has `DATABASE_URL_STAGING` or `DATABASE_URL` (staging) / `DATABASE_URL_PROD` (prod), or pass `--url`.

- **pg_dump fails on port 6543**  
  That’s the pooled URL. Use the **Direct** 5432 URL.

- **SSL required**  
  Add `?sslmode=require` to the connection string.

- **Permission denied on restore**  
  Use `--no-owner --no-privileges` when restoring, or create matching roles before restore.

---

## Change log

- **2025-10-02** Initial version. Captures full dump, schema, version, extensions, and view options.
