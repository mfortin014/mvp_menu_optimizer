# DB Restore — Runbook (MVP)

**Owner:** Ops  
**Scope:** Supabase Postgres restore patterns (rehearsal + incident)  
**Backups:** produced by `scripts/backup_db.sh` → `backups/<YYYYMMDD_HHMMSS>_<env>[_label]/db_full.dump`

> ⚠️ **Safety first**: Prefer a *rehearsal restore* in a fresh Supabase project. For real staging/prod, restore **only the `public` schema** unless you intentionally need to replace Supabase-managed schemas (`auth`, `storage`, etc.). Always keep `--no-owner --no-privileges` during restore to avoid role conflicts.

---

## Prerequisites

- PostgreSQL client tools installed: `pg_restore`, `psql`
- A backup created by the runbook (custom format `.dump`)
- Connection info for the **target** project:
  - **Direct** host: `db.<PROJECT_REF>.supabase.co`, user `postgres`, port `5432`
  - **Supavisor (pooler) session** host: `aws-0-<REGION>.pooler.supabase.com`, user `postgres.<PROJECT_REF>`, port `5432`
  - **Supavisor (pooler) transaction** port: `6543` (same host/user as session)
- The **project’s database password** (from Supabase → Project → Database → Connection)

> ✅ Use the **Direct** or **session pooler** connection when possible. Avoid the transaction pooler for long restores unless needed.

---

## Restore modes

### A) Rehearsal restore (fresh Supabase project) — **recommended**
Use this to validate backups without touching staging/prod.

1. Create a **new Supabase project** (keep it empty).  
2. Pick a connection type:
   - **Direct** (recommended):
     ```bash
     PGPASSWORD='<NEW_DB_PASSWORD>'      pg_restore --clean --if-exists --no-owner --no-privileges        -n public        -h db.<NEW_PROJECT_REF>.supabase.co -p 5432        -U postgres -d postgres        backups/<ts>_staging_*/db_full.dump
     ```
   - **Session pooler** (if Direct is unavailable from your network):
     ```bash
     PGPASSWORD='<NEW_DB_PASSWORD>'      pg_restore --clean --if-exists --no-owner --no-privileges        -n public        -h aws-0-<REGION>.pooler.supabase.com -p 5432        -U postgres.<NEW_PROJECT_REF> -d postgres        backups/<ts>_staging_*/db_full.dump
     ```
3. Verify (see **Post-restore verification** below).

---

### B) Incident recovery (staging/prod) — **public schema restore**
For production or staging, restore only `public` by default.

**Staging example (Direct):**
```bash
PGPASSWORD='<STAGING_DB_PASSWORD>' pg_restore --clean --if-exists --no-owner --no-privileges   -n public   -h db.<STAGING_PROJECT_REF>.supabase.co -p 5432   -U postgres -d postgres   backups/<ts>_staging_*/db_full.dump
```

**Prod example (Session pooler):**
```bash
PGPASSWORD='<PROD_DB_PASSWORD>' pg_restore --clean --if-exists --no-owner --no-privileges   -n public   -h aws-0-<REGION>.pooler.supabase.com -p 5432   -U postgres.<PROD_PROJECT_REF> -d postgres   backups/<ts>_prod_*/db_full.dump
```

> If you *must* restore specific tables only:
> ```bash
> # data-only restore for selected tables
> PGPASSWORD='<PASS>' pg_restore --data-only --no-owner --no-privileges >   -t public.table_a -t public.table_b >   -h db.<PROJECT_REF>.supabase.co -p 5432 -U postgres -d postgres >   backups/<ts>_*/db_full.dump
> ```

---

## Post-restore verification (target project)

Run in Supabase SQL editor or `psql`.

**1) DB/version & extensions**
```sql
SELECT version();
SELECT n.nspname, extname, extversion
FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace
ORDER BY 1,2;
```

**2) RLS on sensitive tables**
```sql
SELECT relname, relrowsecurity
FROM pg_class
WHERE relnamespace = 'public'::regnamespace
  AND relname IN ('profiles','schema_migrations')
ORDER BY 1;
```

**3) Views run as caller (security invoker)**
```sql
SELECT c.relname AS view, c.reloptions
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE c.relkind='v' AND n.nspname='public'
  AND c.relname IN ('recipe_line_costs','recipe_summary','missing_uom_conversions',
                    'ingredient_costs','input_catalog','recipe_line_costs_base','prep_costs')
ORDER BY 1;
```

**4) Functions pinned search_path**
```sql
SELECT p.proname AS function,
       oidvectortypes(p.proargtypes) AS arg_types,
       p.proconfig
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public'
  AND p.proname IN (
    'enforce_same_tenant_sales',
    'enforce_same_tenant_recipe_lines',
    'enforce_same_tenant_ingredient_refs',
    'get_recipe_details_mt',
    'get_unit_costs_for_inputs_mt',
    'set_updated_at',
    'update_updated_at_column',
    'get_recipe_details',
    'get_unit_costs_for_inputs'
  )
ORDER BY 1;
```

**5) Application smoke**
- App boots and loads core views
- A couple of read/write flows succeed (e.g., profile update is restricted to self via RLS)

---

## Helper scripts (optional)

If present in the repo:

- **Backup:** `scripts/backup_db.sh [prod|staging] [label]`  
- **Restore (URL-free):** `scripts/restore_public.sh --host HOST --port 5432 --user USER --db DB --password 'SECRET' <dump_path>`

Example (Direct):
```bash
scripts/restore_public.sh   --host db.<PROJECT_REF>.supabase.co --port 5432   --user postgres --db postgres --password '<PASS>'   backups/<ts>_staging_*/db_full.dump
```

Example (Session pooler):
```bash
scripts/restore_public.sh   --host aws-0-<REGION>.pooler.supabase.com --port 5432   --user postgres.<PROJECT_REF> --db postgres --password '<PASS>'   backups/<ts>_staging_*/db_full.dump
```

---

## Common pitfalls & fixes

- **`FATAL: Tenant or user not found`**  
  Using a pooler host with the wrong username. For pooler: `postgres.<PROJECT_REF>`. For Direct: user `postgres` and host `db.<PROJECT_REF>.supabase.co`.

- **Local socket error (`/var/run/postgresql/.s.PGSQL.5432`)**  
  Connection string/env var didn’t reach `pg_restore`. Prefer the `PGPASSWORD ... pg_restore -h ... -U ...` pattern.

- **Passwords with `!` or special chars**  
  Avoid embedding in URLs (history expansion, percent-encoding). Use `PGPASSWORD='...'` + flags.

- **`permission denied` / owner mismatches**  
  Keep `--no-owner --no-privileges` on restore.

- **Extensions missing**  
  Enable in Supabase → Database → Extensions, then `ALTER EXTENSION ... UPDATE;` if needed.

- **Network/IPv6**  
  If Direct fails, try the session pooler (5432) or transaction pooler (6543).

- **Large dump timeouts**  
  Add `--jobs=4` (or higher) to pg_restore if your environment supports parallel restore.

---

## Change log

- **2025-10-02** Initial version (MVP). Rehearsal + incident restores, verification, pitfalls.
