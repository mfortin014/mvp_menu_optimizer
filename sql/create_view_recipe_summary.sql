create view public.recipe_summary as
select
  r.id as recipe_id,
  r.name as recipe,
  r.price,
  COALESCE(sum(rlc.line_cost), 0::numeric) as cost,
  r.price - COALESCE(sum(rlc.line_cost), 0::numeric) as margin_dollar,
  case
    when r.price > 0::numeric then (
      r.price - COALESCE(sum(rlc.line_cost), 0::numeric)
    ) / r.price
    else 0::numeric
  end as profitability,
  COALESCE(s.total_units_sold, 0::numeric) as popularity
from
  recipes r
  left join recipe_line_costs rlc on rlc.recipe_id = r.id
  left join (
    select
      sales.recipe_id,
      sum(sales.qty) as total_units_sold
    from
      sales
    group by
      sales.recipe_id
  ) s on s.recipe_id = r.id
group by
  r.id,
  r.name,
  r.price,
  s.total_units_sold;