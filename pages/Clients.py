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

# Auto-focus the row we just saved (if any)
_focus_id = st.session_state.pop("_clients_focus_id", None)
if _focus_id:
    sel = df_all.loc[df_all["id"] == _focus_id]
    if not sel.empty:
        st.session_state["_clients_sel_row"] = sel.iloc[0].to_dict()

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
    # Handle selection first, then render the form (no reruns on click)
    left, right = st.columns([1.2, 2.2])

    # --- RIGHT: GRID (selection) ---
    with right:
        st.subheader("Clients")
        table_df = df_all.copy()

        gb = GridOptionsBuilder.from_dataframe(table_df)
        gb.configure_default_column(editable=False, filter=True, sortable=True)
        gb.configure_selection("single", use_checkbox=False)  # row click selects & highlights
        gb.configure_column("id", hide=True)
        grid = AgGrid(
            table_df,
            gridOptions=gb.build(),
            update_mode=GridUpdateMode.SELECTION_CHANGED,
            fit_columns_on_grid_load=True,
            height=420,
            allow_unsafe_jscode=True,
        )

        picked = grid["selected_rows"]
        picked_row = None
        if isinstance(picked, list) and picked:
            picked_row = picked[0]
        elif hasattr(picked, "empty") and not picked.empty:
            picked_row = picked.iloc[0].to_dict()

        if picked_row and picked_row.get("id"):
            full = df_all.loc[df_all["id"] == picked_row["id"]]
            if not full.empty:
                st.session_state["_clients_sel_row"] = full.iloc[0].to_dict()

    # --- LEFT: FORM (reads hydrated selection this same run) ---
    with left:
        st.subheader("Add / Edit")
        sel_row = st.session_state.get("_clients_sel_row", {})
        rowkey = sel_row.get("id", "new")  # key suffix to isolate widget state per row

        with st.form("client_form"):
            name = st.text_input("Name", value=sel_row.get("name",""), key=f"client_name_{rowkey}")
            code = st.text_input("Code", value=sel_row.get("code",""), key=f"client_code_{rowkey}")

            is_active  = st.checkbox("Active", value=bool(sel_row.get("is_active", True)), key=f"client_active_{rowkey}")
            is_default = st.checkbox("Make default", value=bool(sel_row.get("is_default", False)), key=f"client_default_{rowkey}")

            # Color pickers show the hex and color
            brand_primary = st.color_picker("Primary color", value=(sel_row.get("brand_primary") or "#111827"), key=f"cp_primary_{rowkey}")
            brand_secondary = st.color_picker("Secondary color", value=(sel_row.get("brand_secondary") or "#6b7280"), key=f"cp_secondary_{rowkey}")

            logo_url = st.text_input("Logo URL", value=sel_row.get("logo_url",""), key=f"client_logo_{rowkey}")

            if st.form_submit_button("Save client", use_container_width=True):
                # Accurate guardrails
                if not name or not code:
                    st.error("Please provide both Name and Code.")
                elif sel_row.get("id") and sel_row.get("is_default") and (is_active is False):
                    st.error("The default client cannot be deactivated. Please set another client as default first.")
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

                    # Enforce single default: unset others (scoped WHERE) before saving this one
                    if is_default:
                        q = db.table("tenants").update({"is_default": False}).eq("is_default", True)
                        if sel_row.get("id"):
                            q = q.neq("id", sel_row["id"])
                        q.execute()

                    saved_id = sel_row.get("id")
                    if saved_id:
                        db.table("tenants").update(payload).eq("id", saved_id).execute()
                        st.success("Client updated.")
                    else:
                        res = db.insert("tenants", payload).execute()
                        if res.data and len(res.data):
                            saved_id = res.data[0].get("id")

                    # Focus the saved row on the next render so the form matches DB truth
                    if saved_id:
                        st.session_state["_clients_focus_id"] = saved_id

                    st.cache_data.clear()
                    st.rerun()

        if sel_row.get("id"):
            c1, c2 = st.columns(2)
            if c1.button("Load client", key=f"btn_manage_load_{rowkey}"):
                set_active_tenant(sel_row["id"])
                st.success(f"Loaded: {sel_row['name']}")
                st.rerun()
            if c2.button("Clear selection", key=f"btn_manage_clear_{rowkey}"):
                st.session_state.pop("_clients_sel_row", None)
                st.rerun()
