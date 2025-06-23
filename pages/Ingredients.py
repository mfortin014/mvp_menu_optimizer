import streamlit as st
import pandas as pd
from utils.supabase import supabase
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

st.set_page_config(page_title="Ingredients", layout="wide")
st.title("🥦 Ingredients")

# === Helper Functions ===
def fetch_ingredients():
    res = supabase.table("ingredients").select("*").order("name").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

def fetch_ingredient_costs():
    res = supabase.table("ingredient_costs").select("ingredient_code, unit_cost").execute()
    return {row["ingredient_code"]: row["unit_cost"] for row in res.data} if res.data else {}

def fetch_uoms():
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted(set(row["from_uom"] for row in res.data)) if res.data else []

def fetch_categories():
    res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
    return res.data if res.data else []

def fetch_storage_types():
    res = supabase.table("ref_storage_type").select("id, name").eq("status", "Active").execute()
    return res.data if res.data else []

# === Fetch data ===
uom_options = fetch_uoms()
categories = fetch_categories()
storage_types = fetch_storage_types()
category_lookup = {c["id"]: c["name"] for c in categories}
storage_lookup = {s["id"]: s["name"] for s in storage_types}
category_reverse_lookup = {v: k for k, v in category_lookup.items()}

cost_lookup = fetch_ingredient_costs()

df = fetch_ingredients()
df["category"] = df["category_id"].map(category_lookup)
df["storage_type"] = df["storage_type_id"].map(storage_lookup)
df["unit_cost"] = df["ingredient_code"].map(cost_lookup)

column_order = [
    "name", "ingredient_code", "ingredient_type", "package_qty", "package_uom",
    "package_cost", "yield_pct", "status", "category", "storage_type", "unit_cost", "base_uom"
]
display_df = df[column_order if all(c in df.columns for c in column_order) else df.columns]

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
st.markdown("### 🇵 Export Ingredients")
export_df = display_df.copy()
for col in ["package_qty", "package_cost", "yield_pct", "unit_cost"]:
    if col in export_df.columns:
        export_df[col] = export_df[col].round(6)
st.download_button(
    label="Download Ingredients as CSV",
    data=export_df.to_csv(index=False),
    file_name="ingredients_export.csv",
    mime="text/csv"
)

# === Handle Selection ===
selected_row = grid_response["selected_rows"]
edit_data = None

if selected_row is not None:
    if isinstance(selected_row, pd.DataFrame) and not selected_row.empty:
        selected_code = selected_row.iloc[0].get("ingredient_code")
    elif isinstance(selected_row, list) and len(selected_row) > 0:
        selected_code = selected_row[0].get("ingredient_code")
    else:
        selected_code = None

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

        # Ingredient Type
        type_options = ["— Select —", "Bought", "Prepped"]
        selected_type = edit_data.get("ingredient_type") if edit_mode else None
        type_index = type_options.index(selected_type) if selected_type in type_options else 0
        ingredient_type = st.selectbox("Ingredient Type", type_options, index=type_index)
        ingredient_type = ingredient_type if ingredient_type != "— Select —" else None

        # Package Quantity
        package_qty = st.number_input("Package Quantity", min_value=0.0, step=0.1,
                                      value=float(edit_data.get("package_qty", 0.0)) if edit_mode else 0.0)

        # Package UOM
        uom_list = ["— Select —"] + uom_options
        selected_uom = edit_data.get("package_uom") if edit_mode else None
        uom_index = uom_list.index(selected_uom) if selected_uom in uom_list else 0
        package_uom = st.selectbox("Package UOM", uom_list, index=uom_index)
        package_uom = package_uom if package_uom != "— Select —" else None

        # Package Cost
        package_cost = st.number_input("Package Cost", min_value=0.0, step=0.01,
                                       value=float(edit_data.get("package_cost", 0.0)) if edit_mode else 0.0)

        # Yield %
        yield_pct = st.number_input("Yield (%)", min_value=0.0, max_value=100.0, step=1.0,
                                    value=float(edit_data.get("yield_pct", 100.0)) if edit_mode else 100.0)

        # Status
        status_options = ["— Select —", "Active", "Inactive"]
        selected_status = edit_data.get("status") if edit_mode else None
        status_index = status_options.index(selected_status) if selected_status in status_options else 0
        status = st.selectbox("Status", status_options, index=status_index)
        status = status if status != "— Select —" else None

        # Category
        category_names = ["— Select —"] + [c['name'] for c in categories]
        category_id = edit_data.get("category_id") if edit_mode else None
        preselected_category = category_lookup.get(category_id)
        category_index = category_names.index(preselected_category) if preselected_category in category_names else 0
        category_name = st.selectbox("Category", category_names, index=category_index)
        category_id = [c["id"] for c in categories if c["name"] == category_name][0] if category_name != "— Select —" else None

        # Storage Type
        storage_names = ["— Select —"] + [s["name"] for s in storage_types]
        storage_id = edit_data.get("storage_type_id") if edit_mode else None
        preselected_storage = storage_lookup.get(storage_id)
        storage_index = storage_names.index(preselected_storage) if preselected_storage in storage_names else 0
        selected_storage = st.selectbox("Storage Type", storage_names, index=storage_index)
        storage_type_id = [s["id"] for s in storage_types if s["name"] == selected_storage][0] if selected_storage != "— Select —" else None

        # Base UOM
        base_uom_options = ["— Select —", "g", "ml", "unit"]
        selected_base = edit_data.get("base_uom") if edit_mode else None
        base_index = base_uom_options.index(selected_base) if selected_base in base_uom_options else 0
        base_uom = st.selectbox("Base UOM (optional, will be inferred if left blank)", base_uom_options, index=base_index)
        base_uom = base_uom if base_uom != "— Select —" else None

        submitted = st.form_submit_button("Save Ingredient")
        errors = []

        if not name:
            errors.append("Name")
        if not code:
            errors.append("Ingredient Code")
        if not ingredient_type:
            errors.append("Ingredient Type")
        if not package_uom:
            errors.append("Package UOM")
        if not status:
            errors.append("Status")
        if not category_id:
            errors.append("Category")

        if submitted:
            if errors:
                st.error(f"⚠️ Please complete the following fields: {', '.join(errors)}")
            else:
                data = {
                    "name": name,
                    "ingredient_code": code,
                    "ingredient_type": ingredient_type,
                    "package_qty": round(package_qty, 6),
                    "package_uom": package_uom,
                    "package_cost": round(package_cost, 6),
                    "yield_pct": round(yield_pct, 6),
                    "base_uom": base_uom,
                    "status": status,
                    "category_id": category_id,
                    "storage_type_id": storage_type_id
                }
                if edit_mode:
                    supabase.table("ingredients").update(data).eq("id", edit_data["id"]).execute()
                    st.success("Ingredient updated.")
                else:
                    supabase.table("ingredients").insert(data).execute()
                    st.success("Ingredient added.")
                st.rerun()

    if edit_mode:
        if st.button("Cancel"):
            st.rerun()
        if st.button("Delete"):
            supabase.table("ingredients").update({"status": "Inactive"}).eq("id", edit_data["id"]).execute()
            st.success("Ingredient inactivated.")
            st.rerun()
