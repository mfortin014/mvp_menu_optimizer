-- 1. Create 'recipes' table
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

-- 2. Create 'recipe_lines' table
create table public.recipe_lines (
  id uuid primary key default uuid_generate_v4(),
  recipe_id uuid references public.recipes(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id) on delete restrict,
  qty numeric,
  qty_uom text,
  note text,
  updated_at timestamp with time zone default now()
);

-- 3. Add update trigger for 'updated_at'
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

create trigger set_updated_at
before update on public.recipes
for each row
execute procedure update_updated_at_column();

create trigger set_updated_at
before update on public.recipe_lines
for each row
execute procedure update_updated_at_column();

-- 4. Enable Row-Level Security (RLS)
alter table public.recipes enable row level security;
alter table public.recipe_lines enable row level security;

-- 5. Add permissive RLS policies for MVP (adjust later)
create policy "Allow all" on public.recipes
  for all using (true);

create policy "Allow all" on public.recipe_lines
  for all using (true);
