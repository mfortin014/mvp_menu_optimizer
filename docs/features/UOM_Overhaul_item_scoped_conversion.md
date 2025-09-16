# UOM Overhaul - Item Scoped Conversion

Treat “mass ↔ volume” (and any other oddball pairings) as item-scoped conversions, not columns on recipes or ingredients. Here’s a clean, migration-friendly design that gives Chef “declare both 10 L and 10.1 kg” now, and scales later.

## Data model (additive, not disruptive)

**1. Canonical UOMs and same-dimension conversions (global)**
- ref_uom(id, code, name, dimension) where dimension ∈ {mass, volume, unit}.
- ref_uom_conv_global(from_uom_id, to_uom_id, factor) for same-dimension scaling (kg→g, L→ml). One-way rows; use inverse via 1/factor.

**2. Item-scoped conversions (cross-dimension or overrides)**
- item_uom_conv(tenant_id, scope, item_id, from_uom_id, to_uom_id, factor, is_bidirectional, active, created_at)
  - scope enum: 'ingredient' | 'recipe' (prep recipes use recipe scope).
  - Use this for density (g↔ml) or any special override (e.g., “one egg ≈ 56 g”).
  - Partial unique index to prevent duplicates:
    - unique (tenant_id, scope, item_id, from_uom_id, to_uom_id) where active.

**3. Yield measurements (store Chef’s dual declarations)**
- recipe_yields(tenant_id, recipe_id, qty, uom_id, alt_qty, alt_uom_id, source, effective_at, active)
  - source enum: 'declared' | 'measured'.
  - For ingredients you can ignore; for prep recipes this is gold. Keep multiple rows over time; active marks the current one.

You keep ingredients.base_unit (g/ml/unit) as your costing anchor. No schema churn there.

## Server logic (portable to Supabase RPC later)

Conversion resolution in one place

Create two SQL functions (stable, pure):
```
-- Returns NULL if not convertible
create or replace function can_convert_qty(
  p_tenant uuid,
  p_scope text,           -- 'ingredient' or 'recipe'
  p_item_id uuid,         -- ingredient.id or recipe.id (when scope='recipe')
  p_from_uom uuid,
  p_to_uom uuid
) returns boolean language sql as $$
  with
  -- 1) trivial
  same as (
    select p_from_uom = p_to_uom as ok
  ),
  -- 2) global same-dimension path
  g as (
    select true as ok from ref_uom f
    join ref_uom t on t.id = p_to_uom
    where f.id = p_from_uom and f.dimension = t.dimension
  ),
  -- 3) item-scoped direct mapping (either direction if is_bidirectional)
  m as (
    select true as ok
    from item_uom_conv c
    where c.tenant_id = p_tenant and c.scope = p_scope and c.item_id = p_item_id and c.active
      and (
        (c.from_uom_id = p_from_uom and c.to_uom_id = p_to_uom)
        or (c.is_bidirectional and c.from_uom_id = p_to_uom and c.to_uom_id = p_from_uom)
      )
    limit 1
  )
  select coalesce((select ok from same), false)
      or coalesce((select ok from g), false)
      or coalesce((select ok from m), false);
$$;

-- Same search, but returns numeric factor (NULL if impossible).
-- Uses: 1) 1.0 for same UOM, 2) product of global factors, 3) item mapping (or inverse).
-- Keep it small at MVP: no graph search; direct/inverse only.
create or replace function convert_qty(
  p_tenant uuid,
  p_scope text,
  p_item_id uuid,
  p_qty numeric,
  p_from_uom uuid,
  p_to_uom uuid
) returns numeric language plpgsql as $$
declare
  v_factor numeric;
  v_same_dim boolean;
  v_bidirectional boolean;
begin
  if p_from_uom = p_to_uom then
    return p_qty;
  end if;

  -- Global same-dimension direct
  select (f.dimension = t.dimension) into v_same_dim
  from ref_uom f join ref_uom t on t.id = p_to_uom
  where f.id = p_from_uom;
  if v_same_dim then
    select cg.factor into v_factor
    from ref_uom_conv_global cg
    where cg.from_uom_id = p_from_uom and cg.to_uom_id = p_to_uom;
    if v_factor is not null then
      return p_qty * v_factor;
    end if;
  end if;

  -- Item mapping direct or inverse
  select c.factor, c.is_bidirectional into v_factor, v_bidirectional
  from item_uom_conv c
  where c.tenant_id = p_tenant and c.scope = p_scope and c.item_id = p_item_id and c.active
    and c.from_uom_id = p_from_uom and c.to_uom_id = p_to_uom
  limit 1;

  if v_factor is not null then
    return p_qty * v_factor;
  end if;

  if v_same_dim is distinct from true then
    -- Try inverse via item mapping if bidirectional
    select c.factor, c.is_bidirectional into v_factor, v_bidirectional
    from item_uom_conv c
    where c.tenant_id = p_tenant and c.scope = p_scope and c.item_id = p_item_id and c.active
      and c.from_uom_id = p_to_uom and c.to_uom_id = p_from_uom
    limit 1;
    if v_factor is not null and v_bidirectional then
      return p_qty / v_factor;
    end if;
  end if;

  return null;
end;
$$;
```

