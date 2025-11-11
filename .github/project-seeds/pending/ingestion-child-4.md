<!--
title: Data Ingestion — Observability & job artifacts
labels: ["intake"]
assignees: []
uid: ingestion-child-4
parent_uid: ingestion-epic
type: Feature
priority: P2
target: mvp-0.8.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 3
step: 4
doc: "docs/proposals/2025-11-05-data-ingestion-module.md"
-->

# Data Ingestion — Observability & job artifacts

## Summary

- Persist validation reports, errors.csv, dry-run/publish summaries as downloadable artifacts per job.
- Emit structured events (`ingestion.job.*`) with tenant_id/job_id/status and row counts.
- Add lightweight dashboard (Streamlit page or metrics board) for job throughput, failure reasons, and quarantines.

## Acceptance

- [ ] Each job stores artifact URLs and they’re accessible with tenant scoping
- [ ] Events/logs capture status transitions with metrics (rows processed, duration, errors)
- [ ] Dashboard or report surfaces job success/failure trends
- [ ] Deploy marker `mvp-0.8.0` recorded when observability live
