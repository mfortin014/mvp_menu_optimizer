# 🤖 AGENTS.md – Agent Implementation Protocol

## 📌 Purpose

This file defines how AI agents (e.g., Codex, Copilot, ChatGPT) or human collaborators should contribute to this codebase. It ensures a consistent, migration-aware, and documented approach to development that aligns with the broader OpsForge ecosystem.

This file is always in effect, regardless of the specific feature or module being developed.

---

## 🧠 Agent Responsibilities

### ✅ Always

* Check for relevant `*.Specs.md` or `*.Changelog.md` files before starting work.
* Follow all instructions defined in:

  * `AGENTS.md` (this file)
  * `dump_schema.sh` and connection string setup (via `.env` or manual export)
  * Schema files in `/schema/`
* Use semantic, atomic Git commits with meaningful messages.
* Annotate AI-assisted commits with `[aigen]` at the end.
* Update the following files when your implementation touches them:

  * `Menu_Optimizer_Specs.md`
  * `Menu_Optimizer_Changelog.md`
  * `Menu_Optimizer_DataDictionary.md`
* Ensure features are **fully functional** unless the spec says otherwise. If a new table or view is required, define it in SQL and include it in the feature spec. Do not apply changes directly to the live database.

### ❌ Never

* Assume stub-only implementation unless explicitly scoped in the feature spec
* Modify unrelated files or refactor without documented reason
* Leave undocumented assumptions in code or logic
* Overwrite or rename reference data without updating source `.md` docs

---

## 🔁 Workflow Summary

1. **Branch** off from `main`:

   ```bash
   git checkout -b feature/<feature-name>
   ```

2. **Implement** according to the spec. If a spec doesn’t exist, pause and escalate.

3. **Validate** that all:

   * Code changes are scoped to the task
   * Frontend + backend logic is consistent
   * UI changes reflect updated logic (if applicable)
   * Database schema changes are reflected in `schema/supabase_schema.sql`

4. **Update** affected `.md` files.

5. **Commit** with clear messages:

   ```bash
   git commit -m "feat(recipes): add service/ingredient booleans [aigen]"
   ```

6. **Push & PR**:

   * Push to your branch
   * Open a pull request into `main`
   * Link it to the relevant spec if possible

---

## 🧪 Testing Expectations

* All new functionality must be manually tested in the Streamlit UI
* DB views must be reviewed in SQL format (via pgAdmin, Supabase, or CLI)
* Feature must work from the user’s perspective, not just technically pass

---

## 🔍 Key Patterns to Follow

| Area              | Pattern / Rule                                                                                                                                                                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Commit Format     | `type(area): message [aigen]`                                                                                                                                                                                                                                      |
| Feature Spec File | `*.Specs.md` with deliverables checklist                                                                                                                                                                                                                           |
| Schema Sync       | Do not modify the schema dump directly. If a schema change is required, provide the SQL migration statement in the relevant feature spec or in a dedicated `.sql` file. A human will apply it and refresh `schema/supabase_schema.sql` using the provided tooling. |
|                   |                                                                                                                                                                                                                                                                    |

---

## 🛠 Supported Tools

* Supabase Postgres
* Streamlit (Python)
* pg\_dump (`dump_schema.sh`)
* GitHub branching with protection rules enabled

---

## 📄 Related Documents

* `dump_schema.sh` — how to keep DB schema up to date
* `Menu_Optimizer_Specs.md` — global feature specifications
* `Menu_Optimizer_Changelog.md` — release notes per version
* `Menu_Optimizer_DataDictionary.md` — table-by-table schema guide

---

**Maintained by:** Project Owner / OpsForge Architect
**Audience:** GitHub-based agents (Codex, Copilot), external devs, and collaborators
