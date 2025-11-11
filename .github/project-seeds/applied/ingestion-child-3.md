<!--
title: Data Ingestion — Publish pipeline & alias writes
labels: ["intake"]
assignees: []
uid: ingestion-child-3
parent_uid: ingestion-epic
type: Feature
status: Draft
priority: P1
target: mvp-0.8.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 3
doc: "docs/proposals/2025-11-05-data-ingestion-module.md"
-->

# Data Ingestion — Publish pipeline & alias writes

## Summary

- Build publish RPC / stored procedures that transform validated staging rows into canonical tables with idempotent upserts.
- Generate alias map entries for each source row to canonical component/variant/recipe IDs; replays skip duplicates.
- Quarantine handling for partial failures and clean retry path.

## Acceptance

- [ ] Publish job promotes staged data into canonical tables with transactional safety
- [ ] Alias entries created for every source row with tenant_id/file_id/row_ref linkage
- [ ] Replay of same job proves idempotency and reuses alias decisions
- [ ] Quarantined rows expose reasons and can be retried after fixes
