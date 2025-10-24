<!--
title: Relax AGENTS.md handshake for seeding workflows
labels: ["docs","ci"]
assignees: []
uid: ghwf-upgrade-agents
parent_uid: ghwf-upgrade-epic
type: Policy
status: Draft
priority: P2
area: ci
series: "Throughput"
story_points: 2
step: 4
doc: "AGENTS.md"
-->

# Relax AGENTS.md handshake for seeding workflows

Adjust the agent instructions so seeding requests may proceed without an existing Issue number while keeping delivery guardrails intact.

## Acceptance criteria
- [ ] `AGENTS.md` Start-here handshake references seeding exception and points to the seeding docs
- [ ] Clarify branch + Draft PR expectations for seed-generation work
- [ ] Confirm no guidance conflicts with `docs/policy/issues_workflow.md`
- [ ] Provide rationale for when to request an Issue link vs when to seed locally

## Notes
- Coordinate with documentation updates to avoid contradictory instructions
- Run wording past maintainer for tone and clarity before merging

