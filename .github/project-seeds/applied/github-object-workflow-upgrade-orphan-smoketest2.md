<!--
title: Orphan seed — agile field smoke test 2
labels: ["ci","github-admin", "test"]
assignees: ["mfortin014"]
uid: ghwf-upgrade-orphan-smoketest-2
type: Chore
status: Draft
priority: P2
area: ci

target: mvp-0.7.1
start_date: 2025-10-21
target_date: 2025-11-21
sprint: Sprint 16
doc: "docs/policy/seed_schema.md"
-->

# Orphan seed — agile field smoke test 2

Validate that the updated seeding automation can populate the new agile-friendly fields on an orphan work item without a parent epic.

## Acceptance check

- [ ] Workflow writes Start Date, Target Date, Target Release, and Sprint iteration values without manual fixes
- [ ] Resulting issue stays in Draft status with correct Priority and Area
- [ ] Project Insights includes the item in Velocity charts under Series defaults
