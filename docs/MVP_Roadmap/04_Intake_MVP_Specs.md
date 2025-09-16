
# Intake_MVP — CSV Upload, Validate, Quarantine, Commit (Spec)
**Version:** 1.0  \n**Updated:** 2025-09-16 17:47  \n**Applies to:** Streamlit MVP (no FIRE), Supabase Postgres  \n**Owner:** Intake_MVP

---

## 1) Purpose & Scope (MVP)
Provide a **safe CSV ingestion pipeline** that turns messy files into deterministic writes:
- Accept CSV uploads for **ingredients** and **ingredient costs** (minimum viable entities).
- Validate and **quarantine** bad rows with machine-readable error codes.
- Commit clean rows **idempotently** and emit `import.completed`.
- Keep the surface area small now, but mirror v1’s pipeline shape.

**In scope (MVP)**
- `import_batches`, `import_rows_quarantine`, `import_errors` tables.
- Minimal per-entity mappers: `ingredients`, `ingredient_costs`.
- Idempotency on batches; dedupe double-submits.
- Basic header mapping (rename columns); **per-tenant mapping profile** is **nice-to-have**.
- Streamlit flows: Upload -> Validate -> Review Quarantine -> Commit.

**Out of scope (v1+)**
- Multi-entity, multi-sheet workbook ingestion.
- Advanced transforms (units, densities) beyond Measure/Identity rules.
- Async workers, retries, S3 file vault, and full audit catalog.

---

## 2) Design Principles
- **Quarantine, don’t corrupt.** Nothing hits target tables until validation passes.
- **Idempotent commits.** Same `idempotency_key` = no-op.
- **Tenant-safe.** All rows are scoped to `tenant_id`; lookups honor Identity_MVP (normalized codes & aliases).
- **Small, composable mappers.** A mapper per import type; map -> validate -> normalize -> commit.

---

## 3) Data Model (DDL)

### 3.1 Batch & quarantine
```sql
create table if not exists public.import_batches (
  import_batch_id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  import_type text not null check (import_type in ('ingredients','ingredient_costs')),
  source_filename text,
  file_sha256 text,                       -- optional fingerprint for dedupe
  total_rows int default 0,
  valid_rows int default 0,
  invalid_rows int default 0,
  status text not null default 'received' -- received|validated|committed|failed|discarded
    check (status in ('received','validated','committed','failed','discarded')),
  idempotency_key text,                   -- unique per tenant (to dedupe double-commit attempts)
  created_at timestamptz not null default now(),
  created_by text,
  committed_at timestamptz,
  committed_by text
);

create unique index if not exists ux_import_idem
  on public.import_batches (tenant_id, idempotency_key)
  where idempotency_key is not null;

create table if not exists public.import_rows_quarantine (
  import_batch_id uuid not null references public.import_batches(import_batch_id) on delete cascade,
  row_number int not null,
  raw_row jsonb not null,                 -- as parsed from CSV
  normalized_row jsonb,                   -- after mapper normalization (nullable if schema fail)
  error_codes text[] default '{}',      -- e.g., '{"REQUIRED_MISSING","BAD_UOM"}'
  created_at timestamptz not null default now(),
  primary key (import_batch_id, row_number)
);

create table if not exists public.import_errors (
  import_batch_id uuid not null references public.import_batches(import_batch_id) on delete cascade,
  row_number int,
  code text not null,
  message text,
  field text,
  created_at timestamptz not null default now()
);
```

### 3.2 Nice-to-have: mapping profiles
```sql
create table if not exists public.import_mapping_profiles (
  profile_id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  import_type text not null check (import_type in ('ingredients','ingredient_costs')),
  profile_name text not null,
  header_map jsonb not null,              -- e.g., { "SKU":"ingredient_code","Name":"name","Unit":"base_unit" }
  created_at timestamptz not null default now(),
  created_by text
);

create unique index if not exists ux_mapping_profile_name
  on public.import_mapping_profiles (tenant_id, import_type, profile_name);
```

---

## 4) Mappers & Validation (MVP)
We support **two import types** with minimal required columns.

### 4.1 `ingredients` CSV
Required columns (after mapping):  
- `ingredient_code` (string) — canonical code; normalized via `normalize_code`.  
Optional: `name`, `base_unit` (`g|ml|unit`).  

