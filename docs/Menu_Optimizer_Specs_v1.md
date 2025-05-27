# Menu Optimizer – Technical Requirements Specification (v1.0.0)

## Purpose
To define the technical scope and stack for the Menu Optimizer MVP, enabling a culinary consultant to evaluate menu items based on performance data. This specification supports structured development, deployment, and future integration with OpsForge.

---

## 1. Application Architecture

### Frontend
- **Framework**: [Streamlit](https://streamlit.io/)
- **Design**: Native multipage layout
- **UI Layer**: Streamlit widgets, `st.dataframe`, `st.altair_chart`
- **Routing**: Streamlit folder-based multipage system

### Backend
- **Database**: [Supabase](https://supabase.com/) (PostgreSQL hosted)
- **Auth**: Public anon key (RLS enabled)
- **API Client**: `supabase-py`
- **Secrets Management**: `.streamlit/secrets.toml`

---

## 2. Tech Stack

| Component       | Technology           | Notes                              |
|----------------|----------------------|------------------------------------|
| Language        | Python 3.10+         | Running inside WSL                 |
| Frontend        | Streamlit            | Local runtime                      |
| Database        | Supabase (Postgres)  | Connected via REST + RPC           |
| Hosting         | Local only (for now) | Supabase backend hosted            |
| VCS             | Git                  | Git-based commit discipline        |

---

## 3. Folder Structure

```
menu_optimizer/
├── .venv/                # Python environment (local only)
├── app.py                # Dashboard
├── pages/                # Modular views
│   ├── Ingredients.py    # Phase 1 complete
│   ├── Recipes.py        # Phase 2 WIP
├── utils/
│   └── data.py           # Supabase client abstraction
├── .streamlit/
│   └── secrets.toml      # Supabase connection keys
├── requirements.txt      # Pinned dependencies
├── README.md             # Dev usage & git convention
```

---

## 4. Supabase Table Requirements

### Table: `ingredients`
- `id` (uuid, pk)
- `ingredient_code` (text)
- `name` (text)
- `ingredient_type` (text)
- `status` (text)
- `package_qty` (numeric)
- `package_uom` (text)
- `package_type` (text)
- `package_cost` (numeric)
- `base_uom` (text)
- `std_qty` (numeric)
- `unit_weight_g` (numeric)
- `yield_qty` (numeric)
- `message` (text)
- `updated_at` (timestamp, auto)

### Table: `recipes` (Phase 2)
- `id` (uuid, pk)
- `recipe_code` (text)
- `name` (text)
- `status` (text)
- `base_yield_qty` (numeric)
- `base_yield_uom` (text)
- `price` (numeric)
- `updated_at` (timestamp, auto)

### Table: `recipe_lines` (Phase 2)
- `id` (uuid, pk)
- `recipe_id` (uuid, fk)
- `ingredient_id` (uuid, fk)
- `qty` (numeric)
- `qty_uom` (text)
- `note` (text)
- `updated_at` (timestamp)

---

## 5. Supabase Best Practices
- Enable RLS
- Use `uuid_generate_v4()` for keys
- Use `now()` for `updated_at`
- Dev policy: `USING (true)` during MVP
- Consider future use of views or RPCs for matrix summaries

---

## 6. MVP Success Criteria
- [x] Connect to Supabase from local app
- [x] Display ingredients from cloud
- [x] Confirm RLS works without error
- [x] Use secrets for environment-safe access
- [x] Git-enabled with clear commit messages
- [ ] Recipes & lines visible and interactive

---

## 7. Future Scope
- CRUD interface
- Auth & roles
- Versioned costing
- Export to PDF/Excel
- Migration to OpsForge module