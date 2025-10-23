<!--
title: Production smoke + promotion gate wired
labels: ["ci","runbooks","phase:prod-setup"]
assignees: []
uid: prod-smoke-and-promotion
parent_uid: prod-setup-epic
type: Runbook
status: Todo
priority: P1
target: mvp-0.7.0
area: runbooks
doc: "docs/runbooks/release_playbook.md"
pr: ""
-->

# Production smoke + promotion gate

Add the **manual approval** step for the GitHub **production** environment and ensure a thin **smoke** runs post-deploy, aligned with our Release Playbook.

## Acceptance

- GitHub Actions uses **production** Environment with required approval.
- Promotion uses the **same artifact** that passed staging.
- Post-deploy **smoke** succeeds (Golden Path) on production.
- If smoke fails, **rollback** path documented and rehearsed.
- Project item updated to **Done** only after promotion gate passes.
