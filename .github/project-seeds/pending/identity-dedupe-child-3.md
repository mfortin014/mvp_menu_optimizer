<!--
title: Identity & Dedupe — Blocking, scoring & clustering engine
labels: ["intake"]
assignees: []
uid: identity-dedupe-child-3
parent_uid: identity-dedupe-epic
type: Feature
status: draft
priority: P1
target: mvp-0.9.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 3
doc: "docs/proposals/2025-11-05-universal-identity-and-dedupe.md"
-->

# Identity & Dedupe — Blocking, scoring & clustering engine

> Depends on `identity-dedupe-child-2` (normalized features) to produce candidate pairs.

## Summary

- Implement multi-pass blocking strategy (phonetic, n-gram, attribute buckets) to limit comparisons.
- Score candidate pairs with explainable weights (name similarity, attributes, supplier hints, UOM compatibility) and persist reasoning JSON.
- Build clustering step (connected components) with thresholds for auto-accept, review, reject buckets.

## Acceptance

- [ ] Blocking jobs generate candidate sets with tunable thresholds
- [ ] Scoring outputs reasons per pair and classifies them into confidence bands
- [ ] Clusters stored with metadata (confidence, size, status) and surfaced via SQL/RPC
- [ ] Benchmark dataset demonstrates expected auto-accept / needs-review ratios
