# Menu Optimizer v1.1 – README

## Overview

This MVP supports Chef's culinary consulting work by allowing them to manage and analyze recipes, ingredient costs, and performance. It is a prototype built in **Streamlit** using a **Supabase** backend. The project will later be migrated to a React + Supabase architecture inside the OpsForge platform.

---

## Key Features

### 🥦 Ingredient Management
- Add/Edit/Delete ingredients (soft delete only)
- Yield percentage support (for post-prep loss)
- Ingredient categories (linked to `ref_ingredient_categories`)
- Clean layout with editable form sidebar and data editor
- Radio-style selection behavior in the ingredient table
- Recipes can be flagged as **menu items** or **ingredients** for nesting

### 📄 Recipe Summary & Breakdown
- View recipe performance from `recipe_summary`
- Total cost, price, and margin calculation
- Uses latest cost view logic with `yield_pct`

### 📊 MPM Quadrant (Menu Performance Matrix)
- Visual graph (popularity vs profitability)
- Table format with quadrant filter (coming soon)

---

## Tech Stack

- Frontend: [Streamlit](https://streamlit.io)
- Backend: [Supabase](https://supabase.com)
  - PostgreSQL
  - RPC for recipe breakdown
  - View logic for costing

---

## Dev Setup

1. Clone this repo
2. Create `.env` file or set `secrets.toml` in `.streamlit/`
```env
SUPABASE_URL=...
SUPABASE_KEY=...
```
3. Install requirements
```bash
pip install -r requirements.txt
```
4. Run app:
```bash
streamlit run Home.py
```

---

## Project Structure

```
.
├── Home.py
├── pages/
│   └── Ingredients.py
├── utils/
│   ├── data.py
│   └── supabase.py
├── requirements.txt
├── .env
└── README.md
```

---

## Known Issues / To Do

- Ingredient "Select" column behavior not fully radio-style yet
- Recipe breakdown page still uses outdated cost logic
- Ref tables management (e.g., categories, UOM) not yet exposed in UI
- Inline editing in `st.data_editor` is currently disabled for validation consistency

---

## License
MIT