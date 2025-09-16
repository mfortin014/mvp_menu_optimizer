
# Measure_MVP — Item-Scoped UOM & Cost Math (Spec)
**Version:** 1.0  \n**Updated:** 2025-09-16 17:39  \n**Applies to:** Streamlit MVP (no FIRE), Supabase Postgres  \n**Owner:** Measure_MVP

---

## 1) Purpose & Scope (MVP)
Normalize ingredient quantities and costs across arbitrary units of measure (UOM) so that:
- All costs are stored per **base unit** (`g`, `ml`, or `unit`).
- Recipes can reference ingredients in any UOM (kg, L, tsp, cases, etc.).
- Conversions are item-scoped: each ingredient may have different equivalences (e.g., “1 bunch parsley ≈ 30 g”).
- Downstream math (Chronicle_MVP cost recompute, margin calculations) is deterministic.

**In scope (MVP)**
- `ref_uom` lookup table (canonical list).
- `ingredient_conversions` table (item-scoped mappings).
- Base unit field in `ingredients` (Identity_MVP).
- Functions to normalize quantities & compute extended cost.
- Integration points with Chronicle_MVP recompute.

**Out of scope (v1+)**
- Complex equivalence trees (e.g., density-based conversions auto-derived).
- Multi-language UOM labels (Lexicon_MVP handles later).
- Yield-loss modeling (per step, not per ingredient).

---

## 2) Design Principles
- **Single base unit per ingredient** (declared at creation).  
- **All costs stored per base unit** (see Chronicle_MVP’s `ingredient_costs`).  
- **Conversions are scoped** to `(ingredient_id, from_uom → to_base_unit)`.  
- **No global assumptions** (1 cup sugar ≠ 1 cup flour).  
- **Deterministic math**: convert → normalize → multiply.

---

## 3) Data Model (DDL)

### 3.1 Reference UOMs
```sql
create table if not exists public.ref_uom (
  uom_code text primary key,     -- 'g','kg','ml','l','unit','bunch','case','tsp','tbsp'...
  category text not null,        -- 'mass','volume','count'
  description text
);
```

### 3.2 Ingredient base unit
Extend `ingredients` (Identity_MVP):
```sql
alter table public.ingredients
  add column if not exists base_unit text not null default 'g'
  references public.ref_uom(uom_code);
```

### 3.3 Ingredient-specific conversions
```sql
create table if not exists public.ingredient_conversions (
  ingredient_id uuid not null references public.ingredients(ingredient_id) on delete cascade,
  from_uom text not null references public.ref_uom(uom_code),
  factor numeric(14,6) not null,    -- multiply qty_in_from_uom * factor = qty_in_base_unit
  notes text,
  created_at timestamptz not null default now(),
  created_by text,
  primary key (ingredient_id, from_uom)
);
```

---

## 4) Functions (local now, FIRE-compatible later)

### 4.1 Normalize qty
```python
def normalize_qty(ingredient_id: str, qty: float, from_uom: str) -> float:
    """Convert qty from arbitrary UOM → base unit using ingredient_conversions."""
```

### 4.2 Compute extended cost
```python
def compute_extended_cost(ingredient_id: str, qty: float, from_uom: str, at: datetime) -> dict:
    """Normalize qty → base units; join Chronicle_MVP.ingredient_costs(as-of at);
    return {'normalized_qty':..., 'unit_cost':..., 'extended_cost':...}."""
```

---

## 5) Integration with Chronicle_MVP
- `recipe_cost_as_of` (Chronicle) calls `compute_extended_cost` for each line.
- Unit cost always comes from `ingredient_costs` (per base unit).  
- Measure_MVP handles only the normalization layer.

---

## 6) Events
No new events.  
Emit via Chronicle: `ingredient.cost.updated`, `recipe.recomputed`.  
Future v1: may add `ingredient.conversion.updated`.

---

## 7) Idempotency rules
- Conversions are updated in place (overwrite factor).  
- For auditability, v1 may promote conversions to SCD.

---

## 8) Migration Plan
1. Create `ref_uom`. Populate with canonical list (`g`,`kg`,`ml`,`l`,`unit`).  
2. Add `base_unit` to `ingredients`. Backfill defaults (`g`).  
3. Create `ingredient_conversions`.  
4. Populate minimal conversions (kg→g, l→ml).  
5. Update Streamlit ingredient editor: require base_unit on create; allow adding conversions.

---

## 9) QA & Test Plan
- **Unit tests**: normalize_qty works for standard and item-scoped conversions.  
- **Integration**: `recipe_cost_as_of` uses normalized_qty correctly.  
- **SQL assertions**: base_unit exists for all ingredients; no missing conversions for active recipes.

---

## 10) Acceptance Gates (MVP)
- Every ingredient has a `base_unit`.  
- Costs in `ingredient_costs` are per base_unit.  
- Conversions exist for all non-base-unit UOMs used in recipes.  
- `recipe_cost_as_of` returns correct totals regardless of recipe UOM.  
- Tests cover normalize & extended cost paths.

---

## 11) Future Hooks (v1)
- Add SCD-lite to conversions (track factor history).  
- Support density-based auto-conversions (ml↔g).  
- Multi-language UOM labels.  
- Integration with yield-loss per step.
