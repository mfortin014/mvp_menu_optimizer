<!--
title: Test-Epic: CI/CD Phase 1A — Project Exporter
labels: ["test","epic","CI/CD-phase:phase-1a"]
assigness: ["mfortin014"]
uid: test-ci-cd-phase1a-epic-2
children_uids: ["test-ci-cd-phase1a-workflow-2","test-ci-cd-phase1a-schema-2","test-ci-cd-phase1a-first-export-2"]

# Project field mappings (exact names from our Project policy):
project: "test"
-->

# Test - Epic: CI/CD Phase 1A — Project Exporter

## Intent

Produce portable snapshots of the Project for coordination and metrics without touching CI gates.

## Acceptance

- [ ] Exporter workflow exists and runs on manual trigger (no schedule yet)
- [ ] Snapshot schema documented (JSON/MD artifacts, fields, enums)
- [ ] First manual export committed (`project_sync/project_state.json` and `project_status.md`)
