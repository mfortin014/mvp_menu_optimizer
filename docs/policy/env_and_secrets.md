# Environments & Secrets (SimplerTree)
**Updated:** 2025-09-19 13:11

Goal: keep you shipping with **staging → production**, clean separation of data, and zero leaked secrets. Terms link to the [Glossary](../reference/glossary.md).

---

## 1) The SimplerTree
- **Staging** — auto-deploy on merge to `main`; mirrors prod closely; scrubbed data; safe for UAT.  
- **Production** — manual approval; live users; feature flags default **OFF**.

**Out-of-scope for MVP** (parked for v1): per-PR preview environments; blue/green; canary at the infra level (we emulate canary via **feature flags**). See: [CI/CD Constitution](ci_cd_constitution.md).

---

## 2) Source of truth for configuration
- **Runtime config via environment variables** (12-factor). No env-specific builds.  
- Repo only contains **templates**, never real secrets:
  - `.env.example` — sample local variables (no credentials).  
  - `.streamlit/secrets.toml.example` — sample Streamlit secrets.  
- Real secrets live in **GitHub Environments**:
  - `staging` — scoped secrets for staging.
  - `production` — scoped secrets for production.

See also: [Minimal CI (Week 1)](ci_minimal.md) and [Release Playbook](../runbooks/release_playbook.md).

---

## 3) Environment variables (MVP list)
Name → purpose (and whether secret):  
- `APP_ENV` → `staging` or `production` (not secret).  
- `APP_VERSION` → injected from `VERSION`/tag (not secret).  
- `SUPABASE_URL` → project URL (treat with care; not a secret but avoid leaking).  
- `SUPABASE_ANON_KEY` → public client key (handle carefully; not admin).  
- `SUPABASE_SERVICE_KEY` → service role key (secret; **never** ship to browser).  
- `SUPABASE_SCHEMA` → primary schema name if non-default (not secret).  
- `SENTRY_DSN` (or equivalent) → error reporting (secret).  
- `LOG_LEVEL` → `INFO`/`DEBUG` (not secret).  
- `FEATURE_FLAGS_JSON` → optional JSON for defaults (not secret).

If you add more, update this list and the templates.

---

## 4) Secrets handling in GitHub
- Define **Environments** named `staging` and `production`.  
- Add secrets with identical **keys** across envs; values differ per env.  
- Use protection rules: require approval to deploy to `production`.  
- Jobs reference them as environment-scoped secrets (never echo values).

**Rotation policy**  
- Rotate immediately if a secret is suspected exposed.  
- Routine rotation every 90–180 days for service keys.

---

## 5) Data policy
- **Staging** uses **scrubbed or synthetic** data; avoid copying raw prod.  
- Access to `production` DB is least-privilege; prefer read-only replicas for analytics.  
- Keep only **release** schema dumps in `schema/` (e.g., `supabase_schema_2025-09-16_01.sql`). Add non-release dumps to `.gitignore`.

---

## 6) Feature flags (runtime safety)
- Merge early, release later. Flags let you ship code dark and enable per **tenant cohort**.  
- Each flag defines **owner**, **default**, **planned removal date**.  
- Kill switch must exist. Document flags in the PR (see the template at `../../.github/pull_request_template.md`).

See: [Glossary → Feature Flag](../reference/glossary.md#feature-flag).

---

## 7) Observability & deploy markers
- Include `version`, `tenant_id`, `request_id`, and `correlation_id` in logs/events.  
- Add a **deploy marker** on staging and prod so you can correlate behavior with deploys.  
- Run post-deploy **smoke**; if it fails, rollback or fix forward. See: [CI/CD Constitution](ci_cd_constitution.md#rollback-and-roll-forward).

---

## 8) Access & roles (Supabase specifics)
- Client uses **Anonymous Key** with **RLS** (Row-Level Security) enforced.  
- Server-side operations use **Service Role** key from the environment (never shipped to browser).  
- Periodically audit policies to ensure no cross-tenant reads/writes.

---

## 9) Naming & branching conventions (env sense)
- Branch names do not encode environments. The **artifact** is the same for staging and prod.  
- Use tags like `mvp-0.6.0` to identify the artifact; inject `APP_VERSION` from the tag.

---

## 10) Setup checklist (MVP — do once)
- Create GitHub **Environments**: `staging`, `production`.  
- Add secrets in each: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`, `SENTRY_DSN` (optional), and any others you use.  
- Commit `.env.example` and `.streamlit/secrets.toml.example` with placeholder values.  
- Ensure CI workflow deploys to **staging** on merge to `main` and requires approval for **production**.  
- Add post-deploy **smoke** in both environments.  
- Document any **flags** added in PRs; maintain an index under `docs/reference/` (Phase 2).

---

## 11) v1 enhancements (parked)
- **Preview environments** per PR.  
- **Blue/green** at infra level.  
- Centralized **secret management** (e.g., Vault) with auto-rotation.  
- **SBOM** and signed artifacts for supply-chain integrity.

---

> Example filenames in this document are wrapped with backticks to avoid accidental links (e.g., `supabase_schema_2025-09-16_01.sql`).