#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?Set DATABASE_URL}"
echo "Verifying key invariants..."
psql "$DATABASE_URL" -c "select 'tenants' tbl, count(*) from public.tenants;"
psql "$DATABASE_URL" -c "select table_name, column_name from information_schema.columns where table_schema='public' and column_name='tenant_id' order by table_name;"
psql "$DATABASE_URL" -c "select 'ingredients no tenant' as check, count(*) from public.ingredients where tenant_id is null;"
psql "$DATABASE_URL" -c "select 'recipes no tenant' as check, count(*) from public.recipes where tenant_id is null;"
psql "$DATABASE_URL" -c "select 'deleted_at present' as check, count(*) from information_schema.columns where table_schema='public' and column_name='deleted_at';"
echo "Done."
