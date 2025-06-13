# Menu Optimizer – Functional & Technical Specifications

## 🔍 Purpose

This document outlines the core functionality, structure, and technical requirements of the Menu Optimizer MVP. It is designed to ensure consistency across development, testing, and eventual migration to the OpsForge platform.

---

## 🧠 Product Scope

The Menu Optimizer MVP is a lightweight prototype of a culinary consulting tool used by Chef to:

* Analyze, optimize, and re-engineer restaurant menus
* Track ingredient-level costs and profitability
* Support ideation and documentation of new recipes

This MVP will be built in Streamlit for rapid iteration and will later be migrated to a React + Supabase implementation inside OpsForge.

---

## ✨ Core Features (MVP)

### 1. Ingredient Management

* Add/Edit/Deactivate ingredients (CRUD)
* Fields:

  * `ingredient_code` (unique)
  * `name`
  * `ingredient_type` (Bought, Prepped, or blank)
  * `package_qty`, `package_uom`, `package_cost`, `yield_pct`
  * `status` (Active/Inactive)
  * `category`
* Package cost and yield are used to compute cost per base unit
* Validation: all fields required except optional ones like `ingredient_type`
* CSV Export & CSV Import (with pre-validation, rejected rows file, duplicate detection)

### 2. Recipe Management (Header Only)

* Add/Edit/Deactivate recipes
* Fields:

  * `recipe_code` (unique)
  * `name`
  * `recipe_category` (free text)
  * `base_yield_qty`, `base_yield_uom`
  * `price`
  * `status`
* CSV Export

### 3. Recipe Editor (WIP)

* Designed to allow dynamic editing of recipe lines
* Currently under development (Phase 2+)

### 4. Reference Data Editor

* Inline editors for:

  * `ref_ingredient_categories`
  * `ref_uom_conversion`
  * `ref_sample_types`
  * `ref_warehouses`
  * `ref_markets`
  * `ref_generic_status`
  * `ref_seasons`
* Supports inline Add/Edit, no delete or CSV export required

### 5. Clear All Data

* Admin-only button to clear all core data tables:

  * `ingredients`, `recipes`, `recipe_lines`, `ref_*`
* Useful for switching from dummy data to a clean client dataset

### 6. Home Dashboard

* Basic matrix visualization of Profitability vs Popularity (manual dummy data)

---

## 🧱 Database Overview

### Ingredients Table

| Field            | Type    | Notes                       |
| ---------------- | ------- | --------------------------- |
| id               | UUID    | Primary Key                 |
| ingredient\_code | Text    | Unique, required            |
| name             | Text    | Required                    |
| ingredient\_type | Text    | Optional                    |
| package\_qty     | Numeric | Required                    |
| package\_uom     | Text    | Required                    |
| package\_cost    | Numeric | Required                    |
| yield\_pct       | Numeric | Required, 1–100 (%)         |
| category\_id     | UUID    | FK to ingredient categories |
| status           | Text    | Active/Inactive             |

### Recipes Table

| Field            | Type    | Notes            |
| ---------------- | ------- | ---------------- |
| id               | UUID    | Primary Key      |
| recipe\_code     | Text    | Unique, required |
| name             | Text    | Required         |
| recipe\_category | Text    | Optional         |
| base\_yield\_qty | Numeric | Required         |
| base\_yield\_uom | Text    | Required         |
| price            | Numeric | Optional         |
| status           | Text    | Active/Inactive  |

---

## 🧪 Validation Rules

* Ingredient and Recipe codes must be unique
* Yield % must be between 1–100 (accepts 0.83 and converts to 83)
* Required fields enforced in both form and CSV import
* Ingredient import checks for:

  * Duplicate codes with source vs DB comparison
  * Missing or invalid fields
  * Rows failing validation get saved to CSV with `errors` column

---

## 🧼 UX Considerations

* Ingredient/Recipe forms provide helpful validation errors
* Missing fields are clearly called out
* Rejected CSV rows provide a downloadable file for correction
* Cancel button clears form state
* Delete sets status to `Inactive`, not hard delete
* AgGrid used for all major tables for filtering/sorting

---

## 🚧 Future Considerations (Post-MVP)

* Add Client layer for multi-client data management
* Enable recipe-to-ingredient nesting (multi-level BOMs)
* Versioning for ingredient packaging changes
* Rework UOM tables for tiered packaging and tracking
* Proper reference table for Recipe Categories
* Add unit tests and staging pipeline
