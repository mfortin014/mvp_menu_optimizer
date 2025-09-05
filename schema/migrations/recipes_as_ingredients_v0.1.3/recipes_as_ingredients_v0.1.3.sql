-- =========================================
-- 🧹 Step 1: Drop outdated views and columns
-- =========================================

DROP VIEW IF EXISTS recipe_line_costs;
DROP VIEW IF EXISTS prep_costs;
DROP VIEW IF EXISTS recipe_summary;
DROP VIEW IF EXISTS recipe_as_ingredient_cost;
DROP VIEW IF EXISTS prep_recipe_cost_summary;

ALTER TABLE recipes
  DROP COLUMN IF EXISTS is_service_recipe,
  DROP COLUMN IF EXISTS is_ingredient_recipe;

ALTER TABLE recipes
  RENAME COLUMN base_yield_qty TO yield_qty,
  RENAME COLUMN base_yield_uom TO yield_uom;

ALTER TABLE recipes
  ADD COLUMN recipe_type TEXT NOT NULL DEFAULT 'service' CHECK (recipe_type IN ('service', 'prep'));

-- =========================================
-- 📦 Step 2: Recreate recipe_line_costs (prep_costs dependency deactivated)
-- =========================================

CREATE VIEW public.recipe_line_costs AS
SELECT
  rl.id AS recipe_line_id,
  rl.recipe_id,
  rl.ingredient_id,
  rl.qty,
  rl.qty_uom,
  i.package_qty,
  i.package_uom,
  i.package_cost,
  i.ingredient_type,
  i.yield_pct,
  CASE
    -- Use ingredient cost
    WHEN i.id IS NOT NULL AND i.package_qty > 0 AND (rl.qty_uom = i.package_uom OR c.factor IS NOT NULL) THEN
      CASE
        WHEN rl.qty_uom = i.package_uom THEN rl.qty / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
        ELSE rl.qty * c.factor / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
      END

    -- Use prep recipe cost
    --WHEN pc.unit_cost IS NOT NULL THEN rl.qty * pc.unit_cost

    ELSE 0::numeric
  END AS line_cost
FROM
  recipe_lines rl
  LEFT JOIN ingredients i ON i.id = rl.ingredient_id
  LEFT JOIN ref_uom_conversion c ON rl.qty_uom = c.from_uom AND i.package_uom = c.to_uom
 -- LEFT JOIN prep_costs pc ON pc.recipe_id = rl.ingredient_id;



-- =========================================
-- 💸 Step 3: Create prep_costs view (depends on recipe_line_costs)
-- =========================================

CREATE VIEW public.prep_costs AS
SELECT
  r.id AS recipe_id,
  r.recipe_code,
  r.name,
  r.yield_qty,
  r.yield_uom,
  SUM(rlc.line_cost) AS total_cost,
  c.factor AS conversion_factor,
  r.yield_qty * c.factor AS yield_qty_in_base_unit,
  CASE
    WHEN (r.yield_qty * c.factor) > 0 THEN SUM(rlc.line_cost) / (r.yield_qty * c.factor)
    ELSE NULL
  END AS unit_cost,
  c.to_uom AS base_uom
FROM
  recipes r
  LEFT JOIN recipe_line_costs rlc ON r.id = rlc.recipe_id
  LEFT JOIN ref_uom_conversion c ON r.yield_uom = c.from_uom
WHERE
  r.recipe_type = 'prep'
  AND r.status = 'Active'
GROUP BY
  r.id, r.recipe_code, r.name, r.yield_qty, r.yield_uom, c.factor, c.to_uom;


-- =========================================
-- 📊 Step 4: Recreate recipe_summary (service recipes only)
-- =========================================

CREATE VIEW public.recipe_summary AS
SELECT
  r.id AS recipe_id,
  r.recipe_code,
  r.name,
  r.status,
  r.price,
  SUM(rlc.line_cost) AS total_cost,
  CASE
    WHEN r.price > 0 THEN ROUND(SUM(rlc.line_cost) / r.price * 100, 2)
    ELSE NULL
  END AS cost_pct,
  CASE
    WHEN r.price > 0 THEN ROUND(r.price - SUM(rlc.line_cost), 2)
    ELSE NULL
  END AS margin
FROM
  recipes r
  LEFT JOIN recipe_line_costs rlc ON r.id = rlc.recipe_id
WHERE
  r.status = 'Active'
  AND r.recipe_type = 'service'
GROUP BY
  r.id, r.recipe_code, r.name, r.status, r.price;

-- =========================================
-- 📊 Step 5: Modify recipe_line_costs (to activate prep_costs dependency)
-- =========================================

CREATE OR REPLACE VIEW public.recipe_line_costs AS
SELECT
  rl.id AS recipe_line_id,
  rl.recipe_id,
  rl.ingredient_id,
  rl.qty,
  rl.qty_uom,
  i.package_qty,
  i.package_uom,
  i.package_cost,
  i.ingredient_type,
  i.yield_pct,
  CASE
    -- Use ingredient cost (with or without conversion)
    WHEN i.package_qty > 0::numeric
      AND (
        rl.qty_uom = i.package_uom
        OR c.factor IS NOT NULL
      ) THEN CASE
        WHEN rl.qty_uom = i.package_uom THEN rl.qty / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
        ELSE rl.qty * c.factor / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
      END

    -- Use prep recipe cost
    WHEN pc.unit_cost IS NOT NULL THEN rl.qty * pc.unit_cost

    ELSE 0::numeric
  END AS line_cost
FROM
  recipe_lines rl
  LEFT JOIN ingredients i ON i.id = rl.ingredient_id
  LEFT JOIN ref_uom_conversion c ON rl.qty_uom = c.from_uom AND i.package_uom = c.to_uom
  LEFT JOIN prep_costs pc ON pc.recipe_id = rl.ingredient_id;
