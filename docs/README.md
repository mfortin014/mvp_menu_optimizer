# Project Bible (Index)

**Updated:** 2025-09-18 19:08

This is the single entrypoint to all project documentation. Each link is marked as [MVP] or [v1].  
Repo = Library (durable truth). GitHub = Town Square (work-in-progress). OneDrive = heavy files & research.

> Tip: Need a term? Jump to the [Glossary](reference/glossary.md).

## CI/CD & Governance

- [Docs Policy & Map](policy/docs_policy.md) — what lives where; includes the commit intent decision tree. [MVP]
- [CI/CD Constitution](policy/ci_cd_constitution.md) — principles, gates, environments. [MVP]
- [Branching & PR Protocol](policy/branching_and_prs.md) — trunk-based, Draft PRs, squash. [MVP]
- [Conventional Commits & Changelog](policy/commits_and_changelog.md) — commit types, tags, CHANGELOG. [MVP]
- [Minimal CI (Week 1)](policy/ci_minimal.md) — required checks and shape of Actions. [MVP]
- [.github/PULL_REQUEST_TEMPLATE.md](../.github/pull_request_template.md) — intent-first structure. [MVP]

## Runbooks

- [Release Playbook](runbooks/release_playbook.md) — bump → verify → tag → stage → promote → aftercare. [MVP]
- First Run — (to be added in Phase 1). [MVP]
- Rollback — (to be added in Phase 2). [v1]
- [DB Security Hardening](runbooks/db_security_hardening.md)

## Environments & Secrets

- [Environments & Secrets](policy/env_and_secrets.md) — SimplerTree; Supabase staging/prod; GitHub Environments. [MVP]

## Reference

- [Glossary](reference/glossary.md) — shared language across docs and PRs. [MVP]
- Data Dictionary — add link under `docs/reference/` when ready. [MVP]
- Events & Error Model — Phase 3. [v1]

## Specs / ADRs

- Accepted specs live in `docs/specs/` (Phase 1 adds an index). [MVP]
- ADRs live in `docs/adr/` (template arrives in Phase 2). [v1]

## Work Tracking & Heavy Files (update these URLs)

- GitHub Issues: [Link](https://github.com/mfortin014/mvp_menu_optimizer/issues)
- GitHub Projects: [Link](https://github.com/users/mfortin014/projects/1/views/5)
- OneDrive root for this project: [\OneDrive - Sur Le Feu\Menu_Optimizer\docs](https://surlefeu-my.sharepoint.com/:f:/p/mathieu_fortin/EnSXY-AFa9RCh1eRI804IwUBLaHXiZ7Ko1S_iWLJJTT61w?e=Jw0nTt)

---

**How to use this index**  
• If a document exists but isn’t listed here, add it — the map is the contract.  
• When a doc spans MVP and v1, label sections inside the doc “MVP now” vs “v1 later”.  
• When giving examples of filenames, wrap them in backticks to avoid accidental links (e.g., `2025-08-19-title.md`).
