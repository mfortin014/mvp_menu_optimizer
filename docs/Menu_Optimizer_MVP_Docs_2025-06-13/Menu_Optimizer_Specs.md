# 📐 Menu Optimizer – Functional Specifications (MVP)

## 👨‍🍳 Target User
Chef or consultant managing restaurant menus with a need to track ingredients, recipes, and optimize profit.

## 🎯 Core Functionalities
### Ingredients
- Add, update, and deactivate
- Viewable in sortable/filterable table
- Export and import via CSV
- Enforced unique codes

### Recipes
- Add, update, deactivate
- Flexible yield definition
- Support for freeform categories and UOMs

### Reference Data
- Edit UOM conversions, categories, and statuses inline
- Reuse across objects

## 📁 CSV Import Requirements
- Ingredient import fully validated
- Row-level error detection
- Supports partial loads with rejected row file

## 🧮 Data Validations
- `ingredient_code` and `recipe_code` must be unique
- `yield_pct` is normalized from 0–1 to 0–100
- Missing or invalid fields prompt in-app rejection

## 📈 Analytics & Planning (Future)
- Menu performance matrix (popularity x profitability)
- Cost breakdown per recipe
- Suggested optimizations