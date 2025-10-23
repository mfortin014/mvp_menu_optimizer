<!--
title: Streamlit Cloud — create new production app
labels: ["streamlit","ci","runbooks","phase:prod-setup"]
assignees: []
uid: prod-streamlit-app
parent_uid: prod-setup-epic
type: Feature
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
doc: "docs/runbooks/release_playbook.md"
pr: ""
-->

# Streamlit Cloud — create new production app

Stand up a **new Streamlit Cloud app** for **production**, wired to the same repo artifact line, but consuming **production** environment secrets per SimplerTree.

## Acceptance

- New Streamlit Cloud app created and named clearly with “prod” / “production”.
- App configured with **GitHub production environment** secrets or `st.secrets` injected from CI at deploy-time only.
- Health check page or home screen boots with production **DEFAULT_TENANT_ID**.
- Deploy marker emitted on first prod deploy.

## Notes

- Artifact must be the same as staging (“build once, promote many”).
