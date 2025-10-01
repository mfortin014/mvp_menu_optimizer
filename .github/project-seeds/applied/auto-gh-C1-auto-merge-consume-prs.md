<!--
title: "Automation C1 — Auto-merge consume PRs (workflow_run)"
labels: ["ci","github-admin","phase:phase-0"]
assignees: ["mfortin014"]
uid: "auto-gh-C1"
parent_uid: "auto-gh-epic"
type: "Chore"
status: "Todo"
priority: "P1"
target: "mvp-0.7.0"
area: "ci"
doc: "docs/policy/ci_minimal.md"
project: "test"
-->

# Automation C1 — Auto-merge consume PRs (workflow_run)

Follow-up to **Automation C**. Goal: auto-approve and squash-merge _consume_ PRs that only touch `.github/project-seeds/**`, even when the PR is created by `GITHUB_TOKEN`.

## Scope (v1)

- Trigger on `workflow_run` of **Seed Project Items** (no coupling to feature PRs).
- Locate the consume PR (base = branch that ran seeder; head starts with `automation/consume/`; author = `github-actions[bot]`).
- Guard: only merge when all files are under `.github/project-seeds/**`.
- Approve → squash-merge → delete consume branch.
- If branch protection blocks merge: add `manual-merge-required` label and comment.

## Acceptance

- A new seed run on a feature branch results in: consume PR auto-approved, merged, and branch deleted (or labeled/commented when protections block).
- No effect on non-consume PRs and no merges outside the guarded path.

## Notes

- Keep seeder workflow name as **Seed Project Items** (change here if renamed).
- Main holds the auto-merge workflow; feature branches only need the seeder.

<!-- seed-uid:auto-gh-C1 -->
