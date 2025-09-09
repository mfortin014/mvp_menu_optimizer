#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then set -a; . "$PROJECT_ROOT/.env"; set +a; fi
: "${DATABASE_URL:?Set DATABASE_URL in .env or environment to your Postgres connection string}"
run() { local file="$1"; echo "Applying $file ..."; psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"; }
DIR="$PROJECT_ROOT/migrations/sql"
for f in $(ls -1 "$DIR"/V*.sql | sort); do run "$f"; done
echo "All migrations applied."
