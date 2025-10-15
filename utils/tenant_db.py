# utils/tenant_db.py
from typing import Any, Dict, List, Optional, Set

from utils.secrets import get as get_secret
from utils.supabase_client import supabase
from utils.tenant_state import get_active_tenant, set_active_tenant

Json = Dict[str, Any]

# Tables that are tenant-scoped and have tenant_id
TENANT_SCOPED: Set[str] = {
    "ingredients",
    "recipes",
    "recipe_lines",
    "ref_ingredient_categories",
    "ref_storage_type",
    "sales",
    "ingredient_costs",
    "input_catalog",
    "recipe_line_costs",
    "recipe_line_costs_base",
    "recipe_summary",
    "prep_costs",
    "missing_uom_conversions",
    # add more here as you tenant-scope them
}

# Tables that have soft-delete (deleted_at)
SOFT_DELETE: Set[str] = {
    "ingredients",
    "recipes",
    "recipe_lines",
    "ref_ingredient_categories",
    "ref_storage_type",
    "sales",
    # add more here if needed
}

# Global (no tenant filter)
GLOBAL_TABLES: Set[str] = {
    "tenants",
    "user_tenant_memberships",
    "ref_uom_conversion",  # global by design
}


def _tid() -> str:
    t = get_active_tenant()
    if t:
        return t

    # 1) DB default (and active)
    r = (
        supabase.table("tenants")
        .select("id")
        .eq("is_default", True)
        .eq("is_active", True)
        .limit(1)
        .execute()
    )
    if r.data:
        tid = r.data[0]["id"]
        set_active_tenant(tid)
        return tid

    # 2) ENV default (ID first, then CODE)
    want_id = (get_secret("DEFAULT_TENANT_ID", default="") or "").strip()
    if want_id:
        r = supabase.table("tenants").select("id").eq("id", want_id).limit(1).execute()
        if r.data:
            set_active_tenant(want_id)
            return want_id

    want_code = (get_secret("DEFAULT_TENANT_CODE", default="") or "").strip()
    if want_code:
        r = supabase.table("tenants").select("id").eq("code", want_code).limit(1).execute()
        if r.data:
            tid = r.data[0]["id"]
            set_active_tenant(tid)
            return tid

    # 3) Fallback: first by name
    r = supabase.table("tenants").select("id").order("name").limit(1).execute()
    if not r.data:
        raise RuntimeError("No tenants provisioned.")
    tid = r.data[0]["id"]
    set_active_tenant(tid)
    return tid


class _TenantTable:
    def __init__(self, name: str, include_deleted: bool = False):
        self.name = name
        self.include_deleted = include_deleted

    # --- READS ---
    def select(self, columns: str = "*"):
        b = supabase.table(self.name).select(columns)
        if self.name in TENANT_SCOPED:
            b = b.eq("tenant_id", _tid())
        if (self.name in SOFT_DELETE) and (not self.include_deleted):
            # only apply if table supports soft delete
            b = b.is_("deleted_at", "null")
        return b

    # --- WRITES ---
    def insert(self, row: Json):
        payload = dict(row)
        if self.name in TENANT_SCOPED:
            payload.setdefault("tenant_id", _tid())
        return supabase.table(self.name).insert(payload)

    def upsert(self, row: Json):
        payload = dict(row)
        if self.name in TENANT_SCOPED:
            payload.setdefault("tenant_id", _tid())
        return supabase.table(self.name).upsert(payload)

    def update(self, values: Json):
        # return a builder that already includes tenant filter, so callers can chain .eq("id",..).execute()
        b = supabase.table(self.name).update(values)
        if self.name in TENANT_SCOPED:
            b = b.eq("tenant_id", _tid())
        return b

    def delete(self):
        # hard delete (discouraged). Still tenant-scoped if used.
        b = supabase.table(self.name).delete()
        if self.name in TENANT_SCOPED:
            b = b.eq("tenant_id", _tid())
        return b


# Public helpers
def table(name: str, include_deleted: bool = False) -> _TenantTable:
    return _TenantTable(name, include_deleted=include_deleted)


def insert(name: str, row: Json):
    return table(name).insert(row)


def upsert(name: str, row: Json):
    return table(name).upsert(row)


def insert_many(name: str, rows: List[Json]):
    if name in TENANT_SCOPED:
        t = _tid()
        rows = [{**r, "tenant_id": r.get("tenant_id", t)} for r in rows]
    return supabase.table(name).insert(rows)


def update(name: str, values: Json, **filters):
    b = supabase.table(name)
    if name in TENANT_SCOPED:
        b = b.eq("tenant_id", _tid())
    for k, v in filters.items():
        b = b.eq(k, v)
    return b.update(values)


def soft_delete(name: str, **filters):
    # sets deleted_at = now()
    b = supabase.table(name)
    if name in TENANT_SCOPED:
        b = b.eq("tenant_id", _tid())
    for k, v in filters.items():
        b = b.eq(k, v)
    return b.update({"deleted_at": "now()"})


def restore(name: str, **filters):
    b = supabase.table(name)
    if name in TENANT_SCOPED:
        b = b.eq("tenant_id", _tid())
    for k, v in filters.items():
        b = b.eq(k, v)
    return b.update({"deleted_at": None})


# RPC helpers
def rpc(name: str, params: Optional[Json] = None):
    p = dict(params or {})
    if name in {"get_recipe_details_mt", "get_unit_costs_for_inputs_mt"}:
        p.setdefault("p_tenant", _tid())
    return supabase.rpc(name, p)
