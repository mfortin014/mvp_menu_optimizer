#!/usr/bin/env bash
set -euo pipefail

MIGRATIONS_DIRS="${MIGRATIONS_DIRS:-migrations/sql:migrations}"
ENV_NAME=""
PROJECT_ID=""
DRIVER_OVERRIDE="${DB_DRIVER:-}"

usage() {
  cat <<'EOF'
Usage:
  ./migrate.sh --env <name> up [--dry-run]
  ./migrate.sh --env <name> mark <Vxxx__name.sql|.sh|.py ...>
  ./migrate.sh --env <name> mark-before <Vxxx__cutoff.sql>

Options:
  --env <name>          Environment label (e.g., staging, prod); must map to a Bitwarden project id via .envrc.
  --project-id <uuid>   Bitwarden project id (skip --env when provided).
  --driver <name>       Optional driver override passed to utils.db (e.g., postgresql+psycopg).
  --help                Show this help message.

Notes:
  - Resolves DATABASE_URL through Bitwarden secrets using `python -m utils.db`.
  - Runs V*.sql with psql in a single transaction (-1), V*.sh with bash, V*.py with python3.
  - Creates public.schema_migrations if missing:
      (filename text PK, checksum text NOT NULL, executed_at timestamptz NOT NULL)
  - Files are tracked by BASENAME; you can move them across dirs safely.
EOF
  exit 1
}

CMD=""
CMD_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_NAME="${2:-}"
      shift 2
      ;;
    --project-id)
      PROJECT_ID="${2:-}"
      shift 2
      ;;
    --driver)
      DRIVER_OVERRIDE="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    up|mark|mark-before)
      CMD="$1"
      shift
      CMD_ARGS=("$@")
      break
      ;;
    *)
      echo "Unknown option or command: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "${CMD}" ]]; then
  usage
fi

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "$1 not found." >&2; exit 1; }
}

resolve_python_bin() {
  local candidate="${PYTHON_BIN:-python}"
  if command -v "${candidate}" >/dev/null 2>&1; then
    echo "${candidate}"
    return
  fi
  candidate="python3"
  if command -v "${candidate}" >/dev/null 2>&1; then
    echo "${candidate}"
    return
  fi
  return 1
}

