<!--
seed-uid: SEC-001
parent_uid: SEC-000
title: Flip cost/reporting views to SECURITY INVOKER
type: Chore
area: db
priority: P0
status: Todo
project: main
-->
## Done when
- [ ] recipe_line_costs, recipe_summary, missing_uom_conversions, ingredient_costs use (security_invoker = true)
- [ ] If present: input_catalog, recipe_line_costs_base, prep_costs also flipped
- [ ] Governance: all future CREATE VIEW include WITH (security_invoker=true)
## Migrations
- [ ] V012__views_security_invoker.sql committed and applied
