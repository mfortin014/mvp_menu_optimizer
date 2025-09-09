
# Upgrade: Single-DB Multi-Tenant + Soft Delete (MVP)

## Prereqs
- Postgres connection string in `DATABASE_URL` env var.
- `psql` and `pg_dump` available.

## Steps
1. Backup:
   ```bash
   ./scripts/backup_db.sh
   ```

2. Apply migrations:
   ```bash
   ./scripts/upgrade.sh
   ```

3. Verify:
   ```bash
   ./scripts/verify.sh
   ```

4. App changes (summary):
   - Add a **Client** dropdown bound to `st.session_state['tenant_id']` populated via:
     ```sql
     select t.id, t.name
     from public.tenants t
     join public.user_tenant_memberships m on m.tenant_id = t.id
     join public.profiles p on p.id = m.user_id
     where m.deleted_at is null and t.deleted_at is null and p.email = :chef_email;
     ```
   - All selects: add `.eq('tenant_id', tenant_id)` and `deleted_at is null` filter.
   - All inserts/updates: include `tenant_id=tenant_id` and never set `deleted_at` (use soft delete action to set it).

5. Seed Chef membership (if needed):
   ```sql
   insert into public.user_tenant_memberships (user_id, tenant_id, role)
   select p.id, t.id, 'owner'
   from public.profiles p, public.tenants t
   where p.email = :chef_email and t.code = 'SLF'
   on conflict do nothing;
   ```

## Notes
- Cross-tenant guards prevent `recipe_lines`/`sales` from pointing at parents in other tenants.
- RLS policies are permissive for MVP (service role bypasses them). Tighten later with JWT claims.
- Soft delete via `deleted_at`; status remains a pure business field.