extract_project_id() {
  local env_name="$1"
  local varname="${env_name^^}"

  if [[ -n "${!varname:-}" ]]; then
    echo "${!varname}"
    return
  fi

  if [[ -f .envrc ]]; then
    while IFS= read -r line; do
      line="${line%%#*}"
      [[ -z "${line// }" ]] && continue
      if [[ "${line}" =~ ^[[:space:]]*export[[:space:]]+${varname}=(\"?)([^\"[:space:]]+)\1 ]]; then
        echo "${BASH_REMATCH[2]}"
        return
      fi
    done < .envrc
  fi
}

fetch_database_url() {
  local python_bin="$1"
  local project_id="$2"
  local driver="$3"

  if [[ -n "${driver}" ]]; then
    DB_DRIVER_OVERRIDE="${driver}" bws run --project-id="${project_id}" -- "${python_bin}" - <<'PY'
from utils import db
import os, sys
driver = os.environ.get("DB_DRIVER_OVERRIDE")
sys.stdout.write(db.database_url(driver))
PY
  else
    bws run --project-id="${project_id}" -- "${python_bin}" -m utils.db
  fi
}

setup_connection() {
  require_command bws

  local python_bin
  python_bin="$(resolve_python_bin)" || {
    echo "python (or python3) not found in PATH." >&2
    exit 1
  }

  local project="${PROJECT_ID}"
  if [[ -z "${project}" ]]; then
    if [[ -z "${ENV_NAME}" ]]; then
      echo "Provide --env <name> or --project-id <uuid> to select a Bitwarden project." >&2
      exit 1
    fi
    project="$(extract_project_id "${ENV_NAME}")"
    if [[ -z "${project}" ]]; then
      echo "Could not resolve Bitwarden project id for env '${ENV_NAME}'. Ensure '${ENV_NAME^^}' is exported or present in .envrc." >&2
      exit 1
    fi
  fi

  local url
  url="$(fetch_database_url "${python_bin}" "${project}" "${DRIVER_OVERRIDE}")" || {
    echo "Unable to synthesize DATABASE_URL via Bitwarden project ${project}." >&2
    exit 1
  }
  if [[ -z "${url}" ]]; then
    echo "utils.db returned an empty DATABASE_URL for project ${project}." >&2
    exit 1
  fi

  DB_URL="${url}"
  BITWARDEN_PROJECT_ID="${project}"
}

setup_connection

# --- File discovery & bookkeeping --------------------------------------------

readarray -d : -t __DIRS__ <<<"${MIGRATIONS_DIRS}:"

gather_migration_files() {
  local files=()
  for d in "${__DIRS__[@]}"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' f; do files+=("$f"); done \
      < <(LC_ALL=C find "$d" -maxdepth 1 -type f -regextype posix-extended \
            -regex '.*/V[0-9]{3}__.*\.(sql|sh|py)$' -print0)
  done
  printf '%s\n' "${files[@]}" | awk -F/ '{print $NF "|" $0}' | LC_ALL=C sort | cut -d'|' -f2
}

basename_only() { basename "$1"; }

# --- Requirements -------------------------------------------------------------

require_db() {
  if [[ -z "${DB_URL:-}" ]]; then
    echo "DATABASE_URL could not be resolved." >&2
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

is_applied() {
  local base
  base="$(basename_only "$1")"
  psql "${DB_URL}" -t -A -q -X -c \
    "select 1 from public.schema_migrations where filename = '${base}' limit 1;" \
    | grep -q '^1$'
}

record_applied() {
  local file="$1"
  local base sum
  base="$(basename_only "$file")"
  sum="$(sha256_of "$file")"
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X -c \
    "insert into public.schema_migrations(filename, checksum) values ('${base}', '${sum}')
     on conflict (filename) do update set checksum = excluded.checksum, executed_at = now();"
}

resolve_by_basename() {
  local target_base="$1"
  for d in "${__DIRS__[@]}"; do
    [[ -d "$d" ]] || continue
    local candidate="${d}/${target_base}"
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# --- Executors ----------------------------------------------------------------

run_sql() {
  require_psql
  local file="$1"
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -q -X -1 -f "$file"
}

run_sh() {
  local file="$1"
  DB_URL="${DB_URL}" bash -euo pipefail "$file"
}

run_py() {
  local file="$1"
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
  if [[ "${1:-}" == "--dry-run" ]]; then
    dry="yes"
    shift || true
  fi

  require_db
  mk_migrations_table

  mapfile -t files < <(gather_migration_files)
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No migrations found in: ${MIGRATIONS_DIRS}" >&2
    exit 0
  fi

  for f in "${files[@]}"; do
    local base
    base="$(basename_only "$f")"
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
  local args=("$@")
  require_db
  mk_migrations_table
  if [[ ${#args[@]} -lt 1 ]]; then
    echo "mark requires at least one filename (basename or path)" >&2
    exit 1
  fi

  for arg in "${args[@]}"; do
    local f="$arg"
    if [[ ! -f "$f" ]]; then
      if ! f="$(resolve_by_basename "$(basename_only "$arg")")"; then
        echo "Not found in MIGRATIONS_DIRS: $arg" >&2
        exit 1
      fi
    fi
    echo "→ MARK $(basename_only "$f")"
    record_applied "$f"
  done
}

cmd_mark_before() {
  local args=("$@")
  require_db
  mk_migrations_table
  local cutoff="${args[0]:-}"
  if [[ -z "$cutoff" ]]; then
    echo "mark-before requires a cutoff filename" >&2
    exit 1
  fi

  mapfile -t files < <(gather_migration_files)
  local found="no"
  for f in "${files[@]}"; do
    local base
    base="$(basename_only "$f")"
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
  up)            cmd_up "${CMD_ARGS[@]}";;
  mark)          cmd_mark "${CMD_ARGS[@]}";;
  mark-before)   cmd_mark_before "${CMD_ARGS[@]}";;
  *) echo "Unknown command: $CMD"; usage;;
esac
