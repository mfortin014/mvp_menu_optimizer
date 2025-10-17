#!/bin/bash
set -euo pipefail

# Load DATABASE_URL, preferring environment (direnv/BWS)
if [ -z "${DATABASE_URL:-}" ]; then
  if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
  fi
fi

if [ -z "${DATABASE_URL:-}" ]; then
  echo "❌ DATABASE_URL is not set. Export it via direnv/BWS or provide it in .env."
  exit 1
fi

# Output dir
DATESTAMP=$(date +%F)
OUTDIR="data/exports/$DATESTAMP"
mkdir -p "$OUTDIR"

# Choose schemas (default public)
SCHEMAS="${SAMPLE_SCHEMAS:-public}"
echo "📦 Saving sample CSVs to: $OUTDIR"
echo "🔎 Schemas: $SCHEMAS"

# Loop through schemas and tables
for schema in $(echo "$SCHEMAS" | tr ',' ' '); do
  tables=$(psql "$DATABASE_URL" -Atc \
    "SELECT tablename FROM pg_tables WHERE schemaname='${schema}' ORDER BY tablename;")
  
  for tbl in $tables; do
    FILE="$OUTDIR/${schema}.${tbl}.csv"
    echo "→ ${schema}.${tbl}  →  $FILE"
    psql "$DATABASE_URL" -c "\COPY (SELECT * FROM ${schema}.${tbl} LIMIT 5) TO STDOUT WITH CSV HEADER" > "$FILE" || true
  done
done

echo "✅ Done."
