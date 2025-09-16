
# Identity_MVP — Ingredient Identity & Deterministic Dedupe (Spec)
**Version:** 1.0  \n**Updated:** 2025-09-16 05:02  \n**Applies to:** Streamlit MVP (no FIRE), Supabase Postgres  \n**Owner:** Identity_MVP

---

## 1) Purpose & Scope (MVP)
We establish **tenant-safe, deterministic identity** for ingredients and a minimal **rule-based dedupe** process. This creates a stable spine for UOM, costing (SCD-lite), ingestion, and later v1 services.

**In scope (MVP)**
- Canonical ingredient key and normalization rules.
- Tenant isolation and **soft delete** invariants.
- Alias mapping for vendor codes/legacy codes/GTIN (exact match only; normalized).
- Deterministic dedupe policy (exact/normalized rules; no fuzzy matching).
- Manual merge/split with lineage logging (SQL-level stubs).
- Views that enforce soft-delete + tenant scoping for all reads.

**Out of scope (v1+)**
- Probabilistic/ML matching, confidence scores, review UI.
- Global external registries, supplier sync adapters.
- Cross-domain identity stitching.

---

## 2) Design Principles
- **Identity != label.** The identity key is never derived from the display name or translations.
- **Determinism over cleverness.** MVP uses exact/normalized rules only.
- **Tenant first.** Every unique constraint and query is tenant-scoped.
- **Soft delete everywhere.** Deletion never reuses identities; unique indexes exclude soft-deleted rows.
- **Idempotency friendly.** Writes accept idempotency keys (owned by Chronicle/Intake specs; honored here).

---

## 3) Data Model (DDL)
> Notes: We use UUID primary keys for internal joins, with a **tenant-scoped unique** on the canonical `ingredient_code` while `deleted_at is null`. Codes and aliases are stored **normalized** per rules below.

```sql
-- Core table
create table if not exists public.ingredients (
  ingredient_id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  ingredient_code text not null,        -- canonical code (normalized)
  -- labels live in Lexicon_MVP; optional minimal label for MVP UIs (may be removed later)
  name text,                            -- (optional, non-unique, not identity)
  -- base_unit is owned by Measure_MVP (declared here to avoid later migration churn)
  base_unit text check (base_unit in ('g','ml','unit')),
  created_at timestamptz not null default now(),
  created_by text,
  updated_at timestamptz not null default now(),
  updated_by text,
  deleted_at timestamptz
);

-- Tenant-scoped uniqueness while active
create unique index if not exists ux_ingredients_code_active
  on public.ingredients (tenant_id, ingredient_code)
  where deleted_at is null;

create index if not exists ix_ingredients_tenant_active
  on public.ingredients (tenant_id)
  where deleted_at is null;

-- Aliases table: vendor codes, GTIN, legacy codes, etc.
create table if not exists public.ingredient_aliases (
  alias_id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  ingredient_id uuid not null references public.ingredients(ingredient_id) on delete cascade,
  alias_type text not null check (alias_type in ('vendor_code','gtin','legacy_code','external_sku')),
  alias_value text not null,    -- stored normalized
  source text,                  -- optional: 'import:vendorX', 'manual', etc.
  created_at timestamptz not null default now(),
  created_by text
);

-- No duplicate alias for a tenant
create unique index if not exists ux_alias_unique
  on public.ingredient_aliases (tenant_id, alias_type, alias_value);

create index if not exists ix_alias_tenant_type
  on public.ingredient_aliases (tenant_id, alias_type);

-- Merge lineage (manual merges in MVP)
create table if not exists public.ingredient_merges (
  merge_id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  from_ingredient_id uuid not null references public.ingredients(ingredient_id),
  to_ingredient_id   uuid not null references public.ingredients(ingredient_id),
  merged_at timestamptz not null default now(),
  merged_by text,
  reason text
);
```

### 3.1 Normalization helpers (Postgres)
```sql
-- Normalize a code or alias: trim, collapse spaces to single, remove leading zeros around delimiters,
-- upper-case, strip non [A-Z0-9._-], and collapse multiple delimiters.
create or replace function public.normalize_code(p text)
returns text language sql immutable as $$
  select
    regexp_replace(
      regexp_replace(
        upper(trim(p)),
        '\s+', ' ', 'g'
      ),
      '[^A-Z0-9._-]', '', 'g'
    )
$$;

-- Optional: guarantee canonical storage via generated column (if preferred)
-- alter table public.ingredients add column ingredient_code_norm text generated always as (public.normalize_code(ingredient_code)) stored;
```

---

## 4) Identity & Dedupe Rules (MVP)
1. **Canonical identity:** `(tenant_id, ingredient_code_normalized)` is the identity.  
2. **Aliases:** For lookups, we resolve in this order (exact, normalized):  
   a) `ingredient_code` → match; b) `alias_value` (any alias_type) → match; otherwise not found.  
3. **No name-based identity.** Names/labels never participate in identity.
4. **Dedupe process (manual):**
   - Identify duplicates via queries (see §10).
   - Choose a **survivor** ingredient; move all aliases from duplicates to survivor; log `ingredient_merges`.
   - Soft-delete the duplicate records (`deleted_at = now()`).
5. **No auto-merge.** MVP does not merge without an explicit human choice.
6. **Idempotency:** If a create/upsert arrives with an idempotency key already used for the same `(tenant_id, normalized_code)`, the op is **no-op**.

---

