<!--
title: Extend seeding automation for new project fields
labels: ["ci","github-admin"]
assignees: []
uid: ghwf-upgrade-automation
parent_uid: ghwf-upgrade-epic
type: Chore
status: Draft
priority: P1
area: ci
series: "Throughput"
story_points: 8
step: 1
-->

# Extend seeding automation for new project fields

Upgrade the seed processing workflow so it records the new Step, Sprint, Story Points, Series, and Start Date fields while aligning status options with the refreshed agile model.

## Acceptance criteria
- [ ] Project field writer populates Step, Sprint (iteration), Story Points, Series, and Start Date when present in seed headers
- [ ] Seeds enforce per-issue required fields (epic/orphan vs child) with actionable validation errors
- [ ] Status field updates map to Draft, Ready, In Progress, In Review, Done and ignore removed options
- [ ] Target Release and Target Date restricted to epic/orphan issues in automation logic
- [ ] Tests cover the new field permutations and minimal field rules

## Notes
- Guard against Step / Priority inconsistencies during validation
- Keep Series defaulting to "Throughput" when omitted for child issues
- Maintain idempotency so reruns do not duplicate or overwrite manual edits

