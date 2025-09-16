# Ingredients Identity
Here’s a cohesive, migration-friendly design that adds:
- multi-code identity for ingredients (without widening rows),
- ingredient variants (price/packaging/supplier differences),
- true recipe versions (draft/compare/activate),
- and clean interplay with your SCD2 + UOM system.

I’m keeping everything Supabase-friendly, RLS-safe, and React-ready.

### 1. Identity layer: internal codes + external identifiers
**Internal codes (auto-generated, short, distinct per entity)**
- Use one PG sequence per entity and a tiny insert trigger.
- Format suggestion: ING-000123, PRP-000045, REC-000789. Not information-dense; just recognizable by eye.

```
-- sequences
create sequence if not exists seq_ing_code;
create sequence if not exists seq_prep_code;
create sequence if not exists seq_rec_code;

-- example: ingredients
alter table ingredients
  add column if not exists code text unique;

create or replace function set_ing_code()
returns trigger language plpgsql as $$
begin
  if new.code is null or new.code = '' then
    new.code := 'ING-' || lpad(nextval('seq_ing_code')::text, 6, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_ing_code on ingredients;
create trigger trg_set_ing_code
before insert on ingredients
for each row execute function set_ing_code();
```

Repeat for prep_recipes (PRP) and recipes (REC).


#### External identifiers (supplier SKU, producer, distributor, client code…)
- Don’t add columns to ingredients. Model them as item-scoped identifiers.
- Optional linkage to a party (supplier/producer/distributor/client). This gives you dedup, search, and history.

```
-- who issued the code
create table if not exists party (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  name text not null,
  kind text not null check (kind in ('supplier','producer','distributor','client','other')),
  active boolean not null default true
);

-- normalized identifiers
create table if not exists item_identifier (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  entity text not null check (entity in ('ingredient','ingredient_variant','recipe','prep_recipe')),
  entity_id uuid not null,                 -- points to the row in that entity
  identifier_type text not null,           -- 'supplier_sku','producer_code','distributor_code','client_code','barcode','legacy'
  value text not null,
  party_id uuid,                           -- optional: who owns this code
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  is_current boolean not null default true
);

-- no duplicates for current rows
create unique index if not exists uq_item_identifier_current
  on item_identifier(tenant_id, entity, entity_id, identifier_type, coalesce(party_id, '00000000-0000-0000-0000-000000000000'::uuid), value)
  where is_current = true;

```

> Want SCD2-style history here? You’ve already got valid_from/valid_to/is_current. Flip is_current and set valid_to when replacing a code; keep queries simple with … where is_current.

### 2. Ingredient variants (same ingredient, different attributes)

Conceptual split:
- ingredients = family (how the kitchen uses it conceptually; base unit, name, default behavior).
- ingredient_variant = procurement/packaging choice (supplier, brand, package size, cost, lead time…).

Tie your costing to variants, but let recipes refer to families and map (per recipe version) to a chosen variant when needed.

```
create table if not exists ingredient_variant (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  ingredient_id uuid not null references ingredients(id),
  name text,                               -- optional label/brand
  supplier_id uuid references party(id),
  distributor_id uuid references party(id),
  package_qty numeric(14,6) not null default 1.0,
  package_uom uuid not null references ref_uom(id),   -- g/ml/unit
  package_cost numeric(14,6) not null,                -- cost per package
  loss_pct numeric(6,3) not null default 0.0,         -- trim/waste for this variant
  moq integer, lead_time_days integer,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- SCD2 for variant economics (when prices/packaging change)
create table if not exists ingredient_variant_hist (
  id uuid not null, tenant_id uuid not null,
  ingredient_id uuid not null,
  supplier_id uuid, distributor_id uuid,
  package_qty numeric(14,6) not null,
  package_uom uuid not null,
  package_cost numeric(14,6) not null,
  loss_pct numeric(6,3) not null,
  moq integer, lead_time_days integer,
  version int not null,
  valid_from timestamptz not null,
  valid_to timestamptz not null,
  is_current boolean not null default false,
  primary key (id, valid_from)
);

```

**Unit cost (derived)**
- Keep your existing ingredient_costs view, but compute via variant economics:
  - Convert package_qty → ingredient base_unit (via item_uom_conv, now extended to variants—see below).
  - Apply loss_pct.
  - unit_cost = package_cost / net_qty_in_base_unit.

