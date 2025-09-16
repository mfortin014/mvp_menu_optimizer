
# Foundation_MVP — Platform Invariants & App Skeleton (Spec)
**Version:** 1.0  \n**Updated:** 2025-09-16 05:12  \n**Applies to:** Streamlit MVP (no FIRE), Supabase Postgres  \n**Owner:** Foundation_MVP

---

## 1) Purpose & Scope
Lock a few **non‑negotiable invariants** and a thin app structure so the Streamlit MVP can later **socket‑swap** to Forge v1 with minimal friction.
- Keep it **simple now**, but **shaped for v1** (contracts, events, tenant safety).
- No FIRE in MVP; we still mirror FIRE’s future boundaries (client layer, events, idempotency).

**In scope**
- Tenant scoping pattern (RLS‑optional for MVP; views + session variable shape).
- Soft delete invariant and index pattern.
- Idempotent writes (imports & cost updates).
- Event logging (triad events) and parity export.
- Uniform error shape.
- Thin client interface (`MO_API_MODE=local|remote`).

**Out of scope (v1+)**
- Full RLS rollout, audit log catalog, API gateway, brokered events, Playwright/E2E CI.

---

## 2) Invariants (MVP)
1) **Tenant‑safe reads**: every read passes a tenant context; list/detail queries must **exclude soft‑deleted rows**.  
2) **Soft delete everywhere**: entities use `deleted_at`; unique indexes exclude deleted rows.  
3) **Idempotent writes**: imports and cost updates carry an `idempotency_key`; repeated keys are **no‑ops**.  
4) **Event logging**: emit `import.completed`, `ingredient.cost.updated`, `recipe.recomputed` with minimal payloads.  
5) **Uniform error**: { "error": { "code": "...","message":"...","details":{} } } across all app-layer calls.  
6) **Client abstraction**: Streamlit pages only call `MOClient`; flip `MO_API_MODE` later to hit v1 services.

---

## 3) Data Layer — DDL & Patterns

### 3.1 `event_log` (required)
```sql
create table if not exists public.event_log (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  tenant_id text not null,
  event_type text not null,
  entity_type text not null,
  entity_id text not null,
  correlation_id text,
  idempotency_key text,
  actor text,
  payload jsonb not null,
  source text not null default 'mvp'
);
create index if not exists event_log_tenant_time on public.event_log (tenant_id, occurred_at desc);
create index if not exists event_log_event_time  on public.event_log (event_type, occurred_at desc);
create index if not exists event_log_entity      on public.event_log (entity_type, entity_id);
```

### 3.2 Soft delete + unique index pattern (copy for entities)
```sql
-- Example: ingredients (full table lives in Identity_MVP)
create unique index if not exists ux_ingredients_code_active
  on public.ingredients (tenant_id, ingredient_code)
  where deleted_at is null;
```

### 3.3 Idempotency pattern
MVP keeps idempotency **in the target tables** (no central registry). Required columns:
- `idempotency_key text` (nullable), unique **per natural key & effective window** where applicable.
- For `ingredient_costs`: unique on `(tenant_id, ingredient_code, effective_from)`; store the key.
- For `import_batches`: unique on `(tenant_id, import_batch_id)`; store the key.

> v1 may introduce a shared `idempotency` registry table; MVP just stores the key where it matters.

### 3.4 Tenant session shape (optional RLS)
Use a session variable to carry tenant context even if you don’t enable RLS yet.

```sql
-- call per-connection
select set_config('app.tenant_id', 'chefco', true);
-- pattern used by policies or views later: current_setting('app.tenant_id', true)
```

---

## 4) App Structure — Thin Layers
```
/mvp
  /api/client.py        # MOClient interface + LocalClient + HttpClient (env switch)
  /db/queries.py        # SQL helpers; must accept tenant_id (or read session var)
  /events.py            # emit_event(conn, ...)
  /services/            # pure Python domain logic (no Streamlit widgets here)
  /pages/               # Streamlit UI; calls client/services only
/migrations             # SQL files (idempotent)
```

**Rules**
- Streamlit pages import **services**; services call **db helpers** and **emit_event**.  
- **No business rules** in widgets (formatting/UI only).  
- All db helpers take `tenant_id` or set it in session.

---

