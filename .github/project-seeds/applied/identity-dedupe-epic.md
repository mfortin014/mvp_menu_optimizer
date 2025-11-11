<!--
title: Epic — Universal Identity & Dedupe Platform
labels: ["intake"]
assignees: []
uid: identity-dedupe-epic
type: Feature
status: draft
priority: P1
target: mvp-0.9.0
area: Intake
children_uids: ["identity-dedupe-child-1","identity-dedupe-child-2","identity-dedupe-child-3","identity-dedupe-child-4","identity-dedupe-child-5"]
series: "Throughput"
work_type: Epic
doc: "docs/proposals/2025-11-05-universal-identity-and-dedupe.md"
-->

# Epic — Universal Identity & Dedupe Platform

Implements the dataset registry, normalization pipeline, matching engine, reviewer workbench hooks, and observability defined in `docs/proposals/2025-11-05-universal-identity-and-dedupe.md`. Builds on the ingestion staging/alias groundwork (`ingestion-child-1`, `ingestion-child-3`).

## Acceptance

- [ ] All child issues complete and verified
- [ ] Datasets can be registered, normalized, scored, and reviewed with audit trail
- [ ] Alias map promoted outcomes consumable by downstream engines
