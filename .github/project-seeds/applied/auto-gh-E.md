<!--
title: Automation E — Workflow naming & orchestration cleanup
labels: ["ci","github-admin","phase:phase-0"]
assignees: []
uid: auto-gh-E
parent_uid: auto-gh-epic
type: Chore
status: Draft
priority: P2
target: mvp-0.7.0
area: ci
-->

# Automation E — Workflow naming & orchestration cleanup

| Step     | Current File Name       | New File Name | Current Workflow Name                        | New Workflow Name |
| -------- | ----------------------- | ------------- | -------------------------------------------- | ----------------- |
| Link     | auto-link-subissues.yml |               | Auto — Link native parent/child from library |                   |
| Consume  | consume-auto-merge.yml  |               | Auto-approve & merge consume PRs             |                   |
| Backfill | library-backfill.yml    |               | Library Backfill                             |                   |
| Seeder   | seed-project-items.yml  |               | Seed Project Items                           |                   |

## Plan

- [ ] 1. Find new names and fill table above
- [ ] 2. Rename files + update `name:` fields to match above; keep `workflow_dispatch` for all.
- [ ] 3. Commit “bridge” first, then rename files; verify runs via `workflow_dispatch`.
- [ ] 4. Update badges/docs references (README, docs/policy/\*).

## Acceptance

- Workflows appear with the new names, triggers fire, no regressions.
- No dangling references to old names/paths.
