import streamlit as st
import pandas as pd
from utils.data import load_recipe_list, load_ingredient_master, get_recipe_id_by_name, get_ingredient_id_by_name, add_recipe, add_recipe_line

st.set_page_config(page_title="Recipe Editor", layout="wide")
st.title("🛠️ Recipe Editor")

# --- SECTION 1: Add New Recipe ---
st.subheader("➕ Add New Recipe")

with st.form("add_recipe_form", clear_on_submit=True):
    col1, col2 = st.columns(2)
    with col1:
        recipe_name = st.text_input("Recipe Name", max_chars=100)
        recipe_code = st.text_input("Recipe Code", max_chars=20)
    with col2:
        base_yield_qty = st.number_input("Base Yield Quantity", min_value=0.0, step=0.1)
        base_yield_uom = st.text_input("Yield UOM", value="plate")
        price = st.number_input("Selling Price ($)", min_value=0.0, step=0.1)
        status = st.selectbox("Status", ["Active", "In Development", "Seasonal", "Discontinued"])

    submitted = st.form_submit_button("Create Recipe")
    if submitted:
        success = add_recipe(recipe_name, recipe_code, price, base_yield_qty, base_yield_uom, status)
        if success:
            st.success(f"✅ Recipe '{recipe_name}' added.")
        else:
            st.error("❌ Failed to add recipe. Please check the input.")

st.markdown("---")

# --- SECTION 2: Add Ingredient Line to Existing Recipe ---
st.subheader("➕ Add Ingredient to Recipe")

recipes = load_recipe_list()
ingredients_df = load_ingredient_master()
ingredient_names = ingredients_df["name"].tolist()

with st.form("add_recipe_line_form", clear_on_submit=True):
    col1, col2 = st.columns(2)
    with col1:
        selected_recipe = st.selectbox("Select Recipe", recipes)
        selected_ingredient = st.selectbox("Select Ingredient", ingredient_names)
    with col2:
        qty = st.number_input("Quantity", min_value=0.0, step=0.1)
        qty_uom = st.text_input("Quantity UOM", value="g")
        note = st.text_input("Optional Note")

    submitted_line = st.form_submit_button("Add Line to Recipe")
    if submitted_line:
        recipe_id = get_recipe_id_by_name(selected_recipe)
        ingredient_id = get_ingredient_id_by_name(selected_ingredient)
        success = add_recipe_line(recipe_id, ingredient_id, qty, qty_uom, note)
        if success:
            st.success(f"✅ Added {selected_ingredient} to {selected_recipe}.")
        else:
            st.error("❌ Failed to add line.")
