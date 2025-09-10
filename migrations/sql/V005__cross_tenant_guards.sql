
create or replace function public.enforce_same_tenant_recipe_lines()
returns trigger language plpgsql as $$
declare parent_t uuid; ingredient_t uuid;
begin
  select tenant_id into parent_t from public.recipes where id = new.recipe_id;
  select tenant_id into ingredient_t from public.ingredients where id = new.ingredient_id;
  if parent_t is null or ingredient_t is null then return new; end if;
  if new.tenant_id is distinct from parent_t or new.tenant_id is distinct from ingredient_t then
    raise exception 'Cross-tenant reference in recipe_lines';
  end if;
  return new;
end $$;
drop trigger if exists tr_recipe_lines_tenant_guard on public.recipe_lines;
create trigger tr_recipe_lines_tenant_guard
before insert or update on public.recipe_lines
for each row execute function public.enforce_same_tenant_recipe_lines();

create or replace function public.enforce_same_tenant_sales()
returns trigger language plpgsql as $$
declare parent_t uuid;
begin
  select tenant_id into parent_t from public.recipes where id = new.recipe_id;
  if parent_t is null then return new; end if;
  if new.tenant_id is distinct from parent_t then
    raise exception 'Cross-tenant reference in sales';
  end if;
  return new;
end $$;
drop trigger if exists tr_sales_tenant_guard on public.sales;
create trigger tr_sales_tenant_guard
before insert or update on public.sales
for each row execute function public.enforce_same_tenant_sales();
