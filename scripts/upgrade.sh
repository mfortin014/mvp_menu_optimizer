#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?Set DATABASE_URL to your Postgres connection string}"
run() {
  local file="$1"
  echo "Applying $file ..."
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/migrations/sql"
for f in $(ls -1 "$DIR"/V*.sql | sort); do
  run "$f"
done
echo "All migrations applied."
