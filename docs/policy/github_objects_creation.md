# GitHub Objects Creation (GOC) — Architecture & Design
Updated: 2025-10-04

This document describes the **architecture, responsibilities, and design rules** for the **GitHub Objects Creation (GOC)** system. GOC turns Markdown **seed files** into real GitHub objects (Issues/Epics), writes **Projects v2** fields, creates **native hierarchy**, and maintains a **Seed Library** for idempotency.

---

## 1) System goals (non-negotiables)
- **Idempotent**: re-runs must not duplicate issues, project items, or links.
- **Least-privilege**: every job has only the permissions it needs.
- **Separation of concerns**: workflows orchestrate, actions wrap, **scripts do domain logic**.
- **Repo-agnostic**: generic actions (`gh-*`) are reusable across repos.
- **Human-auditable**: logs explain routing, field writes, and hierarchy operations.
- **Traceable**: every created Issue embeds `<!-- seed-uid:... -->`; commits/PRs reference seed UIDs.

---

## 2) What goes where

### `.github/workflows/` — Orchestration only
- Decides **when** to run (triggers), **in what order** (job graph), and **with what permissions**.
- Contains no business logic; calls composite actions with clear inputs/outputs.
- **Workflows (target set):**
  - `goc-seed.yml` — seed → issue → project add → field writes (optional link-after-seed)
  - `goc-hierarchy.yml` — create **Hierarchy** via Sub-issues (triggered or manual)
  - `goc-backfill.yml` — rebuild/repair Seed Library (manual + weekly schedule)
  - `goc-consume.yml` — move pending → applied & update library (optional; or handled by PR seeds)

### `.github/actions/` — Reusable building blocks
- **Generic (repo-agnostic):**
  - `gh-move-files-commit` — move files, commit, push branch
  - `gh-open-pr` — open/update PR (base/head/title/body/labels)
  - `gh-auto-merge-pr` — enable auto-merge (GraphQL)
  - `gh-link-hierarchy` — idempotent Sub-issues link (parent/child numbers or via UID)
- **GOC-specific (seed-aware or Projects-specific):**
  - `goc-seed` — parse seed, create/resolve issue, add to Project, write fields
  - `goc-project-set-fields` (optional separate action) — write Project fields only

### `scripts/goc/` — Domain logic (the brain)
- `seed_parse.ts` — parse HTML-comment header; enforce **JSON arrays** for `labels`, `assignees`, `children_uids`
- `seed_library.ts` — read/upsert/find `library.json` (UID↔Issue mapping); backfill helpers
- `routing.ts` — resolve target project (`project_url` > `project` “test/main” > repo default)
- `project_resolver.ts` — `PROJECT_URL` → node id (LRU cache per URL)
- `fields_writer.ts` — write Projects v2 fields; cache option IDs per project
- `issue_creator.ts` — create/find-by-UID; embed `<!-- seed-uid:... -->`; write checklist mirror for epics
- `hierarchy_linker.ts` — Sub-issues REST linking; pre-check existing links; idempotent
- `logger.ts` — standardized `::notice`/`::warning` helpers

> **Rule of thumb:** scripts return plain values (no `$GITHUB_OUTPUT`); actions adapt results to the runner; workflows set permissions and order.

---

## 3) Actions catalog (interfaces)

### Generic (`gh-*`)
- **gh-move-files-commit**
  - _Inputs:_ `base`, `head`, `moves_json:[{from,to}]`, `commit_message`, `dry_run`
  - _Outputs:_ `head`, `commit_sha`, `moved_count`

- **gh-open-pr**
  - _Inputs:_ `base`, `head`, `title`, `body`, `draft`, `labels_json`, `reviewers_json`, `team_reviewers_json`, `update_if_exists`
  - _Outputs:_ `pr_number`, `pr_url`

- **gh-auto-merge-pr**
  - _Inputs:_ `pr_number`, `merge_method: SQUASH|MERGE|REBASE`, `require_checks_green`
  - _Outputs:_ `automerge_enabled`

- **gh-link-hierarchy**
  - _Inputs:_ `parent_number|parent_uid`, `child_number|child_uid`, `library_path`
  - _Outputs:_ `linked`, `skipped_reason`

### GOC-specific (`goc-*`)
- **goc-seed**
  - _Inputs:_ path/glob to seeds, routing inputs (`project_url_override`), flags (`link_after_seed`)
  - _Outputs:_ counts (created, skipped, project_added, fields_written)

- **goc-project-set-fields** (optional)
  - _Inputs:_ `project_url`, `issue_node_id`, `{type,status,priority,target,area,doc,pr}`
  - _Outputs:_ `fields_written`

---

## 4) Workflow design & triggers

