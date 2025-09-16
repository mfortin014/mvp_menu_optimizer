
# MVP Readiness Checklist — Contract Parity & Event Logging (with Forge v1 Context)
**Version:** 1.0  
**Updated:** 2025-09-16 03:41  
**Audience:** MVP developers (Streamlit + Supabase) preparing for a **socket‑swap** to Forge v1.

---

## Why this document exists
You’re shipping the **Menu Optimizer (MVP)** now and will cut over to **Forge v1 (full‑stack SaaS)** later. To make that transition painless, the MVP must:
1) **Mirror** v1 API **contracts** (payloads & routes) behind a tiny client layer.  
2) **Emit** minimal, structured **events** so we can run parity tests (MVP vs v1) on real flows.

This checklist gives you precise tasks, acceptance criteria, and copy‑pasteable code so MVP stays aligned with v1—even before v1 exists.

---

## Snapshot: What “Forge v1” looks like (so MVP can aim at it)
**High‑level:** v1 is contract‑driven. We define schemas/APLs/events once, and **FIRE** (our code generator + runner) builds both backend services and a minimal React UI that use a shared **Forge UI** component library.

### Boundaries (thin sketch)
```
   [Streamlit MVP]  ───────────────────────────┐   (today)
                                                 ▼
   [Contracts v1]──> FIRE codegen ──> Services (FastAPI + Pydantic + Postgres RLS)
                                 └─> Web App (Next.js + Forge UI + Tailwind)

   Platform glue: Auth (Supabase), API Gateway, Observability (request logs, event/audit tables),
                  Backups/Restore, Tenant tokens (RLS on even for 1 tenant in pilot)
```

### Contract Pack v1 (source of truth)
- **Domains (JSON Schema):** `Ingredient`, `Recipe`, `RecipeLine`, `ImportBatch`, `CostCurve`  
- **APLs (procedures):** `ingredient.upsert`, `import.process`, `recipe.recompute`, `pricing.what_if`  
- **Events (audit/telemetry):** `ingredient.cost.updated`, `import.completed`, `recipe.recomputed`  
- **Conventions:** idempotency keys, error taxonomy (`code/message/details`), perf budgets (basic).

### FIRE responsibilities (v1 scope)
- **Codegen:** From contracts → FastAPI routes, Pydantic models, OpenAPI, pytest; Next.js pages using **Forge UI**; typed TS SDK; Playwright e2e tests.
- **Runner:** Sandbox execution, idempotency, **audit logging** and **event emission** baked in.
- **Registry:** APL → service target + version mapping.

### UI consistency (v1 scope)
- **Forge UI library** (`/packages/forge-ui`): Buttons, Inputs, Form kit (zod + react-hook-form), DataTable (TanStack), Layouts, Import Wizard; tokens in `/packages/forge-tokens`.
- **UI Registry** (`/contracts/ui/registry.yaml`): Maps domain hints to components and page recipes (forms, lists, filters, actions, RBAC, i18n).

**Implication for MVP:** If you mirror the **routes + payloads** below and **emit the same event shapes**, cutting over to v1 becomes changing a client, not rewriting flows.

---

## TASK 1 — Mirror the **Contract Pack v1** payloads & routes in MVP
**Goal:** Swap from local Python calls to v1 HTTP by flipping an env var. No UI rewrites.

### Routes & minimal payloads (use these exact shapes)
- `POST /import.process`
```json
{ "import_batch_id":"ib_123", "source":"upload", "file_name":"ingredients.xlsx", "file_type":"xlsx" }
```
- `POST /ingredient.upsert`
```json
{ "ingredient_code":"TOM-14OZ", "name":"Diced Tomato 14oz", "base_unit":"g",
  "unit_cost":0.0042, "effective_from":"2025-09-01" }
```
- `POST /recipe.recompute`
```json
{ "recipe_id":"rcp_001", "reason":"ingredient.cost.updated", "idempotency_key":"uuid-..." }
```
- `POST /pricing.what_if`
```json
{ "recipe_id":"rcp_001", "price_change_pct":5, "portion_change_pct":0 }
```

