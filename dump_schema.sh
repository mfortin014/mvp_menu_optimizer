#!/usr/bin/env bash
set -euo pipefail

# Ensure dependencies
command -v pg_dump >/dev/null || { echo "❌ pg_dump not found in PATH."; exit 1; }

# Ensure .env file exists
if [[ ! -f .env ]]; then
  echo "❌ .env file not found. Please create it with your DATABASE_URL."
  exit 1
fi

# Load env (supports quoted values)
set -a
# shellcheck source=/dev/null
source .env
set +a

: "${DATABASE_URL:?❌ DATABASE_URL not set in .env}"

# Create schema directory if it doesn't exist
mkdir -p schema

# Build dated, incremented filename
today="$(date +%F)"             # e.g. 2025-09-04
idx=1
outfile="$(printf "schema/supabase_schema_%s_%02d.sql" "$today" "$idx")"
while [[ -e "$outfile" ]]; do
  ((idx++))
  outfile="$(printf "schema/supabase_schema_%s_%02d.sql" "$today" "$idx")"
done

echo "🔄 Dumping Supabase schema to $outfile ..."
pg_dump "$DATABASE_URL" \
  --schema-only \
  --no-owner \
  --no-privileges \
  --file="$outfile"

echo "✅ Schema successfully exported."
echo "📄 File: $outfile"
