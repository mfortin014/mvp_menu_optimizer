#!/usr/bin/env bash
set -euo pipefail

# sync_status.sh
# Show actionable sync signals between main and develop.
#
# Usage: scripts/sync_status.sh

git fetch --all --prune >/dev/null

# Counts
read -r main_only dev_only < <(git rev-list --left-right --count origin/main...origin/develop | awk '{print $1, $2}')

echo "main-only commits (develop missing): ${main_only}"
if [[ "${main_only}" != "0" ]]; then
  echo "Top main-only commits:"
  git log --oneline origin/develop..origin/main | head -n 10
  echo
fi

echo "develop-only commits (ahead of main): ${dev_only} (expected to be large if you squash)"
echo

# Size of change since last release tag
last_tag="$(git describe --tags --abbrev=0 --match 'mvp-*' 2>/dev/null || true)"
if [[ -n "${last_tag}" ]]; then
  echo "Changes since ${last_tag} on develop:"
  git diff --shortstat "${last_tag}..origin/develop" || true
  echo
fi

# Diff preview (files)
echo "Files changed between origin/main and origin/develop (top 20):"
git diff --name-status origin/main..origin/develop | head -n 20 || true
