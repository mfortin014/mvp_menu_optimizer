#!/usr/bin/env bash
# Usage:
#   scripts/restore_public.sh --host HOST --port 5432 --user USER --db DB --password 'SECRET' <dump_path>
# Example (Supabase Direct):
#   scripts/restore_public.sh --host db.<PROJECT_REF>.supabase.co --port 5432 --user postgres --db postgres --password '...' backups/<ts>_staging_*/db_full.dump
# Example (Supavisor session pooler):
#   scripts/restore_public.sh --host aws-0-<REGION>.pooler.supabase.com --port 5432 --user postgres.<PROJECT_REF> --db postgres --password '...' <dump>
set -euo pipefail

HOST=""; PORT="5432"; USER=""; DB=""; PGPASS=""; DUMP=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --db)   DB="$2";   shift 2 ;;
    --password) PGPASS="$2"; shift 2 ;;
    -h|--help) echo "see header for usage"; exit 0 ;;
    *) DUMP="$1"; shift ;;
  esac
done

[[ -n "$HOST" && -n "$USER" && -n "$DB" && -n "$PGPASS" && -n "$DUMP" ]] || {
  echo "ERROR: missing args. Run with --help."; exit 1; }

command -v pg_restore >/dev/null || { echo "ERROR: pg_restore not found"; exit 1; }

# Use env var for password to avoid URL encoding issues (e.g., '!').
PGPASSWORD="$PGPASS" pg_restore --clean --if-exists --no-owner --no-privileges \
  -n public -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" "$DUMP"