Validation
- `ingredient_code` present, non-empty.  
- `base_unit` (if provided) in `ref_uom` and category matches existing base_unit if row updates.  
- Dedup within file: no two rows resolve to the same normalized code.  

Commit
- Upsert via local `ingredient_upsert` (Identity_MVP); record who/when.  
- Add vendor legacy codes as aliases if a mapped column exists (optional in MVP).

### 4.2 `ingredient_costs` CSV
Required columns (after mapping):  
- `ingredient_code` or `ingredient_id` (resolve with Identity_MVP/aliases).  
- `unit_cost` (numeric, per base_unit).  
Optional: `currency` (default 'CAD'), `effective_from` (default now).  

Validation
- Ingredient resolvable for tenant (by code or alias).  
- `unit_cost` > 0; numeric.  
- If `effective_from` provided, must be a valid timestamp.  

Commit
- Call `ingredient_cost_upsert` (Chronicle_MVP SCD-2).  
- Emit `ingredient.cost.updated` on change (Chronicle function handles event).

---

## 5) Streamlit Flow
1) **Upload CSV** -> create `import_batches` row (status='received', compute `file_sha256`, store `idempotency_key`).  
2) **Map headers** (load profile or manual field selection).  
3) **Validate** -> write `import_rows_quarantine` with `normalized_row` + `error_codes`; update counts; set `status='validated'`.  
4) **Review quarantine** (table with filters: show errors, show normalized good rows).  
5) **Commit** (only if `invalid_rows=0`): transactional writes to target tables, set `status='committed'`, `committed_at`, `committed_by`; emit `import.completed`.  
6) **Discard** (optional): set `status='discarded'` (keeps quarantine for audit).

**Duplicate protection**
- If `idempotency_key` already committed for tenant -> return prior `import_batch_id` (no-op).  
- If `file_sha256` matches a committed batch for same tenant & import_type, show a warning (can proceed if intentional).

---

## 6) Events
Emit to `event_log` (Foundation_MVP):
- **`import.completed`** — after successful commit.  
  Payload: `{"import_batch_id":"…","import_type":"…","total_rows":…,"valid_rows":…,"invalid_rows":0}`.

(Ingredient cost updates also produce `ingredient.cost.updated` via Chronicle_MVP.)

---

## 7) Idempotency
- Enforced at the **batch** level via `(tenant_id, idempotency_key)` unique index.  
- On commit, if a batch is already `committed`, further commits return the same result.

---

## 8) API/Function Shapes (local now, FIRE-compatible later)
```python
def intake_start_batch(*, tenant_id:str, import_type:str, source_filename:str|None, idempotency_key:str|None, file_sha256:str|None) -> dict: ...

def intake_validate(*, import_batch_id:str, header_map:dict, rows:list[dict]) -> dict:
    """Apply mapping; run per-row validators; write quarantine rows with error codes; return counts."""

def intake_commit(*, import_batch_id:str, actor:str) -> dict:
    """Commit normalized rows transactionally to target tables; set status; emit import.completed."""

def intake_discard(*, import_batch_id:str, actor:str) -> dict: ...
```

---

## 9) Migration Plan
1) Create `import_*` tables.  
2) Seed one default mapping profile per import type (optional).  
3) Wire Streamlit pages to use the functions above.  
4) Add unique index for idempotency keys.

---

## 10) QA & Test Plan
- **Unit**: mapper for `ingredients`; mapper for `ingredient_costs`; header map application.  
- **Integration**: upload->validate->commit happy path; duplicate submit protected by idempotency; quarantine shows errors.  
- **SQL**: status transitions only allow {received->validated->committed|discarded}.  
- **Manual**: try a file with mixed good/bad rows; verify all bad rows quarantined and no partial commit.

---

## 11) Acceptance Gates (MVP)
- Good file commits cleanly; event emitted; rows present in targets.  
- Bad file results in **0 target writes** and fully-populated quarantine with actionable error codes.  
- Batch idempotency verified (same key doesn’t duplicate).  
- Tenant scoping verified in lookups and writes.

---

## 12) Future Hooks (v1)
- More import types (recipes, lines, prices).  
- Profile library per vendor; auto-detect profile from header signature.  
- Async processing, large-file streaming, file vault.  
- Full audit catalog with request/response payloads.
