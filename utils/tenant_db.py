# utils/tenant_db.py
from typing import Any, Dict, List, Optional
from utils.supabase import supabase
from utils.tenant_state import get_active_tenant
from utils import tenant_db as db

Json = Dict[str, Any]

def _tid() -> str:
    t = get_active_tenant()
    if not t:
        raise RuntimeError("No active tenant set in session_state.")
    return t

# ---------- READS ----------
def table(name: str, include_deleted: bool = False):
    b = supabase.table(name).eq("tenant_id", _tid())
    if not include_deleted:
        try:
            b = b.is_("deleted_at", "null")
        except Exception:
            pass  # table might not have deleted_at
    return b

# ---------- WRITES ----------
def insert(name: str, row: Json):
    payload = dict(row)
    payload.setdefault("tenant_id", _tid())
    return supabase.table(name).insert(payload)

def upsert(name: str, row: Json):
    payload = dict(row)
    payload.setdefault("tenant_id", _tid())
    return supabase.table(name).upsert(payload)

def insert_many(name: str, rows: List[Json]):
    t = _tid()
    payload = [{**r, "tenant_id": r.get("tenant_id", t)} for r in rows]
    return supabase.table(name).insert(payload)

def update(name: str, values: Json, **filters):
    b = supabase.table(name).eq("tenant_id", _tid())
    for k, v in filters.items():
        b = b.eq(k, v)
    return b.update(values)

def soft_delete(name: str, **filters):
    b = supabase.table(name).eq("tenant_id", _tid())
    for k, v in filters.items():
        b = b.eq(k, v)
    return b.update({"deleted_at": "now()"})

def restore(name: str, **filters):
    b = supabase.table(name).eq("tenant_id", _tid())
    for k, v in filters.items():
        b = b.eq(k, v)
    return b.update({"deleted_at": None})

# ---------- RPC ----------
def rpc(name: str, params: Optional[Json] = None):
    p = dict(params or {})
    if name in {"get_recipe_details_mt", "get_unit_costs_for_inputs_mt"}:
        p.setdefault("p_tenant", _tid())
    return supabase.rpc(name, p)