# Recipes.py – Feature Release Workplan (MVP R1)

**Base branch:** `dev_featClean`  
**Commit policy:** One commit per group (full-file drop), then merge `--no-ff` into `dev_featClean`.  
**Owner:** Math (with AI copilot)  
**Scope guardrails:** Only items listed here. Anything else goes to “Out-of-scope / Later”.

---

## ✅ Definition of Done (this release)
- [x] Filters work: Status (All/Active/Inactive), Type (All/Service/Prep) with empty-safe UI
- [x] Table shows **Cost (% of price)** and **Margin ($)**; matches Editor/Home math
- [x] CSV export mirrors visible grid (filters + sort) with timestamped filename
- [ ] Form uses UOM dropdown; type-aware behavior (Prep excludes “service”; Service defaults “Serving”)
- [ ] Selecting a row loads **yield_uom** correctly
- [ ] Price disabled for **prep**
- [ ] Buttons inline: **Save / Delete / Clear**; Delete visible but disabled when no selection
- [ ] Clear button present and **does not crash**; final behavior chosen & implemented
- [ ] Soft delete = `status='Inactive'` (no hard deletes)

---

## Group A — Table, Filters, CSV
**Branch:** `feat/recipes-filters-kpis-csv`  
**Files:** `pages/Recipes.py`

### Features
- Status filter: **All / Active / Inactive** (empty-safe UI; export disabled if empty)
- Type filter: **All / Service / Prep** (empty-safe)
- Columns: **Cost (% of price)** and **Margin ($)**
- CSV export mirrors **current grid** (filters + sort)
- CSV filename: `recipes_<status>_<type>_<YYYYMMDD-HHMM>.csv`

### Commit
- [x] `feat(recipes): Group A — filters + KPIs + mirror-the-grid CSV [aigen]`
- [x] `feat(recipes): Group A — horizontal filters + formatted columns [aigen]`

### Testing
- [x] Inactive on all-active dataset → info state; Export disabled
- [x] Type=Prep → only prep rows; toggling back to All restores list
- [x] Cost% & Margin match Recipe Editor for sampled rows
- [x] Sort by Margin desc → export → CSV order matches grid; filename includes filters + timestamp

### Feedback Round 1
- Status & Type filter:
  - display should horizontal
  - no need for the "?" tooltip
  - when no results, no need for the blue message. The "No Rows To Show" message inside the table itself is enough
- Columns
  - price
    - Format: currency
    - rename: Price
  - margin
    - Format: currency
    - rename: Margin
  - total cost
    - format: currency with 5 decimal
    - rename: Total Cost
  - Cost (% of margin)
    - format: percent with 1 decimal
    - rename: Cost %
  - CSV export mirrors **current grid** (filters + sort)
    - radio style filters and in-table filters are mirrored in export
    - column sorting (I referred to it as order previously, maybe you though column order, my bad) is not reflected in the export.
  - CSV filename
    - all good here
  - Export disabled when table empty
    - When this is the case, can you show a message under the disabled button indicating that?

### Feedback Round 2
- Status & Type filter:
  - intially were still showing on multiple rows (2 instead of 3 previously)
    - I modified the line: 
        ```
        f1, f2, _ = st.columns([1,1,6])
        ```
        with
        ```
        f1, f2, _ = st.columns([1,1,1])
        ```
- column formats are good
- csv export doesn't maintain grid sort

### Decisions
- Rounding: Cost% to 1 decimal (match Editor/Home)
  - yes
- Export disabled when table empty
  - good idea
- We'll let go of csv export maintaining grid sort order. This is not important.

---

## Group B — Form UX & UOM behavior
**Branch:** `feat/recipes-form-uom-dropdown-and-behavior`  
**Files:** `pages/Recipes.py`

