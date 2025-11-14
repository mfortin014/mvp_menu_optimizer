-- ============================================
-- V015: Ingestion job registry & staging layer
--   - Job / file / artifact metadata tables
--   - Staging tables for wizard-managed entities
--   - Tenant guardrails + RPC helper
-- ============================================

-- ============================================
-- Job registry tables
-- ============================================

create table if not exists public.ingestion_jobs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  requested_by uuid,
  preset_code text not null,
  source_system text not null default 'wizard',
  status text not null default 'draft'
    check (status in ('draft','uploading','validating','ready','published','failed','canceled')),
  job_checksum text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  validation_summary jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ingestion_jobs_tenant on public.ingestion_jobs(tenant_id);
create index if not exists idx_ingestion_jobs_status on public.ingestion_jobs(status);
create index if not exists idx_ingestion_jobs_created on public.ingestion_jobs(created_at desc);

drop trigger if exists tr_ingestion_jobs_updated_at on public.ingestion_jobs;
create trigger tr_ingestion_jobs_updated_at
before update on public.ingestion_jobs
for each row execute function public.update_updated_at_column();

create table if not exists public.ingestion_job_files (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  kind text not null,
  file_name text not null,
  bucket_id text not null default 'ingestion-artifacts',
  storage_path text not null,
  checksum text not null,
  byte_length bigint not null default 0,
  content_type text not null default 'text/csv',
  status text not null default 'pending'
    check (status in ('pending','uploading','uploaded','failed')),
  uploaded_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ingestion_job_files_job on public.ingestion_job_files(job_id);
create index if not exists idx_ingestion_job_files_tenant on public.ingestion_job_files(tenant_id);
create unique index if not exists ux_ingestion_job_files_job_kind_file
  on public.ingestion_job_files(job_id, kind, file_name);

drop trigger if exists tr_ingestion_job_files_updated_at on public.ingestion_job_files;
create trigger tr_ingestion_job_files_updated_at
before update on public.ingestion_job_files
for each row execute function public.update_updated_at_column();

create table if not exists public.ingestion_job_artifacts (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  artifact_type text not null,
  label text,
  bucket_id text not null default 'ingestion-artifacts',
  storage_path text not null,
  checksum text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_ingestion_job_artifacts_job on public.ingestion_job_artifacts(job_id);
create index if not exists idx_ingestion_job_artifacts_type on public.ingestion_job_artifacts(artifact_type);

-- ============================================
-- Staging tables (payload + lineage metadata)
-- ============================================

create table if not exists public.stg_component (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  job_file_id uuid references public.ingestion_job_files(id) on delete set null,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  source_system text not null default 'wizard',
  source_row_id text not null,
  source_row_num integer,
  row_checksum text not null,
  payload jsonb not null default '{}'::jsonb,
  provenance jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_stg_component_job_row
  on public.stg_component(job_id, source_row_id);
create index if not exists idx_stg_component_checksum
  on public.stg_component(tenant_id, row_checksum);

create table if not exists public.stg_bom_header (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  job_file_id uuid references public.ingestion_job_files(id) on delete set null,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  source_system text not null default 'wizard',
  source_row_id text not null,
  source_row_num integer,
  row_checksum text not null,
  payload jsonb not null default '{}'::jsonb,
  provenance jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_stg_bom_header_job_row
  on public.stg_bom_header(job_id, source_row_id);
create index if not exists idx_stg_bom_header_checksum
  on public.stg_bom_header(tenant_id, row_checksum);

create table if not exists public.stg_product (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  job_file_id uuid references public.ingestion_job_files(id) on delete set null,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  source_system text not null default 'wizard',
  source_row_id text not null,
  source_row_num integer,
  row_checksum text not null,
  payload jsonb not null default '{}'::jsonb,
  provenance jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_stg_product_job_row
  on public.stg_product(job_id, source_row_id);
create index if not exists idx_stg_product_checksum
  on public.stg_product(tenant_id, row_checksum);

create table if not exists public.stg_bom_line (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  job_file_id uuid references public.ingestion_job_files(id) on delete set null,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  source_system text not null default 'wizard',
  source_row_id text not null,
  source_row_num integer,
  row_checksum text not null,
  payload jsonb not null default '{}'::jsonb,
  provenance jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_stg_bom_line_job_row
  on public.stg_bom_line(job_id, source_row_id);
create index if not exists idx_stg_bom_line_checksum
  on public.stg_bom_line(tenant_id, row_checksum);

create table if not exists public.stg_party (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  job_file_id uuid references public.ingestion_job_files(id) on delete set null,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  source_system text not null default 'wizard',
  source_row_id text not null,
  source_row_num integer,
  row_checksum text not null,
  payload jsonb not null default '{}'::jsonb,
  provenance jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_stg_party_job_row
  on public.stg_party(job_id, source_row_id);
create index if not exists idx_stg_party_checksum
  on public.stg_party(tenant_id, row_checksum);

create table if not exists public.stg_uom_conversion (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ingestion_jobs(id) on delete cascade,
  job_file_id uuid references public.ingestion_job_files(id) on delete set null,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  source_system text not null default 'wizard',
  source_row_id text not null,
  source_row_num integer,
  row_checksum text not null,
  payload jsonb not null default '{}'::jsonb,
  provenance jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_stg_uom_conversion_job_row
  on public.stg_uom_conversion(job_id, source_row_id);
create index if not exists idx_stg_uom_conversion_checksum
  on public.stg_uom_conversion(tenant_id, row_checksum);

-- ============================================
-- Tenant guard helpers + triggers
-- ============================================

create or replace function public.ingestion_enforce_job_tenant()
returns trigger
language plpgsql
as $$
declare
  job_tenant uuid;
begin
  select tenant_id into job_tenant
  from public.ingestion_jobs
  where id = new.job_id;

  if job_tenant is null then
    raise exception 'Unknown ingestion job %', new.job_id;
  end if;

  if new.tenant_id is null then
    new.tenant_id = job_tenant;
  elsif new.tenant_id is distinct from job_tenant then
    raise exception 'Cross-tenant ingestion reference';
  end if;

  return new;
end;
$$;

create or replace function public.ingestion_enforce_staging_lineage()
returns trigger
language plpgsql
as $$
declare
  job_tenant uuid;
  file_job uuid;
  file_tenant uuid;
begin
  select tenant_id into job_tenant
  from public.ingestion_jobs
  where id = new.job_id;

  if job_tenant is null then
    raise exception 'Unknown ingestion job %', new.job_id;
  end if;

  if new.tenant_id is null then
    new.tenant_id = job_tenant;
  elsif new.tenant_id is distinct from job_tenant then
    raise exception 'Cross-tenant ingestion staging reference (job mismatch)';
  end if;

  if new.job_file_id is not null then
    select job_id, tenant_id into file_job, file_tenant
    from public.ingestion_job_files
    where id = new.job_file_id;

    if file_job is null then
      raise exception 'Unknown ingestion job file %', new.job_file_id;
    end if;

    if file_job is distinct from new.job_id then
      raise exception 'Job file % does not belong to job %', new.job_file_id, new.job_id;
    end if;

    if file_tenant is not null and file_tenant is distinct from new.tenant_id then
      raise exception 'Cross-tenant ingestion staging reference (file mismatch)';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tr_ingestion_job_files_tenant_guard on public.ingestion_job_files;
create trigger tr_ingestion_job_files_tenant_guard
before insert or update on public.ingestion_job_files
for each row execute function public.ingestion_enforce_job_tenant();

drop trigger if exists tr_ingestion_job_artifacts_tenant_guard on public.ingestion_job_artifacts;
create trigger tr_ingestion_job_artifacts_tenant_guard
before insert or update on public.ingestion_job_artifacts
for each row execute function public.ingestion_enforce_job_tenant();

drop trigger if exists tr_stg_component_guard on public.stg_component;
create trigger tr_stg_component_guard
before insert or update on public.stg_component
for each row execute function public.ingestion_enforce_staging_lineage();

drop trigger if exists tr_stg_bom_header_guard on public.stg_bom_header;
create trigger tr_stg_bom_header_guard
before insert or update on public.stg_bom_header
for each row execute function public.ingestion_enforce_staging_lineage();

drop trigger if exists tr_stg_product_guard on public.stg_product;
create trigger tr_stg_product_guard
before insert or update on public.stg_product
for each row execute function public.ingestion_enforce_staging_lineage();

drop trigger if exists tr_stg_bom_line_guard on public.stg_bom_line;
create trigger tr_stg_bom_line_guard
before insert or update on public.stg_bom_line
for each row execute function public.ingestion_enforce_staging_lineage();

drop trigger if exists tr_stg_party_guard on public.stg_party;
create trigger tr_stg_party_guard
before insert or update on public.stg_party
for each row execute function public.ingestion_enforce_staging_lineage();

drop trigger if exists tr_stg_uom_conversion_guard on public.stg_uom_conversion;
create trigger tr_stg_uom_conversion_guard
before insert or update on public.stg_uom_conversion
for each row execute function public.ingestion_enforce_staging_lineage();

-- ============================================
-- Row-level security: tenant isolation
-- ============================================

do $$
declare
  rel text;
  rels text[] := array[
    'ingestion_jobs',
    'ingestion_job_files',
    'ingestion_job_artifacts',
    'stg_component',
    'stg_bom_header',
    'stg_product',
    'stg_bom_line',
    'stg_party',
    'stg_uom_conversion'
  ];
begin
  foreach rel in array rels loop
    execute format('alter table public.%I enable row level security;', rel);
    execute format('alter table public.%I force row level security;', rel);
    execute format('drop policy if exists %I_tenant_rw on public.%I;', rel, rel);
    execute format($fmt$
      create policy %I_tenant_rw
      on public.%I
      for all
      to authenticated
      using (
        tenant_id is not distinct from ((auth.jwt() ->> 'tenant_id')::uuid)
      )
      with check (
        tenant_id is not distinct from ((auth.jwt() ->> 'tenant_id')::uuid)
      );
    $fmt$, rel, rel);
  end loop;
end;
$$;

-- ============================================
-- RPC helper: open an ingestion job + file targets
-- ============================================

create or replace function public.ingestion_open_job(
  p_tenant_id uuid,
  p_preset text,
  p_files jsonb default '[]'::jsonb,
  p_actor uuid default null,
  p_source text default 'wizard'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job_id uuid;
  v_bucket text := 'ingestion-artifacts';
  v_files jsonb := '[]'::jsonb;
  v_checksum text;
  caller_tenant uuid;
begin
  -- Ensure callers can only open jobs for their tenant unless using the service role.
  if auth.role() is distinct from 'service_role' then
    caller_tenant := (auth.jwt() ->> 'tenant_id')::uuid;
    if caller_tenant is null or caller_tenant is distinct from p_tenant_id then
      raise exception 'Tenant mismatch for ingestion job';
    end if;
  end if;

  with file_checks as (
    select coalesce(value->>'checksum', '') as checksum
    from jsonb_array_elements(coalesce(p_files, '[]'::jsonb)) as value
  )
  select encode(
      digest(coalesce(string_agg(checksum, ',' order by checksum), ''), 'sha256'),
      'hex'
    )
  into v_checksum
  from file_checks;

  if v_checksum is null then
    v_checksum := encode(digest('', 'sha256'), 'hex');
  end if;

  insert into public.ingestion_jobs (
    tenant_id,
    requested_by,
    preset_code,
    source_system,
    status,
    job_checksum
  )
  values (
    p_tenant_id,
    p_actor,
    p_preset,
    coalesce(nullif(p_source, ''), 'wizard'),
    'uploading',
    v_checksum
  )
  returning id into v_job_id;

  with payload as (
    select
      coalesce(value->>'kind', 'component') as kind,
      coalesce(
        value->>'file_name',
        value->>'filename',
        format('%s.csv', coalesce(value->>'kind', 'component'))
      ) as file_name,
      coalesce(value->>'checksum', '') as checksum,
      coalesce(value->>'content_type', 'text/csv') as content_type,
      coalesce((value->>'byte_length')::bigint, 0) as byte_length
    from jsonb_array_elements(coalesce(p_files, '[]'::jsonb)) as value
  ),
  inserted as (
    insert into public.ingestion_job_files (
      job_id,
      tenant_id,
      kind,
      file_name,
      storage_path,
      checksum,
      content_type,
      byte_length,
      bucket_id,
      status
    )
    select
      v_job_id,
      p_tenant_id,
      kind,
      file_name,
      format(
        'tenants/%s/ingestion/%s/%s/%s',
        p_tenant_id,
        v_job_id,
        kind,
        gen_random_uuid() || '-' || file_name
      ),
      checksum,
      content_type,
      byte_length,
      v_bucket,
      'pending'
    from payload
    returning
      id,
      kind,
      file_name,
      storage_path,
      checksum,
      byte_length,
      content_type
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'file_id', id,
      'kind', kind,
      'file_name', file_name,
      'storage_path', storage_path,
      'checksum', checksum,
      'byte_length', byte_length,
      'content_type', content_type,
      'bucket', v_bucket
    )
  ), '[]'::jsonb)
  into v_files
  from inserted;

  return jsonb_build_object(
    'job_id', v_job_id,
    'tenant_id', p_tenant_id,
    'files', coalesce(v_files, '[]'::jsonb)
  );
end;
$$;

grant execute on function public.ingestion_open_job(uuid, text, jsonb, uuid, text)
  to authenticated, service_role;
