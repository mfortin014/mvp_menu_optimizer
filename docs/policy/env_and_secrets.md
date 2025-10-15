# Environments & Secrets (SimplerTree)

**Updated:** 2025-10-14

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
- Real secrets live in:
  - **GitHub Environments** (`staging`, `production`) for CI/CD.
  - **Local development** via **Bitwarden Secrets Manager (bws CLI) + direnv**: inject **staging-scope** env vars into the shell at runtime (no plaintext files on disk).

See also: [Minimal CI (Week 1)](ci_minimal.md) and [Release Playbook](../runbooks/release_playbook.md).

---

## 3) Environment variables (MVP list)

Name → purpose (and whether secret):

- `APP_ENV` → `staging` or `production` (not secret). \*not implemented yet
- `APP_VERSION` → injected from `VERSION`/tag (not secret). \*not implemented yet
- `CHEF_PASSWORD` → temporary page guard for Streamlit (secret; local/staging only;
- `DB_HOST` → used to create `DATABASE_URL` (not secret)
- `DB_NAME` → used to create `DATABASE_URL` (not secret)
- `DB_PASSWORD` → non-encoded database password, is encoded and then used to create `DATABASE_URL` (secret)
- `DB_PORT` → used to create `DATABASE_URL` (not secret)
- `FEATURE_FLAGS_JSON` → optional JSON for defaults (not secret). \*not implemented yet
- `LOG_LEVEL` → `INFO`/`DEBUG` (not secret). \*not implemented yet
- `SENTRY_DSN` → error reporting (secret). \*not implemented yet
- `SUPABASE_ANON_KEY` → public client key (handle carefully; not admin).
- `SUPABASE_PROJECT_ID` → non-secret project ref used to derive URL & DB user;
  will be replaced).
- `SUPABASE_SCHEMA` → primary schema name if non-default (not secret). \*not implemented yet
- `SUPABASE_SERVICE_KEY` → service role key (secret; **never** ship to browser; **CI-only**)

The following are no longer stored as variables/secrets and are derived at runtime:

- `DB_USER` → created using `DB_NAME` and `SUPABASE_PROJECT_ID` and is used to create `DATABASE_URL`
- `SUPABASE_URL` → project URL (treat with care; not a secret but avoid leaking).
- `DATABASE_URL` → SQLAlchemy connection string (secret).

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

## 5) Local development

- Use **Bitwarden Secrets Manager** with a project like `menu-optimizer-staging`.
- Install `bws` and `direnv`; commit an `.envrc` that **exports** env vars from the BWS project **only when the token is present**.
- Developer workflow (shell-only; secrets never touch disk):
  ```bash
  export BWS_ACCESS_TOKEN='<machine-token>'   # or use helper: bws_on
  direnv reload                                # injects DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY, CHEF_PASSWORD, …
  # run app/tests
  unset BWS_ACCESS_TOKEN && direnv reload      # un-injects on exit
  ```
- The app reads env first via `utils/secrets.py` and falls back to `st.secrets` only in CI.
- **Never** commit `.env` or `.streamlit/secrets.toml`; keep only the `*.example` templates.

---

## 6) Data policy

- **Staging** uses **scrubbed or synthetic** data; avoid copying raw prod.
- Access to `production` DB is least-privilege; prefer read-only replicas for analytics.
- Keep only **release** schema dumps in `schema/` (e.g., `supabase_schema_2025-09-16_01.sql`). Add non-release dumps to `.gitignore`.

---

## 7) Feature flags (runtime safety)

- Merge early, release later. Flags let you ship code dark and enable per **tenant cohort**.
- Each flag defines **owner**, **default**, **planned removal date**.
- Kill switch must exist. Document flags in the PR (see the template at `../../.github/pull_request_template.md`).

See: [Glossary → Feature Flag](../reference/glossary.md#feature-flag).

---

## 8) Observability & deploy markers

- Include `version`, `tenant_id`, `request_id`, and `correlation_id` in logs/events.
- Add a **deploy marker** on staging and prod so you can correlate behavior with deploys.
- Run post-deploy **smoke**; if it fails, rollback or fix forward. See: [CI/CD Constitution](ci_cd_constitution.md#rollback-and-roll-forward).

---

## 9) Access & roles (Supabase specifics)

- Client uses **Anonymous Key** with **RLS** (Row-Level Security) enforced.
- Server-side operations use **Service Role** key from the environment (never shipped to browser).
- Periodically audit policies to ensure no cross-tenant reads/writes.

---

## 10) Naming & branching conventions (env sense)

- Branch names do not encode environments. The **artifact** is the same for staging and prod.
- Use tags like `mvp-0.6.0` to identify the artifact; inject `APP_VERSION` from the tag.

---

## 11) Setup checklist (MVP — do once)

- Create GitHub **Environments**: `staging`, `production`.
- Add secrets in each: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`, `SENTRY_DSN` (optional), and any others you use.
- Commit `.env.example` and `.streamlit/secrets.toml.example` with placeholder values.
- **Local dev**: install `bws` + `direnv`, add `.envrc` (no secrets) that injects from the BWS project; document `bws_on` / `bws_off` helpers in the runbook.
- Ensure CI workflow deploys to **staging** on merge to `main` and requires approval for **production**.
- Add post-deploy **smoke** in both environments.
- Document any **flags** added in PRs; maintain an index under `docs/reference/` (Phase 2).

---

## 12) v1 enhancements (parked)

- **Preview environments** per PR.
- **Blue/green** at infra level.
- Centralized **secret management** (e.g., Vault) with auto-rotation.
- **SBOM** and signed artifacts for supply-chain integrity.

---

> Example filenames in this document are wrapped with backticks to avoid accidental links (e.g., `supabase_schema_2025-09-16_01.sql`).
