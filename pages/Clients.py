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
        if st.button("Load client"):
            if chosen_id and chosen_id != cur_tid:
                set_active_tenant(chosen_id)
                st.success(f"Loaded: {chosen_name}")
                st.cache_data.clear()
                st.rerun()
            else:
                st.info("That client is already loaded.")

# ---------- MANAGE TAB ----------
with manage_tab:
    left, right = st.columns([1.2, 2.2])

    with left:
        st.subheader("Add / Edit")
        # Selected row context (if any)
        sel_row = st.session_state.get("_clients_sel_row")
        # Form fields
        with st.form("client_form"):
            # Defaults from selection if exists
            base = sel_row or {}
            name = st.text_input("Name", value=base.get("name",""))
            code = st.text_input("Code", value=base.get("code",""))
            is_active = st.checkbox("Active", value=bool(base.get("is_active", True)))
            is_default = st.checkbox("Make default", value=bool(base.get("is_default", False)))

            logo_url = st.text_input("Logo URL", value=base.get("logo_url",""))
            brand_primary = st.text_input("Primary color (hex)", value=base.get("brand_primary","#111827"))
            brand_secondary = st.text_input("Secondary color (hex)", value=base.get("brand_secondary","#6b7280"))

            submitted = st.form_submit_button("Save client")
            if submitted:
                if not name or not code:
                    st.error("Name and Code are required.")
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
                    if base.get("id"):
                        db.table("tenants").update(payload).eq("id", base["id"]).execute()
                        st.success("Client updated.")
                    else:
                        db.insert("tenants", payload).execute()
                        st.success("Client created.")
                    # If marked default, unset default on others (DB enforces at-most-one anyway)
                    if is_default:
                        supabase.rpc("sql", { "q": """
                            update public.tenants set is_default = false
                            where id <> (select id from public.tenants where code = %(code)s limit 1)
                              and is_default = true;
                        """, "params": {"code": code}})  # Optional: if you have a generic `sql` RPC; otherwise ignore
                    st.cache_data.clear()
                    st.session_state.pop("_clients_sel_row", None)
                    st.rerun()

        if sel_row:
            c1, c2 = st.columns(2)
            if c1.button("Make loaded"):
                set_active_tenant(sel_row["id"])
                st.success(f"Loaded: {sel_row['name']}")
                st.rerun()
            if c2.button("Clear selection"):
                st.session_state.pop("_clients_sel_row", None)
                st.rerun()

    with right:
        st.subheader("Clients")
        # Build grid; hide id column
        show_cols = ["name","code","is_active","is_default","logo_url","brand_primary","brand_secondary"]
        table_df = df_all[show_cols] if not df_all.empty else pd.DataFrame(columns=show_cols)

        gb = GridOptionsBuilder.from_dataframe(table_df)
        gb.configure_default_column(editable=False, filter=True, sortable=True)
        gb.configure_selection("single", use_checkbox=False)
        grid = AgGrid(
            table_df,
            gridOptions=gb.build(),
            update_mode=GridUpdateMode.SELECTION_CHANGED,
            fit_columns_on_grid_load=True,
            height=420,
            allow_unsafe_jscode=True,
        )

        # Find the selected full row (by name+code to rehydrate id)
        sel = grid["selected_rows"]
        picked = None
        if isinstance(sel, pd.DataFrame) and not sel.empty:
            picked = sel.iloc[0].to_dict()
        elif isinstance(sel, list) and sel:
            picked = sel[0]

        if picked:
            # Rehydrate full row (get id)
            full = df_all.loc[(df_all["name"] == picked["name"]) & (df_all["code"] == picked["code"])]
            if not full.empty:
                st.session_state["_clients_sel_row"] = full.iloc[0].to_dict()
