<!--
title: Configure test project automation smoke checks - 6
labels: ["test"]
assignees: ["mfortin014"]
uid: test-project-bootstrap-child-1-automation-6
parent_uid: test-project-bootstrap-epic-6
type: Chore
status: Draft
priority: P1
area: ci
project: "test"
series: "Throughput"
work_type: Child
story_points: 3
step: 1
sprint: "Sprint 13"
-->

# Configure test project automation smoke checks - 6

Verify the seed workflow can safely target the sandbox project and surface iteration warnings without impacting production boards.

## Acceptance criteria

- [ ] Trigger a seed run that adds an item to the test project with Work Type, Step, and Series populated
- [ ] Record the expected warning when the sprint iteration is missing and outline the remediation
- [ ] Document cleanup steps for items created during the smoke check
