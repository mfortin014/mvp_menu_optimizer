# Seed File Schema (Markdown → GitHub Objects)

Updated: 2025-09-27

This document defines the **authoritative schema** for Markdown seed files that our automation converts into **GitHub Issues/Epics** and wires into **Projects v2** with correct field values and (later) native hierarchy.

> TL;DR: Put a short **HTML comment header** at the top of each seed with keys below. The page body is human-readable, not authoritative.

---

## 1) File location & naming

- Location (pending queue):  
  `.github/project-seeds/pending/*.md`
- After successful processing, files are moved to:  
  `.github/project-seeds/applied/`
- Use short, kebab-case filenames (e.g., `auto-gh-A-project-add-and-fields.md`).

---

## 2) Header format (HTML comment)

The header **must** be the first thing in the file. **Arrays must use valid JSON array syntax** (e.g., `labels: ["ci", "github-admin"]`).

```md
<!--
title: <string>                                                             # REQUIRED
labels: ["label-1", "label-2"]                                              # OPTIONAL JSON array (GitHub labels)
assignees: ["user1", "user2"]                                               # OPTIONAL JSON array
uid: <string>                                                               # REQUIRED, unique across repo
parent_uid: <string>                                                        # OPTIONAL, for native hierarchy
children_uids: ["uid1","uid2",...]                                          # OPTIONAL JSON array of strings, epic convenience

# Project field mappings (exact names from our Project policy):
type: <Spec|Policy|Runbook|Feature|Bug|Chore>                               # REQUIRED
status: <Draft|Ready|In Progress|In Review|Done>                            # OPTIONAL (automation forces "Draft")
priority: <P0|P1|P2|P3>                                                     # OPTIONAL
target: <string>                                                            # OPTIONAL, maps to "Target Release" (text)
area: <intake|identity|measure|chronicle|lexicon|ui|db|ci|policy|runbooks>  # OPTIONAL
project: <main|test>                                                        # OPTIONAL. Route to Main or Test Project. Defaults to "main" if omitted.
project_url: "https://github.com/users/<user>/projects/<n>"                 # OPTIONAL explicit Project URL override (wins over `project`)
doc: <path/to/doc.md>                                                       # OPTIONAL, maps to "Doc Link"
pr: <https://github.com/...>                                                # OPTIONAL, maps to "PR Link"
series: "Throughput"                                                        # REQUIRED, maps to "Series"
work_type: <Epic|Child|Standalone>                                          # REQUIRED, maps to "Work Type"
story_points: <1|2|3|5|8|13>                                                # OPTIONAL (see matrix), maps to "Story Points"
step: <positive integer>                                                    # OPTIONAL (see matrix), maps to "Step"
start_date: <YYYY-MM-DD>                                                    # OPTIONAL (see matrix), maps to "Start Date"
target_date: <YYYY-MM-DD>                                                   # OPTIONAL (see matrix), maps to "Target Date"
sprint: <Sprint label>                                                      # OPTIONAL (see matrix), maps to "Sprint" iteration
-->
```

### Notes

- **`uid`** is our idempotency key. The workflow embeds `<!-- seed-uid:... -->` in created Issues to find them on re-runs.
- `children_uids` must list every planned child `uid` so automation can mirror checklists and create parent/child links.
- Keys are **case-insensitive**; values for single-select fields are matched **case-insensitively** to option names in your Project.
- Extra keys are ignored.
- **Arrays must be JSON** (square brackets, quoted strings, comma separated).
- Seeds default to the maintainer configured via `vars.GH_DEFAULT_SEED_ASSIGNEE` (see `docs/policy/ci_github_object_creation.md`). Override only when a different owner is explicitly requested.
- Automation coerces every seed to **Status = Draft** even if another value is supplied. Provide the eventual status in notes if needed.
- Sprint values should match the iteration title shown in Projects (e.g., `Sprint 16`). Use the schedule lookup in `docs/runbooks/github_projects_setup.md#7-sprint-schedule` to confirm dates. If the iteration is missing, automation logs a warning and leaves the Sprint empty so you can finish configuration manually.

### Routing quick reference

- Use `project: "test"` to route a seed into the sandbox Project whose URL is stored in `vars.PROJECT_URL_TEST`.
- Use `project: "main"` (or omit the key) to route into the production Project referenced by `vars.PROJECT_URL`.
- Provide `project_url: "https://github.com/.../projects/<n>"` to override both `project` values. The seeder resolves this key first, mirroring the logic documented in `docs/policy/ci_github_object_creation.md`.

---

## 3) Supported keys (reference)

