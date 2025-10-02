#!/usr/bin/env bash
# Usage:
#   scripts/backup_db.sh [prod|staging] [--url <postgresql://...>] [--no-restore-hint] [label]
# Defaults to staging:
#   - staging URL resolution order: DATABASE_URL_STAGING → DATABASE_URL (legacy)
#   - prod URL variable: DATABASE_URL_PROD
# You can always override with --url.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- parse args
ENV_CHOICE="staging"
NO_HINT=0
URL_OVERRIDE=""
LABEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    prod|--prod|production) ENV_CHOICE="prod"; shift ;;
    staging|--staging) ENV_CHOICE="staging"; shift ;;
    --no-restore-hint) NO_HINT=1; shift ;;
    --url) URL_OVERRIDE="${2:-}"; shift 2 ;;
    *) LABEL="$1"; shift ;;
  esac
done

# --- load .env safely if present
if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ROOT_DIR/.env"
  set +a
fi

# --- choose DB URL
DB_URL=""
if [[ -n "${URL_OVERRIDE}" ]]; then
  DB_URL="$URL_OVERRIDE"
elif [[ "$ENV_CHOICE" == "prod" ]]; then
  DB_URL="${DATABASE_URL_PROD:-}"
else
  DB_URL="${DATABASE_URL_STAGING:-${DATABASE_URL:-}}"
fi

if [[ -z "${DB_URL:-}" ]]; then
  if [[ "$ENV_CHOICE" == "prod" ]]; then
    echo "ERROR: No DATABASE_URL_PROD set. Put it in .env or pass --url." >&2; exit 1
  else
    echo "ERROR: No staging URL found. Expected DATABASE_URL_STAGING or legacy DATABASE_URL. Put it in .env or pass --url." >&2; exit 1
  fi
fi

# --- basic tooling checks
for bin in pg_dump psql; do
  command -v "$bin" >/dev/null || { echo "ERROR: $bin not found in PATH"; exit 1; }
done

# --- friendly checks (informational)
if [[ "$DB_URL" =~ :6543/ ]]; then
  echo "WARNING: URL uses pooled port 6543. Use the Direct 5432 URL for pg_dump if possible." >&2
fi
if ! [[ "$DB_URL" =~ sslmode= ]]; then
  echo "NOTE: Consider appending '?sslmode=require' for Supabase." >&2
fi

# --- output dir
TS="$(date +%Y%m%d_%H%M%S)"
DEST="$ROOT_DIR/backups/${TS}_${ENV_CHOICE}${LABEL:+_$LABEL}"
mkdir -p "$DEST"

# --- backups
# 1) Full dump (best for restore)
pg_dump "$DB_URL" --format=custom --file="$DEST/db_full.dump" --no-owner --no-privileges

# 2) Schema-only (easy to diff/grep)
pg_dump "$DB_URL" --schema-only --no-owner --no-privileges \
  --exclude-schema 'pg_*' --exclude-schema 'information_schema' \
  > "$DEST/schema.sql"

# 3) Server version + extensions inventory
psql "$DB_URL" -Atc "SELECT version();" > "$DEST/version.txt"
psql "$DB_URL" -A -F $'\t' -c "
  SELECT n.nspname, extname, extversion
  FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace
  ORDER BY 1,2;" > "$DEST/extensions.tsv"

# 4) View reloptions snapshot (e.g., security_invoker, check_option)
psql "$DB_URL" -At -F $'\t' -c "
  SELECT n.nspname||'.'||c.relname AS view,
         COALESCE(array_to_string(c.reloptions,','),'') AS reloptions
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='v'
  ORDER BY 1;" > "$DEST/views_reloptions.tsv"

echo "✅ Backup complete → $DEST"
if [[ "$NO_HINT" -eq 0 ]]; then
  echo "To test restore locally (optional):"
  echo "  createdb test_restore_menu_optimizer && pg_restore --clean --if-exists --no-owner --no-privileges -j4 -d test_restore_menu_optimizer \"$DEST/db_full.dump\""
fi
