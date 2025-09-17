-- ============================================
-- V008: Cross-tenant guards (recipes-as-ingredients, ingredient refs)
--       + permissive RLS on tenants & memberships for MVP.
-- ============================================

-- 1) Cross-tenant guard for recipe_lines (ingredient OR prep recipe)
create or replace function public.enforce_same_tenant_recipe_lines()
returns trigger language plpgsql as $$
declare parent_t uuid; ing_t uuid; prep_t uuid;
begin
  select tenant_id into parent_t from public.recipes where id = new.recipe_id;

  select tenant_id into ing_t from public.ingredients where id = new.ingredient_id;
  if ing_t is null then
    select tenant_id into prep_t from public.recipes where id = new.ingredient_id and recipe_type = 'prep';
  end if;

  if parent_t is not null and new.tenant_id is distinct from parent_t then
    raise exception 'Cross-tenant reference (parent recipe)';
  end if;

  if ing_t is not null and new.tenant_id is distinct from ing_t then
    raise exception 'Cross-tenant reference (ingredient)';
  end if;

  if prep_t is not null and new.tenant_id is distinct from prep_t then
    raise exception 'Cross-tenant reference (prep recipe)';
  end if;

  return new;
end $$;

drop trigger if exists tr_recipe_lines_tenant_guard on public.recipe_lines;
create trigger tr_recipe_lines_tenant_guard
before insert or update on public.recipe_lines
for each row execute function public.enforce_same_tenant_recipe_lines();

-- 2) Guard ingredient.category_id and ingredient.storage_type_id to same tenant
create or replace function public.enforce_same_tenant_ingredient_refs()
returns trigger language plpgsql as $$
declare cat_t uuid; st_t uuid;
begin
  if new.category_id is not null then
    select tenant_id into cat_t from public.ref_ingredient_categories where id = new.category_id;
    if cat_t is not null and new.tenant_id is distinct from cat_t then
      raise exception 'Cross-tenant reference: ingredient.category_id';
    end if;
  end if;

  if new.storage_type_id is not null then
    select tenant_id into st_t from public.ref_storage_type where id = new.storage_type_id;
    if st_t is not null and new.tenant_id is distinct from st_t then
      raise exception 'Cross-tenant reference: ingredient.storage_type_id';
    end if;
  end if;

  return new;
end $$;

drop trigger if exists tr_ingredients_tenant_guard on public.ingredients;
create trigger tr_ingredients_tenant_guard
before insert or update on public.ingredients
for each row execute function public.enforce_same_tenant_ingredient_refs();

-- 3) Ensure RLS is enabled on tenants and user_tenant_memberships with permissive policies for MVP

alter table public.tenants enable row level security;
alter table public.user_tenant_memberships enable row level security;

-- cleanup any old policies to avoid duplicates
drop policy if exists tenants_select_all on public.tenants;
drop policy if exists tenants_write_all on public.tenants;
drop policy if exists memberships_select_all on public.user_tenant_memberships;
drop policy if exists memberships_write_all on public.user_tenant_memberships;

create policy tenants_select_all
on public.tenants
for select using (true);

create policy tenants_write_all
on public.tenants
for all using (true) with check (true);

create policy memberships_select_all
on public.user_tenant_memberships
for select using (true);

create policy memberships_write_all
on public.user_tenant_memberships
for all using (true) with check (true);
