<!--
title: Fix auto-link-subissues workflow trigger reliability
labels: ["ci","github-admin"]
assignees: []
uid: ghwf-upgrade-autolink
parent_uid: ghwf-upgrade-epic
type: Bug
status: Draft
priority: P1
area: ci
series: "Throughput"
story_points: 5
step: 2
-->

# Fix auto-link-subissues workflow trigger reliability

Ensure `auto-link-subissues.yml` runs automatically after seeds land so native parent/child links stay in sync without manual reruns.

## Acceptance criteria
- [ ] Workflow triggers automatically after seeds are applied or moved to `applied/`
- [ ] Failed runs surface clear logs and retry guidance
- [ ] Updated tests or dry-runs confirm the workflow links new child issues to their epic
- [ ] Documented troubleshooting steps in the workflow README or inline comments

## Notes
- Coordinate with the seeding automation changes to avoid race conditions
- Consider backoff or dedupe guards to prevent repeated linking attempts

