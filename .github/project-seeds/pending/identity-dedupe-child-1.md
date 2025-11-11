<!--
title: Identity & Dedupe — Dataset registry & staging integration
labels: ["intake"]
assignees: []
uid: identity-dedupe-child-1
parent_uid: identity-dedupe-epic
type: Feature
status: draft
priority: P1
target: mvp-0.9.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 1
doc: "docs/proposals/2025-11-05-universal-identity-and-dedupe.md"
-->

# Identity & Dedupe — Dataset registry & staging integration

> Depends on `ingestion-child-1` (job registry & staging layer) to reuse staging tables and file metadata.

## Summary

- Add `dataset`, `dataset_snapshot`, and `dataset_file` tables referencing ingestion jobs/files with tenant RLS.
- Build API/RPC to register datasets (entity type, schema hints, key strategy) and tie uploaded files to snapshots.
- Extend staging ETL to tag rows with dataset_id + snapshot_id so dedupe runs know scope.

## Acceptance

- [ ] Dataset registry tables created with indexes, RLS, and Supabase RPCs
- [ ] Upload flow associates ingestion jobs/files with dataset snapshots
- [ ] Sample dataset registration visible in admin UI or SQL view (dataset + files + ingestion job linkage)
