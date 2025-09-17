# Menu Optimizer — Recipe Editor: Spec & Checklist (MVP Sprint)

_Last updated: 2025-09-06 03:51 (local)_

## 1) Scope & Intent
Make the Recipe Editor stable, predictable, and testable by: hardening filters, clarifying the “Clear” behavior, separating grid vs form state, and polishing exports, KPIs, and small UX details. No data is lost; soft-delete remains.

---

## 2) UI/UX Behaviors (consolidated)

### 2.1 Filters & Table
- [ ] **Status filter** implemented with options: `All / Active / Inactive`
- [ ] **Type filter** implemented with options: `All / service / prep`
- [ ] **KPI columns** visible in table: **Cost %** and **Margin ($)**
- [ ] **Inactive filter crash fixed**: handle empty DataFrames before any `zip(*)`/`explode` step
- [ ] **Type radio safeguard**: page tolerates **zero rows** for any filter combination without error

### 2.2 Buttons & Controls
- [ ] **Buttons layout**: always side-by-side in **three fixed columns**
- [ ] **Delete** label remains **“Delete”** (still **soft-delete** under the hood)
- [ ] **Delete** is **visible but disabled** when nothing is selected
- [ ] **Price field** is **disabled** when `recipe_type='prep'`
- [ ] **Yield UOM preselect**: persists after selection and on Clear

### 2.3 CSV Export
> Two captured options — choose at ship time and tick all that apply.

- [ ] **Filename** includes timestamp `YYYY-MM-DD_HH-MM`
- [ ] **Chosen CSV behavior: Simple export (for now)**
- [ ] **Chosen CSV behavior: Honors grid filter + sort** via `DataReturnMode.FILTERED_AND_SORTED` using `grid["data"]`
  - [ ] If chosen, **client-side sort/filter parity** verified

---

## 3) “Clear” Action — Final Model

### 3.1 Design: **Decouple grid selection from the form**
Treat the grid as a **picker only**. The form maintains its **own state**; clicking a row **loads the form once**, then the form is independent.
- [ ] **Form is source of truth**; grid selection is not mutated by Clear/Save
- [ ] **Grid selection remains untouched** when **clearing** or **saving**

> **Deprecated (documented for traceability):** Bumping a `recipes_grid_key` to force the grid to lose selection. **Not used.**

### 3.2 Form state in `st.session_state` (form-only)
- [ ] `rf_edit_id` (None for new, `<recipe_id>` for editing)
- [ ] `rf_recipe_code`
- [ ] `rf_name`
- [ ] `rf_status`
- [ ] `rf_type`
- [ ] `rf_yield_qty`
- [ ] `rf_yield_uom`
- [ ] `rf_price`

### 3.3 Actions (three scenarios)
1) **Clear while creating**
   - [ ] Reset all `rf_*` to defaults: `status=Active`, `type=service`, `yield_qty=1.0`, `yield_uom` default, `price=0.0`
   - [ ] `rf_edit_id = None`
   - [ ] **Do not** touch grid selection

2) **Save after editing**
   - [ ] Persist changes
   - [ ] Reset `rf_*` to defaults; `rf_edit_id = None`
   - [ ] **Do not** touch grid selection

3) **Clear while editing** (return to “new recipe” mode)
   - [ ] Same as (1)
   - [ ] **Do not** touch grid selection

---

## 4) Row-Click Crash — Selection Parser
Normalize selection input with a small helper:
- [ ] If `selected_rows` is a **list** and non-empty → use `list[0]["id"]` (if present)
- [ ] If `selected_rows` is a **DataFrame** → convert to records, then `records[0]["id"]`
- [ ] Otherwise → `None`

This removes ambiguity errors without special cases.

---

## 5) UOM Behavior (service vs prep)

### 5.1 Display logic
- [ ] **Prep** recipes: show the **full UOM list** from `ref_uom_conversion`
- [ ] **Service** recipes: default the **Yield UOM** to **Serving**

### 5.2 Implementation choice (**Option B — explicit DB identity row**)
- [ ] Insert identity row in `ref_uom_conversion`: `('Serving', 'Serving', 1.0)`
- [ ] Store `yield_uom='Serving'` directly for service recipes
- [ ] UI validation auto-sets `Serving` for `service` type

_Note: a one-liner SQL insert can be added upon request; intent is recorded._

---

## 6) Workflow & Branching

### 6.1 Micro-branches (small, single-purpose → merge → delete)
Always branch from `dev_feat_prep_recipe_as_ingredient` **after a pull**:

- [ ] `feat/recipes-service-uom-serving` — UI shows “Serving”; DB stores unit; validation auto-sets
- [ ] `feat/recipes-price-disable-prep` — Disable Price when `recipe_type='prep'`
- [ ] `feat/recipes-kpi-table-polish` — Cost%/Margin robust, crash-free on empties
- [ ] `feat/recipes-grid-export` — Honors client-side sort/filter (if pursued now)

**Branch template**
```bash
git checkout dev_feat_prep_recipe_as_ingredient
git pull --ff-only
git checkout -b feat/<tiny-scope-name>

# ... code, test ...
git add -A
git commit -m "<type>(Recipes): <short description>"
git push -u origin feat/<tiny-scope-name>

git checkout dev_feat_prep_recipe_as_ingredient
git pull --ff-only
git merge --no-ff feat/<tiny-scope-name> -m "merge: <tiny-scope-name>"
git push

git branch -d feat/<tiny-scope-name>
git push origin :feat/<tiny-scope-name>
```

### 6.2 Why this flow
- **Single-purpose branches** keep risk contained and reviews trivial.
- **No fast-forward merges** → clear grouping in history.
- **No grid hacks for Clear** → state belongs **in the form**, not the grid.

---

## 7) Quick Reference — Defaults & Guardrails
- **Form defaults** (on Clear or post-Save):  
  `status=Active`, `type=service`, `yield_qty=1.0`, `yield_uom=default/Serving (per rules)`, `price=0.0`
- **Soft-delete** only; “Delete” label unchanged.
- **Resilience**: zero-row tolerance across filters; empty-frame checks before transforms.
- **CSV**: timestamped filename; choose **Simple** now or **Filtered+Sorted** now (see §2.3).

---

## 8) Acceptance Checklist (ship-ready)
- [ ] Filters: Status & Type work; zero-row safe
- [ ] KPIs: Cost % & Margin render; no crashes on empties
- [ ] Buttons: three columns; Delete disabled with no selection
- [ ] Price: disabled when `recipe_type='prep'`
- [ ] Yield UOM: preselect persists; Service defaults to “Serving”
- [ ] “Clear”: resets **form only**; never mutates grid selection
- [ ] Row-click helper: list/DataFrame selection normalized without error
- [ ] CSV: timestamped files; chosen behavior implemented per §2.3
- [ ] Soft-delete confirmed; label remains “Delete”
