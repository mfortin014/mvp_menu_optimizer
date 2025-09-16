# Slowly Chaning Dimensions (SCD)

You don’t need a full-blown enterprise data warehouse to get the benefits of SCDs. Here’s a lean, Postgres-native pattern that:
- versions only what matters (Type 2),
- is multi-tenant safe,
- keeps “current” queries dead simple,
- and ports cleanly to Supabase RPC and later React.

## What to version (Type 2)
Start with the few fields where “as of date” really matters:
- **Ingredients**: unit_cost (derived but snapshot-worthy), supplier_price, package_size, base_unit, active
- **Prep recipes**: yield (qty+uom), loss %, active
- **Menu items**: sell_price, portion_size
- **Item-specific conversions**: factor, bidirectional (densities change!)
- **All name/label fields** if you want historical labeling for invoices/exports

Everything else: use a cheap audit log (who/when/what) without version joins.

## Shape of a versioned table (Type 2)
Use a “current table” + “history table”. The current table holds only the present row; history stores the past, with validity periods.

#### ingredients (current)
- `id` (UUID PK), `tenant_id`
- business keys (code/name), current attributes (unit_cost, base_unit, etc.)
- `version` (int, starts at 1)
- `valid_from` timestamptz, `valid_to` NULL (current)
- `is_current` bool default true

#### ingredients_hist (history)
- same columns as current
- `valid_to` NOT NULL
- `is_current` always false
- `exclusion constraint` to prevent overlapping periods per `(tenant_id, id)`.

>Why keep valid_from/valid_to on current too? Because “as-of” union queries become trivial and consistent.

### PostgreSQL DDL pattern (copy/paste-able)
```
-- 1) History table
create table if not exists ingredients_hist (
  id uuid not null,
  tenant_id uuid not null,
  code text not null,
  name text not null,
  base_unit text not null,         -- g/ml/unit
  supplier_price numeric(12,6),
  unit_cost numeric(12,6),
  version int not null,
  valid_from timestamptz not null,
  valid_to   timestamptz not null, -- closed interval end
  is_current boolean not null default false,
  primary key (id, valid_from),
  -- no overlaps per item within a tenant
  exclude using gist (
    tenant_id with =,
    id with =,
    tstzrange(valid_from, valid_to, '[]') with &&
  )
);

-- 2) Current table (your existing one; add versioning cols)
alter table ingredients
  add column if not exists version int not null default 1,
  add column if not exists valid_from timestamptz not null default now(),
  add column if not exists valid_to timestamptz,
  add column if not exists is_current boolean not null default true;

-- RLS mirror later as you already do (tenant_id filters).

-- 3) Trigger to write history on change (Type 2)
create or replace function scd2_ingredients_before_update()
returns trigger language plpgsql as $$
begin
  -- If nothing relevant changed, do nothing.
  if row(NEW.supplier_price, NEW.unit_cost, NEW.base_unit, NEW.name, NEW.code, NEW.is_current)
     is not distinct from
     row(OLD.supplier_price, OLD.unit_cost, OLD.base_unit, OLD.name, OLD.code, OLD.is_current)
  then
    return NEW;
  end if;

  -- Close the old version into history
  insert into ingredients_hist
    (id, tenant_id, code, name, base_unit, supplier_price, unit_cost,
     version, valid_from, valid_to, is_current)
  values
    (OLD.id, OLD.tenant_id, OLD.code, OLD.name, OLD.base_unit, OLD.supplier_price, OLD.unit_cost,
     OLD.version, OLD.valid_from, now(), false);

  -- Bump version, start new validity window
  NEW.version := OLD.version + 1;
  NEW.valid_from := now();
  NEW.valid_to := null;
  NEW.is_current := true;

  return NEW;
end;
$$;

drop trigger if exists trg_scd2_ingredients on ingredients;
create trigger trg_scd2_ingredients
before update on ingredients
for each row
when (OLD.* is distinct from NEW.*)
execute function scd2_ingredients_before_update();

-- 4) Helper “as of” view for easy querying
create or replace view ingredients_asof as
select * from ingredients
union all
select * from ingredients_hist;
```
>Repeat this pattern for prep_recipes, menu_items, and item_uom_conv (rename to item_uom_conv_hist for the history). You can extract a generic trigger by passing table/columns via generated SQL, but for MVP clarity, keep one function per table.

### How to use it
#### Current value (unchanged):
```
select * from ingredients where tenant_id = $1 and id = $2;
```

#### As-of any date:
```
-- get the row that was valid at '2025-08-01 12:00:00+00'
select *
from ingredients_asof
where tenant_id = $1
  and id = $2
  and coalesce(valid_to, 'infinity') >= $3
  and valid_from <= $3
order by valid_from desc
limit 1;

```

#### Point-in-time costing (critical later):
- When you create a menu price, order, or estimate, store as_of_ts and the IDs. When rendering, query …_asof with that timestamp so numbers always reconcile.

### Keep it fast & safe
- Indexes:
  - ingredients(tenant_id, id) already PK.
  - ingredients_hist(tenant_id, id, valid_from desc) for as-of seeks.
- RLS: same policies on ingredients_hist as ingredients.
- No overlaps: the gist + tstzrange exclusion constraint already ensures clean histories.

### Streamlit polish (minimal)
- On detail pages, add a small “History” expander:
  - Table with `version`, `valid_from` → `valid_to`, and the changed fields highlighted.
- In editors, show “Last changed (field): timestamp by user”. You can inject `updated_by` via app-side.

### Costs are derived — snapshot or not?
- Derived costs (e.g., unit_cost via your views) still deserve a snapshot at the moment you need auditability (menu price lock, order creation). Two common patterns:
  - Store `extended_cost` numbers directly on the fact row (simple, immutable).
  - Store only `as_of_ts`, then resolve via `…_asof` on read (more flexible, mildly more compute).

For MVP, (1) on facts + SCD2 on inputs is the sweet spot.

### Don’t version everything (on purpose)
- Use SCD2 where consumers need “what was true then”.
- Use a generic `audit_log` for the rest:
  - (`tenant_id`, `table_name`, `row_id`, `action`, `changed_cols` `jsonb`, `at`, `by`)
  - Show it in an expander for nerds like us; don’t burden the main UX.

### Naming & reuse (React migration-friendly)
- Suffix history tables with _hist.
- Columns: `version`, `valid_from`, `valid_to`, `is_current`, `updated_by` (nullable for service jobs).
- Provide two RPCs per entity: `get_current(id)` and `get_asof(id, ts)` — your React app can call these 1:1 later.

### Quick checklist to implement next
- [ ] Add SCD2 scaffolding to: `ingredients`, `prep_recipes`, `menu_items`, `item_uom_conv`.
- [ ] Clone the trigger function per table (change column lists accordingly).
- [ ] Build `…_asof` views.
- [ ] Add `History` expander in Streamlit (read-only).
- [ ] For any price lock or order flow you add: snapshot extended costs on write.