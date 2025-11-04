# Release Playbook — MVP
**Updated:** 2025-09-19 13:17

Applies to: Streamlit app + Supabase Postgres (multi-tenant)  
Related: [CI/CD Constitution](../policy/ci_cd_constitution.md), [Minimal CI](../policy/ci_minimal.md), [Commits & Changelog](../policy/commits_and_changelog.md), [Environments & Secrets](../policy/env_and_secrets.md), [Branching & PR Protocol](../policy/branching_and_prs.md).

Purpose: a repeatable, low‑risk path from `main` to staging and production with clear checkpoints, rollback, and documentation.

---

## 0) Preconditions
- `main` is green (all required checks passing).  
- No open critical Issues linked to the milestone.  
- Database migrations follow **Expand → Migrate → Contract** and are idempotent.  
- Feature flags for this release are documented in the PR(s).

---

## 1) Version bump
- Update `VERSION` with `mvp-X.Y.Z` scheme. Pre‑1.0: bump **Y** for features/breaking changes, **Z** for fixes.  
- Commit with: `chore(release): bump version to mvp-X.Y.Z`.

---

## 2) Tag
- Create an annotated tag on `main`: `mvp-X.Y.Z`.  
- Push the tag. This should trigger the **build-and-stage** workflow (see [Minimal CI](../policy/ci_minimal.md)).

Tag message template:
- Title: `mvp-X.Y.Z`  
- Body: paste curated sections from `CHANGELOG.md` (Added / Changed / Fixed / Removed / Security).

---

## 3) Staging deploy
Triggered automatically from tag push (or merge to `main`, depending on workflow):

- Build **immutable artifact** for the tag; label with version + SHA.  
- Deploy to **staging** (`surlefeu-preview.streamlit.app` on branch `main`) using environment-scoped secrets.  
- Add a **deploy marker** with version + SHA.  
- Run post-deploy **smoke** (Golden Path) in staging. (CI job: `deploy-staging` in `.github/workflows/ci.yml`)

Gate to proceed:
- Smoke green.  
- No new errors or regressions in metrics/logs for an agreed soak window (e.g., 10–30 minutes).

If staging fails:
- **Rollback** to last green artifact or fix forward and redeploy.  
- Update the release PR or notes with the decision and outcome.

---

## 4) Production promotion
Manual approval via GitHub **production** environment.

- Deploy the **same artifact** used in staging (CI job: `deploy-production`). Requires approval in **Environments → production**.  
- Add **deploy marker**.  
- Run **smoke** again against production secrets.  
- After the gate passes, fast-forward the `prod` branch so Streamlit Cloud (`surlefeu.streamlit.app`) serves the promoted commit.  
- Watch key metrics (error rate, success rate, latency) for the soak window.

If production smoke fails or SLOs degrade:
- **Rollback** immediately to previous tag.  
- If the fix is trivial and safer than rollback, **roll forward** with a `hotfix/…` from the latest tag; tag `mvp-X.Y.(Z+1)`.

Document the incident briefly in the release notes.

---

## 5) Post‑release tasks
- **Close milestone** and related Issues.  
- Ensure `CHANGELOG.md` and GitHub Release page match.  
- Confirm flags’ intended **defaults** in production.  
- Capture any follow‑ups as Issues (e.g., remove temporary code; schedule **Contract** phase of migrations).  
- Record a short summary in the project log (one paragraph).

---

## 6) Rollback playbook
Use when production smoke fails or a severe regression appears.

1. Identify last good tag (e.g., `mvp-X.Y.(Z-1)`).  
2. Promote its artifact to production (no rebuild).  
   - Fast-forward or reset the `prod` branch to the last good commit so Streamlit Cloud serves the rollback.  
3. Post a deploy marker `ROLLBACK mvp-X.Y.Z → mvp-X.Y.(Z-1)`.  
4. Disable related feature flags.  
5. Open an Incident Issue with: **Impact, Timeline, Suspected Cause, Fix plan**.  
6. Decide **fix forward** vs **hold**. If fix forward:
   - Branch `hotfix/short-slug` from last good tag.  
   - Make minimal change; PR → squash → tag `mvp-X.Y.(Z+1)` → stage → prod.  
7. Update `CHANGELOG.md` and Release notes.

---

## 7) Database migrations (safe path)
- **Expand**: additive DDL first; keep app reading both shapes.  
- **Migrate**: backfill using idempotent scripts under `migrations/sql/` (e.g., `V003__add_tenant_id.sql`).  
- **Contract**: remove old structures only after a full release cycle with telemetry showing safety.

If a migration breaks staging or prod:
- Revert application behavior flag‑off; **do not** drop columns under pressure.  
- Create a corrective migration script; run in staging; then redo promotion.

---

## 8) Communications
- Internal: short note in the PR or project log: version, date/time, highlights, known issues.  
- External (optional): update customer‑facing channel if relevant (feature flag on, new behavior visible).

---

## 9) Quality gates (summary)
- PR checks: style, unit, thin smoke → must pass.  
- Staging gate: post‑deploy smoke + metrics stable.  
- Production gate: manual approval + smoke + metrics stable.

---

## 10) Checklist (copy into release Issue if you prefer)
- [ ] `VERSION` updated to `mvp-X.Y.Z`  
- [ ] `CHANGELOG.md` curated for this version  
- [ ] Tag `mvp-X.Y.Z` created and pushed  
- [ ] Staging deployed; smoke passed; metrics stable  
- [ ] Production approved; same artifact promoted  
- [ ] Production smoke passed; metrics stable  
- [ ] Flags set to intended defaults  
- [ ] Milestone closed; follow‑ups filed  
- [ ] Release notes published (GitHub Release)

---

## 11) v1 enhancements (parked)
- Per‑PR preview environments for richer UAT.  
- Automated dependency audit and security scans.  
- SBOM and artifact signing.  
- Canary at infra level and progressive delivery tools.

---

**File conventions used in this doc are wrapped in backticks to avoid accidental links (e.g., `VERSION`, `V003__add_tenant_id.sql`).**
