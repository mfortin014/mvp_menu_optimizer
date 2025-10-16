# CI — GitHub Object Creation Automation (Projects v2 + Seeds)

Updated: 2025-10-07

This policy explains the CI configuration to:

- Create Issues/Epics from Markdown **seeds**,
- Add them to **Projects v2**,
- Write **custom Project fields**,
- (Later) Create **native parent/child** links via Sub-issues,
- Keep runs **idempotent** and production-safe.

> This doc matches our Project schema: **Status**, **Type**, **Priority**, **Target Release**, **Area**, **Doc Link**, **PR Link**.  
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

---

## 3) Project routing (Main vs Test)

We support per-seed routing to avoid polluting the main Project:

- `project: "test" | "main"` chooses `PROJECT_URL_TEST` or `PROJECT_URL`
- `project_url:` (explicit URL) **overrides** both

You can also override via **manual dispatch input** (see §4.1).

---

## 4) Workflow snippets (paste-and-do)

### 4.1 Triggers + optional Project URL override

```yaml
name: Seed Project Items

on:
  push:
    paths:
      - ".github/project-seeds/pending/**.md"
  workflow_dispatch:
    inputs:
      project_url_override:
        description: "Optional: override Project URL for this run (use your Test Project)"
        required: false
        type: string

permissions:
  contents: write
  issues: write
  pull-requests: write

env:
  DEFAULT_PROJECT_URL: ${{ vars.PROJECT_URL }}
  TEST_PROJECT_URL: ${{ vars.PROJECT_URL_TEST }}

jobs:
  seed:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Resolve target Project URL
        id: project
        run: |
          if [ -n "${{ github.event.inputs.project_url_override }}" ]; then
            echo "url=${{ github.event.inputs.project_url_override }}" >> $GITHUB_OUTPUT
          else
            echo "url=${DEFAULT_PROJECT_URL}" >> $GITHUB_OUTPUT
          fi
      - run: echo "Seeding into: ${{ steps.project.outputs.url }}"
```

> Internally, our seeder also reads per-seed `project` / `project_url` headers to route each item individually.

### 4.2 Resolve Project node id (GraphQL)

```yaml
- name: Resolve Project node id
  id: project_id
  env:
    GH_TOKEN: ${{ secrets.PROJECTS_TOKEN }}
  run: |
    node -e '
      (async () => {
        const { GraphQLClient, gql } = await import("graphql-request");
        const url = process.env.PROJECT_URL_TO_RESOLVE || process.env.PROJECT_URL || "";
        const token = process.env.GH_TOKEN;
        if(!url) { throw new Error("Missing Project URL"); }

        // Minimal resolver: ask for node by URL
        // Tip: You can also derive org/user & project number then query owner.projectsV2
        const client = new GraphQLClient("https://api.github.com/graphql", {
          headers: { Authorization: `Bearer ${token}` }
        });

        const q = gql`query($url:String!){
          resource(url:$url){ ... on ProjectV2 { id title } }
        }`;

        const data = await client.request(q, { url });
        if(!data?.resource?.id) { throw new Error("Project id not found for URL: "+url); }
        console.log("PROJECT_ID="+data.resource.id);
      })().catch(e => { console.error(e); process.exit(1); });
    ' > project_env
    cat project_env >> $GITHUB_ENV
```

> Our production workflow caches the id per URL in-run.

### 4.3 Add issue to Project (create-only path)

```yaml
- name: Add to Project (create-only path)
  env:
    GH_TOKEN: ${{ secrets.PROJECTS_TOKEN }}
  run: |
    node -e '
      (async () => {
        const { GraphQLClient, gql } = await import("graphql-request");
        const client = new GraphQLClient("https://api.github.com/graphql", {
          headers: { Authorization: `Bearer ${process.env.GH_TOKEN}` }
        });

        const projectId = process.env.PROJECT_ID;
        const contentId = process.env.CONTENT_NODE_ID; // resolved from issue number
        const m = gql`mutation($projectId:ID!, $contentId:ID!){
          addProjectV2ItemById(input:{projectId:$projectId, contentId:$contentId}) {
            item { id }
          }
        }`;
        await client.request(m, { projectId, contentId });
        console.log("Added to Project:", projectId);
      })().catch(e => { console.error(e); process.exit(1); });
    '
```

