#!/usr/bin/env bash
set -euo pipefail

# release_notes.sh
# Emit a Markdown block of release notes for a given range.
# Default: last mvp-* tag .. HEAD
#
# Usage:
#   scripts/release_notes.sh                # uses last tag .. HEAD
#   scripts/release_notes.sh v0.6.0..HEAD   # explicit range
#   scripts/release_notes.sh mvp-0.6.0..main
#
# Tip: paste the output into PR descriptions or GitHub Releases.

rng="${1:-}"
if [[ -z "${rng}" ]]; then
  last_tag="$(git describe --tags --abbrev=0 --match 'mvp-*' 2>/dev/null || true)"
  if [[ -z "${last_tag}" ]]; then
    echo "No mvp-* tag found; please pass an explicit range (e.g., HEAD~100..HEAD)" >&2
    exit 1
  fi
  rng="${last_tag}..HEAD"
fi

# Collect commits (no merges), one per line: TYPE|SCOPE|SUBJECT|SHORTSHA
mapfile -t COMMITS < <(git log --no-merges --pretty='%s|%h' "${rng}")

# Buckets
declare -A BUCKETS=(
  [Added]=""
  [Fixed]=""
  [Changed]=""
  [Documentation]=""
  [Build]=""
  [CI]=""
  [Tests]=""
  [Chore]=""
  [Style]=""
  [Reverted]=""
  [Other]=""
)

# Categorize
for line in "${COMMITS[@]}"; do
  subj="${line%|*}"; short="${line#*|}"

  # Ignore obvious version bump noise
  shopt -s nocasematch
  if [[ "$subj" =~ ^release\(|^chore\(release\)|^bump[[:space:]]version ]]; then
    continue
  fi
  shopt -u nocasematch

  # Conventional-ish parsing: type(scope): desc
  if [[ "$subj" =~ ^(feat|fix|perf|refactor|docs|style|test|build|ci|chore|revert)(\([^)]+\))?\:?[[:space:]]+(.*)$ ]]; then
    typ="${BASH_REMATCH[1]}"; scope="${BASH_REMATCH[2]}"; desc="${BASH_REMATCH[3]}"
    case "$typ" in
      feat)   key="Added" ;;
      fix)    key="Fixed" ;;
      perf|refactor) key="Changed" ;;
      docs)   key="Documentation" ;;
      build)  key="Build" ;;
      ci)     key="CI" ;;
      test)   key="Tests" ;;
      chore)  key="Chore" ;;
      style)  key="Style" ;;
      revert) key="Reverted" ;;
      *)      key="Other" ;;
    esac
    [[ -n "$scope" ]] && scope=" _${scope}_"
    BUCKETS["$key"]+=$'- '"%s"'%s (%s)\n' % (desc, scope, short)
  else
    BUCKETS["Other"]+=$'- '"%s"' (%s)\n' % (subj, short)
  fi
done

# Print Markdown
echo "### Release notes for \`${rng}\`"
echo
for key in Added Fixed Changed Documentation Build CI Tests Chore Style Reverted Other; do
  val="${BUCKETS[$key]}"
  if [[ -n "$val" ]]; then
    echo "#### ${key}"
    # shellcheck disable=SC2059
    printf "%b" "$val"
    echo
  fi
done
