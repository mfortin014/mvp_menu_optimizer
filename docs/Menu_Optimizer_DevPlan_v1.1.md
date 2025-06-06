
# Menu Optimizer – Dev Plan & Checklist (Updated v1.1)

## ✅ Phase 1: MVP Foundation

### Setup
- [x] Python 3.10 installed in WSL
- [x] Virtual environment `.venv` created and activated
- [x] Git initialized in project folder
- [x] Supabase project created
- [x] `SUPABASE_URL` and `SUPABASE_KEY` added to `secrets.toml`
- [x] `.streamlit/` directory created

### Frontend App
- [x] `app.py` created as landing page
- [x] Streamlit multipage structure in place (`pages/` folder)
- [x] `Ingredients.py` page added with working CRUD (Phase 1)

### Supabase
- [x] `ingredients` table created via SQL
- [x] RLS enabled with permissive policy
- [x] `updated_at` trigger added
- [x] Ingredient categories (`ref_ingredient_categories`) added
- [x] Category foreign key added to ingredients
- [x] `yield_qty` field replaced with `yield_pct`
- [x] Filtering and inactivation logic added (no hard deletes)
- [x] Editable category system added (via linked dropdown)

### Data Layer
- [x] `utils/data.py` and `utils/supabase.py` created
- [x] All Supabase interactions abstracted
- [x] Data fetching utilities added for recipes and ingredients
- [x] UOM and category loaders added

### UI/UX Improvements
- [x] Replaced dataframe view with `st.data_editor` table
- [x] Added single-select "radio-style" row picker using checkboxes
- [x] Ingredient details load into sidebar form on selection
- [x] Form handles Add, Edit, Cancel, Soft Delete (Inactive)
- [x] Inline category name display and mapping

---

## ⏭️ Phase 2: Recipes & Costing

### Schema
- [x] `recipes` table created in Supabase
- [x] `recipe_lines` table created in Supabase
- [x] Sample recipe and line items added
- [x] Policy and trigger setup for new tables

### Pages
- [x] `Recipes.py` displays costing table and summary metrics
- [ ] Recipe line CRUD (Add/Delete lines to recipe)
- [ ] Ability to edit recipe metadata (yield, price, etc.)

### Costing Logic
- [x] `get_recipe_details` RPC updated to use `yield_pct`
- [ ] Validate line_cost logic for edge cases
- [ ] Add performance flags (cost %, MPM quadrant)

---

## 🔁 Outstanding Issues

- [ ] Radio-style checkbox selection still buggy — user can check multiple rows, and unchecking does not preserve last selected row reliably.
- [ ] No enforcement of unique ingredient codes.
- [ ] Performance quadrant classification pending (was paused).
- [ ] Recipe page doesn’t support editing or viewing ingredients inline.
- [ ] True delete logic not yet built (cascading constraints needed).
- [ ] Category CRUD not yet implemented — static values only.

---

## 📌 Next Steps

- [ ] Fix single selection logic in Ingredients table UI
- [ ] Add MPM quadrant fields to `recipe_summary` and integrate into dashboard
- [ ] Enable ingredient CRUD from `Recipes.py`
- [ ] Add "clone" or "duplicate" recipe functionality
- [ ] Export costing report (CSV or PDF)
