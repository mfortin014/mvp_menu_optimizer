import pandas as pd
import streamlit as st
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

from components.active_client_badge import render as client_badge
from utils import tenant_db as db
from utils.auth import require_auth

require_auth()

st.set_page_config(page_title="UOM Conversions", layout="wide")
client_badge(clients_page_title="Clients")
st.title("UOM Conversions")


# === Fetch Conversions ===
def fetch_conversions():
    res = db.table("ref_uom_conversion").select("*").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()


df = fetch_conversions()
display_df = df.drop(columns=["id", "created_at", "updated_at"], errors="ignore")

# Format the factor column uniformly for display
if "factor" in display_df.columns:
    display_df["factor"] = display_df["factor"].round(6)

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
    allow_unsafe_jscode=True,
)

# === Handle Selection ===
selected_row = grid_response["selected_rows"]
edit_data = None

if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_from = selected_row.iloc[0].get("from_uom")
        selected_to = selected_row.iloc[0].get("to_uom")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_from = selected_row[0].get("from_uom")
        selected_to = selected_row[0].get("to_uom")
    else:
        selected_from = selected_to = None

    if selected_from and selected_to:
        match = df[(df["from_uom"] == selected_from) & (df["to_uom"] == selected_to)]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None

# === Sidebar Form ===
with st.sidebar:
    st.subheader("Add or Edit UOM Conversion")
    with st.form("uom_form"):
        from_uom = st.text_input(
            "From UOM", value=edit_data.get("from_uom", "") if edit_mode else ""
        )
        to_uom = st.text_input("To UOM", value=edit_data.get("to_uom", "") if edit_mode else "")

        factor_value = 1.0
        if edit_mode:
            try:
                factor_value = float(edit_data.get("factor", 1.0))
            except Exception:
                pass

        factor_str = st.text_input("Factor", value=f"{factor_value:.6f}")

        try:
            factor = float(factor_str)
        except ValueError:
            factor = -1  # invalid flag value

        submitted = st.form_submit_button("Save Conversion")
        errors = []
        if not from_uom:
            errors.append("From UOM")
        if not to_uom:
            errors.append("To UOM")
        if factor <= 0:
            errors.append("Factor must be > 0")

        if submitted:
            if errors:
                st.error(f"⚠️ Please complete the following fields: {', '.join(errors)}")
            else:
                data = {"from_uom": from_uom, "to_uom": to_uom, "factor": factor}
                if edit_mode:
                    db.table("ref_uom_conversion").update(data).eq("id", edit_data["id"]).execute()
                    st.success("Conversion updated.")
                else:
                    db.insert("ref_uom_conversion", data).execute()
                    st.success("Conversion added.")
                st.rerun()

    if edit_mode:
        if st.button("Cancel"):
            st.rerun()
