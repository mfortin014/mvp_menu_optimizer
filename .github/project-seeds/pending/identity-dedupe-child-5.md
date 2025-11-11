<!--
title: Identity & Dedupe — Promotion APIs & observability
labels: ["intake"]
assignees: []
uid: identity-dedupe-child-5
parent_uid: identity-dedupe-epic
type: Feature
status: draft
priority: P2
target: mvp-0.9.0
area: Intake
series: "Throughput"
work_type: Child
story_points: 3
step: 5
doc: "docs/proposals/2025-11-05-universal-identity-and-dedupe.md"
-->

# Identity & Dedupe — Promotion APIs & observability

> Depends on `identity-dedupe-child-4` so promotion events reflect reviewer decisions.

## Summary

- Expose APIs/events for other engines to consume dedupe outcomes (e.g., list alias map entries, fetch canonical/alias pairs).
- Store artifacts (decision reports, errors) and add dashboards for cluster throughput, auto-accept %, reviewer load.
- Ensure deploy markers/alerts fire when dedupe accuracy or backlog drifts.

## Acceptance

- [ ] Public RPCs/events deliver canonical + alias information for downstream consumers
- [ ] Decision artifacts accessible per dataset/review session
- [ ] Observability dashboard charts auto-accept %, manual review queue length, false-positive corrections
- [ ] Deploy marker `mvp-0.9.0` tied to dedupe rollout