## 5) Client Layer (socket‑swap shape)

### 5.1 Interface & adapters
```python
# /mvp/api/client.py
import os, requests

class MOClient:
    def import_process(self, payload: dict) -> dict: ...
    def ingredient_upsert(self, payload: dict) -> dict: ...
    def recipe_recompute(self, payload: dict) -> dict: ...
    def pricing_what_if(self, payload: dict) -> dict: ...

class LocalClient(MOClient):
    # wire to your current Python functions
    ...

class HttpClient(MOClient):
    def __init__(self, base_url, token):
        self.base_url = base_url.rstrip('/'); self.session = requests.Session()
        if token: self.session.headers.update({"Authorization": f"Bearer {token}"})
        self.session.headers.update({"Content-Type":"application/json"})
    def _post(self, route, payload):
        r = self.session.post(f"{self.base_url}/{route}", json=payload, timeout=30)
        if r.status_code >= 400:
            try: err = r.json().get("error", {})
            except Exception: err = {"code":"HTTP_ERROR","message":r.text,"details":{"status":r.status_code}}
            raise RuntimeError(err)
        return r.json()
    def import_process(self, p):    return self._post("import.process", p)
    def ingredient_upsert(self, p): return self._post("ingredient.upsert", p)
    def recipe_recompute(self, p):  return self._post("recipe.recompute", p)
    def pricing_what_if(self, p):   return self._post("pricing.what_if", p)

def get_client():
    return LocalClient() if os.getenv("MO_API_MODE","local")=="local"            else HttpClient(os.getenv("MO_API_URL",""), os.getenv("MO_API_TOKEN",""))
```

### 5.2 Error shape
All adapters raise a `RuntimeError({"error":{...}})` with `code/message/details` keys.

---

## 6) Events — Minimal Helpers
```python
# /mvp/events.py
import json
def emit_event(conn, *, tenant_id, event_type, entity_type, entity_id,
               payload: dict, correlation_id=None, idempotency_key=None, actor="user:mvp"):
    with conn.cursor() as cur:
        cur.execute("""
          insert into public.event_log
            (tenant_id, event_type, entity_type, entity_id, payload, correlation_id, idempotency_key, actor)
          values (%s,%s,%s,%s,%s,%s,%s,%s)
        """, (tenant_id, event_type, entity_type, entity_id, json.dumps(payload),
                correlation_id, idempotency_key, actor))
```

**Where to emit (must)**
- `ingredient.cost.updated` after `ingredient_costs` write (Chronicle_MVP).
- `import.completed` after clean commit (Intake_MVP).
- `recipe.recomputed` after recompute (Chronicle_MVP).

**Sanity**
```sql
select event_type, count(*) from public.event_log
where occurred_at > now() - interval '1 hour' group by 1;
```

---

## 7) Migrations & Scripts
- Store SQL DDL in `/migrations`. Name with incremental prefix: `V001_event_log.sql`, `V002_identity_tables.sql`, etc.
- Provide a tiny runner script or manual checklist to apply them in order.
- Keep migrations **idempotent** (`create if not exists`, `drop trigger if exists`, etc.).

---

## 8) Testing & Parity
- **Unit**: client layer happy/error paths; services idempotency on duplicate calls.
- **SQL**: indexes exist; soft‑delete index filters; event rows appear after flows.
- **Parity export** (for later diff with v1):
```sql
copy (
  select occurred_at, event_type, entity_type, entity_id, payload
  from public.event_log
  where occurred_at >= $1 and occurred_at < $2
) to stdout with csv header;
```

---

## 9) Acceptance Gates (Foundation)
- Tenant context is present in all data paths (param or session var).
- Soft delete enforced by queries and partial unique indexes.
- Imports & cost updates require/record `idempotency_key` and are no‑ops on repeat.
- Event triad emitted and queryable; sanity query returns expected counts.
- Streamlit pages call **client/services only**; no business logic in widgets.
- Migrations are applied and re‑runnable without errors.

---

## 10) Future Hooks (v1)
- Turn on RLS with policies using `current_setting('app.tenant_id', true)`.
- Add `audit_log` table and wrap service calls to persist request/response for traceability.
- Swap `MO_API_MODE` to `remote` to talk to v1 gateway; keep payloads identical.
