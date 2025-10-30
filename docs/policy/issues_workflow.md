# Issues Workflow (MVP)
**Updated:** 2025-09-20 01:37

Purpose: keep work visible and small. Every material change starts with an **Issue**, flows through a **branch** and a **PR**, and lands with a clean **changelog** (when user-visible).

Related: [Branching & PR Protocol](branching_and_prs.md), [Commits & Changelog](commits_and_changelog.md), [Specs Workflow & Acceptance](specs_workflow.md), [CI/CD Constitution](ci_cd_constitution.md), [GitHub Projects setup](../runbooks/github_projects_setup.md).

---

## 1) When to open an Issue
- **Default:** open an Issue for Feature, Bug, Chore, Policy, Runbook, or Standalone work.  
- **Skip only for tiny edits** (typos, 1–2 line docs fixes). Everything else benefits from a single source of truth and acceptance bullets.

Choose the structure that matches the work:
- **Epic** — use when a single goal spans multiple deliverables. Capture the outcome at the epic level and spin up children for each concrete slice.
- **Child** — use inside an epic to describe an actionable, independently testable slice. Each child should be shippable and scoped small enough for a short-lived branch.
- **Standalone** — use when the work stands alone without coordination needs. Standalone issues follow the same discipline as a child issue but without an epic wrapper.

Always set the Project **Work Type** field (Epic, Child, Standalone) to match the structure you pick.

**Town Square vs Library:** the Issue and its Project item are the **Town Square**; they point to the authoritative text in the repo (the **Library**).

---

## 2) Definition of Ready (DoR)
Move an Issue from **Draft/Todo** to **Doing** when:
- Acceptance bullets (“Done when…”) are clear and testable.  
- Scope is small enough to deliver in a short-lived branch.  
- Flags/Migrations/Observability considered if relevant.  
- Links are present (Doc/Spec).  
- Project fields are set (Type, Area, Priority, Target Release).

Specs have their own DoR in [Specs Workflow & Acceptance](specs_workflow.md).

---

## 3) Branching
Create a short-lived branch from `main` using **type/slug**:
- `feat/<short-slug>` — user-visible behavior  
- `fix/<short-slug>` — bug fix  
- `chore/<short-slug>` — repo/infra housekeeping  
- `docs/<short-slug>` — documentation only  
- `policy/<short-slug>` — governance docs (optional alias of docs)  
- `runbook/<short-slug>` — operational guides (optional alias of docs)

For specs, use `spec/<short-slug>`; drafts live only on the branch until accepted.

---

## 4) Pull Request (open early, merge when ready)
- Open a **Draft PR** immediately; it declares intent and gathers review.  
- Use the PR template (“Because / Changed / Result / Done when / Flags / Migrations / Observability / Changelog”).  
- Link the Issue and include **“Closes #<issue>”** when the PR will finish the work.
- Keep commits conventional; keep the PR small (micro-PRs win).

Status in Project now flows: **Draft → Ready → In Progress → In Review → Done**. Specs use **Draft → In Review → Accepted** for the review cycle.

---

## 5) CI/CD handshake
- Draft PR will run **Minimal CI** (lint/tests/smoke); fix red before review.  
- For changes with runtime impact, add the changelog line in the PR.  
- For risky changes, add a flag and write the rollback line in the PR.

---

## 6) Merge and close
- **Squash merge** to keep history linear.  
- Ensure the PR closes the Issue (closing keyword) and update **Project Status = Done**.  
- If user-visible, confirm the CHANGELOG entry and tag in the next release wave.

---

## 7) Exceptions
- **Hotfix:** branch from the last production tag, open PR, fast-track review, merge, then back-merge to `main`.  
- **Docs nit:** direct PR without an Issue is fine; still use conventional commit (`docs(...)`).

---

## 8) Templates
Use the general **Work Item** Issue template for most work. Use **Spec Review** for product specs.

- General Issue: `.github/ISSUE_TEMPLATE/work_item.md`  
- Spec Review: `.github/ISSUE_TEMPLATE/spec_review.md`

---

## 9) Glossary touchpoints
- **Area**: intake, identity, measure, chronicle, lexicon, ui, db, ci, policy, runbooks.  
- **Type**: Feature, Bug, Chore, Policy, Runbook, Spec.  
- **Target Release**: `mvp-X.Y.Z` milestone.  
- **Done when**: acceptance bullets that gate the PR merge.  
- **Town Square**: Issues/Projects. **Library**: repo docs/specs.

Keep it light. The point is to **start with an Issue**, make the next action obvious, and land the change with a tiny blast radius.

---

## 10) Status conventions

- **Allowed values** (seed automation enforces these and defaults to Draft):
  - Draft — planning or newly seeded.
  - Ready — refined and queued.
  - In Progress — actively being worked.
  - In Review — awaiting feedback or approval.
  - Done — complete, no further work.
- Retired statuses (`Blocked`, `Parked`, `Superseded`, `Todo`, `Doing`, `Accepted`) must be expressed via labels or notes instead.
- Sprint cadence and iteration alignment live in `docs/runbooks/github_projects_setup.md`; follow that policy when choosing iteration values.

---

## 11) Label conventions

Keep labels additive—never duplicate information already captured by structured Project fields (Status, Priority, Area, Type, Series). When in doubt, document nuance in the Issue body rather than minting a new label.

Common process labels:
- **Blocked** — needs an external unblock; include a short note.
- **Parked** — intentionally paused; add a “revisit by” note.
- **Test** — temporary validation item that will be cleaned up.

Set the Project **Work Type** field (Epic, Child, Standalone) on every item so the board and automation stay in sync; reserve labels for temporary state.
