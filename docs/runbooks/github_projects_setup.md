# GitHub Projects — Field Schema, Colors & Saved Views (Paste-and-do)
Updated: 2025-09-19 16:18

Goal: stand up a single Project that tracks **Specs, Policies, Runbooks, and Delivery** — using one set of fields, consistent **colors**, clear **descriptions**, and a few saved views. No external tools required.

---

## 0) Create the Project
- Scope: Repository Project (good enough for solo) or Organization Project if you want cross-repo later.
- Name: “Menu Optimizer — Product & CI/CD”

---

## 1) Add custom fields (names, types, colors, descriptions)
Add each via “+ Add field”. Colors reference the standard GitHub palette (pick the closest if exact name differs). Keep names short to reduce friction.

### Field: Status — *Single select*
**Purpose:** lifecycle across both product and process items.  
**Color-by recommendation for Boards:** *Color by Status* for instant scan value.

Options (name — color — description):
- **Draft** — Gray — Idea captured; not ready for review. Needs acceptance bullets or problem statement.  
- **In review** — Blue — Under active review (e.g., spec PR open). Expect comments/edits.  
- **Accepted** — Purple — Agreed scope/policy. Ready to plan or implement.  
- **Parked** — Purple — Intentionally paused; add a short “revisit by” note.  
- **Todo** — Yellow — Ready to start; acceptance clear; no blockers.  
- **Doing** — Orange — In progress.  
- **Done** — Green — Complete. For code: merged + deployed/flag ON. For docs: merged + linked in Bible.

*(Optional later: **Blocked** — Red — Can’t progress; add “blocked by” in the item body.)*

### Field: Type — *Single select*
**Purpose:** what kind of work this is.  
**Recommendation:** Use these colors consistently across repos.

Options (name — color — description):
- **Spec** — Purple — Product spec under review/acceptance.  
- **Policy** — Orange — Governance/process docs (e.g., branching, CI).  
- **Runbook** — Pink — Operational how-tos (e.g., release playbook).  
- **Feature** — Blue — User-visible behavior change.  
- **Bug** — Red — Regression or incorrect behavior.  
- **Chore** — Gray — Repo/infra housekeeping; low user impact.

### Field: Priority — *Single select*
**Purpose:** triage and sequencing.  
**Options:**
- **P0** — Red — Now; breaks commitments or critical path.  
- **P1** — Orange — Next up; important for MVP scope.  
- **P2** — Yellow — Nice to have for MVP; otherwise v1.  
- **P3** — Gray — Low priority; backlog parking.

### Field: Target Release — *Text* (or **Iteration** later)
**Purpose:** human milestone (e.g., `mvp-0.7.0`). If you care about dates, switch to **Iteration**.

### Field: Area — *Single select*
**Purpose:** where it belongs in product/platform.  
**Options (suggested colors):**
- **intake** — Teal — Menu intake & editor flows.  
- **identity** — Blue — Auth & tenant membership.  
- **measure** — Yellow — Metrics & analytics.  
- **chronicle** — Purple — Audit/history/chronicles.  
- **lexicon** — Pink — Shared vocab, dictionaries.  
- **ui** — Cyan — UI components/layout.  
- **db** — Indigo — Schema/migrations/data.  
- **ci** — Orange — CI/CD pipelines & envs.  
- **policy** — Gray — Governance docs.  
- **runbooks** — Green — Operational guides.

### Field: Doc Link — *Text*
**Purpose:** authoritative in-repo path (e.g., `docs/specs/04_Intake_MVP_Specs.md`).

### Field: PR Link — *Text*
**Purpose:** review artifact tying discussion to change (paste the PR URL).

---

## 2) Saved views (create these)
Create each “New view” and set filters/group/sort as described. Rename the view with the title below.

### A) Specs Review (Table)
- Filter: **Type** is “Spec”  
- Group by: **Status**  
- Sort by: **Priority** (ascending), then **Title**  
- Show fields: Status · Type · Priority · Target Release · Doc Link · PR Link · Area

### B) Delivery Board (Board)
- Filter: **Type** is not “Spec”  
- Columns: **Status** (Draft, In review, Accepted, Parked, Todo, Doing, Done)  
- **Card color:** *Status*  
- Card layout: Title · Type · Priority · Target Release · Area

### C) Policy & Runbooks (Table)
- Filter: **Type** is any of “Policy”, “Runbook”  
- Group by: **Type**  
- Sort by: **Title**  
- Show fields: Status · Priority · Doc Link · PR Link

### D) Roadmap (optional)
- Layout: **Roadmap**  
- Time source: **Target Release** (text milestones) — or add an **Iteration** field to timebox  
- Group by: **Type**  
- Filter: exclude “Chore”

---

## 3) Lightweight automation (manual-first, optional later)
MVP: update **Status** manually during review; fill **Doc/PR Links**.  
v1: add workflows to auto-add issues/PRs to the Project and nudge Status on PR open/close.

---

## 4) Labels to help triage (optional)
Create repo labels that mirror **Type** (spec, policy, runbook, feature, bug, chore) and **Area** (intake, identity, …). Nice for quick filters even outside the Project.

---

## 5) Workflow handshake (specs)
Use the “Spec Review” Issue template at `.github/ISSUE_TEMPLATE/spec_review.md`. When you open a spec Issue:
- Add it to **Specs Review**.  
- Set **Type = Spec**, **Status = Draft**, **Doc Link = path to spec**.  
- Open a Draft PR to propose acceptance → **Status = In review**; fill **PR Link**.  
- After approval → **Status = Accepted** and link the merged PR.

---

## 6) Field glossary (quick)
- **Status**: lifecycle across product and process items (color by this on Boards).  
- **Type**: kind of work; colors are consistent across repos.  
- **Area**: product/platform neighborhood.  
- **Target Release**: your version milestone; optionally an Iteration.  
- **Doc/PR Links**: create a tight handshake between docs, PRs, and the Project.

That’s it. This one Project becomes your **Town Square** you can slice by Status, Type, Area, or Release—without leaving GitHub.
