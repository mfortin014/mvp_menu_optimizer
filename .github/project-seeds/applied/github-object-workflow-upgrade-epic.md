<!--
title: Epic — GitHub object creation workflow upgrade
labels: ["ci","github-admin"]
assignees: []
uid: ghwf-upgrade-epic
type: Epic
status: Draft
priority: P1
area: ci
children_uids: ["ghwf-upgrade-automation","ghwf-upgrade-autolink","ghwf-upgrade-docs","ghwf-upgrade-agents"]
-->

# Epic — GitHub object creation workflow upgrade

We need to upgrade the GitHub Project automation so seeds stay aligned with our agile workflow and newly defined fields.

## Field readiness
- [x] Step field exists in GitHub and sequences epic children
- [x] Sprint iteration field defined with 1-week cadence (Mon → Sun)
- [x] Story Points field available for throughput tracking
- [x] Series single-select created for velocity charting
- [ ] Start Date field wired for roadmap views

## Status & workflow updates
- [ ] Status options trimmed to Draft, Ready, In Progress, In Review, Done
- [ ] Labels replace Blocked, Parked, Superseded handling
- [ ] Priority-Step alignment guardrails documented
- [ ] WIP limits and carryover guidance reflected in docs

## Scope & sequencing
- [ ] #ghwf-upgrade-automation — Extend seed automation for new fields and status changes
- [ ] #ghwf-upgrade-autolink — Restore auto-link-subissues.yml trigger reliability post seed run
- [ ] #ghwf-upgrade-docs — Update seed schema and workflow docs for agile conventions
- [ ] #ghwf-upgrade-agents — Amend AGENTS.md handshake for seeding without issue numbers

