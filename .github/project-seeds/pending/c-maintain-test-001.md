<!--
title: "test-C: Maintain upsert smoke test"
labels: ["test","ci","github-admin","phase:phase-0"]
assignees: ["mfortin014"]
uid: "test-c-maintain-test-001"
parent_uid: "auto-gh-epic"
type: "Chore"
status: "Todo"
priority: "P2"
target: "mvp-0.7.0"
area: "ci"
doc: "docs/policy/ci_minimal.md"
-->

# C: Maintain upsert smoke test

This seed verifies that after issue creation + project/field writes, the seeder **upserts** `.github/project-seeds/library.json` and the consume step moves the seed to `applied/` in the same PR.
