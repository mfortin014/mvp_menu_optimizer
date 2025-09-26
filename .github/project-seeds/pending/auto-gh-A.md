<!--
title: Automation A — Projects v2 add & field writes
labels: [ci, github-admin, phase:phase-0]
assignees: []
uid: auto-gh-A
parent_uid: auto-gh-epic
type: chore
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
doc:
pr:
-->

# Automation A — Projects v2 add & field writes

## Summary

Add created/found issues to a **Projects v2** board and write **custom Project fields** from seed headers—idempotently.

## Intent

1. Resolve the target Project (`PROJECT_ID` from `PROJECT_URL` if needed)
2. `addProjectV2ItemById(projectId, contentId)` after create/lookup
3. `updateProjectV2ItemFieldValue` for:
   - `type` → **Type**
   - `status` → **Status**
   - `priority` → **Priority**
   - `target` → **Target Release** (text)
   - `area` → **Area**
   - optional links: `doc` → **Doc Link**, `pr` → **PR Link**

## Acceptance

- Items appear on the Project with fields set
- Re-runs don’t duplicate project items or field rows

## Evidence

- Run logs (resolved `PROJECT_ID`, adds, field writes)
- Project screenshot showing populated fields
