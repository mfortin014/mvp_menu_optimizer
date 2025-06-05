import streamlit as st
import pandas as pd
from utils.supabase import supabase

st.set_page_config(page_title="Ingredients", layout="wide")
st.title("🥦 Ingredients")

# Load data
def fetch_ingredients():
    res = supabase.table("ingredients").select("*", "ref_ingredient_categories(name)").order("name").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

def fetch_uoms():
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted(set(row["from_uom"] for row in res.data)) if res.data else []

def fetch_categories():
    res = supabase.table("ref_ingredient_categories").select("id, name").eq("status", "Active").execute()
    return res.data if res.data else []

if "edit_id" not in st.session_state:
    st.session_state.edit_id = None
if "selected_index" not in st.session_state:
    st.session_state.selected_index = None

# Fetch and prepare data
df = fetch_ingredients()
uom_options = fetch_uoms()
categories = fetch_categories()
category_lookup = {c['id']: c['name'] for c in categories}

# Add selection logic (only one active at a time)
df["Select"] = False
if st.session_state.selected_index is not None and st.session_state.selected_index in df.index:
    df.at[st.session_state.selected_index, "Select"] = True

# Map category names for display
df["category"] = df["category_id"].map(category_lookup)

# Save original ids before slicing
full_df = df.copy()

# Render editable table
display_cols = ["Select", "ingredient_code", "name", "ingredient_type", "package_qty", "package_uom", "package_cost", "yield_pct", "category", "status"]
edited_df = st.data_editor(
    df[display_cols],
    column_config={"Select": st.column_config.CheckboxColumn()},
    hide_index=True,
    use_container_width=True,
    key="ingredient_editor"
)

# Enforce radio-button like selection (only 1 allowed)
new_selection = edited_df[edited_df["Select"] == True].index.tolist()
if new_selection:
    new_index = new_selection[0]
    if st.session_state.selected_index != new_index:
        st.session_state.selected_index = new_index
        match = full_df.loc[[new_index]]
        if not match.empty:
            st.session_state.edit_id = match.iloc[0]["id"]

# Sidebar form for Add/Edit
with st.sidebar:
    st.subheader("➕ Add or Edit Ingredient")
    edit_mode = st.session_state.edit_id is not None
    edit_data = df[df["id"] == st.session_state.edit_id].iloc[0] if edit_mode else {}

    with st.form("ingredient_form"):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        code = st.text_input("Ingredient Code", value=edit_data.get("ingredient_code", "") if edit_mode else "")
        ingredient_type = st.selectbox(
            "Ingredient Type",
            ["Bought", "Prepped"],
            index=["Bought", "Prepped"].index(edit_data.get("ingredient_type", "Bought")) if edit_mode else 0
        )
        package_qty = st.number_input("Package Quantity", min_value=0.0, step=0.1, value=float(edit_data.get("package_qty", 0.0)) if edit_mode else 0.0)
        package_uom = st.selectbox(
            "Package UOM",
            uom_options,
            index=uom_options.index(edit_data.get("package_uom")) if edit_mode and edit_data.get("package_uom") in uom_options else 0
        )
        package_cost = st.number_input("Package Cost", min_value=0.0, step=0.01, value=float(edit_data.get("package_cost", 0.0)) if edit_mode else 0.0)
        yield_pct = st.number_input("Yield (%)", min_value=0.0, max_value=100.0, step=1.0, value=float(edit_data.get("yield_pct", 100.0)) if edit_mode else 100.0)
        status = st.selectbox("Status", ["Active", "Inactive"], index=["Active", "Inactive"].index(edit_data.get("status", "Active")) if edit_mode else 0)
        category_names = [c['name'] for c in categories]
        category_name = st.selectbox("Category", category_names, index=category_names.index(category_lookup.get(edit_data.get("category_id"), category_names[0])) if edit_mode else 0)
        category_id = [c["id"] for c in categories if c["name"] == category_name][0]

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
                supabase.table("ingredients").update(data).eq("id", st.session_state.edit_id).execute()
                st.success("Ingredient updated.")
            else:
                supabase.table("ingredients").insert(data).execute()
                st.success("Ingredient added.")
            st.session_state.edit_id = None
            st.session_state.selected_index = None

    if edit_mode:
        if st.button("Cancel"):
            st.session_state.edit_id = None
            st.session_state.selected_index = None
        if st.button("Delete"):
            supabase.table("ingredients").update({"status": "Inactive"}).eq("id", st.session_state.edit_id).execute()
            st.success("Ingredient inactivated.")
            st.session_state.edit_id = None
            st.session_state.selected_index = None
