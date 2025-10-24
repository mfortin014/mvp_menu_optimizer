<!--
title: Update project field documentation for agile workflow
labels: ["docs","ci"]
assignees: []
uid: ghwf-upgrade-docs
parent_uid: ghwf-upgrade-epic
type: Policy
status: Draft
priority: P2
area: ci
series: "Throughput"
story_points: 3
step: 3
doc: "docs/policy/seed_schema.md"
-->

# Update project field documentation for agile workflow

Refresh internal docs so the new project fields, status lifecycle, and agile conventions are clear to contributors.

## Acceptance criteria
- [ ] `docs/policy/seed_schema.md` describes Step, Sprint, Story Points, Series, and Start Date fields with usage rules
- [ ] `docs/policy/ci_github_object_creation.md` covers the updated automation behavior and minimal field matrix
- [ ] Velocity and WIP guardrails documented (include carryover, counting on completion, stable scale)
- [ ] Changelog or communication notes prepared if policy updates require announcement

## Notes
- Coordinate terminology between docs and project field names (e.g., “Step” vs “Sequence”)
- Include examples showing Series defaulting to Throughput for child issues
- Reference AGENTS/handbooks once their updates land to avoid duplication

