import streamlit as st
from utils.supabase import supabase
import pandas as pd

st.set_page_config(page_title="Ingredients", layout="wide")
st.title("🥦 Ingredients")

# Load ingredients
def fetch_ingredients():
    res = supabase.table("ingredients").select("*").order("name").execute()
    return pd.DataFrame(res.data) if res.data else pd.DataFrame()

# Load unique UOMs
def fetch_uoms():
    res = supabase.table("ref_uom_conversion").select("from_uom").execute()
    return sorted(set(row["from_uom"] for row in res.data)) if res.data else []

# Init state
if "edit_id" not in st.session_state:
    st.session_state.edit_id = None

df = fetch_ingredients()
uom_options = fetch_uoms()

# Active ingredient list
st.subheader("📋 Active Ingredients")
if not df.empty:
    def delete_row(row_id):
        supabase.table("ingredients").update({"status": "Inactive"}).eq("id", row_id).execute()
        st.success("Ingredient deactivated. Refresh to update.")

    for _, row in df[df["status"] == "Active"].iterrows():
        cols = st.columns([4, 2, 2, 1, 1])
        cols[0].markdown(f"**{row['name']}** ({row['ingredient_type']})")
        cols[1].write(f"{row['package_qty']} {row['package_uom']}")
        cols[2].write(f"${row['package_cost']:.2f}")
        if cols[3].button("✏️ Edit", key=f"edit_{row['id']}"):
            st.session_state.edit_id = row['id']
        if cols[4].button("🗑️ Delete", key=f"del_{row['id']}"):
            delete_row(row['id'])

# Add/Edit form
st.subheader("➕ Add or Edit Ingredient")
edit_mode = st.session_state.edit_id is not None
edit_data = df[df["id"] == st.session_state.edit_id].iloc[0] if edit_mode else {}

with st.form("ingredient_form"):
    name = st.text_input("Name", value=edit_data.get("name", "") if edit_mode else "")
    ingredient_type = st.selectbox(
        "Ingredient Type",
        ["Bought", "Prepped"],
        index=["Bought", "Prepped"].index(edit_data.get("ingredient_type", "Bought")) if edit_mode else 0
    )
    package_qty = st.number_input("Package Quantity", min_value=0.0, step=0.1, value=edit_data.get("package_qty", 0.0) if edit_mode else 0.0)
    package_uom = st.selectbox(
        "Package UOM",
        uom_options,
        index=uom_options.index(edit_data.get("package_uom")) if edit_mode and edit_data.get("package_uom") in uom_options else 0
    )
    package_cost = st.number_input("Package Cost", min_value=0.0, step=0.01, value=edit_data.get("package_cost", 0.0) if edit_mode else 0.0)
    yield_pct = st.number_input("Yield (%)", min_value=0.0, max_value=100.0, step=1.0, value=edit_data.get("yield_pct", 100.0) if edit_mode else 100.0)
    status = st.selectbox("Status", ["Active", "Inactive"], index=["Active", "Inactive"].index(edit_data.get("status", "Active")) if edit_mode else 0)

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
        }
        if edit_mode:
            supabase.table("ingredients").update(data).eq("id", st.session_state.edit_id).execute()
            st.success("Ingredient updated.")
        else:
            supabase.table("ingredients").insert(data).execute()
            st.success("Ingredient added.")
        st.session_state.edit_id = None
