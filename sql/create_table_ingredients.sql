create table if not exists ingredients (
  id uuid primary key default gen_random_uuid(),
  ingredient_code text unique not null,               -- e.g. ING001
  name text not null,                                 -- Display name
  ingredient_type text not null,                      -- 'Bought' or 'Prepped'
  status text default 'Active' check (status in ('Active', 'Inactive')),
  
  package_qty numeric,                                -- Number (e.g. 6)
  package_uom text,                                   -- e.g. g, kg, L
  package_type text,                                  -- Optional (box, tray, bag)
  package_cost numeric,                               -- Total purchase cost

  base_uom text,                                      -- Used in recipes (g, unit, etc)
  std_qty numeric default 100,                        -- Default recipe usage qty
  unit_weight_g numeric,                              -- If base_uom = unit

  yield_qty numeric,                                  -- Only for Prepped ingredients

  message text,                                       -- Optional notes (warnings, substitutions, etc)

  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
