import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

st.set_page_config(page_title="Reference Data", layout="wide")
st.title("Reference Data")

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

# === Select Table ===
selected_label = st.selectbox("Select Reference Table to Edit", list(ref_tables.keys()))
config = ref_tables[selected_label]
table_name = config["table"]
editable_fields = config["fields"]

# === Fetch and Prepare Data ===
res = supabase.table(table_name).select("*").execute()
df = pd.DataFrame(res.data) if res.data else pd.DataFrame(columns=editable_fields)
display_df = df[editable_fields].copy()

# === Build AgGrid Table ===
gb = GridOptionsBuilder.from_dataframe(display_df)
for field in editable_fields:
    if field == "status":
        gb.configure_column(field, editable=True, cellEditor="agSelectCellEditor", cellEditorParams={"values": ["Active", "Inactive"]})
    else:
        gb.configure_column(field, editable=True)
gb.configure_selection("single", use_checkbox=True)
grid_options = gb.build()

st.subheader(f"Editing: {selected_label}")
import json
st.write(json.dumps(grid_options, default=str, indent=2))

grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.VALUE_CHANGED,
    fit_columns_on_grid_load=True,
    allow_unsafe_jscode=True,
    height=300,
    key="ref_table_editor"
)

updated_df = grid_response["data"]

# === Save Button ===
if st.button("Save Changes"):
    changes = []
    for idx, row in updated_df.iterrows():
        row_data = {field: row[field] for field in editable_fields if field in row}
        if idx < len(df) and "id" in df.columns and pd.notnull(df.iloc[idx]["id"]):
            row_data["id"] = df.iloc[idx]["id"]
            changes.append(("update", row_data))
        else:
            changes.append(("insert", row_data))

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
