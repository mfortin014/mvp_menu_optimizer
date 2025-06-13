# 🧠 Menu Optimizer – MVP Progress Summary (As of 2025-06-12)

This document summarizes the key milestones, decisions, and technical patterns implemented during the Menu Optimizer MVP development.

---

## ✅ Key Features Implemented

### Ingredients Module
- **Ingredient Form with Validation**
  - `ingredient_code`, `name`, `ingredient_type`, `package_qty`, `package_uom`, `package_cost`, `yield_pct`, `status`, `category`
  - Defaults and validations mirror expected Supabase schema (e.g. yield_pct % logic, normalized type/status, capped field lengths)
  - Form uses Streamlit's sidebar; includes Save, Cancel, and soft Delete logic

- **Table View with AgGrid**
  - Shows ingredients in filterable, sortable table
  - Selection loads sidebar form for edit
  - Export to CSV (rounded numeric fields)
  - Selection logic mimics radio behavior (single edit target)

- **CSV Import with Validation**
  - Supports batch import of ingredients
  - Validation of all fields + conflict detection against existing rows
  - Rejected rows returned in downloadable CSV with error comments
  - Duplicate codes with same data silently skipped; conflicting rows flagged

### Recipes Module
- Same architecture as Ingredients page
- Added `recipe_category` (text field) between `status` and `yield`
- `base_yield_uom` now accepts free-form text (not tied to UOM table)
- Handles basic CRUD via form (Save, Cancel, Inactivate)
- Export to CSV with same rounding logic

### Reference Data Page
- Inline CRUD editors for:
  - `ref_ingredient_categories`
  - `ref_uom_conversion`
  - `ref_sample_types`
  - `ref_markets`
  - `ref_warehouses`
- No CSV export or deletion (MVP constraint)
- Simplified layout and usage flow

---

## 🔁 Technical Patterns

- Shared AgGrid setup for data tables
- Sidebar pattern for editing forms
- Field normalization (e.g. status/title capitalization)
- `st.session_state` used for selection memory and cancel logic
- Conflict resolution on import via content-aware duplicate comparison
- Decimal precision rounding at import and export
- Use of `st.rerun()` instead of deprecated `st.experimental_rerun()`

---

## 🧱 Infrastructure Notes

- All logic connects to Supabase via `supabase.table().select/insert/update`
- `yield_pct` logic: values between 0 and 1 are multiplied by 100
- Ingredient code and recipe code uniqueness enforced at the DB level and on submitting the form
- Manual schema modification occurred to add `recipe_category` field

---

## 🚧 Known Issues & MVP Limitations

- Cancel button does not resets form
- `ref_uom_conversion` used inconsistently for recipe vs ingredient UOMs
- No pagination or lazy loading yet
- No true deletion in reference data
- No recipe lines (ingredients per recipe) management yet

---

## 🧠 Design Decisions to Remember

- Ingredient and Recipe codes are enforced as unique at the database level
- CSV import does not allow overwriting existing entries via import (only via form)
- Ingredient/Recipe `status` is used to soft-delete (avoid true deletion)
- `base_yield_uom` for Recipes is intentionally free-form for MVP
- We opted to allow `package_uom` values not present in the UOM table for flexibility

---

## 🧭 Migration Planning Notes

- UOMs may need clearer scoping between measurement, packaging, and yield contexts
- Recipe-to-ingredient conversion for BOM-level recipes is deferred post-MVP
- Ref tables may benefit from their own structured forms + versioning in React
- Long-term: separate module for recipe lines with drag/drop support and cost validation

---

*Generated 2025-06-12 as a Phase 2 milestone snapshot.*
