-- V011: tenant branding + default client
alter table public.tenants
add column if not exists logo_url text,
    add column if not exists brand_primary text,
    add column if not exists brand_secondary text,
    add column if not exists is_default boolean not null default false;
-- Enforce at most one default client
create unique index if not exists ux_tenants_single_default on public.tenants (is_default)
where is_default;
-- Optional: ensure only active tenants may be set as default (business rule)
-- create policy or trigger later if you want; for now we trust the UI.