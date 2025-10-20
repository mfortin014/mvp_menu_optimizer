<!--
title: Refresh AGENTS.md as canonical agent-collab playbook
labels: ["policy","docs"]
assignees: []
uid: auto-gh-agents-refresh-20251020
parent_uid:
children_uids: []
type: Policy
status: Todo
priority: P2
target:
area: policy
project: main
project_url:
doc: AGENTS.md
pr:
-->

# Policy — Refresh AGENTS.md as canonical agent-collab playbook

Context  
The current AGENTS.md predates CI/CD phases 0–1 and references files that no longer exist, causing agents (e.g., VS Code Codex) to chase dead ends. We need a clean, canonical, tool-agnostic AGENTS.md that encodes original collaboration rules and links back to existing repo policies instead of duplicating them.

Problem / Goal  
Replace AGENTS.md with a concise ruleset that instructs agents how to behave (issues → branch → draft PR), what to avoid (no secrets, no runtime/db), how to link policy (relative links to docs), and how to fail safely (ask, don’t assume)—without restating policy content that already lives elsewhere.

Scope

- Single-file rewrite of AGENTS.md at repo root.
- **Allow agents to prepare migration files** (per `migrations_and_schema.md` conventions: naming, folders, up/down scripts if applicable), but **do not execute** them or connect to any database.
- No CI changes; no tool-specific sidecars in this issue.

Acceptance Criteria (DoD)

- AGENTS.md rewritten from scratch with the following sections: Mission & Scope, Operating Mode (Draft PRs only), Handshake (find/seed Issue → branch → open Draft PR), Guardrails & Prohibitions, Encouraged Behaviors, PR Hygiene, Docs Discovery & Linking Rules, Failure Modes & Recovery, Sidecars (future).
- File contains original guidance only; it links to existing policies (relative links) instead of repeating them.
- No references to removed/obsolete files remain.
- Links validated against current repo docs.
- **If the Issue explicitly requests schema changes:** agents may **author migration files** under the proper directory with correct naming and (where required) rollback/down steps; include a brief migration plan in the PR body. **Do not run** migrations or connect to any DB.
- Draft PR created from a short-lived branch and linked to this Issue.
- Maintainer review requested. Once approved, squash-merge with clean one-liner title.

Out of Scope

- Executing migrations or connecting to any database.
- Adding tool-specific sidecar files.
- Modifying CI/CD, secrets, or environments.

Risk / Rollback  
Low risk; rollback is simply restoring the previous AGENTS.md from Git history if needed.
