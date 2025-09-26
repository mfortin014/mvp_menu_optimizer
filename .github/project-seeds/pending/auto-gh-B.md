<!--
title: Automation B — Native parent/child via Sub-issues
labels: ["ci", "github-admin", "phase-0"]
assignees: []
uid: auto-gh-B
parent_uid: auto-gh-epic
type: chore
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
doc:
pr:
-->

# Automation B — Native parent/child via Sub-issues

## Summary

Create **true** parent/child relationships so children inherit project context and **nest** correctly in Project views.

## Intent

1. When a seed has `parent_uid`, link the child as a **Sub-issue** of the parent
2. For epic seeds with `children_uids`, ensure a native link exists for each child
3. Keep the body **Children** checklist for humans (non-authoritative)

## Acceptance

- Children appear **under** their parent in Project views (no “No Parent issue” bucket)
- Re-runs do not duplicate or break relationships

## Evidence

- Run logs showing successful Sub-issue creation
- Screenshot of nested hierarchy in Project
