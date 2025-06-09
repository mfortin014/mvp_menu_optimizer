import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

st.set_page_config(page_title="Ingredients", layout="wide")
st.title("🥦 Ingredients")

# === Helper Functions ===
def fetch_ingredients():
    res = supabase.table("ingredients").select("*", "ref_ingredient_categories(name)").order("name").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

def fetch_uoms():
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted(set(row["from_uom"] for row in res.data)) if res.data else []

def fetch_categories():
    res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
    return res.data if res.data else []

# === Fetch data ===
uom_options = fetch_uoms()
categories = fetch_categories()
category_lookup = {c["id"]: c["name"] for c in categories}
category_reverse_lookup = {v: k for k, v in category_lookup.items()}

df = fetch_ingredients()
df["category"] = df["category_id"].map(category_lookup)

display_df = df.drop(columns=["id", "created_at", "updated_at", "category_id"], errors="ignore")

# === AgGrid Interactive Table ===
gb = GridOptionsBuilder.from_dataframe(display_df)
# No pagination — scrollable full table
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


selected_row = grid_response["selected_rows"]
edit_data = None

# Safely handle AgGrid return value
if selected_row is not None:
    # Handle case where it's a DataFrame (not expected, but observed)
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_code = selected_row.iloc[0].get("ingredient_code")
    # Handle expected case: list of dicts
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_code = selected_row[0].get("ingredient_code")
    else:
        selected_code = None

    # Match full row from df
    if selected_code:
        match = df[df["ingredient_code"] == selected_code]
        if not match.empty:
            edit_data = match.iloc[0].to_dict()

edit_mode = edit_data is not None


# === Sidebar Form ===
with st.sidebar:
    st.subheader("➕ Add or Edit Ingredient")
    with st.form("ingredient_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        code = st.text_input("Ingredient Code", value=edit_data.get("ingredient_code", "") if edit_mode else "")
        ingredient_type = st.selectbox(
            "Ingredient Type", ["Bought", "Prepped"],
            index=["Bought", "Prepped"].index(edit_data.get("ingredient_type", "Bought")) if edit_mode else 0
        )
        package_qty = st.number_input("Package Quantity", min_value=0.0, step=0.1,
                                      value=float(edit_data.get("package_qty", 0.0)) if edit_mode else 0.0)
        package_uom = st.selectbox(
            "Package UOM", uom_options,
            index=uom_options.index(edit_data.get("package_uom")) if edit_mode and edit_data.get("package_uom") in uom_options else 0
        )
        package_cost = st.number_input("Package Cost", min_value=0.0, step=0.01,
                                       value=float(edit_data.get("package_cost", 0.0)) if edit_mode else 0.0)
        yield_pct = st.number_input("Yield (%)", min_value=0.0, max_value=100.0, step=1.0,
                                    value=float(edit_data.get("yield_pct", 100.0)) if edit_mode else 100.0)
        status = st.selectbox("Status", ["Active", "Inactive"],
                              index=["Active", "Inactive"].index(edit_data.get("status", "Active")) if edit_mode else 0)
        category_names = list(category_reverse_lookup.keys())
        category_name = st.selectbox("Category", category_names,
                                     index=category_names.index(category_lookup.get(edit_data.get("category_id"), category_names[0])) if edit_mode else 0)
        category_id = category_reverse_lookup[category_name]

        submitted = st.form_submit_button("Save Ingredient")
        if submitted and name:
            data = {
                "name": name,
                "ingredient_code": code,
                "ingredient_type": ingredient_type,
                "package_qty": package_qty,
                "package_uom": package_uom,
                "package_cost": package_cost,
                "yield_pct": yield_pct,
                "status": status,
                "category_id": category_id
            }
            if edit_mode:
                supabase.table("ingredients").update(data).eq("id", edit_data["id"]).execute()
                st.success("Ingredient updated.")
            else:
                supabase.table("ingredients").insert(data).execute()
                st.success("Ingredient added.")
            st.experimental_rerun()

    if edit_mode:
        if st.button("Cancel"):
            st.experimental_rerun()
        if st.button("Delete"):
            supabase.table("ingredients").update({"status": "Inactive"}).eq("id", edit_data["id"]).execute()
            st.success("Ingredient inactivated.")
            st.experimental_rerun()
