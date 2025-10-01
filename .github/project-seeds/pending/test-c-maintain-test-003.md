<!--
title: "test-C: Consume PR base-branch check"
labels: ["test","ci","github-admin","phase:phase-0"]
assignees: ["mfortin014"]
uid: "test-c-maintain-test-003"
parent_uid: "auto-gh-epic"
type: "Chore"
status: "Todo"
priority: "P2"
target: "mvp-0.7.0"
area: "ci"
doc: "docs/policy/ci_minimal.md"
project: "test"
-->

# C: Consume PR base-branch check

This seed is for verifying that the consume PR now targets the **current ref** (feature branch) instead of always `main`. It should:

- create the Issue,
- add it to the **Test** Project and write fields,
- upsert `.github/project-seeds/library.json`,
- push a short-lived **consume** branch and show a compare link with the **feature branch as base** (since repo forbids bot PRs right now).
