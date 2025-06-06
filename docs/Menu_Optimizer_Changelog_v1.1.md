# Menu Optimizer – Dev Changelog

## ✅ Completed This Session

### Ingredient CRUD Refactor
- Created `pages/Ingredients.py` with:
  - New sidebar form for Add/Edit.
  - Filtering, category display, and clean layout.
  - Removed old inline button layout and replaced it with a `st.data_editor`-based table with a "Select" column.
- Linked categories via foreign key (`category_id`) to `ref_ingredient_categories`.
- Updated ingredient display to show:
  - Ingredient Code
  - Category Name
  - Type, Cost, Yield %, Status
- Added radio-style selection behavior in the ingredient table.
- Form loads selected item into sidebar for editing.
- Form includes Cancel and Soft Delete (status = "Inactive") actions.

### Costing Logic Updates
- Replaced `yield_qty` with `yield_pct` in `ingredients` table.
- Applied new cost calculation logic in all views:
  - `adjusted_qty = recipe_qty / (yield_pct / 100)`
- Views updated:
  - `recipe_line_costs`
  - `recipe_summary`
- Removed now-obsolete `yield_qty` field.

### Supabase + Utils Refactor
- Refactored `supabase.py` and `data.py` to:
  - Avoid duplication
  - Separate connection logic vs. data fetching logic
- Fixed import errors for missing `utils.supabase`

## 🔧 Still Pending / Incomplete

### Ingredient Form Selection Behavior
- Current "radio-style" selection in `st.data_editor` is not working perfectly.
- ✅ Only 1 row is allowed to be selected.
- ❌ But selection behavior is inconsistent (last selected ≠ last loaded).
- 👉 Needs further JS-based or UI workaround if it becomes a priority.

### Recipe Page Bug
- `recipes.py` still uses old yield-based cost calculations.
- Needs update to match `yield_pct` and new costing logic.

### Styling & UX Polish
- Possible enhancements for future:
  - Better visual cue on selected ingredient
  - Persist filters / sort in data editor
  - True modal form support (once we move to React)

---

## Next Up (Suggested Priorities)
1. 🧪 Fix recipe cost logic in `recipes.py`
2. ✍️ Add full CRUD support for:
   - Recipe Lines (multi-row)
   - Categories
   - Ref tables (UOM, status)
3. 📊 Filter & sort MPM quadrant graph + table
4. 📦 Ingredient Inventory & Real-time Cost Adjustments
5. 🛠️ Phase 2 Streamlit polish before React migration