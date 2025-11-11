<!--
title: Data Ingestion — Mapping UI & validation/dry-run
labels: ["intake"]
assignees: []
uid: ingestion-child-2
parent_uid: ingestion-epic
type: Feature
status: Draft
priority: P1
target: mvp-0.8.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 2
doc: "docs/proposals/2025-11-05-data-ingestion-module.md"
-->

# Data Ingestion — Mapping UI & validation/dry-run

## Summary

- Streamlit wizard step(s) for upload, preset selection, auto-mapping with overrides, and transform previews.
- Validation engine surfaces schema/business/UOM issues per row with actionable hints; blocking errors gate publish.
- Dry-run page summarizes inserts/updates/quarantines and highlights cost/where-used impact placeholders.

## Acceptance

- [ ] Wizard auto-suggests mappings and allows inline edits for every supported entity
- [ ] Validation step shows blocking vs warning issues, referencing rows/columns
- [ ] Dry-run preview displays row counts, quarantines, and dedupe summary
- [ ] UI/automated test covers happy path plus validation failure
