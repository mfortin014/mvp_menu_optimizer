# 📦 Menu Optimizer – Changelog

## MVP Build – June 2025

### ✅ Core Functionality (MVP Complete)
- Full CRUD interface for **Ingredients** and **Recipes**
- Integrated CSV **Import/Export** for Ingredients and Recipes
- Ingredient import includes:
  - Field-level validation and normalization
  - Category name lookup and mapping
  - Rejection summary with downloadable error file
  - Duplicate detection with value comparison
- Recipe import supports basic fields and minimal validation
- Central **Reference Data** page for managing:
  - `ref_ingredient_categories`
  - `ref_uom_conversion`
  - `ref_sample_types`
  - `ref_warehouses`
  - `ref_markets`
  - `ref_seasons`
- Recipes and Ingredients now include **status** field and soft-deletion behavior
- `base_yield_uom` temporarily decoupled from ref UOM table for MVP simplicity
- Recipe editor placeholder structured for future use

### 🧪 Testing and Stability
- All core pages tested with Supabase
- Identified Supabase outage and confirmed app gracefully failed
- Error logs and UX adjusted to reflect DB connection failures
- Form validation messages improved (e.g., field highlighting, rerun behavior)

### 🛠 Developer & Architecture Decisions
- Streamlit MVP organized using a multi-page architecture
- Shared utilities for Supabase access, themes, and data transformation
- Modular and minimal styling to allow easy future React migration
- Git workflow stabilized: `main` + `feature/*` + atomic commits
- Context logging for out-of-scope ideas and post-MVP enhancements

### ⚠️ Known Limitations / Tech Debt
- Cancel button does not clear forms due to Streamlit rerun behavior (documented)
- No client-layer implemented yet (deferred post-MVP)
- UOM conversion logic not enforced at usage level
- Recipe lines (multi-level BOM) and cost breakdown not implemented

### 📌 Decisions for Future Phases
- Add multi-level packaging structure for ingredients
- Add recipe categories table with full FK integration
- Clarify behavior of duplicate recipe codes (currently blocked on insert)
- Possibly separate `ref_uom_display` from `ref_uom_conversion`
- Implement form field validation with per-field highlighting
- Replace Streamlit `st.experimental_rerun` with `st.rerun` universally
- Add full audit trail logging (SCDs and change tracking)

---

_Last updated: 2025-06-12_

Maintainer: `OpsForge Dev Team`
