<!--
Type: Chore
Labels: ["ci","github-admin","phase:phase-0"]
uid: auto-gh-E1
parent_uid: auto-gh-epic
priority: P2
status: Todo
area: ci
target: mvp-0.7.0
-->

# Automation E1 — Establish GOC skeleton (no behavior change)

## Summary

Introduce the **GitHub Objects Creation (GOC)** structure and boundaries so future changes are small and reusable. No behavior change—only scaffolding, naming, and placement.

## Deliverable

A clean repo layout with thin workflows, empty composite actions, and a `scripts/goc` domain layer. Existing logic remains where it is; new pieces are stubs.

## Tasks

- [ ] Create folders: `scripts/goc/`, `.github/actions/gh-*/`, `.github/actions/goc-*/`.
- [ ] Add **stub composite actions** (inputs/outputs only, no logic):  
       `gh-move-files-commit`, `gh-open-pr`, `gh-auto-merge-pr`, `gh-link-hierarchy`, `goc-seed`.
- [ ] Add **no-op wrapper workflows** alongside current ones (do nothing yet):  
       `goc-seed.yml`, `goc-hierarchy.yml`, `goc-backfill.yml`, `goc-consume.yml`.
- [ ] Document boundaries in headers of each stub (what goes where; single responsibility).
- [ ] CI sanity: stubs run and log inputs; no production workflow is changed or removed.

## Acceptance

- New directories + stub actions + stub workflows exist and pass CI without altering behavior.
- Boundaries are written down (action READMEs) and consistent with our “workflows orchestrate / actions wrap / scripts do domain logic” rule.

## Evidence

- PR diff showing folder structure + stubs
- Green CI on the PR
