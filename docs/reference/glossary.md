# Glossary
**Updated:** 2025-09-19 15:18

Shared definitions for CI/CD, Git/GitHub, Supabase, and our house style.  
When in doubt, link terms here from any doc or PR.

---

### ADR (Architecture Decision Record)
A small, dated note that captures a decision, the options considered, and the reasons. Lives in `docs/adr/`. See also: [Docs Policy & Map](../policy/docs_policy.md).

### Anonymous Key (Supabase)
Public client key for Supabase that authenticates anonymous usage within Row-Level Security (RLS) constraints. Never grant admin privileges.

### Approval Gate
A manual control (e.g., “Require review to deploy to production”). In GitHub Actions use **Environments** with required reviewers. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Artifact (Immutable Artifact)
The build output you deploy (e.g., container image). Built once per commit; the **same** artifact is promoted to staging then production. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Artifact Provenance (Labels)
Metadata embedded in the artifact that records version, commit SHA, build time, and dependency digest so you can trace exactly what’s running. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Artifact Registry
A repository that stores built artifacts (e.g., container registry). Critical for “build once, promote many.”

### At-least-once (Event Delivery)
Delivery guarantee for events/logs where messages may be delivered more than once. Deduplicate downstream using a stable `correlation_id`. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Backfill
A data migration step that populates or transforms existing rows to satisfy a new schema. Part of **Expand → Migrate → Contract**.

### Back-merge
Merging a change from a release or hotfix branch back into `main` so histories remain consistent.

### Batch / Umbrella PR
A top-level PR that coordinates several small, related PRs (the “micro-PRs”). Lets you merge incrementally while keeping the big picture visible. See: [Branching & PR Protocol](../policy/branching_and_prs.md).

### Blue/Green Deployment
Two production environments (“blue” live, “green” idle). You deploy to green, switch traffic, and keep blue as rollback. We generally prefer **canary** for MVP.

### Build Once, Promote Many
Build a single immutable artifact per commit and deploy the same artifact to each environment (staging → production) without rebuilding. Ensures what you tested is exactly what you run. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Build vs CI (Commit Types)
**build**: build system or packaging changes. **ci**: continuous integration workflows or configuration changes. See: [Commits & Changelog](../policy/commits_and_changelog.md).

### Breaking Change
A change that requires users or other systems to adapt immediately (API contract change, destructive schema change without compatibility, removed behavior).  
How to mark it:
- Conventional Commits: `feat!:` or `fix!:` **and** add a `BREAKING CHANGE:` footer describing impact and required actions.  
- Versioning pre-1.0: bump **Minor** (Y).  
- Process: include migration steps in the PR, add a clear **Changed** note in the [CHANGELOG](../../CHANGELOG.md), and ensure flags/rollback are ready.

### Canary Release
Gradual exposure of a feature to a small cohort, watching metrics before widening. Often implemented with **feature flags**. See: [Environments & Secrets](../policy/env_and_secrets.md).

### CHANGELOG (Keep a Changelog)
Human-readable summary of changes per release in `CHANGELOG.md`. Curated from merged PRs and scripts. See: [Commits & Changelog](../policy/commits_and_changelog.md).

### CI (Continuous Integration)
Automated checks that run on each change: style, tests, thin smoke. Purpose: **fast feedback**. See: [Minimal CI (Week 1)](../policy/ci_minimal.md).

### CD (Continuous Delivery / Deployment)
Delivery = changes always releasable; Deployment = actually push to users. Our MVP goal: delivery yes, deployment by manual approval.

### Chore (Commit Type)
Repository housekeeping like dependency bumps or config tweaks. Use `chore(scope): …` when it doesn’t fit `build` or `ci`.

### Cohort
A subset of tenants or users who receive a feature first. Controlled with **feature flags**.

### Correlation ID
A UUID carried across services/logs so you can trace one request end-to-end. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Data Dictionary
A canonical list of entities, columns, and enumerations the app depends on. Lives in `docs/reference/` (to be added).

### DDL / DML
**DDL** (Data Definition Language): schema changes (CREATE/ALTER). **DML** (Data Manipulation Language): data changes (INSERT/UPDATE/DELETE).

### Decision Tree (Commit Intent)
Quick classifier for commits (feat, fix, docs, test, build, ci, style, refactor, chore, perf, revert). Canonical version lives in [Conventional Commits & Changelog](../policy/commits_and_changelog.md).

