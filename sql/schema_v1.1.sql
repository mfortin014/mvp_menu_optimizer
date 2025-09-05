create table public.ingredients (
  id uuid not null default gen_random_uuid (),
  ingredient_code text not null,
  name text not null,
  ingredient_type text not null,
  status text null default 'Active'::text,
  package_qty numeric null,
  package_uom text null,
  package_type text null,
  package_cost numeric null,
  unit_weight_g numeric null,
  message text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  yield_pct numeric not null default 100.0,
  category_id uuid null,
  constraint ingredients_pkey primary key (id),
  constraint ingredients_ingredient_code_key unique (ingredient_code),
  constraint ingredients_category_id_fkey foreign KEY (category_id) references ref_ingredient_categories (id),
  constraint ingredients_status_check check (
    (
      status = any (array['Active'::text, 'Inactive'::text])
    )
  )
) TABLESPACE pg_default;

create trigger update_ingredients_updated_at BEFORE
update on ingredients for EACH row
execute FUNCTION set_updated_at ();

create table public.recipe_lines (
  id uuid not null default extensions.uuid_generate_v4 (),
  recipe_id uuid null,
  ingredient_id uuid null,
  qty numeric null,
  qty_uom text null,
  note text null,
  updated_at timestamp with time zone null default now(),
  constraint recipe_lines_pkey primary key (id),
  constraint recipe_lines_ingredient_id_fkey foreign KEY (ingredient_id) references ingredients (id) on delete RESTRICT,
  constraint recipe_lines_recipe_id_fkey foreign KEY (recipe_id) references recipes (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger set_updated_at BEFORE
update on recipe_lines for EACH row
execute FUNCTION update_updated_at_column ();

create table public.recipes (
  id uuid not null default extensions.uuid_generate_v4 (),
  recipe_code text not null,
  name text not null,
  status text null default 'Active'::text,
  base_yield_qty numeric null,
  base_yield_uom text null,
  price numeric null,
  updated_at timestamp with time zone null default now(),
  constraint recipes_pkey primary key (id)
) TABLESPACE pg_default;

create trigger set_updated_at BEFORE
update on recipes for EACH row
execute FUNCTION update_updated_at_column ();

create table public.ref_ingredient_categories (
  id uuid not null default gen_random_uuid (),
  name text not null,
  status text null default 'Active'::text,
  constraint ref_ingredient_categories_pkey primary key (id),
  constraint ref_ingredient_categories_name_key unique (name)
) TABLESPACE pg_default;

create table public.ref_uom_conversion (
  from_uom text not null,
  to_uom text not null,
  factor numeric not null,
  constraint ref_uom_conversion_pkey primary key (from_uom, to_uom)
) TABLESPACE pg_default;

create table public.sales (
  id uuid not null default extensions.uuid_generate_v4 (),
  recipe_id uuid null,
  sale_date date not null,
  qty numeric not null,
  list_price numeric null,
  discount numeric null,
  net_price numeric null,
  created_at timestamp without time zone null default now(),
  constraint sales_pkey primary key (id),
  constraint sales_recipe_id_fkey foreign KEY (recipe_id) references recipes (id) on delete CASCADE
) TABLESPACE pg_default;

create view public.missing_uom_conversions as
select
  rl.id as recipe_line_id,
  r.name as recipe,
  i.name as ingredient,
  rl.qty_uom,
  i.package_uom
from
  recipe_lines rl
  join recipes r on r.id = rl.recipe_id
  join ingredients i on i.id = rl.ingredient_id
  left join ref_uom_conversion c on rl.qty_uom = c.from_uom
  and i.package_uom = c.to_uom
where
  c.factor is null;

  create view public.recipe_line_costs as
select
  rl.id as recipe_line_id,
  rl.recipe_id,
  rl.ingredient_id,
  rl.qty,
  rl.qty_uom,
  i.package_qty,
  i.package_uom,
  i.package_cost,
  i.ingredient_type,
  i.yield_pct,
  case
    when i.package_qty > 0::numeric
    and (
      rl.qty_uom = i.package_uom
      or c.factor is not null
    ) then case
      when rl.qty_uom = i.package_uom then rl.qty / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
      else rl.qty * c.factor / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
    end
    else 0::numeric
  end as line_cost
from
  recipe_lines rl
  left join ingredients i on i.id = rl.ingredient_id
  left join ref_uom_conversion c on rl.qty_uom = c.from_uom
  and i.package_uom = c.to_uom;

  create view public.recipe_summary as
select
  r.id as recipe_id,
  r.name as recipe,
  r.price,
  COALESCE(sum(rlc.line_cost), 0::numeric) as cost,
  r.price - COALESCE(sum(rlc.line_cost), 0::numeric) as margin_dollar,
  case
    when r.price > 0::numeric then (
      r.price - COALESCE(sum(rlc.line_cost), 0::numeric)
    ) / r.price
    else 0::numeric
  end as profitability,
  COALESCE(s.total_units_sold, 0::numeric) as popularity
from
  recipes r
  left join recipe_line_costs rlc on rlc.recipe_id = r.id
  left join (
    select
      sales.recipe_id,
      sum(sales.qty) as total_units_sold
    from
      sales
    group by
      sales.recipe_id
  ) s on s.recipe_id = r.id
group by
  r.id,
  r.name,
  r.price,
  s.total_units_sold;

--function get_recipe_details
select
    i.name as ingredient,
    rl.qty,
    rl.qty_uom,
    i.ingredient_type,
    i.package_qty,
    i.package_uom,
    i.package_cost,
    i.yield_pct,
    case
        when i.package_qty > 0 and i.yield_pct > 0
        then (rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
        else 0
    end as line_cost
from recipe_lines rl
join ingredients i on rl.ingredient_id = i.id
where rl.recipe_id = rid

--function set_updated_at
begin
  new.updated_at = now();
  return new;
end;

--function update_updated_at_column

begin
  new.updated_at = now();
  return new;
end;
