<!--
title: Data Ingestion — Job registry & staging layer
labels: ["intake"]
assignees: []
uid: ingestion-child-1
parent_uid: ingestion-epic
type: Feature
priority: P1
target: mvp-0.8.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 1
doc: "docs/proposals/2025-11-05-data-ingestion-module.md"
-->

# Data Ingestion — Job registry & staging layer

## Summary

- Create ingestion job metadata tables (`job`, `job_file`, artifacts) plus staging tables for components, variants, recipes, recipe lines, parties, and UOM conversions with payload JSONB + tenant guardrails.
- Implement Supabase RPC/SQL helper to open a job, capture checksum, and emit signed upload URLs.
- Seed fixtures/tests proving rows land in staging with provenance.

## Acceptance

- [ ] SQL migrations add job + staging tables with indexes and RLS
- [ ] RPC/SQL helper returns job_id and upload target
- [ ] Sample job writes rows for every target entity with file/row lineage
- [ ] Proposal doc updated if schema deviates from design
