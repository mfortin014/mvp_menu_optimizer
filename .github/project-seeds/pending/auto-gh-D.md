<!--
title: Automation D — CI perms + Seed schema & examples (policy)
labels: ["docs", "ci", "phase-0"]
assignees: []
uid: auto-gh-D
parent_uid: auto-gh-epic
type: policy
status: Todo
priority: P1
target: mvp-0.7.0
area: policy
doc: docs/policy/seed_schema.md
pr:
-->

# Automation D — CI perms + Seed schema & examples (policy)

## Summary

Document:

1. Minimal **token/permission** setup for Projects v2 + Sub-issues
2. Canonical **seed file schema**, validation rules, and examples

## Deliverables

- `docs/policy/ci_minimal.md` (permissions, tokens, variables, APIs, troubleshooting)
- `docs/policy/seed_schema.md` (supported header keys, rules, examples)
  - Supported keys: `title`, `labels`, `assignees`, `uid`, `parent_uid`, `children_uids`,  
    `type`, `status`, `priority`, `target`, `area`, `doc`, `pr`
