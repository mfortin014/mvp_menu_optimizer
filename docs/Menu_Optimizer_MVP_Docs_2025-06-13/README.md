# 📘 Menu Optimizer – MVP

This MVP is a working prototype built in Streamlit to support **Chef**, a culinary consultant offering services like:

* Menu analysis & optimization
* Menu re-engineering
* Ingredient-level costing
* Profitability tracking
* New recipe ideation

This MVP is designed to validate workflows, UX patterns, and core data logic before the tool is rebuilt in **React + Supabase** inside the **OpsForge** platform.

---

## ⚙️ Tech Stack

* **Frontend:** Streamlit (Python)
* **Backend:** Supabase (PostgreSQL)
* **UI Framework:** st\_aggrid
* **Data Export:** CSV
* **Data Structure:** Modular, normalized tables using shared patterns

---

## ✅ Features by Section

### Ingredients

* Full CRUD via form
* Filterable, sortable table
* CSV export
* CSV import with validation and rejection summary
* Package cost & yield validation

### Recipes

* CRUD for recipe header only (not ingredients yet)
* Free-form base yield UOM
* Recipe category field (free-form text)
* CSV export

### Reference Data

* Inline editors for:

  * Ingredient categories
  * UOM conversions
  * Sample types
  * Markets
  * Warehouses
* Soft edit/save pattern

---

## 📤 Import Logic Summary

**Validated fields:**

* `ingredient_code`, `name`, `ingredient_type`
* `package_qty`, `package_uom`, `package_cost`
* `yield_pct`, `status`, `category`

**Rejection behavior:**

* Missing or invalid fields
* Duplicate codes with conflicting data

**Conflict resolution:**

* Matching code with same data: skipped silently
* Matching code with different data: flagged in summary
* Rejected rows exported with error comments

---

## 🚧 Known Limitations

* No multi-level BOM or recipe lines yet
* Some dropdowns rely on free-form text (not ideal)
* No user authentication
* No real-time collaboration
* Minimal styling – MVP focus is function over polish

---

## 🔄 Migration Plan

When rebuilding in React + Supabase:

* Recipes will include ingredient lines and costing
* UOM handling will be standardized
* Reference data will have full relational integrity
* Multi-tenant and access control logic will be added
* All validations will move to the backend for reliability

---

## 🧭 Project Ethos

* **Fast > Fancy** — we validate logic before UI
* **MVP ≠ Final** — expect change and refactoring
* **Migration-Aware** — everything is built for future reuse
* **Zero-Waste Dev** — all logic feeds into OpsForge modules
