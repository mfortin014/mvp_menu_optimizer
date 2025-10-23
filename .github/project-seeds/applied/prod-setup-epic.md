<!--
title: Epic — Production environment setup (Supabase + Streamlit + Secrets)
labels: ["ci","runbooks","db","streamlit","phase:prod-setup"]
assignees: []
uid: prod-setup-epic
type: Epic
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
children_uids: ["prod-db-migrate","prod-default-tenant-secrets","staging-app-rename","prod-streamlit-app","prod-smoke-and-promotion"]
doc: "docs/policy/env_and_secrets.md"
pr: ""
-->

# Epic — Production environment setup

Standing up a clean **production** environment that mirrors staging, promotes the same artifact, and respects our **SimplerTree** (staging → production) with environment-scoped secrets.

## Goals

- Production Supabase DB is built from migrations.
- Default tenant set (Sur Le Feu) across secrets.
- Current Streamlit Cloud app is clearly labeled as **staging**.
- New **production** Streamlit Cloud app configured with prod secrets.
- A thin smoke + promotion gate exists per Release Playbook.

## Done when

- All five child issues are **Done** and the app passes the production smoke.
