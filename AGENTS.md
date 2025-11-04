# AGENTS.md — Canonical rules for code agents in this repo

**Audience:** repository-integrated coding agents (e.g., VS Code Codex/Copilot).  
**Purpose:** encode how to collaborate here.

---

## 1) Mission & scope

Work happens through **Issues → Branches → Draft PRs**, with human review at every gate.  
When you need a rule, **link the exact doc section** rather than paraphrasing it.

---

## 2) Operating mode (Draft PRs only)

- **Never** commit to `main`.
- **Always** open a **Draft PR** first, keep diffs **small and reversible**, and explain intent briefly.
- When unsure, pause and ask in the PR with your best-guess plan.

See: `branching_and_prs.md`, `ci_minimal.md`, `ci_cd_constitution.md`.

---

## 3) Start-here handshake

1. **Create a branch** from the default branch using our naming (see `docs/policy/branching_and_prs.md#3-branching`).
   - Seed-generation work still happens on a short-lived branch; keep the branch limited to the seed file (and supporting docs if needed) before opening the Draft PR.
2. **Confirm you have the right Issue context.**
   - Default: use the Issue in the prompt, or request the link if it’s missing per `docs/policy/issues_workflow.md#1-when-to-open-an-issue`.
   - Exception: when the prompt explicitly asks you to seed and no Issue exists yet, move forward with the seed so automation can mint the Issue.
3. **If instructed, seed an Issue** via our automation (see `docs/policy/ci_github_object_creation.md#2-seeds-folders--schema`).
   - Generate the seed under `.github/project-seeds/pending/`, capturing the full context you have; ask for clarifications when details are missing. Following this path takes the place of requesting an Issue link because automation will create the Issue from the seed for maintainer approval.
4. **Prepare Draft PR content** tied to the Issue or seed intent.
   - Provide a squash-ready **title** and a concise **body** that links the Issue (once it exists) and cites exact policy sections (see `docs/policy/branching_and_prs.md`, `docs/policy/ci_minimal.md`, `docs/policy/commits_and_changelog.md`, and if applicable `docs/policy/migrations_and_schema.md`).

---

## 4) Guardrails & prohibitions

- **Secrets & env:** you cannot access secrets. **Do not** create/edit env/secret files or instructions about them.  
  See: `env_and_secrets.md`.
- **Runtime & DB:** **do not** run the app or connect to any database. Prefer static analysis and compiler/lint checks.
- **Migrations (authorship allowed, execution forbidden):**
  - You **may author** migration files **only when the Issue explicitly requests schema changes** and references `migrations_and_schema.md`.
  - You **must not execute** migrations or perform any DB operations.
- **Cross-repo writes:** confined to this repo.
- **Destructive ops:** avoid bulk renames/deletions without explicit rationale and linked policy.

---

## 5) What’s encouraged

- **Tiny, tidy diffs** (split work if >~200–300 LOC across many files).
- **Inline rationale** where intent isn’t obvious.
- **Pointer-first help:** include direct relative links to exact doc headings you used.
- **Ask > assume:** ask questions when facing ambiguity.

---

## 6) PR hygiene

**Keep PR bodies short and useful:**

- One-sentence **problem** and one-sentence **outcome**.
- Links: **Issue**, **spec** (if any), and **exact policy sections** followed.
- Verification note: what you checked (e.g., lints/static checks), and whether user-visible changes need a changelog line.

**Commits:** small and topical; final merge uses a clean **squash one-liner** (follow `commits_and_changelog.md`).

See: `commits_and_changelog.md`, `release_playbook.md`, `ci_minimal.md`.

---

## 7) Commit recommendations

- Always share the Conventional Commit message you recommend for the current work in a fenced code block, following `docs/policy/commits_and_changelog.md#1-commit-anatomy` and the intent decision tree in that doc.
- Anchor the message to the staged diff only; avoid summarizing prior discussion or future intent.

---

## 8) Docs discovery & linking rules

Treat repo docs as the **library of truth**. Always **use relative links**.

Common entry points (not exhaustive):

- Overview & first run — `README.md`, `first_run.md`
- Issues & seeding — `issues_workflow.md`, `ci_github_object_creation.md`
- Branching & PRs — `branching_and_prs.md`
- CI/CD gates — `ci_minimal.md`, `ci_cd_constitution.md`
- Changelog & releases — `commits_and_changelog.md`, `release_playbook.md`
- Specs & docs discipline — `specs_workflow.md`, `docs_policy.md`
- Data & migrations — `migrations_and_schema.md`
- QA & smoke — `smoke_qa.md`
- Env & secrets — `env_and_secrets.md`

> When citing a rule, prefer **section-level links** (e.g., `migrations_and_schema.md#naming`) instead of summarizing.

---

## 9) Migration authorship protocol (when explicitly requested)

1. Read the Issue and the relevant sections in `migrations_and_schema.md`.
2. Generate files **in the correct directory** with the **prescribed naming** and include **up/down** or rollback notes if required.
3. In the PR body, include a brief **migration plan**: intent, impacted tables/columns, and a link to the exact policy section used.
4. **Do not run** the migration or connect to any DB; mark as “pending maintainer execution.”

---

## 10) Failure modes & recovery

- **Missing info?** Post a concise assumption list and a minimal plan; request confirmation.
- **CI failing?** Point to the exact job/log line, propose the smallest corrective change, and stop for review.
- **Spec vs docs mismatch?** Link both sources, describe the discrepancy, and request guidance—do not resolve solo.

---

## 11) Sidecars (future)

If files like `.cursorrules`, `CLAUDE.md`, or `.github/copilot-instructions.md` are added, they **must** defer to this `AGENTS.md` and only add tool-specific syntax/ergonomics.

---

## 12) GitHub collaboration

- When providing contents for GitHub objects to be manually updated to GitHub by humans, always provide it as markdown codeblocs. If the contents itself contains codeblocs, make sure the outter codebloc is quadruple fenced.

**Prime directive:** reduce risk, increase velocity. Keep diffs tiny, link policy, and ask when unsure.
