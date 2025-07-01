# Menu Optimizer – Dev Plan (Latest)

## Purpose

To outline the current scope, phases, and decisions guiding the MVP build of the Menu Optimizer. This plan is modular, migration-aware, and tightly scoped to enable a quick MVP release followed by iterative upgrades.

---

## 🧩 MVP GOALS

* Enable Chef to start building his dataset from scratch.
* Core CRUD interface for Ingredients and Recipes (header only).
* CSV import/export for Ingredients and Recipes.
* Interactive grid table for editing, selection, and filtering.
* Reference Data Management (CRUD only, no import/export).
* Manual recipe entry (lines handled in separate Recipe Editor page).

### ✅ MVP Features Implemented

* Ingredients Page with full CRUD, CSV import/export.
* Recipes Page with full CRUD, CSV export (import pending testing).
* Reference Data Page with direct table editors (no forms).
* Ingredient form includes: validation, duplication check, dropdowns.
* Recipe form includes: text-based category and yield UOM (not ref-validated).
* Recipes can be flagged as menu items or ingredients (v0.1.3).
* Ingredient and Recipe import logic with:

  * CSV field validation
  * Graceful rejection with downloadable rejected rows CSV
  * Duplicate row detection with detailed conflict summary
  * Auto-conversion of fractional yields (e.g. 0.99 → 99%)

### 🚧 In Progress / Blocked (as of 2025-06-12)

* Supabase availability impacted app testing
* Recipe import testing blocked
* Some minor UI polish deferred (e.g. "Cancel" not clearing forms)

### 🔜 Pre-MVP Tasks Remaining

* Finish testing Recipe CSV import and CRUD edge cases
* Implement Clear All Data button for admin reset
* Final round of manual validation

---

## 🔁 Post-MVP Features (Planned)

* Client layer: isolate data sets per client
* UOM Packaging Structure per ingredient (multi-tiered)
* Ingredient/Recipe archiving and history (SCD-style tracking)
* Filtering enhancements (Clear all filters, individual filter resets)
* Form cancel = true form reset behavior
* Column-level validation hints in import
* In-app UI editor for rejected rows (alternative to CSV feedback)
* Recipe lines editor CRUD integration
* Proper UOM and Recipe Category reference tables

---

## 🛠 Stack & Dev Guidelines

* **Frontend**: Streamlit (rapid prototyping)
* **Backend**: Supabase (PostgreSQL + REST API)
* **Data Layer**: Normalized relational schema with naming standards
* **Migration Ready**: Dev decisions respect future React + Supabase port
* **Git Workflow**: Work on branches, write clear commits, never commit to `main`
* **Componentization**: Match page/component structure across object types

---

## ✅ Workflow Notes

* All object forms (Ingredients, Recipes) follow same UI logic
* Page structure includes:

  * Table (AgGrid)
  * Sidebar form (pre-filled when editing)
  * Export section
  * Import handled on dedicated page, or bottom of object page (per MVP decision)
* Error messages use same copy system ("Please complete all fields")
* Import fields validated per column, normalized as needed (status, type, etc.)

---

## 📌 Key Naming Conventions

* Status: \[Active, Inactive]
* Ingredient Type: \[Bought, Prepped]
* Category: Text field, resolved via `ref_ingredient_categories`
* Recipe Category: MVP = free text
* UOM: Resolved through `ref_uom_conversion`, fallback allowed in Recipe page
* Codes: Unique constraints enforced in DB and import logic (e.g., `ingredient_code`)

---

## 👤 End User

Chef – culinary consultant aiming to use the tool for:

* Ingredient-level costing
* Menu analysis and re-engineering
* Client onboarding (eventually multi-tenant)

Tool must remain fast, resilient, portable, and extensible.

---

## 📦 Structure

* `pages/` for Streamlit views (Ingredients, Recipes, Import, RefData)
* `utils/` for data and API helpers (e.g., `supabase.py`, `data.py`)
* Modular pattern matches future React+Supabase app structure

---

*Last updated: 2025-06-12*
