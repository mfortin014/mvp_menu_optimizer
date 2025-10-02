#!/usr/bin/env bash
# Usage:
#   scripts/backup_db.sh [--url <postgresql://...>] [--no-restore-hint] [label]
#
# Notes:
# - Reads DB URL from .env (SUPABASE_DB_URL, DATABASE_URL, or DB_URL), unless --url is provided.
# - Writes to ./backups/<timestamp>[_label]/ and collects:
#     * full pg_dump (custom format)
#     * schema-only SQL
#     * server version + extensions inventory
#     * view reloptions (e.g., security_invoker)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NO_HINT=0
URL_OVERRIDE=""
LABEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-restore-hint) NO_HINT=1; shift ;;
    --url) URL_OVERRIDE="${2:-}"; shift 2 ;;
    *) LABEL="$1"; shift ;;
  esac
done

# Load .env safely if present
if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ROOT_DIR/.env"
  set +a
fi

DB_URL="${URL_OVERRIDE:-${SUPABASE_DB_URL:-${DATABASE_URL:-${DB_URL:-}}}}"
if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: No DB URL found. Use --url or set SUPABASE_DB_URL (or DATABASE_URL/DB_URL) in .env." >&2
  exit 1
fi

# Basic tooling checks
for bin in pg_dump psql; do
  command -v "$bin" >/dev/null || { echo "ERROR: $bin not found in PATH"; exit 1; }
done

# Friendly warnings for common gotchas
if [[ "$DB_URL" =~ :6543/ ]]; then
  echo "WARNING: URL looks like a pooled connection (port 6543). pg_dump may fail. Prefer the Direct 5432 URL." >&2
fi
if ! [[ "$DB_URL" =~ sslmode= ]]; then
  echo "NOTE: No sslmode in URL. Supabase typically requires '?sslmode=require'." >&2
fi

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

# 4) View reloptions snapshot (e.g., security_invoker, check_option)
psql "$DB_URL" -Atc "
  SELECT n.nspname||'.'||c.relname AS view,
         COALESCE(array_to_string(c.reloptions,','),'') AS reloptions
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='v'
  ORDER BY 1;" \
  -F $'\t' > "$DEST/views_reloptions.tsv"

echo "✅ Backup complete → $DEST"
if [[ "$NO_HINT" -eq 0 ]]; then
  echo "To test restore locally:"
  echo "  createdb test_restore_menu_optimizer && pg_restore --clean --if-exists --no-owner --no-privileges -j4 -d test_restore_menu_optimizer \"$DEST/db_full.dump\""
fi
