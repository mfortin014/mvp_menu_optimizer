# Specs Workflow & Acceptance (MVP)
**Updated:** 2025-09-19 18:25

Purpose: a light-but-real path for specifications to move from idea to **Accepted (MVP)** without bloating your day. Terms link to the [Glossary](../reference/glossary.md).

Related: [Docs Policy & Map](docs_policy.md), [Branching & PR Protocol](branching_and_prs.md), [CI/CD Constitution](ci_cd_constitution.md), [Commits & Changelog](commits_and_changelog.md), [Environments & Secrets](env_and_secrets.md), [GitHub Projects setup](../runbooks/github_projects_setup.md).

---

## 1) Where specs live (and where they don’t)
- **Main branch is canonical**: `docs/specs/` on **main** contains **only Approved (Accepted) specs**.
- **Drafts live only in PR branches**: create/edit the spec in a `spec/<short-slug>` branch under the same path (`docs/specs/…`) so the folder structure stays consistent, but it doesn’t land in main until approved.
- **Town Square**: GitHub **Issues/Projects** track status and discussion; link PRs there.
- **Archive/heavy packs**: OneDrive (research dumps, giant screenshots).

*Optional later*: if you prefer drafts visible in-repo, use `docs/proposals/` for drafts and move to `docs/specs/` on acceptance. For MVP we keep main clean.

---

## 2) Status model (Project → Spec lifecycle)
Use the **Status** field from the Project. Suggested flow:

- **Draft** — spec exists but needs acceptance bullets/problem framing.  
- **In review** — Draft PR and review comments flowing.  
- **Accepted** — approved for MVP scope; ready to break into feature work.  
- **Parked** — intentionally paused; add a “revisit by” note.  
- **Superseded** *(optional)* — replaced by a newer spec; link both ways.

Only **Accepted** specs represent current MVP scope.

**Project note**: add **Superseded** as a Status (neutral color) if you want that explicit state; otherwise leave items Parked and note “superseded by …” in the body.

---

## 3) Authoring a spec (minimum viable content)
Create a branch and a file (in that branch) named like `NN_Module_MVP_Spec.md` or `YYYY-MM-DD-short-slug.md` under `docs/specs/`. Include:

- **Problem** — the user/tenant pain and why it matters now.  
- **Goals / Non-goals** — bullets.  
- **Users & tenants impacted** — who touches this.  
- **Happy path scenarios** — a couple of realistic flows.  
- **Out of scope** — bullets to prevent scope creep.  
- **Risks & assumptions** — what could bite us; what we’re betting on.  
- **Migrations** — database shape changes (follow **Expand → Migrate → Contract**).  
- **Feature flags** — owner, default, kill switch, removal date.  
- **Observability** — events/metrics to watch after release; deploy marker name.  
- **Acceptance bullets** — the merge-ready checklist we will validate in PR.  
- **Rollout** — staging → prod promotion plan (gates, soak window).  
- **Dependencies** — upstream/downstream pieces.  
- **Open questions** — things we deliberately leave to discovery.

Keep prose tight. Specs are decision amplifiers, not novels.

---

## 4) Intake & review (lightweight, MVP)
1) **Branch**: create `spec/<short-slug>` from `main`.  
2) **Spec file**: add/edit under `docs/specs/` in that branch. Commit with `docs(specs): draft <short-title>`.  
3) **Draft PR**: open from `spec/<short-slug>`; title `spec: <short-title>`.  
4) **Spec Review Issue**: use `.github/ISSUE_TEMPLATE/spec_review.md` and fill **Because**, **Doc link**, **Acceptance bullets**, **Flags**, **Migrations**, **Observability**.  
5) **Project fields**: add the Issue to the Project → `Type = Spec`, `Status = Draft`, fill **Doc Link** (use the PR URL or the branch file URL), then when ready set `Status = In review` and fill **PR Link**.  
6) Iterate in the PR; aim for clarity, safety, and testability—not perfection.

---

## 5) Acceptance criteria (when to flip to Accepted)
A spec becomes **Accepted** when:
- Acceptance bullets are precise and testable.  
- Risk is understood and bounded (flags/rollback exist where needed).  
- Migrations are safe (idempotent scripts, burn-in plan).  
- Observability plan exists (what smoke/metrics we’ll check).  
- Out of scope is explicit to control creep.

On approval:
- **Squash-merge** the `spec/<short-slug>` PR into **main** (now the file exists in `docs/specs/` on main).  
- Add a small header line at the top: `Status: Accepted (MVP) — YYYY-MM-DD`.  
- Update the Project item to **Accepted**.

---

## 6) After acceptance → delivery
- Break the spec into **Issues** (Feature/Bug/Chore) and link them back to the spec.  
- Reference the spec in PRs implementing it.  
- Use the [Release Playbook](../runbooks/release_playbook.md) for promotion.  
- If the spec drives DB work, follow **Expand → Migrate → Contract** from the [CI/CD Constitution](ci_cd_constitution.md).

---

## 7) Change control
- **Minor clarifications**: simple PR edits to the spec on main.  
- **Material change** (scope/behavior): new PR from a branch (e.g., `spec/<slug>-v2`) and tag with `feat!` or include a `BREAKING CHANGE:` footer if contracts move.  
- If an Accepted spec is later replaced, mark it **Superseded** with a link to the replacement and optionally move to `docs/archive/`.

---

## 8) Quick checklist (copy/paste)
- [ ] Branch `spec/<short-slug>` from main  
- [ ] Spec file created/updated under `docs/specs/` (in branch)  
- [ ] Draft PR opened; Spec Review Issue created  
- [ ] Project fields set: Type/Status/Links  
- [ ] Acceptance bullets clear and testable  
- [ ] Flags: owner, default, removal date, kill switch  
- [ ] Migrations: **Expand → Migrate → Contract** plan  
- [ ] Observability: smoke + metrics named  
- [ ] On approval: squash-merge; mark file `Status: Accepted (MVP)`; Project → Accepted

---

## 9) Commit & PR hygiene for specs
- Use `docs(specs): …` for pure spec edits.  
- The PR body uses the template sections (**Because / Changed / Result / Done when / Out of scope / Flags / Migrations / Observability / Changelog**).  
- For code work spawned by the spec, follow the [commit decision tree](commits_and_changelog.md#commit-intent-decision-tree).

---

> Example filenames in this policy are wrapped with backticks to avoid accidental links (e.g., `docs/specs/04_Intake_MVP_Specs.md`).