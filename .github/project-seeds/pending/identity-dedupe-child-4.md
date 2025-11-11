<!--
title: Identity & Dedupe — Reviewer queue & decision service
labels: ["intake"]
assignees: []
uid: identity-dedupe-child-4
parent_uid: identity-dedupe-epic
type: Feature
status: draft
priority: P2
target: mvp-0.9.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 4
step: 4
doc: "docs/proposals/2025-11-05-universal-identity-and-dedupe.md"
-->

# Identity & Dedupe — Reviewer queue & decision service

> Depends on `identity-dedupe-child-3` to supply clusters and on `ingestion-child-3` for alias map integration.

## Summary

- API/UI endpoints to list clusters (filters: confidence, “needs split”, dataset, entity).
- Accept/split/reject actions that update canonical records/alias map via centralized decision service.
- Audit log capturing reviewer, decision, rationale, and timestamp; expose undo for recent merges.

## Acceptance

- [ ] Reviewer queue shows paginated clusters with sortable confidence/impact
- [ ] Accept merges canonical components (or marks duplicates) and writes alias entries atomically
- [ ] Split/reject flows update cluster status and prevent future auto-merge of rejected pairs
- [ ] Audit log + metrics track reviewer throughput/accuracy
