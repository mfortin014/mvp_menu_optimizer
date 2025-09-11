-- ============================================
-- V007: Fix global uniques, make UOM conversions global,
--       and rebuild tenant + soft-delete aware views.
-- ============================================

-- 1) Drop residual global uniques; enforce per-tenant uniques (partial on non-deleted)

-- Ingredients codes
alter table public.ingredients
  drop constraint if exists ingredients_ingredient_code_key;
drop index if exists public.ingredients_ingredient_code_key;
create unique index if not exists ux_ingredients_tenant_code_active
  on public.ingredients (tenant_id, ingredient_code)
  where deleted_at is null;

-- Recipes codes
alter table public.recipes
  drop constraint if exists recipes_recipe_code_key;
drop index if exists public.recipes_recipe_code_key;
create unique index if not exists ux_recipes_tenant_code_active
  on public.recipes (tenant_id, recipe_code)
  where deleted_at is null;

-- Ref tables: names per-tenant unique (active only)
alter table public.ref_ingredient_categories
  drop constraint if exists ref_ingredient_categories_name_key;
drop index if exists public.ref_ingredient_categories_name_key;
create unique index if not exists ux_ref_ingredient_categories_tenant_name_active
  on public.ref_ingredient_categories (tenant_id, name)
  where deleted_at is null;

alter table public.ref_storage_type
  drop constraint if exists ref_storage_type_name_key;
drop index if exists public.ref_storage_type_name_key;
create unique index if not exists ux_ref_storage_type_tenant_name_active
  on public.ref_storage_type (tenant_id, name)
  where deleted_at is null;

-- 2) Make UOM conversions GLOBAL (shared by all tenants)

-- If table currently has tenant_id: drop it (and dependent indexes) safely
alter table public.ref_uom_conversion
  drop constraint if exists ref_uom_conversion_pkey;
-- drop any per-tenant unique index if it exists
drop index if exists public.ux_ref_uom_conversion_tenant_from_to;

-- Column drop is safe even if it doesn't exist in some environments
alter table public.ref_uom_conversion
  drop column if exists tenant_id;

-- Rebuild primary key as global pair
alter table public.ref_uom_conversion
  add constraint ref_uom_conversion_pkey primary key (from_uom, to_uom);

-- Optional: keep deleted_at for administrative hiding
-- Make sure there's no RLS that blocks global reads (we'll handle policies in V008)

-- 3) Rebuild views (tenant + soft-delete aware; conversions global)

-- Ingredient costs in base units
create or replace view public.ingredient_costs as
select
  i.tenant_id,
  i.id as ingredient_id,
  i.ingredient_code,
  i.name,
  i.package_qty,
  i.package_uom,
  i.base_uom,
  i.package_cost,
  i.yield_pct,
  -- net qty after yield
  (i.package_qty * (i.yield_pct / 100.0)) as package_qty_net,
  -- conversion factor to base_uom (1.0 when same UOM or missing row)
  coalesce(
    case when i.package_uom = i.base_uom then 1.0
         else c.factor end,
    null
  ) as conversion_factor,
  case
    when i.package_uom = i.base_uom then (i.package_qty * (i.yield_pct / 100.0))
    when c.factor is not null then (i.package_qty * (i.yield_pct / 100.0)) * c.factor
    else null
  end as package_qty_net_base_unit,
  case
    when i.package_uom = i.base_uom and i.package_qty > 0
      then i.package_cost / (i.package_qty * (i.yield_pct / 100.0))
    when c.factor is not null and (i.package_qty * (i.yield_pct / 100.0) * c.factor) > 0
      then i.package_cost / ((i.package_qty * (i.yield_pct / 100.0)) * c.factor)
    else null
  end as unit_cost
from public.ingredients i
left join public.ref_uom_conversion c
  on i.package_uom = c.from_uom
 and i.base_uom    = c.to_uom
where i.deleted_at is null;

-- Catalog of possible inputs: ingredients + PREP recipes only
create or replace view public.input_catalog as
select i.tenant_id, i.id, i.ingredient_code as code, i.name, 'ingredient'::text as source
from public.ingredients i
where i.status = 'Active' and i.deleted_at is null
union all
select r.tenant_id, r.id, r.recipe_code as code, r.name, 'recipe'::text as source
from public.recipes r
where r.status = 'Active' and r.recipe_type = 'prep' and r.deleted_at is null;

