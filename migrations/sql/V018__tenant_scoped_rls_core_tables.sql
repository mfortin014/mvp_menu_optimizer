-- ============================================
-- V018: Tenant-scoped RLS for core tables
--   - Replace permissive policies with tenant-scoped policies
--   - Uses auth.uid() and user_tenant_memberships to verify access
--   - Implements V010 plan for JWT-based tenant isolation
-- ============================================

-- Helper function to check if user has access to a tenant
-- This is used by RLS policies to verify tenant membership
create or replace function public.user_has_tenant_access(p_tenant_id uuid)
returns boolean
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  -- Check if current user (auth.uid()) has an active membership for this tenant
  return exists (
    select 1
    from public.user_tenant_memberships
    where user_id = auth.uid()
      and tenant_id = p_tenant_id
      and is_active = true
      and deleted_at is null
  );
end;
$$;

comment on function public.user_has_tenant_access(uuid) is 'Checks if the current authenticated user has access to a tenant via user_tenant_memberships';

-- Helper function to check if user is admin/owner in a tenant (bypasses RLS)
-- This is used by RLS policies to verify admin status without causing infinite recursion
create or replace function public.user_is_tenant_admin(p_tenant_id uuid)
returns boolean
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  -- Check if current user (auth.uid()) is admin/owner for this tenant
  -- Uses security definer to bypass RLS on user_tenant_memberships
  return exists (
    select 1
    from public.user_tenant_memberships
    where user_id = auth.uid()
      and tenant_id = p_tenant_id
      and role in ('admin', 'owner')
      and is_active = true
      and deleted_at is null
  );
end;
$$;

comment on function public.user_is_tenant_admin(uuid) is 'Checks if the current user is admin/owner in a tenant (bypasses RLS to avoid recursion)';

-- ============================================
-- Ingredients
-- ============================================
drop policy if exists p_select_all_ingredients on public.ingredients;
drop policy if exists p_modify_all_ingredients on public.ingredients;

create policy "ingredients_select_by_tenant"
  on public.ingredients for select
  using (
    user_has_tenant_access(tenant_id)
    and (deleted_at is null)
  );

create policy "ingredients_modify_by_tenant"
  on public.ingredients for all
  using (user_has_tenant_access(tenant_id))
  with check (user_has_tenant_access(tenant_id));

-- ============================================
-- Recipes
-- ============================================
drop policy if exists p_select_all_recipes on public.recipes;
drop policy if exists p_modify_all_recipes on public.recipes;

create policy "recipes_select_by_tenant"
  on public.recipes for select
  using (
    user_has_tenant_access(tenant_id)
    and (deleted_at is null)
  );

create policy "recipes_modify_by_tenant"
  on public.recipes for all
  using (user_has_tenant_access(tenant_id))
  with check (user_has_tenant_access(tenant_id));

-- ============================================
-- Recipe Lines
-- ============================================
drop policy if exists p_select_all_recipe_lines on public.recipe_lines;
drop policy if exists p_modify_all_recipe_lines on public.recipe_lines;

create policy "recipe_lines_select_by_tenant"
  on public.recipe_lines for select
  using (
    user_has_tenant_access(tenant_id)
    and (deleted_at is null)
  );

create policy "recipe_lines_modify_by_tenant"
  on public.recipe_lines for all
  using (user_has_tenant_access(tenant_id))
  with check (user_has_tenant_access(tenant_id));

-- ============================================
-- Sales
-- ============================================
drop policy if exists p_select_all_sales on public.sales;
drop policy if exists p_modify_all_sales on public.sales;

create policy "sales_select_by_tenant"
  on public.sales for select
  using (
    user_has_tenant_access(tenant_id)
    and (deleted_at is null)
  );

create policy "sales_modify_by_tenant"
  on public.sales for all
  using (user_has_tenant_access(tenant_id))
  with check (user_has_tenant_access(tenant_id));

