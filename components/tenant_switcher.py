# components/tenant_switcher.py
import streamlit as st
from utils.supabase import supabase
from utils.tenant_state import set_active_tenant, get_active_tenant

@st.cache_data(ttl=60)
def _load_tenants():
    # keep it simple: id + name, sorted by name for stable display
    resp = supabase.table("tenants").select("id,name").order("name").execute()
    return resp.data or []

def render(in_sidebar: bool = True, label: str = "Active client"):
    container = st.sidebar if in_sidebar else st

    tenants = _load_tenants()
    if not tenants:
        container.warning("No tenants found.")
        return

    # maps
    name_by_id = {t["id"]: t["name"] for t in tenants}
    ids_sorted = [t["id"] for t in sorted(tenants, key=lambda x: x["name"])]

    # current active tenant (from session or lazy-init elsewhere)
    current_id = get_active_tenant(default=ids_sorted[0])

    # IMPORTANT: keep the widget state in sync with the active tenant id
    state_key = "tenant_select_id"
    if st.session_state.get(state_key) != current_id:
        st.session_state[state_key] = current_id  # pre-set before rendering

    # show selectbox storing tenant_id, formatting to human-readable name
    selected_id = container.selectbox(
        label,
        options=ids_sorted,
        key=state_key,
        index=ids_sorted.index(current_id) if current_id in ids_sorted else 0,
        format_func=lambda tid: name_by_id.get(tid, tid),
    )

    # when user changes, update active tenant and rerun
    if selected_id != current_id:
        set_active_tenant(selected_id)
        st.experimental_rerun()
