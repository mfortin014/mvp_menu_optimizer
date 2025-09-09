-- V004__uniques_and_indexes.sql
create unique index if not exists ux_ingredients_tenant_code on public.ingredients(tenant_id, ingredient_code);
create unique index if not exists ux_recipes_tenant_code on public.recipes(tenant_id, recipe_code);
create index if not exists idx_recipe_lines_tenant_recipe on public.recipe_lines(tenant_id, recipe_id);
create index if not exists idx_recipe_lines_tenant_ingredient on public.recipe_lines(tenant_id, ingredient_id);
create index if not exists idx_sales_tenant_recipe on public.sales(tenant_id, recipe_id);