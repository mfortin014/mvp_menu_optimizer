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

### Field: Status — _Single select_

**Purpose:** lifecycle across both product and process items.  
**Color-by recommendation for Boards:** _Color by Status_ for instant scan value.

Options (name — color — description):

- **Draft** — Yellow — Idea captured; not ready for review. Needs acceptance bullets or problem statement.
- **Ready** — Purple — Refined and queued; acceptance bullets clear and no blockers.
- **In Progress** — Orange — Actively being worked.
- **In Review** — Blue — Awaiting feedback or approval (e.g., PR or spec review).
- **Done** — Green — Complete. For code: merged + deployed/flag ON. For docs: merged + linked in Bible.

Use labels (`Blocked`, `Parked`) instead of additional Status options when work is paused or blocked.

### Field: Type — _Single select_

**Purpose:** what kind of work this is.  
**Recommendation:** Use these colors consistently across repos.

Options (name — color — description):

- **Spec** — Purple — Product spec under review/acceptance.
- **Policy** — Orange — Governance/process docs (e.g., branching, CI).
- **Runbook** — Pink — Operational how-tos (e.g., release playbook).
- **Feature** — Blue — User-visible behavior change.
- **Bug** — Red — Regression or incorrect behavior.
- **Chore** — Gray — Repo/infra housekeeping; low user impact.

### Field: Priority — _Single select_

**Purpose:** triage and sequencing.  
**Options:**

- **P0** — Red — Now; breaks commitments or critical path.
- **P1** — Orange — Next up; important for MVP scope.
- **P2** — Yellow — Nice to have for MVP; otherwise v1.
- **P3** — Gray — Low priority; backlog parking.

### Field: Target Release — _Text_ (or **Iteration** later)

**Purpose:** human milestone (e.g., `mvp-0.7.0`). If you care about dates, switch to **Iteration**.

### Field: Area — _Single select_

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

### Field: Series — _Single select_

**Purpose:** velocity roll-up bucket.  
**Options:**  
- **Throughput** — Default bucket used for Story Points aggregation.

### Field: Work Type — _Single select_

**Purpose:** identify whether an item is coordinating work or executing it.  
**Options (name — color — description):**  
- **Epic** — Green — Coordination umbrella with children.  
- **Child** — Emerald — Actionable slice inside an epic.  
- **Standalone** — Teal — Independent item without parent/children.

### Field: Story Points — _Number_

**Purpose:** complexity estimate for velocity tracking.  
Use the Fibonacci scale **(1, 2, 3, 5, 8, 13)**. Epics stay empty; child and standalone issues require a value.

### Field: Step — _Number_

**Purpose:** sequence sibling child issues inside an epic.  
Positive integers only; leave blank for epics and standalone work.

### Field: Sprint — _Iteration_

**Purpose:** one-week iteration (Monday → Sunday).  
Name iterations as `Sprint NN` (e.g., `Sprint 16`). Stories count toward the sprint where they finish; move unfinished work forward during rollover.

### Field: Start Date — _Date_

**Purpose:** roadmap start anchor for epics or standalone items.  
Leave blank for child issues.

### Field: Target Date — _Date_

**Purpose:** expected completion date for epics or standalone items.  
Child issues inherit scheduling from their parent; leave blank unless we explicitly capture it.

### Field: Doc Link — _Text_

**Purpose:** authoritative in-repo path (e.g., `docs/specs/04_Intake_MVP_Specs.md`).

### Field: PR Link — _Text_

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
- Columns: **Status** (Draft, Ready, In Progress, In Review, Done)
- **Card color:** _Status_
- Card layout: Title · Work Type · Type · Priority · Story Points · Step · Sprint

### C) Policy & Runbooks (Table)

- Filter: **Type** is any of “Policy”, “Runbook”
- Group by: **Type**
- Sort by: **Title**
- Show fields: Status · Priority · Doc Link · PR Link

### D) Roadmap (optional)

- Layout: **Roadmap**
- Time source: **Start Date** / **Target Date** (or Sprint if dates are not set)
- Group by: **Type**
- Filter: exclude “Chore”

---

## 3) Lightweight automation (manual-first, optional later)

MVP: update **Status** manually during review; fill **Doc/PR Links**.  
v1: add workflows to auto-add issues/PRs to the Project and nudge Status on PR open/close.

---

## 4) Labels to help triage (optional)

Keep the label set lean—only add labels for signals not already captured by structured fields. Current process labels:

- **Blocked** — needs an external unblock; include a short note.
- **Parked** — intentionally paused; include a “revisit by” note.
- **Test** — temporary validation, easy to cleanup.

Coordinate before introducing new labels so we keep filters tidy.

---

## 5) Workflow handshake (specs)

Use the “Spec Review” Issue template at `.github/ISSUE_TEMPLATE/spec_review.md`. When you open a spec Issue:

- Add it to **Specs Review**.
- Set **Type = Spec**, **Status = Draft**, **Doc Link = path to spec**.
- Open a Draft PR to propose acceptance → **Status = In Review**; fill **PR Link**.
- After approval → **Status = Done** and link the merged PR.

---

## 6) Field glossary (quick)

- **Status**: lifecycle across product and process items (color by this on Boards).
- **Type**: kind of work; colors are consistent across repos.
- **Priority**: sequencing (P0–P3).
- **Area**: product/platform neighborhood.
- **Series**: velocity roll-up bucket (default `Throughput`).
- **Work Type**: whether an item is an Epic, Child, or Standalone (single-select).
- **Story Points**: Fibonacci complexity for child/standalone issues.
- **Step**: execution order inside an epic (child issues only).
- **Sprint**: week-long iteration (`Sprint NN`, Monday → Sunday).
- **Start / Target Date**: roadmap anchors for epics or standalone work.
- **Target Release**: human milestone label (optional).
- **Doc/PR Links**: create a tight handshake between docs, PRs, and the Project.

---

## 7) Sprint schedule

The **Sprint** iteration field drives velocity charts and seed validation. Keep its schedule current by updating the Project’s iteration configuration (Project settings → Sprint field). To inspect the current mapping programmatically, run:

```bash
gh api graphql -f query='
  query($owner:String!, $repo:String!, $number:Int!) {
    repository(owner:$owner, name:$repo) {
      projectV2(number:$number) {
        fields(first: 20) {
          nodes {
            ... on ProjectV2IterationField {
              name
              configuration { iterations { title startDate duration } }
            }
          }
        }
      }
    }
  }
' -F owner=OWNER -F repo=REPO -F number=PROJECT_NUMBER
```

Interpretation tips:
- `startDate` is ISO (YYYY-MM-DD); `duration` is in days. Standard cadence is **Monday → Sunday (duration 7)**.
- Name iterations `Sprint NN` (e.g., `Sprint 16`) so seeds and dashboards stay stable.
- When a sprint ends, create the next iteration immediately so automation can target it.

Current reference:
- **Sprint 13** — 2025-10-27 → 2025-11-02 (duration 7 days)

Document temporary deviations (holidays, partial weeks) in this section so contributors know how to map dates to sprint labels.

That’s it. This one Project becomes your **Town Square** you can slice by Status, Type, Area, or Release—without leaving GitHub.
