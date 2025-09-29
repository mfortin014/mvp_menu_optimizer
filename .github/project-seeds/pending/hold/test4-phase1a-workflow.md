<!--
title: test4-ci: Phase 1A — add Project Exporter workflow (manual trigger)
labels: ["test","ci","CI/CD-phase:phase-1a"]
uid: test4-ci-cd-phase1a-workflow
parent_uid: test4-ci-cd-phase1a-epic

# Project field mappings (exact names from our Project policy):
project: "test"
-->

## Intent

Add `.github/workflows/project_export.yml` that, on `workflow_dispatch`, writes:

- [ ] `project_sync/project_state.json` (items, fields, parent/child)
- [ ] `project_sync/project_status.md` (counts, per-epic progress)

## Acceptance

- [ ] Run completes and commits artifacts on a branch or as workflow artifacts.
- [ ] Does NOT run on a schedule in Phase 1A.
