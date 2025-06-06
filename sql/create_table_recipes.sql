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