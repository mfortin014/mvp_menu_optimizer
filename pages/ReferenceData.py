import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

st.set_page_config(page_title="Reference Data", layout="wide")
st.title("🗂️ Reference Data")

# === Table Configurations ===
ref_tables = {
    "Ingredient Categories": {
        "table": "ref_ingredient_categories",
        "fields": ["name", "status"]
    },
    "UOM Conversions": {
        "table": "ref_uom_conversion",
        "fields": ["from_uom", "to_uom", "factor"]
    }
}

# === Render and Edit Each Table ===
for label, config in ref_tables.items():
    st.subheader(f"📋 {label}")
    table_name = config["table"]
    editable_fields = config["fields"]

    # Fetch data
    res = supabase.table(table_name).select("*").execute()
    df = pd.DataFrame(res.data) if res.data else pd.DataFrame(columns=editable_fields)

    if "id" not in df.columns:
        df.insert(0, "id", [f"new_{i}" for i in range(len(df))])

    gb = GridOptionsBuilder.from_dataframe(df)
    gb.configure_columns(editable_fields, editable=True)
    gb.configure_selection("single", use_checkbox=True)
    grid_options = gb.build()

    grid_response = AgGrid(
        df,
        gridOptions=grid_options,
        update_mode=GridUpdateMode.VALUE_CHANGED,
        fit_columns_on_grid_load=True,
        allow_unsafe_jscode=True,
        height=300,
        key=table_name
    )

    updated_df = grid_response["data"]

    # === Save Changes ===
    if st.button(f"💾 Save Changes to {label}", key=f"save_{table_name}"):
        changes = []
        for _, row in updated_df.iterrows():
            row_data = {field: row[field] for field in editable_fields if field in row}
            if str(row["id"]).startswith("new_"):
                changes.append(("insert", row_data))
            else:
                changes.append(("update", {"id": row["id"], **row_data}))

        inserts = [data for op, data in changes if op == "insert"]
        updates = [data for op, data in changes if op == "update"]

        try:
            if inserts:
                supabase.table(table_name).insert(inserts).execute()
            for item in updates:
                supabase.table(table_name).update(item).eq("id", item["id"]).execute()
            st.success("✅ Changes saved.")
            st.rerun()
        except Exception as e:
            st.error(f"❌ Failed to save changes: {e}")
