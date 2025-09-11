# components/tenant_switcher.py
import streamlit as st
from utils.supabase import supabase
from utils.tenant_state import set_active_tenant, get_active_tenant
from utils import tenant_db as db

@st.cache_data(ttl=60)
def _load_tenants():
    resp = db.table("tenants").select("id,name").order("name").execute()
    return resp.data or []

def render(in_sidebar: bool = True, label: str = "Active client"):
    container = st.sidebar if in_sidebar else st

    tenants = _load_tenants()
    if not tenants:
        container.warning("No tenants found.")
        return

    # Build lookup maps
    id_by_name = {t["name"]: t["id"] for t in tenants}
    names = list(id_by_name.keys())

    current = get_active_tenant(default=tenants[0]["id"])
    try:
        current_name = next(n for n, tid in id_by_name.items() if tid == current)
        idx = names.index(current_name)
    except StopIteration:
        idx = 0

    chosen_name = container.selectbox(label, names, index=idx, key="tenant_select")
    chosen_id = id_by_name[chosen_name]

    if chosen_id != current:
        set_active_tenant(chosen_id)
        st.experimental_rerun()