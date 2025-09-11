import streamlit as st
from typing import Optional
from utils.supabase import supabase
from utils.tenant_state import get_active_tenant

# Optional helper: if streamlit-extras is installed, we can programmatically switch pages.
try:
    from streamlit_extras.switch_page_button import switch_page
    _HAS_SWITCH = True
except Exception:
    _HAS_SWITCH = False

def _tenant_name(tenant_id: Optional[str]) -> str:
    if not tenant_id:
        return "— no tenant —"
    r = supabase.table("tenants").select("name").eq("id", tenant_id).limit(1).execute()
    if r.data:
        return r.data[0]["name"]
    return tenant_id  # fallback to id if not found

def render(page_name: str, switcher_page_title: str = "Client Switcher"):
    """Show 'Active client: <name>' and a 'Change client' button.
       page_name is a friendly label like 'Ingredients' or 'Recipes' (used for return).
    """
    tid = get_active_tenant()
    name = _tenant_name(tid)
    left, right = st.columns([3,1])
    with left:
        st.info(f"Active client: **{name}**")
    with right:
        if st.button("Change client"):
            # record return target; the switcher page will send us back if it can
            st.session_state["_return_to_page"] = page_name
            if _HAS_SWITCH:
                switch_page(switcher_page_title)
            else:
                # fallback: show a hint; user can click the page in the sidebar
                st.session_state["_go_to_switcher"] = True
                st.warning(f"Open the '{switcher_page_title}' page in the sidebar to switch client.")
