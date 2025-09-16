# archive_merged.sh
# Usage:
#   BASE=develop DRY_RUN=1 bash archive_merged.sh        # dry-run
#   BASE=develop DRY_RUN=0 bash archive_merged.sh        # do it
#   BASE=main    DRY_RUN=0 bash archive_merged.sh        # use main as base

set -euo pipefail

BASE="${BASE:-develop}"          # or main
REMOTE="${REMOTE:-origin}"
TODAY="$(date +%F)"
DRY_RUN="${DRY_RUN:-1}"          # 1=dry-run, 0=execute

# branches you will NEVER touch here
PROTECTED_REGEX='^(main|master|develop|dev|HEAD)$'

echo "Fetching and pruning…"
git fetch --all --prune

# Ensure base exists locally
git show-ref --verify --quiet "refs/heads/$BASE" || git checkout -B "$BASE" "$REMOTE/$BASE"

# All local branches fully merged into BASE (excluding BASE itself)
merged_branches=$(git branch --merged "$BASE" --format='%(refname:short)' \
  | grep -Ev "$PROTECTED_REGEX" || true)

if [ -z "$merged_branches" ]; then
  echo "Nothing merged into $BASE. Clean as a whistle."
  exit 0
fi

echo "Candidates (merged into $BASE):"
echo "$merged_branches" | sed 's/^/  - /'

if [ "$DRY_RUN" -ne 0 ]; then
  echo
  echo "Dry run. To execute, run: BASE=$BASE DRY_RUN=0 bash archive_merged.sh"
  exit 0
fi

echo
echo "Archiving and deleting…"
while IFS= read -r BR; do
  # safety: skip current branch
  if [ "$BR" = "$(git rev-parse --abbrev-ref HEAD)" ]; then
    echo "Skipping current branch: $BR"
    continue
  fi

  # safety: skip protected
  if echo "$BR" | grep -Eq "$PROTECTED_REGEX"; then
    echo "Skipping protected: $BR"
    continue
  fi

  TAG="archive/$BR/$TODAY"

  # Tag the branch tip
  COMMIT=$(git rev-parse "$BR")
  echo "Tagging $BR @ $COMMIT -> $TAG"
  git tag -a "$TAG" "$BR" -m "Archive $BR on $TODAY before deletion"

  # Push just this tag
  echo "Pushing tag $TAG"
  git push "$REMOTE" "refs/tags/$TAG"

  # Delete remote branch if it exists upstream
  if git ls-remote --exit-code --heads "$REMOTE" "$BR" >/dev/null 2>&1; then
    echo "Deleting remote branch $REMOTE/$BR"
    git push "$REMOTE" --delete "$BR"
  else
    echo "Remote branch $REMOTE/$BR not found; skipping remote delete"
  fi

  # Delete local branch
  echo "Deleting local branch $BR"
  git branch -D "$BR"

  echo "Done: $BR"
  echo "—"
done <<< "$merged_branches"

echo "All set. Recover any archived branch with:"
echo '  git checkout -b <branch> "tags/archive/<branch>/<YYYY-MM-DD>"'
