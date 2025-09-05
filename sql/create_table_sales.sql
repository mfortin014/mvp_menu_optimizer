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