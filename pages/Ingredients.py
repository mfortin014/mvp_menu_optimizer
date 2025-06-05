import streamlit as st
import pandas as pd
from utils.supabase import supabase

st.set_page_config(page_title="Ingredients", layout="wide")
st.title("🥦 Ingredients")

# --- Fetch Data ---
@st.cache_data(ttl=60)
def fetch_ingredients():
    res = supabase.table("ingredients").select("*").order("name").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

@st.cache_data(ttl=60)
def fetch_uoms():
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted({row["from_uom"] for row in res.data}) if res.data else []

# --- Session State ---
if "edit_id" not in st.session_state:
    st.session_state.edit_id = None
if "confirm_delete" not in st.session_state:
    st.session_state.confirm_delete = None

# --- Load Data ---
df = fetch_ingredients()
uom_options = fetch_uoms()

# --- Actions ---
def delete_row(row_id):
    st.session_state.confirm_delete = row_id

def confirm_delete_row(row_id):
    supabase.table("ingredients").update({"status": "Inactive"}).eq("id", row_id).execute()
    st.success("Ingredient set to Inactive.")
    st.session_state.confirm_delete = None
    st.rerun()

def reset_edit():
    st.session_state.edit_id = None

# --- Display Table ---
st.subheader("📋 Active Ingredients")

if not df.empty:
    active_df = df[df["status"] == "Active"]
    styled_df = active_df[["name", "ingredient_type", "package_qty", "package_uom", "package_cost", "yield_pct"]]
    styled_df = styled_df.rename(columns={
        "name": "Name",
        "ingredient_type": "Type",
        "package_qty": "Qty",
        "package_uom": "UOM",
        "package_cost": "Cost",
        "yield_pct": "Yield (%)"
    })

    st.dataframe(styled_df, use_container_width=True)

    for _, row in active_df.iterrows():
        cols = st.columns([5, 1, 1])
        if cols[0].button(f"✏️ Edit: {row['name']}", key=f"edit_{row['id']}"):
            st.session_state.edit_id = row['id']
        if cols[1].button("🗑️ Delete", key=f"del_{row['id']}"):
            delete_row(row['id'])

        if st.session_state.confirm_delete == row['id']:
            cols[2].warning("Confirm?")
            if cols[2].button("✅ Yes", key=f"confirm_{row['id']}"):
                confirm_delete_row(row['id'])

# --- Sidebar Add/Edit ---
with st.sidebar:
    st.header("➕ Add / Edit Ingredient")
    edit_mode = st.session_state.edit_id is not None
    edit_data = df[df["id"] == st.session_state.edit_id].iloc[0] if edit_mode else {}

    with st.form("ingredient_form", clear_on_submit=not edit_mode):
        name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
        ingredient_type = st.selectbox(
            "Ingredient Type", ["Bought", "Prepped"],
            index=["Bought", "Prepped"].index(edit_data.get("ingredient_type", "Bought")) if edit_mode else 0
        )
        package_qty = st.number_input("Package Quantity", min_value=0.0, step=0.1,
                                      value=edit_data.get("package_qty", 0.0) if edit_mode else 0.0)
        package_uom = st.selectbox(
            "Package UOM", uom_options,
            index=uom_options.index(edit_data.get("package_uom")) if edit_mode and edit_data.get("package_uom") in uom_options else 0
        )
        package_cost = st.number_input("Package Cost", min_value=0.0, step=0.01,
                                       value=edit_data.get("package_cost", 0.0) if edit_mode else 0.0)
        yield_pct = st.number_input("Yield (%)", min_value=0.0, max_value=100.0, step=1.0,
                                    value=edit_data.get("yield_pct", 100.0) if edit_mode else 100.0)
        status = st.selectbox("Status", ["Active", "Inactive"],
                              index=["Active", "Inactive"].index(edit_data.get("status", "Active")) if edit_mode else 0)

        # Optional: Ingredient Category (WIP)
        # categories = [cat["name"] for cat in get_active_ingredient_categories()]
        # category = st.selectbox("Category", categories, index=0)

        submitted = st.form_submit_button("Save Ingredient")

        if submitted and name:
            data = {
                "name": name,
                "ingredient_type": ingredient_type,
                "package_qty": package_qty,
                "package_uom": package_uom,
                "package_cost": package_cost,
                "yield_pct": yield_pct,
                "status": status
                # "category": category  # Optional
            }
            if edit_mode:
                supabase.table("ingredients").update(data).eq("id", st.session_state.edit_id).execute()
                st.success("Ingredient updated.")
            else:
                supabase.table("ingredients").insert(data).execute()
                st.success("Ingredient added.")

            reset_edit()
            st.rerun()
