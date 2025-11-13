<!--
title: Data Ingestion — Nested product/BOM references
labels: ["intake"]
assignees: []
uid: ingestion-child-6
parent_uid: ingestion-epic
type: Feature
status: Draft
priority: P1
target: mvp-0.8.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 5
step: 6
doc: "docs/proposals/2025-11-05-data-ingestion-module.md"
-->

# Data Ingestion — Nested product/BOM references

## Summary

- Let ingestion jobs flag BOM lines that reference other products (recipes-as-ingredients, packages of capabilities, etc.).
- Auto-create referenced products (with empty BOM shell) when they do not exist and link them in the parent BOM.
- Maintain lineage so costing/dedupe can distinguish raw components from referenced products and enforce activation order.

## Acceptance

- [ ] Staging + publish flow capture a `is_product_reference` (or equivalent) flag on BOM lines.
- [ ] Publish path inserts/updates the referenced product in the product table instead of components, preserving tenant + source lineage.
- [ ] Parent BOM stores the correct relationship (product-to-product) and rejects cycles unless explicitly allowed by policy.
- [ ] Validation surfaces actionable errors when the referenced product is missing required data or would create circular dependencies.
