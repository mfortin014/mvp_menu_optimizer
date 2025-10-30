<!--
title: Orphan seed — agile field smoke test
labels: ["ci","github-admin"]
assignees: []
uid: ghwf-upgrade-orphan-smoketest
type: Chore
status: Draft
priority: P2
area: ci
project: "test"
target: mvp-0.9.0
start_date: 2025-02-10
target_date: 2025-02-21
sprint: "2025-02-10"
doc: "docs/policy/seed_schema.md"
-->

# Orphan seed — agile field smoke test

Validate that the updated seeding automation can populate the new agile-friendly fields on an orphan work item without a parent epic.

## Acceptance check
- [ ] Workflow writes Start Date, Target Date, Target Release, and Sprint iteration values without manual fixes
- [ ] Resulting issue stays in Draft status with correct Priority and Area
- [ ] Project Insights includes the item in Velocity charts under Series defaults

