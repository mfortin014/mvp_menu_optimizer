# Menu Optimizer MVP – Phase 1 Completion Report

## Overview
The Menu Optimizer MVP is a lightweight Streamlit app designed to help culinary consultants analyze menu item performance. Phase 1 delivers a working prototype using Streamlit and Supabase.

---

## ✅ Summary of Phase 1 Deliverables

### Stack
- **Frontend**: Streamlit (native multipage)
- **Backend**: Supabase (PostgreSQL)
- **Runtime**: Python 3.10 (WSL with `.venv`)
- **Deployment**: Local development, Supabase cloud database

### Folder Structure
```
menu_optimizer/
├── .venv/                # Virtual environment (not committed)
├── app.py                # Dashboard / entry point
├── pages/                # Multipage structure
│   ├── Ingredients.py    # Ingredients table view
│   └── Recipes.py        # [Placeholder for Phase 2]
├── utils/
│   └── data.py           # Central data access to Supabase
├── .streamlit/
│   └── secrets.toml      # Supabase API credentials
├── requirements.txt      # Project dependencies
├── README.md             # Dev usage
```

### App Capabilities (Phase 1)
- ✅ View ingredients data from Supabase
- ✅ Connect securely via `secrets.toml`
- ✅ WSL + Streamlit local runtime
- ✅ Git-initialized with best practices

### Supabase Setup
- Project created and API credentials configured
- Table `ingredients` created with UUID PK, `updated_at`, and soft metadata columns
- RLS enabled with permissive read policy
- Auto-updating `updated_at` column via trigger
- 5 test records seeded and confirmed

### App Pages Implemented
- **Dashboard (`app.py`)** – Placeholder chart based on recipe popularity & profitability
- **Ingredients** – Live display from `ingredients` table with empty fallback

---

## Git Commit Best Practices

### Format
```
<type>(<scope>): <message>
```

### Examples
- `feat(ui): add navigation sidebar with radio buttons`
- `fix(data): fallback on failed Supabase call`
- `chore: restructure repo and activate multipage layout`

### Types
- `feat` – new user-visible feature
- `fix` – bugfix
- `chore` – config, structure, tooling
- `docs` – updates to README, specs
- `refactor` – internal rework without changing behavior

---

## Next Steps (Phase 2 Preview)
- [ ] Create `recipes` and `recipe_lines` tables
- [ ] Seed both tables with sample data
- [ ] Build Recipes page UI
- [ ] Add dropdown interaction to load detailed recipe view
- [ ] Begin logic layer and computation for profitability matrix

---

## Contact & Ownership
Maintainer: **Mathieu**  
Project Context: Sur Le Feu / OpsForge foundational module