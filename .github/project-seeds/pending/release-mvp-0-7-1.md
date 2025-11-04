<!--
title: Standalone — Prepare release mvp-0.7.1
labels: ["release","chore"]
assignees: ["mfortin014"]
uid: release-mvp-0-7-1
type: Chore
priority: P1
target: mvp-0.7.1
area: ci
series: "Throughput"
work_type: Standalone
story_points: 3
status: Draft
-->

# Standalone — Prepare release mvp-0.7.1

We shipped a batch of CI, docs, and UI improvements after `mvp-0.7.0`. We need a tidy `mvp-0.7.1` release so both Streamlit branches (`main` preview and `prod` production) stay in sync with the latest fixes.

## Scope
- Curate `CHANGELOG.md` for everything merged since `mvp-0.7.0`.
- Bump the repo version and update any docs that reference the previous release.
- Follow the release playbook to promote the tag through staging (`main`) and production (`prod`).

## Acceptance (Done when)
- [ ] `CHANGELOG.md` includes a new `0.7.1` section with highlights from the commits since `mvp-0.7.0`, and the `Unreleased` compare link now targets `mvp-0.7.1` (per [`docs/policy/commits_and_changelog.md#5-changelog-rules-human-first`](../../docs/policy/commits_and_changelog.md#5-changelog-rules-human-first)).
- [ ] `VERSION` reads `0.7.1`, matching the release per [`docs/runbooks/release_playbook.md#1-version-bump`](../../docs/runbooks/release_playbook.md#1-version-bump).
- [ ] Any docs that surface the current release (e.g., release playbook checklists) are aligned with `mvp-0.7.1`.
- [ ] Release checklist covers staging + production promotion, including fast-forwarding the `prod` branch after approval (see [`docs/runbooks/release_playbook.md#4-production-promotion`](../../docs/runbooks/release_playbook.md#4-production-promotion)).
- [ ] Draft PR links this Issue, includes verification notes (lint/static only—no live deploys from automations), and proposes a Conventional Commit-form squash title.

## Notes
- Gather highlights from `git log mvp-0.7.0..main` and the PR templates.
- Coordinate timing with Streamlit Cloud deploy windows so `prod` promotion happens after staging smoke passes.
