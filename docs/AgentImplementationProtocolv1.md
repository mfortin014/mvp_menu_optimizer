# 📋 Agent Implementation Protocol – Menu Optimizer (v0.1.3+)

## 🎯 Objective

Ensure every feature is implemented cleanly, consistently, and traceably, following zero-waste dev practices. All logic, naming, and code structure must align with long-term migration goals (React + Supabase) and current MVP architecture.

---

## 🔄 Development Flow

### 1. Branching

* Create a dedicated Git branch:

  ```bash
  git checkout -b feature/recipes-as-ingredients
  ```
* Use semantic branch names: `feature/*`, `bugfix/*`, `refactor/*`

### 2. Commit Practices

* Atomic commits only – 1 commit = 1 logical change
* Use semantic prefixes:

  ```
  feat(recipe): add is_menu_item and is_ingredient booleans
  fix(recipe-form): prevent save when both booleans are false
  docs(data-dictionary): update recipes table structure
  ```
* Include `[aigen]` tag if commit was assisted by AI

### 3. Code & Data Updates

Update the following files if impacted by the feature:

| File                               | Action                                                   |
| ---------------------------------- | -------------------------------------------------------- |
| `Menu_Optimizer_Changelog.md`      | Add section under `v0.1.3` summarizing changes           |
| `Menu_Optimizer_DataDictionary.md` | Update `recipes` table definition                        |
| `Menu_Optimizer_Specs.md`          | Append or cross-reference `Recipes As Ingredients Specs` |
| `Menu_Optimizer_DevPlan.md`        | Move item from “Planned” to “Completed” under v0.1.3     |
| `README.md`                        | Reflect new functionality if user-facing change          |

---

## 🧪 QA & Validation

* Ensure no breaking changes to current recipe/ingredient flows
* Validate checkbox logic and save blocking when both are false
* Confirm DB migration compatibility with existing rows
* Use mock data to simulate nested recipe inclusion

---

## 📤 Final Deliverables

* Merge into `main` only after full local + functional testing
* Confirm all checklist items in the feature spec are completed
* Notify project owner or stakeholder (e.g., Mathieu) for review/demo

---

## 💡 Additional Notes

* Do **not** duplicate records across `recipes` and `ingredients`
* Avoid hardcoding logic; rely on DB flags (`is_ingredient`, etc.)
* Reuse existing helpers and UI components when applicable
* Maintain migration-aware structure across schema, code, and docs

---

**Author:** ChatGPT (Dev Co-Pilot)
**Version:** v0.1.3
