# Minimal CI (Week 1)

**Updated:** 2025-09-18 20:38

Purpose: fast, deterministic feedback on every PR so you can merge small, safe changes without ritual. Terms link to the [Glossary](../reference/glossary.md).

---

## 1) What “Minimal” means

- **Style gate**: ruff and formatter (black/isort) in check mode to keep reviews focused on intent.
- **Unit tests**: fast logic checks.
- **Thin smoke**: app boots and the **Golden Path** succeeds (non-destructive).

That’s it for MVP. No heroics, no flaky E2E marathons.

See also: [CI/CD Constitution](ci_cd_constitution.md), [Branching & PR Protocol](branching_and_prs.md).

---

## 2) Trigger model

- **pull_request → main**: run style → unit → thin smoke; block merge if any fail.
- **push → main**: build the **artifact**, deploy to **staging**, then run the smoke again post-deploy. (See [Build Once, Promote Many](ci_cd_constitution.md#build-once-promote-many)).

---

## 3) Job breakdown (conceptual)

**Job: check** (PRs)

- Checkout repository.
- Setup Python (pin to the project baseline).
- Restore dependency cache (keyed by lockfile hash).
- Install dev dependencies (`ruff`, `pytest`, etc.).
- Run ruff (lint) and ruff-format/black/isort in **check** mode.
- Run unit tests.
- Run thin smoke (non-destructive).
- Upload artifacts (logs, junit xml) on failure for quick triage.

**Job: build-and-stage** (on merge to `main`)

- Build the immutable artifact (container recommended).
- Label artifact with version, commit SHA, and dependency digest.
- Push to your **artifact registry**.
- Deploy artifact to **staging** with environment-scoped secrets (see [Environments & Secrets](env_and_secrets.md)).
- Run post-deploy smoke; mark the deploy with a **deploy marker**.

**Job: promote-prod** (manual)

- Manual approval via GitHub **production** environment.
- Deploy the **same** artifact used in staging.
- Run smoke again; if it fails, **rollback**.

---

## 4) What to test (Week 1 scope)

- **Unit**: pure functions and adapters (db helpers, parsers, simple services).
- **Integration**: only where contracts are brittle (db layer, auth handshake). Keep it fast.
- **Smoke**: one Golden Path for the core user journey.

If a test flakes: treat it as an **outage**—quarantine or fix within 48h (see [CI/CD Constitution](ci_cd_constitution.md#required-pr-checks-gates)).

---

## 5) Caching & speed

- Cache Python dependencies by **lockfile hash**.
- Avoid network calls in tests; mock or use tiny fixtures.
- Keep the smoke minimal (one or two assertions).
- Fail fast; don’t run slower jobs after a hard failure when on PRs.

---

## 6) Secrets & environments

- Use **GitHub Environments** to store per-env secrets (e.g., `staging` and `production`).
- Populate only the keys needed (SUPABASE_URL, SUPABASE_ANON_KEY, SERVICE_ROLE, etc.).  
  Never echo secrets in logs; prefer masked outputs.
- **Service-role keys are CI-only.** They must live in GitHub _Environment_ secrets (e.g., `staging`, `production`) and are never available in local development.

See: [Environments & Secrets](env_and_secrets.md).

---

## 7) Status checks & branch protection

- Protect `main`.
- Require the **check** job to pass before merging.
- Enforce **linear history** and “Require a pull request before merging”.
- Allow only **squash-merge**.

See: [Branching & PR Protocol](branching_and_prs.md#8-github-settings-branch-protection-solo-friendly).

---

## 8) Failure playbook (CI)

- **Style fails**: run the formatter locally; commit.
- **Unit fails**: fix or xfail; if flaky, quarantine.
- **Smoke fails on PR**: investigate locally; do not merge.
- **Smoke fails after staging deploy**: rollback (if needed) or fix forward; document briefly in release notes.

For production, follow the [Release Playbook](../runbooks/release_playbook.md).

---

## 9) What’s next (v1 later)

- Security scans and dependency audit.
- Coverage reporting with a pragmatic threshold (avoid chasing 100%).
- **Preview environments** per PR for richer review.
- **SBOM** generation and artifact signing.

These can wait until after MVP.

---

> Example filenames in this document are wrapped in backticks to avoid accidental links (e.g., `V003__add_tenant_id.sql`).
