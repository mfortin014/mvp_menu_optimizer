-- V002__add_tenant_id.sql
do $$ begin
  -- Fetch default tenant id
  if not exists (select 1 from public.tenants where code = 'SLF') then
    insert into public.tenants (name, code) values ('Sur Le Feu','SLF');
  end if;
end $$;

-- public.ingredients
alter table public.ingredients add column if not exists tenant_id uuid;
update public.ingredients set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.ingredients alter column tenant_id set not null;
alter table public.ingredients add constraint ingredients_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_ingredients_tenant on public.ingredients(tenant_id);

-- public.ref_uom_conversion
alter table public.ref_uom_conversion add column if not exists tenant_id uuid;
update public.ref_uom_conversion set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.ref_uom_conversion alter column tenant_id set not null;
alter table public.ref_uom_conversion add constraint ref_uom_conversion_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_ref_uom_conversion_tenant on public.ref_uom_conversion(tenant_id);

-- public.recipes
alter table public.recipes add column if not exists tenant_id uuid;
update public.recipes set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.recipes alter column tenant_id set not null;
alter table public.recipes add constraint recipes_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_recipes_tenant on public.recipes(tenant_id);

-- public.recipe_lines
alter table public.recipe_lines add column if not exists tenant_id uuid;
update public.recipe_lines set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.recipe_lines alter column tenant_id set not null;
alter table public.recipe_lines add constraint recipe_lines_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_recipe_lines_tenant on public.recipe_lines(tenant_id);

-- public.ref_ingredient_categories
alter table public.ref_ingredient_categories add column if not exists tenant_id uuid;
update public.ref_ingredient_categories set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.ref_ingredient_categories alter column tenant_id set not null;
alter table public.ref_ingredient_categories add constraint ref_ingredient_categories_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_ref_ingredient_categories_tenant on public.ref_ingredient_categories(tenant_id);

-- public.ref_storage_type
alter table public.ref_storage_type add column if not exists tenant_id uuid;
update public.ref_storage_type set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.ref_storage_type alter column tenant_id set not null;
alter table public.ref_storage_type add constraint ref_storage_type_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_ref_storage_type_tenant on public.ref_storage_type(tenant_id);

-- public.sales
alter table public.sales add column if not exists tenant_id uuid;
update public.sales set tenant_id = (select id from public.tenants where code = 'SLF') where tenant_id is null;
alter table public.sales alter column tenant_id set not null;
alter table public.sales add constraint sales_tenant_fk foreign key (tenant_id) references public.tenants(id) on delete restrict;
create index if not exists idx_sales_tenant on public.sales(tenant_id);