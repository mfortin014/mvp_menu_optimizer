create view public.recipe_line_costs as
select
  rl.id as recipe_line_id,
  rl.recipe_id,
  rl.ingredient_id,
  rl.qty,
  rl.qty_uom,
  i.package_qty,
  i.package_uom,
  i.package_cost,
  i.ingredient_type,
  i.yield_pct,
  case
    when i.package_qty > 0::numeric
    and (
      rl.qty_uom = i.package_uom
      or c.factor is not null
    ) then case
      when rl.qty_uom = i.package_uom then rl.qty / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
      else rl.qty * c.factor / (i.yield_pct / 100.0) * (i.package_cost / i.package_qty)
    end
    else 0::numeric
  end as line_cost
from
  recipe_lines rl
  left join ingredients i on i.id = rl.ingredient_id
  left join ref_uom_conversion c on rl.qty_uom = c.from_uom
  and i.package_uom = c.to_uom;