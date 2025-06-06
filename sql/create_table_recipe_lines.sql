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