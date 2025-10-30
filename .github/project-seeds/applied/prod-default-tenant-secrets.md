<!--
title: Secrets — set Sur Le Feu default tenant ID in BWS and GitHub (prod)
labels: ["ci","policy","phase:prod-setup"]
assignees: []
uid: prod-default-tenant-secrets
parent_uid: prod-setup-epic
type: Chore
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
doc: "docs/policy/env_and_secrets.md"
pr: ""
-->

# Secrets — default tenant ID (prod)

Ensure the **Sur Le Feu** tenant_id is present and consistent in **Bitwarden Secrets Manager (BWS)** and **GitHub Environment: production** so the app boots with the correct default tenant.

## Acceptance

- BWS project for production holds a canonical `DEFAULT_TENANT_ID` (Sur Le Feu).
- GitHub **production** environment has `DEFAULT_TENANT_ID` set (masked, correct value).
- Staging and production values are verified to be **different where appropriate** and documented.
- Short note added to **Docs → Environments & Secrets** about the default tenant variable.
