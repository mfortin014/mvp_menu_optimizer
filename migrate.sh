#!/usr/bin/env bash
set -euo pipefail

# --- Config & env loading -----------------------------------------------------

# Auto-load .env if DB vars not set
if [ -z "${DB_URL:-}" ] && [ -z "${SUPABASE_DB_URL:-}" ] && [ -z "${DATABASE_URL:-}" ] && [ -f ".env" ]; then
  set -a
  . ./.env
  set +a
fi

# Final DB URL fallback chain
DB_URL="${DB_URL:-${SUPABASE_DB_URL:-${DATABASE_URL:-}}}"

# Multiple dirs, colon-separated (searched in order)
# Default looks in migrations/sql first, then migrations
MIGRATIONS_DIRS="${MIGRATIONS_DIRS:-migrations/sql:migrations}"

CMD="${1:-}"; shift || true

usage() {
  cat <<EOF
Usage:
  ./migrate.sh up [--dry-run]
  ./migrate.sh mark <Vxxx__name.sql|.sh|.py ...>
  ./migrate.sh mark-before <Vxxx__cutoff.sql>

Env:
  DB_URL / SUPABASE_DB_URL / DATABASE_URL : Postgres connection string
  MIGRATIONS_DIRS                         : colon-separated dirs (default: migrations/sql:migrations)

Notes:
  - Runs V*.sql with psql in a single transaction (-1), V*.sh with bash, V*.py with python3.
  - Creates public.schema_migrations if missing:
      (filename text PK, checksum text NOT NULL, executed_at timestamptz NOT NULL)
  - Files are tracked by BASENAME; you can move them across dirs safely.
EOF
}

require_db() {
  if [[ -z "${DB_URL}" ]]; then
    echo "DB_URL (or SUPABASE_DB_URL or DATABASE_URL) is not set" >&2
    exit 1
  fi
}

require_psql() {
  if ! command -v psql >/dev/null 2>&1; then
    echo "psql not found." >&2
    exit 1
  fi
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "Need sha256sum or shasum" >&2
    exit 1
  fi
}

mk_migrations_table() {
  require_psql
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X <<'SQL'
create table if not exists public.schema_migrations (
  filename    text primary key,
  checksum    text not null,
  executed_at timestamptz not null default now()
);
SQL
}

# --- File discovery & bookkeeping --------------------------------------------

# Split MIGRATIONS_DIRS by ':'
readarray -d : -t __DIRS__ <<<"${MIGRATIONS_DIRS}:"

gather_migration_files() {
  local files=()
  for d in "${__DIRS__[@]}"; do
    [[ -d "$d" ]] || continue
    # Collect V*.sql/.sh/.py (not recursive; predictable)
    while IFS= read -r -d '' f; do files+=("$f"); done \
      < <(LC_ALL=C find "$d" -maxdepth 1 -type f -regextype posix-extended \
            -regex '.*/V[0-9]{3}__.*\.(sql|sh|py)$' -print0)
  done
  # Sort by BASENAME so V### order is respected across directories
  printf '%s\n' "${files[@]}" | awk -F/ '{print $NF "|" $0}' | LC_ALL=C sort | cut -d'|' -f2
}

basename_only() { basename "$1"; }

is_applied() {
  local base="$(basename_only "$1")"
  psql "${DB_URL}" -t -A -q -X -c \
    "select 1 from public.schema_migrations where filename = '${base}' limit 1;" \
    | grep -q '^1$' && return 0 || return 1
}

record_applied() {
  local file="$1"
  local base="$(basename_only "$file")"
  local sum; sum="$(sha256_of "$file")"
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X -c \
    "insert into public.schema_migrations(filename, checksum) values ('${base}', '${sum}')
     on conflict (filename) do update set checksum = excluded.checksum, executed_at = now();"
}

# Resolve a basename to a real path by searching MIGRATIONS_DIRS
resolve_by_basename() {
  local target_base="$1"
  for d in "${__DIRS__[@]}"; do
    [[ -d "$d" ]] || continue
    local candidate="${d}/${target_base}"
    if [[ -f "$candidate" ]]; then
      echo "$candidate"; return 0
    fi
  done
  return 1
}

# --- Executors ----------------------------------------------------------------

run_sql() {
  require_psql
  local file="$1"
  # -1 single transaction; -X no .psqlrc; -q quiet; ON_ERROR_STOP aborts on first error
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X -1 -f "$file"
}

run_sh() {
  local file="$1"
  # Export DB_URL so scripts can psql with it or do other DB work
  DB_URL="${DB_URL}" bash -euo pipefail "$file"
}

run_py() {
  local file="$1"
  # Python scripts can read DB_URL from the environment
  DB_URL="${DB_URL}" python3 "$file"
}

apply_file() {
  local file="$1"
  case "$file" in
    *.sql) run_sql "$file" ;;
    *.sh)  run_sh  "$file" ;;
    *.py)  run_py  "$file" ;;
    *)     echo "Unknown migration type: $file" >&2; exit 1 ;;
  esac
}

# --- Commands -----------------------------------------------------------------

cmd_up() {
  local dry="no"
  if [[ "${1:-}" == "--dry-run" ]]; then dry="yes"; shift || true; fi

  require_db
  mk_migrations_table

  mapfile -t files < <(gather_migration_files)
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No migrations found in: ${MIGRATIONS_DIRS}" >&2
    exit 0
  fi

  for f in "${files[@]}"; do
    local base="$(basename_only "$f")"
    if is_applied "$f"; then
      echo "✓ SKIP  $base (already applied)"
      continue
    fi
    if [[ "$dry" == "yes" ]]; then
      echo "→ PENDING $base"
      continue
    fi
    echo "→ APPLY $base"
    apply_file "$f"
    record_applied "$f"
    echo "✓ DONE  $base"
  done
}

cmd_mark() {
  require_db
  mk_migrations_table
  if [[ $# -lt 1 ]]; then echo "mark requires at least one filename (basename or path)"; exit 1; fi
  for arg in "$@"; do
    local f="$arg"
    if [[ ! -f "$f" ]]; then
      # try resolve by basename across dirs
      if ! f="$(resolve_by_basename "$(basename_only "$arg")")"; then
        echo "Not found in MIGRATIONS_DIRS: $arg" >&2; exit 1
      fi
    fi
    echo "→ MARK $(basename_only "$f")"
    record_applied "$f"
  done
}

cmd_mark_before() {
  require_db
  mk_migrations_table
  local cutoff="${1:-}"
  if [[ -z "$cutoff" ]]; then echo "mark-before requires a cutoff filename"; exit 1; fi

  mapfile -t files < <(gather_migration_files)
  local found="no"
  for f in "${files[@]}"; do
    local base="$(basename_only "$f")"
    if [[ "$base" < "$cutoff" ]]; then
      echo "→ MARK $base"
      record_applied "$f"
    elif [[ "$base" == "$cutoff" ]]; then
      found="yes"
      break
    fi
  done
  if [[ "$found" == "no" ]]; then
    echo "Warning: cutoff '$cutoff' not found in MIGRATIONS_DIRS (${MIGRATIONS_DIRS})" >&2
  fi
}

case "$CMD" in
  up)            cmd_up "$@";;
  mark)          cmd_mark "$@";;
  mark-before)   cmd_mark_before "$@";;
  ""|help|-h|--help) usage;;
  *) echo "Unknown command: $CMD"; usage; exit 1;;
esac
