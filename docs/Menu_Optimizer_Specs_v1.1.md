
# Menu Optimizer – Specifications v1.1

_Last updated: 2025-06-06_

## Overview
This document outlines the updated specifications for the Menu Optimizer MVP, reflecting changes and additions since version 1.0. It includes technical details, new modules, database adjustments, and user-facing features developed during the recent sprint.

## 1. Core Modules

### 1.1 Recipe Management
- View recipe list, margins, popularity
- Detailed breakdown: ingredients, cost, sales, margin per line
- Uses `get_recipe_details` RPC for performance

### 1.2 Ingredients Management
- Full CRUD
- Side panel form with category, yield %, type
- Linked to `ref_ingredient_categories`
- Uses `data_editor` table with checkbox to load ingredient in form
- Delete sets status = Inactive (not hard delete)

### 1.3 MPM Quadrant Classification
- Quadrants calculated in SQL view and used in graph and data table
- Names:
  - Popular & Profitable → Keep
  - Popular & Not Profitable → Reduce cost
  - Not Popular & Profitable → Boost appeal
  - Not Popular & Not Profitable → Drop

## 2. Technical Changes

### 2.1 Schema Changes
- `ingredients.yield_qty` dropped
- `ingredients.yield_pct` (numeric) added
- `ingredients.category_id` added with FK to `ref_ingredient_categories(id)`
- `ingredient_code` added as required field

### 2.2 Views Updated
- `recipe_line_costs` and `recipe_summary` updated to use yield_pct logic
- Cost logic:
  ```sql
  adjusted_qty = rl.qty / (i.yield_pct / 100.0)
  ```

### 2.3 Supabase RPC
- Updated `get_recipe_details` RPC for corrected cost breakdown

### 2.4 App Architecture
- Refactored `utils.supabase.py` for global client creation
- Removed duplication with `data.py`
- All database calls now route through centralized supabase instance

## 3. Remaining Work

### 3.1 Bug Fixes & UX Polishing
- **Radio-style row selection** in ingredient editor is inconsistent
- Form should reactively bind to the selected row in a smoother UX

### 3.2 Ingredient Category Management
- No interface yet for managing categories (CRUD)

### 3.3 Recipe Editing & Creation
- Not implemented yet

### 3.4 Sales Upload Interface
- Manual input or import from CSV not yet implemented

## 4. Notes for Handoff
- All changes are committed locally and tracked in `Menu_Optimizer_Changelog_v1.1.md`
- Working directory is `.venv` Python environment
- Supabase connection relies on `.env` or Streamlit secrets
- Documented architecture and schema in `Menu_Optimizer_DevPlan_v1.1.md`

---

_Handed off from dev session on June 6, 2025_