#### Enforce at the database edge (safe for Streamlit now, React later)

- Add a BEFORE INSERT OR UPDATE trigger on recipe_lines:
  - Determine line scope/item_id: if ingredient_id set → 'ingredient'; if prep_recipe_id set → 'recipe'.
  - Call can_convert_qty(...) with the chosen line UOM and the item’s base unit (your costing anchor). If false, RAISE EXCEPTION 'UOM_NOT_CONVERTIBLE: add an item-specific conversion first' USING ERRCODE = 'P0001';.

## UI behavior in Streamlit (no overbuilding, but crisp)

#### Show base unit & cost
- In the line editor row, render something like:
  “Base: $0.004 / g (g) · Yield: 1200 g (also 1100 ml)”
- That second piece comes from the current active row in recipe_yields.

#### Block impossible inserts with a helpful path
- On “Add line”, do an RPC (or SQL via Python client) to can_convert_qty(...).
- If False:
  - st.error("This UOM isn’t convertible for this item.")
  - st.button("Add a conversion") opens st.experimental_dialog (or an expander) with a tiny form:
    - From UOM, To UOM, Factor, Bidirectional ✅
    - Hidden fields: tenant_id, scope, item_id
  - On save → insert into item_uom_conv and st.rerun() the editor. Now the add passes.

Sketch (Python/Streamlit)
```
def can_convert(conn, tenant_id, scope, item_id, from_uom_id, to_uom_id):
    sql = "select can_convert_qty(%s,%s,%s,%s,%s)"
    return conn.execute(sql, (tenant_id, scope, item_id, from_uom_id, to_uom_id)).fetchone()[0]

# When user picks UOM and qty for a line:
if st.button("Add line"):
    scope, item_id = ("ingredient", sel_ingredient_id) if sel_ingredient_id else ("recipe", sel_prep_id)
    ok = can_convert(conn, tenant_id, scope, item_id, selected_uom_id, base_uom_id_for_item)
    if not ok:
        st.error("UOM not convertible for this item.")
        if st.button("Add a conversion"):
            with st.experimental_dialog("Add item-specific conversion"):
                from_uom = st.selectbox("From", uoms, index=... )
                to_uom   = st.selectbox("To", uoms, index=... )
                factor   = st.number_input("Factor (qty * factor)", min_value=0.000001, step=0.000001, format="%.6f")
                bidir    = st.checkbox("Bidirectional", value=True)
                if st.button("Save conversion"):
                    conn.execute("""
                      insert into item_uom_conv(tenant_id, scope, item_id, from_uom_id, to_uom_id, factor, is_bidirectional, active)
                      values (%s,%s,%s,%s,%s,%s,%s,true)
                      on conflict (tenant_id, scope, item_id, from_uom_id, to_uom_id)
                      where active
                      do update set factor=excluded.factor, is_bidirectional=excluded.is_bidirectional;
                    """, (tenant_id, scope, item_id, from_uom, to_uom, factor, bidir))
                    st.success("Conversion saved.")
                    st.rerun()
    else:
        # proceed to insert recipe line (server enforces again via trigger)
        insert_recipe_line(...)
```

#### Nice QoL touches
- Filter UOM dropdown by dimension that matches the item’s base unit first; then list cross-dimension ones under a divider (“Needs item conversion”).
- When the user selects a cross-dimension UOM, pre-check can_convert and gray out the “Add line” until a conversion exists—avoid round trips.

#### Costing stays simple (and correct)
- Your existing cost math keeps using the item’s base_unit (g/ml/unit).
- When the line UOM differs, convert the line qty to base using convert_qty(...) before calculating extended cost.
- For prep recipes, when showing a price per serving or per selected UOM, rely on the active recipe_yields row to provide you both the base yield and the alt yield so you can format “$ / 100 g” and “$ / 100 ml” side-by-side.

#### RLS & indices (don’t skip)
- Add tenant_id to item_uom_conv and recipe_yields; mirror your existing RLS patterns.
- Indices you’ll feel:
  - item_uom_conv(tenant_id, scope, item_id, from_uom_id, to_uom_id) where active
  - recipe_yields(tenant_id, recipe_id) where active

#### Why this structure works

- Separation of concerns: global table handles dimensional scales; item table handles densities and exceptions.
- No column bloat: new pairings are data, not schema.
- Forward-compatible: the same functions can be exposed as Supabase RPC for React; Streamlit’s dialog maps to a small React modal later.
- Safety first: DB trigger guarantees you can’t sneak in a non-convertible line even if the UI glitches.