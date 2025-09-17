import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode
import streamlit as st
from utils.auth import require_auth
from components.active_client_badge import render as client_badge
from utils import tenant_db as db

require_auth()


st.set_page_config(page_title="Ingredient Categories", layout="wide")
client_badge(clients_page_title="Clients")
st.title("📋 Ingredient Categories")

# === Fetch Categories ===
def fetch_categories():
    res = db.table("ref_ingredient_categories").select("*").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

df = fetch_categories()
display_df = df.drop(columns=["id", "created_at", "updated_at"], errors="ignore")

# === AgGrid Table ===
gb = GridOptionsBuilder.from_dataframe(display_df)
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
grid_options = gb.build()

grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=400,
    allow_unsafe_jscode=True
)

# === Handle Selection ===
selected_row = grid_response["selected_rows"]
edit_data = None

selected_row = grid_response["selected_rows"]
edit_data = None

if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_name = selected_row.iloc[0].get("name")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_name = selected_row[0].get("name")
    else:
        selected_name = None

    if selected_name:
        match = df[df["name"] == selected_name]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None


# === Sidebar Form ===
with st.sidebar:
    st.subheader("➕ Add or Edit Category")
    with st.form("category_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")

        status_options = ["Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else "Active"
        status = st.selectbox("Status", status_options, index=status_options.index(selected_status))

        submitted = st.form_submit_button("Save Category")
        errors = []
        if not name:
            errors.append("Name")

        if submitted:
            if errors:
                st.error(f"⚠️ Please complete the following fields: {', '.join(errors)}")
            else:
                data = {"name": name, "status": status}
                if edit_mode:
                    db.table("ref_ingredient_categories").update(data).eq("id", edit_data["id"]).execute()
                    st.success("Category updated.")
                else:
                    db.insert("ref_ingredient_categories", data).execute()
                    st.success("Category added.")
                st.rerun()

    if edit_mode:
        if st.button("Cancel"):
            st.rerun()
        if st.button("Delete"):
            db.table("ref_ingredient_categories").update({"status": "Inactive"}).eq("id", edit_data["id"]).execute()
            st.success("Category inactivated.")
            st.rerun()