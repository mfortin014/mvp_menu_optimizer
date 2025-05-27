import streamlit as st
import pandas as pd
from utils.data import load_recipe_list, load_recipe_details

st.set_page_config(page_title="Recipes", layout="wide")
st.subheader("📄 Recipe Breakdown")

recipes = load_recipe_list()
selected = st.selectbox("Select a recipe:", recipes)

if selected:
    df = load_recipe_details(selected)
    st.dataframe(df, use_container_width=True)

    total_cost = df["line_cost"].sum()
    selling_price = df["selling_price"].iloc[0]
    margin = selling_price - total_cost

    st.metric("Total Cost", f"${total_cost:.2f}")
    st.metric("Selling Price", f"${selling_price:.2f}")
    st.metric("Margin", f"${margin:.2f}")
