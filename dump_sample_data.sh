#!/bin/bash
set -euo pipefail

# Load SUPABASE_URL from .env
if [ ! -f .env ]; then
  echo "❌ .env file not found."
  exit 1
fi
source <(grep SUPABASE_URL .env)

# Output dir
DATESTAMP=$(date +%F)
OUTDIR="data/sample_data/$DATESTAMP"
mkdir -p "$OUTDIR"

# Choose schemas (default public)
SCHEMAS="${SAMPLE_SCHEMAS:-public}"
echo "📦 Saving sample CSVs to: $OUTDIR"
echo "🔎 Schemas: $SCHEMAS"

# Loop through schemas and tables
for schema in $(echo "$SCHEMAS" | tr ',' ' '); do
  tables=$(psql "$SUPABASE_URL" -Atc \
    "SELECT tablename FROM pg_tables WHERE schemaname='${schema}' ORDER BY tablename;")
  
  for tbl in $tables; do
    FILE="$OUTDIR/${schema}.${tbl}.csv"
    echo "→ ${schema}.${tbl}  →  $FILE"
    psql "$SUPABASE_URL" -c "\COPY (SELECT * FROM ${schema}.${tbl} LIMIT 5) TO STDOUT WITH CSV HEADER" > "$FILE" || true
  done
done

echo "✅ Done."
