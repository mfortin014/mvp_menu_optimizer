create view public.missing_uom_conversions as
select
  rl.id as recipe_line_id,
  r.name as recipe,
  i.name as ingredient,
  rl.qty_uom,
  i.package_uom
from
  recipe_lines rl
  join recipes r on r.id = rl.recipe_id
  join ingredients i on i.id = rl.ingredient_id
  left join ref_uom_conversion c on rl.qty_uom = c.from_uom
  and i.package_uom = c.to_uom
where
  c.factor is null;