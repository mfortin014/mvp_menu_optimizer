#!/usr/bin/env bash
# Usage: scripts/backup_db.sh [label]
# Creates a timestamped backup in ./backups/<ts>_<label>/ with:
# - full pg_dump (custom format)
# - schema-only SQL
# - server version + extensions inventory
# - view reloptions (so you can verify security_invoker etc.)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load DB URL from .env (optional)
if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC2046
  export $(grep -E '^(SUPABASE_DB_URL|DATABASE_URL|DB_URL)=' "$ROOT_DIR/.env" | xargs -d '\n' -r)
fi

DB_URL="${SUPABASE_DB_URL:-${DATABASE_URL:-${DB_URL:-}}}"
if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: Set SUPABASE_DB_URL (or DATABASE_URL/DB_URL) env var, or put it in .env" >&2
  exit 1
fi

for bin in pg_dump psql; do
  command -v "$bin" >/dev/null || { echo "ERROR: $bin not found in PATH"; exit 1; }
done

LABEL="${1:-}"
TS="$(date +%Y%m%d_%H%M%S)"
DEST="$ROOT_DIR/backups/${TS}${LABEL:+_$LABEL}"
mkdir -p "$DEST"

# 1) Full dump (best for restore)
pg_dump "$DB_URL" \
  --format=custom \
  --file="$DEST/db_full.dump" \
  --no-owner --no-privileges

# 2) Schema-only (easy to diff/grep)
pg_dump "$DB_URL" \
  --schema-only \
  --no-owner --no-privileges \
  --exclude-schema 'pg_*' \
  --exclude-schema 'information_schema' \
  > "$DEST/schema.sql"

# 3) Server version + extensions inventory
psql "$DB_URL" -Atc "SELECT version();" > "$DEST/version.txt"
psql "$DB_URL" -Atc "
  SELECT n.nspname||E'\t'||extname||E'\t'||extversion
  FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace
  ORDER BY 1,2;" > "$DEST/extensions.tsv"

# 4) View reloptions snapshot (e.g., security_invoker)
psql "$DB_URL" -Atc "
  SELECT n.nspname||'.'||c.relname AS view,
         COALESCE(array_to_string(c.reloptions,','),'') AS reloptions
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='v'
  ORDER BY 1;" \
  -F $'\t' > "$DEST/views_reloptions.tsv"

echo "✅ Backup complete → $DEST"
echo "To test restore locally:"
echo "  createdb test_restore_menu_optimizer && pg_restore --clean --if-exists --no-owner --no-privileges -j4 -d test_restore_menu_optimizer \"$DEST/db_full.dump\""