**UOM conversions with variants**
- Extend your item_uom_conv(scope, item_id, …) to allow scope in ('ingredient','ingredient_variant','recipe').
- Resolution order when converting a line qty:
  1. ingredient_variant mapping (most specific),
  2. ingredient mapping,
  3. global same-dimension map.

### 3. Recipe versions (draft/compare/activate)

Treat recipes as the business object and store lines on versions. Exactly one active version per recipe; any number of drafts.

#### Data model
##### Recipe (family)
Stable identity & routing only:
- recipes(id, tenant_id, code, name, category_id, active, owner_client_id, created_by, created_at)
- No price, no yield, no portion here. Keep this clean.

##### Recipe version (header that can change)
```
create table if not exists recipe_version (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_id uuid not null references recipes(id),
  number int not null,                              -- 1,2,3… per recipe
  sell_price numeric(12,2),
  portion_qty numeric(12,6), portion_uom uuid,
  target_cost_pct numeric(5,2),
  service_time_min int,
  -- plu text, menu_section text, diet_tags text -- optional
  label text,                                       -- "Summer tweak A"
  status text not null check (status in ('draft','active','archived')),
  based_on_version_id uuid,                         -- fork lineage (optional)
  notes text,
  frozen_at timestamptz,                            -- when activated (snapshot moment)
  created_by uuid, created_at timestamptz not null default now()
);

-- enforce one active
create unique index if not exists uq_recipe_version_one_active
  on recipe_version(recipe_id)
  where status = 'active';

-- lines attach to version
create table if not exists recipe_line (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  sort_order int not null,
  -- choose exactly one of the two:
  ingredient_id uuid references ingredients(id),
  ingredient_variant_id uuid references ingredient_variant(id),
  -- or a prep recipe (as an ingredient); initially resolve to its active version:
  prep_recipe_id uuid references recipes(id),
  qty numeric(14,6) not null,
  uom uuid not null references ref_uom(id),
  notes text
  -- (db constraint to ensure either ingredient[_variant] XOR prep is set)
);

-- prep yields MUST be versioned too
create table if not exists recipe_version_yield (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  qty numeric(14,6) not null,
  uom uuid not null references ref_uom(id),
  alt_qty numeric(14,6),
  alt_uom uuid references ref_uom(id),
  source text not null check (source in ('declared','measured')),
  is_current boolean not null default true
);
```

#### Version yield (dual UOM ready)
- recipe_version_yield(id, tenant_id, recipe_version_id, qty, uom, alt_qty, alt_uom, source, is_current)

##### Version lines
- recipe_line(id, tenant_id, recipe_version_id, sort_order, ingredient_id, ingredient_variant_id, prep_recipe_id, qty, uom, notes)
- Your circular-dep guard and UOM checks run here.
##### Snapshots (on activation)
- recipe_version_cost_snapshot(recipe_version_id, total_cost, cost_per_yield, margin_at_activation, computed_at)
- recipe_version_line_snapshot(recipe_version_id, recipe_line_id, resolved_variant_id, qty_in_base, unit_cost_at_activation, line_cost_at_activation)

>This lets you compare any draft to the active version, with both header deltas (price/portion/etc.) and composition deltas (lines/costs).

#### Typical flows
##### Create a draft
1. insert recipe_version (recipe_id, number=next, status='draft', …header fields…)
2. copy lines from current active → new draft
3. copy current yield (so UOM math stays sane)
4. Chef tweaks header (price/portion/goals) and lines independently

##### Compare to active
- Compute draft cost using current variant economics (or as-of a chosen date).
- Compare to active using the active’s snapshot for “what guests are paying now”.
- Show:
  - Total cost Δ, cost% Δ, margin Δ (header price included)
  - Biggest line movers (by extended cost)
  - Portion normalization (e.g., “per 250 g” vs header portion)

##### Activate a version
- Enforce one active per recipe.
- Set frozen_at=now().
- Compute and write snapshots (header + per line).
- Flip previous active to archived.

