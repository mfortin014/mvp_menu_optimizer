
# Chronicle_MVP — Time-Scoped Costs & Recipe Versions (Spec)
**Version:** 1.0  
**Updated:** 2025-09-16 16:40  
**Applies to:** Streamlit MVP (no FIRE), Supabase Postgres  
**Owner:** Chronicle_MVP

---

## 1) Purpose & Scope (MVP)
Track **ingredient cost history** and **recipe composition & price history** using lean SCD-2 (slowly changing dimension type 2) so we can:
- Recompute **current** recipe cost deterministically.
- Answer **as-of** questions: “What was margin on 2025-03-03?”
- Emit canonical events for parity with v1.

**In scope (MVP)**
- SCD-lite tables: `ingredient_costs`, `recipe_versions` (+ `recipe_line_versions`), `recipe_price_history`.
- **Draft vs Published** versions: one draft max; published versions are immutable and time-boxed.
- Functions (local, FIRE-compatible shapes): publish, recompute now, cost as-of.
- Events: `ingredient.cost.updated`, `recipe.versioned`, `recipe.recomputed`.
- Idempotency keys on cost updates and publish.

**Out of scope (v1+)**
- Bitemporal corrections (valid vs system time), backdating UI, audit catalog, async recompute queues.

---

## 2) Design Principles
- **Version at the header**: lines are a snapshot under a version; their lifetime is the version’s window.
- **Publish creates history**: drafts are mutable; publishing stamps an effective window and freezes the snapshot.
- **Half-open windows**: `[effective_from, effective_to)]; current rows have `effective_to = NULL, is_current = true`.
- **Idempotent writes**: repeated idempotency key → no-op.
- **Deterministic math**: rely on Measure_MVP conversions; no implicit UOM tricks.

---

## 3) Data Model (DDL)

### 3.1 Ingredient cost SCD-lite
```sql
create table if not exists public.ingredient_costs (
  ingredient_id uuid not null references public.ingredients(ingredient_id) on delete cascade,
  tenant_id text not null,
  effective_from timestamptz not null,
  effective_to   timestamptz,
  is_current     boolean not null default true,
  unit_cost numeric(14,6) not null, -- cost per ingredient.base_unit (Measure_MVP)
  currency text not null default 'CAD',
  idempotency_key text,             -- to dedupe cost updates
  created_at timestamptz not null default now(),
  created_by text,
  constraint pk_ing_cost primary key (ingredient_id, effective_from)
);

create unique index if not exists ux_ing_cost_current
  on public.ingredient_costs (ingredient_id)
  where is_current = true;

create index if not exists ix_ing_cost_tenant_time
  on public.ingredient_costs (tenant_id, ingredient_id, effective_from);
```

**Upsert rule (SCD-2):**
- If new `unit_cost` equals current: **no-op** (but may set idempotency_key).
- Else: set current row `is_current=false, effective_to=now()`; insert new row with `effective_from=now(), is_current=true`.

---

### 3.2 Recipe versions (draft & published) + lines
```sql
create table if not exists public.recipe_versions (
  recipe_version_id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null,            -- your base recipes table PK
  tenant_id text not null,
  is_published boolean not null default false,
  effective_from timestamptz,         -- set on publish
  effective_to   timestamptz,         -- closed on next publish
  is_current     boolean not null default false, -- true for the one current published row
  yield_qty numeric(12,4) not null default 1,
  yield_uom text not null,            -- 'g' | 'ml' | 'unit' (Measure_MVP)
  notes text,
  publish_idempotency_key text,       -- to dedupe accidental double publish
  created_at timestamptz not null default now(),
  created_by text,
  updated_at timestamptz not null default now(),
  updated_by text
);

-- one current published per recipe
create unique index if not exists ux_recipe_current
  on public.recipe_versions (recipe_id)
  where is_published = true and is_current = true and effective_to is null;

-- at most one draft per recipe
create unique index if not exists ux_recipe_draft
  on public.recipe_versions (recipe_id)
  where is_published = false;

create unique index if not exists ux_recipe_publish_idem
  on public.recipe_versions (recipe_id, publish_idempotency_key)
  where is_published = true;

create table if not exists public.recipe_line_versions (
  recipe_version_id uuid not null references public.recipe_versions(recipe_version_id) on delete cascade,
  line_no int not null,
  ingredient_id uuid not null references public.ingredients(ingredient_id),
  qty numeric(14,6) not null,
  uom text not null,                  -- unit at entry time; convert via Measure_MVP at compute
  waste_pct numeric(6,3) not null default 0,
  primary key (recipe_version_id, line_no)
);
```

**Semantics**
- Draft = `is_published=false` (mutable lines).  
- Publish: set `effective_from=now(), is_published=true, is_current=true`; close previous published (`effective_to=now(), is_current=false`).

---

### 3.3 Recipe price history (SCD-lite)
```sql
create table if not exists public.recipe_price_history (
  recipe_id uuid not null,
  tenant_id text not null,
  effective_from timestamptz not null,
  effective_to   timestamptz,
  is_current     boolean not null default true,
  price numeric(12,2) not null,
  currency text not null default 'CAD',
  created_at timestamptz not null default now(),
  created_by text,
  constraint pk_recipe_price primary key (recipe_id, effective_from)
);

create unique index if not exists ux_recipe_price_current
  on public.recipe_price_history (recipe_id)
  where is_current = true;
```

---

## 4) Functions (local now, FIRE-compatible later)

### 4.1 Cost update (SCD-2 upsert)
```python
def ingredient_cost_upsert(*, tenant_id: str, ingredient_id: str, unit_cost: float,
                           currency: str = "CAD", idempotency_key: str | None = None) -> dict:
    """SCD-2 upsert cost; emit ingredient.cost.updated on change."""
