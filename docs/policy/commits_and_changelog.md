# Conventional Commits & Changelog Rules
**Updated:** 2025-09-18 19:42

Purpose: keep history **explanatory**, releases **human-readable**, and changes **classifiable**. Terms link to the [Glossary](../reference/glossary.md).

> Canonical note: this page is the **source of truth** for commit intent. It refines and supersedes the quick tree summarized in [Docs Policy & Map](docs_policy.md).

---

## 1) Commit anatomy
Format: `type(scope): subject`  

- **type** — intent (see decision tree below).  
- **scope** — optional focus area (e.g., `intake`, `identity`, `measure`, `chronicle`, `lexicon`, `ui`, `db`, `ci`, `docs`, `release`, `scripts`).  
- **subject** — imperative mood, no ending period, ≤ 72 chars.

Body (optional but encouraged): 3–6 lines answering **Because / Changed / Result**.  
Footers (optional): `Closes #123`, `Refs #456`, `BREAKING CHANGE: ...`, `Co-authored-by: ...`

> Squash merges: title should be a Conventional Commit; copy the **Because / Changed / Result** summary into the body. See [Branching & PR Protocol](branching_and_prs.md).

---

## 2) Commit intent decision tree (refined)
Use this tree to pick a **single** intent. If you did two distinct things, make two commits.

1) **Did runtime behavior visible to users change?**  
   - **Yes → Is it new behavior?**  
     - **Yes → `feat`** — e.g., `feat(intake): bulk import of recipes`  
     - **No  → `fix`**  — e.g., `fix(lexicon): prevent duplicate UOMs`
   - **No → Continue:**

2) **Did performance improve without changing behavior?**  
   - **Yes → `perf`** — e.g., `perf(db): add index on tenant_id`  
   - **No → Continue:**

3) **Is this an internal code change with no behavior change?**  
   - **Yes → `refactor`** — e.g., `refactor(chronicle): extract event writer`  
   - **No → Continue:**

4) **Is this documentation-only?**  
   - **Yes → `docs`** — e.g., `docs(ci): add smoke checklist`  
   - **No → Continue:**

5) **Is this test-only?**  
   - **Yes → `test`** — e.g., `test(utils): add idempotency tests`  
   - **No → Continue:**

6) **Is this build/package config or CI workflow?**  
   - **Yes → `build`** (packaging), or **`ci`** (workflows)  
     - e.g., `ci: add ruff and smoke job`  
     - e.g., `build: pin streamlit to 1.39`  
   - **No → Continue:**

7) **Is this dependency, config, or repo housekeeping?**  
   - **Yes → `chore`** — e.g., `chore: bump ruff to 0.6.2`  
   - **No → Continue:**

8) **Is this formatting-only or lints-only change (no logic)?**  
   - **Yes → `style`** — e.g., `style: ruff --fix across utils`  
   - **No → Continue:**

9) **Are you reverting a prior commit?**  
   - **Yes → `revert`** — include the SHA and reason

> Breaking changes: use the `!` shorthand in the type (e.g., `feat!:`) **and** add a `BREAKING CHANGE:` footer. Pre-1.0, treat breaking changes as **minor** bumps (Y). See [Glossary → SemVer](../reference/glossary.md#semver-semantic-versioning).

---

## 3) Good subject lines
- Do: “normalize”, “add”, “remove”, “migrate”, “guard”, “emit”.  
- Avoid: “address review comments”, “wip”, “misc fixes”.  
- Keep it human; assume a future you scanning 6 months from now.

**Examples**  
- `feat(identity): support Google OAuth login`  
- `fix(intake): clamp negative quantities`  
- `refactor(db): isolate RLS helpers`  
- `perf(ingredients): cache costing for 10x speedup`  
- `ci: run thin smoke on PRs`  
- `docs(policy): clarify decision tree`

---

## 4) Scopes (house style)
Pick a short noun; avoid nesting. Common scopes: `intake`, `identity`, `measure`, `chronicle`, `lexicon`, `ui`, `db`, `ci`, `docs`, `release`, `scripts`.  
If you must touch multiple areas, keep the scope generic (`ui`, `db`) and explain details in the body.

---

## 5) Changelog rules (human first)
We follow **Keep a Changelog** so humans can skim releases.

**Sections we use**
- **Added** — new features (primarily `feat`)  
- **Changed** — behavior changes, migrations, large refactors with user impact  
- **Fixed** — bug fixes (`fix`)  
- **Removed** — deprecations or feature removals  
- **Security** — security-impacting changes

**Curation beats automation**: the PR author proposes a one-liner under **Changelog** in the PR template; the release editor polishes it.

**Mapping (guidance, not law)**
- `feat` → **Added**  
- `fix` → **Fixed**  
- `perf`/`refactor` with user impact → **Changed** (otherwise omit)  
- `docs`, `test`, `style`, `chore`, `ci`, `build` → usually omitted unless noteworthy (then **Changed**)

> Scripts in use: `gen_changelog.py` and `release_notes.sh`. See the [Release Playbook](../runbooks/release_playbook.md) for when to run them.

---

## 6) Versions & tags
- Single source of truth: the `VERSION` file (displayed in-app).  
- Tags from `main`: `mvp-X.Y.Z`. Pre-1.0: bump **Y** for features (and breaking changes), **Z** for fixes.  
- Releases are built once and promoted; see [CI/CD Constitution](ci_cd_constitution.md).

---

## 7) FAQ
**Q: I touched docs and code in the same commit—what type?**  
Prefer two commits. If you must squash: choose the **dominant** intent and mention the secondary work in the body.

**Q: I renamed files and changed behavior—`style` or `feat`?**  
Behavior wins: use `feat` or `fix`. Mention the rename in the body.

**Q: Do I need a scope?**  
No, but it helps searchability and changelog clarity.

**Q: Are long bodies okay?**  
Yes if they explain decisions (link Issues/ADRs). Keep the subject tight.

---

## 8) Quick reference
- Format: `type(scope): subject`  
- One intent per commit; split if needed.  
- Use backticks for example filenames in docs (e.g., `V003__add_tenant_id.sql`).  
- Draft PR early; copy **Because / Changed / Result** into the squash body.  
- Update the PR’s **Changelog** line; the release editor curates final notes.

See also: [Branching & PR Protocol](branching_and_prs.md), [Minimal CI (Week 1)](ci_minimal.md), [CI/CD Constitution](ci_cd_constitution.md), and the [Glossary](../reference/glossary.md).
