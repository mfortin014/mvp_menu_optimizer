<!--
title: "test-C: Maintain upsert (Test project)"
labels: ["test","ci","github-admin","phase:phase-0"]
assignees: ["mfortin014"]
uid: "test-c-maintain-test-002"
parent_uid: "auto-gh-epic"
type: "Chore"
status: "Todo"
priority: "P2"
target: "mvp-0.7.0"
area: "ci"
doc: "docs/policy/ci_minimal.md"
project: "test"
-->

# C: Maintain upsert (Test project)

This seed validates that maintain mode:

1. Routes to the **Test** Project,
2. Upserts `.github/project-seeds/library.json` with a **non-null** `project_item_id` for the Test board,
3. Moves this seed from `pending/` → `applied/` in the consume PR.