| Key             | Type                  | Maps to                              | Notes                                                                                |
| --------------- | --------------------- | ------------------------------------ | ------------------------------------------------------------------------------------ |
| `title`         | string                | Issue/PR title                       | ≤ 256 chars recommended                                                              |
| `labels`        | JSON array of strings | GitHub labels                        | Must exist or GitHub creates on the fly                                              |
| `assignees`     | JSON array of strings | Assignees                            | Defaults to maintainer set in `vars.GH_DEFAULT_SEED_ASSIGNEE`; override sparingly    |
| `uid`           | string                | Idempotency + local library          | Regex: `^[a-z0-9][a-z0-9-_.]{2,64}$`; required for every seed                        |
| `parent_uid`    | string                | Native hierarchy                     | Reference an existing UID when creating children                                     |
| `children_uids` | JSON array of strings | Epic checklist + linking             | Required for epics so automation can mirror checklists and establish sub-issues      |
| `type`          | string (enum)         | **Type** (Project single-select)     | One of: `Spec, Policy, Runbook, Feature, Bug, Chore`                                 |
| `status`        | string (enum)         | **Status** (Project single-select)   | `Draft, Ready, In Progress, In Review, Done`; automation resets to Draft on creation |
| `priority`      | string (enum)         | **Priority** (Project single-select) | `P0, P1, P2, P3`                                                                     |
| `target`        | string                | **Target Release** (Project text)    | Omit unless specifically requested                                                   |
| `area`          | string (enum)         | **Area** (Project single-select)     | `intake, identity, measure, chronicle, lexicon, ui, db, ci, policy, runbooks`        |
| `project`       | string (enum)         | **Routing**                          | `"main"` (default) or `"test"`; see §5 for current availability                      |
| `project_url`   | string (URL)          | **Routing**                          | Explicit Project URL override                                                        |
| `doc`           | string                | **Doc Link** (Project text)          | Prefer repo-relative path                                                            |
| `pr`            | string (URL)          | **PR Link** (Project text)           | Any valid URL                                                                        |
| `series`        | string                | **Series** (Project single-select)   | Required; set to `"Throughput"` unless the maintainer requests another value         |
| `work_type`     | string (enum)         | **Work Type** (Project single-select)| Required; one of `Epic`, `Child`, `Standalone`                                       |
| `story_points`  | number (integer)      | **Story Points** (Project number)    | Allowed values: 1, 2, 3, 5, 8, 13; see matrix for when to include                    |
| `step`          | number (integer)      | **Step** (Project number)            | Positive integer; include only for child issues                                      |
| `start_date`    | string (YYYY-MM-DD)   | **Start Date** (Project date)        | Include only when the request supplies it                                            |
| `target_date`   | string (YYYY-MM-DD)   | **Target Date** (Project date)       | Include only when the request supplies it                                            |
| `sprint`        | string                | **Sprint** (Project iteration)       | Iteration title (e.g., `Sprint 16`); include only when the request supplies it       |

---

## 4) Minimal field matrix

The table below uses “work type” to describe the expected relationships:

- **Epic** — seed lists `children_uids` and has no `parent_uid`.
- **Child** — seed includes a `parent_uid`.
- **Standalone** — seed has neither `children_uids` nor `parent_uid`.

Keep seeds tiny but complete. The automation validates inputs according to the table below.

| Field          | Epic (parent)                          | Child (has `parent_uid`)                                         | Standalone (no parent)                                           |
| -------------- | -------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------- |
| `status`       | Required → `Draft` (auto)              | Required → `Draft` (auto)                                        | Required → `Draft` (auto)                                        |
| `type`         | Required                               | Required                                                         | Required                                                         |
| `priority`     | Required                               | Required                                                         | Required                                                         |
| `area`         | Required                               | Required                                                         | Required                                                         |
| `series`       | Required (`Throughput`)                | Required (`Throughput`)                                          | Required (`Throughput`)                                          |
| `work_type`    | Required (`Epic`)                      | Required (`Child`)                                               | Required (`Standalone`)                                          |
| `story_points` | Do not include                         | Required (1,2,3,5,8,13)                                          | Required (1,2,3,5,8,13)                                          |
| `step`         | Do not include                         | Required (positive integer)                                      | Do not include                                                   |
| `start_date`   | Include only if provided by maintainer | Do not include                                                   | Include only if provided by maintainer                           |
| `target_date`  | Include only if provided by maintainer | Do not include                                                   | Include only if provided by maintainer                           |
| `target`       | Include only if provided by maintainer | Do not include                                                   | Include only if provided by maintainer                           |
| `sprint`       | Do not include                         | Include only if maintainer supplies value aligned to parent epic | Include only if maintainer supplies value aligned to target date |
| `doc` / `pr`   | Optional                               | Optional                                                         | Optional                                                         |