### 4.4 Write Project fields

```yaml
- name: Update Project fields
  env:
    GH_TOKEN: ${{ secrets.PROJECTS_TOKEN }}
  run: |
    node -e '
      (async () => {
        const { GraphQLClient, gql } = await import("graphql-request");
        const client = new GraphQLClient("https://api.github.com/graphql", {
          headers: { Authorization: `Bearer ${process.env.GH_TOKEN}` }
        });

        const projectId = process.env.PROJECT_ID;
        const itemId = process.env.PROJECT_ITEM_ID; // from addProjectV2ItemById
        // Assume we discovered fieldId + optionId map earlier in the run:
        const fieldId = process.env.FIELD_ID_TYPE;
        const optionId = process.env.OPTION_ID_TYPE_FEATURE;

        const m = gql`mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optionId:String!){
          updateProjectV2ItemFieldValue(input:{
            projectId:$projectId, itemId:$itemId,
            fieldId:$fieldId,
            value:{ singleSelectOptionId:$optionId }
          }) { projectV2Item { id } }
        }`;
        await client.request(m, { projectId, itemId, fieldId, optionId });
        console.log("Updated fields on item:", itemId);
      })().catch(e => { console.error(e); process.exit(1); });
    '
```

### 4.5 Create native Parent/Child (Sub-issues) — B enables this

B uses the **REST Sub-issues API** after parent/child issue numbers are known.

```yaml
- name: Link Parent ⇄ Child (Sub-issues)
  env:
    GH_TOKEN: ${{ secrets.PROJECTS_TOKEN }}
  run: |
    PARENT=${PARENT_NUMBER}
    CHILD=${CHILD_NUMBER}
    curl -sS -X POST \
      -H "Authorization: Bearer ${GH_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PARENT}/sub_issues \
      -d "{\\"sub_issue_id\\": ${CHILD}}"
    echo "::notice::Linked parent #${PARENT} ⇄ child #${CHILD}"
```

> B also pre-checks existing links to keep runs idempotent.

---

## 5) Idempotency rules we enforce

- **Create-only** for A: if an issue with the same `uid` exists, we **skip** creation and (by default) skip field rewrites.  
  Optional future flag: `update_fields: true`.
- **Project add** is treated as success if the item already exists in the Project.
- **Field writes** are skipped if values are unmapped; we log available options.
- **Sub-issues**: if already linked, we treat as success.

---

## 6) Safety & environments

- Use per-seed `project: "test"` or `project_url:` to divert runs into a **Test Project**.
- Keep **`ALLOW_AUTOCONSUME_PR`** off until you’ve verified Project add/fields/hierarchy are correct; turning it on lets the bot open the “pending → applied” PR.
- Don’t store PATs in code; use **`secrets.PROJECTS_TOKEN`**.

---

## 7) Troubleshooting

**“Project id not found”**

- Confirm the URL is a valid **Projects v2** URL.
- Check `PROJECTS_TOKEN` scopes (must include `project` + `repo`).

**“Field option not found”**

- The value in the seed doesn’t match any option (case-insensitive) in your Project field.  
  Fix the seed or add the option to the Project, then re-run.

**“Already added / Already linked”**

- This is expected on re-runs; we treat these as successful no-ops.

---

## 8) References

- Project schema & colors: `docs/policy/github_projects_setup.md`
- Seed schema (authoritative): `docs/policy/seed_schema.md`
- Sub-issues: implemented in **Automation B**

---

This doc and `seed_schema.md` form the “contract” between seeds and CI. Keep headers tidy, values valid, and enjoy boring, correct automation.
