# utils/tenant_state.py
import streamlit as st
from typing import Optional

TENANT_KEY = "tenant_id"

def set_active_tenant(tenant_id: str) -> None:
    st.session_state[TENANT_KEY] = tenant_id

def get_active_tenant(default: Optional[str] = None) -> Optional[str]:
    return st.session_state.get(TENANT_KEY, default)

def key(name: str) -> str:
    """Prefix keys with the active tenant to avoid cross-tenant widget bleed."""
    tid = get_active_tenant("no-tenant")
    return f"{tid}__{name}"
