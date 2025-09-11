import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

from utils import tenant_db as db
from utils.supabase import supabase
from utils.auth import require_auth
from utils.tenant_state import get_active_tenant, set_active_tenant

require_auth()
st.set_page_config(page_title="Clients", layout="wide")
st.title("🪪 Clients")

# ---------- data ----------
@st.cache_data(ttl=60)
def load_tenants_df() -> pd.DataFrame:
    r = db.table("tenants").select("id,name,code,is_active").order("name").execute()
    return pd.DataFrame(r.data or [])

def resolve_name_by_id(df: pd.DataFrame, tid: str) -> str:
    if df.empty: return "— no tenants —"
    row = df.loc[df["id"] == tid]
    return row.iloc[0]["name"] if not row.empty else "— unknown —"

tenants_df = load_tenants_df()
if tenants_df.empty:
    st.warning("No tenants found. Create one below.")
current_tid = get_active_tenant() or (tenants_df.iloc[0]["id"] if not tenants_df.empty else None)
current_name = resolve_name_by_id(tenants_df, current_tid) if current_tid else "—"

switch_tab, manage_tab = st.tabs(["🔁 Switch active client", "🛠️ Manage tenants"])

# ---------- SWITCH TAB ----------
with switch_tab:
    st.subheader("Switch active client")
    st.info(f"Current active client: **{current_name}**")

    names = tenants_df["name"].tolist() if not tenants_df.empty else []
    name_to_id = dict(zip(tenants_df["name"], tenants_df["id"])) if not tenants_df.empty else {}
    default_idx = names.index(current_name) if current_name in names else 0 if names else 0
    chosen_name = st.selectbox("Choose client to load", names, index=default_idx if names else 0, key="switcher_select")
    chosen_id = name_to_id.get(chosen_name)

    load_col, _ = st.columns([1,3])
    with load_col:
        if st.button("Load client"):
            if chosen_id and chosen_id != current_tid:
                set_active_tenant(chosen_id)
                st.success(f"Loaded client: {chosen_name}")
                st.cache_data.clear()
                st.rerun()
            else:
                st.info("That client is already active.")

# ---------- MANAGE TAB ----------
with manage_tab:
    st.subheader("Tenants")

    # Grid
    grid_df = tenants_df.copy()
    gb = GridOptionsBuilder.from_dataframe(grid_df if not grid_df.empty else pd.DataFrame(columns=["name","code","is_active"]))
    gb.configure_default_column(editable=False, filter=True, sortable=True)
    gb.configure_selection("single", use_checkbox=False)
    grid = AgGrid(
        grid_df,
        gridOptions=gb.build(),
        update_mode=GridUpdateMode.SELECTION_CHANGED,
        fit_columns_on_grid_load=True,
        height=380,
        allow_unsafe_jscode=True,
    )
    sel = grid["selected_rows"]
    edit_data = None
    if isinstance(sel, pd.DataFrame) and not sel.empty:
        edit_data = sel.iloc[0].to_dict()
    elif isinstance(sel, list) and sel:
        edit_data = sel[0]

    st.markdown("---")
    st.subheader("Add / Edit")

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
        c1, c2, c3 = st.columns(3)
        with c1:
            if st.button("Make Active in App"):
                set_active_tenant(edit_data["id"])
                st.success(f"Active client set: {edit_data['name']}")
                st.rerun()
        with c2:
            if st.button("Deactivate"):
                db.table("tenants").update({"is_active": False}).eq("id", edit_data["id"]).execute()
                st.success("Tenant deactivated.")
                st.cache_data.clear()
                st.rerun()
        with c3:
            if st.button("Activate"):
                db.table("tenants").update({"is_active": True}).eq("id", edit_data["id"]).execute()
                st.success("Tenant activated.")
                st.cache_data.clear()
                st.rerun()