### Features & Results
| Feature                                                                  |      Success       | Partial | Failure | Feedback                                                                                                                                                                                                                                                                          |
| ------------------------------------------------------------------------ | :----------------: | :-----: | :-----: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UOM dropdown from `ref_uom_conversion` (unique union of from_uom/to_uom) | :heavy_check_mark: |         |         |                                                                                                                                                                                                                                                                                   |
| When **prep**: exclude `"service"` UOM                                   | :heavy_check_mark: |         |         |                                                                                                                                                                                                                                                                                   |
| When **service**: default UOM `"Serving"` (fallback `"unit"` if absent)  | :heavy_check_mark: |         |         | Now it works, I'm not a huge fan of the Recipe Type field being about the form but it works.                                                                                                                                                                                      |
| Selecting row always loads **yield_uom**                                 | :heavy_check_mark: |         |         |                                                                                                                                                                                                                                                                                   |
| Price input **disabled** for prep (remove “only relevant…” copy)         | :heavy_check_mark: |         |         | When clicking a row in the grid, the data is loaded in the form and when it's a prep recipe, then yes the pice field is loaded and greyed out. But when the form is blank, creating a recipe, selecting type = "prep" then the price field stays open. This needs to be corrected |
| Buttons always inline: **Save / Delete / Clear**                         | :heavy_check_mark: |         |         | Fixed                                                                                                                                                                                                                                                                             |
| Delete visible always, **disabled** unless a recipe is loaded            | :heavy_check_mark: |         |         |                                                                                                                                                                                                                                                                                   |

### Commit
- [x] `feat(recipes): Group B — UOM dropdown + type-aware behavior + form UX (price disabled for prep; inline actions) [aigen]`
- [x] "feat(recipes): Group B — UOM dropdown + type-aware behavior; price disables for prep; inline actions [aigen]

### Testing
- [x] Flip type service↔prep → UOM choices update; service defaults to “Serving”
- [x] Select several rows (service & prep) → yield_uom loads correctly
- [x] Price disabled for prep; editable for service
- [x] Change UOM, save, reselect → persists

### Feedback
- 
- When **service**: default UOM `"Serving"` (fallback `"unit"` if absent)
  - this does not work. I'm seeing the same list as when "prep" type is selected. Also, no need for the "unit" fallback, the record for "Serving" was added in the backend.
- 

### Decisions
- Fallback UOM for service is `"unit"` if “Serving” missing
- Delete is soft (status flip)

---

## Group C — “Clear” behavior (spike → pick → finalize)
**Branch (spike):** `spike/recipes-clear` → **Branch (final):** `feat/recipes-clear-final`  
**Files:** `pages/Recipes.py`

### Features (phase 1 – spike)
- Clear button present; safe placeholder (sentinel + `st.rerun()`)
- Toggle constant to try:
  - Option 1: page-bounce (`st.switch_page("Home.py")` then back)
  - Option 2: dummy-record reset (hidden from table)
- No crash, no auth prompt

### Commit (spike)
- [ ] `spike(recipes): Group C — Clear button placeholder + option switch [aigen]`

### Testing (spike)
- [ ] Case 1: typing new recipe → Clear resets to default empty
- [ ] Case 2: after Save → form clears; grid unchanged
- [ ] Case 3: selected row → Clear resets; grid selection irrelevant

### Decision
- Pick Option 1 or 2 and note why

### Commit (finalize)
- [ ] `feat(recipes): Group C — Clear behavior finalized (remove spike toggle) [aigen]`

### Testing (final)
- [ ] Re-run Cases 1–3 with final behavior

---

## Group D — Docs & Export polish
**Branch:** `chore/recipes-docs-and-export`  
**Files:** `pages/Recipes.py`, `docs/trackers/RECIPES_Workplan.md`

### Features
- CSV uses **exact grid snapshot** at click time
- CHANGELOG header + WHY comments added to code where non-obvious
- Workplan updated (checkboxes + short notes)

### Commit
- [ ] `chore(recipes): Group D — export snapshot correctness + docs/comments [aigen]`

### Testing
- [ ] Complex sort+filter → export → CSV matches grid exactly

### Feedback
- Notes here…

### Decisions
- Notes here…

---

## Out-of-scope / Later
- Multi-tenant project picker (`feat/multitenant-project-picker`)
- Settings CSV overhaul beyond Recipes (will come with task 3D)
- Any new KPIs not listed above
