# components/tenant_switcher.py
import os
import streamlit as st
from utils.tenant_state import set_active_tenant, get_active_tenant
from utils.supabase import supabase

@st.cache_data(ttl=60)
def _load_tenants():
    resp = supabase.table("tenants").select("id,name,code").order("name").execute()
    return resp.data or []

def _resolve_active_tenant(tenants):
    """
    Resolve the active tenant in this priority:
      1) URL query param ?tenant=<id>
      2) session_state["tenant_id"]
      3) DEFAULT_TENANT_ID / DEFAULT_TENANT_CODE env
      4) first by name
    Writes back to session_state so the app can rely on it.
    """
    # 1) URL
    qp = st.experimental_get_query_params()
    q_tid = (qp.get("tenant") or [None])[0]
    ids = {t["id"] for t in tenants}
    if q_tid and q_tid in ids:
        if get_active_tenant() != q_tid:
            set_active_tenant(q_tid)
        return q_tid

    # 2) session
    cur = get_active_tenant()
    if cur and cur in ids:
        return cur

    # 3) ENV defaults
    want_id = os.getenv("DEFAULT_TENANT_ID", "").strip()
    if want_id and want_id in ids:
        set_active_tenant(want_id)
        return want_id

    want_code = os.getenv("DEFAULT_TENANT_CODE", "").strip()
    if want_code:
        by_code = {t.get("code"): t["id"] for t in tenants if t.get("code")}
        if want_code in by_code:
            tid = by_code[want_code]
            set_active_tenant(tid)
            return tid

    # 4) fallback: first by name
    tid = tenants[0]["id"]
    set_active_tenant(tid)
    return tid

def render(in_sidebar: bool = True, label: str = "Active client"):
    container = st.sidebar if in_sidebar else st

    tenants = _load_tenants()
    if not tenants:
        container.warning("No tenants found.")
        return

    # Resolve authoritative active tenant
    current = _resolve_active_tenant(tenants)

    id_by_name = {t["name"]: t["id"] for t in tenants}
    name_by_id = {t["id"]: t["name"] for t in tenants}
    names = list(id_by_name.keys())

    current_name = name_by_id.get(current, names[0])

    # Always sync widget state to active name before rendering
    if st.session_state.get("tenant_select") != current_name:
        st.session_state["tenant_select"] = current_name

    chosen_name = container.selectbox(label, names, key="tenant_select")
    chosen_id = id_by_name[chosen_name]

    if chosen_id != current:
        # Update both session and URL so navigation keeps the choice
        set_active_tenant(chosen_id)
        st.experimental_set_query_params(tenant=chosen_id)
        st.rerun()
