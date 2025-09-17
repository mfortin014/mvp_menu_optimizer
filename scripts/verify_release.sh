#!/usr/bin/env bash
set -euo pipefail

# verify_release.sh
# Pre-flight checks before cutting/tagging a release.
#
# Usage:
#   scripts/verify_release.sh X.Y.Z

version="${1:-}"
if [[ -z "${version}" ]]; then
  echo "usage: $0 X.Y.Z" >&2
  exit 2
fi

fail=0

echo "Version to release: ${version}"
echo

# 1) VERSION file matches
if [[ -f VERSION ]]; then
  current="$(tr -d '\n' < VERSION)"
  if [[ "${current}" != "${version}" ]]; then
    echo "❌ VERSION file is '${current}', expected '${version}'"
    fail=1
  else
    echo "✅ VERSION file matches"
  fi
else
  echo "❌ VERSION file not found"
  fail=1
fi

# 2) Pending main-only commits (back-merge forgotten?)
git fetch --all --prune >/dev/null
main_only="$(git rev-list --left-right --count origin/main...origin/develop | awk '{print $1}')"
if [[ "${main_only}" != "0" ]]; then
  echo "❌ develop is missing ${main_only} commit(s) from main (merge main → develop first)"
  fail=1
else
  echo "✅ develop contains all main commits"
fi

# 3) Migration marker present for this version?
if ls migrations/*__release_"${version}".sql >/dev/null 2>&1; then
  echo "✅ migration marker exists"
else
  echo "❌ missing migrations/*__release_${version}.sql"
  fail=1
fi

# 4) Recent schema dump present (within 2 days)
latest_dump="$(ls -1t schema/supabase_schema_*.sql 2>/dev/null | head -n1 || true)"
if [[ -n "${latest_dump}" ]]; then
  ts="$(date -r "${latest_dump}" +%s)"
  now="$(date +%s)"
  if (( now - ts < 172800 )); then
    echo "✅ recent schema dump: ${latest_dump}"
  else
    echo "⚠️ schema dump is older than 2 days: ${latest_dump}"
  fi
else
  echo "❌ no schema dump found (run dump_schema.sh)"
  fail=1
fi

# 5) Dirty tree?
if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ working tree not clean"
  fail=1
else
  echo "✅ working tree clean"
fi

if [[ "${fail}" != "0" ]]; then
  echo
  echo "Pre-flight failed. Fix the ❌ items above."
  exit 1
fi

echo
echo "All checks passed. Ready to cut and tag ${version}."
