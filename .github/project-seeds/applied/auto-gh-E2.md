<!--
Type: Chore
Labels: ["ci","github-admin","phase:phase-0"]
uid: auto-gh-E2
parent_uid: auto-gh-epic
priority: P2
status: Todo
area: ci
target: mvp-0.7.0
-->

# Automation E2 — Swap-in generic bricks & rewire workflows (minimal behavior delta)

## Summary

Replace in-workflow logic with **generic actions** and point our thin workflows at them. Keep old workflow names bridged for one cycle. Behavior should be equivalent (or strictly safer/idempotent).

## Deliverable

Workflows call small, reusable **gh-\* actions**; GOC-specific glue stays in `goc-*`; domain logic moves into `scripts/goc/*`.

## Tasks

- [ ] Extract existing logic behind actions:  
       `gh-move-files-commit`, `gh-open-pr`, `gh-auto-merge-pr`, `gh-link-hierarchy`.  
       (Each action: one capability, clear inputs/outputs, good logs. No repo-specific naming.)
- [ ] Introduce `scripts/goc/` modules for domain rules (seed parsing, routing, fields, library, hierarchy). Actions call these modules.
- [ ] Rewire workflows to call the new actions (keep behavior equivalent).  
       - Add **bridge**: `workflow_run.workflows` references old AND new names for one release window.
- [ ] Tighten job permissions to least-privilege (seed, hierarchy, backfill, consume).
- [ ] Remove duplicated inline logic from workflows.

## Acceptance

- New actions are used by the workflows; runs are green; outputs match previous behavior (no regressions).
- Bridge works: chained runs still trigger. After one green cycle on `main`, old names are removable.
- Workflows are visibly thinner; logic is only in actions + `scripts/goc/*`.

## Evidence

- PR(s) replacing inline steps with action calls
- Action logs showing inputs/outputs and idempotent behavior
- Screenshot of Actions list with new workflow names and successful runs
