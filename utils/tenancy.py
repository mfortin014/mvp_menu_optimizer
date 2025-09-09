import os
import streamlit as st
from datetime import datetime, timezone

DEFAULT_TENANT_LABEL = "Default Tenant"

def set_current_tenant(tenant_id: str, tenant_name: str):
    st.session_state["tenant_id"] = tenant_id
    st.session_state["tenant_name"] = tenant_name

def get_current_tenant_id():
    return st.session_state.get("tenant_id")

def ensure_tenant(client, chef_email: str | None = None):
    tenants = client.table("tenants").select("*").is_("deleted_at","null").order("name").execute().data or []
    if not tenants:
        try:
            created = client.table("tenants").insert({"name":"Sur Le Feu","code":"SLF"}).execute()
            tenants = [created.data[0]]
        except Exception:
            tenants = [{"id":"00000000-0000-0000-0000-000000000000","name":DEFAULT_TENANT_LABEL}]
    if "tenant_id" not in st.session_state or not st.session_state["tenant_id"]:
        st.session_state["tenant_id"] = tenants[0]["id"]
        st.session_state["tenant_name"] = tenants[0]["name"]
    return st.session_state["tenant_id"], st.session_state.get("tenant_name", DEFAULT_TENANT_LABEL)

def soft_delete_payload():
    return {"deleted_at": datetime.now(timezone.utc).isoformat()}

def restore_payload():
    return {"deleted_at": None}
