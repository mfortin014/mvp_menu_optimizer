#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?Set DATABASE_URL to your Postgres connection string}"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="backup_${STAMP}.sql"
pg_dump --no-owner --no-privileges --format=plain --create --clean --if-exists --dbname="$DATABASE_URL" > "$OUT"
echo "Backup saved to $OUT"
