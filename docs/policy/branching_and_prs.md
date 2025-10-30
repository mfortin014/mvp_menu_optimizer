# Branching & PR Protocol (Solo Edition)
**Updated:** 2025-09-18 19:35

Purpose: make changes small, visible, and reversible. This protocol encodes **trunk-based development** and an **intent-first** pull request habit so you ship steadily without fear. Terms link to the [Glossary](../reference/glossary.md) (e.g., [Trunk-Based Development](../reference/glossary.md#trunk-based-development), [CI](../reference/glossary.md#ci-continuous-integration), [SemVer](../reference/glossary.md#semver-semantic-versioning)).

---

## 1) Principles
- **Trunk-only**: `main` is always releasable. No permanent `develop` branch.  
- **Short-lived branches**: aim for hours or a day or two, not weeks.  
- **Open a Draft PR immediately**: declare intent early, keep scope honest. Use the template in [.github/pull_request_template.md](../../.github/pull_request_template.md).  
- **Squash-merge** into `main`: linear, human history; delete branches after merge.  
- **Build once, promote**: releases are cut from `main` and tagged `mvp-X.Y.Z`. See the [Release Playbook](../runbooks/release_playbook.md).

---

## 2) Branch naming
Use lowercase, kebab-case segments; choose a **type** + short slug:

- `feat/…` new user-visible behavior ([feat](../reference/glossary.md#fix-commit-type) in Conventional Commits)  
- `fix/…` bug fix in runtime behavior  
- `chore/…` config/deps; `build/…` packaging; `ci/…` workflows  
- `refactor/…` internal change; `perf/…` performance; `docs/…` docs-only; `test/…` tests-only

**Examples**  
- `feat/intake-uom-normalization`  
- `fix/tenant-switcher-null`  
- `chore/deps-ruff-0-6`

If linking to a GitHub Issue, optionally suffix with the issue number: `feat/intake-uom-normalization-#123`.

---

## 3) Lifecycle of a PR
### Step A — Branch & Draft
1. Branch from `main`. Example: `feat/tenant-claim-wizard`.  
2. Open a **Draft PR** using the intent-first template. Fill in **Because** and **Done when** first.  
3. If your work spans multiple pieces, create an **umbrella** Draft PR and link child PRs.

### Step B — Keep it small
- If your PR exceeds ~400–600 changed lines, ask: *what can I trim or split?*  
- Save big rewrites for v1 or split across micro-PRs coordinated by an umbrella PR.

### Step C — Commit style
- Follow [Conventional Commits & Changelog](commits_and_changelog.md).  
- One **intent** per commit. If you did two different things, make two commits.  
- Use a **scope** when helpful: `feat(intake): normalize UOM on import`.

### Step D — Ready for review
A PR graduates from Draft when:  
- All acceptance bullets in **Done when** pass locally.  
- Required checks from [Minimal CI (Week 1)](ci_minimal.md) are close to green.  
- **Migrations** (if any) follow Expand → Migrate → Contract (see [CI/CD Constitution](ci_cd_constitution.md)).  
- **Observability** notes filled (version, tenant_id, request_id, correlation_id).

### Step E — Merge
- **Squash-merge** into `main`.  
- Squash title should be a Conventional Commit:  
  `feat(scope): short subject`  
  Body: a tight **Because / Changed / Result** summary (copy from the PR).  
- Delete the branch.

### Step F — After merge
- `main` deploys to **staging** automatically; post-deploy **smoke** runs (see [Minimal CI (Week 1)](ci_minimal.md)).  
- When staging looks good, promote to **production** per the [Release Playbook](../runbooks/release_playbook.md).

---

## 4) Definition of Ready & Done
**Ready (to leave Draft)**  
- Scope is tight (one change story).  
- Acceptance bullets are specific and testable.  
- Rollback plan exists (artifact rollback or flag OFF).  
- If schema changed, **migrations** plan is written (see [CI/CD Constitution](ci_cd_constitution.md)).

**Done (to merge)**  
- All required checks are green (see [Minimal CI (Week 1)](ci_minimal.md)).  
- **Observability** markers considered (deploy marker, key metrics/events).  
- **CHANGELOG** line is drafted (see [Commits & Changelog](commits_and_changelog.md)).  
- Docs or flags updated as needed.

---

## 5) Conflict hygiene
- Prefer updating your branch with `main` early (don’t sit on conflicts).  
- Resolve conflicts locally; rerun **smoke** tests before flipping Ready.  
- If a branch grows long-lived, split into micro-PRs and merge incrementally.

---

## 6) Hotfixes
- Branch from the last production tag (e.g., `mvp-0.6.0`): `hotfix/short-slug`.  
- Keep the PR tiny; tag a new patch (`mvp-0.6.1`); follow the [Release Playbook](../runbooks/release_playbook.md).  
- Back-merge to `main` if you had to cut from an older tag.

---

## 7) Batching safely (umbrella PR)
Use when a single user-facing feature needs several small PRs.

Pattern:  
- Create `feat/umbrella-tenancy-wizard` with a Draft summary and acceptance bullets.  
- Link child PRs like `feat/tenant-wizard-form`, `feat/tenant-wizard-email`, `chore/db-indexes-wizard`.  
- Merge children one by one behind **feature flags** ([Feature Flag](../reference/glossary.md#feature-flag)).  
- Close the umbrella PR once staging passes a full **smoke** of the end-to-end flow.

---

## 8) GitHub settings (branch protection, solo-friendly)
- Protect `main`: require status checks to pass.  
- Enable “Require linear history” and “Require pull request before merging.”  
- Allow only **squash-merge**. Disable rebase/merge commits.  
- Protect the production deployment branch (`prod`): require PR approval + status checks before promoting a commit (align with [Release Playbook — Production promotion](../runbooks/release_playbook.md#4-production-promotion)). No direct pushes.  
- Optional (solo): don’t require code owners/reviews; rely on checks.

See more principles in the [CI/CD Constitution](ci_cd_constitution.md).

---

## 9) FAQs
**Q: When do I open a PR?**  
As soon as you branch. Draft PRs create a social contract with your future self.

**Q: How big is too big?**  
If review takes more than ~15 minutes, split it.

**Q: How do I handle database changes?**  
Use **Expand → Migrate → Contract**; write idempotent scripts under `migrations/sql/` (e.g., `V003__add_tenant_id.sql`). Reference them in the **Migrations** section of the PR.

**Q: Do I rebase?**  
With squash-merge, either rebase or merge `main` into your branch—your final history will be a single squashed commit anyway.

**Q: What goes in the squash title/body?**  
Title: `type(scope): subject`. Body: **Because / Changed / Result** in 3–6 lines; link related Issues.

---

## 10) Pointers
- Template: [.github/pull_request_template.md](../../.github/pull_request_template.md)  
- Commits & Changelog: [docs/policy/commits_and_changelog.md](commits_and_changelog.md)  
- Minimal CI: [docs/policy/ci_minimal.md](ci_minimal.md)  
- CI/CD Constitution: [docs/policy/ci_cd_constitution.md](ci_cd_constitution.md)  
- Glossary: [docs/reference/glossary.md](../reference/glossary.md)

> Example filenames in this document are wrapped with backticks to avoid accidental links (e.g., `V003__add_tenant_id.sql`).
