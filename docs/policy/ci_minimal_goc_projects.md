# CI Minimal (GOC add-on) — Tokens & Permissions for Projects v2 + Sub-issues
Updated: 2025-10-04

This complements your general `ci_minimal.md` by documenting the **extra bits** needed for GOC’s GitHub Projects v2 and Sub-issues.

## Secrets
- `PROJECTS_TOKEN` — **classic PAT** with scopes:
  - `project` (Projects v2 GraphQL writes)
  - `repo` (issues/PRs as needed)

> Many orgs restrict `projects:write` on `GITHUB_TOKEN`. Use this PAT explicitly where we call Projects v2.

## Variables
- `PROJECT_URL` — Main Project URL  
- `PROJECT_URL_TEST` — Test Project URL  
- `ALLOW_AUTOCONSUME_PR` — `"true"` to allow auto “consume seeds” PRs (optional)

## Minimal permissions (per job)
- **Seed**:  
  ```yaml
  permissions:
    contents: read
    issues: write
    pull-requests: write
    projects: write
  ```
- **Hierarchy**:  
  ```yaml
  permissions:
    issues: write
  ```
- **Backfill**:  
  ```yaml
  permissions:
    contents: write   # to update library.json
    issues: read
    pull-requests: read
  ```
- **Consume**:  
  ```yaml
  permissions:
    contents: write
    pull-requests: write
  ```

## Routing input (optional override)
```yaml
on:
  workflow_dispatch:
    inputs:
      project_url_override:
        description: "Override Project URL (Test or ad-hoc)"
        required: false
        type: string
```

## APIs used
- GraphQL: `addProjectV2ItemById`, `updateProjectV2ItemFieldValue`
- REST: Issues create/search, **Sub-issues** link

## Quick checks
- Seed with `project: "test"` goes to Test Project.  
- Fields mapped: Type, Status, Priority, Target, Area, Doc, PR.  
- Children nest under parent in Project views.  
- Re-run on same commit creates **no** duplicates.
