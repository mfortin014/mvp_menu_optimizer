# 📘 Feature Spec: Prep Recipes as Ingredients (v0.1.3)

## 🧩 Purpose

Enable **prep recipes** to be used as ingredients in other recipes, unlocking multi-level composition and true cost propagation (e.g., signature spice mix → spaghetti sauce → pasta dish).

---

## 📌 Versioning

* **Feature Release**: `v0.1.3`
* **Based On**: `v0.1.2`
* **Spec Updated**: July 2025

---

## ✅ Summary of Changes

### 1. Database – Schema Changes

Add a new field to `recipes`:

```sql
ALTER TABLE recipes
ADD COLUMN recipe_type TEXT NOT NULL CHECK (recipe_type IN ('service', 'prep'));
```

Only one type is allowed per recipe. We'll use a dropdown in the UI for now but consider normalizing later via a `ref_recipe_type` table.

---

### 2. UI – Recipe Editor Form

* Add a new dropdown labeled `Recipe Type`
* Options:

  * `service` → sold to customers (e.g. Burrito), this is the default value.
  * `prep` → used as an ingredient in other recipes (e.g. Guacamole)
* Make this field **required**
* Tooltip:

  > “Prep recipes are used as ingredients in other recipes. Service recipes are sold to customers.”

---

### 3. UX – Adding Ingredients to a Recipe

Update the recipe line ingredient selector to:

* List **Ingredients** where `status = 'Active'`
* List **Recipes** where `status = 'Active'` AND `recipe_type = 'prep'`
* Format label as: `name – code` (e.g., `Sauce Tartare – PREP0001`)
* Sorted alphabetically by name

---

### 4. Circular Dependency Protection

Enforce logic to **prevent recursive links**, e.g., A → B → A.

**At runtime (UI-side)**:

* When editing or creating a recipe, the ingredient selector **must exclude**:

  * The current recipe
  * Any recipe that (directly or indirectly) uses the current recipe as an ingredient

This avoids infinite costing loops and UX bugs.

---

### 5. Costing Logic – Fully Functional

Prep recipes added as ingredients must behave like normal ingredients.

Use a new cost view:

```sql
create view public.prep_costs as
select
  r.id as recipe_id,
  r.recipe_code,
  r.name,
  r.base_yield_qty,
  r.base_yield_uom,
  rs.total_cost,
  c.factor as conversion_factor,
  r.base_yield_qty * c.factor as yield_qty_in_base_unit,
  case
    when (r.base_yield_qty * c.factor) > 0::numeric then rs.total_cost / (r.base_yield_qty * c.factor)
    else null::numeric
  end as unit_cost,
  c.to_uom as base_uom
from
  recipes r
  inner join recipe_summary rs on rs.recipe_id = r.id
  left join ref_uom_conversion c on r.base_yield_uom = c.from_uom
where
  r.recipe_type = 'prep'
  and r.status = 'Active';
```

This parallels `ingredient_costs` and will be integrated into `recipe_line_costs` logic via left join on both views.

---

## 🧠 Architecture Decisions

* **Single-type enforcement**: A recipe can’t be both `prep` and `service`
* **No shadow ingredients**: Prep recipes are not duplicated in `ingredients`
* **Unit cost**: Always based on base yield (converted to base unit)

---

## 🔮 Future Extensions

* Normalize `recipe_type` via `ref_recipe_type`
* Add support for `retail`, `e-com`, etc.
* Abstract costing via unified `all_input_costs` view (ingredients + recipes)
* Add recursive costing view using SQL CTE (for full dependency tracing)
* UI toggles to show “where used” (reverse lookup for recipes)

---

## 📤 Deliverables

### 🔧 Migration & Schema Cleanup

* Drop obsolete view that depends on deprecated fields:

```sql
DROP VIEW IF EXISTS recipe_as_ingredient_cost;
```

```sql
ALTER TABLE recipes DROP COLUMN IF EXISTS is_service_recipe;
ALTER TABLE recipes DROP COLUMN IF EXISTS is_ingredient_recipe;
```

*

```sql
ALTER TABLE recipes RENAME COLUMN base_yield_qty TO yield_qty;
ALTER TABLE recipes RENAME COLUMN base_yield_uom TO yield_uom;
```

*

```sql
ALTER TABLE recipes
ADD COLUMN recipe_type TEXT NOT NULL CHECK (recipe_type IN ('service', 'prep'));
```

### 🧩 Logic & View Creation

*

```sql
CREATE VIEW public.prep_costs AS
SELECT
  r.id AS recipe_id,
  r.recipe_code,
  r.name,
  r.yield_qty,
  r.yield_uom,
  rs.total_cost,
  c.factor AS conversion_factor,
  r.yield_qty * c.factor AS yield_qty_in_base_unit,
  CASE
    WHEN (r.yield_qty * c.factor) > 0::numeric THEN rs.total_cost / (r.yield_qty * c.factor)
    ELSE NULL::numeric
  END AS unit_cost,
  c.to_uom AS base_uom
FROM
  recipes r
  INNER JOIN recipe_summary rs ON rs.recipe_id = r.id
  LEFT JOIN ref_uom_conversion c ON r.yield_uom = c.from_uom
WHERE
  r.recipe_type = 'prep'
  AND r.status = 'Active';
```

*

### 🖥️ Frontend

*

### 🗂️ Documentation

*

---

**Author:** ChatGPT (Dev Co-Pilot)
**Status:** Finalized, fully aligned with latest terminology and logic
