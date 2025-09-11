# utils/auth.py
import streamlit as st
from utils.supabase import supabase
from utils.tenant_state import get_active_tenant, set_active_tenant

def ensure_client_selected_pre_auth():
    """Show an active-clients picker above the password UI (always visible).
       Preselects DB default; updates session tenant on selection change.
    """
    # Load active clients
    r = supabase.table("tenants").select("id,name,is_default").eq("is_active", True).order("name").execute()
    data = r.data or []
    if not data:
        st.error("No active clients configured.")
        st.stop()

    # Determine which should be selected by default in the widget
    db_default_id = next((row["id"] for row in data if row.get("is_default")), data[0]["id"])
    tenant_names = [row["name"] for row in data]
    id_by_name = {row["name"]: row["id"] for row in data}
    name_by_id = {row["id"]: row["name"] for row in data}

    current = get_active_tenant() or db_default_id
    current_name = name_by_id.get(current, name_by_id.get(db_default_id, tenant_names[0]))

    st.subheader("Client")
    choice = st.selectbox("Choose client", tenant_names, index=tenant_names.index(current_name), key="login_client_select")
    chosen_id = id_by_name[choice]

    if chosen_id != current:
        set_active_tenant(chosen_id)

def require_auth():
    if "authenticated" not in st.session_state:
        st.session_state.authenticated = False

    if not st.session_state.authenticated:
        ensure_client_selected_pre_auth()
        st.title("🔐 Secure Access")
        password = st.text_input("Enter password:", type="password")
        if password == st.secrets.get("CHEF_PASSWORD"):
            st.session_state.authenticated = True
            st.success("Authenticated! You may continue.")
            st.rerun()
        elif password:
            st.error("Incorrect password")
            st.stop()
        else:
            st.stop()