-- Base line-costs (ingredients only) without prep substitution
create or replace view public.recipe_line_costs_base as
select
  rl.tenant_id,
  rl.id as recipe_line_id,
  rl.recipe_id,
  rl.ingredient_id,
  rl.qty,
  rl.qty_uom,
  i.package_qty,
  i.package_uom,
  i.package_cost,
  i.yield_pct,
  case
    when i.id is not null
     and i.package_qty > 0
     and (
       rl.qty_uom = i.package_uom
       or exists (select 1 from public.ref_uom_conversion cu where cu.from_uom = rl.qty_uom and cu.to_uom = i.package_uom)
     )
    then
      case
        when rl.qty_uom = i.package_uom
          then (rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
        else
          (rl.qty * coalesce(
            (select factor from public.ref_uom_conversion cu where cu.from_uom = rl.qty_uom and cu.to_uom = i.package_uom),
            null
          ) / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
      end
    else 0
  end as line_cost
from public.recipe_lines rl
left join public.ingredients i
  on i.id = rl.ingredient_id
 and i.tenant_id = rl.tenant_id
 and i.deleted_at is null
where rl.deleted_at is null;

-- Aggregated unit-cost for prep recipes
create or replace view public.prep_costs as
select
  r.tenant_id,
  r.id as recipe_id,
  r.recipe_code,
  r.name,
  r.yield_qty,
  r.yield_uom,
  sum(coalesce(rlcb.line_cost, 0)) as total_cost,
  coalesce(
    case when r.yield_uom = b.base_uom then 1.0
         else (select factor from public.ref_uom_conversion cu where cu.from_uom = r.yield_uom and cu.to_uom = b.base_uom)
    end, null
  ) as conversion_factor,
  case
    when b.base_uom is not null then b.base_uom
    else r.yield_uom
  end as base_uom,
  case
    when (coalesce(
            case when r.yield_uom = b.base_uom then 1.0
                 else (select factor from public.ref_uom_conversion cu where cu.from_uom = r.yield_uom and cu.to_uom = b.base_uom)
            end, null
         ) * r.yield_qty) > 0
    then sum(coalesce(rlcb.line_cost, 0)) /
         (r.yield_qty * coalesce(
            case when r.yield_uom = b.base_uom then 1.0
                 else (select factor from public.ref_uom_conversion cu where cu.from_uom = r.yield_uom and cu.to_uom = b.base_uom)
            end, null
         ))
    else null
  end as unit_cost
from public.recipes r
left join (
  -- choose a base_uom for the recipe: if all lines use ingredients with package_uom, prefer that; otherwise default to yield_uom
  select rl.recipe_id, rl.tenant_id,
         min(i.base_uom) as base_uom
  from public.recipe_lines rl
  join public.ingredients i
    on i.id = rl.ingredient_id
   and i.tenant_id = rl.tenant_id
   and i.deleted_at is null
  where rl.deleted_at is null
  group by rl.recipe_id, rl.tenant_id
) b
  on b.recipe_id = r.id
 and b.tenant_id = r.tenant_id
left join public.recipe_line_costs_base rlcb
  on rlcb.recipe_id = r.id
 and rlcb.tenant_id = r.tenant_id
where r.recipe_type = 'prep'
  and r.status = 'Active'
  and r.deleted_at is null
group by r.tenant_id, r.id, r.recipe_code, r.name, r.yield_qty, r.yield_uom, b.base_uom;

-- Final line costs: ingredient OR prep substitution
create or replace view public.recipe_line_costs as
select
  rl.tenant_id,
  rl.id as recipe_line_id,
  rl.recipe_id,
  rl.ingredient_id,
  rl.qty,
  rl.qty_uom,
  coalesce(
    -- ingredient path
    case
      when i.id is not null
       and i.package_qty > 0
       and (rl.qty_uom = i.package_uom
            or exists (select 1 from public.ref_uom_conversion cu where cu.from_uom = rl.qty_uom and cu.to_uom = i.package_uom))
      then
        case
          when rl.qty_uom = i.package_uom
            then (rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
          else ((rl.qty * (select factor from public.ref_uom_conversion cu where cu.from_uom = rl.qty_uom and cu.to_uom = i.package_uom))
                 / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
        end
      else null
    end,
    -- prep path
    case
      when pr.id is not null and pc.unit_cost is not null then
        case
          when rl.qty_uom = pc.base_uom then rl.qty * pc.unit_cost
          else (rl.qty * (select factor from public.ref_uom_conversion cu where cu.from_uom = rl.qty_uom and cu.to_uom = pc.base_uom)) * pc.unit_cost
        end
      else null
    end,
    0
  ) as line_cost
from public.recipe_lines rl
left join public.ingredients i
  on i.id = rl.ingredient_id
 and i.tenant_id = rl.tenant_id
 and i.deleted_at is null
left join public.recipes pr
  on pr.id = rl.ingredient_id
 and pr.tenant_id = rl.tenant_id
 and pr.recipe_type = 'prep'
 and pr.deleted_at is null
left join public.prep_costs pc
  on pc.recipe_id = pr.id
 and pc.tenant_id = pr.tenant_id
where rl.deleted_at is null;

-- Summary for service recipes
create or replace view public.recipe_summary as
select
  r.tenant_id,
  r.id as recipe_id,
  r.recipe_code,
  r.name,
  r.status,
  r.price,
  sum(coalesce(rlc.line_cost, 0)) as total_cost,
  case when r.price > 0 then round((sum(coalesce(rlc.line_cost, 0)) / r.price) * 100.0, 2) else null end as cost_pct,
  case when r.price > 0 then round(r.price - sum(coalesce(rlc.line_cost, 0)), 2) else null end as margin
from public.recipes r
left join public.recipe_line_costs rlc
  on rlc.recipe_id = r.id
 and rlc.tenant_id = r.tenant_id
where r.status = 'Active'
  and r.recipe_type = 'service'
  and r.deleted_at is null
group by r.tenant_id, r.id, r.recipe_code, r.name, r.status, r.price;

-- Missing conversions (global)
create or replace view public.missing_uom_conversions as
select
  rl.tenant_id,
  rl.id as recipe_line_id,
  r.name as recipe,
  i.name as ingredient,
  rl.qty_uom,
  i.package_uom
from public.recipe_lines rl
join public.recipes r
  on r.id = rl.recipe_id
 and r.tenant_id = rl.tenant_id
 and r.deleted_at is null
join public.ingredients i
  on i.id = rl.ingredient_id
 and i.tenant_id = rl.tenant_id
 and i.deleted_at is null
left join public.ref_uom_conversion c
  on rl.qty_uom = c.from_uom
 and i.package_uom = c.to_uom
where rl.deleted_at is null
  and rl.qty_uom <> i.package_uom
  and c.from_uom is null;
