#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# dump_schema.sh
#
#   Collect a schema snapshot using Bitwarden-injected secrets:
#     bws run --project-id="<project-id>" -- ./dump_schema.sh [--mode release] [--tag <release>]
#
#   Outputs (with <env> inferred from .envrc exports matching the project id):
#     - schema/current/supabase_schema_<env>.sql
#     - schema/archive/supabase_schema_<env>_<timestamp>.sql
#     - schema/releases/supabase_schema_<env>_<release>.sql (only when --mode release)
# ------------------------------------------------------------

MODE="latest"
RELEASE_TAG=""

usage() {
  cat <<'EOF'
Usage:
  bws run --project-id="<project-id>" -- ./dump_schema.sh [--mode latest|release] [--tag <release-tag>]

Options:
  --mode latest|release   Dump mode to run (default: latest)
  --tag <release-tag>     Optional release tag used for release snapshot filenames
  -h, --help              Show this help text and exit
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode|-m) MODE="${2:-}"; shift 2 ;;
    --tag|-t)  RELEASE_TAG="${2:-}"; shift 2 ;;
    --help|-h) usage ;;
    *)         echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ "${MODE}" != "latest" && "${MODE}" != "release" ]]; then
  echo "❌ Invalid mode: ${MODE}. Use --mode latest|release" >&2
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

get_database_url() {
  local python_bin="$1"
  local url
  if ! url="$("${python_bin}" -m utils.db)"; then
    echo "❌ Unable to synthesize DATABASE_URL. Run via Bitwarden: bws run --project-id=\"<id>\" -- ./dump_schema.sh" >&2
    return 1
  fi
  if [[ -z "${url}" ]]; then
    echo "❌ utils.db returned an empty DATABASE_URL. Check Bitwarden secrets." >&2
    return 1
  fi
  echo "${url}"
}

ts_utc() { date -u +%Y-%m-%d_%H%MUTC; }
ts_utc_arch() { date -u +%Y_%m_%d_%H%M; }
git_rev() { git rev-parse --short HEAD 2>/dev/null || echo "unknown"; }

infer_env_label() {
  local project_id="${BWS_PROJECT_ID:-}"
  if [[ -z "${project_id}" ]]; then
    echo "unknown"
    return
  fi

  local match=""
  while IFS='=' read -r key value; do
    [[ -z "${key}" || -z "${value}" ]] && continue
    if [[ "${value}" == "${project_id}" && "${key}" =~ ^[A-Z0-9_]+$ ]]; then
      match="${key,,}"
      break
    fi
  done < <(printenv)

  if [[ -n "${match}" ]]; then
    echo "${match}"
  else
    echo "${project_id}"
  fi
}

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
  local token
  if [[ -n "${RELEASE_TAG}" ]]; then
    token="${RELEASE_TAG}"
  else
    token="$(ts_utc)"
  fi
  echo "schema/releases/supabase_schema_${env}_${token}.sql"
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
    echo "-- Env: via bws project (${env})"
    echo "-- BWS Project ID: ${project}"
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

  local python_bin
  if ! python_bin="$(resolve_python_bin)"; then
    echo "❌ python (or python3) not found in PATH." >&2
    exit 1
  fi

  mkdir -p schema/current schema/archive schema/releases

  local env_label
  env_label="$(infer_env_label)"
  local project_id="${BWS_PROJECT_ID:-unknown}"

  local db_url
  db_url="$(get_database_url "${python_bin}")" || exit 1

  local tmp
  tmp="$(mktemp)"
  echo "🔄 Dumping schema (${MODE}) for ${env_label}..."
  pg_dump "${db_url}" --schema-only --no-owner --no-privileges --file="${tmp}"

  prepend_header "${tmp}" "${env_label}" "${MODE}" "${RELEASE_TAG}" "${project_id}"

  local current="schema/current/supabase_schema_${env_label}.sql"
  mv -f "${tmp}" "${current}"

  local stamp_arch
  stamp_arch="$(ts_utc_arch)"
  local arch
  arch="$(archive_path "${env_label}" "${stamp_arch}")"
  cp -f "${current}" "${arch}"
  echo "✅ Updated current schema → ${current}"
  echo "🗄️  Archived snapshot     → ${arch}"

  if [[ "${MODE}" == "release" ]]; then
    local rel
    rel="$(release_filename "${env_label}")"
    cp -f "${current}" "${rel}"
    echo "🏷️  Release snapshot      → ${rel}"
  fi

  echo "🎉 Schema dump completed."
}

main "$@"
