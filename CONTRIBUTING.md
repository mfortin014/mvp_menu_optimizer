# CONTRIBUTING (MVP)
**Updated:** 2025-09-19 13:23

Audience: solo/tiny team. Purpose: make work small, visible, and reversible. Terms link to the [Glossary](docs/reference/glossary.md).  
Examples of filenames in this document are wrapped in backticks to avoid accidental links (e.g., `VERSION`, `V003__add_tenant_id.sql`).

---

## How we work
- **Trunk-based**: `main` is always releasable. No permanent `develop`.
- **Small branches**: open a **Draft PR** immediately, keep scope tight, merge quickly.
- **Squash-merge** to `main`; delete branches after merge.
- Build once, promote the **same artifact** to staging then production.

See: [Branching & PR Protocol](docs/policy/branching_and_prs.md).

---

## Branches & naming
Use lowercase with slashes: `feat/short-slug`, `fix/short-slug`, `docs/policy-…`, `chore/…`, `ci/…`, `refactor/…`, `test/…`.  
Open a Draft PR as soon as you branch.

---

## Pull requests (intent-first)
Use the template at `.github/pull_request_template.md`. Fill **Because / Changed / Result / Done when / Out of scope / Flags / Migrations / Observability / Changelog**.  
Graduate from Draft when acceptance bullets pass locally and checks are nearly green.

---

## Definition of Ready / Done
**Ready** (leave Draft):
- One change story, clearly scoped.
- Acceptance bullets are specific and testable.
- Rollback plan (artifact or flag OFF).
- If schema changes: **Expand → Migrate → Contract** plan exists.

**Done** (merge):
- All required checks pass (see [Minimal CI](docs/policy/ci_minimal.md)).
- Observability: deploy marker considered; IDs present (version, tenant, request, correlation).
- **CHANGELOG** line written in the PR.
- Related docs/flags updated if needed.

---

## Required checks (Week 1)
- Style: ruff + formatter in check mode.
- Tests: unit + thin smoke (Golden Path).  
- No flaky tests; quarantine or fix within 48h.

See: [Minimal CI (Week 1)](docs/policy/ci_minimal.md).

---

## Commits & changelog
Follow **Conventional Commits**: `type(scope): subject`. One intent per commit.  
Use scopes like `intake`, `identity`, `measure`, `chronicle`, `lexicon`, `ui`, `db`, `ci`, `policy`, `runbooks`.  
Curate human-friendly entries in `CHANGELOG.md` (Keep a Changelog).

See: [Commits & Changelog](docs/policy/commits_and_changelog.md).

---

## Environments & secrets
- SimplerTree: **staging** (auto on merge) → **production** (manual approval).  
- Secrets live in GitHub **Environments** (`staging`, `production`); repo contains only templates: `.env.example`, `.streamlit/secrets.toml.example`.  
- Never echo secrets in logs.

See: [Environments & Secrets](docs/policy/env_and_secrets.md).

---

## Releases
- Version in `VERSION`; tags from `main` as `mvp-X.Y.Z` (pre-1.0: bump **Y** for features/breaking; **Z** for fixes).  
- Use the [Release Playbook](docs/runbooks/release_playbook.md): bump → tag → staging → smoke → approve → prod → aftercare.

---

## Migrations & flags
- **Migrations**: keep scripts idempotent under `migrations/sql/` (e.g., `V003__add_tenant_id.sql`); follow **Expand → Migrate → Contract**.  
- **Feature flags**: merge early, release later; define owner, default, removal date; support cohort rollout and kill switch.

See: [CI/CD Constitution](docs/policy/ci_cd_constitution.md).

---

## Docs
- The docs index is at `docs/README.md` (Project Bible). If a page exists and isn’t linked there, add it.  
- Put accepted specs in `docs/specs/`; use `docs/adr/` for small, dated decisions.  
- Trackers and active plans live in GitHub Issues/Projects; heavy notes in OneDrive.

See: [Docs Policy & Map](docs/policy/docs_policy.md).

---

## House style (quick)
- Keep PRs reviewable in ~15 minutes; split if larger.
- Avoid “wip/misc fixes” subjects.
- Prefer links to terms in the **Glossary** on first mention.
- Example filenames are wrapped in backticks (e.g., `supabase_schema_2025-09-16_01.sql`).

---

## Contact
Owner: Mathieu Fortin. Review cadence: quick scan monthly; deeper pass per release.
