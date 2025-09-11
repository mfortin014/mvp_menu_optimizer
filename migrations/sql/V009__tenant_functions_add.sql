-- ============================================
-- V009: Add tenant-aware helper functions
--       (wrappers over the new views).
-- ============================================

-- Get a summary row for a SERVICE recipe (by tenant + id)
create or replace function public.get_recipe_details_mt(p_tenant uuid, p_recipe_id uuid)
returns table (
  tenant_id uuid,
  recipe_id uuid,
  recipe_code text,
  name text,
  status text,
  price numeric,
  total_cost numeric,
  cost_pct numeric,
  margin numeric
) language sql stable as $$
  select *
  from public.recipe_summary
  where tenant_id = p_tenant
    and recipe_id = p_recipe_id
$$;

-- Compute unit costs for all selectable inputs (ingredients + prep recipes)
-- so the UI can bind a cost table without bespoke joins.
create or replace function public.get_unit_costs_for_inputs_mt(p_tenant uuid)
returns table (
  tenant_id uuid,
  input_id uuid,
  source text,
  code text,
  name text,
  base_uom text,
  unit_cost numeric
) language sql stable as $$
  with ic as (
    select
      i.tenant_id,
      i.id as input_id,
      'ingredient'::text as source,
      i.ingredient_code as code,
      i.name,
      i.base_uom,
      c.unit_cost
    from public.ingredients i
    left join public.ingredient_costs c
      on c.ingredient_id = i.id
     and c.tenant_id = i.tenant_id
    where i.deleted_at is null
  ),
  pc as (
    select
      r.tenant_id,
      r.id as input_id,
      'recipe'::text as source,
      r.recipe_code as code,
      r.name,
      p.base_uom,
      p.unit_cost
    from public.recipes r
    join public.prep_costs p
      on p.recipe_id = r.id
     and p.tenant_id = r.tenant_id
    where r.recipe_type = 'prep'
      and r.deleted_at is null
  )
  select * from ic where tenant_id = p_tenant
  union all
  select * from pc where tenant_id = p_tenant
$$;
