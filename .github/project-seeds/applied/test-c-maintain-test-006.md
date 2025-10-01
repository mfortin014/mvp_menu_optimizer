<!--
title: "test-C: Consume PR template check"
labels: ["test","ci","github-admin","phase:phase-0"]
assignees: ["mfortin014"]
uid: "test-c-maintain-test-006"
parent_uid: "auto-gh-epic"
type: "Chore"
status: "Todo"
priority: "P2"
target: "mvp-0.7.0"
area: "ci"
doc: "docs/policy/ci_minimal.md"
project: "test"
-->

# C: Consume PR template check

Purpose: confirm that the consume PR now:

- targets the **current feature branch** as base,
- opens automatically (since Actions can create PRs),
- and uses the **consume.md** PR template when opened via the compare link (manual path).
