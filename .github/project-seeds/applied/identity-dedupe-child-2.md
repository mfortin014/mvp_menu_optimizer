<!--
title: Identity & Dedupe — Normalization & feature extraction
labels: ["intake"]
assignees: []
uid: identity-dedupe-child-2
parent_uid: identity-dedupe-epic
type: Feature
status: draft
priority: P1
target: mvp-0.9.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 2
doc: "docs/proposals/2025-11-05-universal-identity-and-dedupe.md"
-->

# Identity & Dedupe — Normalization & feature extraction

> Depends on `identity-dedupe-child-1` for dataset metadata and staging linkage.

## Summary

- Implement normalization pipeline (text cleaning, tokenization, phonetics, normalized attributes, UOM harmonization via `Conversions` helpers).
- Store features in `match_candidate` tables with reasons + metadata.
- Configure job runner (SQL/worker) to process new snapshots into feature rows with retry + audit.

## Acceptance

- [ ] Feature tables populated for sample datasets with tokens, phonetics, normalized attributes, UOM conversions
- [ ] Normalization jobs tracked with status metrics/logs
- [ ] Unit/integration tests cover tricky cases (diacritics, multilingual strings, UOM edge cases)
