#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# dump_sample_data.sh
#
# Export lightweight CSV samples for the requested environment.
# The script resolves secrets via Bitwarden:
#
#   ./dump_sample_data.sh --env staging [--schemas public,foo]
#
# Options:
#   --env <name>          Environment label mapped in .envrc (e.g., STAGING, PROD)
#   --project-id <uuid>   Bitwarden project id (skip --env when provided)
#   --driver <name>       Optional driver override for utils.db (e.g., postgresql+psycopg)
#   --schemas <list>      Comma-separated schema list (default: SAMPLE_SCHEMAS env or "public")
# ------------------------------------------------------------

ENV_NAME=""
PROJECT_ID=""
DRIVER_OVERRIDE="${DB_DRIVER:-}"
SCHEMAS_OVERRIDE=""

usage() {
  cat <<'EOF'
Usage:
  ./dump_sample_data.sh --env <name> [--schemas public,foo] [--driver postgresql+psycopg]

Options:
  --env <name>          Environment label (must match an export in .envrc)
  --project-id <uuid>   Bitwarden project id (bypass --env)
  --driver <name>       Optional driver override passed to utils.db
  --schemas <list>      Comma-separated schema list (defaults to SAMPLE_SCHEMAS env or "public")
  --help                Show this help message
EOF
  exit 1
}

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
    --schemas)
      SCHEMAS_OVERRIDE="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

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
  require_command psql

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
  }

  DB_URL="${url}"
  BITWARDEN_PROJECT_ID="${project}"
}

setup_connection

SCHEMAS="${SCHEMAS_OVERRIDE:-${SAMPLE_SCHEMAS:-public}}"
if [[ -z "${SCHEMAS// }" ]]; then
  SCHEMAS="public"
fi

DATESTAMP="$(date +%Y-%m-%d_%H%M)"
OUTDIR="data/exports/${DATESTAMP}"
mkdir -p "${OUTDIR}"

echo "📦 Saving sample CSVs to: ${OUTDIR}"
echo "🔎 Schemas: ${SCHEMAS}"

for schema in $(echo "${SCHEMAS}" | tr ',' ' '); do
  tables=$(psql "${DB_URL}" -Atc \
    "SELECT tablename FROM pg_tables WHERE schemaname='${schema}' ORDER BY tablename;") || true

  for tbl in $tables; do
    file="${OUTDIR}/${schema}.${tbl}.csv"
    echo "→ ${schema}.${tbl}  →  ${file}"
    psql "${DB_URL}" -c \
      "\COPY (SELECT * FROM ${schema}.${tbl} LIMIT 5) TO STDOUT WITH CSV HEADER" > "${file}" || true
  done
done

echo "✅ Done."
