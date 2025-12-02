<!--
title: Fix — require explicit APP_ENV to prevent accidental production access
labels: ["bug", "security", "ci"]
assignees: []
uid: fix-env-require-explicit-app-env
type: Bug
status: Draft
priority: P1
area: ci
series: "Throughput"
work_type: Standalone
story_points: 2
doc: "docs/policy/env_and_secrets.md"
-->

# Fix — require explicit APP_ENV to prevent accidental production access

**Intent**  
The `get_env()` function in `utils/env.py` currently defaults to "prod" when `APP_ENV` is not found, which creates a safety risk where developers might accidentally run against production when they intended to use test/staging.

## Problem

When `APP_ENV` is not explicitly set (either via environment variable or Streamlit secrets), the application silently defaults to "prod". This means:
- A developer might think they're running against test/staging but are actually hitting production
- Missing configuration could lead to accidental data modifications in production
- The fail-safe principle is violated: we should fail loudly rather than defaulting to a dangerous state

## Solution

Modify `get_env()` to:
1. Check environment variables first (supports `bws run`, direnv, .env exports)
2. Check Streamlit secrets with graceful handling of missing `secrets.toml` (for local dev)
3. **Fail loudly** with a clear error message if `APP_ENV` is not found anywhere

This follows the fail-safe principle: when in doubt, fail rather than silently defaulting to a dangerous state.

## Plan

- [ ] Update `get_env()` in `utils/env.py` to handle `FileNotFoundError` when accessing `st.secrets` (local dev without secrets.toml)
- [ ] Replace default "prod" return with `RuntimeError` that includes clear guidance
- [ ] Verify error message appears when `APP_ENV` is not set
- [ ] Verify it works when `APP_ENV=test` is set via environment variable
- [ ] Verify it works when `APP_ENV` is in Streamlit secrets
- [ ] Run lint checks
- [ ] Run smoke tests (if applicable)

## Acceptance

- [ ] `get_env()` raises `RuntimeError` when `APP_ENV` is not set
- [ ] Error message includes guidance on how to set `APP_ENV` (e.g., `APP_ENV=test bws run --project-id="$TEST" -- streamlit run Home.py`)
- [ ] Function works correctly when `APP_ENV` is set via environment variable
- [ ] Function works correctly when `APP_ENV` is in Streamlit secrets
- [ ] Function handles missing `secrets.toml` gracefully (local dev scenario)
- [ ] All lint checks pass
- [ ] Application behavior is unchanged when `APP_ENV` is properly set

## Backout

Revert the change to `utils/env.py` to restore the default "prod" behavior (though this is not recommended due to safety concerns).

