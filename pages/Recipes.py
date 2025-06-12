import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

st.set_page_config(page_title="Recipes", layout="wide")
st.title("📘 Recipes")

# === Helper Functions ===
def fetch_recipes():
    res = supabase.table("recipes").select("*").order("name").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

def fetch_uoms():
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted(set(row["from_uom"] for row in res.data)) if res.data else []

# === Fetch data ===
uom_options = fetch_uoms()
df = fetch_recipes()
display_df = df.drop(columns=["id", "updated_at"], errors="ignore")

# === AgGrid Interactive Table ===
gb = GridOptionsBuilder.from_dataframe(display_df)
grid_height = 600 if len(display_df) > 10 else None
gb.configure_default_column(editable=False, filter=True, sortable=True)
gb.configure_selection("single", use_checkbox=False)
grid_options = gb.build()

grid_response = AgGrid(
    display_df,
    gridOptions=grid_options,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    fit_columns_on_grid_load=True,
    height=grid_height,
    allow_unsafe_jscode=True
)

# === CSV Export Button ===
st.markdown("### 📤 Export Recipes")
export_df = display_df.copy()
for col in ["base_yield_qty", "price"]:
    if col in export_df.columns:
        export_df[col] = export_df[col].round(6)
st.download_button(
    label="Download Recipes as CSV",
    data=export_df.to_csv(index=False),
    file_name="recipes_export.csv",
    mime="text/csv"
)

# === Handle Selection ===
selected_row = grid_response["selected_rows"]
edit_data = None

if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_code = selected_row.iloc[0].get("recipe_code")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_code = selected_row[0].get("recipe_code")
    else:
        selected_code = None

    if selected_code:
        match = df[df["recipe_code"] == selected_code]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None

# === Sidebar Form ===
with st.sidebar:
    st.subheader("➕ Add or Edit Recipe")
    with st.form("recipe_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        code = st.text_input("Recipe Code", value=edit_data.get("recipe_code", "") if edit_mode else "")

        # Yield Quantity
        yield_qty = st.number_input("Base Yield Quantity", min_value=0.0, step=0.1,
                                    value=float(edit_data.get("base_yield_qty", 1.0)) if edit_mode else 1.0)

        # Yield UOM
        uom_list = ["— Select —"] + uom_options
        selected_uom = edit_data.get("base_yield_uom") if edit_mode else None
        uom_index = uom_list.index(selected_uom) if selected_uom in uom_list else 0
        yield_uom = st.selectbox("Base Yield UOM", uom_list, index=uom_index)
        yield_uom = yield_uom if yield_uom != "— Select —" else None

        # Price
        price = st.number_input("Price", min_value=0.0, step=0.01,
                                value=float(edit_data.get("price", 0.0)) if edit_mode else 0.0)

        # Status
        status_options = ["— Select —", "Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else None
        status_index = status_options.index(selected_status) if selected_status in status_options else 0
        status = st.selectbox("Status", status_options, index=status_index)
        status = status if status != "— Select —" else None

        submitted = st.form_submit_button("Save Recipe")
        errors = []

        if not name:
            errors.append("Name")
        if not code:
            errors.append("Recipe Code")
        if not yield_uom:
            errors.append("Base Yield UOM")
        if not status:
            errors.append("Status")

        if submitted:
            if errors:
                st.error(f"⚠️ Please complete the following fields: {', '.join(errors)}")
            else:
                data = {
                    "name": name,
                    "recipe_code": code,
                    "base_yield_qty": round(yield_qty, 6),
                    "base_yield_uom": yield_uom,
                    "price": round(price, 6),
                    "status": status
                }
                if edit_mode:
                    supabase.table("recipes").update(data).eq("id", edit_data["id"]).execute()
                    st.success("Recipe updated.")
                else:
                    supabase.table("recipes").insert(data).execute()
                    st.success("Recipe added.")
                st.rerun()

    if edit_mode:
        if st.button("Cancel"):
            st.rerun()
        if st.button("Delete"):
            supabase.table("recipes").update({"status": "Inactive"}).eq("id", edit_data["id"]).execute()
            st.success("Recipe inactivated.")
            st.rerun()
