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