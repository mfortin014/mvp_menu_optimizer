
-- V006__rls_enable_and_policies.sql

-- Enable RLS on owned tables
alter table public.ingredients enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_lines enable row level security;
alter table public.ref_ingredient_categories enable row level security;
alter table public.ref_storage_type enable row level security;
alter table public.ref_uom_conversion enable row level security;
alter table public.sales enable row level security;
alter table public.tenants enable row level security;
alter table public.user_tenant_memberships enable row level security;

-- Minimal permissive policies for MVP (service role bypasses these anyway).
do $$ begin
  perform 1;
exception when others then null;
end $$;

create policy if not exists p_select_all_ingredients on public.ingredients for select using (true);
create policy if not exists p_modify_all_ingredients on public.ingredients for all using (true) with check (true);

create policy if not exists p_select_all_recipes on public.recipes for select using (true);
create policy if not exists p_modify_all_recipes on public.recipes for all using (true) with check (true);

create policy if not exists p_select_all_recipe_lines on public.recipe_lines for select using (true);
create policy if not exists p_modify_all_recipe_lines on public.recipe_lines for all using (true) with check (true);

create policy if not exists p_select_all_refcat on public.ref_ingredient_categories for select using (true);
create policy if not exists p_modify_all_refcat on public.ref_ingredient_categories for all using (true) with check (true);

create policy if not exists p_select_all_refstore on public.ref_storage_type for select using (true);
create policy if not exists p_modify_all_refstore on public.ref_storage_type for all using (true) with check (true);

create policy if not exists p_select_all_uom on public.ref_uom_conversion for select using (true);
create policy if not exists p_modify_all_uom on public.ref_uom_conversion for all using (true) with check (true);

create policy if not exists p_select_all_sales on public.sales for select using (true);
create policy if not exists p_modify_all_sales on public.sales for all using (true) with check (true);

create policy if not exists p_select_all_tenants on public.tenants for select using (true);
create policy if not exists p_modify_all_tenants on public.tenants for all using (true) with check (true);

create policy if not exists p_select_all_memberships on public.user_tenant_memberships for select using (true);
create policy if not exists p_modify_all_memberships on public.user_tenant_memberships for all using (true) with check (true);
