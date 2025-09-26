<!--
title: Epic — GitHub Objects Creation Automation
labels: [ci, github-admin, phase:phase-0]
assignees: []
uid: auto-gh-epic
type: epic
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
children_uids: auto-gh-A,auto-gh-B,auto-gh-C,auto-gh-D
doc:
pr:
-->

# Epic — GitHub Objects Creation Automation

Build a reliable pipeline that converts Markdown seeds into **real GitHub objects** and wires them into **Projects v2** with correct fields and **native hierarchy**—idempotently.

## Goals

- Projects v2 add + **field writes** from seed headers
- **Native** parent/child relationships (true nesting)
- Local **UID↔GitHub** library for future linkage
- **Docs** for tokens/permissions + canonical seed schema & examples

## Children

- [ ] #auto-gh-A — Automation A — Projects v2 add & field writes
- [ ] #auto-gh-B — Automation B — Native parent/child via Sub-issues
- [ ] #auto-gh-C — Automation C — Seeds library index & applied moves
- [ ] #auto-gh-D — Automation D — CI perms + Seed schema & examples (policy)

## Evidence (Epic)

- Screenshot of a Project showing an epic with children **nested** and fields populated
- Successful runs across all four child issues
