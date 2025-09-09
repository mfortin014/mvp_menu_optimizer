#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then set -a; . "$PROJECT_ROOT/.env"; set +a; fi
: "${DATABASE_URL:?Set DATABASE_URL in .env or environment to your Postgres connection string}"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$PROJECT_ROOT/backup_${STAMP}.sql"
echo "Backing up to $OUT"
pg_dump --no-owner --no-privileges --format=plain --create --clean --if-exists --dbname="$DATABASE_URL" > "$OUT"
echo "Backup saved to $OUT"
