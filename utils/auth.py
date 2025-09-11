# utils/auth.py
import streamlit as st
from utils.supabase import supabase
from utils.tenant_state import get_active_tenant, set_active_tenant

def ensure_client_selected_pre_auth():
    """Render a client chooser (active clients only) before showing the password form.
       Preselects DB default; if none, env default; else first by name.
    """
    if get_active_tenant():
        return  # already chosen

    # active clients only
    r = supabase.table("tenants").select("id,name,is_default").eq("is_active", True).order("name").execute()
    data = r.data or []
    if not data:
        st.error("No active clients configured.")
        st.stop()

    # pick default
    default_id = next((row["id"] for row in data if row.get("is_default")), data[0]["id"])
    names = [row["name"] for row in data]
    name_to_id = {row["name"]: row["id"] for row in data}
    default_name = next((row["name"] for row in data if row["id"] == default_id), names[0])

    st.subheader("Choose client")
    choice = st.selectbox("Client", names, index=names.index(default_name))
    chosen_id = name_to_id[choice]
    if chosen_id != get_active_tenant():
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
