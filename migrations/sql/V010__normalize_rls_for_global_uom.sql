-- ============================================
-- V010: Normalize RLS for global ref_uom_conversion
--        - Keep RLS enabled
--        - Allow SELECT for anon/authenticated
--        - No write policies (service role can still write; it bypasses RLS)
-- ============================================
-- Ensure RLS on
alter table public.ref_uom_conversion enable row level security;
-- Drop ALL existing policies on this table (names may vary across envs)
do $$
declare pol record;
begin for pol in
select schemaname,
    tablename,
    policyname
from pg_policies
where schemaname = 'public'
    and tablename = 'ref_uom_conversion' loop execute format(
        'drop policy if exists %I on public.ref_uom_conversion;',
        pol.policyname
    );
end loop;
end $$;
-- Re-create a single read policy for both anon and authenticated
create policy p_uom_select_public on public.ref_uom_conversion for
select to anon,
    authenticated using (true);
-- (No insert/update/delete policy: normal users cannot modify.
--  Service role bypasses RLS and remains able to write via admin scripts.)