### `goc-seed.yml`
- **on:** `push` to `.github/project-seeds/pending/**.md`, `workflow_dispatch`
- **jobs.seed:** permissions → `contents:read`, `issues:write`, `pull-requests:write` (+`contents:write` if opening consume PR)
- Calls `goc-seed`; optional `link_after_seed: true` invokes `gh-link-hierarchy` directly

### `goc-hierarchy.yml`
- **on:** `workflow_run` (goc-seed success), `workflow_dispatch`
- **jobs.link:** permissions → `issues:write`
- Calls `gh-link-hierarchy` over new or library-listed pairs

### `goc-backfill.yml`
- **on:** `workflow_dispatch`, `schedule: weekly`
- **jobs.backfill:** permissions → `contents:read`, `issues:read`, `pull-requests:read`, `contents:write`
- Runs `scripts/goc/seed_library.ts` to rebuild `library.json`

### `goc-consume.yml` (optional)
- **on:** `workflow_run` (seed) or manual
- **jobs.consume:** permissions → `contents:write`, `pull-requests:write`
- Uses the trio: `gh-move-files-commit` → `gh-open-pr` → `gh-auto-merge-pr`

**Deprecation bridge:** for one cycle, `workflow_run.workflows` references old and new names; remove after a green main run.

---

## 5) Permissions matrix (least-privilege)

| Job              | contents | issues | pull-requests | projects |
|------------------|---------:|------:|--------------:|---------:|
| **Seed**         | read     | write | write         | write    |
| **Hierarchy**    | none     | write | none          | none     |
| **Backfill**     | read+write (library) | read | read | none |
| **Consume**      | write    | none  | write         | none     |

> Projects v2 GraphQL writes require a **classic PAT** with `project` + `repo` scopes (exposed to actions as `PROJECTS_TOKEN`). The default `GITHUB_TOKEN` is not sufficient for all org setups.

---

## 6) Data contracts

### Seed header (HTML comment at file top)
- Arrays are **JSON arrays** for `labels`, `assignees`, `children_uids`.
- Supported keys: `title`, `labels`, `assignees`, `uid`, `parent_uid`, `children_uids`, `type`, `status`, `priority`, `target`, `area`, `doc`, `pr`, `project`, `project_url`.

**Example (epic):**
```md
<!--
title: Epic — GitHub Objects Creation
labels: ["ci","github-admin","phase:phase-0"]
assignees: []
uid: auto-gh-epic
type: Epic
status: Todo
priority: P1
target: mvp-0.7.0
area: ci
children_uids: ["auto-gh-A","auto-gh-B","auto-gh-C","auto-gh-D"]
project: "main"
project_url: ""
doc: ""
pr: ""
-->
```

### Seed Library (`.github/project-seeds/library.json`)
```json
[
  {
    "uid": "auto-gh-A",
    "issue_number": 123,
    "issue_node_id": "I_kw...",
    "project_item_id": "PVTI_...",
    "parent_uid": "auto-gh-epic",
    "created_at": "2025-09-27T12:34:56Z"
  }
]
```

---

## 7) Idempotency & logging

- **Find-by-UID**: always search for the embedded `seed-uid` marker before creating.
- **Project add**: treat “already on project” as success; skip duplicates.
- **Field writes**: case-insensitive option lookup; warn and skip on unknown values (list available options in the warning).
- **Hierarchy**: pre-check parent’s sub-issues; create if missing; treat existing as success.
- **Standard log lines** (examples):
  - `route: seed=<uid> source=<project_url|project=test|main> resolved=<url> id=<PVT_*>`
  - `fields: issue=<#> wrote=Type=Chore,Status=Todo,Priority=P1`
  - `hierarchy: parent=#12 child=#34 action=linked`

---

## 8) Testing strategy

- **Dry-runs** via `workflow_dispatch` on a **Test Project** (`project_url_override` input).
- **Smoke packs**: minimal epic + two children seeds that do not touch production.
- **Weekly backfill**: ensures library stays consistent with reality.
- **Replays**: re-run the same commit to confirm idempotency (no duplicates).

---

## 9) Glossary
- **GOC**: GitHub Objects Creation
- **Hierarchy**: native Parent/Child via Sub-issues
- **Seed**: Markdown file with HTML-comment header (machine-parsed)
- **Seed Library**: local mapping from `uid` to GitHub objects
- **Routing**: logic selecting the target Project (Test vs Main vs explicit URL)

---

## 10) Appendix — Deprecation playbook
1) Introduce new workflow names; keep `workflow_run` listening to old **and** new for one cycle.  
2) Announce rename in PR body; link to green runs.  
3) Remove old names once the chain is green on `main`.
