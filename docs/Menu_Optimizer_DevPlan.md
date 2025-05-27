# Menu Optimizer – Dev Plan & Checklist (Phase 1 to 2)

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
- [x] `Ingredients.py` page added with working table view

### Supabase
- [x] `ingredients` table created via SQL
- [x] RLS enabled with permissive policy
- [x] `updated_at` trigger added
- [x] 5 ingredients inserted

### Data Layer
- [x] `utils/data.py` created
- [x] All Supabase interactions abstracted
- [x] Test connection confirmed with print/debug

### Misc
- [x] README and git commit standards documented
- [x] First commits staged and pushed locally

---

## ⏭️ Phase 2: Core Data & Page Expansion

### Schema
- [ ] `recipes` table created in Supabase
- [ ] `recipe_lines` table created in Supabase
- [ ] Sample data seeded into both tables
- [ ] Policy and trigger setup for each table

### Pages
- [ ] `Recipes.py` page added
- [ ] `Dashboard` (chart logic) connects to live `recipe_summary`
- [ ] Dropdown or filter for selecting a single recipe
- [ ] Table: recipe ingredients breakdown view

### Data Access
- [ ] Add `load_recipes_summary()` to data.py
- [ ] Add `load_recipe_details()` to fetch breakdown via RPC or SQL
- [ ] Update ingredient loader to use `select(columns)`

### Docs & Git
- [ ] Update README with schema additions
- [ ] Commit Phase 2 schema + seed scripts to `/sql/`
- [ ] Git commit: `feat(schema): add recipes + recipe_lines structure`
- [ ] Git commit: `feat(ui): render recipe list page with breakdown`

---

## Future (Phase 3+)
- [ ] Editable CRUD tables in Streamlit
- [ ] Calculated cost per recipe
- [ ] Add/delete ingredients from a recipe
- [ ] Filter by market/season
- [ ] Export CSV or formatted costing PDF
- [ ] Admin login + restricted view by client