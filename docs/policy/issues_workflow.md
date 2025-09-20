# Issues Workflow (MVP)
**Updated:** 2025-09-20 01:37

Purpose: keep work visible and small. Every material change starts with an **Issue**, flows through a **branch** and a **PR**, and lands with a clean **changelog** (when user-visible).

Related: [Branching & PR Protocol](branching_and_prs.md), [Commits & Changelog](commits_and_changelog.md), [Specs Workflow & Acceptance](specs_workflow.md), [CI/CD Constitution](ci_cd_constitution.md), [GitHub Projects setup](../runbooks/github_projects_setup.md).

---

## 1) When to open an Issue
- **Default:** open an Issue for Feature, Bug, Chore, Policy, or Runbook work.  
- **Skip only for tiny edits** (typos, 1–2 line docs fixes). Everything else benefits from a single source of truth and acceptance bullets.

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

Status in Project typically flows: **Todo → Doing → In review → Done**. Specs use **Draft → In review → Accepted**.

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
