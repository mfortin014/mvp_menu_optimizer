from typing import Optional

import streamlit as st

from utils.branding import inject_brand_colors
from utils.supabase import supabase
from utils.tenant_state import get_active_tenant, set_active_tenant


def _pick_default_tenant() -> Optional[str]:
    # Prefer DB default & active, else first by name
    r = (
        supabase.table("tenants")
        .select("id")
        .eq("is_default", True)
        .eq("is_active", True)
        .limit(1)
        .execute()
    )
    if r.data:
        return r.data[0]["id"]
    r = supabase.table("tenants").select("id").order("name").limit(1).execute()
    return r.data[0]["id"] if r.data else None


def _ensure_loaded_tenant() -> Optional[str]:
    tid = get_active_tenant()
    if tid:
        return tid
    tid = _pick_default_tenant()
    if tid:
        set_active_tenant(tid)
    return tid


def _tenant_name(tenant_id: Optional[str]) -> str:
    if not tenant_id:
        return "— No client loaded —"
    r = supabase.table("tenants").select("name").eq("id", tenant_id).limit(1).execute()
    return r.data[0]["name"] if r.data else tenant_id


def _go_clients_page():
    # Try built-in navigation if available; otherwise show a hint.
    if hasattr(st, "switch_page"):
        try:
            st.switch_page("Clients")
            return
        except Exception:
            try:
                st.switch_page("pages/Clients.py")
                return
            except Exception:
                pass
    st.info("Open the **Clients** page in the sidebar to change client.")


def render(clients_page_title: str = "Clients", **_ignore_kwargs):
    # ensure CSS vars are present (safe to call multiple times)
    inject_brand_colors()

    tid = _ensure_loaded_tenant()
    name = _tenant_name(tid)

    left, right = st.columns([5, 1.5])
    with left:
        st.markdown(
            f"""
            <div style="display:flex;align-items:center;gap:10px;margin:6px 0 4px 0;">
              <span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:var(--brand-primary);"></span>
              <div style="font-size:13px;color:#666;">Loaded client</div>
              <div style="font-weight:600;">{name}</div>
            </div>
            """,
            unsafe_allow_html=True,
        )
    with right:
        if st.button("Change client", key="btn_change_client_header"):
            _go_clients_page()
