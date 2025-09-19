# Docs Policy & Map
**Updated:** 2025-09-18 19:19

This page defines *what goes where*, how docs evolve, and how to keep knowledge tidy without slowing down delivery.  
Need a definition? See the [Glossary](../reference/glossary.md).

---

## 1) The Three Homes
We separate knowledge by *how durable it needs to be*.

**Library (Repo: `docs/…`)** — durable truths that travel with the code.  
**Town Square (GitHub)** — living plans, debates, status (Issues/Projects/PRs/Discussions).  
**Archive (OneDrive)** — heavy or long-form artifacts (docx, decks, screenshots, customer notes).

Why: the repo’s history shouldn’t churn every time a checklist item flips from unchecked to checked.

---

## 2) What lives where (authoritative)
**Repo (`docs/`)**
- **Policy** (rules we run by): `docs/policy/`
  - CI/CD Constitution → `docs/policy/ci_cd_constitution.md`
  - Branching & PR Protocol → `docs/policy/branching_and_prs.md`
  - Conventional Commits & Changelog → `docs/policy/commits_and_changelog.md`
  - Minimal CI (Week 1) → `docs/policy/ci_minimal.md`
  - Environments & Secrets → `docs/policy/env_and_secrets.md`
  - This page → `docs/policy/docs_policy.md`
- **Runbooks** (how-tos used under stress): `docs/runbooks/`
  - Release Playbook → `docs/runbooks/release_playbook.md`
  - First-Run (Phase 1) and Rollback (Phase 2) will live here too.
- **Reference** (contracts the code depends on): `docs/reference/`
  - Glossary → `docs/reference/glossary.md`
  - Data Dictionary (add later)
  - Events & Error Model (Phase 3)
- **Specs** (accepted / contractual): `docs/specs/`
  - Index arrives in Phase 1.
- **ADRs** (Architecture Decision Records): `docs/adr/`
  - Template arrives in Phase 2.
- **Archive (lightweight)**: `docs/archive/`
  - Index files that *link out* to OneDrive for large packs.

**GitHub**
- **Issues** — work items, checklists, follow-ups.  
- **Projects** — planning/priority boards.  
- **Pull Requests** — proposals and reviews (start as Draft).  
- **Discussions** — brainstorms and Q&A (optional).

**OneDrive**
- Meeting notes, customer research, Chef feedback, large screenshots, videos, decks.  
- Organize by date and topic; keep a link index from `docs/archive/INDEX.md`.

---

## 3) File/Folder conventions
- Kebab-case names; **no spaces**. Example: 'data-dictionary.md'.  
- Use a date prefix when chronology matters. Example: '2025-08-19-tenant-interview-notes.md'.  
- Recommended layout (see the Project Bible at [docs/README.md](../README.md) for the full map).

**Docs maturity badges (top of each doc):** `[Draft]`, `[Accepted]`, `[Superseded by 'ADR-0005-…']`.

---

## 4) Writing rules (style that scales)
- Write for *future you*: lead with *why*, then *what*, keep *how* crisp.  
- Use short, skimmable sections; prefer lists over walls of text.  
- When showing filenames, **quote them** so they don’t auto-link (e.g., '2025-08-19-title.md').  
- Link terms to the [Glossary](../reference/glossary.md) the first time they appear (e.g., [CI](../reference/glossary.md#ci-continuous-integration), [ADR](../reference/glossary.md#adr-architecture-decision-record), [SemVer](../reference/glossary.md#semver-semantic-versioning)).

---

## 5) Change process (lightweight governance)
- **Small edits** → normal PR. Use the intent-first template.  
- **Major rewrites** → start a Draft PR labeled `docs:` with a 3–5 bullet summary (why, scope, impact).  
- **Policy changes** (anything under `docs/policy/`) → require reviewer acknowledgement before merge.  
- **Superseding** → keep the old doc, add a banner at top: “Superseded by 'ADR-####-…' or 'rfc-####-…'” and link the replacement.

**Commit intent decision tree (pointer)** — canonical lives in [Conventional Commits & Changelog](commits_and_changelog.md). Quick-skim version:

1) Runtime behavior visible to users changed?  
   • Yes → new behavior → **feat**. Bug fix → **fix**.  
   • No  → continue.

2) Performance improved with no behavior change? → **perf**.  
3) Internal code-only change (no behavior change)? → **refactor**.  
4) Documentation-only? → **docs**. Tests-only? → **test**.  
5) Build packaging vs CI workflows? → **build** / **ci**.  
6) Dependencies/config/repo housekeeping? → **chore**.  
7) Formatting-only (no logic)? → **style**.  
8) Reverting a prior commit? → **revert**.

Breaking changes: use `!` in the type (e.g., `feat!:`) **and** add a `BREAKING CHANGE:` footer.
See: [Commits & Changelog](commits_and_changelog.md).

---

## 6) Linking rules (so links don’t rot)
- Prefer **relative links** inside the repo (e.g., `../policy/ci_cd_constitution.md`).  
- For GitHub Issues/PRs, paste the canonical URL; for OneDrive, paste the shared link and add a short label.  
- Do not link to **mutable** Google Docs as truth—export or summarize key decisions into the repo (or create an ADR).

---

## 7) Trackers and specs (Library ↔ Town Square handshake)
- Trackers and checklists **live in GitHub Issues/Projects** (not the repo).  
- Specs are drafted in Discussions or OneDrive; once **accepted**, create an RFC/Spec in `docs/specs/` and link the originating Discussion/Issue.  
- Each Spec has: *Intent*, *Decision*, *Constraints*, *Impact*, *Open Questions*, *Owner*, *Reviewers*.  
- When a Spec changes runtime behavior, ensure the PR uses the intent-first template and update the [CHANGELOG](../../CHANGELOG.md).

---

## 8) Security & privacy for docs
- Never commit secrets or keys (see [Environments & Secrets](env_and_secrets.md)).  
- Do not copy raw customer data into the repo. For examples, anonymize and store any real samples in OneDrive.  
- Avoid personal data in Issues/PRs; put sensitive details in OneDrive and link with a redacted summary.

---

## 9) Ownership & lifecycle
- Every **Policy** page lists an **Owner** at top; the owner tends the garden and drives updates.  
- **Review cadence:** quick scan monthly; deeper review each release.  
- **Archival:** when a document stops being useful, move it under `docs/archive/` and link its replacement.

---

## 10) Indexes you can trust
- The Project Bible at [docs/README.md](../README.md) is the canonical index.  
- Add new docs there as they appear; if it’s not on the map, it doesn’t exist.

---

### Appendix A — Directory quick map
- `docs/policy/` — constitutions, protocols, governance (e.g., 'ci_cd_constitution.md').  
- `docs/runbooks/` — pressure-tested how-tos (e.g., 'release_playbook.md').  
- `docs/reference/` — canonical facts (e.g., 'glossary.md', later data dictionary).  
- `docs/specs/` — accepted specs and RFCs (index added in Phase 1).  
- `docs/adr/` — small, dated decisions (template ships in Phase 2).  
- `docs/archive/` — small stubs that link out to large OneDrive packs.

When in doubt, ask: **Will future code or decisions break if this knowledge goes missing?**  
If yes → it belongs in the **Library**. If no → Town Square or Archive.
