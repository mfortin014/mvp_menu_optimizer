<!--
title: Automation C — Seeds library index & applied moves
labels: ["ci", "github-admin", "phase-0"]
assignees: []
uid: auto-gh-C
parent_uid: auto-gh-epic
type: chore
status: Todo
priority: P2
target: mvp-0.7.0
area: ci
doc:
pr:
-->

# Automation C — Seeds library index & applied moves

## Summary

Maintain a local **UID ↔ GitHub** index and move processed seeds from `pending/` → `applied/` once all steps succeed.

## Intent

1. Persist `.github/project-seeds/library.json` with:  
   `{ uid, issue_number, issue_node_id, project_item_id, parent_uid, created_at }`
2. Move only fully processed seeds to `applied/` to prevent reprocessing

## Acceptance

- `library.json` contains all processed UIDs without duplicates
- Seeds move to `applied/` only after all gating steps pass
- Re-runs are clean and idempotent

## Evidence

- PR showing `library.json` updates and file moves
- Run logs summarizing indexed items & moved seeds