#### Minimal DDL sketch (names are illustrative)
```
-- family
create table recipes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  code text unique,
  name text not null,
  category_id uuid,
  owner_client_id uuid,
  active boolean not null default true,
  created_by uuid,
  created_at timestamptz not null default now()
);

-- versions (header lives here)
create table recipe_version (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_id uuid not null references recipes(id),
  number int not null,
  label text,
  status text not null check (status in ('draft','active','archived')),
  based_on_version_id uuid references recipe_version(id),
  notes text,
  frozen_at timestamptz,

  -- header fields that can change per version
  sell_price numeric(12,2),
  portion_qty numeric(14,6),
  portion_uom uuid references ref_uom(id),
  target_cost_pct numeric(5,2),
  service_time_min int,
  plu text,
  menu_section text,
  diet_tags text[],

  created_by uuid,
  created_at timestamptz not null default now()
);

create unique index uq_one_active_per_recipe
  on recipe_version(recipe_id)
  where status = 'active';

-- per-version yield (dual)
create table recipe_version_yield (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  qty numeric(14,6) not null,
  uom uuid not null references ref_uom(id),
  alt_qty numeric(14,6),
  alt_uom uuid references ref_uom(id),
  source text not null check (source in ('declared','measured')),
  is_current boolean not null default true
);

-- version lines
create table recipe_line (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  sort_order int not null,
  ingredient_id uuid references ingredients(id),
  ingredient_variant_id uuid references ingredient_variant(id),
  prep_recipe_id uuid references recipes(id),
  qty numeric(14,6) not null,
  uom uuid not null references ref_uom(id),
  notes text
);

-- snapshots (optional now, required on activation)
create table recipe_version_cost_snapshot (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  total_cost numeric(14,6) not null,
  cost_per_yield numeric(14,6) not null,
  margin_at_activation numeric(14,6),
  computed_at timestamptz not null default now()
);

create table recipe_version_line_snapshot (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  recipe_line_id uuid not null,
  resolved_variant_id uuid,
  qty_in_base numeric(14,6) not null,
  unit_cost_at_activation numeric(14,6) not null,
  line_cost_at_activation numeric(14,6) not null
);

```



**Variant binding per version**
- Let lines point directly to a variant when Chef wants to lock a specific vendor/pack.
- Otherwise, allow ingredient_id and resolve to the ingredient’s preferred variant (per tenant) at costing time.
- Add an optional table to set a preferred variant globally or per recipe:

```
create table if not exists ingredient_preference (
  tenant_id uuid not null,
  ingredient_id uuid not null,
  preferred_variant_id uuid not null references ingredient_variant(id),
  scope text not null check (scope in ('tenant','recipe_version')), -- global default or per recipe version
  recipe_version_id uuid,
  primary key (tenant_id, ingredient_id, scope, coalesce(recipe_version_id, '00000000-0000-0000-0000-000000000000'::uuid))
);
```

**Activation + snapshot**
- On status → 'active', set frozen_at = now() and snapshot economics so comparisons are reproducible even if vendors change tomorrow.

```
create table if not exists recipe_version_cost_snapshot (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  total_cost numeric(14,6) not null,
  cost_per_yield numeric(14,6) not null,
  margin_at_activation numeric(14,6),
  computed_at timestamptz not null default now()
);

create table if not exists recipe_version_line_snapshot (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_version_id uuid not null references recipe_version(id) on delete cascade,
  recipe_line_id uuid not null,
  resolved_variant_id uuid,               -- which variant was used (if any)
  qty_in_base numeric(14,6) not null,     -- after conversion
  unit_cost_at_activation numeric(14,6) not null,
  line_cost_at_activation numeric(14,6) not null
);

```

**Compare versions**
- A view that computes deltas vs the active version:
  - per-line and total cost difference,
  - effect on cost %, margin $, margin %,
  - optionally tag which differences are due to composition vs price drift (use snapshots + SCD2 as-of).

### 4. Costing + conversions across all of this
- Keep your single source of truth conversion functions:
  - can_convert_qty(tenant_id, scope, item_id, from_uom, to_uom)
  - convert_qty(tenant_id, scope, item_id, qty, from_uom, to_uom)
- Extend scope to include 'ingredient_variant'.
- Resolution order (most specific → least): variant → ingredient → global.
- For version costing:
  - Resolve each line’s effective variant (direct or preferred).
  - Convert qty to the ingredient family’s base_unit.
  - Pull SCD2 as-of economics (frozen_at if active w/ snapshots; otherwise “now” for drafts).
  - Roll up to recipe_version_cost_summary.