**Uniform error shape (v1 standard)**
```json
{ "error": { "code":"INVALID_PAYLOAD|NOT_FOUND|CONFLICT", "message":"...", "details":{} } }
```

### Client interface (drop‑in for MVP)
Create a very small client layer your Streamlit code calls—today it routes to local functions; tomorrow it calls HTTP with the **same** payloads.

```python
# mvp/api/client.py
import os, requests

class MOClient:
    def import_process(self, payload: dict) -> dict: ...
    def ingredient_upsert(self, payload: dict) -> dict: ...
    def recipe_recompute(self, payload: dict) -> dict: ...
    def pricing_what_if(self, payload: dict) -> dict: ...

class LocalClient(MOClient):
    # today: reuse your existing Python functions/modules
    def import_process(self, payload):    return local_import_process(payload)
    def ingredient_upsert(self, payload): return local_ingredient_upsert(payload)
    def recipe_recompute(self, payload):  return local_recipe_recompute(payload)
    def pricing_what_if(self, payload):   return local_pricing_what_if(payload)

class HttpClient(MOClient):
    def __init__(self, base_url, token):
        self.base_url, self.token = base_url.rstrip('/'), token
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {token}","Content-Type":"application/json"})

    def _post(self, route, payload):
        r = self.session.post(f"{self.base_url}/{route}", json=payload, timeout=30)
        if r.status_code >= 400:
            try:
                err = r.json().get("error", {})
            except Exception:
                err = {"code":"HTTP_ERROR","message":r.text,"details":{"status":r.status_code}}
            raise RuntimeError(err)
        return r.json()

    def import_process(self, payload):    return self._post("import.process", payload)
    def ingredient_upsert(self, payload): return self._post("ingredient.upsert", payload)
    def recipe_recompute(self, payload):  return self._post("recipe.recompute", payload)
    def pricing_what_if(self, payload):   return self._post("pricing.what_if", payload)

def get_client():
    mode = os.getenv("MO_API_MODE","local")
    return LocalClient() if mode=="local" else HttpClient(os.getenv("MO_API_URL",""), os.getenv("MO_API_TOKEN",""))
```

Wire Streamlit pages to **only** call `client = get_client()` then `client.ingredient_upsert(payload)` etc. Keep UOM/costing logic in DB views or Python modules—not inside widgets.

### Acceptance criteria
- Setting `MO_API_MODE=remote` is the **only** change needed to talk to v1.
- All four methods accept/return the payloads above and raise the uniform error shape.
- Unit tests cover happy path + one error per route.

---

## TASK 2 — Emit lightweight `event_log` rows (for parity & tracing)
**Goal:** Record the same events v1 will emit, so we can diff behavior later.

### Table DDL (Postgres / Supabase)
```sql
create table if not exists public.event_log (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  tenant_id text not null,
  event_type text not null,              -- e.g., 'ingredient.cost.updated'
  entity_type text not null,             -- 'ingredient' | 'recipe' | 'import_batch'
  entity_id text not null,
  correlation_id text,                   -- tie related events together
  idempotency_key text,
  actor text,                            -- 'user:mathieu' | 'system:mvp'
  payload jsonb not null,                -- event-specific fields
  source text not null default 'mvp'     -- 'mvp' | 'forge'
);
create index if not exists event_log_tenant_time on public.event_log (tenant_id, occurred_at desc);
create index if not exists event_log_event_time  on public.event_log (event_type, occurred_at desc);
create index if not exists event_log_entity      on public.event_log (entity_type, entity_id);
```

### Emit helper (Python)
```python
# mvp/events.py
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

### Where to emit (minimum viable)
- **`ingredient.cost.updated`** — after writing to `ingredient_costs`:
```python
emit_event(conn,
  tenant_id=t, event_type="ingredient.cost.updated",
  entity_type="ingredient", entity_id=ingredient_code,
  payload={"ingredient_code":ingredient_code,"unit_cost":unit_cost,"effective_from":effective_from},
  correlation_id=current_import_batch_id, idempotency_key=idemp_key, actor=current_user)
```
- **`import.completed`** — when a file completes validation + write:
```python
emit_event(conn, tenant_id=t, event_type="import.completed",
  entity_type="import_batch", entity_id=import_batch_id,
  payload={"file_name":file_name,"rows_ok":n_ok,"rows_error":n_err})
