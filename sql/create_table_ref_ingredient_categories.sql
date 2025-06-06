create table public.ref_ingredient_categories (
  id uuid not null default gen_random_uuid (),
  name text not null,
  status text null default 'Active'::text,
  constraint ref_ingredient_categories_pkey primary key (id),
  constraint ref_ingredient_categories_name_key unique (name)
) TABLESPACE pg_default;