#!/usr/bin/env bash
set -euo pipefail

# --- prerequisites ---
command -v psql >/dev/null || { echo "❌ psql not found in PATH."; exit 1; }

# --- load env ---
if [[ ! -f .env ]]; then
  echo "❌ .env file not found. Please create it with SUPABASE_URL."
  exit 1
fi
set -a
# shellcheck source=/dev/null
source .env
set +a
: "${SUPABASE_URL:?❌ SUPABASE_URL not set in .env}"

# --- output folder ---
today="$(date +%F)"  # YYYY-MM-DD
outdir="data/sample_data/${today}"
mkdir -p "$outdir"

echo "📦 Saving sample CSVs to: $outdir"

# --- helper: sanitize filenames (just in case) ---
sanitize() {
  # lower-case, replace non [a-z0-9._-] with _
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/_/g'
}

# --- get all base tables (exclude system schemas) ---
readarray -t tables < <(
  psql "$SUPABASE_URL" -At -F $'\t' -c "
    select table_schema, table_name
    from information_schema.tables
    where table_type = 'BASE TABLE'
      and table_schema not in ('pg_catalog','information_schema')
    order by table_schema, table_name;
  "
)

# --- export top 5 from each table ---
count=0
for line in "${tables[@]}"; do
  schema="${line%%$'\t'*}"
  table="${line#*$'\t'}"

  fq_name="\"${schema}\".\"${table}\""
  fname="$(sanitize "${schema}.${table}.csv")"
  outfile="${outdir}/${fname}"

  echo "→ ${schema}.${table}  →  ${outfile}"

  # \copy writes to STDOUT; we redirect to file. Header included.
  sql="\\copy (select * from ${fq_name} limit 5) to STDOUT with csv header"
  if ! psql "$SUPABASE_URL" -q -c "$sql" > "$outfile"; then
    echo "   ⚠️  Skipped ${schema}.${table} (query failed)."
    rm -f "$outfile"
    continue
  fi
  ((count++))
done

echo "✅ Done. Exported ${count} table(s) to ${outdir}"
