import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

from utils.auth import require_auth
from components.tenant_switcher import render as tenant_switcher
from utils import tenant_db as db
from utils.tenant_state import set_active_tenant

require_auth()
st.set_page_config(page_title="Tenants", layout="wide")
st.title("🏷️ Tenants")

# Switcher up top (shows current)
tenant_switcher(in_sidebar=True)

# ---- Load tenants (global) ----
@st.cache_data(ttl=30)
def load_tenants():
    res = db.table("tenants").select("id,name,code,is_active").order("name").execute()
    rows = res.data or []
    return pd.DataFrame(rows)

df = load_tenants()

# ---- Grid ----
gb = GridOptionsBuilder.from_dataframe(df if not df.empty else pd.DataFrame(columns=["name","code","is_active"]))
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
grid = AgGrid(
    df, gridOptions=gb.build(), update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True, height=400, allow_unsafe_jscode=True
)

sel = grid["selected_rows"]
edit_data = None
if isinstance(sel, pd.DataFrame) and not sel.empty:
    edit_data = sel.iloc[0].to_dict()
elif isinstance(sel, list) and sel:
    edit_data = sel[0]

# ---- Sidebar form ----
with st.sidebar:
    st.subheader("➕ Add / Edit Tenant")
    with st.form("tenant_form"):
        name = st.text_input("Name", value=edit_data.get("name","") if edit_data else "")
        code = st.text_input("Code", value=edit_data.get("code","") if edit_data else "")
        is_active = st.checkbox("Active", value=bool(edit_data.get("is_active")) if edit_data else True)

        submitted = st.form_submit_button("Save")
        if submitted:
            if not name or not code:
                st.error("Name and Code are required.")
            else:
                payload = {"name": name, "code": code, "is_active": is_active}
                if edit_data:
                    db.table("tenants").update(payload).eq("id", edit_data["id"]).execute()
                    st.success("Tenant updated.")
                else:
                    db.insert("tenants", payload).execute()
                    st.success("Tenant created.")
                st.cache_data.clear()
                st.rerun()

    if edit_data:
        c1, c2 = st.columns(2)
        if c1.button("Switch to this tenant"):
            set_active_tenant(edit_data["id"])
            st.success(f"Switched to: {edit_data['name']}")
            st.rerun()
        # “Deactivate” instead of deleting tenants
        if c2.button("Deactivate"):
            db.table("tenants").update({"is_active": False}).eq("id", edit_data["id"]).execute()
            st.success("Tenant deactivated.")
            st.cache_data.clear()
            st.rerun()
