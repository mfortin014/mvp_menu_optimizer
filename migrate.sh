#!/usr/bin/env bash
set -euo pipefail

# Try to auto-load .env if present and DB_URL/SUPABASE_DB_URL not set
if [ -z "${DB_URL:-}" ] && [ -z "${SUPABASE_DB_URL:-}" ] && [ -f ".env" ]; then
  set -a
  . ./.env
  set +a
fi

DB_URL="${DB_URL:-${SUPABASE_DB_URL:-${DATABASE_URL:-}}}"

MIGRATIONS_DIR="${MIGRATIONS_DIR:-migrations/sql}"
CMD="${1:-}"
shift || true

usage() {
  cat <<EOF
Usage:
  DB_URL=postgres://... ./migrate.sh up [--dry-run]
  DB_URL=postgres://... ./migrate.sh mark <files...>
  DB_URL=postgres://... ./migrate.sh mark-before <filename>

Env:
  DB_URL / SUPABASE_DB_URL : Postgres connection string
  MIGRATIONS_DIR           : default "migrations"

Commands:
  up          : run pending V*.sql in order (skips already applied)
  mark        : mark specific migration files as applied (no execution)
  mark-before : mark all files sorted before <filename> as applied

Notes:
  - Each migration runs in a single transaction (-1). Avoid BEGIN/COMMIT inside files.
  - Creates public.schema_migrations if missing:
      (filename text PK, checksum text NOT NULL, executed_at timestamptz NOT NULL)
EOF
}

require_psql() {
  if ! command -v psql >/dev/null 2>&1; then
    echo "psql not found. Install psql or run inside a shell that has it." >&2
    exit 1
  fi
}

require_db() {
  if [[ -z "${DB_URL}" ]]; then
    echo "DB_URL (or SUPABASE_DB_URL) is not set" >&2
    exit 1
  fi
}

mk_migrations_table() {
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X <<'SQL'
create table if not exists public.schema_migrations (
  filename    text primary key,
  checksum    text not null,
  executed_at timestamptz not null default now()
);
SQL
}

sha256_of() {
  # portable sha256
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "Need sha256sum or shasum" >&2
    exit 1
  fi
}

is_applied() {
  local file="$1"
  psql "${DB_URL}" -t -A -q -X -c \
    "select 1 from public.schema_migrations where filename = '$(basename "$file" )' limit 1;" \
    | grep -q '^1$' && return 0 || return 1
}

record_applied() {
  local file="$1"
  local sum
  sum="$(sha256_of "$file")"
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X -c \
    "insert into public.schema_migrations(filename, checksum) values ('$(basename "$file")', '${sum}')
     on conflict (filename) do update set checksum = excluded.checksum, executed_at = now();"
}

cmd_up() {
  local dry="no"
  if [[ "${1:-}" == "--dry-run" ]]; then dry="yes"; fi

  mk_migrations_table

  mapfile -t files < <(LC_ALL=C ls -1 "${MIGRATIONS_DIR}"/V*.sql 2>/dev/null | sort)
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No migrations found in ${MIGRATIONS_DIR}" >&2
    exit 0
  fi

  for f in "${files[@]}"; do
    if is_applied "$f"; then
      echo "✓ SKIP $(basename "$f") (already applied)"
      continue
    fi
    if [[ "$dry" == "yes" ]]; then
      echo "→ PENDING $(basename "$f")"
      continue
    fi
    echo "→ APPLY  $(basename "$f")"
    # -1 = single transaction; -v ON_ERROR_STOP=1 aborts on first error
    psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X -1 -f "$f"
    record_applied "$f"
    echo "✓ DONE   $(basename "$f")"
  done
}

cmd_mark() {
  mk_migrations_table
  if [[ $# -lt 1 ]]; then echo "mark requires filenames" >&2; exit 1; fi
  for f in "$@"; do
    local path="${MIGRATIONS_DIR}/$(basename "$f")"
    if [[ ! -f "$path" ]]; then
      echo "Not found: $path" >&2; exit 1
    fi
    echo "→ MARK   $(basename "$path")"
    record_applied "$path"
  done
}

cmd_mark_before() {
  mk_migrations_table
  local cutoff="${1:-}"
  if [[ -z "$cutoff" ]]; then echo "mark-before requires a cutoff filename" >&2; exit 1; fi
  mapfile -t files < <(LC_ALL=C ls -1 "${MIGRATIONS_DIR}"/V*.sql 2>/dev/null | sort)
  for f in "${files[@]}"; do
    local base="$(basename "$f")"
    if [[ "$base" < "$cutoff" ]]; then
      echo "→ MARK   $base"
      record_applied "$f"
    fi
  done
}

case "$CMD" in
  up)           require_psql; require_db; cmd_up "${1:-}";;
  mark)         require_psql; require_db; cmd_mark "$@";;
  mark-before)  require_psql; require_db; cmd_mark_before "${1:-}";;
  ""|help|-h|--help) usage;;
  *) echo "Unknown command: $CMD"; usage; exit 1;;
esac
