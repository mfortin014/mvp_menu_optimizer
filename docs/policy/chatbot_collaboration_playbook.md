# Collaboration Methods Playbook — Safe · Fast · Low-Friction

Updated: 2025-10-04

This playbook standardizes **how we, human and chatbot, exchange changes** during development so we protect proven code, move quickly, and keep things easy for the human applying changes.

**Priorities (in order):**

1. **Protect existing code** (no accidental rewrites, no lost comments)
2. **Speed on assistant side** (fast to generate repeatedly)
3. **Ease on human side** (minimal manual steps)

---

## Methods Overview (use the right tool for the job)

| Method                                                         | When to Use                                                          | Pros                                                            | Cons                                                 |
| -------------------------------------------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------- |
| **Unified patch (.patch)** ← **Default**                       | Any change to existing files; structural edits across multiple files | Context-aware, merge-friendly (`--3way`), auditable, reversible | Requires running a couple git commands               |
| **Anchored replace** (scripted in-place edits between markers) | Tiny surgical edits inside large files                               | Very fast to generate/apply; no hunting                         | Requires unique anchors; not ideal for big refactors |
| **Downloadable single file**                                   | **New** files (scripts, docs, assets)                                | Easiest to drop in                                              | Whole-file overwrite if used for edits               |
| **Downloadable zip**                                           | Bulk **scaffolding** (many new stubs/docs)                           | One-shot delivery for many files                                | Harder to review; not for modifying live logic       |
| **Whole-file replacement** (copy/paste)                        | Only for brand-new or trivial files                                  | Simple to apply                                                 | High risk of clobbering unrelated code/comments      |
| **Partial snippet in chat**                                    | Micro-tweak with clear boundaries                                    | Fast to send                                                    | Error-prone if you have to “hunt” sections           |

---

## Decision Tree

1. **Is this editing existing code?** → Use a **patch**.
2. **Is it a tiny, well-bounded change inside a big file?** → Use an **anchored replace**.
3. **Is it adding brand-new files only?** → Provide **downloadable files** (or a small zip if many).
4. **Avoid** whole-file replacements and ad-hoc snippets for nontrivial edits.

---

## Standard Operating Procedure — Patches (Default)

**Naming & storage**

- Store patches under `patch/` and ignore them in git.
- Naming: `YYYYMMDD-<short-scope>-<seed-uid>.patch` (e.g., `2025-10-04-goc-E1-auto-gh-E1.patch`).

**.gitignore**

```gitignore
# Patches are ephemeral
patch/*.patch
```

**Apply a patch**

```bash
# From repo root, inside your shell (WSL/Linux/macOS)
git apply --3way --check patch/<file.patch>    # dry-run
git apply --3way patch/<file.patch>            # apply
git status
git diff
git add -A
git commit -m "<scope>: <summary> [<seed-uid>]"
```

**Revert a patch**

```bash
git apply -R patch/<file.patch>
```

**If conflicts**

- Git writes `.rej` files beside the conflicted sources. Open, resolve, `git add`, and commit.
- If a patch won’t apply cleanly, ensure you’re on the **intended base branch/commit**.

**Optional helper script**

```bash
# scripts/patch/apply.sh
set -euxo pipefail
PATCH="${1:?usage: scripts/patch/apply.sh patch/<file.patch>}"
git apply --3way --check "$PATCH"
git apply --3way "$PATCH"
git status
```

**Recommended commit message template**

```
<scope>: <summary> [<seed-uid>]

- Why: <one-liner>
- Ref: <issue # or seed uid>
```

---

## Standard Operating Procedure — Anchored Replaces (Surgical Edits)

**Anchors (unique, durable):**

```ts
// GOC-BEGIN: project routing
...existing block...
// GOC-END: project routing
```

**Apply (WSL/Linux/macOS)**

```bash
# Replace the content between anchors with NEW_CONTENT (use single quotes)
perl -0777 -pe 'BEGIN{undef $/}
s|// GOC-BEGIN: project routing.*?// GOC-END: project routing|// GOC-BEGIN: project routing\nNEW_CONTENT\n// GOC-END: project routing|s' \
-i scripts/goc/routing.ts
```

**Guidelines**

- One block per concern; clear names (`GOC-BEGIN: <topic>`).
- Never overlap anchor regions.
- Prefer patches if the change is larger than ~30 lines or touches multiple areas.

---

## SOP — New Files & Zips

**Single files**

- Provide as downloads; human drops them into the specified path.
- Include the **exact target path** at the top of the file or in instructions.

**Zips (scaffolding)**

- Only for bulk **new** files (stubs/docs).
- Include a top-level `MANIFEST.md` listing file paths and purposes.
- Human reviews the manifest before unzipping to repo root.

---

## PR Hygiene & Traceability

- **One patch per issue** (e.g., `auto-gh-E1.patch`, `auto-gh-E2.patch`).
- Reference the **seed UID** in commit messages and PR descriptions.
- Use this **PR template**:

```md
# <PR title>: <scope> — <short description>

Refs: <issue # / seed uid>

## Scope

<what this PR changes and _does not_ change>

## Task → Evidence

- [ ] T1: <task> → <path/log/screenshot>
- [ ] T2: <task> → <path/log/screenshot>

## Acceptance

- [ ] <acceptance criterion> (proof: <link or path>)

## Risk & Rollback

- Risk: <low/med/high>; Rollback: `git revert <sha>` or revert patch
```

---

## WSL & Cross-Platform Notes

- Run git commands **inside** WSL if your repo lives there.
- Line endings: repo should enforce `* text=auto` (or `.editorconfig`) so patches apply cleanly.
- Binary files don’t belong in patches; deliver them as **downloadable files** or via git LFS if large.

---

## Quick Reference — What Goes Where

- **`.github/workflows/`** → Orchestration only (triggers, order, perms, chaining).
- **`.github/actions/`** → Reusable, single-capability bricks (inputs/outputs; thin wrappers).
- **`scripts/goc/`** → Domain logic (seed parsing, routing, fields, hierarchy, library). Pure, testable.

---

## Default Collaboration Contract

1. I deliver **patches** for edits, **downloads** for new files, **anchored replaces** for micro-edits.
2. You apply patches from `patch/` with `git apply --3way` and commit using the provided message.
3. Everything references a **seed UID** for traceability.
4. Patches are **ephemeral**; delete them after merge.

This keeps code safe, moves fast, and stays easy for the human who has to ship it.