## 5) Views & Query Invariants
All reads go through tenant-scoped, soft-delete-filtered views.

```sql
create or replace view public.v_ingredients_active as
select i.*
from public.ingredients i
where i.deleted_at is null;

create or replace view public.v_ingredient_aliases as
select a.*
from public.ingredient_aliases a;  -- aliases are never soft-deleted in MVP; delete means row removal

-- Helper: resolve by code or alias (normalized)
create or replace function public.find_ingredient_id(p_tenant text, p_code_or_alias text)
returns uuid language plpgsql stable as $$
declare
  norm text := public.normalize_code(p_code_or_alias);
  iid uuid;
begin
  select ingredient_id into iid
  from public.ingredients
  where tenant_id = p_tenant and deleted_at is null and ingredient_code = norm;

  if iid is not null then return iid; end if;

  select a.ingredient_id into iid
  from public.ingredient_aliases a
  join public.ingredients i on i.ingredient_id = a.ingredient_id and i.deleted_at is null
  where a.tenant_id = p_tenant and a.alias_value = norm
  limit 1;

  return iid;
end$$;
```

---

## 6) RLS & Soft Delete (policy sketch)
> If RLS is enabled now, apply. If not, keep the patterns (queries and unique indexes already assume tenant scoping).

- Policy target: `public.ingredients`, `public.ingredient_aliases`, `public.ingredient_merges`  
- Session variable: `app.tenant_id` (set at connection).

```sql
-- Example (enable RLS and allow tenant rows only)
alter table public.ingredients enable row level security;
create policy p_ingr_tenant on public.ingredients
  using (tenant_id = current_setting('app.tenant_id', true));

alter table public.ingredient_aliases enable row level security;
create policy p_alias_tenant on public.ingredient_aliases
  using (tenant_id = current_setting('app.tenant_id', true));
```

**Soft delete invariant:** all list/detail queries use `deleted_at is null`. Partial unique index enforces uniqueness only for active rows.

---

## 7) API/Function Shapes (MVP; FIRE-compatible)
Even without FIRE, we align function signatures with future APLs.

- **Upsert ingredient** (local function in MVP):
```python
def ingredient_upsert(*, tenant_id: str, ingredient_code: str, name: str|None=None,
                      base_unit: str|None=None, idempotency_key: str|None=None) -> dict:
    """
    - normalize code; if exists (active): update name/base_unit; else insert.
    - reject if soft-deleted duplicate exists (require manual undelete/merge).
    - return ingredient_id, normalized_code, timestamps.
    """
```
- **Add alias**
```python
def ingredient_alias_add(*, tenant_id: str, ingredient_id: str, alias_type: str, alias_value: str) -> dict:
    """Normalize and insert alias; unique per (tenant, type, value)."""
```
- **Merge ingredients** (manual, admin only)
```python
def ingredient_merge(*, tenant_id: str, from_id: str, to_id: str, reason: str|None=None) -> dict:
    """
    Move aliases; log ingredient_merges; set deleted_at on from_id; return survivor.
    """
```

---

## 8) Events (integration points)
MVP **does not** introduce new public events beyond the shared triad; however, these identity actions **should** emit internal events to `event_log` for traceability:

- On `ingredient_upsert` (new row): emit `ingredient.created` (source=`mvp`, low priority). *(Optional; can be skipped for scope control.)*
- On `ingredient_merge`: emit `ingredient.merged` with `from_id`, `to_id`. *(Optional, recommended if merges are used.)*

> The canonical shared events remain: `ingredient.cost.updated`, `import.completed`, `recipe.recomputed` (owned by Chronicle/Intake specs).

---

## 9) Migration Plan
1. Create new tables and indexes (safe to run repeatedly).
2. Backfill `ingredients.tenant_id` (if missing) and normalize existing `ingredient_code` values via `normalize_code`.
3. Identify duplicates post-normalization per tenant; produce a merge sheet for manual decisions.
4. Apply merges; move legacy external codes into `ingredient_aliases` with `alias_type='legacy_code'`.
5. Update app code to read from `v_ingredients_active` and lookups via `find_ingredient_id`.
6. Turn on partial unique index; address violations.

---

## 10) QA & Test Plan
- **Unit tests (Python):** code normalization, upsert semantics, alias add, merge behavior.
- **SQL tests:** uniqueness under soft delete; `find_ingredient_id` returns correct IDs for codes and aliases.
- **Manual scripts:** duplicate detection (post-normalization):
```sql
-- Find normalized duplicates by tenant
select tenant_id, ingredient_code, count(*) as cnt
from public.ingredients
where deleted_at is null
group by 1,2 having count(*) > 1;
```
- **RLS smoke:** when enabled, set `app.tenant_id` and verify cross-tenant reads fail.

---

## 11) Acceptance Gates (MVP)
- Deterministic identity: `(tenant_id, normalized ingredient_code)` unique while active.
- All reads via tenant-scoped views; soft-deleted rows never appear on lists.
- Alias lookups resolve deterministically; no name-based identity.
- Manual merge process tested end-to-end; lineage logged.
- No duplicate aliases per tenant/type/value.
- Migration completed on seed data without data loss.

---

## 12) Future Hooks (v1)
- Plug-in fuzzy matchers (blocking list to avoid false merges).
- Supplier adapters that populate aliases automatically.
- Lineage viewer (UI) and merge-undo tooling.
- Move optional events (`ingredient.created/merged`) to formal event catalog.
