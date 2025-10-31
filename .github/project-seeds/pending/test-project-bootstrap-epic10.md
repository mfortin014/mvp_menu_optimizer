<!--
title: Epic — bootstrap test project workflows - 10
labels: ["test"]
assignees: ["mfortin014"]
uid: test-project-bootstrap-epic-10
type: Chore
status: Draft
priority: P2
area: ci
project: "test"
series: "Throughput"
work_type: Epic
children_uids: ["test-project-bootstrap-child-1-automation-10","test-project-bootstrap-child-2-documentation-10"]
start_date: 2025-10-30
target_date: 2025-10-31
target: mvp-0.7.1
-->

# Epic — bootstrap test project workflows - 10

Stand up the initial automation and documentation needed to validate the test project board without touching production items.

## Goals

- Confirm seed workflow writes Work Type, Step, and Series correctly in the sandbox project
- Capture instructions for maintaining and cleaning up the test board
- Produce a standalone smoke item to exercise board views

## Children

- [ ] #test-project-bootstrap-automation-child — Configure smoke checks against the test project
- [ ] #test-project-bootstrap-docs-child — Document test project procedures and cleanup
