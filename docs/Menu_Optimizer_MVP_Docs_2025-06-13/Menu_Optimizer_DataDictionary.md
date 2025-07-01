# 📘 Menu Optimizer – Data Dictionary

This data dictionary defines all the core tables and columns used in the Menu Optimizer MVP. All names reflect the current Supabase schema and Streamlit implementation as of June 2025.

---

## 🧾 Table: `ingredients`

| Column           | Type        | Description                                                  |
| ---------------- | ----------- | ------------------------------------------------------------ |
| id               | UUID        | Primary key                                                  |
| ingredient\_code | text        | Unique code, must be distinct across ingredients             |
| name             | text        | Display name of the ingredient                               |
| ingredient\_type | text        | Optional, either 'Bought' or 'Prepped'                       |
| package\_qty     | numeric     | Quantity per purchase unit                                   |
| package\_uom     | text        | UOM for purchase (can be free text)                          |
| package\_cost    | numeric     | Cost of one package unit                                     |
| yield\_pct       | numeric     | Yield in percent (0–100). Converted from decimals if needed. |
| category\_id     | UUID        | Foreign key to `ref_ingredient_categories`                   |
| status           | text        | Status ('Active', 'Inactive')                                |
| created\_at      | timestamptz | Timestamp of creation                                        |
| updated\_at      | timestamptz | Auto-updated via trigger                                     |

## 🧾 Table: `recipes`

| Column           | Type        | Description                                                   |
| ---------------- | ----------- | ------------------------------------------------------------- |
| id               | UUID        | Primary key                                                   |
| recipe\_code     | text        | Unique code                                                   |
| name             | text        | Display name                                                  |
| recipe\_category | text        | Optional freeform category                                    |
| base\_yield\_qty | numeric     | Number of portions or units this recipe yields                |
| base\_yield\_uom | text        | UOM for yield (can be free text, disconnected from UOM table) |
| price            | numeric     | Selling price |
| status           | text        | 'Active' or 'Inactive' |
| is_menu_item     | boolean     | True if recipe is sold directly |
| is_ingredient    | boolean     | True if recipe can be used in another recipe |
| updated_at       | timestamptz | Auto-updated via trigger |

## 🧾 Table: `ref_ingredient_categories`

| Column | Type | Description            |
| ------ | ---- | ---------------------- |
| id     | UUID | Primary key            |
| name   | text | Category name          |
| status | text | 'Active' or 'Inactive' |

## 🧾 Table: `ref_uom_conversion`

| Column    | Type    | Description                                |
| --------- | ------- | ------------------------------------------ |
| from\_uom | text    | Source unit of measure                     |
| to\_uom   | text    | Target unit of measure                     |
| factor    | numeric | Multiplier to convert from\_uom to to\_uom |

⚠️ Used only for ingredient UOM conversion. Recipes use free text for `base_yield_uom`.

## 🧾 Table: `ingredients_recipes_link` (Planned for post-MVP)

This table will define line-level links between ingredients and recipes for BOM costing.

| Column         | Type    | Description                               |
| -------------- | ------- | ----------------------------------------- |
| recipe\_id     | UUID    | Foreign key to recipes                    |
| ingredient\_id | UUID    | Foreign key to ingredients                |
| qty            | numeric | Quantity of ingredient used               |
| uom            | text    | UOM of the ingredient in this recipe line |

---

✅ Updated: June 12, 2025
