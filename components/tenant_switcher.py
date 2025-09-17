# components/tenant_switcher.py
import os
import streamlit as st
from utils.tenant_state import set_active_tenant, get_active_tenant
from utils.supabase import supabase

@st.cache_data(ttl=60)
def _load_tenants():
    # include code so we can honor DEFAULT_TENANT_CODE
    resp = supabase.table("tenants").select("id,name,code").order("name").execute()
    return resp.data or []

def _ensure_active_tenant(tenants):
    """Set session active tenant if missing, using env default or first by name."""
    current = get_active_tenant()
    if current:
        return current

    want_id   = os.getenv("DEFAULT_TENANT_ID", "").strip()
    want_code = os.getenv("DEFAULT_TENANT_CODE", "").strip()

    if want_id and any(t["id"] == want_id for t in tenants):
        set_active_tenant(want_id)
        return want_id

    if want_code:
        by_code = {t.get("code"): t["id"] for t in tenants if t.get("code")}
        if want_code in by_code:
            set_active_tenant(by_code[want_code])
            return by_code[want_code]

    # fallback: first by name
    tid = tenants[0]["id"]
    set_active_tenant(tid)
    return tid

def render(in_sidebar: bool = True, label: str = "Active client"):
    container = st.sidebar if in_sidebar else st

    tenants = _load_tenants()
    if not tenants:
        container.warning("No tenants found.")
        return

    current = _ensure_active_tenant(tenants)

    id_by_name = {t["name"]: t["id"] for t in tenants}
    names = list(id_by_name.keys())

    # Find the current name from the active id
    current_name = next((n for n, tid in id_by_name.items() if tid == current), names[0])

    # Pre-seed widget state so the selectbox shows the real active tenant on first render
    if "tenant_select" not in st.session_state:
        st.session_state["tenant_select"] = current_name

    chosen_name = container.selectbox(label, names, key="tenant_select")
    chosen_id = id_by_name[chosen_name]

    if chosen_id != current:
        set_active_tenant(chosen_id)
        st.rerun()