Costing logic (where the math happens)

For drafts: price from recipe_version.sell_price; yield from recipe_version_yield; lines from recipe_line; economics from current variant/ingredient SCD as-of “now”, unless Chef chooses a “what-if as-of date”.

For active: use the snapshot (frozen numbers) for all operational outputs (training sheets, prep lists, forecasts), so reports reconcile even if vendor prices change tomorrow.

Your existing UOM engine plugs in cleanly:

Convert each line to the ingredient family’s base_unit via resolution order: variant → ingredient → global.

Roll up extended costs → total_cost.

Compute cost_per_yield using version yield; then cost_pct = total_cost / sell_price.

Streamlit UX tweaks

Recipe header shows the active version badge and header fields (price, portion, tags).

“Fork from active” creates a draft copying header + yield + lines.

“Compare to active” panel shows header deltas (price/portion/targets) and composition deltas.

“Activate” runs validation (no cycles, yields present), computes snapshots, enforces single active.

Migration notes

Keep your current recipes as the family; add recipe_version and migrate everything into version #1 (active).

Move any header-ish fields currently on recipes (price, portion, etc.) to recipe_version.

Update foreign keys where needed (e.g., editor loads by active version id rather than recipe id).

Why this works

Version = unit of change: header + lines evolve together, so comparisons and activations are coherent.

Family stays stable: codes, naming, ownership, and permissions live at the family level (easier RLS).

Auditable: snapshots + SCD inputs give you point-in-time truth; drafts use “today math” for what-ifs.

Migration-ready: the same tables slot cleanly into Supabase + React; Streamlit just gives us the initial flows.

### 5. RLS + indices you’ll feel
- Every new table gets tenant_id and mirrors your existing policies.
- Hot indices:
  - ingredient_variant(tenant_id, ingredient_id, active)
  - recipe_version(tenant_id, recipe_id, status)
  - recipe_line(recipe_version_id, sort_order)
  - ingredient_preference(tenant_id, ingredient_id, scope, recipe_version_id)
  - item_identifier(tenant_id, entity, entity_id, is_current)
  - For SCD2 tables: (tenant_id, id, valid_from desc)

### 6. Streamlit UX (fast > fancy, but sharp)
- Ingredient detail
  - Header: internal code; quick copy buttons.
  - Tabs: “Variants”, “Identifiers”, “Conversions”, “History”.
  - Variants tab lists cards with supplier, pkg, unit cost; inline toggle for preferred default.
  - Identifiers tab lists current codes by type/party; add/retire dialog (sets valid_to + new current).
- Recipe editor
  - Draft vs Active badge; button to “Fork from active” → creates a new version populated with current lines.
  - Each line:
    - show base unit + cost anchor (from family),
    - if using a variant, show chip for supplier/brand and unit cost;
    - dropdown to pin a different variant (writes ingredient_variant_id); or switch back to family (uses preference).
  - Compare button side-by-side with active: total cost, cost %, margin $/% deltas; highlight biggest movers.
  - Activate button → runs snapshot, enforces one active, sets frozen_at.
- Guardrails
  - Prevent circular deps using your existing cycle check, but now per recipe_version.
  - On add line, preflight can_convert (with variant/ingredient scope). Prompt to add item-specific conversion if needed (the dialog you already planned).

### 7. Migration plan (safe increments)

1. Identity
   - Add sequences + insert triggers for internal codes.
   - Create party + item_identifier and wire simple UI.
2. Variants (phase 1)
   - Create ingredient_variant + ingredient_variant_hist.
   - Materialize ingredient_variant_costs view.
   - For now, set one variant per ingredient by script; keep recipes referencing families.
3. Recipe versions (phase 1)
   - Add recipe_version, recipe_line(→ version), recipe_version_yield.
   - Migrate current recipes to version #1 (active).
   - Compute cost summary view for versions.
4.  Variants (phase 2)
    - Allow lines to pin a variant; add ingredient_preference for defaults.
    - Update line editor UX.
5.  Snapshots + compare
    - Add snapshot tables and activation workflow.
    - Add “Compare to Active” panel.

Everything above plays nicely with your SCD2 approach and the item-scoped UOM model you’re implementing. You can ship step 1–3 as MVP and add 4–5 without refactors.