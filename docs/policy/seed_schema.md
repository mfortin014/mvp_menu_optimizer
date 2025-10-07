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
type: <Spec|Policy|Runbook|Feature|Bug|Chore|Epic>                          # REQUIRED
status: <Draft|In review|Accepted|Parked|Todo|Doing|Done>                   # OPTIONAL (default: Todo)
priority: <P0|P1|P2|P3>                                                     # OPTIONAL
target: <string>                                                            # OPTIONAL, maps to "Target Release" (text)
area: <intake|identity|measure|chronicle|lexicon|ui|db|ci|policy|runbooks>  # OPTIONAL
project: <main|test>                                                        # OPTIONAL. Route to Main or Test Project. Defaults to "main" if omitted.
project_url: "https://github.com/users/<user>/projects/<n>"                 # OPTIONAL explicit Project URL override (wins over `project`)
doc: <path/to/doc.md>                                                       # OPTIONAL, maps to "Doc Link"
pr: <https://github.com/...>                                                # OPTIONAL, maps to "PR Link"
-->
```

### Notes

- **`uid`** is our idempotency key. The workflow embeds `<!-- seed-uid:... -->` in created Issues to find them on re-runs.
- `children_uids` is for **epic seed convenience** (checklist mirror). Native parent/child is handled by **Automation B** via Sub-issues.
- Keys are **case-insensitive**; values for single-select fields are matched **case-insensitively** to option names in your Project.
- Extra keys are ignored.
- **Arrays must be JSON** (square brackets, quoted strings, comma separated).

---

## 3) Supported keys (reference)

| Key             | Type                  | Required | Maps to                              | Rules                                                                         |
| --------------- | --------------------- | -------- | ------------------------------------ | ----------------------------------------------------------------------------- |
| `title`         | string                | Yes      | Issue/PR title                       | ≤ 256 chars recommended                                                       |
| `labels`        | JSON array of strings | No       | GitHub labels                        | Must exist or GitHub creates on the fly                                       |
| `assignees`     | JSON array of strings | No       | Assignees                            | Must be valid repo users                                                      |
| `uid`           | string                | Yes      | Idempotency + local library          | Regex: `^[a-z0-9][a-z0-9-_.]{2,64}$`                                          |
| `parent_uid`    | string                | No       | Native hierarchy (later)             | Must reference an existing UID                                                |
| `children_uids` | JSON array of strings | No       | Epic body checklist mirror           | Non-authoritative convenience                                                 |
| `type`          | string (enum)         | Yes      | **Type** (Project single-select)     | One of: `Spec, Policy, Runbook, Feature, Bug, Chore, Epic` (case-insensitive) |
| `status`        | string (enum)         | No       | **Status** (Project single-select)   | `Draft, In review, Accepted, Parked, Todo, Doing, Done`                       |
| `priority`      | string (enum)         | No       | **Priority** (Project single-select) | `P0, P1, P2, P3`                                                              |
| `target`        | string                | No       | **Target Release** (Project text)    | e.g., `mvp-0.7.0`                                                             |
| `area`          | string (enum)         | No       | **Area** (Project single-select)     | `intake, identity, measure, chronicle, lexicon, ui, db, ci, policy, runbooks` |
| `project`       | string (enum)         | No       | **Routing**                          | "main" (default) or "test"                                                    |
| `project_url`   | string (URL)          | No       | **Routing**                          | explicit project URL provided                                                 |
| `doc`           | string                | No       | **Doc Link** (Project text)          | Prefer repo-relative path                                                     |
| `pr`            | string (URL)          | No       | **PR Link** (Project text)           | Any valid URL                                                                 |

---

## 4) Validation & behavior

- **UID uniqueness:** the workflow will **skip creating** a new issue if it finds an existing one with the same embedded `seed-uid`.
- **Option matching (single-select fields):** case-insensitive **name match**; if not found, we **warn and skip** writing that field (no failure).
- **Order of operations (post-creation):**
  1. Add to **Project** (Automation A)
  2. Write **fields** (Automation A)
  3. Create **native parent/child links** (Automation B)
  4. Update **library.json** and move seed to **applied/** (Automation C)
- **Body checklist:** maintained for epics as a human mirror; non-authoritative.
- **Idempotency:** re-runs should not duplicate items, project rows, or relationships.

---

## 5) Examples

### A) Epic with four children (A–D)

```md
<!--
title: Epic — GitHub Objects Creation Automation
labels: ["ci", "github-admin", "phase:phase-0"]
assignees: []
uid: auto-gh-epic
type: Epic
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
children_uids: ["auto-gh-A","auto-gh-B","auto-gh-C","auto-gh-D"]
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
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
doc: ""
pr: ""
-->

# Automation B — Native parent/child via Sub-issues

Summary and acceptance.
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
doc: "docs/policy/seed_schema.md"
pr: ""
-->

# Automation D — CI perms + Seed schema & examples (policy)

Deliverables and acceptance.
```

---

## 6) FAQ

**What if a seed value doesn’t match a Project field option?**  
We log a **warning** and skip that field. Fix the option name in the seed (or add the option in the Project) and re-run.

**Can I change a `uid` later?**  
Avoid it. `uid` is the durable identity between seed and issue. If you must, update the issue’s embedded marker too (or let the workflow do it in a dedicated maintenance script).

**Where do I put long context?**  
In the **body**. The header stays lean and machine-parsable.
