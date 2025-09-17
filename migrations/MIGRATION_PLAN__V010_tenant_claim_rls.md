# Plan: V010 — Swap to JWT-claim RLS (React phase)

Goal: move from permissive MVP policies to strict per-user tenant isolation using Supabase Auth JWT claims.

## Steps

1) **Auth model**
   - Use Supabase Auth for users.
   - Maintain `user_tenant_memberships(user_id uuid, tenant_id uuid, role text)`.

2) **JWT claims**
   - On sign-in, issue a JWT that contains either:
     - a single `tenant_id` claim **or**
     - a `tenant_ids` array claim (for multi-tenant users; Chef might keep one).
   - Optionally include `role`/permissions by tenant.

3) **Policy changes**
   - For each tenant-scoped table `T`:
     ```
     alter table public.T enable row level security;

     drop policy if exists T_select_all on public.T;
     drop policy if exists T_write_all on public.T;

     create policy "T_select_by_claim"
     on public.T for select
     using (
       (current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid = tenant_id
       -- Or: tenant_id in (select jsonb_array_elements_text(...)::uuid)
     );

     create policy "T_write_by_claim"
     on public.T for all
     using (
       (current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid = tenant_id
     )
     with check (
       (current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid = tenant_id
     );
     ```

4) **App swap**
   - In React, authenticate with the **anon** key (not service key).
   - Store the active tenant in UI state, but **authorization** is enforced by RLS.
   - For multi-tenant users, re-issue a token when switching tenants (or use a claim array policy).

5) **De-risking**
   - Keep a feature flag to fall back to MVP-permissive policies during rollout.
   - Add a read-only “admin” RPC that checks `current_setting('request.jwt.claims', true)` to debug claim parsing.

6) **Cutover**
   - Apply V010 with new policies.
   - Rotate client to use anon key + session JWT.
   - Verify queries fail when tenant does not match claims; verify succeed when it does.
