#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# dump_schema.sh
#
#   Usage:
#     ./dump_schema.sh --env <name> [--mode latest|release] [--tag <release>]
#
#   The script:
#     1. Looks up <name> (e.g., staging) in exported variables / .envrc to find the Bitwarden project id.
#     2. Invokes `bws run --project-id=<id> -- python -m utils.db` to synthesize the database URL.
#     3. Dumps the schema via pg_dump and writes labelled artifacts:
#        - schema/current/supabase_schema_<env>.sql
#        - schema/archive/supabase_schema_<env>_<timestamp>.sql
#        - schema/releases/supabase_schema_<env>_<release>.sql (only for --mode release, using --tag or timestamp)
# ------------------------------------------------------------

MODE="latest"
RELEASE_TAG=""
ENV_NAME=""

usage() {
  cat <<'EOF'
Usage:
  ./dump_schema.sh --env <name> [--mode latest|release] [--tag <release-tag>]

Options:
  --env <name>            Environment label (e.g., staging, prod); must match an export in .envrc
  --mode latest|release   Dump mode (default: latest)
  --tag <release-tag>     Release tag to use in release filenames (required when --mode release)
  -h, --help              Show this help text and exit
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)      ENV_NAME="${2:-}"; shift 2 ;;
    --mode|-m)  MODE="${2:-}"; shift 2 ;;
    --tag|-t)   RELEASE_TAG="${2:-}"; shift 2 ;;
    --help|-h)  usage ;;
    *)          echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "${ENV_NAME}" ]]; then
  echo "❌ --env <name> is required (e.g., --env staging)" >&2
  exit 1
fi
if [[ "${MODE}" != "latest" && "${MODE}" != "release" ]]; then
  echo "❌ Invalid mode: ${MODE}. Use --mode latest|release" >&2
  exit 1
fi
if [[ "${MODE}" == "release" && -z "${RELEASE_TAG}" ]]; then
  echo "❌ --tag <release> is required when --mode release" >&2
  exit 1
fi

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "❌ $1 not found in PATH." >&2; exit 1; }
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
  local varname="${env_name^^}"  # uppercase

  # Check current environment variables first
  if [[ -n "${!varname:-}" ]]; then
    echo "${!varname}"
    return
  fi

  # Fallback: parse .envrc if available
  if [[ -f .envrc ]]; then
    while IFS= read -r line; do
      line="${line%%#*}"                # strip comments
      [[ -z "${line// }" ]] && continue # skip blank lines
      if [[ "${line}" =~ ^[[:space:]]*export[[:space:]]+${varname}=(\"?)([^\"[:space:]]+)\1 ]]; then
        echo "${BASH_REMATCH[2]}"
        return
      fi
    done < .envrc
  fi

  echo ""
}

fetch_database_url() {
  local python_bin="$1"
  local project_id="$2"

  local url
  if ! url="$(bws run --project-id="${project_id}" -- "${python_bin}" -m utils.db)"; then
    echo "❌ Failed to obtain DATABASE_URL via Bitwarden project ${project_id}" >&2
    return 1
  fi
  if [[ -z "${url}" ]]; then
    echo "❌ utils.db returned an empty DATABASE_URL for project ${project_id}" >&2
    return 1
  fi
  echo "${url}"
}

ts_utc() { date -u +%Y-%m-%d_%H%MUTC; }
ts_utc_arch() { date -u +%Y_%m_%d_%H%M; }
git_rev() { git rev-parse --short HEAD 2>/dev/null || echo "unknown"; }

archive_path() {
  local env="$1"
  local stamp_arch="$2"
  local base="schema/archive/supabase_schema_${env}_${stamp_arch}.sql"
  if [[ ! -e "${base}" ]]; then
    echo "${base}"
    return
  fi
  local idx=2
  while :; do
    local candidate="schema/archive/supabase_schema_${env}_${stamp_arch}_v$(printf "%02d" "${idx}").sql"
    [[ ! -e "${candidate}" ]] && { echo "${candidate}"; return; }
    idx=$((idx + 1))
  done
}

release_filename() {
  local env="$1"
  local tag="$2"
  echo "schema/releases/supabase_schema_${env}_${tag}.sql"
}

prepend_header() {
  local file="$1"
  local env="$2"
  local mode="$3"
  local tag="$4"
  local project="$5"

  local stamp rev tmp
  stamp="$(ts_utc)"
  rev="$(git_rev)"
  tmp="$(mktemp)"

  {
    echo "-- ------------------------------------------------------------"
    echo "-- Schema dump"
    echo "-- Env: ${env}"
    echo "-- Bitwarden project: ${project}"
    echo "-- Mode: ${mode}"
    echo "-- Timestamp (UTC): ${stamp}"
    echo "-- Git commit: ${rev}"
    if [[ -n "${tag}" ]]; then
      echo "-- Release Tag: ${tag}"
    fi
    echo "-- ------------------------------------------------------------"
  } > "${tmp}"
  cat "${file}" >> "${tmp}"
  mv -f "${tmp}" "${file}"
}

main() {
  require_command pg_dump
  require_command bws

  local python_bin
  if ! python_bin="$(resolve_python_bin)"; then
    echo "❌ python (or python3) not found in PATH." >&2
    exit 1
  fi

  mkdir -p schema/current schema/archive schema/releases

  local project_id
  project_id="$(extract_project_id "${ENV_NAME}")"
  if [[ -z "${project_id}" ]]; then
    echo "❌ Could not resolve Bitwarden project id for env '${ENV_NAME}'. Ensure '${ENV_NAME^^}' is exported in your shell or .envrc." >&2
    exit 1
  fi

  local db_url
  db_url="$(fetch_database_url "${python_bin}" "${project_id}")" || exit 1

  local tmp
  tmp="$(mktemp)"
  echo "🔄 Dumping schema (${MODE}) for ${ENV_NAME} (project ${project_id})..."
  pg_dump "${db_url}" --schema-only --no-owner --no-privileges --file="${tmp}"

  prepend_header "${tmp}" "${ENV_NAME}" "${MODE}" "${RELEASE_TAG}" "${project_id}"

  local current="schema/current/supabase_schema_${ENV_NAME}.sql"
  mv -f "${tmp}" "${current}"

  local stamp_arch arch_path
  stamp_arch="$(ts_utc_arch)"
  arch_path="$(archive_path "${ENV_NAME}" "${stamp_arch}")"
  cp -f "${current}" "${arch_path}"
  echo "✅ Updated current schema → ${current}"
  echo "🗄️  Archived snapshot     → ${arch_path}"

  if [[ "${MODE}" == "release" ]]; then
    local rel_path
    rel_path="$(release_filename "${ENV_NAME}" "${RELEASE_TAG}")"
    cp -f "${current}" "${rel_path}"
    echo "🏷️  Release snapshot      → ${rel_path}"
  fi

  echo "🎉 Schema dump completed."
}

main "$@"
