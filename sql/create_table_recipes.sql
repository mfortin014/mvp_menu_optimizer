create table public.recipes (
  id uuid primary key default uuid_generate_v4(),
  recipe_code text not null,
  name text not null,
  status text default 'Active',
  base_yield_qty numeric,
  base_yield_uom text,
  price numeric,
  updated_at timestamp with time zone default now()
);