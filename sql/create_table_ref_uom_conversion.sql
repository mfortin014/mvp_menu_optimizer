create table public.ref_uom_conversion (
  from_uom text not null,
  to_uom text not null,
  factor numeric not null,
  constraint ref_uom_conversion_pkey primary key (from_uom, to_uom)
) TABLESPACE pg_default;