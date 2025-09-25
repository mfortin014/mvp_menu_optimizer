<!--
title: ci: Phase 1A — add Project Exporter workflow (manual trigger)
labels: ["ci","CI/CD-phase:phase-1a"]
uid: ci-cd-phase1a-workflow
parent_uid: ci-cd-phase1a-epic

mode: create_only
frozen: true
lifecycle: seed_only

-->

## Intent
Add `.github/workflows/project_export.yml` that, on `workflow_dispatch`, writes:
- [ ] `project_sync/project_state.json` (items, fields, parent/child)
- [ ] `project_sync/project_status.md` (counts, per-epic progress)

## Acceptance
- [ ] Run completes and commits artifacts on a branch or as workflow artifacts.
- [ ] Does NOT run on a schedule in Phase 1A.