```

### 4.2 Get or create draft
```python
def recipe_get_or_create_draft(*, tenant_id: str, recipe_id: str, actor: str) -> dict:
    """Return draft version_id; clone from current published if none."""
```

### 4.3 Publish draft → new version
```python
def recipe_publish_version(*, tenant_id: str, recipe_id: str, publish_idempotency_key: str | None,
                           actor: str) -> dict:
    """Atomically close previous published, publish draft, recompute, emit events."""
```

### 4.4 Recompute now (current)
```python
def recipe_recompute_now(*, tenant_id: str, recipe_id: str) -> dict:
    """Use current published version + current ingredient costs; emit recipe.recomputed."""
```

### 4.5 Cost as-of timestamp
```python
from datetime import datetime as dt
def recipe_cost_as_of(*, tenant_id: str, recipe_id: str, at: dt) -> dict:
    """Pick the published version window at 'at'; join ingredient costs and price effective at 'at'."""
```

**Return shapes (success)**
```json
{ "ok": true, "data": { "total_cost": 12.3456, "price": 18.00, "margin_pct": 31.3 } }
```
Errors use the standard shape:
```json
{ "error": { "code": "NOT_FOUND|INVALID_PAYLOAD|CONFLICT", "message": "...", "details": {} } }
```

---

## 5) As-of selection (reference SQL)

### 5.1 Pick published version at timestamp
```sql
select rv.recipe_version_id
from public.recipe_versions rv
where rv.recipe_id = $1
  and rv.is_published = true
  and rv.effective_from <= $2
  and coalesce(rv.effective_to, 'infinity') > $2
order by rv.effective_from desc
limit 1;
```

### 5.2 Join lines + ingredient costs + price
Pseudo-SQL for computation:
```sql
with v as (
  select rv.recipe_version_id, rv.yield_qty, rv.yield_uom
  from public.recipe_versions rv
  where rv.recipe_id = $1 and rv.is_published = true
    and rv.effective_from <= $2 and coalesce(rv.effective_to,'infinity') > $2
),
lines as (
  select rl.recipe_version_id, rl.line_no, rl.ingredient_id, rl.qty, rl.uom, rl.waste_pct
  from public.recipe_line_versions rl join v using (recipe_version_id)
),
costs as (
  select ic.ingredient_id, ic.unit_cost
  from public.ingredient_costs ic
  where ic.effective_from <= $2 and coalesce(ic.effective_to,'infinity') > $2
),
price as (
  select rph.price
  from public.recipe_price_history rph
  where rph.recipe_id = $1
    and rph.effective_from <= $2 and coalesce(rph.effective_to,'infinity') > $2
)
-- app layer converts qty/uom -> ingredient base_unit via Measure_MVP, applies waste, sums * unit_cost
```

---

## 6) Events (emit to `event_log`)

- **`ingredient.cost.updated`** — after cost SCD upsert changes current.  
  Payload: `{ "ingredient_id":"…","unit_cost":…,"effective_from":"…" }`

- **`recipe.versioned`** — after publish.  
  Payload: `{ "recipe_id":"…","version_id":"…","effective_from":"…" }`

- **`recipe.recomputed`** — after recompute.  
  Payload: `{ "recipe_id":"…","total_cost":…,"price":…,"margin_pct":… }`

Use `correlation_id` to tie recomputes to publishes/imports, and `idempotency_key` where provided.

---

## 7) Idempotency rules
- **ingredient_cost_upsert**: if `idempotency_key` matches latest row for `(tenant_id, ingredient_id)`, **no-op**.  
- **recipe_publish_version**: enforce once-only publish per idempotency key:
```sql
create unique index if not exists ux_recipe_publish_idem
on public.recipe_versions (recipe_id, publish_idempotency_key)
where is_published = true;
```

---

## 8) Migration Plan
1. Create the three tablesets and indexes.  
2. Backfill: for each existing recipe, create **one** published `recipe_version` from current rows and copy its lines.  
3. Backfill: set an initial price row per recipe in `recipe_price_history`.  
4. Ensure all existing ingredient costs are inserted as one `ingredient_costs` current row per ingredient (using Identity_MVP to resolve IDs).  
5. Update app:
   - Editor uses **draft** row (auto-created) and publishes on Save.
   - Cost changes flow through `ingredient_cost_upsert()`.
   - Recompute button calls `recipe_recompute_now()` and emits event.

---

## 9) QA & Test Plan
- **Unit tests (Python):**
  - Cost upsert SCD transitions (open/close windows, no-op on same value).
  - Draft reuse and publish atomics (previous closed, new current opened).
  - As-of math against crafted timelines (cost change before & after version publish).

- **SQL assertions:**
  - `ux_recipe_current` invariant holds (0/1 current).
  - `ux_recipe_draft` invariant holds (0/1 draft).
  - Ingredient cost current unique holds.

- **Event sanity:** expected events appear with correlation IDs and reasonable payloads.

---

## 10) Acceptance Gates (MVP)
- Editing a published recipe and saving **creates exactly one new published version** and closes the previous one.
- As-of computation returns deterministic totals that match “now” when `at=now()`.
- Cost updates open/close windows correctly; recomputes emit events.
- No more than one current published version per recipe; at most one draft per recipe.
- Idempotency protects against double-publish and duplicate cost updates.

---

## 11) Future Hooks (v1)
- Backdating UI (set `effective_from` manually), bitemporal corrections.
- Async recompute & replay from event log.
- Move functions to FIRE APLs (`recipe.publish`, `recipe.cost.as_of`, `ingredient.cost.upsert`) with audit trails.
