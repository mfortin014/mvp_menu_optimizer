# Menu Optimizer MVP – Progress Summary (as of 2025-06-12)

## ✅ MVP Feature Implementation

### Core Features

* **Recipe Management** (`Recipes.py`)

  * CRUD interface for recipe headers (code, name, base yield, price, etc.)
  * Inactive state used for soft deletion
  * CSV export of recipe list
  * Form prefill logic restored and aligned with Ingredients pattern
  * Recipe category field added to table, form, and Supabase schema

* **Ingredient Management** (`Ingredients.py`)

  * CRUD form with validations, dropdowns for status/type/UOM
  * Fully functional AgGrid table with filtering/sorting
  * CSV import and export
  * Rounding and conversion for yield\_pct
  * Duplicate ingredient\_code detection with diff visualization

* **Import Functionality** (`Import.py`)

  * Ingredient import with inline validation, rejection tracking, and CSV export of failed rows
  * Support for partial loads
  * Detailed summary UI with reason tracking
  * Import type selector scaffolded (CSV only supported for now)
  * Recipe import logic (matching spec) implemented

* **Reference Data Editor** (`ReferenceData.py`)

  * Unified UI to manage multiple `ref_` tables (e.g., UOMs, Categories, Statuses)
  * Inline table editor with `add/save/reset` controls
  * No CSV export or row deletion (as decided)

### Supabase Schema Updates

* New field added: `recipe_category` to `recipes` table
* Validation constraints honored on frontend (even if not enforced in DB for all fields)
* Note: `recipe_code` and `ingredient_code` have unique constraints in Supabase

### Misc Improvements

* `st.experimental_rerun()` replaced with `st.rerun()`
* Numeric precision rounding set to 6 decimals for all numeric inputs and exports
* Form save logic upgraded to prevent submission if required fields are missing
* All import forms now strip and normalize data, and drop "errors" column if present
* Data preview and error summary included before insert

## 🟡 In Progress / To Finish Before MVP Release

* [ ] Final validation of CRUD and Import/Export for Recipes
* [ ] Smoke test of Reference Data page (CRUD save/reset working?)
* [ ] Add "Clear All Data" button (to reset Chef’s workspace)
* [ ] Validate all forms respect numeric default values (e.g., package\_qty = 1)
* [ ] Implement full testing of user-facing CSV imports/exports
* [ ] Ensure Supabase is not paused and connection is stable for demo/test

## 🧠 Notes & Observations

* Supabase downtime caused delays and masked some frontend bugs
* Unique constraint on ingredient\_code saved us from duplicate uploads via form
* Ingredient import logic is most robust of all workflows and serves as blueprint
* Refactoring code to reuse validation logic between CRUD and import may help post-MVP
* CSV editor for failed imports was proposed but deferred for now

## 🕳️ Known Gaps or Bugs

* "Cancel" on form doesn't clear form context (known, not MVP blocking)
* AgGrid filters: no "clear all filters" yet, and no "clear filter" per column
* Some UOMs (like "each") don’t appear unless added to `ref_uom_conversion`
* Form submission can still feel brittle when required fields are missing silently (minor UX)

## 🧭 Post-MVP Considerations

* Multi-client layer (so Chef can manage multiple businesses or clients)
* Full support for nested recipes / multi-level BOMs
* SCD-style ingredient packaging data
* Improved onboarding flow (clear data, restore sample data)
* Add recipe category table and refactor `recipes.recipe_category` to `category_id`
* Visual PP Matrix for recipe performance (existing spec)
* Import UX enhancements: CSV diff editor, conflict resolution UI, AI cleanup suggestions
* Git/GitHub branching guardrails now active in dev process

---

This document should be used in the next dev cycle to track final MVP polish tasks, demo readiness, and planning of post-MVP upgrades.

Author: ChatGPT (Dev Co-pilot) – based on conversation history with user
