
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";
create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  deleted_at timestamptz null
);
create table if not exists public.user_tenant_memberships (
  user_id uuid not null references public.profiles(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  role text not null default 'owner',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  deleted_at timestamptz null,
  primary key (user_id, tenant_id)
);
insert into public.tenants (name, code)
select 'Sur Le Feu', 'SLF'
where not exists (select 1 from public.tenants where code = 'SLF');
