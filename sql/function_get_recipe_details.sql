
select
    i.name as ingredient,
    rl.qty,
    rl.qty_uom,
    i.ingredient_type,
    i.package_qty,
    i.package_uom,
    i.package_cost,
    i.yield_pct,
    case
        when i.package_qty > 0 and i.yield_pct > 0
        then (rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
        else 0
    end as line_cost
from recipe_lines rl
join ingredients i on rl.ingredient_id = i.id
where rl.recipe_id = rid
