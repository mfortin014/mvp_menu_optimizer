<!--
title: Epic — bootstrap test project workflows - 6
labels: ["test"]
assignees: ["mfortin014"]
uid: test-project-bootstrap-epic-6
type: Chore
status: Draft
priority: P2
area: ci
project: "test"
series: "Throughput"
work_type: Epic
children_uids: ["test-project-bootstrap-child-1-automation-6","test-project-bootstrap-child-2-documentation-6"]
start_date: 2025-10-30
target_date: 2025-10-31
target: mvp-0.7.1
-->

# Epic — bootstrap test project workflows - 6

Stand up the initial automation and documentation needed to validate the test project board without touching production items.

## Goals

- Confirm seed workflow writes Work Type, Step, and Series correctly in the sandbox project
- Capture instructions for maintaining and cleaning up the test board
- Produce a standalone smoke item to exercise board views

## Children

- [ ] #test-project-bootstrap-automation-child — Configure smoke checks against the test project
- [ ] #test-project-bootstrap-docs-child — Document test project procedures and cleanup
