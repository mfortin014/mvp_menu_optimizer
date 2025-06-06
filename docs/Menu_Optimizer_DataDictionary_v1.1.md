# Menu Optimizer – Data Dictionary (v1.1)

## 🔗 Supabase Tables

---

### 🍴 `recipes`

| Column           | Type     | Description                         |
|------------------|----------|-------------------------------------|
| id               | UUID     | Primary key                         |
| name             | text     | Recipe name                         |
| recipe_code      | text     | Short internal code                 |
| price            | numeric  | Selling price                       |
| base_yield_qty   | numeric  | Quantity yielded by base recipe     |
| base_yield_uom   | text     | Unit of measure for yield           |
| status           | text     | 'Active' or 'Inactive'              |

---

### 🧂 `ingredients`

| Column           | Type     | Description                                         |
|------------------|----------|-----------------------------------------------------|
| id               | UUID     | Primary key                                         |
| name             | text     | Ingredient name                                     |
| ingredient_code  | text     | Internal code (displayed in tables)                |
| ingredient_type  | text     | 'Bought' or 'Prepped'                               |
| package_qty      | numeric  | Quantity per package (e.g., 10 lbs)                 |
| package_uom      | text     | Unit of measure of the package                      |
| package_cost     | numeric  | Cost of full package                                |
| yield_pct        | numeric  | Percent yield after trimming/cooking/etc. (0-100)   |
| category_id      | UUID     | FK to `ref_ingredient_categories`                  |
| status           | text     | 'Active' or 'Inactive'                              |

---

### 🧾 `recipe_lines`

| Column         | Type     | Description                          |
|----------------|----------|--------------------------------------|
| id             | UUID     | Primary key                          |
| recipe_id      | UUID     | FK to `recipes`                      |
| ingredient_id  | UUID     | FK to `ingredients`                  |
| qty            | numeric  | Quantity used                        |
| qty_uom        | text     | UOM used (e.g., grams, tbsp)         |
| note           | text     | Optional note (prep instruction)     |

---

### 🏷️ `ref_ingredient_categories`

| Column | Type | Description          |
|--------|------|----------------------|
| id     | UUID | Primary key          |
| name   | text | Category name (e.g. Vegetables, Protein) |
| status | text | 'Active' or 'Inactive' |

---

### 📐 `ref_uom_conversion`

| Column   | Type    | Description                                |
|----------|---------|--------------------------------------------|
| from_uom | text    | Source unit (e.g. lb)                      |
| to_uom   | text    | Target unit (e.g. g)                       |
| factor   | numeric | Conversion factor                          |

---

## 📊 Views

### `recipe_line_costs`
Calculates line cost with yield-adjusted quantity:
```sql
adjusted_qty = rl.qty / (i.yield_pct / 100.0)
```

### `recipe_summary`
- Aggregates total cost per recipe
- Calculates:
  - Margin ($)
  - Margin (%)
  - Popularity (from sales)
  - Quadrant (MPM classification)

---

## 🧠 Notes

- Only soft deletes are used (`status = 'Inactive'`)
- Category is now shown via lookup (not stored as string)
- UOM conversions must be complete to calculate costs across different units