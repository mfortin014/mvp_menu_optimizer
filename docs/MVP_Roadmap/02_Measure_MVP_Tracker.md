
# Measure_MVP — Implementation Tracker
**Version:** 1.0  \n**Updated:** 2025-09-16 17:39  \n**Owner:** Measure_MVP  \n**Status:** Draft

---

## Scope (MVP)
Item-scoped conversions, base units, and normalized cost math.

## Out of Scope (v1+)
Conversion history (SCD), density-based conversions, multi-language UOM labels.

---

## Schema & Indexes
- [ ] Create `ref_uom` table; seed canonical UOMs.
- [ ] Add `base_unit` to `ingredients`; backfill defaults.
- [ ] Create `ingredient_conversions` table.

## App Functions
- [ ] Implement `normalize_qty(ingredient_id, qty, from_uom)`.
- [ ] Implement `compute_extended_cost(ingredient_id, qty, from_uom, at)`.

## Streamlit Wiring
- [ ] Ingredient editor: require base_unit on create.
- [ ] Ingredient editor: allow adding conversions.
- [ ] Recipe editor: call normalize_qty/compute_extended_cost when displaying costs.

## Integration
- [ ] Wire `recipe_cost_as_of` (Chronicle_MVP) to call compute_extended_cost.
- [ ] Ensure unit_cost from Chronicle is always per base_unit.

## QA / Tests
- [ ] Unit: normalize_qty for standard (kg→g, l→ml).
- [ ] Unit: normalize_qty for custom (bunch parsley→g).
- [ ] Integration: recipe_cost_as_of returns same total regardless of recipe UOM.
- [ ] SQL: ensure every ingredient has base_unit.

## Acceptance Gate
- [ ] All active ingredients have base_unit.  
- [ ] All active recipes have valid conversions.  
- [ ] Costs are computed deterministically in base units.  
- [ ] Tests pass; editor enforces base_unit + conversions.
