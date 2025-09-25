#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# dump_schema.sh
#
# Purpose
#   Keep one stable, human-friendly "current" schema per env
#   AND maintain a clean, timestamped history for releases.
#
# Layout (repo relative)
#   schema/current/<env>.schema.sql          # tracked, always latest (for humans + AI)
#   schema/releases/supabase_schema_<env>_<YYYY-MM-DD_HHMMUTC>.sql  # tracked, release-time snapshots
#   schema/archive/<YYYY_MM_DD_HHMM>_<env>.sql                     # ignored, local forensic trail
#
# Modes
#   --mode latest   (default)  → updates schema/current/, also writes a timestamped copy to schema/archive/
#   --mode release             → writes a timestamped file to schema/releases/ (and also refreshes schema/current/)
#
# Environments
#   --env prod|staging|both|auto   (default: auto)
#   URLs are taken from process env first, then .env if present:
#     PROD:    DATABASE_URL_PROD   (fallback: DATABASE_URL)
#     STAGING: DATABASE_URL_STAGING
#
# Usage
#   ./dump_schema.sh
#   ./dump_schema.sh --env prod
#   ./dump_schema.sh --env staging
#   ./dump_schema.sh --env both
#   ./dump_schema.sh --mode release --env prod    # when cutting a release PR
#
# ------------------------------------------------------------

# Defaults
MODE="latest"
ENV_TARGET="auto"
RELEASE_TAG=""   # optional: tag to stamp in header (e.g., mvp-0.6.1)

usage() {
  echo "Usage: $0 [--mode latest|release] [--env prod|staging|both|auto] [--tag <release-tag>]"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode|-m)    MODE="${2:-}"; shift 2 ;;
    --env|-e)     ENV_TARGET="${2:-}"; shift 2 ;;
    --tag|-t)     RELEASE_TAG="${2:-}"; shift 2 ;;
    --help|-h)    usage ;;
    *)            echo "Unknown arg: $1" >&2; usage ;;
  esac
done

# Ensure pg_dump available
command -v pg_dump >/dev/null || { echo "❌ pg_dump not found in PATH."; exit 1; }

# Load .env only if present (process env takes precedence)
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

# Resolve URLs (prefer explicit env vars; keep DATABASE_URL as last resort for prod)
PROD_URL="${DATABASE_URL_PROD:-${DATABASE_URL:-}}"
STAGING_URL="${DATABASE_URL_STAGING:-}"

# Select targets
targets=()
case "${ENV_TARGET}" in
  auto)
    if [[ -n "${PROD_URL}" && -n "${STAGING_URL}" ]]; then
      targets=(prod staging)
    elif [[ -n "${PROD_URL}" ]]; then
      targets=(prod)
    elif [[ -n "${STAGING_URL}" ]]; then
      targets=(staging)
    else
      echo "❌ No database URLs found."
      echo "   Set DATABASE_URL_PROD (or DATABASE_URL) for prod and/or DATABASE_URL_STAGING for staging."
      exit 1
    fi
    ;;
  both)    targets=(prod staging) ;;
  prod)    targets=(prod) ;;
  staging) targets=(staging) ;;
  *)       usage ;;
esac

# Validate URLs for chosen targets
for t in "${targets[@]}"; do
  if [[ "${t}" == "prod"    && -z "${PROD_URL}"    ]]; then echo "❌ Missing DATABASE_URL_PROD (or DATABASE_URL)"; exit 1; fi
  if [[ "${t}" == "staging" && -z "${STAGING_URL}" ]]; then echo "❌ Missing DATABASE_URL_STAGING"; exit 1; fi
done

# Validate mode
if [[ "${MODE}" != "latest" && "${MODE}" != "release" ]]; then
  echo "❌ Invalid mode: ${MODE}. Use --mode latest|release"
  exit 1
fi

# Prepare folders
mkdir -p schema/current schema/releases schema/archive

# Helpers
ts_utc() { date -u +%Y-%m-%d_%H%MUTC; }        # for releases
ts_utc_arch() { date -u +%Y_%m_%d_%H%M; }      # for archive
git_rev() { git rev-parse --short HEAD 2>/dev/null || echo "unknown"; }

prepend_header() {
  local file="$1"; local env="$2"; local mode="$3"; local tag="$4"
  local stamp="$(ts_utc)"
  local rev="$(git_rev)"
  local tmp="$(mktemp)"
  {
    echo "-- ------------------------------------------------------------"
    echo "-- Schema dump"
    echo "-- Env: ${env}"
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

archive_path() {
  local env="$1"; local stamp_arch="$2"   # YYYY_MM_DD_HHMM
  local base="schema/archive/${stamp_arch}_${env}.sql"
  if [[ ! -e "${base}" ]]; then
    echo "${base}"; return
  fi
  # Collision guard: add _v02, _v03, ...
  local idx=2
  while :; do
    local candidate="schema/archive/${stamp_arch}_${env}_v$(printf "%02d" "${idx}").sql"
    [[ ! -e "${candidate}" ]] && { echo "${candidate}"; return; }
    idx=$((idx+1))
  done
}

dump_env() {
  local env="$1"; local url="$2"

  # Dump to temporary file first
  local tmp="$(mktemp)"
  echo "🔄 Dumping ${env} schema (${MODE}) ..."
  pg_dump "${url}" --schema-only --no-owner --no-privileges --file="${tmp}"

  # Add header
  prepend_header "${tmp}" "${env}" "${MODE}" "${RELEASE_TAG}"

  # Always refresh "current" (stable path for humans/AI)
  local current="schema/current/${env}.schema.sql"
  mv -f "${tmp}" "${current}"

  # Always write an ignored archive copy (for local forensics)
  local stamp_arch="$(ts_utc_arch)"
  local arch="$(archive_path "${env}" "${stamp_arch}")"
  cp -f "${current}" "${arch}"

  echo "✅ ${env}: updated current → ${current}"
  echo "🗄️  ${env}: archived      → ${arch}"

  # On release mode, also write a tracked release snapshot
  if [[ "${MODE}" == "release" ]]; then
    local stamp_rel="$(ts_utc)"  # YYYY-MM-DD_HHMMUTC
    local rel="schema/releases/supabase_schema_${env}_${stamp_rel}.sql"
    cp -f "${current}" "${rel}"
    echo "🏷️  ${env}: release snapshot → ${rel}"
  fi
}

# Execute
for t in "${targets[@]}"; do
  case "${t}" in
    prod)    dump_env "prod"    "${PROD_URL}" ;;
    staging) dump_env "staging" "${STAGING_URL}" ;;
  esac
done

echo "🎉 All requested schema dumps completed."
