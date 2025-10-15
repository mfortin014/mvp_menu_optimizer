<!--
title: security,chore: Migrate to Supabase publishable key (replace legacy anon)
labels: ["security","chore","CI-phase:phase-2"]
uid: sec-migrate-publishable-key
parent_uid: ci-phase1-epic
type: Chore
status: Todo
priority: P2
area: ci
project: "main"
-->

# security,chore: Migrate to Supabase publishable key

**Intent**  
Replace legacy anon key with the **publishable** key across local + CI without breaking RLS-guarded flows.

**Plan**

- Add optional `SUPABASE_PUBLISHABLE_KEY`; code resolves in order: `SUPABASE_PUBLISHABLE_KEY` → `SUPABASE_ANON_KEY`.
- Feature-flag the switch (`USE_PUBLISHABLE_KEY=true`), default **off**.
- Staging test: set `SUPABASE_PUBLISHABLE_KEY` in Bitwarden + GitHub Envs; turn flag **on**; verify app + smoke.
- If green, disable **legacy API keys** in Supabase (staging), then repeat in prod with a short maintenance window.
- Remove flag and legacy env var after rollout.

**Acceptance**

- App launches in staging with publishable key only.
- CI green with publishable key only.
- Legacy keys disabled in both envs.