-- ============================================
-- Ref Ingredient Categories (tenant-scoped)
-- ============================================
drop policy if exists p_select_all_refcat on public.ref_ingredient_categories;
drop policy if exists p_modify_all_refcat on public.ref_ingredient_categories;

create policy "ref_ingredient_categories_select_by_tenant"
  on public.ref_ingredient_categories for select
  using (
    user_has_tenant_access(tenant_id)
    and (deleted_at is null)
  );

create policy "ref_ingredient_categories_modify_by_tenant"
  on public.ref_ingredient_categories for all
  using (user_has_tenant_access(tenant_id))
  with check (user_has_tenant_access(tenant_id));

-- ============================================
-- Ref Storage Type (tenant-scoped)
-- ============================================
drop policy if exists p_select_all_refstore on public.ref_storage_type;
drop policy if exists p_modify_all_refstore on public.ref_storage_type;

create policy "ref_storage_type_select_by_tenant"
  on public.ref_storage_type for select
  using (
    user_has_tenant_access(tenant_id)
    and (deleted_at is null)
  );

create policy "ref_storage_type_modify_by_tenant"
  on public.ref_storage_type for all
  using (user_has_tenant_access(tenant_id))
  with check (user_has_tenant_access(tenant_id));

-- ============================================
-- User Tenant Memberships
-- ============================================
drop policy if exists p_select_all_memberships on public.user_tenant_memberships;
drop policy if exists p_modify_all_memberships on public.user_tenant_memberships;

-- Users can view their own memberships
create policy "user_tenant_memberships_select_own"
  on public.user_tenant_memberships for select
  using (user_id = auth.uid());

-- Admins can view all memberships in their tenants
-- (This allows admins to manage users, but RLS still restricts to their tenants)
-- Uses helper function to avoid infinite recursion
create policy "user_tenant_memberships_select_tenant_admin"
  on public.user_tenant_memberships for select
  using (user_is_tenant_admin(tenant_id));

-- Only admins/owners can modify memberships
-- Uses helper function to avoid infinite recursion
create policy "user_tenant_memberships_modify_admin"
  on public.user_tenant_memberships for all
  using (user_is_tenant_admin(tenant_id))
  with check (user_is_tenant_admin(tenant_id));

-- ============================================
-- Tenants
-- ============================================
drop policy if exists tenants_select_all on public.tenants;
drop policy if exists tenants_write_all on public.tenants;

-- Users can view tenants they have access to
create policy "tenants_select_by_membership"
  on public.tenants for select
  using (
    exists (
      select 1
      from public.user_tenant_memberships
      where user_id = auth.uid()
        and tenant_id = tenants.id
        and is_active = true
        and deleted_at is null
    )
  );

-- Only admins/owners can modify tenants
create policy "tenants_modify_admin"
  on public.tenants for all
  using (
    exists (
      select 1
      from public.user_tenant_memberships
      where user_id = auth.uid()
        and tenant_id = tenants.id
        and role in ('admin', 'owner')
        and is_active = true
        and deleted_at is null
    )
  )
  with check (
    exists (
      select 1
      from public.user_tenant_memberships
      where user_id = auth.uid()
        and tenant_id = tenants.id
        and role in ('admin', 'owner')
        and is_active = true
        and deleted_at is null
    )
  );

-- ============================================
-- Note: ref_uom_conversion remains global (no tenant_id)
-- Keep existing permissive policy or make it public-readable
-- ============================================
-- ref_uom_conversion is global, so we keep a permissive read policy
-- but restrict writes to authenticated users
drop policy if exists p_select_all_uom on public.ref_uom_conversion;
drop policy if exists p_modify_all_uom on public.ref_uom_conversion;

create policy "ref_uom_conversion_select_all"
  on public.ref_uom_conversion for select
  using (true);

create policy "ref_uom_conversion_modify_authenticated"
  on public.ref_uom_conversion for all
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

