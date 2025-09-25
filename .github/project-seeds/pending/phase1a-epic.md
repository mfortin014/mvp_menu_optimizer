<!--
title: Epic: CI/CD Phase 1A — Project Exporter
labels: ["epic","CI/CD-phase:phase-1a"]
uid: ci-cd-phase1a-epic
children_uids: ["ci-cd-phase1a-workflow","ci-cd-phase1a-schema","ci-cd-phase1a-first-export"]

# snapshot semantics (create-only)
mode: create_only
frozen: true
lifecycle: seed_only
-->

# Epic: CI/CD Phase 1A — Project Exporter

## Intent
Produce portable snapshots of the Project for coordination and metrics without touching CI gates.

## Acceptance
- [ ] Exporter workflow exists and runs on manual trigger (no schedule yet)
- [ ] Snapshot schema documented (JSON/MD artifacts, fields, enums)
- [ ] First manual export committed (`project_sync/project_state.json` and `project_status.md`)
