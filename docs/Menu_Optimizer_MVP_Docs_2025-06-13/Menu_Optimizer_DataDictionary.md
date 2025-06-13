# 📚 Data Dictionary – Menu Optimizer MVP

## 📦 `ingredients`
| Column           | Type     | Description                              |
|------------------|----------|------------------------------------------|
| ingredient_code  | text     | Unique identifier                        |
| name             | text     | Ingredient name                          |
| ingredient_type  | text     | "Bought" or "Prepped"                    |
| package_qty      | numeric  | Purchase unit quantity                   |
| package_uom      | text     | Purchase unit of measure (freeform)      |
| package_cost     | numeric  | Cost for full purchase unit              |
| yield_pct        | numeric  | Yield percentage (0–100)                 |
| status           | text     | "Active", "Inactive"                     |
| category_id      | uuid     | FK to `ref_ingredient_categories`        |

## 📘 `recipes`
| Column           | Type     | Description                              |
|------------------|----------|------------------------------------------|
| recipe_code      | text     | Unique identifier                        |
| name             | text     | Recipe name                              |
| recipe_category  | text     | Optional category                        |
| base_yield_qty   | numeric  | Number of units produced                 |
| base_yield_uom   | text     | Unit of measure (freeform for MVP)       |
| price            | numeric  | Selling price                            |
| status           | text     | "Active", "Inactive"                     |

## 🧾 `ref_ingredient_categories`
| Column  | Type | Description          |
|---------|------|----------------------|
| id      | uuid | Primary key          |
| name    | text | Category name        |
| status  | text | "Active", "Inactive" |

## ⚖️ `ref_uom_conversion`
| Column     | Type    | Description                    |
|------------|---------|--------------------------------|
| from_uom   | text    | Source unit of measure         |
| to_uom     | text    | Target unit of measure         |
| factor     | numeric | Conversion multiplier          |
| status     | text    | "Active", "Inactive"           |