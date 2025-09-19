# CI/CD Constitution — Menu Optimizer MVP
**Version:** 1.2 • **Updated:** 2025-09-19 14:42  
**Applies to:** Streamlit app + Supabase Postgres (multi-tenant)

Terms link to the [Glossary](../reference/glossary.md).

---

## North Star
Ship **small, safe, reversible** changes on a steady cadence. Optimize for:  
- short lead time,  
- low change failure rate,  
- fast MTTR (mean time to restore), and  
- frequent deploys.

We achieve this with **trunk-based development**, **automation with taste**, and **evidence over drama**.

---

## Branching & Flow
- `main` is sacred and always releasable. (See [Branching & PR Protocol](branching_and_prs.md)).  
- Short-lived branches (`feat/*`, `fix/*`, `chore/*`), opened as **Draft PRs** immediately.  
- **Squash-merge** to `main`; delete branches after merge.  
- Tags from `main`: `mvp-X.Y.Z` (see [Conventional Commits & Changelog](commits_and_changelog.md)).

**MVP now:** trunk-only, Draft PRs, squash-merge.  
**v1 later:** optional preview environments per PR; release candidate branches if needed.

---

## Required PR Checks (gates)
1) **Style** — ruff + format (no nitpicking in review).  
2) **Unit tests** — minutes, not hours.  
3) **Thin smoke** — app boots; Golden Path works (non-destructive).

**MVP now:** 1–3 above (see [Minimal CI](ci_minimal.md)).  
**v1 later:** security scans, coverage thresholds, mutation tests.

**Rule:** **flaky tests are an outage** — quarantine or fix within 48h.

---

## Build Once, Promote Many
- Build a single **immutable artifact** per commit (container recommended).  
- Inject **environment variables** at runtime (12-factor).  
- Store provenance: commit SHA, build time, dependency digest in the artifact label.

**MVP now:** artifact + staging deploy on merge to `main`.  
**v1 later:** SBOM and signed artifacts.

---

## Environments (SimplerTree)
- **Staging** — auto-deploy on merge to `main`; mirrors prod closely.  
- **Production** — manual approval via **GitHub Environments**; feature flags default OFF.

See details in [Environments & Secrets](env_and_secrets.md).

---

## Migrations (Expand → Migrate → Contract)
- **Expand**: additive changes first (columns/tables), code reads both shapes.  
- **Migrate**: backfill jobs; keep idempotent scripts in `migrations/sql/` (e.g., `V003__add_tenant_id.sql`).  
- **Contract**: remove old structures only after a **staging burn-in** and telemetry shows safety.

Document the plan in the PR (**Migrations** section).

---

## Idempotency & Events
- Mutations accept an **idempotency key**; retries are safe.  
- Events are **at-least-once**; dedupe by `correlation_id`.  
- Include `version`, `tenant_id`, `request_id`, `correlation_id` in logs/events.

Changes to events belong under **Changed** in the [CHANGELOG](../../CHANGELOG.md).

---

## Feature Flags & Rollout
- **Merge early, release later**: hide unfinished paths behind flags.  
- Each flag has: **owner**, **default**, **planned removal date**.  
- Enable by **tenant cohort** first; observe metrics; then widen.

In PRs, fill the **Flags** section (see the template at `../../.github/pull_request_template.md`).

---

## Observability
- Add **deploy markers** with version/SHA.  
- Log standard IDs (version/tenant/request/correlation).  
- Keep an at-a-glance dashboard for: error rate, latency, success rate of the Golden Path.

Post-deploy **smoke** runs automatically; failures block promotion.

---

## Rollback and Roll-forward
- Prefer **rollback** to last healthy artifact on smoke failure or SLO breach.  
- If the fix is trivial and safer than rollback, **roll-forward** quickly with a hotfix.

Document the decision briefly in the release notes.

---

## Documentation & Roles
- Every PR body uses **Because / Changed / Result / Done when / Out of scope / Flags / Migrations / Observability / Changelog**.  
- Decisions that set precedent become **ADRs** (`docs/adr/`).  
- Owners:  
  - **CI/CD Constitution** — owner: Mathieu
  - **Release Playbook** — owner: Mathieu
  - **Environments & Secrets** — owner: Mathieu

**Review cadence:** quick scan monthly; deeper audit each release.

---

## GitHub Actions (shape, not YAML)
- **PR workflow**: checkout → setup Python → cache deps → style → unit → thin smoke → status.  
- **Main merge workflow**: build artifact → push to registry → deploy to **staging** → run smoke.  
- **Promotion**: manual approval in **production** environment → deploy same artifact → smoke.

Secrets per environment are stored in **GitHub Environments** (see [Environments & Secrets](env_and_secrets.md)).

---

## Risk policy
- Small PRs, reversible steps, and strong observability beat heroics.  
- Breaking changes must use the `!` marker **and** a `BREAKING CHANGE:` footer, with migration steps and a rollback path (see [Glossary → Breaking Change](../reference/glossary.md#breaking-change)).

---

Sections labeled “MVP now” are in-scope immediately; “v1 later” items are parked until the React/Forge transition.

**Examples of filenames are wrapped in backticks to avoid accidental links (e.g., `V003__add_tenant_id.sql`).**