Additional guardrails:

- Children inherit scheduling from their parent epic. Set `sprint` only when the epic’s delivery window is known; otherwise omit and update post-creation.
- Standalone items should align the sprint with the **target date** (velocity counts when the work finishes). Start date may fall earlier if work begins before the sprint boundary.
- If you need a field that is “optional” above, include it only when the request explicitly calls it out.

---

## 5) Validation & behavior

- **UID uniqueness:** the workflow will **skip creating** a new issue if it finds an existing one with the same embedded `seed-uid`.
- **Option matching (single-select fields):** case-insensitive **name match**; if not found, we **warn and skip** writing that field (no failure).
- **Best-effort writes:** when validations fail (missing iteration, invalid number, etc.), we log a warning and continue so you can finish the value manually in GitHub.
- **Order of operations (post-creation):**
  1. Add to **Project** (Automation A)
  2. Write **fields** (Automation A)
  3. Create **native parent/child links** (Automation B)
  4. Update **library.json** and move seed to **applied/** (Automation C)
- **Body checklist:** maintained for epics as a human mirror; non-authoritative.
- **Idempotency:** re-runs should not duplicate items, project rows, or relationships.

---

## 6) Examples

### A) Epic with four children (A–D)

```md
<!--
title: Epic — GitHub Objects Creation Automation
labels: ["ci", "github-admin", "phase:phase-0"]
assignees: []
uid: auto-gh-epic
type: Chore
status: Draft
priority: P1
target: mvp-0.7.0
area: ci
children_uids: ["auto-gh-A","auto-gh-B","auto-gh-C","auto-gh-D"]
series: "Throughput"
work_type: Epic
doc: ""
pr: ""
-->

# Epic — GitHub Objects Creation Automation

Goals, context, and acceptance here.

## Children

- [ ] #auto-gh-A — Automation A — Projects v2 add & field writes
- [ ] #auto-gh-B — Automation B — Native parent/child via Sub-issues
- [ ] #auto-gh-C — Automation C — Seeds library index & applied moves
- [ ] #auto-gh-D — Automation D — CI perms + Seed schema & examples (policy)
```

### B) Child issue with `parent_uid`

```md
<!--
title: Automation B — Native parent/child via Sub-issues
labels: ["ci", "github-admin", "phase:phase-0"]
assignees: []
uid: auto-gh-B
parent_uid: auto-gh-epic
type: Chore
status: Draft
priority: P1
target: mvp-0.7.0
area: ci
series: "Throughput"
work_type: Child
story_points: 5
step: 1
doc: ""
pr: ""
-->

# Automation B — Native parent/child via Sub-issues

Summary

Plan

- [ ] Step 1
- [ ] Step 2
- [ ] etc

Acceptance

- [ ] Criteria 1
- [ ] Criteria 2
- [ ] etc
```

### C) Regular item with links & fields

```md
<!--
title: Automation D — CI perms + Seed schema & examples (policy)
labels: ["docs", "ci", "phase:phase-0"]
assignees: []
uid: auto-gh-D
parent_uid: auto-gh-epic
type: Policy
status: Draft
priority: P1
target: mvp-0.7.0
area: policy
series: "Throughput"
work_type: Child
story_points: 3
step: 2
doc: "docs/policy/seed_schema.md"
pr: ""
-->

# Automation D — CI perms + Seed schema & examples (policy)

Summary

Plan

- [ ] Step 1
- [ ] Step 2
- [ ] etc

Acceptance

- [ ] Criteria 1
- [ ] Criteria 2
- [ ] etc
```

### D) Quick-start seed (copy/paste)

```md
<!--
title: Quick-start — Test seed
labels: ["ci"]
assignees: ["opsforge-bot"]
uid: quick-start-test
type: Feature
status: Draft
priority: P2
target: mvp-0.7.0
area: ci
project: "test"
children_uids: ["uidA","uidB"]
series: "Throughput"
work_type: Epic
doc: "docs/policy/seed_schema.md"
pr: "https://github.com/opsforge/menu-optimizer/pull/123"
-->

Summary

Plan

- [ ] Step 1
- [ ] Step 2
- [ ] etc

Acceptance

- [ ] Criteria 1
- [ ] Criteria 2
- [ ] etc
```

---

## 6) FAQ

**What if a seed value doesn’t match a Project field option?**  
We log a **warning** and skip that field. Fix the option name in the seed (or add the option in the Project) and re-run.

**Can I change a `uid` later?**  
Avoid it. `uid` is the durable identity between seed and issue. If you must, update the issue’s embedded marker too (or let the workflow do it in a dedicated maintenance script).

**Where do I put long context?**  
In the **body**. The header stays lean and machine-parsable.