### Definition of Ready (DoR)
Local checklist for when a Draft PR is ready for review: scope is tight, acceptance bullets are testable, rollback exists, migrations planned if needed. See: [Branching & PR Protocol](../policy/branching_and_prs.md#4-definition-of-ready--done).

### Definition of Done (DoD)
Checklist for merge: required checks are green, observability markers considered, CHANGELOG line drafted, docs/flags updated. See: [Branching & PR Protocol](../policy/branching_and_prs.md#4-definition-of-ready--done).

### Deploy Marker
A visible marker (with version/SHA) on dashboards/logs so deploys correlate with metrics. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### DORA Metrics
Industry-standard delivery outcomes we care about: **Deployment Frequency**, **Lead Time for Changes**, **Change Failure Rate**, and **MTTR** (Mean Time to Restore). Our North Star for CI/CD. See: [CI/CD Constitution](../policy/ci_cd_constitution.md#north-star).

### Draft PR
A pull request opened intentionally before it’s ready to merge so scope and acceptance can be reviewed while work is in progress. See: [Branching & PR Protocol](../policy/branching_and_prs.md).

### E2E (End-to-End) Test
A test that exercises a full user flow. We keep these thin for MVP; most confidence comes from unit + integration + smoke.

### Environment (Local / Staging / Production / Preview)
**Local** (optional): developer laptop. **Staging**: auto-deploy on merge to main. **Production**: serves users; approval required. **Preview**: ephemeral per-PR environment (v1). See: [Environments & Secrets](../policy/env_and_secrets.md).

### Environment Variable
A key/value read at runtime to configure the app per environment (12-factor style).

### Expand → Migrate → Contract
Our safe migration pattern: add columns/tables (expand), backfill/migrate data, then remove obsolete structures (contract). See: Migrations in [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Feature Flag
A runtime switch to enable/disable code paths per tenant/user. Enables “merge early, release later.” Each flag has owner, default, removal date. See: [Environments & Secrets](../policy/env_and_secrets.md).

### Fix (Commit Type)
Bug resolved in runtime behavior. Example: `fix(intake): clamp negative quantities`.

### Golden Path
The simplest, representative user journey that must always work. Our **smoke test** validates this path after every deploy.

### GitHub Environment
A named environment in GitHub with scoped secrets and protection rules (e.g., require reviewers to deploy to production).

### Hotfix
A small, urgent fix branched from the last production tag, then merged back into `main` with a new tag.

### Idempotency / Idempotency Key
Calling the same mutation twice yields the same effect. A client-provided unique key defends against retries/duplicates. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Immutable
An artifact or identifier that never changes once created (e.g., image digest, tag with SHA). Enables reliable promotion.

### Integration Test
Validates the contract between modules (e.g., DB layer + service). Sits between unit tests and E2E tests.

### Issue / Project (GitHub)
**Issues** track work items; **Projects** group and prioritize them. We keep trackers here, not in git history. See: [Docs Policy & Map](../policy/docs_policy.md).

### JUnit XML
A common test report format that CI uploads on failure to speed up triage. Mentioned in our Minimal CI. See: [Minimal CI (Week 1)](../policy/ci_minimal.md).

### Kebab-case (Naming)
Lowercase words separated by hyphens used for file and branch names (e.g., `feat/add-tenant-wizard`). Improves portability and link reliability.

### Keep a Changelog
Community format for writing CHANGELOG.md so humans can scan what changed. See: [Commits & Changelog](../policy/commits_and_changelog.md).

### Kill Switch (Feature Flags)
A flag or config that can immediately disable a risky path at runtime without redeploying. Every flagged feature should define a kill switch. See: [Environments & Secrets](../policy/env_and_secrets.md).

### Linear History
A repository setting that enforces merges as single commits (squash) to avoid complex graph histories.

### Lockfile / Cache Key
The lockfile (e.g., pinned requirements) provides a stable hash used as a CI cache key for dependencies, keeping builds fast and deterministic. See: [Minimal CI (Week 1)](../policy/ci_minimal.md).

### Main (Trunk)
The protected, always-releasable branch. All feature branches merge here via PR. See: [Branching & PR Protocol](../policy/branching_and_prs.md).

### Micro-PR
A very small pull request focused on one logical change. Easier to review, safer to merge.

### Migration (Database)
A repeatable script that changes schema or data. Must be forward-only and safe to rerun. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Observability
Making behavior visible via logs, metrics, and (later) traces. Includes **deploy markers** and standard IDs. See: [CI/CD Constitution](../policy/ci_cd_constitution.md).

### Perf (Commit Type)
Performance-only improvement (no behavior change).

### Pipeline / Workflow / Job / Step (GitHub Actions)
A **workflow** is a YAML file of **jobs**; each job has **steps**. Pipelines run on triggers (PRs, merges, or manual). See: [Minimal CI (Week 1)](../policy/ci_minimal.md).

### PR (Pull Request)
A proposal to merge changes. For us, PRs start as Draft, declare intent, and include acceptance bullets. See: [Branching & PR Protocol](../policy/branching_and_prs.md).

### Preview Environment
An ephemeral, per-PR deployment to click around safely. Useful in v1; out-of-scope for MVP.

### Pre-commit / Ruff / Black / Isort
Local tooling that runs before commits to keep style noise out of reviews. **pre-commit** runs hooks, **ruff** lints, **black** formats, **isort** orders imports. See: [Minimal CI (Week 1)](../policy/ci_minimal.md).

### Production
The live environment for users. Access is least privilege; deploys require approval.

### Protected Branch / Branch Protection
Rules that guard `main` (require status checks, linear history, PRs before merge).

### Refactor (Commit Type)
Internal change that doesn’t alter behavior (e.g., extracting functions).

### Release (Tag)
A semantic, immutable label (e.g., `mvp-0.6.0`) applied to `main` to mark a version.

### Release Notes
Human-readable summary of what’s in a release (also published as GitHub Release). See: [Release Playbook](../runbooks/release_playbook.md).

### RLS (Row-Level Security)
Postgres policy system (used by Supabase) that filters rows per user/tenant. Ensures tenants can only see their own data.

### Roll-forward
Fix forward with a new commit and redeploy, instead of rolling back.

### Rollback
Returning the system to a previous healthy artifact or turning a flag off. Prefer rollback over hot-fixing in production.

### Runbook
A pressure-tested, step-by-step guide used during operations or incidents (e.g., `release_playbook.md`). Lives under `docs/runbooks/`.

### SBOM (Software Bill of Materials)
A manifest of components and versions in your artifact. Useful for security and compliance; v1 item.

### Scope (Commit Scope)
A short identifier in parentheses that narrows the commit (e.g., `feat(intake): …`). Helps generate focused release notes. See: [Commits & Changelog](../policy/commits_and_changelog.md).

### Secret
Sensitive value (keys, tokens). In GitHub, store in **Environments**; locally use `.env` templates (never commit real secrets). See: [Environments & Secrets](../policy/env_and_secrets.md).

### SemVer (Semantic Versioning)
Major.Minor.Patch. Pre-1.0 we bump **Minor** for features and **Patch** for fixes. See: [Commits & Changelog](../policy/commits_and_changelog.md).

### Service Role (Supabase)
Admin-level key used for server-side operations. Treat as highly sensitive; never ship to clients.

### SLA / SLO / SLI
**SLA**: external promise. **SLO**: internal target (e.g., 99.9% success). **SLI**: measured indicator (e.g., success rate). We start with light SLOs in v1.

### Smoke Test
A small, brutal test verifying the Golden Path right after a deploy. Failure blocks or rolls back. See: [Minimal CI (Week 1)](../policy/ci_minimal.md) and [Release Playbook](../runbooks/release_playbook.md).

### Squash Merge
Merging a PR as a single commit to keep history clean. See: [Branching & PR Protocol](../policy/branching_and_prs.md).

### Staging
Pre-production environment that mirrors prod closely. Auto-deploy on merge to main for rehearsal.

### Staging Burn-in
A period where new schema or behavior runs in staging while telemetry is monitored before contracting or promoting. See: [CI/CD Constitution](../policy/ci_cd_constitution.md#migrations-expand--migrate--contract).

### Tag (Git)
A named pointer to a commit, often used for releases. Immutable by convention.

### Tenant
An isolated customer/account space. All data and actions are scoped by `tenant_id` and RLS.

### Test Pyramid
Emphasis on many fast unit tests, fewer integration tests, and very few E2E tests.

### Three Homes (Library / Town Square / Archive)
Our documentation homes by durability: **Library** (repo `docs/` for durable truths), **Town Square** (GitHub for work-in-progress planning and review), **Archive** (OneDrive for heavy packs and research). See: [Docs Policy & Map](../policy/docs_policy.md#1-the-three-homes).

### Trunk-Based Development
Working on short-lived branches that frequently merge into `main` (the trunk). See: [Branching & PR Protocol](../policy/branching_and_prs.md).

### UAT (User Acceptance Testing)
Human verification that behavior meets expectations. For MVP we do this in **staging** or behind flags in **production**.

### Umbrella PR
See **Batch / Umbrella PR**.

### Unit Test
Small, fast test for a single function or module.

### VERSION (File)
The single source of truth for the app’s version, displayed in-app and used for tagging.

### Version Pinning
Locking a dependency to a specific version to avoid surprise changes.

### xfail (Expected Failure)
A test marked as “expected to fail” when a known issue exists; keep usage rare and temporary. Mentioned in the CI failure playbook. See: [Minimal CI (Week 1)](../policy/ci_minimal.md).

### Zero-Downtime Migration
Schema/data evolution done without taking the app offline, usually via **Expand → Migrate → Contract**.