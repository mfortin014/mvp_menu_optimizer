import streamlit as st
import pandas as pd
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode
from utils import tenant_db as db
from utils.supabase import supabase
from utils.auth import require_auth
from utils.tenant_state import get_active_tenant, set_active_tenant
from components.active_client_badge import render as client_badge

require_auth()
st.set_page_config(page_title="Clients", layout="wide")
client_badge(clients_page_title="Clients")
st.title("🪪 Clients")

# ---------- data ----------
@st.cache_data(ttl=60)
def load_all_clients_df() -> pd.DataFrame:
    r = db.table("tenants").select("id,name,code,is_active,logo_url,brand_primary,brand_secondary,is_default").order("name").execute()
    return pd.DataFrame(r.data or [])

def _name_by_id(df: pd.DataFrame, tid: str) -> str:
    if df.empty: return "—"
    row = df.loc[df["id"] == tid]
    return row.iloc[0]["name"] if not row.empty else "—"

df_all = load_all_clients_df()
cur_tid = get_active_tenant() or (df_all.iloc[0]["id"] if not df_all.empty else None)
cur_name = _name_by_id(df_all, cur_tid) if cur_tid else "—"

switch_tab, manage_tab = st.tabs(["🔁 Switch client", "🛠️ Manage clients"])

# ---------- SWITCH TAB ----------
with switch_tab:
    st.subheader("Switch client")
    st.info(f"Currently loaded: **{cur_name}**")

    df_active = df_all[df_all["is_active"] == True] if not df_all.empty else df_all
    names = df_active["name"].tolist() if not df_active.empty else []
    map_name_id = dict(zip(df_active["name"], df_active["id"])) if not df_active.empty else {}
    idx = names.index(cur_name) if cur_name in names else 0 if names else 0

    chosen_name = st.selectbox("Choose client to load", names, index=idx if names else 0, key="switcher_select")
    chosen_id = map_name_id.get(chosen_name)

    col_load, _ = st.columns([1,3])
    with col_load:
        if st.button("Load client", key="btn_switch_load"):
            if chosen_id and chosen_id != cur_tid:
                set_active_tenant(chosen_id)
                st.success(f"Loaded: {chosen_name}")
                st.cache_data.clear()
                st.rerun()
            else:
                st.info("That client is already loaded.")

# ---------- MANAGE TAB ----------
with manage_tab:
    # Handle selection first, then render form
    left, right = st.columns([1.2, 2.2])

    # --- RIGHT: GRID (selection); we’ll add “edit mode” afterward in §2 ---
    with right:
        st.subheader("Clients")
        table_df = df_all.copy()
        gb = GridOptionsBuilder.from_dataframe(table_df)
        gb.configure_default_column(editable=False, filter=True, sortable=True)
        gb.configure_selection("single", use_checkbox=False)
        gb.configure_column("id", hide=True)
        grid = AgGrid(
            table_df,
            gridOptions=gb.build(),
            update_mode=GridUpdateMode.SELECTION_CHANGED,
            fit_columns_on_grid_load=True,
            height=420,
            allow_unsafe_jscode=True,
        )

        current_sel = st.session_state.get("_clients_sel_row", {})
        picked = grid["selected_rows"]
        picked_row = None
        if isinstance(picked, list) and picked:
            picked_row = picked[0]
        elif hasattr(picked, "empty") and not picked.empty:
            picked_row = picked.iloc[0].to_dict()

        if picked_row and picked_row.get("id") and picked_row.get("id") != current_sel.get("id"):
            full = df_all.loc[df_all["id"] == picked_row["id"]]
            if not full.empty:
                st.session_state["_clients_sel_row"] = full.iloc[0].to_dict()
                st.experimental_rerun()

    # --- LEFT: FORM (reads hydrated selection) ---
    with left:
        st.subheader("Add / Edit")
        sel_row = st.session_state.get("_clients_sel_row", {})

        with st.form("client_form"):
            name = st.text_input("Name", value=sel_row.get("name",""))
            code = st.text_input("Code", value=sel_row.get("code",""))
            is_active = st.checkbox("Active", value=bool(sel_row.get("is_active", True)))
            is_default = st.checkbox("Make default", value=bool(sel_row.get("is_default", False)))

            logo_url = st.text_input("Logo URL", value=sel_row.get("logo_url",""))
            brand_primary = st.text_input("Primary color (hex)", value=sel_row.get("brand_primary","#111827"))
            brand_secondary = st.text_input("Secondary color (hex)", value=sel_row.get("brand_secondary","#6b7280"))

            if st.form_submit_button("Save client", use_container_width=True):
                if not name or not code:
                    st.error("Please provide both Name and Code.")
                elif is_default and not is_active:
                    st.error("A client must be active before it can be set as the default.")
                else:
                    payload = {
                        "name": name,
                        "code": code,
                        "is_active": is_active,
                        "is_default": is_default,
                        "logo_url": logo_url or None,
                        "brand_primary": brand_primary or None,
                        "brand_secondary": brand_secondary or None,
                    }

                    # Ensure single default at the app layer (DB also enforces it)
                    if is_default:
                        # Unset default on all other clients *before* saving this one
                        db.table("tenants").update({"is_default": False}).execute()

                    if sel_row.get("id"):
                        db.table("tenants").update(payload).eq("id", sel_row["id"]).execute()
                        st.success("Client updated.")
                    else:
                        db.insert("tenants", payload).execute()
                        st.success("Client created.")

                    st.cache_data.clear()
                    st.session_state.pop("_clients_sel_row", None)
                    st.rerun()

        # Action row
        if sel_row.get("id"):
            c1, c2, c3 = st.columns(3)
            if c1.button("Load client", key="btn_manage_load"):
                set_active_tenant(sel_row["id"])
                st.success(f"Loaded: {sel_row['name']}")
                st.rerun()
            if c2.button("Deactivate", key="btn_manage_deactivate"):
                if sel_row.get("is_default"):
                    st.error("The default client cannot be deactivated. Please unset it as default first.")
                else:
                    db.table("tenants").update({"is_active": False}).eq("id", sel_row["id"]).execute()
                    st.success("Client deactivated.")
                    st.cache_data.clear()
                    st.rerun()
            if c3.button("Activate", key="btn_manage_activate"):
                db.table("tenants").update({"is_active": True}).eq("id", sel_row["id"]).execute()
                st.success("Client activated.")
                st.cache_data.clear()
                st.rerun()