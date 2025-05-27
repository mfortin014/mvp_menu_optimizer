create table public.recipe_lines (
  id uuid primary key default uuid_generate_v4(),
  recipe_id uuid references public.recipes(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id) on delete restrict,
  qty numeric,
  qty_uom text,
  note text,
  updated_at timestamp with time zone default now()
);