```
- **`recipe.recomputed`** — after recomputing margin:
```python
emit_event(conn, tenant_id=t, event_type="recipe.recomputed",
  entity_type="recipe", entity_id=recipe_id,
  payload={"prev_margin":prev,"new_margin":new,"changed_inputs":changed_inputs},
  correlation_id=trigger_event_id)
```

### (Optional) DB‑level emission for cost updates
```sql
create or replace function log_ingredient_cost_update()
returns trigger language plpgsql as $$
begin
  insert into public.event_log (tenant_id,event_type,entity_type,entity_id,payload,actor,source)
  values (current_setting('app.tenant_id', true), 'ingredient.cost.updated','ingredient', new.ingredient_code,
          jsonb_build_object('ingredient_code',new.ingredient_code,'unit_cost',new.unit_cost,'effective_from',new.effective_from),
          'system:db','mvp');
  return new;
end$$;

drop trigger if exists trg_cost_updated on public.ingredient_costs;
create trigger trg_cost_updated
after insert or update on public.ingredient_costs
for each row execute function log_ingredient_cost_update();
```
> Note: set `app.tenant_id` in the session on connect.

### Sanity & export queries
```sql
-- quick sanity
select event_type, count(*) 
from public.event_log
where occurred_at > now() - interval '1 hour'
group by 1;

-- parity export (windowed)
copy (
  select occurred_at, event_type, entity_type, entity_id, payload
  from public.event_log
  where occurred_at >= $1 and occurred_at < $2
) to stdout with csv header;
```

### Acceptance criteria
- The three events above are emitted with the fields shown.
- Sanity query returns rows after test actions.
- A parity export script can dump events for a given window to compare MVP vs v1.

---

## Environment variables and session settings
- `MO_API_MODE` = `local` | `remote`  
- `MO_API_URL` = base URL for v1 gateway  
- `MO_API_TOKEN` = JWT for v1  
- Postgres session: `set app.tenant_id = 'chefco';` (if using DB‑level event triggers)

---

## Quick reference: v1 service names to aim for
- **APLs:** `import.process`, `ingredient.upsert`, `recipe.recompute`, `pricing.what_if`  
- **Events:** `import.completed`, `ingredient.cost.updated`, `recipe.recomputed`  
- **Entities:** `ingredient`, `recipe`, `import_batch`

---

## Definition of Done (to mark MVP “v1‑ready”)
- ✅ Client layer abstracts calls; env flip hits v1 routes with zero page rewrites.  
- ✅ All four route payloads and the uniform error shape implemented.  
- ✅ `event_log` table created; the three core events are emitted in real flows.  
- ✅ Sanity queries and parity export tested on a small dataset.  
- ✅ Unit tests in place for client + emit functions (happy + error paths).

---

## Appendix A — Minimal v1 monorepo map (for awareness)
```
/contracts
  /domains/*.json
  /apl/*.json
  /events/*.json
  /ui/registry.yaml
/packages
  /forge-tokens    # Tailwind tokens & CSS vars
  /forge-ui        # React components used by codegen
/scaffolds
  /react/*         # Next.js page templates import forge-ui
/services          # Generated FastAPI services
/apps/mo           # Generated Next.js app for MO
/platform          # API gateway, ops (backup/restore), observability
/tests/golden      # Shared parity inputs vs MVP
```

## Appendix B — Error taxonomy (starter)
- `INVALID_PAYLOAD` — schema validation failed  
- `NOT_FOUND` — entity missing  
- `CONFLICT` — idempotency or uniqueness conflict  
- `INTERNAL_ERROR` — unhandled exceptions

## Appendix C — Notes on RLS (for later cutover)
Even if pilot is single‑tenant, v1 services run with **tenant tokens** and RLS **on**. Keep `tenant_id` available in MVP sessions (connection setting or app context) to ease the switch.

---

**That’s it.** Add the two tasks to your tracker with the acceptance criteria above. Once done, your MVP will plug directly into Forge v1 services and your parity tests will be trivial to run.
