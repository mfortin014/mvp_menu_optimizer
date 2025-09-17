#!/bin/bash
set -euo pipefail

# Load DATABASE_URL from .env
if [ ! -f .env ]; then
  echo "❌ .env file not found."
  exit 1
fi
source <(grep DATABASE_URL .env)

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
  tables=$(psql "$DATABASE_URL" -Atc \
    "SELECT tablename FROM pg_tables WHERE schemaname='${schema}' ORDER BY tablename;")
  
  for tbl in $tables; do
    FILE="$OUTDIR/${schema}.${tbl}.csv"
    echo "→ ${schema}.${tbl}  →  $FILE"
    psql "$DATABASE_URL" -c "\COPY (SELECT * FROM ${schema}.${tbl} LIMIT 5) TO STDOUT WITH CSV HEADER" > "$FILE" || true
  done
done

echo "✅ Done."
