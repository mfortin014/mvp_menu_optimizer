import streamlit as st
from typing import Optional
from utils.supabase import supabase
from utils.tenant_state import get_active_tenant, set_active_tenant

# ---- helpers ----

def _ensure_loaded_tenant() -> Optional[str]:
    """Ensure we have a tenant set in session; prefer existing, else env default, else first by name."""
    tid = get_active_tenant()
    if tid:
        return tid
    # fallback to first by name
    r = supabase.table("tenants").select("id").order("name").limit(1).execute()
    rows = r.data or []
    if not rows:
        return None
    tid = rows[0]["id"]
    set_active_tenant(tid)
    return tid

def _tenant_name(tenant_id: Optional[str]) -> str:
    if not tenant_id:
        return "— No client loaded —"
    r = supabase.table("tenants").select("name").eq("id", tenant_id).limit(1).execute()
    return r.data[0]["name"] if r.data else tenant_id

# ---- component ----

def render(clients_page_title: str = "Clients"):
    """Sidebar badge that shows the Loaded Client and links to Clients page."""
    tid = _ensure_loaded_tenant()
    name = _tenant_name(tid)

    with st.sidebar:
        st.markdown(
            f"""
            <div style="
                padding:10px 12px;
                border:1px solid rgba(0,0,0,0.08);
                border-radius:10px;
                background:linear-gradient(180deg, rgba(250,250,250,0.95), rgba(245,245,245,0.95));
                box-shadow:0 1px 2px rgba(0,0,0,0.04);
                margin:8px 0 12px 0;
                ">
              <div style="font-size:12px; color:#666; margin-bottom:4px;">Loaded client</div>
              <div style="font-weight:600; margin-bottom:8px;">{name}</div>
              <div>
                👉 <span style="font-size:14px;">
                  {st.page_link(f"{clients_page_title}.py", label="Change client", icon="🔁")}
                </span>
              </div>
            </div>
            """,
            unsafe_allow_html=True,
        )
