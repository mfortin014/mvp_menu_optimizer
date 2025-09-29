<!--
title: Test: field writes — single select + text
labels: ["test","chore","ci"]
assignees: ["mfortin014"]
uid: test6-field-writes

# Project field mappings (exact names from our Project policy):
project: "test"
type: "Chore"
status: "Todo"
priority: "P1"
target: "mvp-0.7.0"
area: "ci"
doc: "docs/policy/ci_minimal.md"
pr: "https://github.com/mfortin014/mvp_menu_optimizer/pull/1"

-->

This is a single test issue to verify **Projects v2 field writes** are applied:

- Type, Status, Priority, Area (single-select)
- Target Release, Doc Link, PR Link (text)
