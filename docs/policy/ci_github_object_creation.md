# CI — GitHub Object Creation Automation (Projects v2 + Seeds)

Updated: 2025-10-07

This policy explains the CI configuration to:

- Create Issues/Epics from Markdown **seeds**,
- Add them to **Projects v2**,
- Write **custom Project fields**,
- (Later) Create **native parent/child** links via Sub-issues,
- Keep runs **idempotent** and production-safe.

> This doc matches our Project schema: **Status**, **Type**, **Priority**, **Target Release**, **Area**, **Series**, **Story Points**, **Step**, **Sprint**, **Start Date**, **Target Date**, **Doc Link**, **PR Link**.  
> It also matches our seed header schema in `docs/policy/seed_schema.md`.

---

## 1) Tokens, permissions, variables

### 1.1 Token reality

- The default **`GITHUB_TOKEN` does not reliably write to Projects v2**.  
  Use one of:
  - **Classic PAT** with scopes: `project` + `repo` → store as `PROJECTS_TOKEN` secret.
  - **GitHub App** with Project write perms (org setups).

We currently use a **classic PAT** for simplicity.

### 1.2 Workflow permissions

Set **minimal repo permissions** for the workflow:

```yaml
permissions:
  contents: write
  issues: write
  pull-requests: write
```

> We only elevate what we actually need. Project writes are done via GraphQL using `PROJECTS_TOKEN`, not via `GITHUB_TOKEN`.

### 1.3 Repo Variables & Secrets

**Variables (Actions → Variables):**

- `PROJECT_URL` → Main Project v2 URL (human URL)
- `PROJECT_URL_TEST` → Test Project v2 URL (human URL)
- `ALLOW_AUTOCONSUME_PR` → `"true"` to let the workflow open the “consume seeds → applied/” PR; otherwise it just prints a compare link.

**Secret (Actions → Secrets):**

- `PROJECTS_TOKEN` → Classic PAT with `project` + `repo` scopes.

---

## 2) Seeds: folders & schema

- Place new seeds in:  
  `.github/project-seeds/pending/`
- After successful processing, they are moved to:  
  `.github/project-seeds/applied/`

Headers are **HTML comments** at the top of the file and fields must follow our schema. See:

- **`docs/policy/seed_schema.md`** (authoritative)
- Arrays must be **JSON arrays** (e.g., `labels: ["ci"]`, `children_uids: ["uidA","uidB"]`)

### 2.1 Field purpose quick reference

Authoritative requirements live in `docs/policy/seed_schema.md#minimal-field-matrix`. Use the table below as a reminder of why each Project field exists:

| Project field | Purpose | Notes |
| ------------- | ------- | ----- |
| Status        | Lifecycle coordination | Automation seeds everything as **Draft**; adjust manually once work starts. |
| Type          | High-level work classification | Mirrors the Type field in Issues (Spec, Policy, Runbook, Feature, Bug, Chore). |
| Priority      | Sequencing | P0–P3 per Issues workflow. |
| Area          | Product/platform subsystem | Keeps filters from colliding with Type. |
| Target Release| Human milestone text | Use when the request explicitly calls it out. |
| Series        | Velocity roll-up grouping | Default is `Throughput`; change only when the maintainer asks. |
| Story Points  | Complexity estimate | Fibonacci scale (1,2,3,5,8,13) for child/standalone work. |
| Step          | Sequencing inside an epic | Positive integer; only appears on child issues. |
| Sprint        | Iteration assignment | Use the iteration title (e.g., `Sprint 16`) when provided; automation skips it if the iteration is missing. |
| Start Date    | Roadmap start anchor | Include only when supplied for epics/standalone items. |
| Target Date   | Expected completion | Drives roadmap views and sprint validation. |
| Doc Link / PR Link | Cross-reference | Repo-relative doc path and PR URL (when known). |

Default assignee: configure the GitHub Actions variable `DEFAULT_SEED_ASSIGNEE` (e.g., `mfortin014`). The workflow uses that value unless a seed overrides `assignees`.

---

## 3) Project routing (Main vs Test)

We support per-seed routing to avoid polluting the main Project:

- `project: "test" | "main"` chooses `PROJECT_URL_TEST` or `PROJECT_URL`
- `project_url:` (explicit URL) **overrides** both

The workflow resolves Project IDs from the URLs stored in repository variables. To enable a test board, duplicate the main Project so it retains the same field schema, set `vars.PROJECT_URL_TEST` to the duplicate’s URL, and keep the fields in sync. Until that copy exists, omit `project: "test"` so seeds route to the main board.

---

## 4) Idempotency rules we enforce

- **Create-only** for A: if an issue with the same `uid` exists, we **skip** creation and (by default) skip field rewrites.  
  Optional future flag: `update_fields: true`.
- **Project add** is treated as success if the item already exists in the Project.
- **Field writes** are skipped if values are unmapped; we log available options and keep going so you can finish manually.
- **Sub-issues**: if already linked, we treat as success.

---

## 5) Safety & environments

- Use per-seed `project: "test"` or `project_url:` to divert runs into a **Test Project** once it mirrors the main board’s schema.
- Keep **`ALLOW_AUTOCONSUME_PR`** enabled so the bot moves processed seeds to `applied/`. Disable temporarily if you need to inspect changes before moving them.
- Don’t store PATs in code; use **`secrets.PROJECTS_TOKEN`**.

---

## 6) Troubleshooting

**“Project id not found”**

- Confirm the URL is a valid **Projects v2** URL.
- Check `PROJECTS_TOKEN` scopes (must include `project` + `repo`).

**“Field option not found”**

- The value in the seed doesn’t match any option (case-insensitive) in your Project field.  
  Fix the seed or add the option to the Project, then re-run.

**“Already added / Already linked”**

- This is expected on re-runs; we treat these as successful no-ops.

---

## 7) References

- Project schema & colors: `docs/runbooks/github_projects_setup.md`
- Seed schema (authoritative): `docs/policy/seed_schema.md`
- Sub-issues: implemented in **Automation B**

---

This doc and `seed_schema.md` form the “contract” between seeds and CI. Keep headers tidy, values valid, and enjoy boring, correct automation.
