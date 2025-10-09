<!--
title: Phase 1 — local secrets hardening via direnv (keep Codex on, keep secrets out of workspace)
labels: ["security","chore","CI-phase:phase-1"]
uid: ci-phase1-secrets-direnv
parent_uid: ci-phase1-epic
-->

# Phase 1 — local secrets hardening via direnv

**Intent**  
Keep Codex enabled and the repo Trusted, but ensure real secrets never reside in (or are referenced by) the workspace. Move secrets to home-scoped paths, load them via **direnv**, rotate keys, and prove that Codex cannot access paths outside the repo.

---

## Plan (sequence matters)

### A) Tighten VS Code trust _before_ touching secrets

- [ ] In “Manage Workspace Trust”, remove trust from broad parents (e.g., `/home/mathieu`, `/home/mathieu/mvp_apps`); keep only `/home/mathieu/mvp_apps/menu_optimizer` **Trusted**.
- [ ] Ensure no other workspace folders include `~` or directories where secrets will live.
- [ ] Settings check: `.vscode/settings.json` does **not** point `python.envFile` to a real dotenv (okay to point at `.env.example` or leave unset).
- [ ] Canary test: create `../CANARY_OUTSIDE_WORKSPACE.txt` (one level up), ask Codex (in this workspace) to summarize it → Expected: **blocked/unavailable**. Attach a screenshot/note here.

### B) Place real secrets _outside_ the repo (home-scoped)

- [ ] Create `~/.env.menu_optimizer` with real env vars (DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY, etc.). **Do not open this file in VS Code.**
- [ ] Create `~/.streamlit/secrets.toml` with the Streamlit secrets. **Do not open this file in VS Code.**

### C) Wire loading with **direnv** (no secrets in repo)

- [ ] Install direnv and hook your shell: https://direnv.net/docs/hook.html
- [ ] Add `.envrc` **in the repo root** with _only_ this line:
      dotenv ~/.env.menu_optimizer
- [ ] `direnv allow` (repo root). Verify `echo $DATABASE_URL` after cd into repo.
- [ ] Commit `.envrc` (no secrets), `.env.example`, and `.streamlit/secrets.toml.example`.  
       In `.env.example`, list keys only (no values).

### D) Purge secrets from the workspace (if any existed)

- [ ] Ensure `.gitignore` ignores `.env` and `.streamlit/secrets.toml`.
- [ ] If real files exist inside the repo: `git rm --cached .env .streamlit/secrets.toml` (files remain locally). Commit this cleanup.
- [ ] Search the repo history for leaks (`git log -S SUPABASE_` etc.). If found, note commit(s) and proceed to rotate.

### E) Rotate keys (only after direnv is live and workspace is clean)

- [ ] Rotate **staging** ANON and SERVICE ROLE keys in Supabase; update `~/.env.menu_optimizer` and `~/.streamlit/secrets.toml`.
- [ ] If prod ever touched the workspace, rotate prod keys as well.
- [ ] Update GitHub Environments (staging/production) secrets with the new values.

### F) Verify app & CI behavior

- [ ] New shell: `cd repo → direnv loads → ruff check . → pytest -q → streamlit run Home.py` (works with staging creds).
- [ ] Ensure CI still passes (CI uses GitHub Environment secrets; no changes required locally).

### G) Document & evidence

- [ ] Update `docs/runbooks/first_run.md` to mention direnv and home-scoped secrets paths.
- [ ] Attach to this issue: (1) Workspace Trust screenshot (only repo trusted), (2) Codex canary note, (3) confirmation of rotations and successful local boot.

---

## Acceptance (Done when)

- [ ] No real secret files exist anywhere in the repo directory; only templates remain.
- [ ] Repo is Trusted; parent directories are not (no accidental broad trust).
- [ ] Codex cannot access files outside the repo (canary passes).
- [ ] direnv loads `~/.env.menu_optimizer` automatically on `cd` into the repo.
- [ ] Keys rotated where necessary; GitHub Environment secrets updated.
- [ ] Runbook updated; local dev and CI both green.

## Dependencies

- Independent of other Phase-1 tasks; recommended to complete **before** rotating keys in #ci-phase1-non-repo so new keys never land in the workspace.

## Backout

- You can temporarily disable direnv (`direnv deny`) and export vars manually; do **not** move secrets back into the repo.
